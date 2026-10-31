# GOD PUMP — Backlog

> Owner: Producer. Ordered. Briefs live in `docs/briefs/`.
> Rebuilt on 2026-10-31 from the old BACKLOG.md (docs/archive/BACKLOG_history.md: rounds 1–11, all done items, the old Gas Bar Blues ideas).

## Current milestone: M1 Vertical Slice
Goal: one complete GOD PUMP run (first day to win or loss) at near-final quality, in French and English.
Exit criteria:
- A new player learns the game from the tutorial alone and finishes a run.
- The Director plays a full run and wants another.
- Every screen in the cartoon look; no known blocking bugs.
- The bot wins about 1 run in 25; a skilled player can reach 100% with work.
- `main` holds the playable build (done 2026-10-31, PR #38).

| Priority | ID | Brief | Type | Status | PR |
|---|---|---|---|---|---|
| 1 | — | Playtest v0.48 (`/studio:playtest`): tutorial (reset save in F1), chain on screen, Garage tab and nozzle ladder, new cards, closing and report reveal, new-car card, difficulty | Playtest | Waiting on the Director | |
| 2 | — | Merge `hypothesis/god-pump-run` into `main` so main is playable | Tech | Done | #38 |
| 3 | B01 | Fix the one biggest weakness from playtest 13 | Feature | Not written | |
| 4 | B02 | Menus in the cartoon look: night, report, title, garage, cards, truck, icons (round 10 C pass 2) | Art | Not written | |
| 5 | B03 | Split the day scene (`god_pump.gd`, 2,315 lines) into components; then run arch_check in CI | Tech | Not written | |
| 6 | — | Still to check from playtest 9: the wheel clamps; one run in French | Playtest | Open | |

## Next milestones
- M2 Alpha: real sounds instead of placeholders; settings screen (volume, fullscreen) and pause (Esc); the title check (see risks).

## Cut list (Won't — with reason and date)
- Meta progression between runs (Papa's Garage between runs, meta XP) — three upgrade layers confused players; 2026-10-25.
- L'Écho newspaper — playtest 8: not fun; replaced by the visitors in round 9.
- Self-service pumps and the key-per-pump game — replaced by GOD PUMP; 2026-10-20.

## Ideas parking lot (not yet evaluated)
- Windows build and installer (on hold until the game is stable; tooling in tools/windows)
- `[juice]` Piggy-bank car: swells as it fills, pops on the stop
- More car types (diesel, electric, environmentalist…) with their own rules
- Gas price variation; inspections; bribing an inspector (comedy)
- Pump as a character; receipts and invoices; fuel types
- Mobile version
- Tips as a personal third currency

## Bugs
| ID | Title | Severity | Status | Found in |
|---|---|---|---|---|

## Risk register
| Risk | Likelihood | Impact | Mitigation | Owner | Revisit trigger |
|---|---|---|---|---|---|
| Too easy / too hard to reach 100% | Medium | High | Balance bot + Director playtest | Producer | Playtest 13 |
| Title clash ("Gaz Bar Blues" film, 2003) / GOD PUMP not checked | Medium | High at release | Name check before any public page | Producer | Before G3 |
| `god_pump.gd` too big to change safely | High | Medium | Brief B03 | Programmer | Before B02 |
| Music licence (ElevenLabs plan) | Low | High at release | Confirm commercial use | Audio Director | Before G3 |
