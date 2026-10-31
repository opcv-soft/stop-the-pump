# GOD PUMP — Art bible

> Owner: Art Director. Written on 2026-10-31 from round 10 C (the cartoon look, approved 2026-10-25). Older directions (Hopper low-poly, HD-2D, pixel) are history: docs/archive/DESIGN_history.md §9b and docs/art/AFFORDANCES.md.

## Look and feel
Bright, warm 2D cartoon of a small Québec village lot. Reference frame: docs/art/look_test_cartoon.png.

## Style
Drawn in code by `scripts/components/cartoon_art.gd`: cars per type (`CARS`), people (`PEOPLE`), upgrade props (`PROPS`). The menus' icons are still pixel art (claude-pxl); the menus' cartoon redraw is the open art brief (round 10 C pass 2).

## Palette
Saturated for what the player acts on (the cars, the nozzle, the ring, coins in four colours); softer for the lot and the village.

## Shape language
Round, chunky, readable silhouettes; each car type has its own silhouette and colour.

## Readability rules
1. Every asset communicates an affordance (what you can act on) before it is pretty.
2. The ring, the fill gauge and the grade must read over any car.
3. Coins rest on the lot under the cars without hiding them.
4. CASH (the register) and TANK (the old pump, as a percentage) are labelled.

## Animation
Pops and squash for reveals (grades, props popping in, the new-car card spinning in).

## VFX
Pour stream, sparkle on Topped off, the combo pill's flames from x3, rays on reveals.

## UI / UX
Night screen with two tabs (THE SHOP, THE GARAGE), the car codex, the truck's card choice, the day report revealing piece by piece. French and English.

## Generation recipe (ComfyUI)
N/A — because the art is drawn in code.

## Asset design process
New look → look test frame approved by the Director → code in cartoon_art.gd.
