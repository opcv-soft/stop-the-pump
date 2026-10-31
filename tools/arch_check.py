#!/usr/bin/env python3
"""Architecture check — enforces the studio's code rules with code, not with hope.

Run from the repo root:  python3 tools/arch_check.py        (exit 1 if any rule is broken)
Runs in CI on every push, and by the Code Reviewer and QA Lead.

Rules (edit the constants below, by decision record):
  R1  File size: no .gd file in src/ over MAX_LINES lines.
  R2  Pure core: scripts in src/core/ don't extend Node types or touch the scene tree.
  R3  Static typing: every `var`/`const` and function parameter in src/ has a type (or uses :=);
      every func declares a return type.
  R4  Naming: .gd/.tscn file names are snake_case; class_name is PascalCase.
  R5  Godot 3 traps: no Godot 3 syntax.
  R6  Glossary: identifiers listed as "forbidden" in docs/glossary.md never appear in src/.
  R7  No bare print() in src/ (use the Log/Telemetry autoload, or push_error/push_warning).
"""
import os
import re
import sys

MAX_LINES = 300
SRC = "scripts"
CORE = os.path.join("scripts", "core")
GLOSSARY = os.path.join("docs", "glossary.md")
NODE_BASES = r"(Node|Node2D|Node3D|Control|CanvasItem|CanvasLayer|Sprite2D|Area2D|CharacterBody2D|CharacterBody3D|RigidBody2D|RigidBody3D|Camera2D|Camera3D)"
GODOT3 = [
    (r"\byield\s*\(", "yield( → use await"),
    (r"\.connect\(\s*\"[a-z_]+\"\s*,\s*self\s*,", "connect(\"sig\", self, \"m\") → sig.connect(m)"),
    (r"^\s*export\s*(\(|var)", "export var → @export var"),
    (r"^\s*onready\s+var", "onready var → @onready var"),
    (r"^\s*tool\s*$", "tool → @tool"),
    (r"\bKinematicBody(2D)?\b", "KinematicBody → CharacterBody2D/3D"),
    (r"\.instance\(\)", ".instance() → .instantiate()"),
    (r"change_scene\(", "change_scene( → change_scene_to_file("),
    (r"\bOS\.get_ticks_msec\(", "OS.get_ticks_msec → Time.get_ticks_msec"),
    (r"\brand_range\(", "rand_range → randf_range"),
    (r"\bFile\.new\(\)|\bDirectory\.new\(\)", "File/Directory.new → FileAccess/DirAccess"),
    (r"\bsetget\b", "setget → property get:/set:"),
]
SNAKE = re.compile(r"^[a-z0-9_]+$")
PASCAL = re.compile(r"^[A-Z][A-Za-z0-9]*$")


def gd_files(root):
    for d, _, files in os.walk(root):
        if os.sep + "addons" in d or os.sep + ".godot" in d:
            continue
        for f in files:
            if f.endswith((".gd", ".tscn")):
                yield os.path.join(d, f)


def forbidden_terms():
    """Glossary lines like: | Worker | `Worker` | employee, guy, npc |  → 3rd column = forbidden."""
    terms = set()
    if not os.path.exists(GLOSSARY):
        return terms
    with open(GLOSSARY, encoding="utf-8") as f:
        for line in f:
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(cells) >= 3 and cells[0] and not cells[0].startswith(("-", "Design term")):
                for t in cells[2].split(","):
                    t = t.strip().strip("`")
                    if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", t or ""):
                        terms.add(t)
    return terms


def strip_strings_and_comments(line):
    line = re.sub(r'"(\\.|[^"\\])*"', '""', line)
    line = re.sub(r"'(\\.|[^'\\])*'", "''", line)
    return line.split("#", 1)[0]


def main():
    problems = []
    if not os.path.isdir(SRC):
        print(f"arch_check: no {SRC}/ yet — nothing to check.")
        return 0
    forbidden = forbidden_terms()
    for path in gd_files(SRC):
        name = os.path.splitext(os.path.basename(path))[0]
        if not SNAKE.match(name):
            problems.append(f"R4 {path}: file name must be snake_case")
        if not path.endswith(".gd"):
            continue
        with open(path, encoding="utf-8") as f:
            lines = f.read().splitlines()
        if len(lines) > MAX_LINES:
            problems.append(f"R1 {path}: {len(lines)} lines (max {MAX_LINES}) — split it")
        in_core = os.path.commonpath([os.path.abspath(path), os.path.abspath(CORE)]) == os.path.abspath(CORE) \
            if os.path.isdir(CORE) else False
        for i, raw in enumerate(lines, 1):
            code = strip_strings_and_comments(raw)
            where = f"{path}:{i}"
            m = re.match(r"^\s*class_name\s+(\w+)", code)
            if m and not PASCAL.match(m.group(1)):
                problems.append(f"R4 {where}: class_name '{m.group(1)}' must be PascalCase")
            if in_core:
                if re.match(rf"^\s*extends\s+{NODE_BASES}\b", code):
                    problems.append(f"R2 {where}: src/core must not extend a Node type (use RefCounted/Resource)")
                if re.search(r"\$[A-Za-z\"]|get_node\(|get_tree\(|add_child\(", code):
                    problems.append(f"R2 {where}: src/core must not touch the scene tree")
            m = re.match(r"^\s*(?:@\w+(?:\([^)]*\))?\s+)*(var|const)\s+(\w+)\s*(:?=|:|$)", code)
            if m and m.group(3) not in (":", ":="):
                problems.append(f"R3 {where}: '{m.group(2)}' needs a type (e.g. `var x: int = 0` or `:=`)")
            m = re.match(r"^\s*(?:static\s+)?func\s+(\w+)\s*\((.*)\)\s*(->\s*[\w\[\], .]+)?\s*:", code)
            if m:
                if not m.group(3):
                    problems.append(f"R3 {where}: func {m.group(1)} needs a return type (-> void, -> int…)")
                params = [p.strip() for p in m.group(2).split(",") if p.strip()]
                for p in params:
                    if ":" not in p:
                        problems.append(f"R3 {where}: parameter '{p}' of {m.group(1)} needs a type")
            for pat, msg in GODOT3:
                if re.search(pat, code):
                    problems.append(f"R5 {where}: Godot 3 syntax — {msg}")
            for t in forbidden:
                if re.search(rf"\b{re.escape(t)}\b", code):
                    problems.append(f"R6 {where}: '{t}' is a forbidden name in docs/glossary.md")
            if re.match(r"^\s*print\(", code):
                problems.append(f"R7 {where}: bare print() — use the Log autoload or push_warning/push_error")
    if problems:
        print(f"arch_check: {len(problems)} problem(s)")
        for p in problems:
            print("  " + p)
        return 1
    print("arch_check: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
