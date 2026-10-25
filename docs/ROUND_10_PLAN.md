# GOD PUMP: round 10 build plan (2026-10-25)

> From playtest 9 (v0.44.0). The designer asked for seventeen changes at once. The Committee split them into
> five batches, smallest risk first. Each batch: spec → test → code → tests green → the designer plays it.
> **DECIDED** marks a call the Committee made on the designer's behalf, to review at the playtest.

## Designer's calls (2026-10-25)
- **Market share is per run.** Every run starts 50/50 with Gaétan. Win at 100%. Lose if you go broke (the
  fuel truck stays) or fall to 0%. XP and the Garage carry over between runs.
- **Visitors stay**, driving in, parking and chatting, "but background, not attention-dividing".
- **Art: look test first.** One mock frame in the new style, approved before anything is redrawn.

## Batch A: fixes and focus (v0.45.0) — built 2026-10-25, awaiting playtest
1. **The nozzle ring** (and the broken Double jet). A ring on the ground shows where the nozzle reaches.
   - No car in the ring: the gas spills. One car: it fills.
   - With Double jet, two cars in the ring fill at once, each at full speed (twice the gas per second).
   - The bug: the second car filled but was never graded or paid. Now every car leaving the stream settles.
2. **Cars stay in front.** No money lies on the lot any more: coins pop out of the car and fly straight
   into the tray.
3. **Coins instead of bills:** $1 blue, $5 green, $20 red, $50 purple, poker-chip style. They stack in four
   poker stacks in a tray, bottom right. At closing the stacks slide into the cash register (ka-ching),
   then the report opens. (**DECIDED:** the sale and tip are rounded to the dollar for the coins; the cash
   stays exact.)
4. **The day bar:** a progress bar across the top, opening hour at the left end, closing hour at the right.
5. **The regulars step aside:** no speech bubbles. They keep to the store's side of the lot, walk, hop,
   cheer and applaud. **Visitors** park in the lot's corner by the store; their chat is shown as small
   faded bubbles with no words ("…", "!", "ha ha", "♪") and doesn't stop the regulars cheering. Their lines
   still go to the menu's scrapbook. (**DECIDED**)
6. **Drones burn gas:** each drone burns $0.30 of gas per second while it flies or pours, out of the tank.
   (**DECIDED**, to tune)
7. **XP = litres put in cars × combo points × accuracy**, for the day.
   - Litres: the gas that went into tanks (overflow and spills don't count).
   - Combo points: the sum of the combo multipliers paid on hand-poured Good-or-better fills.
   - Accuracy: the day's accuracy (0–100%).
   - The day report shows the sum: "120 L × 34 combo × 91% = 3 713 XP".
   - The Garage's prices are rescaled with the campaign bot (target unchanged: a first day 50 around 3 h).
   - **Risk to watch:** litres and combo points both grow with the cars served, so XP grows with the
     square of a day's size. Long late days will pay a lot more than short early ones.

## Batch B: the rival across the road — built 2026-10-25 (numbers in docs/balance/GOD_PUMP_BALANCE.md)
- **New lore** (docs/LORE.md rewritten): Dad was the best gas man in Saint-Clin-Clin, topping off to the
  cent; the village never needed a second station. Then his hands got shaky, and Gaétan opened across the
  road. Dad tried hiring: "ces gars-là l'ont pas." So he hands you the keys. He's alive, on the bench with
  the regulars.
- **The avenue:** cars enter from the left or right with a low fuel gauge. Each one drives straight by,
  pulls into Gaétan's, or pulls into yours. Gaétan's station is drawn across the road: pumps, a sign.
  You only see cars go in low and come out full.
- **Market share** (the split of cars that want gas) starts at 50%. **Reputation** comes from your fills
  and tilts the split toward you. Shown at the end of each day, with the change.
- **Win:** 100% market share. The town cheers, Dad is avenged, and his heart gives out from joy (a happy,
  over-the-top ending). Replaces the day-50 ending and the postcards.
- **The end-of-day books:** a P&L (sales, tips, other income; fuel at wholesale, spills, drone gas, fines,
  stolen gas; net) and a balance sheet (cash, gas in the tank at cost, equipment at cost, loans, equity).

## Batch C: the cartoon look — look test drawn 2026-10-25 (docs/art/look_test_cartoon.svg / .png), awaiting the designer's approval
- Look test: one mock frame (the lot, Gaétan's across the road, chunky cars, the coins and stacks, the HUD)
  in stylized 2D cartoon: chunky cars with thick outlines, exaggerated effects, shiny loot, a clean
  high-contrast UI, a distinct colour for each coin value, perk and tree branch. The designer approves it.
- Then redraw everything in that style (replaces HD-2D).
- How it's made: hand-written SVG (Godot imports SVG), rendered with headless Chrome for review. Every car is one
  symbol whose body takes any colour, with a 4 px dark outline, one shade and one shine.
- Noted while drawing: the strip across the road is too thin for Gaétan's station under the HUD; the redraw
  moves the avenue down a little to give his station room.

## Batch D: the car codex and new cars (v0.48.0)
- **Car types unlock in the run by XP** (a difficulty ladder, no longer permanent).
- **A codex:** every car type, what it does and the XP that unlocks it.
- **New cars**, each with a very distinct look:
  - **Bumper car:** runs around hitting other cars.
  - **In a rush:** doesn't stay long, tips big.
  - **The tank:** a huge tank, drives in straight lines.
  - **Trio elétrico:** a full samba school on top, Rio style. Overfilling it is a disaster, but filling it
    well earns a lot of reputation.

## Batch E: new upgrades — built 2026-10-25 (with batch B in v0.46.0)
- **A spill branch:** upgrades that soften the cost of spilled gas, including a second tube man who sucks
  spilled gas off the lot and puts it back in the tank.
- **Herding dog robot:** every few seconds it runs out and rounds the cars up into a circle (so one ring
  can reach two of them).
