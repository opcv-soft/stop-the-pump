# GOD PUMP — Concept card

> Identity of the game. Changed only by decision record.
> Rebuilt on 2026-10-31 from the pre-studio design (docs/archive/DESIGN_history.md, the round plans and the playtest log), when the project moved to the studio method. The original game, Gas Bar Blues (a key per pump), became GOD PUMP on 2026-10-20.

| | |
|---|---|
| **Status** | Agreed in practice (playtests 1–12, before the studio method). Re-confirm at the next gate. |
| **Working title** | GOD PUMP (repo: stop-the-pump; earlier: Gas Bar Blues) |
| **Mantra** | Top them off to the cent, win the village back. |
| **It's X meets Y, but Z** | It's a Bills Must Be Paid roguelite meets an arcade pour-and-stop, but you pour gas from the sky onto cars driving around your lot. |

## Pillars
1. **The fill is the skill** — hold to pour, let go at the top; the closer to 100% without spilling, the better. *Test:* a playtester talks about their fills ("I topped that one off!"), not their upgrades.
2. **Chains pay for everything** — chains of Good-or-better fills earn the XP that buys the Garage. *Test:* players change how they pour to keep a chain alive.
3. **Small-town comedy with a heart** — Saint-Clin-Clin, Dad, Gaétan across the road, the regulars. *Test:* players quote a line or a car type after playing.

## Steam short description
> You inherit Dad's run-down gaz bar in Saint-Clin-Clin, Québec. Gaétan opened across the road. Pour gas from the sky onto the cars on your lot, top each one off to the cent, chain perfect fills, and win the whole village back — before the fuel truck's bills bury you.

Character count: 270

## Genre
- **Genre:** roguelite, arcade skill game
- **Sub-genre:** short-run "number go up" with a build layer (Bills Must Be Paid, Balatro, 9 Kings)

### Convention ledger
| # | Convention players expect | Honor / Twist / Break | Our version | Why |
|---|---|---|---|---|
| 1 | Run ends in win or loss | Honor | Win at 100% market share; lose broke or at 0% | Clear goal |
| 2 | Between-rounds shop | Honor | The night's SHOP (cash tree) | Familiar build layer |
| 3 | Second currency for upgrades | Twist | XP earned **and spent** in the run (THE GARAGE) | Makes chaining matter |
| 4 | Meta progression between runs | Break | None: each run stands alone (round 11) | Three upgrade layers confused players |
| 5 | Timing / stop-the-meter mechanic | Twist | A god-sized nozzle over moving cars, a ring to aim, a fill to top off | The theme makes the mechanic |
| 6 | Rent / escalating bill | Twist | The fuel truck: full tank or nothing, each delivery deals rule-changing cards | Tension between saving and calling early |
| 7 | Enemy waves of rising difficulty | Twist | Car types unlock by the run's XP (a difficulty ladder) | Variety that challenges the fill |

Ratio: Honor ~30% · Twist ~55% · Break ~15% (more innovative than the 60/40 target; the core loop is proven fun, so the risk is accepted).

## Forms of fun (Garneau's 14)
| Rank | Form | The moment the player feels it | Mechanic that delivers it | How a playtest measures it |
|---|---|---|---|---|
| Primary | Application of an ability | "TOPPED OFF!" on a moving car | Hold, aim the ring, let go at F; grades | Share of Good+ fills; player comments |
| Primary | Advancement / completion | The market bar sweeps up at night; a new nozzle | Market share, the Shop, the Garage, car ladder | Does the player want "one more night"? |
| Secondary | Comedy | A bumper car knocks the line; Dad's line on the report | Car types, regulars, visitors, lore | Laughs, quoted lines |

**Deliberately avoided:** story-heavy play and fine-grained rhythm precision (the game is generous to the eye, not frame-perfect).

## Audience
- **Primary player:** fans of short roguelite runs (Balatro, Bills Must Be Paid, 9 Kings), on Mac or PC, 20–60 minute sittings.
- **What would make them stop:** idle-watching (drones doing everything), unclear goals, a run that feels lost early.

## Perspective
- 2D, cartoon drawn in code; one fixed top-down-ish view of the lot, road and Chez Gaétan.
- Why: the whole lot and every car must read at once.

## Game modes
| Mode | MVP? | Notes |
|---|---|---|
| Single-player run | Yes | Win at 100% share |
| First-day tutorial | Yes | Teaches by doing |

## Tone and themes
- **Tone:** warm, tongue-in-cheek, small-town Québec — **never:** mean, cynical, crude.
- **Themes:** inheriting a father's craft; winning a community back. Lore bible: docs/LORE.md.

## Look, sound and feel
- **Look:** bright 2D cartoon drawn in code (docs/02-art-bible.md).
- **Sound:** plain SFX + looping background music (docs/03-audio-bible.md).
- **Feel:** the pour is tactile; reveals land like opening a pack.

## Monetization
- Model: premium, one-time purchase (assumed; not decided).

## Platform, engine, performance
- Platforms: Mac and PC; a web build for playtests. Windows installer parked.
- Engine: Godot 4.7.2, typed GDScript.

## Key risks
1. Difficulty: is 100% hard enough for a skilled player (bot: 1 win in 24)?
2. The title: "Gaz Bar Blues" is a 2003 Québec film; GOD PUMP needs a name check before release.
3. Code size: the day scene (god_pump.gd) is 2,300 lines.

## Prototype questions
All answered before the studio method (the core loop was declared fun on 2026-10-19; the god pump kept on 2026-10-20). See docs/playtests/PLAYTEST_LOG.md.
