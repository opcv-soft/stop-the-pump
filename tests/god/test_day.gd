extends GutTest
## Spec: features/god_day.feature (#37): what shapes a GOD PUMP day.

const SCENE := preload("res://scenes/god/day/god_pump.tscn")

var game: GodPump


func before_each() -> void:
	game = SCENE.instantiate()
	game.auto_traffic = false
	game.sound_on = false
	game.view = "flat"
	add_child_autofree(game)
	game.rng.seed = 11


func _mods(changes := {}) -> Dictionary:
	var m := GodData.BASE.duplicate()
	for k in changes:
		m[k] = changes[k]
	return m


func _open(changes := {}, pool := ["sedan"]) -> void:
	game.start_day(_mods(changes), 800.0, 1, pool)


func _parked(type_id := "sedan", at := Vector2(500, 380), target := 20.0) -> ProtoCar:
	var car := game.park_customer(target, at)
	car.set_type(type_id, game.rng)
	car.target = target
	car.moving = false
	return car


func test_the_clock_limits_the_day() -> void:
	_open()
	assert_almost_eq(game.round_seconds, 27.0, 0.01)
	assert_almost_eq(game.hour_now(), 7.0, 0.01)
	for i in 28:
		game.step(1.0)
	assert_true(game.round_over)


func test_marketing_queues_cars_at_opening() -> void:
	_open({"queue": 3})
	var waiting := game.cars.filter(func(c: ProtoCar) -> bool: return c.customer and c.accepts_fuel())
	assert_eq(waiting.size(), 3)


func test_auto_aim_bends_the_stream_onto_a_nearby_car() -> void:
	_open({"auto_aim": 60.0})
	var car := _parked()
	game.aim(car.position + Vector2(70, 0))
	game.set_pouring(true)
	game.step(1.0)
	assert_gt(car.amount, 3.0)


func test_without_auto_aim_the_same_pour_misses() -> void:
	_open()
	var car := _parked()
	game.aim(car.position + Vector2(70, 0))
	game.set_pouring(true)
	game.step(1.0)
	assert_almost_eq(car.amount, 0.0, 0.001)


func test_a_drone_fills_and_settles_a_car() -> void:
	_open({"drones": 1})
	var car := _parked()
	for i in 200:
		game.step(0.1)
		if car.tier != "":
			break
	assert_ne(car.tier, "")
	assert_true(car.by_drone)


func test_the_pickup_pays_80_percent() -> void:
	_open()
	var car := _parked("pickup", Vector2(500, 380), 50.0)
	car.amount = 50.0
	game._settle(car)
	assert_almost_eq(game.round_sales, 40.0, 0.01)


func test_the_bazou_takes_fuel_slower() -> void:
	_open()
	var car := _parked("bazou")
	game.aim(car.position)
	game.set_pouring(true)
	game.step(1.0)
	assert_almost_eq(car.amount, game.flow_rate * 0.6, 0.05)


func test_the_thief_siphons_gas_and_pouring_scares_it() -> void:
	_open({}, ["sedan", "thief"])
	var victim := _parked("sedan", Vector2(500, 380))
	victim.amount = 15.0
	var thief := game.park_customer(0.0, Vector2(540, 380))
	thief.set_type("thief", game.rng)
	thief.moving = false
	for i in 20:
		game.step(0.1)
	assert_lt(victim.amount, 15.0)
	assert_gt(game.stolen, 0.0)
	game.aim(thief.position)
	game.set_pouring(true)
	game.step(0.1)
	assert_eq(thief.phase, ProtoCar.Phase.LEAVING)


func test_pouring_on_the_electric_car_costs_a_fine() -> void:
	_open({}, ["sedan", "electric"])
	var e := game.park_customer(0.0, Vector2(500, 380))
	e.set_type("electric", game.rng)
	e.moving = false
	game.aim(e.position)
	game.set_pouring(true)
	game.step(0.1)
	assert_almost_eq(game.fines, 10.0, 0.01)


func test_the_sweeper_cleans_puddles() -> void:
	_open()
	game._spill(Vector2(500, 380), 2.0)
	var sw := game.park_customer(0.0, Vector2(500, 380))
	sw.set_type("sweeper", game.rng)
	sw.moving = false
	game.step(0.1)
	assert_eq(game.puddles.size(), 0)


func test_the_clumsy_car_makes_others_spill() -> void:
	_open()
	var victim := _parked("sedan", Vector2(500, 380))
	victim.amount = 12.0
	var clumsy := _parked("clumsy", Vector2(530, 380))
	game.step(0.1)
	assert_lt(victim.amount, 12.0)
	assert_gt(game.round_wasted, 0.0)


func test_a_car_waiting_too_long_drives_off_unserved() -> void:
	_open()
	game.reset_day_stats()
	var car := _parked()
	car.patience = 2.0
	for i in 30:
		game.step(0.1)
	assert_eq(game.day_stats.tiers[ScoreTiers.UNSERVED], 1)
	assert_eq(car.phase, ProtoCar.Phase.LEAVING)


func test_combo_lock_keeps_the_chain_on_an_ok() -> void:
	_open({"combo_lock": 1})
	var a := _parked("sedan", Vector2(400, 380))
	a.amount = 20.0
	game._settle(a)
	var before: int = game.combo.multiplier
	var b := _parked("sedan", Vector2(700, 380))
	b.amount = 17.0
	game._settle(b)
	assert_eq(game.combo.multiplier, before)


func test_shop_bonuses_reach_the_till() -> void:
	_open({"per_car_bonus": 2.0, "tip_mult": 2.0})
	var car := _parked()
	car.amount = 20.0
	game._settle(car)
	assert_almost_eq(game.round_sales, 22.0, 0.01)
	assert_almost_eq(car.tip, game.tip_for(1.0, 0.0) * 2.0, 0.01)


func test_the_day_report_and_the_signal() -> void:
	game.managed = true
	_open()
	watch_signals(game)
	var car := _parked()
	car.amount = 20.0
	game._settle(car)
	game.end_round()
	assert_signal_not_emitted(game, "day_over", "the stacks go into the register first")
	for i in 40:
		game.step(0.05)
	assert_signal_emitted(game, "day_over")
	var r: Dictionary = game.day_report()
	for key in ["loot", "tank_left", "xp", "cars", "tiers", "accuracy", "best_combo"]:
		assert_true(r.has(key), key)
	assert_eq(r.cars, 1)


# --- Round 8: the new upgrades in the day (features/god_shop.feature) --------------------------

## Fills a parked car to 99.6% and settles it; returns what it paid.
func _fill(car: ProtoCar) -> float:
	car.amount = car.target * 0.996
	game._settle(car)
	return car.paid


func test_a_car_that_waited_buys_a_coffee() -> void:
	_open({"coffee_sale": 1.0})
	var quick := _parked("sedan", Vector2(400, 380))
	var slow := _parked("sedan", Vector2(600, 380))
	slow.waited = 4.0
	var a := _fill(quick)
	var b := _fill(slow)
	assert_almost_eq(b - quick.tip, a - quick.tip + 1.0, 0.01 + absf(slow.tip - quick.tip))


func test_every_fifth_car_is_a_regular_who_tips_double() -> void:
	_open({"loyalty_every": 5})
	var tips := []
	for i in 5:
		var car := _parked("sedan", Vector2(300 + i * 90, 380))
		_fill(car)
		tips.append(car.tip)
	assert_almost_eq(tips[4], tips[0] * 2.0, 0.01)


func test_night_neons_raise_tips_after_19h() -> void:
	game.start_day(_mods({"night_tip_mult": 1.3, "close_hour": 23.0}), 800.0, 1, ["sedan"])
	var early := _parked("sedan", Vector2(400, 380))
	_fill(early)
	game.round_t = game.round_seconds * 0.8  # 7 h + 16 h * 0.8 = 19.8 h
	var late := _parked("sedan", Vector2(600, 380))
	_fill(late)
	assert_almost_eq(late.tip, early.tip * 1.3, 0.01)


func test_the_drone_hangar_pays_for_drone_fills() -> void:
	_open({"drone_bonus": 2.0})
	var a := _parked("sedan", Vector2(400, 380))
	var b := _parked("sedan", Vector2(600, 380))
	b.by_drone = true
	_fill(a)
	_fill(b)
	assert_almost_eq(b.paid - b.tip, a.paid - a.tip + 2.0, 0.01)


func test_hockey_night_brings_the_town() -> void:
	game.start_day(_mods({"hockey_every": 7}), 800.0, 7, ["sedan"])
	assert_true(game.hockey_night)
	var waiting := game.cars.filter(func(c: ProtoCar) -> bool: return c.customer and c.accepts_fuel())
	assert_eq(waiting.size(), 3)
	assert_true(game.day_report().hockey)
	game.start_day(_mods({"hockey_every": 7}), 800.0, 8, ["sedan"])
	assert_false(game.hockey_night)


func test_the_tank_alarm_speaks_when_gas_runs_low() -> void:
	_open({"tank_alarm": 1})
	game.tank = GodPump.LOW_GAS - 1.0
	game.step(0.1)
	assert_true(game._alarm_said)


# --- Round 8: Bonhomme gonflable --------------------------------------------------------------

func _road_car_near_the_tube_man() -> ProtoCar:
	var car := game.spawn_road_car()
	car.customer = false
	car.wants_in = false
	car.road_dir = 1.0
	car.position = Vector2(GodPump.TUBE_AT.x - 40.0, GodPump.ROAD_Y + 12.0)
	return car


func test_the_tube_man_siphons_a_passing_car_into_the_tank() -> void:
	_open({"tube_man": 1})
	var car := _road_car_near_the_tube_man()
	var tank_before := game.tank
	game._tube_cd = 0.0
	game.step(0.05)
	assert_eq(car.phase, ProtoCar.Phase.GRABBED, "grabbed off the road")
	for i in 60:
		game.step(0.05)
	assert_gt(game.tank, tank_before, "its gas went into the tank")
	assert_gt(game.day_report().tube_gas, 0.0)
	assert_true(car.phase in [ProtoCar.Phase.ROAD, ProtoCar.Phase.GONE], "tier 1 puts it back on the road")
	assert_false(car.customer, "not on the lot")


func test_tier_2_drops_the_emptied_car_on_the_lot_as_a_customer() -> void:
	_open({"tube_man": 2})
	var car := _road_car_near_the_tube_man()
	game._tube_cd = 0.0
	for i in 60:
		game.step(0.05)
	assert_true(car.customer)
	assert_true(car.accepts_fuel(), "it's on the lot, waiting for gas")
	assert_eq(car.amount, 0.0)


func test_no_tube_man_no_grabs() -> void:
	_open()
	var car := _road_car_near_the_tube_man()
	game._tube_cd = 0.0
	game.step(0.05)
	assert_eq(car.phase, ProtoCar.Phase.ROAD)


# --- Round 8: the regulars' routines ------------------------------------------------------------

func test_the_regulars_get_up_and_come_back() -> void:
	_open()
	var crew: RegularsCrew = game.crew
	var states := {}
	var had_coffee := false
	for i in 1200:  # two minutes of an open day
		crew.step(0.1, game.rng, true)
		for r in crew.list:
			states[r.state] = true
			if r.cup > 0.0:
				had_coffee = true
		assert_true(crew.away() <= RegularsCrew.MAX_AWAY, "the bench is never empty")
	assert_true(states.has("walk") and states.has("watch"), "they wander over to watch")
	assert_true(states.has("inside"), "and go in the dépanneur")
	assert_true(had_coffee, "and come back out with a coffee")


func test_the_regulars_cheer_from_wherever_they_are() -> void:
	_open()
	var r: Dictionary = game.regulars[0]
	r.state = "watch"
	r.cheer = 1.0
	assert_eq(RegularsCrew.pose(r), "cheer")
	r.state = "sit"
	assert_eq(RegularsCrew.pose(r), "sit_cheer")
	r.state = "inside"
	assert_eq(RegularsCrew.pose(r), "", "inside, nobody sees them")


func test_fast_cars_stay_on_the_lot() -> void:
	_open()
	var car := _parked("racer", Vector2(900, 560))
	car.moving = true
	car.heading = PI * 0.5  # pointing at the bottom curb, at racer speed
	for i in 200:
		game.step(0.05)
		assert_true(GodPump.LOT.has_point(car.position), "still on the lot at step %d" % i)
		if not car.accepts_fuel():
			break


# --- Round 9: the lore drives in and chats -----------------------------------------------------

func test_a_visitor_drives_in_chats_and_leaves() -> void:
	game.visit = Visitors.beat_for(2)
	game.start_day(_mods({"close_hour": 23.0}), 800.0, 2, ["sedan"])
	game.visit = Visitors.beat_for(2)  # start_day keeps the visit GodGame set
	var seen := []
	for i in 600:
		game.step(0.05)
		var said: String = game.chat_line.get("text", "") if not game.chat_line.is_empty() else (game.quip_text if game.quip_t > 0.0 else "")
		if said != "" and not said in seen:
			seen.append(said)
		if game._visit_done:
			break
	assert_true(game._visit_done, "the chat finished")
	assert_true(seen.any(func(s: String) -> bool: return s.begins_with("Gaétan:")), "the visitor spoke")
	assert_true(seen.any(func(s: String) -> bool: return s.begins_with("Ti-Guy:")), "a regular answered")
	assert_eq(game.visitor_car.phase, ProtoCar.Phase.LEAVING)


func test_the_postcards_come_with_the_mail_carrier() -> void:
	for d in [10, 20, 30, 40]:
		assert_eq(Visitors.beat_for(d).get("postcard", 0), d)
		assert_eq(Visitors.beat_for(d).who, "facteur")
	assert_true(Visitors.beat_for(3).is_empty(), "not every day")



# --- Round 9: Sabot de Denver --------------------------------------------------------------------

func test_a_clamped_thief_gives_the_gas_back() -> void:
	_open({"clamp_thief": 1})
	var victim := _parked("sedan", Vector2(500, 380))
	victim.amount = 15.0
	var thief := _parked("thief", Vector2(560, 380))
	thief.moving = true
	var tank_before := game.tank
	for i in 200:
		game.step(0.05)
		if thief.clamped:
			break
	assert_true(thief.clamped, "it tried to flee and got clamped")
	assert_gt(game.tank, tank_before, "what it stole went back in the tank")
	assert_eq(game.day_report().stolen, 0.0)


func test_without_clamps_the_thief_flees() -> void:
	_open()
	var victim := _parked("sedan", Vector2(500, 380))
	victim.amount = 15.0
	var thief := _parked("thief", Vector2(560, 380))
	thief.moving = true
	for i in 200:
		game.step(0.05)
	assert_false(thief.clamped)
	assert_ne(thief.phase, ProtoCar.Phase.WANDER, "gone with the gas")


func test_an_impatient_customer_gets_clamped_instead_of_leaving() -> void:
	_open({"clamp_wait": 1})
	game.reset_day_stats()
	var car := _parked()
	car.patience = 2.0
	for i in 25:
		game.step(0.1)
	assert_true(car.clamped)
	assert_true(car.accepts_fuel(), "still on the lot")
	assert_eq(game.day_stats.tiers[ScoreTiers.UNSERVED], 0)


# --- Round 10, batch A (playtest 9: focus) -------------------------------------------------------

func test_the_ring_spills_with_no_car_and_fills_one_car() -> void:
	_open()
	var car := _parked("sedan", Vector2(500, 380))
	game.aim(Vector2(800, 450))
	game.set_pouring(true)
	game.step(0.5)
	assert_true(game.cars_in_ring().is_empty())
	assert_gt(game.round_wasted, 1.0, "no car in the ring: it spills")
	game.aim(car.position + Vector2(game.ring_radius() * 0.8, 0))
	game.step(0.5)
	assert_eq(game.cars_in_ring(), [car])
	assert_gt(car.amount, 1.5, "a car inside the ring fills, even off-centre")


func test_double_jet_fills_both_cars_in_the_ring_at_full_speed_and_pays_both() -> void:
	_open({"twin_stream": 1})
	var a := _parked("sedan", Vector2(500, 380), 30.0)
	var b := _parked("sedan", Vector2(500 + game.ring_radius() * 0.9, 380), 30.0)
	game.aim(Vector2(500 + game.ring_radius() * 0.45, 380))
	game.set_pouring(true)
	game.step(1.0)
	assert_almost_eq(a.amount, game.flow_rate, 0.01)
	assert_almost_eq(b.amount, game.flow_rate, 0.01)
	a.amount = 29.9
	b.amount = 29.9
	game.set_pouring(false)
	assert_ne(a.tier, "", "the first car is graded")
	assert_ne(b.tier, "", "the second car is graded too (the playtest-9 bug)")
	assert_gt(b.paid, 0.0)


func test_without_double_jet_only_the_nearest_car_in_the_ring_fills() -> void:
	_open()
	var a := _parked("sedan", Vector2(500, 380), 30.0)
	var b := _parked("sedan", Vector2(500 + game.ring_radius() * 0.9, 380), 30.0)
	game.aim(Vector2(500 + game.ring_radius() * 0.3, 380))
	game.set_pouring(true)
	game.step(1.0)
	assert_gt(a.amount, 3.0)
	assert_almost_eq(b.amount, 0.0, 0.001)


func test_coins_come_in_four_values() -> void:
	assert_eq(GodPump.coins_for(27.0), [20, 5, 1, 1])
	assert_eq(GodPump.coins_for(76.4), [50, 20, 5, 1])
	assert_eq(GodPump.coins_for(0.4), [])


func test_paid_coins_lie_on_the_lot_then_fly_to_the_stacks() -> void:
	_open()
	var car := _parked("sedan", Vector2(500, 380), 25.0)
	car.amount = 25.0
	game._settle(car)
	for i in 30:
		game.step(0.05)
	assert_false(game.coins_on_lot().is_empty(), "playtest 10: coins stay on the lot a few seconds")
	assert_true(game.money.all(func(m: Dictionary) -> bool: return m.kind == "coin"))
	for i in 100:
		game.step(0.05)
	assert_true(game.money.is_empty(), "then they're all in the tray")
	assert_eq(game.stacks_value(), int(round(car.paid)))


func test_the_day_bar_runs_from_opening_to_closing() -> void:
	_open({"close_hour": 19.0})
	assert_almost_eq(game.day_progress(), 0.0, 0.001)
	game.round_t = game.round_seconds * 0.25
	assert_almost_eq(game.day_progress(), 0.25, 0.001)
	assert_almost_eq(game.hour_now(), 10.0, 0.01)


func test_the_regulars_never_speak_but_still_cheer() -> void:
	_open()
	var car := _parked()
	car.amount = 20.0
	game._settle(car)
	assert_eq(game.quip_text, "", "no speech bubbles")
	assert_true(game.regulars.all(func(r: Dictionary) -> bool: return r.cheer > 0.0))


func test_the_regulars_keep_to_the_store_side() -> void:
	for p in RegularsCrew.WATCH:
		assert_lt(p.x, GodPump.LOT.position.x + 40.0, "off the lot's play area")
	assert_lt(GodPump.VISITOR_SPOT.x, GodPump.LOT.position.x + 60.0, "visitors park in the corner by the store")


func test_a_flying_drone_burns_gas() -> void:
	_open({"drones": 1})
	var car := _parked("sedan", Vector2(1000, 560))
	game.drones[0].pos = Vector2(200, 200)
	var before := game.tank
	game.step(1.0)
	assert_eq(game.drones[0].state, "flying")
	assert_almost_eq(before - game.tank, GodPump.DRONE_BURN, 0.001)
	assert_almost_eq(game.day_report().drone_gas, GodPump.DRONE_BURN, 0.001)
	assert_almost_eq(car.amount, 0.0, 0.001)


func test_xp_is_litres_times_one_plus_average_combo_times_accuracy() -> void:
	assert_eq(GodPump.xp_formula(30.0, 2.0, 0.9), 81)
	_open()
	for i in 3:  # three Perfects in a row: combo paid x1, x2, x3 = 6 combo points
		var car := _parked("sedan", Vector2(300 + i * 150, 380), 20.0)
		car.amount = 19.6
		game._settle(car)
	var litres := 3 * 19.6 / game.economy.price_per_liter
	assert_almost_eq(game.day_stats.litres, litres, 0.01)
	assert_eq(game.day_stats.combo_points, 6)
	assert_almost_eq(game.avg_combo(), 2.0, 0.001)
	assert_eq(game.day_report().xp, GodPump.xp_formula(litres, 2.0, game.day_accuracy()))


func test_drone_fills_add_litres_but_no_combo_points() -> void:
	_open()
	var car := _parked()
	car.amount = 19.6
	car.by_drone = true
	game._settle(car)
	assert_gt(game.day_stats.litres, 0.0)
	assert_eq(game.day_stats.combo_points, 0)
	assert_eq(game.day_report().xp, GodPump.xp_formula(game.day_stats.litres, 0.0, game.day_accuracy()), "volume still counts")


func test_a_car_a_drone_touched_never_tips() -> void:
	_open({"drones": 1, "tip_mult": 2.0})
	var car := _parked()
	game.drones[0].pos = car.position
	game.step(0.2)  # the drone pours a little
	assert_true(car.drone_touched)
	game.drones.clear()
	car.amount = 19.95  # then I top it off by hand
	game._settle(car)
	assert_ne(car.tier, "")
	assert_almost_eq(car.tip, 0.0, 0.001, "playtest 10: no tip once a drone touched it")
	assert_gt(car.paid, 0.0, "it still pays for its gas")


func test_the_multi_jet_branch_opens_after_bec_large() -> void:
	var run := RunState.new()
	run.cash = 5000.0
	assert_true(run.next_node("multi").is_empty(), "closed until Bec large")
	assert_false(run.buy("multi"))
	assert_true(run.buy("nozzle"))  # Bec large
	assert_true(run.buy("multi"))  # Double pistolet
	assert_eq(run.mods().twin_stream, 1)
	run.buy("multi")
	run.buy("multi")  # Triple pistolet
	assert_eq(run.mods().twin_stream, 2)


func test_double_pistolet_and_the_card_stack_to_three_cars() -> void:
	_open({"twin_stream": 2})
	assert_eq(game.streams(), 3)


func test_the_visitors_chat_goes_to_the_report() -> void:
	game.start_day(_mods({"close_hour": 23.0}), 800.0, 2, ["sedan"])
	game.visit = Visitors.beat_for(2)
	for i in 600:
		game.step(0.05)
		if game._visit_done:
			break
	var chat: Array = game.day_report().chat
	assert_gt(chat.size(), 1)
	assert_true(String(chat[0]).begins_with("Gaétan:"))
