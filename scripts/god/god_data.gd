class_name GodData
extends RefCounted
## Everything GOD PUMP can own, as data (docs/GOD_PUMP_PLAN.md): the night shop's branches, the
## fuel-truck cards, the car types, and Papa's Garage (nozzles, bling, perks). Each item carries `fx`:
## effects that GodMods adds up into the numbers a day runs on. Keeping it all here means balance is a
## data edit, and the bot plays exactly what the player plays. Serves: Advancement.

## How each effect combines: "add" sums, "mul" multiplies, "max" keeps the largest.
const FX_OPS := {
	"close_hour": "max", "queue": "add", "customer_chance": "add", "per_car_bonus": "add",
	"perfect_bonus": "add", "topoff_bonus": "add", "stream_radius": "add", "auto_aim": "add", "drones": "add",
	"combo_max": "add", "applause_bonus": "add", "loto_chance": "add", "luck": "add", "start_cash": "add",
	"tank_capacity": "add", "flow_mult": "mul", "tip_mult": "mul", "patience_mult": "mul", "spill_mult": "mul",
	"happy_hour": "max", "twin_stream": "add", "golden_chance": "add", "recycle": "max", "first_car_tip_mult": "max",
	"combo_lock": "max", "overfill_saves": "add", "refund_every": "max", "upgrade_discount": "add",
	"jackpot_chance": "add", "first_delivery_discount": "add", "cards_offered": "add", "rerolls": "add",
	"bling_slots": "add", "price_rise_mult": "mul", "sale_mult": "mul",
	# round 8: the CAMION branch and the upgrades with two parents
	"tank_alarm": "max", "bulk_discount": "add", "partial_rise_mult": "mul", "freeze_every": "max",
	"coffee_sale": "add", "hockey_every": "max", "loyalty_every": "max", "night_tip_mult": "mul",
	"drone_bonus": "add", "tube_man": "add", "clamp_thief": "max", "clamp_wait": "max",
	# round 10 E: the spill branch and the herding dog
	"puddle_vacuum": "max", "overfill_grace": "add", "herd_dog": "max",
	# round 11: the rule-changing cards
	"rep_nightly": "add", "gaetan_push_mult": "mul", "topoff_coin": "add", "double_or_nothing": "max", "poach": "add",
}

## The defaults a day runs on before anything is bought.
const BASE := {
	"close_hour": 13.0, "queue": 0, "customer_chance": 0.5, "per_car_bonus": 0.0, "perfect_bonus": 0.0,
	"topoff_bonus": 2.0, "stream_radius": 0.0, "auto_aim": 0.0, "drones": 0, "combo_max": 5, "applause_bonus": 0.0,
	"loto_chance": 0.0, "luck": 0.0, "start_cash": 60.0, "tank_capacity": 700.0, "flow_mult": 1.0,
	"tip_mult": 1.0, "patience_mult": 1.0, "spill_mult": 1.0, "happy_hour": 0, "twin_stream": 0,
	"golden_chance": 0.0, "recycle": 0, "first_car_tip_mult": 1.0, "combo_lock": 0, "overfill_saves": 0,
	"refund_every": 0, "upgrade_discount": 0.0, "jackpot_chance": 0.0, "first_delivery_discount": 0.0,
	"cards_offered": 3, "rerolls": 0, "bling_slots": 1, "price_rise_mult": 1.0, "sale_mult": 1.0,
	"tank_alarm": 0, "bulk_discount": 0.0, "partial_rise_mult": 1.0, "freeze_every": 0, "coffee_sale": 0.0,
	"hockey_every": 0, "loyalty_every": 0, "night_tip_mult": 1.0, "drone_bonus": 0.0, "tube_man": 0,
	"clamp_thief": 0, "clamp_wait": 0, "puddle_vacuum": 0, "overfill_grace": 0.0, "herd_dog": 0,
	"rep_nightly": 0.0, "gaetan_push_mult": 1.0, "topoff_coin": 0.0, "double_or_nothing": 0, "poach": 0.0,
}

# --- The night shop (cash, always available) ----------------------------------------------------
const BRANCHES := [
	{"id": "hours", "name": "HEURES", "nodes": [
		{"id": "thermos", "name": "Thermos de café", "helps": "you stay awake: open until 14 h", "price": 60.0, "fx": {"close_hour": 14.0}},
		{"id": "mom_lunch", "name": "Maman fait le dîner", "helps": "Mom covers lunch: open until 16 h", "price": 140.0, "fx": {"close_hour": 16.0}},
		{"id": "permit", "name": "Permis du soir", "helps": "the council says yes: open until 19 h", "price": 260.0, "fx": {"close_hour": 19.0}},
		{"id": "cousin", "name": "Cousin Réjean de nuit", "helps": "open until 23 h", "price": 420.0, "fx": {"close_hour": 23.0}},
	]},
	{"id": "marketing", "name": "MARKETING", "nodes": [
		{"id": "flyers", "name": "Flyers", "helps": "+1 car waiting when you open", "price": 50.0, "fx": {"queue": 1}},
		{"id": "radio_ad", "name": "Pub à la radio", "helps": "+2 cars waiting when you open", "price": 120.0, "fx": {"queue": 2}},
		{"id": "billboard", "name": "Panneau", "helps": "+3 cars waiting, and more cars pull in", "price": 240.0, "fx": {"queue": 3, "customer_chance": 0.05}},
	]},
	{"id": "attractions", "name": "ATTRACTIONS", "nodes": [
		{"id": "traffic_light", "name": "Feu de circulation", "helps": "cars cut through your lot: more pull in", "price": 90.0, "fx": {"customer_chance": 0.15}},
		{"id": "grocery", "name": "Mini-épicerie", "helps": "every car also buys a snack: +$2", "price": 160.0, "fx": {"per_car_bonus": 2.0}},
		{"id": "car_wash", "name": "Lave-auto", "helps": "+$4 a car, and cars wait 30% longer", "price": 300.0, "fx": {"per_car_bonus": 4.0, "patience_mult": 1.3}},
		{"id": "loto", "name": "Machine à loto", "helps": "5% chance a car tips $20 more", "price": 380.0, "fx": {"loto_chance": 0.05}},
	]},
	{"id": "nozzle", "name": "PISTOLET", "nodes": [
		# round 11: speed and area belong to the nozzles now (the Garage); the tree keeps aim and drones
		{"id": "aim_1", "name": "Visée auto I", "helps": "the stream bends toward a car nearby", "price": 100.0, "fx": {"auto_aim": 30.0}},
		{"id": "aim_2", "name": "Visée auto II", "helps": "the stream bends from even further", "price": 260.0, "fx": {"auto_aim": 30.0}},
		{"id": "drone_1", "name": "Drone pistolet", "helps": "a little drone fills cars on its own", "price": 340.0, "fx": {"drones": 1}},
		{"id": "drone_2", "name": "Drone pistolet II", "helps": "a second drone", "price": 520.0, "fx": {"drones": 1}},
	]},
	# Round 10 (playtest 10): fill more cars at once. Hangs off Bec large ("root": bought after it).
	{"id": "multi", "name": "MULTI-JET", "root": "aim_1", "nodes": [
		{"id": "twin_1", "name": "Double pistolet", "helps": "fills two cars at once when both are inside the ring", "price": 220.0, "glyph": "x2", "fx": {"twin_stream": 1}},
		{"id": "twin_2", "name": "Triple pistolet", "helps": "fills three cars at once", "price": 460.0, "glyph": "x3", "fx": {"twin_stream": 1}},
		{"id": "herd_dog", "name": "Chien de berger robot", "helps": "every 12 s a robot dog rounds your customers up around the nozzle", "price": 520.0, "glyph": "DOG", "fx": {"herd_dog": 1}},
	]},
	{"id": "service", "name": "SERVICE", "nodes": [
		{"id": "tip_sign", "name": "Pancarte pourboire", "helps": "tips +20%", "price": 60.0, "fx": {"tip_mult": 1.2}},
		{"id": "squeegee", "name": "Raclette", "helps": "+$2 on a Perfect or better", "price": 140.0, "fx": {"perfect_bonus": 2.0}},
		{"id": "coffee", "name": "Café pour la file", "helps": "cars wait 30% longer", "price": 220.0, "fx": {"patience_mult": 1.3}},
	]},
	{"id": "vibe", "name": "AMBIANCE", "nodes": [
		{"id": "radio", "name": "Radio bluesy", "helps": "max combo +1", "price": 80.0, "fx": {"combo_max": 1}},
		{"id": "bench", "name": "Banc des habitués", "helps": "every applause from the regulars: +$1", "price": 170.0, "fx": {"applause_bonus": 1.0}},
		{"id": "jukebox", "name": "Juke-box", "helps": "max combo +1", "price": 300.0, "fx": {"combo_max": 1}},
	]},
	{"id": "tank", "name": "RÉSERVOIR", "nodes": [
		{"id": "tank_1", "name": "Gros réservoir", "helps": "the tank holds $200 more gas", "price": 120.0, "fx": {"tank_capacity": 200.0}},
		{"id": "tank_2", "name": "Gros réservoir II", "helps": "$200 more", "price": 240.0, "fx": {"tank_capacity": 200.0}},
		{"id": "tank_3", "name": "Gros réservoir III", "helps": "$300 more", "price": 400.0, "fx": {"tank_capacity": 300.0}},
	]},
	# Round 10 (playtest 9): softer spills. Hangs off Gros réservoir.
	{"id": "spill", "name": "DÉGÂTS", "root": "tank_1", "nodes": [
		{"id": "litter", "name": "Litière à chat", "helps": "a bag of kitty litter: spills waste 25% less gas", "price": 120.0, "glyph": "~", "fx": {"spill_mult": 0.75}},
		{"id": "vacuum", "name": "Aspirateur gonflable", "helps": "a second tube man sucks up a puddle every 4 s and puts 70% of it back in the tank", "price": 260.0, "glyph": "VAC", "fx": {"puddle_vacuum": 1}},
		{"id": "anti_drip", "name": "Bec anti-goutte", "helps": "a drip under 50 cents no longer counts as Overfilled", "price": 380.0, "glyph": "!", "fx": {"overfill_grace": 0.5}},
	]},
	# Round 8: the truck itself. Plays on the tension between refuelling early (cards) and late (price).
	{"id": "truck", "name": "CAMION", "nodes": [
		{"id": "tank_gauge", "name": "Jauge d'alarme", "helps": "know to the hour how long the tank lasts, and get warned in the day", "price": 40.0, "fx": {"tank_alarm": 1}},
		{"id": "bulk", "name": "Achat en vrac", "helps": "a delivery costs 10% less when the tank is under 25%", "price": 150.0, "fx": {"bulk_discount": 0.10}},
		{"id": "used_tanker", "name": "Citerne usagée", "helps": "a partial delivery raises the price half as much", "price": 220.0, "fx": {"partial_rise_mult": 0.5}},
	]},
]

# --- Upgrades with two parents (round 8): each sits between two branches and unlocks once you own
# both of the upgrades it names in `needs`. The tree view places them (GodTreeView.LINK_CELLS).
const LINKS := [
	{"id": "drive_thru", "name": "Fenêtre au volant", "helps": "a car that waited over 3 s buys a coffee: +$1", "price": 150.0, "needs": ["coffee", "thermos"], "fx": {"coffee_sale": 1.0}},
	{"id": "hockey", "name": "Soirée du hockey", "helps": "every 7th day is hockey night: 3 more cars waiting, more cars pull in", "price": 200.0, "needs": ["mom_lunch", "radio"], "fx": {"hockey_every": 7}},
	{"id": "loyalty", "name": "Carte fidélité", "helps": "every 5th car is a regular who tips double", "price": 180.0, "needs": ["radio_ad", "tip_sign"], "fx": {"loyalty_every": 5}},
	{"id": "night_neons", "name": "Néons de nuit", "helps": "tips +30% after 19 h", "price": 320.0, "needs": ["permit", "jukebox"], "fx": {"night_tip_mult": 1.3}},
	{"id": "drone_hangar", "name": "Hangar à drones", "helps": "a drone fill earns $2 more", "price": 300.0, "needs": ["drone_1", "car_wash"], "fx": {"drone_bonus": 2.0}},
	{"id": "chip_truck", "name": "Cantine à patates", "helps": "a chip truck on the lot: cars wait 20% longer, every applause +$2", "price": 260.0, "needs": ["grocery", "bench"], "fx": {"patience_mult": 1.2, "applause_bonus": 2.0}},
	{"id": "price_board", "name": "Prix affiché", "helps": "a big price sign by the road: every sale pays 5% more", "price": 280.0, "needs": ["billboard", "tank_1"], "fx": {"sale_mult": 1.05}},
	{"id": "clamp_1", "name": "Sabot de Denver", "helps": "thieves get a wheel clamp: they can't flee, and what they stole goes back in your tank", "price": 260.0, "needs": ["bulk", "aim_1"], "fx": {"clamp_thief": 1}},
	{"id": "clamp_2", "name": "Sabot de Denver II", "helps": "a customer about to give up gets clamped instead: it stops, and waits a while longer", "price": 420.0, "needs": ["clamp_1", "used_tanker"], "fx": {"clamp_wait": 1}},
	{"id": "forward_contract", "name": "Contrat à terme", "helps": "every fourth delivery comes without a price rise", "price": 480.0, "needs": ["tank_2", "billboard"], "fx": {"freeze_every": 4}},
]

# --- Fuel-truck cards: choose 1 of 3 per delivery (luck raises the rarity) ----------------------
const CARDS := [
	# Round 11 (playtest 12): the cards bend a rule; the tree's upgrades are the steady ones.
	{"id": "combo_lock", "name": "Combo béton", "rarity": "common", "helps": "an OK no longer breaks your chain", "fx": {"combo_lock": 1}},
	{"id": "gas_saver", "name": "Économiseur", "rarity": "common", "helps": "spills waste half as much gas", "fx": {"spill_mult": 0.5}},
	{"id": "happy_hour", "name": "Happy hour", "rarity": "common", "helps": "tips x3 for the first 2 hours of each day", "fx": {"happy_hour": 1}},
	{"id": "patient", "name": "Clientèle patiente", "rarity": "common", "helps": "cars wait twice as long before giving up", "fx": {"patience_mult": 2.0}},
	{"id": "rumour", "name": "Rumeur au village", "rarity": "common", "helps": "the village talks: +1 reputation every night", "fx": {"rep_nightly": 1.0}},
	{"id": "twin_stream", "name": "Double jet", "rarity": "rare", "helps": "the nozzle fills one more car at once", "fx": {"twin_stream": 1}},
	{"id": "spy", "name": "Espion chez Gaétan", "rarity": "rare", "helps": "you know his specials: Gaétan's nightly push is halved", "fx": {"gaetan_push_mult": 0.5}},
	{"id": "golden_chain", "name": "Chaîne dorée", "rarity": "rare", "helps": "chains climb 3 higher: up to x8", "fx": {"combo_max": 3}},
	{"id": "price_freeze", "name": "Gel des prix", "rarity": "rare", "helps": "the next delivery doesn't raise the gas price", "fx": {}},
	{"id": "drone_card", "name": "Drone en prime", "rarity": "rare", "helps": "+1 drone nozzle", "fx": {"drones": 1}},
	{"id": "coin_rain", "name": "Pluie de pièces", "rarity": "rare", "helps": "every Topped off drops a $20 coin too", "fx": {"topoff_coin": 20.0}},
	{"id": "golden_hose", "name": "Boyau doré", "rarity": "legendary", "helps": "10% of fills are golden: tip x3", "fx": {"golden_chance": 0.10}},
	{"id": "recycler", "name": "Recycleur", "rarity": "legendary", "helps": "spilled gas flows back into the tank", "fx": {"recycle": 1}},
	{"id": "devil", "name": "Pacte avec le diable", "rarity": "legendary", "helps": "tips x2, but gas prices rise twice as fast", "fx": {"tip_mult": 2.0}},
	{"id": "double_or_nothing", "name": "Double ou rien", "rarity": "legendary", "helps": "a Topped off tips x3; an Overfilled car pays nothing", "fx": {"double_or_nothing": 1}},
	{"id": "poach", "name": "Vol de clients", "rarity": "legendary", "helps": "1 car in 3 heading to Gaétan's turns into your lot instead", "fx": {"poach": 0.33}},
]
const RARITY_WEIGHT := {"common": 70.0, "rare": 25.0, "legendary": 5.0}

# --- Car types: a difficulty ladder that unlocks during each run, by the XP earned in it (round 10 D) --
## customer: wants gas. fill_speed: how fast its tank takes fuel. pay: share of the sale it pays.
## tip: tip multiplier. speed: how fast it drives. orders: what it asks for. unlock: run XP needed.
## patience: how long it waits (x the usual). pattern: how it moves. rep_mult: reputation per grade (x).
## miss_fine: what an overfill costs you. helps: its rule, as the codex says it.
const CAR_TYPES := {
	"sedan": {"name": "Berline", "customer": true, "orders": [10.0, 15.0, 20.0, 25.0, 30.0], "unlock": 0, "weight": 10.0,
		"helps": "The everyday car. Fill it, get paid."},
	"pickup": {"name": "Le Pick-up", "customer": true, "orders": [40.0, 50.0, 60.0], "pay": 0.8, "unlock": 60, "weight": 3.0,
		"helps": "A huge order, but it haggles: pays 80%."},
	"cadillac": {"name": "Le Cadillac", "customer": true, "orders": [20.0, 30.0, 40.0], "tip": 2.0, "unlock": 160, "weight": 2.0,
		"helps": "A big tipper: tips x2."},
	"bazou": {"name": "Le Bazou", "customer": true, "orders": [10.0, 15.0, 20.0], "fill_speed": 0.6, "unlock": 320, "weight": 2.5,
		"helps": "A rusty beater: its tank takes gas slowly (60%)."},
	"racer": {"name": "Le Char de course", "customer": true, "orders": [15.0, 20.0, 25.0], "speed": 2.2, "tip": 1.3, "unlock": 520, "weight": 2.0,
		"helps": "Drives around fast. Tips x1.3."},
	"rush": {"name": "Le Pressé", "customer": true, "orders": [10.0, 15.0, 20.0], "patience": 0.4, "tip": 2.5, "speed": 1.3, "unlock": 760, "weight": 2.0,
		"helps": "In a rush: leaves quickly, but tips x2.5."},
	"sweeper": {"name": "La Balayeuse", "customer": false, "role": "sweeper", "unlock": 1040, "weight": 1.0,
		"helps": "Not a customer: cleans up the puddles it drives over."},
	"bumper": {"name": "L'Auto tamponneuse", "customer": true, "orders": [15.0, 20.0, 25.0], "role": "bumper", "pattern": "bounce", "speed": 1.5, "tip": 1.2, "unlock": 1360, "weight": 1.5,
		"helps": "A bumper car: bounces around and knocks other cars out of your ring."},
	"thief": {"name": "Le Voleur", "customer": false, "role": "thief", "unlock": 1720, "weight": 1.2,
		"helps": "Not a customer: siphons gas from your customers. Pour on it to scare it off."},
	"clumsy": {"name": "Le Maladroit", "customer": true, "orders": [15.0, 20.0, 25.0], "role": "clumsy", "unlock": 2120, "weight": 1.5,
		"helps": "Bumps into cars and makes them spill a quarter of their gas."},
	"tank": {"name": "Le Mastodonte", "customer": true, "orders": [100.0, 120.0, 150.0], "fill_speed": 1.8, "speed": 0.55, "pattern": "shuttle", "unlock": 2560, "weight": 1.0,
		"helps": "A tanker: a huge order, drives in straight lines, takes gas fast."},
	"electric": {"name": "L'Électrique", "customer": false, "role": "electric", "unlock": 3040, "weight": 1.5,
		"helps": "Doesn't take gas: pour on it and you pay a $10 fine."},
	"trio": {"name": "Le Trio elétrico", "customer": true, "orders": [40.0, 50.0, 60.0], "speed": 0.7, "tip": 1.5, "rep_mult": 5.0, "miss_fine": 20.0, "unlock": 3600, "weight": 1.0,
		"helps": "A samba truck: a good fill is reputation x5; an overfill costs $20 and reputation x5."},
	# Day 50 only, before round 10 B: Dad, in the old orange hatchback (never drawn from the pool).
	"papa": {"name": "Papa", "customer": true, "orders": [30.0], "tip": 5.0, "unlock": 1000000000, "weight": 0.0, "stack": "papa"},
}
const CAR_ORDER := ["sedan", "pickup", "cadillac", "bazou", "racer", "rush", "sweeper", "bumper", "thief", "clumsy", "tank", "electric", "trio"]

# --- The Garage (round 11: in the run, a night tab paid with this run's XP; nothing carries over) ---------
## The nozzle ladder: each one replaces the last, faster and with a bigger ring, plus a perk. Bought in order.
const NOZZLES := [
	{"id": "classique", "name": "Le Classique", "helps": "Dad's old nozzle. Honest.", "price": 0, "fx": {}},
	{"id": "costaud", "name": "Le Costaud", "helps": "speed x1.2, ring +8; a top-off pays $2 more", "price": 600, "fx": {"flow_mult": 1.2, "stream_radius": 8.0, "topoff_bonus": 2.0}},
	{"id": "chrome", "name": "Le Chromé", "helps": "speed x1.4, ring +16; a drip under 50 cents isn't Overfilled", "price": 1800, "fx": {"flow_mult": 1.4, "stream_radius": 16.0, "overfill_grace": 0.25}},
	{"id": "turbo", "name": "Le Turbo", "helps": "speed x1.6, ring +24; the stream bends toward cars nearby", "price": 3600, "fx": {"flow_mult": 1.6, "stream_radius": 24.0, "auto_aim": 30.0}},
	{"id": "doree", "name": "La Dorée", "helps": "speed x1.8, ring +32; 10% golden fills (tip x3)", "price": 6400, "fx": {"flow_mult": 1.8, "stream_radius": 32.0, "golden_chance": 0.1}},
]
## Bling on the nozzle: each piece bought once, always on.
const BLING := [
	{"id": "fuzzy_dice", "name": "Dés en minou", "helps": "luck +10", "price": 500, "fx": {"luck": 10.0}},
	{"id": "pine", "name": "Sapin parfumé", "helps": "cars wait 20% longer", "price": 700, "fx": {"patience_mult": 1.2}},
	{"id": "hula", "name": "Danseuse hula", "helps": "the first car of each day tips double", "price": 800, "fx": {"first_car_tip_mult": 2.0}},
	{"id": "flame_decal", "name": "Flammes", "helps": "chains climb 1 higher", "price": 1200, "fx": {"combo_max": 1}},
	{"id": "coupons", "name": "Livret de coupons", "helps": "shop upgrades 10% cheaper", "price": 1000, "fx": {"upgrade_discount": 0.10}},
	{"id": "medal", "name": "Médaille de saint Christophe", "helps": "once a day, an overfill doesn't break the chain", "price": 1400, "fx": {"overfill_saves": 1}},
	{"id": "bobblehead", "name": "Bobblehead", "helps": "+5% tip per chain step", "price": 1600, "fx": {}},
	{"id": "rabbit", "name": "Patte de lapin", "helps": "every 10th car's gas goes back in the tank", "price": 1800, "fx": {"refund_every": 10}},
]
## Perks: tiers, each tier costs more (price × tier).
const PERKS := [
	{"id": "lucky", "name": "Bonne étoile", "helps": "luck +5", "price": 400, "tiers": 4, "fx": {"luck": 5.0}},
	{"id": "morning_rush", "name": "Rush du matin", "helps": "+1 car waiting when you open", "price": 600, "tiers": 3, "fx": {"queue": 1}},
	{"id": "reroll", "name": "Rebrasser", "helps": "1 reroll per delivery", "price": 800, "tiers": 2, "fx": {"rerolls": 1}},
	{"id": "contract", "name": "Contrat du fournisseur", "helps": "gas prices rise 20% slower", "price": 1000, "tiers": 3, "fx": {"price_rise_mult": 0.8}},
	{"id": "premium", "name": "Super sans plomb", "helps": "premium gas: every sale pays 10% more", "price": 1000, "tiers": 3, "fx": {"sale_mult": 1.1}},
	{"id": "jackpot", "name": "Jackpot", "helps": "3% of fills tip x4", "price": 1200, "tiers": 2, "fx": {"jackpot_chance": 0.03}},
	{"id": "tube_man", "name": "Bonhomme gonflable", "helps": "siphons passing cars' gas into your tank; tier 2 drops them on your lot", "price": 1400, "tiers": 2, "fx": {"tube_man": 1}},
	{"id": "big_cards", "name": "Plus de choix", "helps": "4 cards per delivery", "price": 2000, "tiers": 1, "fx": {"cards_offered": 1}},
]

## Round 10 batch B: the rival across the road. Every run starts 50/50 with Gaétan; win at 100% market
## share, lose at 0%. Reputation comes from your fills; each night Gaétan's specials take some back, and
## the market share moves toward your reputation by at most SHARE_STEP points (people switch slowly).
const START_SHARE := 50.0
const START_REPUTATION := 50.0
const REPUTATION := {ScoreTiers.SUPER_PERFECT: 1.8, ScoreTiers.PERFECT: 1.1, ScoreTiers.GOOD: 0.5, ScoreTiers.OK: 0.0,
	ScoreTiers.MISS: -0.75, ScoreTiers.UNSERVED: -0.5}
const GAETAN_PUSH := 0.5
const GAETAN_PUSH_GROWTH := 0.03  # round 11: his push grows this much each day
const SHARE_STEP := 5.0
## A game hour lasts this many real seconds (7 h to 13 h = 27 s; to 23 h = 72 s).
const HOUR_SECONDS := 4.5
const OPEN_HOUR := 7.0
## Gas price: pump price per litre, and the wholesale price the truck starts at, rising per delivery.
const PUMP_PRICE := 2.0
const WHOLESALE_START := 1.2  # balance bot (#37): fresh runs reach about day 13
const PRICE_RISE := 0.25  # balance bot campaign (#37): day 50 takes about 2 h of Garage upgrades


static func branch(id: String) -> Dictionary:
	for b in BRANCHES:
		if b.id == id:
			return b
	return {}


static func link(id: String) -> Dictionary:
	for l in LINKS:
		if l.id == id:
			return l
	return {}


## Any shop upgrade by id (a branch node or a link), or {}.
static func shop_node(id: String) -> Dictionary:
	for b in BRANCHES:
		for n in b.nodes:
			if n.id == id:
				return n
	return link(id)


static func card(id: String) -> Dictionary:
	for c in CARDS:
		if c.id == id:
			return c
	return {}


static func item(list: Array, id: String) -> Dictionary:
	for i in list:
		if i.id == id:
			return i
	return {}


## Adds one item's effects into `mods`, following FX_OPS.
static func apply_fx(mods: Dictionary, fx: Dictionary, times := 1) -> void:
	for k in fx:
		for t in times:
			match FX_OPS.get(k, "add"):
				"add":
					mods[k] = mods.get(k, 0) + fx[k]
				"mul":
					mods[k] = mods.get(k, 1.0) * fx[k]
				"max":
					mods[k] = maxf(mods.get(k, 0.0), fx[k])
