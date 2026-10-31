# GOD PUMP — Glossary

> One name per thing, everywhere: design docs, code, data, UI text, commit messages.
> `tools/arch_check.py` fails if a **forbidden synonym** appears in `scripts/` as an identifier. Forbidden synonyms are left empty for now (added only by decision record, after checking the code).
> Owner: Game Designer (design terms) and Programmer (code names). Changing a name is a decision record.

| Design term | Code name | Forbidden synonyms | Notes |
|---|---|---|---|
| The God Pump / the nozzle | nozzle | | The giant nozzle the player pours from |
| The ring | ring | | The aiming circle under the nozzle |
| Fill | fill | | One car's pour, graded when the stream leaves the car |
| Grade | grade | | TOPPED OFF, PERFECT, GOOD, OK, MISS |
| Chain | combo | | Consecutive Good-or-better fills; UI says CHAIN / combo pill |
| Day | day | | One opening, OUVERT to FERMÉ |
| Night | night | | Between days: Shop, Garage, truck, codex |
| Run | run (RunState) | | From the intro to a win or a loss |
| THE SHOP | tree | | Cash upgrade tree |
| THE GARAGE | garage | | XP: nozzles, bling, perks (in the run) |
| The fuel truck / delivery | truck | | Full tank or nothing, unless dry |
| Card | card | | Rule-changer dealt by each delivery |
| Car type | car type (CARS) | | 13 types on the car ladder |
| Car ladder | | | Car types unlocking by the run's XP |
| Market share | share | | 50% at start; 100% wins, 0% loses |
| Reputation | reputation | | Earned by fills; moves the share at night |
| Gaétan / Chez Gaétan | Gaétan | | The rival station across the road |
| Regulars | regulars | | The village crowd that reacts to fills |
| Visitors | visitors | | Lore characters on set days |
| Drone | drone | | A nozzle that fills cars on its own |
| Tank | tank | | The station's gas; TANK label in UI |
| Cash | cash | | CASH label on the register |
| XP | xp | | litres × sum of the day's chains × accuracy |

## Naming conventions
- Files and folders: `snake_case`
- Classes / `class_name`: `PascalCase` (`GodPump`, `RunState`)
- Functions and variables: `snake_case`; booleans read as questions
- Signals: past tense
- Constants: `UPPER_SNAKE`
- Save-states: `debug/states/<situation>.json`
