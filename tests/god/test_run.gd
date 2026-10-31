extends GutTest
## Spec: features/god_run.feature (#37): the run, the fuel truck, cards, and Papa's Garage.

const SAVE := "user://test_godpump_meta.cfg"


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func _run() -> RunState:
	var r := RunState.new()
	r.rng.seed = 7
	return r


func test_a_new_run_starts_with_a_full_tank_and_starting_cash() -> void:
	var r := _run()
	assert_almost_eq(r.tank, GodData.BASE.tank_capacity, 0.01)
	assert_almost_eq(r.cash, GodData.BASE.start_cash, 0.01)
	assert_eq(r.day, 1)


func test_a_day_folds_into_the_run() -> void:
	var r := _run()
	r.end_day({"loot": 120.0, "tank_left": r.tank - 150.0, "xp": 30, "cars": 8, "tiers": {ScoreTiers.SUPER_PERFECT: 2}})
	assert_almost_eq(r.cash, 180.0, 0.01)
	assert_almost_eq(r.tank, GodData.BASE.tank_capacity - 150.0, 0.01)
	assert_eq(r.totals.supers, 2)
	assert_eq(r.xp, 30)


func test_the_truck_fills_the_tank_at_the_wholesale_price() -> void:
	var r := _run()
	r.tank = 400.0
	r.cash = 1000.0
	var cost := r.delivery_cost()
	assert_almost_eq(cost, (r.tank_capacity() - 400.0) / GodData.PUMP_PRICE * GodData.WHOLESALE_START, 0.5)
	assert_true(r.call_truck())
	assert_almost_eq(r.tank, r.tank_capacity(), 0.01)
	assert_almost_eq(r.cash, 1000.0 - cost, 0.01)


func test_every_delivery_raises_the_price() -> void:
	var r := _run()
	r.tank = 0.0
	r.cash = 5000.0
	r.call_truck()
	r.pick_card(r.offer[0])
	assert_almost_eq(r.price, GodData.WHOLESALE_START * (1.0 + GodData.PRICE_RISE), 0.0001)


func test_a_delivery_offers_three_different_cards() -> void:
	var r := _run()
	r.tank = 0.0
	r.cash = 5000.0
	r.call_truck()
	assert_eq(r.offer.size(), 3)
	assert_eq(r.offer.size(), {r.offer[0]: 1, r.offer[1]: 1, r.offer[2]: 1}.size())
	var picked: String = r.offer[1]
	assert_true(r.pick_card(picked))
	assert_true(picked in r.cards)
	assert_true(r.offer.is_empty())


func test_cards_change_the_mods() -> void:
	var r := _run()
	r.cards.append("golden_chain")
	assert_eq(r.mods().combo_max, GodData.BASE.combo_max + 3)


func test_price_freeze() -> void:
	var r := _run()
	r.cards.append("price_freeze")
	r.price_frozen = true
	r.tank = 0.0
	r.cash = 5000.0
	r.call_truck()
	assert_almost_eq(r.price, GodData.WHOLESALE_START, 0.0001, "frozen")


func test_luck_brings_rarer_cards() -> void:
	var plain := 0
	var lucky := 0
	for seed in 300:
		var r := _run()
		r.rng.seed = seed
		for id in r.draw_cards(3):
			if GodData.card(id).rarity != "common":
				plain += 1
	for seed in 300:
		var r := _run()
		r.perk_tiers = {"lucky": 4}  # round 11: the Garage is in the run
		r.bling = ["fuzzy_dice"]
		r.rng.seed = seed
		for id in r.draw_cards(3):
			if GodData.card(id).rarity != "common":
				lucky += 1
	assert_gt(lucky, plain)


func test_out_of_gas_and_broke_is_bankrupt() -> void:
	var r := _run()
	r.tank = 0.0
	r.cash = 10.0
	assert_true(r.bankrupt())
	r.cash = 25.0  # enough for a partial delivery
	assert_false(r.bankrupt())
	r.cash = 5000.0
	assert_false(r.bankrupt())


func test_a_run_starts_50_50_with_gaetan() -> void:
	var r := _run()
	assert_almost_eq(r.share, 50.0, 0.001)
	assert_almost_eq(r.reputation, 50.0, 0.001)


func test_good_fills_raise_reputation_and_the_share_follows_slowly() -> void:
	var r := _run()
	r.end_day({"loot": 10.0, "rep": 20.0})
	assert_almost_eq(r.reputation, 50.0 + 20.0 - GodData.GAETAN_PUSH, 0.001)
	assert_almost_eq(r.share, 50.0 + GodData.SHARE_STEP, 0.001, "at most a few points a night")
	assert_false(r.over)


func test_gaetan_claws_back_a_little_every_night() -> void:
	var r := _run()
	r.end_day({"loot": 10.0, "rep": 0.0})
	assert_almost_eq(r.reputation, 50.0 - GodData.GAETAN_PUSH, 0.001)
	assert_lt(r.share, 50.0)


func test_100_percent_wins_the_run() -> void:
	var r := _run()
	r.reputation = 100.0
	r.share = 96.0
	r.end_day({"loot": 10.0, "rep": 5.0})
	assert_almost_eq(r.share, 100.0, 0.001)
	assert_true(r.won)
	assert_true(r.over)


func test_0_percent_loses_the_run_to_gaetan() -> void:
	var r := _run()
	r.reputation = 0.0
	r.share = 4.0
	r.end_day({"loot": 10.0, "rep": -3.0})
	assert_true(r.lost_to_gaetan)
	assert_true(r.over)
	assert_false(r.won)


func test_the_books_count_gas_at_what_the_truck_charged() -> void:
	var r := _run()
	r.price = 1.5
	r.cash = 200.0
	r.tank = 100.0
	var b := r.books({"sales": 60.0, "tips": 12.0, "litres": 30.0, "wasted": 4.0, "drone_gas": 2.0, "fines": 10.0})
	assert_almost_eq(b.gas_sold, 30.0 * 1.5, 0.001)
	assert_almost_eq(b.spills, 4.0 / GodData.PUMP_PRICE * 1.5, 0.001)
	assert_almost_eq(b.drones, 2.0 / GodData.PUMP_PRICE * 1.5, 0.001)
	assert_almost_eq(b.net, 60.0 + 12.0 - 45.0 - 3.0 - 1.5 - 10.0, 0.001)
	assert_almost_eq(b.gas_in_tank, 100.0 / GodData.PUMP_PRICE * 1.5, 0.001)
	assert_almost_eq(b.equity, b.cash + b.gas_in_tank + b.equipment - b.loan, 0.001)
	assert_almost_eq(b.assets, b.liabilities + b.equity, 0.001, "it balances")
	assert_almost_eq(b.capital + b.retained, b.equity, 0.001)


func test_the_shop_sells_nodes_in_order() -> void:
	var r := _run()
	r.cash = 1000.0
	assert_eq(r.next_node("hours").id, "thermos")
	assert_true(r.buy("hours"))
	assert_almost_eq(r.mods().close_hour, 14.0, 0.001)
	assert_eq(r.next_node("hours").id, "mom_lunch")


func test_the_garage_spends_this_runs_xp() -> void:
	var r := _run()
	r.xp = 3000
	assert_true(r.buy_nozzle(), "Le Costaud, the next nozzle")
	assert_eq(r.nozzle_tier, 1)
	assert_almost_eq(r.mods().flow_mult, 1.2, 0.001)
	assert_almost_eq(r.mods().stream_radius, 8.0, 0.001)
	assert_true(r.buy_bling("pine"))
	assert_true(r.buy_perk("lucky"))
	var spent: int = GodData.NOZZLES[1].price + GodData.item(GodData.BLING, "pine").price + GodData.item(GodData.PERKS, "lucky").price
	assert_eq(r.xp_left(), 3000 - spent)
	assert_eq(r.xp, 3000, "the car ladder counts all the XP earned")
	assert_false(r.buy_nozzle(), "not enough XP left for Le Chromé")


func test_each_nozzle_is_a_straight_improvement() -> void:
	for i in range(1, GodData.NOZZLES.size()):
		var a: Dictionary = GodData.NOZZLES[i - 1].fx
		var b: Dictionary = GodData.NOZZLES[i].fx
		assert_gt(b.get("flow_mult", 1.0), a.get("flow_mult", 1.0), "faster")
		assert_gt(b.get("stream_radius", 0.0), a.get("stream_radius", 0.0), "a bigger ring")
		assert_gt(GodData.NOZZLES[i].price, GodData.NOZZLES[i - 1].price)


func test_finishing_a_run_banks_its_stats_but_no_xp() -> void:
	var m := MetaState.new()
	m.path = ""
	var r := RunState.new(m)
	r.xp = 120
	r.totals.cars = 40
	r.day = 6
	r.finish()
	assert_eq(m.xp, 0, "round 11: nothing carries over")
	assert_eq(m.total_cars, 40)
	assert_eq(m.best_day, 6)
	assert_eq(m.runs, 1)


func test_car_types_unlock_with_cars_filled() -> void:
	var m := MetaState.new()
	m.path = ""
	var r2 := RunState.new(m)
	assert_eq(r2.unlocked_cars(), ["sedan"], "round 10 D: every run starts with sedans only")
	assert_eq(r2.next_unlock().id, "pickup")
	r2.xp = GodData.CAR_TYPES.cadillac.unlock
	assert_true("cadillac" in r2.unlocked_cars())
	assert_eq(r2.next_unlock().id, "bazou")


func test_the_truck_sells_what_the_cash_buys() -> void:
	var r := _run()
	r.tank = 0.0
	var full := r.delivery_cost()
	r.cash = full * 0.25
	assert_true(r.call_truck())
	assert_almost_eq(r.cash, 0.0, 0.01)
	assert_almost_eq(r.tank, r.tank_capacity() * 0.25, 1.0)
	assert_true(r.offer.is_empty(), "under half a tank: no cards")
	r.cash = 5.0
	assert_false(r.call_truck(), "under $20: no truck")


func test_a_big_partial_delivery_still_deals_cards() -> void:
	var r := _run()
	r.tank = 0.0
	r.cash = r.delivery_cost() * 0.6
	assert_true(r.call_truck())
	assert_eq(r.offer.size(), 3)


func test_the_run_knows_when_the_tank_wont_last() -> void:
	var r := _run()
	r.tank = r.tank_capacity()
	assert_false(r.tank_warning())
	r.tank = 40.0
	assert_true(r.tank_warning())
	r.cash = 500.0
	assert_true(r.purchase_risky(400.0), "leaves less than the truck costs")
	assert_false(r.purchase_risky(10.0))


func test_the_suppliers_contract_slows_the_price_rise() -> void:
	var r := _run()
	var plain := r.price_rise()
	r.perk_tiers = {"contract": 2}
	assert_almost_eq(r.price_rise(), plain * 0.64, 0.0001)


func test_premium_gas_makes_sales_pay_more() -> void:
	var r := _run()
	r.perk_tiers = {"premium": 3}
	assert_almost_eq(r.mods().sale_mult, 1.331, 0.001)


# --- Round 8: the CAMION branch and the upgrades with two parents ------------------------------

func test_a_link_needs_both_of_its_parents() -> void:
	var r := _run()
	r.cash = 5000.0
	assert_false(r.link_open("drive_thru"))
	assert_false(r.buy_link("drive_thru"))
	while r.owned.get("service", 0) < 3:
		assert_true(r.buy("service"))  # ...up to Café pour la file
	assert_false(r.link_open("drive_thru"), "one parent isn't enough")
	assert_true(r.buy("hours"))  # Thermos de café
	assert_true(r.owns("coffee") and r.owns("thermos"))
	assert_true(r.link_open("drive_thru"))
	var before := r.cash
	assert_true(r.buy_link("drive_thru"))
	assert_eq(r.cash, before - GodData.link("drive_thru").price)
	assert_eq(r.mods().coffee_sale, 1.0)
	assert_false(r.buy_link("drive_thru"), "only once")


func test_every_link_names_two_real_parents() -> void:
	for l in GodData.LINKS:
		assert_eq(l.needs.size(), 2, l.id)
		for need in l.needs:
			assert_false(GodData.shop_node(need).is_empty(), "%s needs %s" % [l.id, need])


func test_bulk_buying_when_the_tank_is_low() -> void:
	var r := _run()
	r.tank = r.tank_capacity() * 0.2
	var plain := r.delivery_cost()
	r.owned["truck"] = 2  # Jauge d'alarme, Achat en vrac
	assert_almost_eq(r.delivery_cost(), roundf(plain * 0.9), 1.0)
	r.tank = r.tank_capacity() * 0.5
	var half := r.delivery_cost()
	r.owned["truck"] = 0
	assert_eq(r.delivery_cost(), half, "no discount above 25%")


func test_the_used_tanker_halves_a_partial_deliverys_rise() -> void:
	var r := _run()
	r.owned["truck"] = 3
	r.tank = 0.0
	r.cash = r.delivery_cost() * 0.6
	var p := r.price
	assert_true(r.call_truck())
	assert_almost_eq(r.price, p * (1.0 + GodData.PRICE_RISE * 0.5), 0.0001)


func test_the_forward_contract_freezes_every_fourth_delivery() -> void:
	var r := _run()
	r.links = ["forward_contract"]
	r.cash = 100000.0
	var prices := []
	for i in 4:
		r.tank = 0.0
		assert_true(r.call_truck())
		prices.append(r.price)
	assert_gt(prices[2], prices[1])
	assert_eq(prices[3], prices[2], "the fourth delivery comes at the old price")


# --- Round 10 D: the car ladder unlocks by the run's XP ------------------------------------------

func test_a_new_car_type_is_announced_the_night_it_unlocks() -> void:
	var r := _run()
	r.end_day({"loot": 10.0, "xp": GodData.CAR_TYPES.pickup.unlock})
	assert_eq(r.last_night.unlocked, ["pickup"])
	r.end_day({"loot": 10.0, "xp": 10})
	assert_true(r.last_night.unlocked.is_empty())


func test_every_car_type_has_a_rule_for_the_codex() -> void:
	for id in GodData.CAR_ORDER:
		assert_ne(GodData.CAR_TYPES[id].get("helps", ""), "", id)
		assert_true(CartoonArt.CARS.has(id), "%s has a cartoon look" % id)


func test_the_truck_brings_a_full_tank_or_nothing_unless_dry() -> void:
	var r := _run()
	r.tank = r.tank_capacity() * 0.5
	r.cash = r.delivery_cost() * 0.9
	assert_false(r.can_call_truck(), "playtest 12: no small top-offs")
	assert_false(r.call_truck())
	r.cash = r.delivery_cost()
	assert_true(r.call_truck())
	assert_almost_eq(r.tank, r.tank_capacity(), 0.01)
