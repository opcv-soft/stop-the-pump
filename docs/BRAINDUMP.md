# GOD PUMP: the full braindump (hand-over to the new studio project)

> **Written 2026-10-31, when stop-the-pump was sunset at v0.48.0.** This is everything the old project learned, in one file, so a brand-new studio project can rebuild GOD PUMP cleanly without losing anything. The old repo stays as a read-only reference: `~/Games/stop-the-pump` and https://github.com/opcv-soft/stop-the-pump (`main` = v0.48.0).
>
> **Summary**
> 1. **The game:** pour gas from a god-sized nozzle onto cars driving around your lot in Saint-Clin-Clin, Québec. Top each car off to the cent, chain good fills for XP, and win the village back from Gaétan across the road (100% market share wins; 0% or broke loses).
> 2. **Proven fun (Director only):** aiming the nozzle, the cash drop, the truck tension (refuel early for cards, or late for a lower price), two-parent upgrades, the tube man, the ring, the day report.
> 3. **Failed or cut:** exact-stop scoring, upgrade downsides, random shop offers, the newspaper, speech bubbles over the pour, meta progression, music engineering, five art directions.
> 4. **Never tested:** a single outside player. Every one of the 30+ playtests was the Director alone.
> 5. **Why rebuild:** the code works (184 tests) but grew without architecture (the day is one 2,315-line file, with four views kept alive at once). The design is settled enough to rebuild cleanly.
> 6. **How:** §1 is the click-by-click start. §2–§4 are the full spec with every number. §5–§6 say what to keep and what not to repeat. §12 has the brief order for the rebuild.

---

## 1. How to start the new project (click by click)

1. **Close this old session.** If you want, rename the old folder to `stop-the-pump-old` in Finder (*Finder → Games → right-click stop-the-pump → Rename*). Do it only after closing every Claude session that uses it.
2. **Open a new Claude Code session in `~/Games`** and run:
   ```
   /studio:new-game GOD PUMP
   ```
   - Suggested slug: `god-pump`, at `~/Games/god-pump`.
   - Private GitHub repo: yes. The old one is `opcv-soft/stop-the-pump`, so create the new one in the same organisation if you want them side by side.
3. **Open a new session in the new folder** (`~/Games/god-pump`), so its `CLAUDE.md` and hooks apply.
4. **Copy the inheritance in.** Ask the Lead to run the copy list in §13. It brings over this file, the lore, the translations, the music and sounds, and the look test.
5. **Run the kickoff with this file as the pitch:**
   ```
   /studio:kickoff docs/inheritance/BRAINDUMP.md
   ```
   - Tell the Lead: *"This is a rebuild of a game already playtested 30+ times. Pre-fill the concept card from §2 and §5 of the braindump; challenge only what the evidence doesn't settle."*
   - The concept card should take one session, not several.
6. **Gate G0** (`/studio:gate`), with the prototype questions in §12.
7. **Prototype stage:** use **the old v0.48.0 build as the prototype**; no new prototype code is needed. Play it with **3+ outside players** (`/studio:playtest`). This is the one thing the old project never did.
8. **Gate G1**, then milestone **M1 Vertical Slice**: rebuild cleanly, brief by brief, in the order of §12.
9. **Archive the old GitHub repo** once the new one is running, so nobody pushes to it by mistake:
   - *github.com/opcv-soft/stop-the-pump → Settings → scroll to the bottom → Archive this repository → type the name → confirm.*
   - It stays readable.

---

## 2. Identity (paste into the concept card)

| | |
|---|---|
| **Title** | GOD PUMP (earlier: STOP. THE. PUMP., then Gas Bar Blues). Publisher: **OPCV Games**. |
| **Mantra** | Top them off to the cent, win the village back. |
| **X meets Y, but Z** | A Bills Must Be Paid roguelite meets an arcade pour-and-stop, but you pour gas from the sky onto cars driving around your lot. |
| **Steam short description** (270 characters) | You inherit Dad's run-down gaz bar in Saint-Clin-Clin, Québec. Gaétan opened across the road. Pour gas from the sky onto the cars on your lot, top each one off to the cent, chain perfect fills, and win the whole village back — before the fuel truck's bills bury you. |
| **Genre** | Short-run roguelite, arcade skill, with a "number go up" build layer. Comparables: Bills Must Be Paid (the biggest influence: rounds of 15–45 s, the tree, the smash-and-coins payoff), Balatro (cards that bend rules), 9 Kings, Ball x Pit. |
| **Platforms** | Mac and PC, mouse. A web build for playtests. Windows installer tooling exists (NSIS) but was parked "until the game is stable". |
| **Engine** | Godot 4.7.2, typed GDScript. |
| **Tone** | Warm, tongue-in-cheek, small-town Québec. **Never** mean, cynical or crude. English interface, French names and Québécois flavour ("AYOYE", "Câlisse", "ces gars-là l'ont pas"). |
| **Monetization** | Premium (assumed, never decided). |

### Pillars (as they emerged from the playtests)
1. **The fill is the skill.** Hold to pour, let go at F; the closer to 100% without spilling, the better. *Test:* players talk about their fills, not their upgrades.
2. **Chains pay for everything.** Chains of Good-or-better fills earn the XP that buys the Garage. *Test:* players change how they pour to keep a chain alive.
3. **Small-town comedy with a heart.** Saint-Clin-Clin, Dad, Gaétan, the regulars, the car types. *Test:* players quote a line or a car after playing.

A fourth candidate the Director loved and the next team should protect: **the truck tension.** *"The tension between refuelling now to get an upgrade and refuelling later to buy more gas at a lower price is crazy good."* (2026-10-21)

### Forms of fun
- **Primary:** application of an ability (the fill), and advancement (the share bar, nozzles, the tree).
- **Secondary:** comedy (car types, regulars, visitors, Dad).
- **Avoided:** story-heavy play; frame-perfect rhythm precision.

---

## 3. The rules, complete (state of v0.48.0)

### 3.1 The day
- **Opening:** the store opens at 7 h with a big OUVERT sign swinging in. A game hour lasts **4.5 real seconds**. Day 1 closes at **13 h** (27 s); the HEURES branch extends it up to 23 h (72 s). The **day bar** across the top fills from opening to closing.
- **Traffic:** cars drive both ways on the avenue. Those that want gas show a low gauge (a red E) and pick **you or Chez Gaétan by your market share** (×1.1 more cars want gas than before the rival existed). Gaétan's customers visibly pull into his station across the road, wait by a pump and leave full. At most **5 cars** are in your lot at once.
- **Cars in the lot** move in readable patterns: **loop** (75 px/s), **shuttle** (95), **park-and-go** (110), **bounce** (120, the bumper car). Default patience is **24 s** (× the car type's patience × upgrades); past it the car leaves.
- **The nozzle:** the mouse aims the God Pump. A **ring** on the ground shows its reach (radius ≈ 32 px on a 1152×648 canvas, plus the nozzle's bonus).
  - No car in the ring: the gas spills on the lot as a puddle (wasted gas, out of your tank).
  - One car: it fills.
  - With Double/Triple jet: up to 2–3 cars in the ring fill at once, each at full speed.
- **Flow:** $4 of gas per second at the base (×the nozzle's speed). Pump price **$2/L**.
- **Leaving:** a car leaves once it's **past 80% and nothing is pouring into it**. A drone hovers while you pour on its car, and letting go of a car a drone fills doesn't send it off.
- **Closing (FERMÉ):** every coin still on the lot flies to the tray, then into the register. Cars still under 80% pay for what they got and count as Unserved.

### 3.2 Grades (judged when the stream leaves a car)
| Grade (on screen) | Rule | Tip | Reputation | Chain |
|---|---|---|---|---|
| TOPPED OFF! (code: Super Perfect) | fill ≥ 99.5%, spill ≤ $0.25 | max tip + $2 top-off bonus | +1.8 | climbs |
| PERFECT | fill ≥ 97% | high | +1.1 | climbs |
| GOOD | fill ≥ 90% | some | +0.5 | climbs |
| OK | fill ≥ 80% | none | 0 | **breaks** |
| OVERFILLED (code: Miss) | spill > $0.25 | none | −0.75 | **breaks** |
| UNSERVED | left under 80% (patience or closing) | none, no XP, not counted in accuracy | −0.5 | — |

- **Tip curve:** 0 below 90%, then `max_tip × ((fill − 0.9) / 0.1)^1.5` with max_tip = **$6**, plus the $2 top-off bonus at ≥ 99.5%.
- **Tip multipliers:** car type, shop, cards, happy hour, loyalty, night neons, golden/jackpot procs. A car a drone touched **never tips** (it still pays for its gas).
- **Sale:** what the car asked for (never more) × the car's pay share × sale multipliers, + per-car bonuses.
- **Accuracy (for the report and XP):** `1 − |amount + spilled − target| / target`.
- **The regulars react:** everyone throws their arms up for a top-off and applauds a Perfect. The neon flashes like a pinball machine on Good or better.

### 3.3 Chains and XP
- A **chain** is consecutive Good-or-better hand-poured fills. Each fill in a chain pays its step's multiplier (×1, ×2, ×3…, capped at **×5**; Radio bluesy, Juke-box, Flammes and Chaîne dorée raise the cap, up to ×8 with the card).
- **A chain is worth the sum of its multipliers:** x1+x2+x3+x4 = 10. One long chain beats several short ones (one chain of 6 = 1+2+3+4+5+5 = 20 at the ×5 cap, against three chains of 2 = 9).
- **XP for the day = litres put in cars × the sum of the day's chains × the day's accuracy.**
- **On screen:** the combo pill swells with each step, burns hotter, gets flames from ×3 and shakes grey when it breaks. Under it: "CHAIN 1+2+3 = 6" and "TODAY n combo"; a broken chain's value flies into today's total.
- The XP formula changed **four times in one day** (2026-10-25) before landing here. Don't reopen it without evidence.

### 3.4 Money on the lot
- Coins drop out of a paid car, bounce and rest on the lot for a few seconds (drawn **under** the cars), then fly to the tray's four stacks, bottom right.
  - Colours: $1 blue, $5 green, $20 red, $50 purple.
  - No labels on the stacks.
- The register reads **CASH** with the amount, and TODAY +$X over the tray. The old vintage pump at the left reads **TANK** with a percentage.
- **Closing like opening a pack:** the stacks pour into the register (ka-ching). The report opens while the coins still pour: rays burst, the panel pops, the share bar sweeps, numbers count up, the four columns pop in one by one (2 s; Enter skips).

### 3.5 The run
- **Start:** $60 cash, tank of **$700 of gas** (350 L), full (Dad's last delivery), share 50%, reputation 50.
- **Each night**, after the report:
  - **Reputation** += the day's reputation (per car, ×the car type's rep_mult) + card bonuses − **Gaétan's push** (0.5 + 0.03 × (day − 1), halved by Espion chez Gaétan). Clamped 0–100.
  - **Market share** moves toward reputation by **at most 5 points a night** (people switch slowly).
  - **Win:** share 100%. **Lose:** share 0% (Gaétan has the whole village), or **bankrupt** (tank dry and cash < the smallest delivery, $20).
- **No meta progression.** Every run starts fresh; only lifetime stats, language and the station's name are saved (`user://godpump_meta.cfg`).

### 3.6 The fuel truck (the bill)
- Called at night from the **GAS TANK** panel: an industrial tank with a sight glass and dial. A delivery plays a 2.5 s scene: the tanker (Pétroles St-Clin, number 31) backs in, the hose connects, the tank fills, the price ticks up, the truck leaves.
- **Full tank or nothing.** If the tank is dry, the truck brings whatever the cash buys (at least $20), so a forgotten truck never ends a run by itself. (A real dead end in playtest 7 forced this.)
- **Wholesale price** starts at **$1.20/L** (pump price $2/L) and rises **25% per delivery** (slowed by Contrat du fournisseur, doubled by Pacte avec le diable, frozen by Gel des prix or Contrat à terme's turn).
- **Each delivery of half a tank or more deals cards: choose 1 of 3** (4 with Plus de choix; rerolls with Rebrasser).
  - Rarity weights: common 70, rare 25, legendary 5. Luck tilts them.
- A **red night warning** shows when the tank won't last tomorrow, and buying an upgrade that would leave too little for the truck takes a second click.

### 3.7 Truck cards (round 11: each one bends a rule)
| Card | Rarity | Effect |
|---|---|---|
| Combo béton | common | an OK no longer breaks your chain |
| Économiseur | common | spills waste half as much gas |
| Happy hour | common | tips ×3 for the first 2 hours of each day |
| Clientèle patiente | common | cars wait twice as long |
| Rumeur au village | common | +1 reputation every night |
| Double jet | rare | the nozzle fills one more car at once |
| Espion chez Gaétan | rare | Gaétan's nightly push halved |
| Chaîne dorée | rare | chains climb 3 higher (to ×8) |
| Gel des prix | rare | next delivery doesn't raise the price |
| Drone en prime | rare | +1 drone nozzle |
| Pluie de pièces | rare | every Topped off drops a $20 coin too |
| Boyau doré | legendary | 10% of fills are golden: tip ×3 |
| Recycleur | legendary | spilled gas flows back into the tank |
| Pacte avec le diable | legendary | tips ×2, gas prices rise twice as fast |
| Double ou rien | legendary | a Topped off tips ×3; an Overfilled car pays nothing |
| Vol de clients | legendary | 1 car in 3 heading to Gaétan's turns into your lot |

### 3.8 The night: THE SHOP (cash; a Bills-style radial tree)
The tree has the station in the centre and branches radiating out, each with its own bright colour. Every upgrade **pops in as a prop on the lot** the next morning.

| Branch | Nodes, in order (price) |
|---|---|
| **HEURES** | Thermos de café: open until 14 h ($60) · Maman fait le dîner: 16 h ($140) · Permis du soir: 19 h ($260) · Cousin Réjean de nuit: 23 h ($420) |
| **MARKETING** | Flyers: +1 car waiting at opening ($50) · Pub à la radio: +2 ($120) · Panneau: +3, and more cars pull in ($240) |
| **ATTRACTIONS** | Feu de circulation: more cars pull in ($90) · Mini-épicerie: +$2 a car ($160) · Lave-auto: +$4 a car, cars wait 30% longer ($300) · Machine à loto: 5% chance of a $20 tip ($380) |
| **PISTOLET** | Visée auto I: the stream bends toward a nearby car ($100) · Visée auto II ($260) · Drone pistolet ($340) · Drone pistolet II ($520) |
| **MULTI-JET** (off Visée auto I) | Double pistolet: two cars at once ($220) · Triple pistolet ($460) · Chien de berger robot: every 12 s a robot dog herds customers round the nozzle for 2.6 s ($520) |
| **SERVICE** | Pancarte pourboire: tips +20% ($60) · Raclette: +$2 on Perfect or better ($140) · Café pour la file: cars wait 30% longer ($220) |
| **AMBIANCE** | Radio bluesy: max chain +1 ($80) · Banc des habitués: each applause +$1 ($170) · Juke-box: max chain +1 ($300) |
| **RÉSERVOIR** | Gros réservoir: +$200 tank ($120) · II: +$200 ($240) · III: +$300 ($400) |
| **DÉGÂTS** (off Gros réservoir) | Litière à chat: spills waste 25% less ($120) · Aspirateur gonflable: a blue tube man sucks up a puddle every 4 s, 70% back in the tank ($260) · Bec anti-goutte: a drip under 50¢ isn't Overfilled ($380) |
| **CAMION** | Jauge d'alarme: days of gas left, to the hour ($40) · Achat en vrac: −10% when the tank is under 25% ($150) · Citerne usagée: a partial delivery raises the price half as much ($220) |

**Two-parent upgrades** sit between their parents' branches and open once you own both. *"The two-parent upgrades are great."* Branch order around the tree matters, because linked pairs must sit side by side.

| Upgrade | Needs | Effect | Price |
|---|---|---|---|
| Fenêtre au volant | Café + Thermos | a car that waited over 3 s buys a coffee: +$1 | $150 |
| Soirée du hockey | Maman fait le dîner + Radio bluesy | every 7th day: 3 more cars waiting, more pull in | $200 |
| Carte fidélité | Pub à la radio + Pancarte pourboire | every 5th car tips double | $180 |
| Néons de nuit | Permis du soir + Juke-box | tips +30% after 19 h | $320 |
| Hangar à drones | Drone pistolet + Lave-auto | a drone fill earns $2 more | $300 |
| Cantine à patates | Mini-épicerie + Banc | cars wait 20% longer, applause +$2 | $260 |
| Prix affiché | Panneau + Gros réservoir | every sale +5% | $280 |
| Sabot de Denver | Achat en vrac + Visée auto I | thieves get clamped, stolen gas comes back | $260 |
| Sabot de Denver II | Sabot de Denver + Citerne usagée | a customer about to give up is clamped and waits longer | $420 |
| Contrat à terme | Gros réservoir II + Panneau | every 4th delivery without a price rise | $480 |

### 3.9 The night: THE GARAGE (this run's XP)
- **The nozzle ladder** (bought in order; each replaces the last):

  | Nozzle | XP | Effect |
  |---|---|---|
  | Le Classique | start | Dad's old nozzle. Honest. |
  | Le Costaud | 600 | speed ×1.2, ring +8; a top-off pays $2 more |
  | Le Chromé | 1,800 | speed ×1.4, ring +16; a drip under 50¢ isn't Overfilled |
  | Le Turbo | 3,600 | speed ×1.6, ring +24; the stream bends toward cars nearby |
  | La Dorée | 6,400 | speed ×1.8, ring +32; 10% golden fills (tip ×3) |

- **Bling** (bought once, always on; each piece is drawn on the nozzle, and every piece adds a gold ring or bracelet round the handle, "like a hand full of rings"):

  | Bling | XP | Effect |
  |---|---|---|
  | Dés en minou | 500 | luck +10 |
  | Sapin parfumé | 700 | cars wait 20% longer |
  | Danseuse hula | 800 | first car of each day tips double |
  | Livret de coupons | 1,000 | shop 10% cheaper |
  | Flammes | 1,200 | max chain +1 |
  | Médaille de saint Christophe | 1,400 | once a day an overfill doesn't break the chain |
  | Bobblehead | 1,600 | +5% tip per chain step |
  | Patte de lapin | 1,800 | every 10th car's gas back in the tank |

- **Perks** (tiers; each tier costs price × tier; each owned perk stands on the lot as a prop):

  | Perk | Price | Tiers | Effect |
  |---|---|---|---|
  | Bonne étoile | 400 | 4 | luck +5 (horseshoe over the door) |
  | Rush du matin | 600 | 3 | +1 car waiting at opening (rooster on the roof) |
  | Rebrasser | 800 | 2 | 1 reroll per delivery |
  | Contrat du fournisseur | 1,000 | 3 | prices rise 20% slower (framed contract) |
  | Super sans plomb | 1,000 | 3 | sales +10% (gold SUPER sign) |
  | Jackpot | 1,200 | 2 | 3% of fills tip ×4 (slot machine) |
  | Bonhomme gonflable | 1,400 | 2 | a tube man grabs passing cars, siphons their gas into your tank; tier 2 drops them on your lot as customers (*"Tube man feels very fun hahaha"*) |
  | Plus de choix | 2,000 | 1 | 4 cards per delivery |

- The night also has the **CAR CODEX**: every type drawn, its rule and its XP; unlocked ones are lit.

### 3.10 The car ladder (unlocks during each run by the XP earned in it, spent or not)
| Car | XP | Rule |
|---|---|---|
| Berline | 0 | the everyday car; orders $10–30 |
| Le Pick-up | 60 | huge order ($40–60), pays 80% |
| Le Cadillac | 160 | tips ×2 |
| Le Bazou | 320 | its tank takes gas at 60% speed |
| Le Char de course | 520 | drives fast (×2.2), tips ×1.3 |
| Le Pressé | 760 | patience ×0.4, tips ×2.5 |
| La Balayeuse | 1,040 | not a customer: cleans puddles it drives over |
| L'Auto tamponneuse | 1,360 | bounces off curbs, knocks cars out of your ring; tips ×1.2 |
| Le Voleur | 1,720 | not a customer: siphons gas from customers; pour on it to scare it off |
| Le Maladroit | 2,120 | bumps cars, who spill a quarter of their gas |
| Le Mastodonte | 2,560 | a tanker: $100–150 orders, straight lines, takes gas ×1.8 |
| L'Électrique | 3,040 | doesn't take gas: pour on it and pay a $10 fine |
| Le Trio elétrico | 3,600 | a samba truck: reputation ×5 both ways, an overfill costs $20 |

- A new car type gets a **card reveal**: rays, the car spinning in, its name and rule.
- The report says what comes next.
- *"New car types read as a difficulty ladder that adds variety"*: intended.

### 3.11 Automation
**Drones** (from the tree and cards) are the automation:
- Little quadcopters that fill cars on their own (2.2 $/s, 260 px/s), to a good-but-not-perfect level.
- They burn **$0.30 of gas a second** from your tank while they fly or pour.
- They earn no chain, and the cars they touch don't tip.

The old 9 Kings "auto-battler by a third of the run" arc was dropped with the pivot.

### 3.12 The lot, the people, the lore on screen
- **The regulars** (Ti-Guy, Mme Gagnon, Bertrand, Le Grand) have routines: bench, smoke, a coffee inside, watching the lot. They **don't speak during the day** (playtest 9: bubbles stole focus); they walk, hop, cheer and applaud from the store's side.
- **Visitors** drive in on set days and chat in small, faded, wordless bubbles in the lot's corner. Their lines are shown beside the day report (OVERHEARD TODAY):
  - Gaétan: days 2, 18, 40
  - Papa: days 3, 15, 25
  - Sylvie: days 5, 21
  - Cousin Réjean: days 7, 35
  - Me Tremblay: days 9, 30
  - The curé: day 12
- **The lot:** the gaz bar with its flickering red GAZ BAR neon, an ice machine, an AIR 25¢ pump, a propane cage, newspaper boxes, a picnic table, a phone booth, a moose-crossing sign, cows, the church steeple, and Chez Gaétan across the road. The player names the station at the start of a save; the name goes on the pylon sign.
- **Intro** (skippable; in-engine, not a video): mock-biblical. *"In the beginning, there was gas."* Clouds part, a choir swells, the golden nozzle descends, and the title slams in. Then Dad's story (§9).
- **Ending:** 100% share. Gaétan turns off his sign, the village cheers, and Ti-Guy cries. Dad stands up, hands steady for once: *"To the cent, kid. TO THE CENT!"* He laughs so hard his heart gives out, and dies the happiest gas man in Québec. Credits.
- **First-day tutorial** (teaches by doing; the clock is held, never more than 30 s a step; saved once done):
  1. Hold to pour; the ring is where the gas goes.
  2. Let go at F; past 80% the car pays and leaves.
  3. Make a chain of two.
  4. A chain is worth the sum of its steps; an OK or overfill breaks it.
  5. Red-E cars want gas; good fills win them from Gaétan.
  6. The day bar.
  7. Tonight: cash buys THE SHOP, XP buys THE GARAGE.

### 3.13 The day report
- **Header:** the market share bar (you vs Gaétan) sweeping with the change, reputation, the cars that went to Gaétan, and one line from Dad.
- **Columns:**
  - **The day:** grades, cars, accuracy, chain sum, XP shown as a sum ("120 L × 34 × 91% = 3,713 XP"), what car comes next.
  - **The books:** Today's results (revenue, costs, net profit or net loss; a deficit in brackets) and a real balance sheet (assets = cash + gas at cost + equipment; liabilities positive; equity = Dad's capital + retained earnings). *"No negative numbers in accounting."*
  - **OVERHEARD TODAY.**
- End of run: charts (price per delivery, cash per day) and lifetime stats on the menu.

### 3.14 Controls and designer tools
- **Mouse:** aim; hold to pour; let go to stop. **Enter:** skip a reveal. **ESC:** pause (volume slider, back to title).
- **Designer keys:** **F1** dev panel (cash, tank, day, XP, cars filled, game speed, NEXT NIGHT, END THE DAY, RESET SAVE with two clicks) · **F3** end the day · **F4** +$100 · **F6** +10,000 XP · **I** cycle views.
- **Rebuild with these from day one.** The Director asked for them every time they were missing: *"the designer can't test outcomes or tune numbers without asking Claude"* (playtest, v0.10).

---

## 4. Balance (where the numbers stand, and how they were found)

- **Tool:** a balance bot (`tools/sim/god_bot.gd`) plays **the real game headless**: the same simulation and rules as the player.
  - It chases cars at 900 px/s and reacts in 0.25 s.
  - It pours an even split of Topped off / Perfect / Good / OK / overfill.
  - At night it calls the truck when the tank won't last, buys the cheapest upgrade in a fixed branch order, buys nozzles first in the Garage, then contract and premium gas, and picks cards from a preference list.
  - Run: `godot --headless -s tools/sim/god_bot.gd -- 20 fresh`.
- **Target:** an average player (the bot) **wins about 1 run in 25**; a skilled player can reach 100% but has to work for it.
- **Last result (round 11, 24 fresh runs):** median 36 days survived; final share 3–100%, mostly 30–60%; **1 win**; 0 lost to Gaétan; about 11,400 XP a run.
- **What moved the needle (history worth knowing):**
  - The first round 11 pass won 12 of 16 runs: far too easy.
  - Cutting reputation further (1.4/0.9/0.4) gave 0 of 16: too hard.
  - The chosen middle is reputation 1.8 / 1.1 / 0.5, push 0.5 + 0.03 a day, share step 5, Garage prices ×2.
- **The price wall:** with partial deliveries and an 8% rise, every fresh save survived forever.
  - Rises tried: 14% (22/30 survive), 20% (2/30), 26% (0/30).
  - 25% chosen when day 50 was the goal.
  - Growing the business alone doesn't beat it: more sales mean more deliveries, so more rises.
- **Open:** whether 100% is hard enough for a *skilled human*. Never tested by anyone but the Director, and v0.48 was never played.

---

## 5. What the playtests proved (keep these)

| Kept | Evidence (Director's words) |
|---|---|
| Aiming a nozzle at moving cars (replaced hold-a-key-per-pump) | "Aiming is much better." "God Pump is 1000% the right direction." |
| Leave at 80%, tips growing toward 100%, overflow = waste | "Makes the juggling feel good and the animation makes you want to hit perfects." |
| Cash that drops out of the car and flies to your cash | "Cash drop is incredible now." Then, when it flew straight to a tray: the money "lost its weight". Coins must **rest on the lot** first. |
| The truck as the bill, with cards per delivery | "The tension between refuelling now… and later… is crazy good." "They create tons of tension." |
| A Bills-style radial tree | "This made the game much better. The tree looks great." "The tree def gives you a plan… just one more turn." |
| Two-parent upgrades | "The two-parent upgrades are great." |
| The tube man | "Tube man feels very fun hahaha." |
| The ring | "Ring makes aiming much better." |
| The day report | "The report works." |
| Regulars and neon | "The regulars and the neon make the place feel alive." |
| High three-quarter camera | "The three quarter angle is wonderful." (Now 2D cartoon with the same framing.) |
| Juice: stream, sparkle, shake, pop-ins | "Feels much better." "The shake is fun." "The new pump animations are great." |
| Glug sound + counter knocks | "The pouring sound is pretty funny now." (The clicky nozzle sound was "extremely annoying".) |
| Short days | "The days are too long" at 3 min. Bills runs 15–45 s rounds. |
| Combo/chain stakes | "Losing a x5 combo created real pressure." |
| Earning XP by playing better | "Earning XP is good." |

---

## 6. What failed or was cut (don't repeat without new evidence)

| Tried | Why it went |
|---|---|
| Exact-stop scoring (stop the pump on the dollar) with moving cars | Fights continuous juggling; "unclear what a Perfect achieved". |
| Rusty lever (a release delay) | A fixed delay is a constant offset learned once; a random one feels unfair. *Depth comes from juggling and readable variation, never hidden randomness in the player's own controls.* |
| Upgrades with gameplay downsides | "Downsides felt like punishments." Upgrades cost only money/XP. |
| Random shop offers (Balatro-style) | The Director wants a plan to work toward (a tree). |
| Customers with talking rules ($20 Guy, Confused Grandpa…) | A single fill didn't matter enough to adapt per customer. Car *types* with visible rules replaced them. |
| The auto-battler arc (self-service pumps, 1x/2x/3x, manual early → automated) | Belonged to the key-per-pump game; drones replaced it. |
| Music engineering (12-bar blues, notes per tier, chord tracking, beat-synced clicks) | "The music engineering isn't wanted." Plain SFX + looping music only. |
| The morning newspaper (L'Écho de Saint-Clin-Clin) | "The paper is not fun, it's too much info." Visitors replaced it. |
| Speech bubbles over the lot | "They prevent focusing on the game." |
| Poker chips flying straight to a tray | Money lost its weight; coins rest on the lot first. |
| Meta progression (Papa's Garage between runs, meta XP, day-50 goal) | Three upgrade layers confused; XP had nothing to buy in the run, so chaining stopped mattering. |
| Partial top-off deliveries | "Remove small gas top-offs." Full tank or nothing (unless dry). |
| Dad faked his death to go fishing (day-50 ending) | Replaced by the fight with Gaétan and the 100% ending. |
| Cousin's loan card | Confusing ("what is the cousin's loan?"). |
| Fire risk from overshoots | The cleaning delay already did the job (key-per-pump era). |
| Impressionist post-process, tilt-shift | "It doesn't help."; tilt-shift too strong. |
| Per-pump upgrade branches | Cluttered the tree (key-per-pump era). |

---

## 7. The path, in one table

| Date | Version | What happened |
|---|---|---|
| 2026-10-18 | v0.1–0.5 | STOP. THE. PUMP.: hold a key, stop the pump on the dollar. Combo kept; rusty lever cut. |
| 2026-10-19 | v0.6–0.29 | Gas Bar Blues: up to 10 pumps on keys 1–0, a day with a tank and a clock, customers, the blues, the tree, self-service and the auto-battler arc, the 3D Hopper station (Blender kit). The core loop was declared fun (playtest 8). |
| 2026-10-20 | v0.30–0.33 | The god pump prototype ("1000% the right direction") becomes the game; pixel art, three-quarter view, then HD-2D. |
| 2026-10-21 | v0.40–0.44 | Overnight build of the full GOD PUMP loop; round 8 (deeper tree, tube man, living lot, newspaper); round 9 (visitors, clamps, FR/EN, Windows installer). |
| 2026-10-25 | v0.45–0.47 | Round 10 (17 asks in five batches): the ring, coins, the rival and market share, the cartoon look, the car ladder and codex, spills, the dog. |
| 2026-10-25 | v0.48.0 | Round 11: one run with two currencies, the nozzle ladder, rule-changing cards, harder, the chain on screen, the tutorial, pack-opening reveals. **Never playtested.** |
| 2026-10-31 | — | Converted to the studio method, merged into `main` (opcv-soft/stop-the-pump PR 38), then sunset. |

---

## 8. Open questions and known gaps (put these in the new `docs/status.md`)

1. **Has any outside player ever played it?** No. Learnability, the tutorial and difficulty are unproven with strangers.
2. Is 100% hard enough for a skilled player (bot: 1 win in 24)?
3. Do the rule-changing cards pull hard enough to call the truck early?
4. Does the tutorial make the chain's point obvious?
5. Still unchecked from playtest 9: the wheel clamps, and one full run in French.
6. **The menus were never redrawn in the cartoon look:** night, report, title, garage, cards, truck and icons are still in the older pixel style (round 10 C pass 2).
7. Real sounds to replace the synthesized placeholders. Also no settings screen (volume, fullscreen) beyond the pause menu's volume slider.
8. **Title risk:** "Gaz Bar Blues" is a 2003 Québec film. GOD PUMP itself was never checked. Check before any public page.
9. **Music licence:** "Roadside At Two" was made with ElevenLabs Music; confirm the plan allows commercial use before release.
10. Parked ideas, so the Director can say "yes, later":
    - the piggy-bank car (swells as it fills, pops on the stop)
    - more car types (diesel, environmentalist)
    - gas price variation; inspections; bribing an inspector
    - tips as a personal third currency
    - the pump as a character; receipts
    - mobile
    - the Windows installer.

---

## 9. Story and lore (copy `docs/LORE.md` as is)

- **The place:** Saint-Clin-Clin-des-Meuh-Meuh, Québec. Population 412, more cows than that. A silver steeple, the rang, the avenue, your gaz bar and **Chez Gaétan** across the road.
- **The story:** Dad was the best gas man in the village for thirty years; he topped off to the cent. His hands started to shake, and Gaétan opened across the road and took half the village. Dad tried hiring: *"Ces gars-là l'ont pas."* (Those guys don't have it.) So he hands you the keys to the God Pump: *"Win them back, kid. All of them."*
- **Cast:**
  - **Dad:** alive, shaky hands, big heart; drives the old orange hatchback.
  - **Ti-Guy:** red plaid flannel, cap, moustache, dairy farmer, Dad's loudest fan.
  - **Mme Gagnon:** grey bun, pink cardigan, the gossip; her niece is Sylvie.
  - **Bertrand:** bald, suspenders, retired mechanic, Dad's best friend, dry.
  - **Le Grand:** very tall, leather jacket, mullet, plays in Les Pistons.
  - **Gaétan:** smug, cheap, never topped off a thing.
  - **Me Tremblay:** the notary.
  - **Cousin Réjean:** spilled on both of Dad's shoes; works nights once you can pay him.
  - **The curé:** prays for both stations.
  - **Pétroles St-Clin:** truck 31, prices only go up.
- **Running gag:** the village wonders whether the kid is single.

---

## 10. Art and audio direction (final)

### The look
- **2D cartoon drawn in code** (approved look test: `docs/art/look_test_cartoon.png` and `.svg`).
- Chunky cars with thick outlines: each car is one symbol whose body takes any colour, with a 4 px dark outline, one shade and one shine.
- Exaggerated effects, shiny loot, a clean high-contrast UI, a distinct colour per coin value, perk and tree branch.
- The world is drawn at 85% so Gaétan's station fits under the HUD.
- **Readability first:** every asset communicates an affordance (what you act on is saturated and lit; the world around it is muted). The ring, gauge and grade must read over any car, and coins never hide cars.
- Old reference: the late-80s small-town Québec style from the Director's reference photos (plaid flannel, denim, browns and beiges, an aluminium dépanneur storefront, red curbs, boxy sedans with square headlights, a red GAZ BAR neon). It still holds for the cast and props.

### Don't relitigate the look
It changed **six times in a week**:
1. Hopper low-poly 3D (Blender)
2. impressionist filter (rejected)
3. pixel art (claude-pxl)
4. isometric (rejected for three-quarter)
5. HD-2D
6. cartoon

Each switch left a view alive in the code; **I** still cycles four of them. **Build one view only.** Any new look starts as a single look-test frame the Director approves.

### Audio
- **Plain SFX + looping background music.** No music engineering unless the Director asks again.
- Music: "Roadside At Two" (92 BPM, B♭/D minor, ElevenLabs).
- Placeholders synthesized by `tools/make_godpump_sounds.py` (no samples): glug loop, counter knocks, grade stings, applause, register, horn, choir, truck, pop.
- The Director drops real files in `assets/audio/inbox/`; each gets a line in `CREDITS.md`.

---

## 11. Technology: what to keep, what to change

### Keep (patterns that worked)
- **Everything ownable is data:** branches, links, cards, car types, nozzles, bling and perks, each with an `fx` dictionary of effects.
  - A combiner (`FX_OPS`: add / mul / max) folds what you own into one `mods` dictionary that the day reads.
  - Balance is then a data edit, and the bot plays exactly what the player plays.
  - In the rebuild, put this data in `data/` (`.tres` resources or JSON), not in a script of constants.
- **Rules separate from scenes:** RunState (cash, tank, share, XP, truck, cards, the night's fight) has no scene code and is unit-tested. Keep that split, and push it further.
- **A headless balance bot that drives the real day simulation.** Build it as soon as the day and the run exist.
- **Snapshot tool:** saves one frame of a day in progress, to check layouts without playing (`tools/demo/snapshot.gd`).
- **Web build for playtests:**
  - The "Web" preset is single-threaded with the Compatibility renderer.
  - The engine and data are gzipped and unzipped by a custom page (`tools/web/godpump.html`), published as a claude.ai artifact.
  - The old artifact: https://claude.ai/artifact/EcEB3srrceAkaePKW8RHhL. Cheap to share; keep it for outside playtests.
- **Translations from day one:** every on-screen string goes through `tr()` with English keys in `locale/strings.csv` (keys, en, fr); 456 strings exist.
- **Version on the title screen**, bumped every build the Director plays.
- **Composition:** small component nodes (`combo_component`, `nozzle_bling`, `regulars_crew`, `tutorial`).

### Change (why the rebuild)
- **`god_pump.gd` is 2,315 lines.** It holds cars, the nozzle, grading, coins, closing, drones, the tube men, the dog, visitors, the HUD and four views. Split it from the start into systems:
  - nozzle and ring
  - car spawner and traffic (incl. Gaétan's side)
  - fill and grade
  - chain
  - coins and register
  - drones
  - lot helpers (tube men, dog, sweeper)
  - visitors
  - HUD
  - one view.
- **One view only** (cartoon). The HD-2D, pixel and flat views were kept alive "to compare" and cost every change.
- `cartoon_art.gd` (533 lines) draws everything. Split it per family: cars, people, props, lot.
- `run_state.gd` (415 lines): split the truck, the cards, the Garage and the share fight.
- **Respect the studio's `tools/arch_check.py` from brief 1** (300-line files, typed code, a pure `src/core/`).
- Key-per-pump leftovers: `ScoreTiers` still uses dollar windows from the old game, and `fuel_economy.gd` is old too. The rebuild should grade by fill fraction only (§3.2).

### Old file → what it is (to read while rebuilding)
| Old path | Content |
|---|---|
| `scripts/god/god_data.gd` | every number in §3 |
| `scripts/god/run_state.gd` | the run: truck, cards, Garage, share, books |
| `scripts/god/god_mods.gd` | folds owned items into `mods` |
| `scripts/god/meta_state.gd` | the save: lifetime stats, language, station name |
| `scripts/god/visitors.gd` | visitor days and lines |
| `scenes/god/day/god_pump.gd` | the day (all of it) |
| `scenes/god/day/proto_car.gd` | a car: movement patterns, fill, grade, accuracy |
| `scripts/components/cartoon_art.gd` | the cartoon look, drawn in code |
| `scripts/components/tutorial.gd` | the tutorial steps |
| `scenes/god/ui/*` | report, night, tree view, garage tab, codex, card pick, truck scene, cinematic, title, naming, dev panel, charts |
| `tools/sim/god_bot.gd` | the balance bot |
| `features/god_*.feature` | Gherkin specs of day, pump, run and shop |
| `tests/` | 184 GUT tests: good acceptance ideas, not code to copy |

---

## 12. Proposed studio plan for the rebuild

### Kickoff
The concept card comes straight from §2 (and pillars from §2, forms of fun, the convention ledger below). The seats should spend their challenge on §8, not on what §5 already proved.

**Convention ledger (draft):**
| # | Convention | Honor / Twist / Break | Ours |
|---|---|---|---|
| 1 | A run ends in a win or a loss | Honor | win at 100% share; lose broke or at 0% |
| 2 | A between-rounds shop | Honor | THE SHOP, a radial tree |
| 3 | A second currency | Twist | XP earned and spent in the run (THE GARAGE) |
| 4 | Meta progression | Break | none; each run stands alone |
| 5 | A stop-the-meter mechanic | Twist | a god-sized nozzle over moving cars |
| 6 | An escalating bill | Twist | the fuel truck: full tank or nothing, cards per delivery |
| 7 | Waves of rising difficulty | Twist | car types unlock by the run's XP |

### Prototype questions for G0
Answer them with the v0.48.0 build and outside players; no new code.

| ID | Question | Pass | Kill | Time-box |
|---|---|---|---|---|
| P01 | Does a new player understand the goal and the chain from the tutorial alone? | 3 of 4 outside players explain "keep chains to earn XP, win the village" after day 1 | most can't say what a chain is for | 1 week |
| P02 | Is a full run fun for someone who isn't the Director? | 3 of 4 want another run; fills are what they talk about | they stop before day 5, or talk only about menus | same week |
| P03 | Is the difficulty right? | skilled players reach 100% with work; average players lose around 30–60% | everyone wins, or nobody gets past 50% | same week |

### M1 Vertical Slice: brief order (rebuild cleanly; each brief ≤ 1 page)
1. **Skeleton:** project, folders (`src/core`, `data/`), arch_check, CI, `tr()` and `strings.csv`, version on the title, a dev console with F1/F3/F4/F6.
2. **The fill:** nozzle, ring, one car pattern, pour, spill, leave at 80%, grades, the tip curve. (The core: playtest it alone in grey before anything else.)
3. **The chain and XP on screen** (pill, chain sum).
4. **Coins:** drop and rest on the lot, the tray, the register, closing like a pack.
5. **The run:** RunState, the day clock, the report, the share fight with Gaétan, win/lose.
6. **The truck:** the gas tank, full-or-nothing deliveries, the price wall, cards.
7. **THE SHOP:** the data-driven tree with two-parent links, props popping in.
8. **THE GARAGE:** the nozzle ladder, bling on the nozzle, perks.
9. **The car ladder:** 13 types, the codex, the new-car reveal.
10. **Helpers:** drones, multi-jet, the herding dog, the tube men, the sweeper and thief rules.
11. **The balance bot,** then a tuning brief against the target (1 win in 25).
12. **The lot's life:** regulars, visitors, the lot props, Gaétan's station.
13. **Story:** title, naming, intro, ending, the tutorial.
14. **Art:** the cartoon look on every screen, menus included (the old gap).
15. **Audio:** real SFX, the music.
16. **The web build** for outside playtests.

**Scope warning:** the old project's biggest process problem was rounds of 10–17 changes built before one playtest. One brief, one playtest where it matters.

---

## 13. Files to copy into the new repo (the Lead runs these in the new folder)

```bash
mkdir -p docs/inheritance locale assets/audio/music assets/audio/placeholder docs/art
cp ~/Games/stop-the-pump/docs/BRAINDUMP.md docs/inheritance/BRAINDUMP.md
cp ~/Games/stop-the-pump/docs/LORE.md docs/inheritance/LORE.md
cp ~/Games/stop-the-pump/docs/glossary.md docs/inheritance/glossary-old.md
cp ~/Games/stop-the-pump/docs/playtests/PLAYTEST_LOG.md docs/inheritance/PLAYTEST_LOG-old.md
cp ~/Games/stop-the-pump/docs/balance/GOD_PUMP_BALANCE.md docs/inheritance/BALANCE-old.md
cp ~/Games/stop-the-pump/locale/strings.csv locale/strings.csv
cp ~/Games/stop-the-pump/assets/audio/music/roadside_at_two.mp3 assets/audio/music/
cp ~/Games/stop-the-pump/assets/audio/placeholder/*.wav assets/audio/placeholder/
cp ~/Games/stop-the-pump/tools/make_godpump_sounds.py tools/
cp ~/Games/stop-the-pump/docs/art/look_test_cartoon.png ~/Games/stop-the-pump/docs/art/look_test_cartoon.svg docs/art/
cp ~/Games/stop-the-pump/CREDITS.md docs/inheritance/CREDITS-old.md
```

- If the old folder was renamed, replace `stop-the-pump` with the new name.
- The code itself is **not** copied: the Programmer reads it in the old repo (§11) and rebuilds it under the new architecture.
- `strings.csv` is copied because its French translations are work worth keeping. Unused keys get pruned as the rebuild goes.

---

## 14. Process lessons (for the studio knowledge base)

1. **Get outside players early.** 30+ playtests, all by the Director. Learnability and difficulty were never measured on a stranger.
2. **One change per playtest is the rule that broke.** It worked brilliantly in playtests 1–8, then "rounds" of 10–17 changes (and one overnight build) made it impossible to tell which change helped.
3. **Lock the look with one approved frame before redrawing anything.** Six art directions in a week left four views alive in the code.
4. **A tuning formula that changes four times in a day needs a design calculator, not more builds.** A bot or spreadsheet model first, then one build.
5. **Data-driven items with an effect combiner, plus a headless bot that plays the real rules,** made balance passes cheap. Reuse this pattern.
6. **Watch for layered progression.** Three upgrade layers (tree, Garage, cards) plus meta XP confused the Director; one currency per layer, all in the run, fixed it.
7. **Dev keys and a dev panel pay for themselves immediately.** Build them in brief 1.
8. **Keep `main` playable.** All of GOD PUMP lived 51 commits ahead of `main` on a hypothesis branch until the very end.
