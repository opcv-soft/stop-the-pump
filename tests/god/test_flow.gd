extends GutTest
## Spec: features/god_run.feature (#37): GOD PUMP's flow from a run's first day to the garage.

const SCENE := preload("res://scenes/god/god_game.tscn")

var g: GodGame


func before_each() -> void:
	g = SCENE.instantiate()
	g.meta_path = ""
	g.sound_on = false
	g.autostart = true
	g.cash_in_time = 0.0  # the report opens at once (no register animation)
	add_child_autofree(g)
	g.day.view = "flat"
	g.day.set_view("flat")
	g.day.auto_traffic = false


func test_a_run_opens_on_day_1() -> void:
	assert_eq(g.state, "day")
	assert_eq(g.run.day, 1)
	assert_false(g.day.round_over)


func test_closing_shows_the_report_then_the_night() -> void:
	g.day.end_round()
	assert_eq(g.state, "report")
	assert_true(g.report_screen.visible)
	g._after_report()
	assert_eq(g.state, "night")
	assert_true(g.night.visible)


func test_the_truck_deals_cards_and_opening_starts_day_2() -> void:
	g.day.end_round()
	g._after_report()
	g.run.tank = 100.0
	g.run.cash = 5000.0
	g.call_truck()
	assert_eq(g.state, "truck", "the delivery plays first")
	assert_true(g.truck_scene.visible)
	g.truck_scene.skip()
	assert_eq(g.state, "cards")
	assert_eq(g.run.offer.size(), 3)
	var id: String = g.run.offer[0]
	g.run.pick_card(id)
	g.cards.picked.emit(id)
	assert_eq(g.state, "night")
	g.open_next_day()
	assert_eq(g.state, "day")
	assert_eq(g.run.day, 2)


func test_bankrupt_ends_the_run_and_banks_xp() -> void:
	g.day.reset_day_stats()
	g.day.day_stats.xp = 40
	g.day.tank = 0.0
	g.run.cash = 0.0
	g.day.end_round()
	g._after_report()
	assert_eq(g.state, "run_over")
	assert_eq(g.meta.xp, 40)
	assert_eq(g.meta.runs, 1)
	g.run_over.done.emit()
	assert_eq(g.state, "garage")


func test_100_percent_market_share_plays_the_ending() -> void:
	g.run.share = 97.0
	g.run.reputation = 100.0
	var car := g.day.park_customer(20.0, Vector2(500, 380))
	car.amount = 20.0
	g.day._settle(car)  # a top-off: enough reputation to beat Gaétan's push tonight
	g.day.end_round()
	assert_true(g.run.won)
	g._after_report()
	assert_eq(g.state, "cinematic")
	assert_true(g.meta.ending_seen)
	g.cinematic.skip()
	g.cinematic.advance()
	assert_eq(g.state, "run_over")


func test_0_percent_ends_the_run() -> void:
	g.run.share = 2.0
	g.run.reputation = 0.0
	g.day.end_round()
	g._after_report()
	assert_eq(g.state, "run_over")
	assert_true(g.run.lost_to_gaetan)


func test_the_morning_takes_the_runs_market_share() -> void:
	g.run.share = 73.0
	g.start_day()
	assert_almost_eq(g.day.market_share, 73.0, 0.001)


func test_buying_in_the_night_shop_changes_tomorrow() -> void:
	g.day.end_round()
	g._after_report()
	g.run.cash = 1000.0
	assert_true(g.night.tree.press("hours:0"))
	g.open_next_day()
	assert_almost_eq(g.day.round_seconds, (14.0 - 7.0) * GodData.HOUR_SECONDS, 0.01)


func test_escape_pauses_a_day_and_can_go_back_to_the_title() -> void:
	g.toggle_pause()
	assert_true(get_tree().paused)
	g.toggle_pause()
	assert_false(get_tree().paused)


func test_upgrades_bought_last_night_show_on_the_station_this_morning() -> void:
	g.day.view = "hd"
	g.day.set_view("hd")
	g.day.end_round()
	g._after_report()
	g.run.cash = 1000.0
	g.night.tree.press("attractions:0")  # traffic light
	assert_false(g.day._hd_view._props.has("traffic_light"), "not until the morning")
	g.open_next_day()
	g.day._hd_view._sync_props(0.1)
	assert_true(g.day._hd_view._props.has("traffic_light"))


func test_a_small_partial_delivery_stays_on_the_night() -> void:
	g.day.end_round()
	g._after_report()
	g.run.tank = 0.0
	g.run.cash = 30.0
	g.call_truck()
	g.truck_scene.skip()
	assert_eq(g.state, "night")
	assert_gt(g.run.tank, 0.0)


func test_dev_mode_skips_to_the_next_night() -> void:
	g.toggle_dev()
	assert_true(g.dev.visible)
	assert_true(g.get_tree().paused)
	g.dev_next_night()
	assert_false(g.get_tree().paused)
	assert_eq(g.state, "night")
	assert_eq(g.run.day, 1)
	g.dev_next_night()
	assert_eq(g.state, "night")
	assert_eq(g.run.day, 2)


func test_the_delivery_plays_out_on_its_own() -> void:
	g.day.end_round()
	g._after_report()
	g.run.tank = 100.0
	g.run.cash = 5000.0
	g.call_truck()
	assert_eq(g.truck_scene.info.tank_from, 100.0)
	assert_eq(g.truck_scene.info.tank_to, g.run.tank_capacity())
	for i in int(TruckScene.duration() * 20.0) + 4:
		g.truck_scene._process(0.05)
	assert_false(g.truck_scene.visible)
	assert_eq(g.state, "cards")


func test_a_visitor_comes_on_the_lore_days() -> void:
	g.day.end_round()
	g._after_report()
	g.open_next_day()  # day 2: Gaétan, from across the road
	assert_eq(g.day.visit.who, "gaetan")
	assert_string_contains(g.meta.clippings[-1], "gaetan", "remembered for the menu's scrapbook")


func test_the_game_speaks_french_and_english() -> void:
	g.set_language("fr")
	assert_eq(g.tr("PLAY"), "JOUER")
	assert_eq(g.tr("THE NIGHT AFTER DAY %d") % 3, "LA NUIT APRÈS LE JOUR 3")
	assert_eq(g.meta.language, "fr", "the choice is kept")
	g.set_language("en")
	assert_eq(g.tr("PLAY"), "PLAY")


func test_the_night_opens_the_car_codex() -> void:
	g.day.end_round()
	g._after_report()
	assert_eq(g.state, "night")
	g.night._codex_btn.pressed.emit()
	assert_true(g.night.codex.visible)
	g.night.codex.close()
	assert_false(g.night.codex.visible)
