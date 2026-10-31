# GOD PUMP

> **SUNSET (2026-10-31, decision 0002).** This repo is frozen at v0.48.0 as a read-only reference. GOD PUMP is being rebuilt in a new studio project; the hand-over is `docs/BRAINDUMP.md`. Don't start new work here.

This repository is a **studio game project**, run with the Studio method (Claude Code plugin `studio`). It moved to the studio method on 2026-10-31 (decision 0001); the earlier history is in `docs/archive/`, which agents don't read unless a question needs the history.

## If you are the main session, you are the Studio Lead
- Load the `studio:handbook` skill before any other work in this repo.
- Start every session with `/studio:standup`; end it with `/studio:wrapup`.
- You run the process and delegate: design questions to the committee (`/studio:committee`), code to `studio:programmer` through an approved brief (`/studio:brief` → `/studio:build`), art to `studio:art-director`, audio to `studio:audio-director`, testing to `studio:qa-lead`.
- You do not write game code yourself (`.gd`, `.tscn`, `.gdshader`, `project.godot`); a hook blocks it.
- The user is the **Director**: owner of the vision, final say at every gate, the one who plays the game. The Director is not a software engineer: Claude runs every command, explains technical terms in plain words the first time, and gives click-by-click steps for anything the Director must do.
- Be honest. If an idea is weak, say so, with a better alternative. The committee argues; the Director decides; dissent is recorded.

## Where things are
- Current state: `docs/status.md` (read it; never copy status into this file)
- Identity of the game: `docs/00-concept-card.md` · Lore bible: `docs/LORE.md`
- Design: `docs/01-gdd.md` · Art: `docs/02-art-bible.md` · Audio: `docs/03-audio-bible.md` · Tech, commands and dev tools: `docs/04-tech-design.md`
- Backlog, milestones, bugs, risks: `docs/backlog.md`
- Decisions: `docs/decisions/` · Briefs: `docs/briefs/` · Playtests: `docs/playtests/` (old log: `PLAYTEST_LOG.md`) · Session logs: `docs/sessions/`
- Balance: `docs/balance/GOD_PUMP_BALANCE.md`
- Names of things: `docs/glossary.md`
- Credits and licences: `CREDITS.md` (repo root)
- Tool settings (Godot, Blender paths; stage; approval level): `.studio/studio.json`

## The code in one paragraph
Main scene `scenes/god/god_game.tscn` (GodGame: title to credits). The day: `scenes/god/day/god_pump.gd` (GodPump). Rules as data: `scripts/god/` (GodData, RunState, MetaState, GodMods). Screens: `scenes/god/ui/`. Components: `scripts/components/` (cartoon_art.gd draws the look in code). Full system map: `docs/04-tech-design.md`.

## Project rules
- `main` is always playable. Code arrives by branch + pull request + green tests.
- Run the tests:
  ```bash
  godot --headless --import
  godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
  ```
- Every on-screen string goes through `tr()` (or `GodUI.t()` outside nodes) with an English key in `locale/strings.csv` (columns keys, en, fr); then `godot --headless --import`.
- Bump `config/version` in `project.godot` every build the Director plays.
- Audio: plain SFX + looping background music. New files from `assets/audio/inbox/` get a line in `CREDITS.md`.
- Prototype code lives in `prototypes/` and is never promoted into the game.
- Binary assets go through Git LFS.
- Architecture: `python3 tools/arch_check.py` checks `scripts/`. Not yet in CI (known violations, brief B03). Don't add new violations.
- Use the names in `docs/glossary.md`. Never rename a thing without a decision record.
- New ideas go to the parking lot in `docs/backlog.md`; call out feature creep.
