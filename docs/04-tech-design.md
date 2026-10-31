# GOD PUMP — Technical design

> Owner: Programmer. Written on 2026-10-31 from the code as it stands in v0.48.0.

## Engine and tools
- Godot 4.7.2, typed GDScript. Tests: GUT (`addons/gut`), in `tests/`; Gherkin specs in `features/`.
- Pixel art (older views, menu icons): claude-pxl (`~/Tools/claude-pxl`, MIT), sources in `assets/art/pixel/*.px.js`.
- Blender: the old low-poly kit (`tools/blender/`, `assets/art/source|export/`), unused by GOD PUMP.

## Platforms and input
Mac and PC, mouse. A web build (single-threaded, Compatibility renderer) for playtests. Windows installer tooling exists but is parked.

## Performance budget
60 fps on the Director's Mac and in the web build. No measured problems so far.

## System map (plain language — for the Director)
- **GodGame** (`scenes/god/god_game.tscn`) is the whole flow: title → intro → days and nights → ending → credits.
- **GodPump** (`scenes/god/day/god_pump.gd`) is one day on the lot: cars, the nozzle, fills, coins, chains, closing.
- **The rules as data** (`scripts/god/`): GodData lists everything you can own (tree, nozzles, cards, car types) with its numbers; RunState is this run (cash, tank, share, XP); MetaState is the save between runs (lifetime stats, language, station name); GodMods adds up what you own into the numbers the day uses.
- **Screens** (`scenes/god/ui/`): day report, night (Shop, Garage, codex), truck, charts, cinematics.
- **Small parts** (`scripts/components/`): cartoon_art (draws the cartoon look in code), regulars_crew, nozzle_bling, tutorial.
- **Text**: every on-screen string goes through `tr()` with English keys in `locale/strings.csv` (columns keys, en, fr).

## Architecture
- Composition: small component nodes in `scripts/components/`; rules and data in `scripts/god/` with no scene logic.
- Save: `user://godpump_meta.cfg` (lifetime stats, language, station name; no XP).
- Architecture checker: `python3 tools/arch_check.py` checks `scripts/` (decision 0001). It does not run in CI yet: 2 files are over 300 lines (cartoon_art.gd 533, run_state.gd 415), and `scenes/` is not checked (god_pump.gd is 2,315 lines).

## Commands
```bash
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
godot --headless -s tools/sim/god_bot.gd -- 20 fresh
sh tools/web/pack_artifact.sh
godot --path . -s tools/demo/snapshot.gd -- <out.png> [seconds]
```
- Balance bot: `tools/sim/god_bot.gd` plays the real game headless (fresh runs). Report: docs/balance/GOD_PUMP_BALANCE.md.
- Web build: packs `build/artifact/`; publish `build/artifact/index.html` with its 5 files to https://claude.ai/artifact/EcEB3srrceAkaePKW8RHhL.
- Windows installer (parked): `sh tools/windows/build_installer.sh` (NSIS).
- Demo video: `tools/demo/director.gd`. Sounds: `python3 tools/make_godpump_sounds.py`.
- Bump `config/version` in `project.godot` every build the Director plays (shown on the title screen).

## Dev tools
- **I:** cycle the views (cartoon default, HD-2D, three-quarter pixel, flat top-down).
- **F1 dev mode:** configurator panel (cash, tank, day, XP, cars filled, game speed, NEXT NIGHT, END THE DAY, RESET SAVE).
- **F3** end the day · **F4** +$100 · **F6** +10,000 XP.
- Snapshot tool (above) to check a layout without playing. No save-states yet (`debug/states/` is ready).

## Technical risks
1. `god_pump.gd` (2,315 lines) holds most of the day: every change there is slower and riskier. Split it before the menus' redraw adds more.
2. (Resolved 2026-10-31: GOD PUMP merged into `main`, PR #38.)

## Performance log
| Date | Build | Measure | Result |
|---|---|---|---|
