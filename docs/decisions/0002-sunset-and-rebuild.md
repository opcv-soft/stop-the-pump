# 0002 — Sunset stop-the-pump and rebuild GOD PUMP in a new studio project

- **Date:** 2026-10-31
- **Status:** Accepted
- **Type:** Scope
- **Decided by:** Director

## Context
The game is settled enough to rebuild, but the code grew without architecture (the day is one 2,315-line file; four views kept alive). The Director chose to start a brand-new studio project rather than refactor this one.

## Options considered
1. **Refactor in place** — keeps history; every brief fights the old structure.
2. **New studio project, rebuilt cleanly from a full hand-over** — clean architecture from brief 1; costs a rebuild.

## Decision
Option 2. This repo is frozen at v0.48.0 on `main` as a read-only reference. Everything learned is in `docs/BRAINDUMP.md`, which the new project copies in and uses as its kickoff pitch.

## Consequences
- No more work in this repo. The new project reads the old code here while rebuilding.
- The v0.48.0 build serves as the new project's prototype for its first outside playtests.

## Dissent
| Seat | Objection (one line) | Revisit trigger |
|---|---|---|

## Links
docs/BRAINDUMP.md, docs/decisions/0001-adopt-the-studio-method.md
