class_name Tutorial
extends RefCounted
## The first day's tutorial (round 11, playtest 12: "make it obvious what the point is"). It teaches by
## doing: each step is a short card with an arrow, and moves on when you do the thing. While it runs the day's
## clock is held, so there's no rush. The last step waits for the night and points at its two tabs.
## A component GodPump owns (the day steps) and NightScreen reads (the night step).
## Serves: Mastery (the chain is the skill) and onboarding (the first 5 minutes).

signal finished

## Each step: text, where its arrow points ("ring", "gauge", "pill", "road", "bar", "tabs"), and the event
## that completes it.
const STEPS := [
	{"text": "Hold the mouse button to pour. The ring on the ground is where the gas goes.", "point": "ring", "done": "poured"},
	{"text": "Let go when the needle reaches F. Past 80% the car pays and drives off.", "point": "gauge", "done": "settled"},
	{"text": "A Good fill or better starts a CHAIN: x1, then x2, x3... Make two in a row.", "point": "pill", "done": "chain2"},
	{"text": "A chain is worth the sum of its steps: 1+2+3 = 6. That's your XP. An OK or an overfill breaks it. Keep chaining!", "point": "pill", "done": "wait"},
	{"text": "Cars with a red E want gas. Good fills win them over from Gaétan across the road.", "point": "road", "done": "wait"},
	{"text": "The bar up top is your day. When it fills: FERMÉ.", "point": "bar", "done": "wait"},
	{"text": "Tonight: cash buys THE SHOP, your chains' XP buys THE GARAGE.", "point": "tabs", "done": "night"},
]
const WAIT := 5.5  # a "wait" step reads for this long
const GIVE_UP := 30.0  # a day step moves on anyway after this long: the clock is never held for good

var index := 0
var t := 0.0
var active := true


func step() -> Dictionary:
	return STEPS[index] if active and index < STEPS.size() else {}


## While the day's steps run, the clock stands still.
func holds_clock() -> bool:
	return active and index < STEPS.size() - 1


func advance() -> void:
	index += 1
	t = 0.0
	if index >= STEPS.size():
		active = false
		finished.emit()


## Something happened in the day: "poured", "settled", "chain2" (a chain reached two), "night".
func event(name: String) -> void:
	if active and step().get("done", "") == name:
		advance()


func tick(dt: float) -> void:
	if not active:
		return
	t += dt
	var done: String = step().get("done", "")
	if (done == "wait" and t >= WAIT) or (done != "night" and t >= GIVE_UP):
		advance()
