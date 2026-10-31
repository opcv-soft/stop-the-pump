# GOD PUMP — Game Design Document

> Living document. Owner: Game Designer. Numbers live in code data (`scripts/god/god_data.gd`); this document says what they mean.
> Condensed on 2026-10-31 from the pre-studio design (v0.48.0). Full history, every past decision and its evidence: docs/archive/DESIGN_history.md §11 (Decision Log), docs/archive/ROUND_*_PLAN.md, docs/playtests/PLAYTEST_LOG.md. Agents don't read the archive unless a question needs the history.

## Changelog
| Date | Section | Change | Decision record |
|---|---|---|---|
| 2026-10-31 | All | Rebuilt from DESIGN.md and the round 10–11 plans (state of v0.48.0) | 0001 |

---

# Play

## B1. Core loop
*Status: Reviewed (playtests 9–12)*
- **Moment-to-moment (seconds):** a car drives around the lot; hold to pour from the God Pump inside the ring, let go near the top. The fill is graded.
- **Session (one day, ~30–70 s):** the store opens (OUVERT), cars arrive by the car ladder, chains build and break, closing pays every coin into the register (FERMÉ), the day report reveals itself.
- **Night:** THE SHOP (cash tree), THE GARAGE (this run's XP), the fuel truck (and its cards), the car codex. Then open the next day.
- **Run:** many days until 100% market share (win), or broke / 0% share (loss). Nothing carries over between runs except lifetime stats.
- Loop: pour → grade + coins + chain → cash and XP → Shop / Garage / truck → harder cars → pour.

## B2. Objectives and goals
- Short-term: top off this car; keep the chain alive.
- Mid-term: a good day (cash for the Shop, XP for the Garage, reputation for the share).
- Long-term: push market share from 50% to 100% against Gaétan.
- Win: 100% share. Lose: broke (tank dry and can't pay the truck) or 0% share.

## B3. Player actions (verbs)
| Verb | What it does | Feedback | Combines with |
|---|---|---|---|
| Pour | Hold to pour into the car under the ring | Stream, fill gauge, glug | Aim |
| Aim | Move the ring onto a car | Ring highlight | Pour, auto-aim |
| Let go | Ends the fill; graded | Grade pop, coins, regulars react | Chain |
| Buy | Shop (cash) / Garage (XP) | Props pop in on the lot | The run's build |
| Call the truck | Full tank (or what cash buys if dry); pick a card | Delivery scene, card choice | Cash vs tank tension |

## B4. Control scheme
| Verb | Mouse/keyboard | Gamepad | Touch |
|---|---|---|---|
| Aim / pour | Mouse move / hold left button | N/A — not planned | N/A — not planned |
| Skip a reveal | Enter | | |
Designer keys: I (views), F1 dev mode, F3 end day, F4 +$100, F6 +10,000 XP.

## B5. Game mechanics (rules)
- **Grades** (on the fill when the stream leaves the car): TOPPED OFF (99.5%+, no spill) · PERFECT (97%+) · GOOD (90%+) · OK (80%+) · MISS (overfilled, or under 80% at closing).
- A car leaves once past 80% with nothing pouring into it.
- **Chain:** consecutive Good-or-better fills; each chain is worth the sum of its multipliers (1+2+3 = 6). An OK or a Miss breaks it.
- **XP = litres × the sum of the day's chains × accuracy.**
- **Closing:** every coin on the lot (and what unserved cars owe for what they got) flies to the tray, then the register.

## B6. Interaction systems
Drones (bought in the tree) fill cars on their own and burn gas; a drone hovers while the player pours on its car. Regulars react to grades (applause, AYOYE). Lore visitors arrive on set days (scripts/god/visitors.gd).

---

# Systems

## C1. AI and behaviour
Cars follow paths around the lot with patience; each car type bends one rule (e.g. Le Pressé: little patience, tips ×2.5; L'Auto tamponneuse: knocks cars out of the ring; Le Mastodonte: huge orders). Gaétan's push grows day by day.

## C2. Combat system
N/A — because there is no combat.

## C3. Abilities
The nozzle ladder (Garage): Le Classique → Le Costaud → Le Chromé → Le Turbo → La Dorée; each faster with a bigger ring, plus one perk. Bling and perks: bought once with XP, always on.

## C4. Economy
| Resource | Sources | Sinks | Converts to | Cap |
|---|---|---|---|---|
| Cash | Sales, tips, coins at closing | The Shop, the fuel truck | Upgrades, gas | — |
| XP | Chains (litres × chains × accuracy) | The Garage | Nozzles, bling, perks | — |
| Gas (tank) | The truck (full tank only, unless dry) | Cars, drones, spills | Sales | Tank size |
| Reputation / share | Good fills (Topped off counts most) | Gaétan's push | Market share (≤ 5 points a night) | 0–100% |

## C5. Reward structure
Grades pay tips; chains pay XP; the night reveals the share bar; each delivery deals a choice of rule-changing cards (Happy hour, Chaîne dorée, Double jet, Pacte avec le diable…). A new car type is a card reveal.

---

# Progression

## D1. Progression system
In-run only: the Shop tree (hours, marketing, attractions, nozzle/drones, service, vibe, spills), the Garage, truck cards. No meta progression (decided round 11).

## D2. Difficulty and its progression
The car ladder: 13 car types unlock by the XP earned in the run (spent or not), from the Berline to the Trio elétrico. Gaétan's push rises daily. Target: the balance bot (an average player) wins about 1 run in 25; a skilled player has to work for 100%.

## D3. Pacing
Day 1 is short (closes at 13 h); the HOURS branch extends to 23 h. Reveals (closing, report, new car) give rest beats between frantic days.

## D4. Variety
Car types, truck cards, the tree's branches, visitors.

---

# World and narrative

## E1. Story summary
Dad was the best gas man in Saint-Clin-Clin for thirty years. His hands started to shake; Gaétan opened across the road and took half the village. Dad hands you the God Pump: "Win them back, kid. All of them." Full bible: docs/LORE.md.

## E2. Key events
| # | Event | Trigger | Player feels | Changes |
|---|---|---|---|---|
| 1 | Intro | New run | Purpose | — |
| 2 | First-day tutorial | First run | Competence | Taught once, saved |
| 3 | Visitors | Set days | Belonging, comedy | Lore |
| 4 | Ending | 100% share | Triumph | Run won |

## E3. World-building
See docs/LORE.md.

## E4. Level design
One lot: the road, your gaz bar, Chez Gaétan across the road. Upgrade props pop in on the lot.

## E5. Environment types
N/A — one location by design.

## E6. Key challenges
Moving cars, rule-bending car types, keeping a chain, the tank vs cash tension.
