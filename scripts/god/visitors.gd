class_name Visitors
extends RefCounted
## The lore, told at the gaz bar (round 9; round 10 B: the fight with Gaétan). On set days a visitor
## drives in, parks in the lot's corner by the store and chats with the regulars (wordless in the day;
## the lines are read beside the day report): Gaétan from across the road, Dad himself, Sylvie (Mme
## Gagnon's niece), Me Tremblay the notary, cousin Réjean and the curé. Pure data; GodPump plays it.
## Serves: the story, Comedy. The lore bible: docs/LORE.md.

## Who visits: their name and the car they drive (a sprite stack).
const CAST := {
	"gaetan": {"name": "Gaétan", "stack": "green"},
	"papa": {"name": "Papa", "stack": "papa"},
	"sylvie": {"name": "Sylvie", "stack": "cream"},
	"tremblay": {"name": "Me Tremblay", "stack": "purple"},
	"rejean": {"name": "Cousin Réjean", "stack": "red"},
	"cure": {"name": "The curé", "stack": "white"},
}

## Round 10 B: Dad is alive (no more postcards). Kept empty for the old saves' scrapbook.
const POSTCARDS := []

## The visits, by day: who comes, and the lines (speaker: a CAST id or a regular's name).
const BEATS := [
	{"day": 2, "who": "gaetan", "lines": [["gaetan", "Gaétan, from across the road. Half the village fills up at my place now."],
		["tiguy", "Only because the old man's hands shake."], ["gaetan", "Hands don't lie, Ti-Guy."]]},
	{"day": 3, "who": "papa", "lines": [["papa", "How's my pump, kid? Don't look at my hands."],
		["bertrand", "Thirty years, he topped off to the cent."], ["papa", "To the CENT."]]},
	{"day": 5, "who": "sylvie", "lines": [["sylvie", "Hi! I'm Sylvie, Mme Gagnon's niece."],
		["gagnon", "She's single. Just saying."], ["legrand", "Is the kid single, though?"]]},
	{"day": 7, "who": "rejean", "lines": [["rejean", "Your father tried to hire me once. I spilled on his shoes."],
		["gagnon", "Both shoes."], ["rejean", "\"Ces gars-là l'ont pas,\" he said. I'm one of those guys."]]},
	{"day": 9, "who": "tremblay", "lines": [["tremblay", "Gaétan asked me to draw up papers. To buy you out."],
		["legrand", "Tell him to fill up his own tank."], ["tremblay", "I'll... phrase it differently."]]},
	{"day": 12, "who": "cure", "lines": [["cure", "Half my parish fills up across the road now. I pray for you both."],
		["bertrand", "Pray harder for Gaétan, mon père."]]},
	{"day": 15, "who": "papa", "lines": [["papa", "I watched your Perfects from the window. My hands were steady once."],
		["tiguy", "Steadiest in Québec."], ["papa", "Gaétan never topped off a thing in his life."]]},
	{"day": 18, "who": "gaetan", "lines": [["gaetan", "Business is slow across the road."],
		["legrand", "Lower your prices, Gaétan."], ["gaetan", "Never."]]},
	{"day": 21, "who": "sylvie", "lines": [["sylvie", "My aunt says you're getting good at this."],
		["gagnon", "I did say that."], ["sylvie", "She also says you're single."]]},
	{"day": 25, "who": "papa", "lines": [["papa", "Gaétan bought a new sign. A NEW SIGN."],
		["gagnon", "Breathe. Your heart."], ["papa", "My heart is fine. My heart is GREAT."]]},
	{"day": 30, "who": "tremblay", "lines": [["tremblay", "Gaétan is asking about his options."],
		["bertrand", "He has one."], ["tremblay", "Which is?"], ["bertrand", "Losing."]]},
	{"day": 35, "who": "rejean", "lines": [["rejean", "Gaétan's cousin says he's thinking of opening a car wash instead."],
		["tiguy", "A car wash! HA!"]]},
	{"day": 40, "who": "gaetan", "lines": [["gaetan", "If you ever win them all back, I'll close. Ha. As if."],
		["papa", "Keep pouring, kid."]]},
]


## Today's visit, or {} on a day nobody comes.
static func beat_for(day: int) -> Dictionary:
	for b in BEATS:
		if b.day == day:
			return b
	return {}


## The name to show for a speaker (a visitor's, or a regular's full name).
static func speaker_name(id: String) -> String:
	if CAST.has(id):
		return CAST[id].name
	return RegularsCrew.FULL_NAMES.get(id, id)
