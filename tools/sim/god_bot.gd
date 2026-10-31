extends SceneTree
## GOD PUMP balance bot (#37): plays the real game headless (GodPump's own simulation, RunState's own
## rules), run after run, and reports how far runs get. The bot chases a moving car with the mouse at a
## human-ish speed, pours, and lets go aiming for an even split of Topped off / Perfect / Good / OK /
## overfill (the designer's assumption). At night it buys upgrades and calls the truck just in time.
##
##     godot --headless -s tools/sim/god_bot.gd -- 20 fresh      (runs, meta level: fresh | mid | late)
##     (round 11: no campaign mode: the Garage is in the run, paid with its XP; every run starts fresh)

const DT := 0.05
const AIM_SPEED := 900.0  # px/s the "mouse" moves
const REACT := 0.25  # seconds between letting go and moving on
const PRIORITY := ["hours", "marketing", "nozzle", "attractions", "service", "tank", "vibe", "truck", "multi"]

var runs := 20
var level := "fresh"
var out_path := ""


var _started := false


func _process(_dt: float) -> bool:
	if _started:
		return true
	_started = true
	_run_all()
	return true


func _run_all() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		runs = int(args[0])
	if args.size() > 1:
		level = args[1]
	if args.size() > 2:
		out_path = args[2]
	var results := []
	var t0 := Time.get_ticks_msec()
	for i in runs:
		results.append(play_run(i + 1, _meta()))
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.days < b.days)
	var days := results.map(func(r: Dictionary) -> int: return r.days)
	var total := 0
	for d in days:
		total += d
	var wins := results.filter(func(r: Dictionary) -> bool: return r.won).size()
	var lines := [
		"GOD PUMP bot: %d runs, meta %s, %.0f s" % [runs, level, (Time.get_ticks_msec() - t0) / 1000.0],
		"days survived: median %d, mean %.1f, min %d, max %d; won (100%% share): %d" % [days[days.size() / 2], float(total) / runs, days[0], days[-1], wins],
		"per run (days / deliveries / cars / XP / cash at end): " + ", ".join(results.map(func(r: Dictionary) -> String: return "%d/%d/%d/%d/$%.0f" % [r.days, r.deliveries, r.cars, r.xp, r.cash])),
		"mean per run: XP %.0f, play time %.1f min  ->  %.0f XP per hour of play" % [_mean(results, "xp"), _mean(results, "minutes"), _mean(results, "xp") / maxf(_mean(results, "minutes"), 0.01) * 60.0],
		"mean per day: loot $%.0f, gas used $%.0f, cars %.1f" % [_mean(results, "loot_per_day"), _mean(results, "gas_per_day"), _mean(results, "cars_per_day")],
		"market share at the end: " + ", ".join(results.map(func(r: Dictionary) -> String: return "%d%%" % int(r.share))) + "; lost to Gaétan (0%%): %d" % results.filter(func(r: Dictionary) -> bool: return r.lost).size(),
	]
	for l in lines:
		print(l)
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		f.store_string("\n".join(lines) + "\n")
		f.close()


func _mean(results: Array, key: String) -> float:
	var s := 0.0
	for r in results:
		s += r[key]
	return s / maxf(results.size(), 1.0)


func _meta() -> MetaState:
	var m := MetaState.new()
	m.path = ""
	match level:
		"mid":
			m.total_cars = 400
			m.perk_tiers = {"lucky": 2, "nest_egg": 2, "morning_rush": 1, "truck_friend": 1, "slot": 1}
			m.owned_bling = ["receipt", "hula", "pine"]
			m.equipped_bling = ["receipt", "hula"]
		"contract3":
			m.perk_tiers = {"contract": 3}
		"c2p2":
			m.perk_tiers = {"contract": 2, "premium": 2}
		"c3p3":
			m.perk_tiers = {"contract": 3, "premium": 3}
		"late_c3":
			m.total_cars = 1500
			m.perk_tiers = {"lucky": 4, "nest_egg": 3, "morning_rush": 3, "truck_friend": 2, "slot": 2, "jackpot": 2, "reroll": 1, "big_cards": 1, "head_start": 1, "contract": 3}
			m.owned_nozzles = ["classique", "laser"]
			m.nozzle = "laser"
			m.owned_bling = ["receipt", "hula", "rabbit"]
			m.equipped_bling = ["receipt", "hula", "rabbit"]
		"late":
			m.total_cars = 1500
			m.perk_tiers = {"lucky": 4, "nest_egg": 3, "morning_rush": 3, "truck_friend": 2, "slot": 2, "jackpot": 2, "reroll": 1, "big_cards": 1, "head_start": 1}
			m.owned_nozzles = ["classique", "laser"]
			m.nozzle = "laser"
			m.owned_bling = ["receipt", "hula", "rabbit"]
			m.equipped_bling = ["receipt", "hula", "rabbit"]
	return m


func play_run(seed: int, meta: MetaState) -> Dictionary:
	var run := RunState.new(meta)
	run.rng.seed = seed
	var day: GodPump = load("res://scenes/god/day/god_pump.tscn").instantiate()
	day.sound_on = false
	day.view = "flat"
	day.managed = true
	root.add_child(day)
	day.rng.seed = seed * 7919
	var gas_used := 0.0
	var seconds := 0.0  # a person's play time: each day's clock, plus ~25 s for the report and night
	var last_gas := 150.0
	while not run.over:
		var tank_before := run.tank
		day.market_share = run.share
		day.start_day(run.mods(), run.tank, run.day, run.unlocked_cars())
		seconds += (run.mods().close_hour - GodData.OPEN_HOUR) * GodData.HOUR_SECONDS + 25.0
		_play_day(day)
		var report := day.day_report()
		last_gas = maxf(tank_before - report.tank_left, 1.0)
		gas_used += last_gas
		run.end_day(report)
		if run.over:
			break
		_night(run, last_gas)
		_garage(run)
		if run.tank < 1.0 and run.call_truck():  # dry: a partial delivery with whatever cash is left
			if not run.offer.is_empty():
				run.pick_card(_best_card(run))
		if run.bankrupt() or run.tank < 1.0:
			break
		run.next_day()
	day.queue_free()
	return {"days": run.day, "won": run.won, "share": run.share, "lost": run.lost_to_gaetan, "deliveries": run.deliveries, "cars": run.totals.cars, "xp": run.xp,
		"cash": run.cash, "loot_per_day": run.totals.loot / run.day, "gas_per_day": gas_used / run.day,
		"cars_per_day": float(run.totals.cars) / run.day, "minutes": seconds / 60.0}


## One day of play: chase, pour, let go at the planned fill, move on.
func _play_day(day: GodPump) -> void:
	var aim := Vector2(GodPump.WIDTH * 0.5, 380)
	var car: ProtoCar = null
	var plan := 1.0
	var overfill := 0.0
	var wait := 0.0
	var guard := 0
	while not day.round_over and guard < 20000:
		guard += 1
		if wait > 0.0:
			wait -= DT
		elif not car or not is_instance_valid(car) or not car.accepts_fuel():
			car = _pick(day, aim)
			if car:
				var roll := day.rng.randi() % 5  # the even split
				plan = [0.998, 0.982, 0.935, 0.85, 1.0][roll]
				overfill = day.rng.randf_range(0.4, 1.5) if roll == 4 else 0.0
		if car and is_instance_valid(car) and car.accepts_fuel() and wait <= 0.0:
			var gap := car.position - aim
			aim += gap.normalized() * minf(gap.length(), AIM_SPEED * DT)
			day.aim(aim)
			if gap.length() < 12.0:
				day.set_pouring(true)
				# Stop on the planned fill exactly (the even split is about outcomes, not the bot's timer).
				var rate := day.flow_rate * car.fill_speed
				var left := plan * car.target - car.amount
				if overfill == 0.0 and left > 0.0 and left < rate * DT:
					day.step(left / rate)
				var done := car.fill() >= plan - 0.0001 and (overfill == 0.0 or car.spilled >= overfill)
				if done:
					day.set_pouring(false)
					car = null
					wait = REACT
			else:
				day.set_pouring(false)
		else:
			day.set_pouring(false)
		day.step(DT)


func _pick(day: GodPump, from: Vector2) -> ProtoCar:
	var best: ProtoCar = null
	var best_d := INF
	for c in day.cars:
		if c.customer and c.accepts_fuel() and not c.drone_target and c.fill() < 0.8:
			var d := from.distance_to(c.position)
			if d < best_d:
				best_d = d
				best = c
	return best


## The night: keep enough for the truck when the tank won't last two more days; buy upgrades with the
## rest (cheapest first, in priority order); call the truck when the tank won't last tomorrow.
func _night(run: RunState, last_gas: float) -> void:
	if run.tank < last_gas * 1.3 and run.cash >= run.delivery_cost() and run.delivery_cost() > 0.0:
		run.call_truck()
		run.pick_card(_best_card(run))
	var reserve := run.delivery_cost() if run.tank < last_gas * 2.5 else 0.0
	var bought := true
	while bought:
		bought = false
		var cheapest := ""
		var cheapest_p := INF
		for b in PRIORITY:
			var node := run.next_node(b)
			if node.is_empty():
				continue
			var p := run.node_price(node)
			if p < cheapest_p:
				cheapest_p = p
				cheapest = b
		for l in GodData.LINKS:  # the upgrades with two parents, once both are owned
			if run.link_open(l.id) and run.node_price(l) < cheapest_p:
				cheapest_p = run.node_price(l)
				cheapest = "link:" + l.id
		if cheapest != "" and run.cash - cheapest_p >= reserve:
			bought = run.buy_link(cheapest.substr(5)) if cheapest.begins_with("link:") else run.buy(cheapest)


func _best_card(run: RunState) -> String:
	var order := ["poach", "golden_hose", "spy", "twin_stream", "golden_chain", "drone_card", "rumour", "combo_lock",
		"coin_rain", "happy_hour", "recycler", "patient", "gas_saver", "price_freeze", "devil", "double_or_nothing"]
	for id in order:
		if id in run.offer:
			return id
	return run.offer[0] if not run.offer.is_empty() else ""


## Round 11: the Garage is a night tab paid with this run's XP. What the bot buys, in order, when it can.
const GARAGE_ORDER := [["nozzle", ""], ["perk", "contract"], ["perk", "premium"], ["nozzle", ""], ["bling", "pine"],
	["perk", "contract"], ["perk", "premium"], ["nozzle", ""], ["bling", "flame_decal"], ["perk", "tube_man"],
	["bling", "medal"], ["perk", "contract"], ["perk", "premium"], ["nozzle", ""], ["bling", "hula"], ["perk", "lucky"],
	["bling", "rabbit"], ["perk", "jackpot"], ["perk", "reroll"], ["bling", "bobblehead"], ["perk", "big_cards"]]


## Spends the run's XP in the Garage, first affordable thing in GARAGE_ORDER, again and again.
func _garage(run: RunState) -> void:
	var bought := true
	while bought:
		bought = false
		for item in GARAGE_ORDER:
			var ok := false
			match item[0]:
				"nozzle":
					ok = run.buy_nozzle()
				"perk":
					ok = run.buy_perk(item[1])
				"bling":
					ok = run.buy_bling(item[1])
			if ok:
				bought = true
				break
