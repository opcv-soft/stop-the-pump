# 0001 — Adopt the studio method mid-project

- **Date:** 2026-10-31
- **Status:** Accepted
- **Type:** Scope
- **Decided by:** Director

## Context
GOD PUMP was built with the Indie Game Committee method (DESIGN.md, BACKLOG.md, Claude coding directly on `hypothesis/*` branches). The Director chose to move it to the studio method (`.studio/studio.json`, `/studio:standup` → brief → build → wrapup).

## Options considered
1. **Keep the old routine** — no disruption; no gates, briefs or code review.
2. **Convert in place** — keep all code and history, rebuild the docs in the studio layout.
3. **New repo with /studio:new-game** — clean, but loses history and the working game.

## Decision
Convert in place (option 2):
- **Stage:** Implement, milestone **M1 Vertical Slice**. G0 and G1 count as passed under the old method (the core loop was declared fun on 2026-10-19; the god pump kept on 2026-10-20; 12 playtests since). No formal gate records exist for them.
- **Docs:** DESIGN.md, BACKLOG.md and the round plans moved to `docs/archive/`; their current content condensed into the concept card, GDD, bibles, tech design and backlog. The old Decision Log (DESIGN_history.md §11) is the record of every decision before this one. The playtest log moved to `docs/playtests/`.
- **Code rules:** from now on game code is written by the Programmer from a brief; the Lead doesn't edit code (`lead_can_code: false`).
- **Architecture checker:** `tools/arch_check.py` points at `scripts/` (the game has no `src/`). Not in CI yet, because existing files break the size rule.
- **Kept as is:** the GUT tests and Gherkin specs, CREDITS.md at the root, the CI workflow.

## Rationale
The game works and the history is valuable; only the process changes.

## Consequences
- Every change now goes through a brief; small tweaks get batched.
- `main` must become playable: the GOD PUMP branch needs merging (Director's call).
- `docs/` now has a `.gdignore`, so Godot no longer imports the docs' screenshots (nothing in the game uses them).

## Dissent
| Seat | Objection (one line) | Revisit trigger |
|---|---|---|
| Programmer | The size rule should cover `scenes/` too, where god_pump.gd is 2,315 lines | When the split-the-day brief is written |

## Links
docs/archive/DESIGN_history.md, docs/archive/BACKLOG_history.md
