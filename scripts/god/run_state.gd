class_name RunState
extends RefCounted
## One GOD PUMP run (docs/GOD_PUMP_PLAN.md): the day, the cash, the station's tank (in pump dollars),
## the fuel truck (the bill: each delivery raises the price, and lets you pick 1 of 3 cards), the shop
## upgrades bought, the cards picked, and the run's totals. Pure rules, no drawing: GodGame drives it,
## the tests and the balance bot play it. Serves: Advancement (the build) and tension (when to call
## the truck).

## The smallest delivery the truck will make: below this, with a dry tank, the run is over.
const MIN_DELIVERY := 20.0

var meta: MetaState
var rng := RandomNumberGenerator.new()
var day := 1
var cash := 60.0
var tank := 800.0
var price := GodData.WHOLESALE_START  # wholesale, per litre
var deliveries := 0
var owned := {}  # branch id -> nodes bought
var links: Array = []  # the two-parent upgrades bought (GodData.LINKS ids)
var cards: Array = []
var price_frozen := false
var next_delivery_extra := 0.0
var xp := 0
var totals := {"cars": 0, "loot": 0.0, "supers": 0, "perfects": 0, "goods": 0, "oks": 0, "misses": 0, "unserved": 0, "best_combo": 1}
var over := false
var won := false
## Round 10 batch B: the fight for Saint-Clin-Clin. `share` is your market share (the cars that want gas
## and pick you), `reputation` what the village thinks of your pours. Both 0–100.
var share := GodData.START_SHARE
var reputation := GodData.START_REPUTATION
var lost_to_gaetan := false
## What Dad handed over on day 1 (cash + the full tank at the starting price): the owner's capital on the
## balance sheet; everything above it is retained earnings.
var start_capital := 0.0
## Last night's numbers, for the report: {share_from, share_to, rep_from, rep_to}.
var last_night := {}
## Round 8, for the newspaper's charts: the wholesale price after each delivery (the first entry is
## the starting price), and the cash at the end of each day.
var price_history: Array = []
var cash_history: Array = []
## The cards offered at the current delivery (empty when none is pending).
var offer: Array = []
var rerolls_left := 0


func _init(m: MetaState = null) -> void:
	if m:
		meta = m
	else:
		meta = MetaState.new()
		meta.path = ""  # a run without a meta (tests, the bot) saves nothing
	var mods := GodMods.compute(self)
	cash = mods.start_cash
	tank = mods.tank_capacity  # Dad's last delivery: the tank starts full
	price_history = [price]
	start_capital = cash + tank / GodData.PUMP_PRICE * price


func mods() -> Dictionary:
	return GodMods.compute(self)


func tank_capacity() -> float:
	return mods().tank_capacity


# --- The night shop -----------------------------------------------------------------------------

func next_node(branch_id: String) -> Dictionary:
	var b := GodData.branch(branch_id)
	var level: int = owned.get(branch_id, 0)
	if not b.is_empty() and level == 0 and b.has("root") and not owns(b.root):
		return {}  # a branch hanging off another upgrade opens once that upgrade is owned
	return b.nodes[level] if not b.is_empty() and level < b.nodes.size() else {}


func node_price(node: Dictionary) -> float:
	return roundf(node.price * (1.0 - mods().upgrade_discount))


## Do I own this shop upgrade (a branch node or a link)?
func owns(node_id: String) -> bool:
	if node_id in links:
		return true
	for b in GodData.BRANCHES:
		var level: int = owned.get(b.id, 0)
		for i in level:
			if b.nodes[i].id == node_id:
				return true
	return false


## A link can be bought once both of its parents are owned.
func link_open(id: String) -> bool:
	var l := GodData.link(id)
	if l.is_empty() or id in links:
		return false
	for need in l.needs:
		if not owns(need):
			return false
	return true


func buy_link(id: String) -> bool:
	if not link_open(id):
		return false
	var p := node_price(GodData.link(id))
	if cash < p:
		return false
	cash -= p
	links.append(id)
	return true


func buy(branch_id: String) -> bool:
	var node := next_node(branch_id)
	if node.is_empty():
		return false
	var p := node_price(node)
	if cash < p:
		return false
	cash -= p
	owned[branch_id] = owned.get(branch_id, 0) + 1
	return true


# --- The fuel truck -----------------------------------------------------------------------------

## What a full delivery costs right now.
func delivery_cost() -> float:
	var missing := maxf(tank_capacity() - tank, 0.0)
	var cost := missing / GodData.PUMP_PRICE * price
	var m := mods()
	if deliveries == 0:
		cost *= 1.0 - m.first_delivery_discount
	if tank < tank_capacity() * 0.25:
		cost *= 1.0 - m.bulk_discount  # Achat en vrac: stretch the tank, buy in bulk
	return roundf(cost * (1.0 + next_delivery_extra))


## The truck fills the tank, or, if the cash is short, brings as much gas as the cash buys (at least
## MIN_DELIVERY). A delivery of half a tank or more offers cards to pick from.
func call_truck() -> bool:
	var cost := delivery_cost()
	if cost <= 0.0 or cash < minf(cost, MIN_DELIVERY):
		return false
	var pay := minf(cost, cash)
	var share := pay / cost
	cash -= pay
	tank = tank_capacity() if share >= 0.999 else tank + (tank_capacity() - tank) * share
	var frozen := next_delivery_frozen()
	deliveries += 1
	next_delivery_extra = 0.0
	if price_frozen:
		price_frozen = false
	elif not frozen:
		var rise := price_rise()
		if share < 0.999:
			rise *= mods().partial_rise_mult  # Citerne usagée: a partial delivery rises less
		price *= 1.0 + rise
	price_history.append(price)
	rerolls_left = int(mods().rerolls)
	offer = draw_cards(int(mods().cards_offered)) if share >= 0.5 else []
	return true


## How much the wholesale price rises with each delivery (the supplier's contract slows it, the
## devil doubles it).
func price_rise() -> float:
	return GodData.PRICE_RISE * mods().price_rise_mult * (2.0 if "devil" in cards else 1.0)


## The next delivery won't raise the price: a Gel des prix card, or the forward contract's turn.
func next_delivery_frozen() -> bool:
	var every := int(mods().freeze_every)
	return price_frozen or (every > 0 and (deliveries + 1) % every == 0)


## Out of gas and can't afford even a small delivery: the run is over.
func bankrupt() -> bool:
	return tank < 1.0 and cash < minf(delivery_cost(), MIN_DELIVERY)


## About how much gas a day burns, from this run so far (a cautious guess before the first day).
func gas_per_day() -> float:
	return maxf(totals.loot / maxf(day, 1) * 1.1, 90.0)


func days_of_gas() -> float:
	return tank / gas_per_day()


## The tank probably won't last tomorrow.
func tank_warning() -> bool:
	return days_of_gas() < 1.2 and delivery_cost() > 0.0


## Spending `price` now would leave too little to call the truck when the tank needs it.
func purchase_risky(price: float) -> bool:
	return tank_warning() and cash - price < delivery_cost()


## `n` different cards, weighted by rarity; luck tilts the odds toward rare and legendary.
func draw_cards(n: int) -> Array:
	var luck: float = mods().luck
	var weights := {"common": GodData.RARITY_WEIGHT.common, "rare": GodData.RARITY_WEIGHT.rare + luck * 0.6,
		"legendary": GodData.RARITY_WEIGHT.legendary + luck * 0.25}
	var pool := []
	for c in GodData.CARDS:
		pool.append(c.id)
	var out := []
	while out.size() < n and not pool.is_empty():
		var total := 0.0
		for id in pool:
			total += weights[GodData.card(id).rarity]
		var pick := rng.randf() * total
		for id in pool:
			pick -= weights[GodData.card(id).rarity]
			if pick <= 0.0:
				out.append(id)
				pool.erase(id)
				break
	return out


func reroll() -> bool:
	if rerolls_left <= 0 or offer.is_empty():
		return false
	rerolls_left -= 1
	offer = draw_cards(offer.size())
	return true


func pick_card(id: String) -> bool:
	if not id in offer:
		return false
	cards.append(id)
	offer = []
	match id:
		"price_freeze":
			price_frozen = true
		"loan":
			cash += 300.0
			next_delivery_extra = 0.4
	return true


# --- Days ---------------------------------------------------------------------------------------

## Folds a finished day into the run: its cash, gas left, XP and stats.
func end_day(report: Dictionary) -> void:
	var before := unlocked_cars()  # to announce what today's XP unlocks
	cash += report.get("loot", 0.0)
	tank = minf(report.get("tank_left", tank), tank_capacity())  # the tube man can't overfill it
	xp += report.get("xp", 0)
	totals.cars += report.get("cars", 0)
	totals.loot += report.get("loot", 0.0)
	var t: Dictionary = report.get("tiers", {})
	totals.supers += t.get(ScoreTiers.SUPER_PERFECT, 0)
	totals.perfects += t.get(ScoreTiers.PERFECT, 0)
	totals.goods += t.get(ScoreTiers.GOOD, 0)
	totals.oks += t.get(ScoreTiers.OK, 0)
	totals.misses += t.get(ScoreTiers.MISS, 0)  # overfilled
	totals.unserved += t.get(ScoreTiers.UNSERVED, 0)
	totals.best_combo = maxi(totals.best_combo, report.get("best_combo", 1))
	cash_history.append(cash)
	_fight_for_the_village(report.get("rep", 0.0))
	last_night.unlocked = unlocked_cars().filter(func(id: String) -> bool: return not id in before)


## Round 10 D: the car types this run has unlocked, by the XP earned in it (a difficulty ladder).
func unlocked_cars() -> Array:
	return GodData.CAR_ORDER.filter(func(id: String) -> bool: return xp >= GodData.CAR_TYPES[id].unlock)


## The next car type this run unlocks: {id, name, have, need}, or {} when all are in.
func next_unlock() -> Dictionary:
	for id in GodData.CAR_ORDER:
		var need: int = GodData.CAR_TYPES[id].unlock
		if xp < need:
			return {"id": id, "name": GodData.CAR_TYPES[id].name, "have": xp, "need": need}
	return {}


## The night after a day: your fills move your reputation, Gaétan's specials take some back, and the
## village follows your reputation, a few points a night. 100% wins the run; 0% loses it.
func _fight_for_the_village(rep_gain: float) -> void:
	last_night = {"share_from": share, "rep_from": reputation}
	reputation = clampf(reputation + rep_gain - GodData.GAETAN_PUSH, 0.0, 100.0)
	share = move_toward(share, reputation, GodData.SHARE_STEP)
	last_night.share_to = share
	last_night.rep_to = reputation
	if share >= 100.0:
		won = true
		over = true
	elif share <= 0.0:
		lost_to_gaetan = true
		over = true


## The books for a day (round 10, playtest 9): a P&L at wholesale cost and a balance sheet. Gas is in
## pump dollars in the game; the books count it at what the truck charged (`price` per litre).
func books(report: Dictionary) -> Dictionary:
	var at_cost := func(pump_dollars: float) -> float: return pump_dollars / GodData.PUMP_PRICE * price
	var sales: float = report.get("sales", 0.0)
	var tips: float = report.get("tips", 0.0)
	var gas_sold: float = at_cost.call(report.get("litres", 0.0) * GodData.PUMP_PRICE)
	var spills: float = at_cost.call(report.get("wasted", 0.0))
	var drones: float = at_cost.call(report.get("drone_gas", 0.0))
	var fines: float = report.get("fines", 0.0)
	var net := sales + tips - gas_sold - spills - drones - fines
	var equipment := 0.0
	for b in GodData.BRANCHES:
		for i in owned.get(b.id, 0):
			equipment += b.nodes[i].price
	for id in links:
		equipment += GodData.link(id).price
	var gas_in_tank: float = at_cost.call(tank)
	var loan := 300.0 if next_delivery_extra > 0.0 else 0.0  # the cousin's loan, repaid on the next delivery
	var assets := cash + gas_in_tank + equipment
	var equity := assets - loan
	return {"sales": sales, "tips": tips, "gas_sold": gas_sold, "spills": spills, "drones": drones, "fines": fines,
		"net": net, "cash": cash, "gas_in_tank": gas_in_tank, "equipment": equipment, "assets": assets,
		"loan": loan, "liabilities": loan, "equity": equity, "capital": start_capital, "retained": equity - start_capital}


func next_day() -> void:
	day += 1


## Ends the run and banks it in the meta: XP, cars, best day.
func finish() -> void:
	over = true
	meta.xp += xp
	meta.total_cars += totals.cars
	meta.runs += 1
	meta.best_day = maxi(meta.best_day, day)
	meta.best_share = maxf(meta.best_share, share)
	if won:
		meta.ending_seen = true
	meta.bank_run(self)
	meta.save()
