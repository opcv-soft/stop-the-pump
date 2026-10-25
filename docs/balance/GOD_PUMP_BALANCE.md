# GOD PUMP balance (2026-10-25, #37)

`tools/sim/god_bot.gd` plays the real game headless: GodPump's own simulation and RunState's rules.
The bot chases moving cars at 900 px/s and reacts in 0.25 s. It lets go aiming for an even split of
Topped off, Perfect, Good, OK and overfill (the designer's assumption), stopping exactly on its plan.
At night it calls the truck when the tank won't last tomorrow, keeps cash for it when the tank is
short, and buys the cheapest upgrade in this order: hours, marketing, nozzle, attractions, service,
tank, vibe. Cards are picked from a fixed preference list.

    godot --headless -s tools/sim/god_bot.gd -- 20 fresh      (fresh | mid | late)

## Target (playtest 7, 2026-10-21)
- **Day 50 is impossible on a fresh save.**
- **It takes about 2 hours of Papa's Garage upgrades.** The first win comes around hour 3: about 2 h of earning XP, then the winning run.
- **New car types are a difficulty ladder:** unlocking them makes days harder; the Garage answers them.

## Chosen economy
- **Wholesale price:** starts at $1.20/L against a $2.00 pump price and rises **25% per delivery** (was 8%).
- **Tank:** $700 of gas, full at the start.
- **The truck sells partial deliveries:** whatever your cash buys, at least $20. Bankrupt means a dry tank and under $20.
- **Two Garage perks push the wall back,** each 350 XP a tier (350, 700, 1050), 3 tiers:
  - **Contrat du fournisseur:** prices rise 20% slower per tier.
  - **Super sans plomb:** sales pay 10% more per tier.

Why: with 8% and full deliveries only, most runs ended in the trap the designer hit (enough money, not enough for a *full* delivery). Once partial deliveries were in, even a fresh save reached day 50 every time. The rising price is the wall. Growing the business doesn't beat it on its own: more sales mean more deliveries, so more rises. The fully kitted "late" save without the two perks dies around day 28. So the Garage needed levers aimed at the wall.

Tried along the way (price rise per delivery, fresh save):
- **14%:** 22 of 30 reach day 50.
- **20%:** 2 of 30.
- **26%:** 0 of 30, median day 34.
- **32–40%:** median day 27–29.
- **Perk tiers at 200 XP:** half the bot players won in their second run (1.5 h).

## Round 10, take 3: XP = litres × the sum of chains × accuracy (playtest 11, 2026-10-25)
- 12 fresh runs: 9,557 XP a run, **16,755 XP per hour** (×14.5 round 8). Garage prices **×15** round 8; F6 / F1 give 15,000 XP.

    campaign: first win 9 of 12 players; median 2.9 h

## Round 10 batch B: the fight with Gaétan (2026-10-25)
The win is now 100% market share (day 50 is gone). Constants in GodData: reputation per car (Topped off +2,
Perfect +1.25, Good +0.6, OK 0, Overfilled −0.75, Unserved −0.5), Gaétan's push −0.5 a night, the share
moves toward reputation by at most 8 points a night. Cars both ways may want gas (×1.1), split by share.

Tried (12–16 fresh runs, then a 12-player campaign):
- Push 1.5, Overfilled −1, Unserved −1, Good +0.5: the bot loses to Gaétan in 8 of 10 fresh runs (0%). Far too harsh.
- Push 0.75, Unserved −0.5: fresh runs end at 14–57%.
- Push 0.5, Overfilled −0.75: fresh 31–70%; campaign first win median 3.8 h (2 of 12 never).
- Push 0.4: campaign median 4.1 h (noise: the limit is surviving the price wall, not the push).
- **Chosen:** push 0.5, and good fills worth 25% more (Topped off 2, Perfect 1.25, Good 0.6):

    fresh (16 runs): days survived median 37; market share at the end 37–86%, one lucky win (100%); lost to Gaétan: 0
    campaign: first win 10 of 12 players; median 3.6 h

Open: a fresh save can (rarely) win. If the designer wants 100% out of reach at first, lower Topped off/Perfect a notch.

## Round 10 retune, take 2 (playtest 10, 2026-10-25)
XP is now **litres × (1 + average combo) × accuracy**: it grows in step with a day's size instead of with its square.
- 10 fresh runs: 3,502 XP a run, **5,717 XP per hour** (×5 the round-8 1,152).
- Garage prices are **×5** the round-8 prices (were ×15 under take 1). F6 and the F1 panel give 5,000 XP.

    campaign: 12 players from a fresh save
    first day 50: 12 of 12 players; median 3.0 h

## Round 10 retune: the new XP (2026-10-25, replaced the same day)
XP is now **litres put in cars × combo points × accuracy** per day (playtest 9). Same bot, same 10 fresh runs:
- Before: 648 XP a run, **1,152 XP per hour**.
- After: 10,664 XP a run, **18,100 XP per hour** (×15.7). Days survived barely moved (drones burning $0.30/s of gas costs little).
- So every Garage price is **×15** (nozzles, bling, perk tiers). The dev keys follow: F6 and the F1 panel give 15,000 XP.

    campaign: 12 players from a fresh save
    first day 50: 12 of 12 players; median 3.0 h (earliest 2.2 h, latest 4.3 h)

Watch: litres and combo points both grow with a day's size, so XP grows with its square. Long late days
pay far more than short early ones; the campaign still lands on target, but the spread widened.

## Round 8 retune (2026-10-21)
Round 8 added three things that change the numbers:
- **A deeper tree:** the CAMION branch and 8 upgrades with two parents.
- **The tube man perk.**
- **No XP for unserved cars:** cars that leave without their fill no longer count, which lowered XP to about 1,175 an hour.

The new upgrades made every run stronger, so two prices went up:
- **Contrat à terme:** every **fourth** delivery comes without a price rise (was every third), and it costs $480 (was $380). At every third it cut the price wall by a third, and a fresh save reached day 50 in 1 run of 60.
- **Contrat du fournisseur** and **Super sans plomb:** **450 XP a tier** (was 350). At 350, the campaign's median first win came at 2.6 h.

    fresh (80 runs):  days survived median 34, mean 35.0, min 27, max 48; reached day 50: 0
                      mean per run: XP 694, play time 35.5 min -> 1174 XP per hour of play
    campaign: 12 players from a fresh save (Garage order: contract and premium gas first, then the tube man)
    first day 50: 12 of 12 players; median 2.8 h (earliest 1.5 h, latest 3.8 h)
    (full log: docs/balance/campaign.txt)

## Results before round 8
    fresh (80 runs):  days survived median 34, mean 34.9, min 27, max 47; reached day 50: 0
                      mean per run: XP 871, play time 35.8 min -> 1462 XP per hour of play
    mid (20 runs):    median 33, max 43; reached day 50: 0
    late (20 runs):   median 28, max 31; reached day 50: 0   (everything unlocked, no contract or premium gas)

    campaign: 12 players from a fresh save, buying contract and premium gas first
    first day 50: 12 of 12 players; median 3.1 h (earliest 1.5 h, latest 4.6 h)
    (full log: docs/balance/campaign.txt)

- **Play time** counts each day's clock plus about 25 s for the report and the night.
- **The bot is better than a person:** perfect tracking, instant reactions, a guaranteed even split. People will probably need longer than 3 h, and should still be able to find the contract and premium gas.
