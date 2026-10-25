class_name DayReportScreen
extends Control
## End of a day. Round 10 (playtests 9 and 10): the fight with Gaétan on top (market share and
## reputation, with Dad's reaction), then four columns: the day (accuracy, cars, combo, XP, grades), today's
## results (the P&L at wholesale cost), the balance sheet (assets, liabilities, equity) and what was overheard (the visitor's chat, read
## here instead of over the pour). ENTER or the button goes on.

signal done

## Dad's line after a night: by how the market share moved (up, flat, down). Picked by the day.
const DAD_LINES := {
	"up": ["That's my kid!", "Gaétan's sweating. I can see it from here.", "To the cent. TO THE CENT.",
		"Ti-Guy says the whole rang is talking about you."],
	"flat": ["Hold the line, kid.", "Gaétan isn't going anywhere. Neither are we.", "Steady hands. That's all it takes."],
	"down": ["Half the village at Gaétan's. Câlisse.", "My hands shook too. Shake it off.",
		"Tomorrow, kid. Tomorrow we take them back."],
}

var report := {}
var run: RunState
var meta: MetaState
var _t := 0.0
var _btn: Button


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_btn = GodUI.button("THE NIGHT  »")
	_btn.position = Vector2(466, 572)
	_btn.pressed.connect(func() -> void: done.emit())
	add_child(_btn)


func show_report(r: Dictionary, the_run: RunState, the_meta: MetaState) -> void:
	report = r
	run = the_run
	meta = the_meta
	_t = 0.0
	_btn.text = tr("THE END  »") if run.won else tr("THE NIGHT  »")
	visible = true
	queue_redraw()


func _process(dt: float) -> void:
	if visible:
		_t += dt
		queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if visible and e is InputEventKey and e.pressed and not e.echo and e.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		get_viewport().set_input_as_handled()
		done.emit()


## What Dad says tonight.
func dad_line() -> String:
	var night: Dictionary = run.last_night if run else {}
	var moved: float = night.get("share_to", 50.0) - night.get("share_from", 50.0)
	var mood := "up" if moved > 0.5 else ("down" if moved < -0.5 else "flat")
	var pool: Array = DAD_LINES[mood]
	return pool[report.get("day", 1) % pool.size()]


func _draw() -> void:
	if report.is_empty():
		return
	GodUI.dim(self, size, 0.6)
	draw_style_box(GodUI.panel_box(GodUI.GOLD_DIM), Rect2(28, 20, 1096, 540))
	var day: int = report.get("day", 1)
	GodUI.text(self, Vector2(576, 60), tr("FERMÉ  ·  DAY %d") % day, 30, GodUI.GOLD, true)
	if report.get("out_of_gas", false):
		GodUI.text(self, Vector2(576, 84), tr("out of gas before closing!"), 15, GodUI.RED, true)
	_draw_fight()
	_draw_day(Rect2(46, 200, 250, 340))
	_draw_results(Rect2(318, 200, 250, 340))
	_draw_balance(Rect2(590, 200, 250, 340))
	_draw_chat(Rect2(862, 200, 244, 340))


## The market share bar (you in gold, Gaétan in green), the reputation, and Dad.
func _draw_fight() -> void:
	var night: Dictionary = run.last_night if run else {}
	var share: float = night.get("share_to", run.share if run else 50.0)
	var moved := int(round(share)) - int(round(night.get("share_from", share)))  # whole points, so the bar adds up
	var bar := Rect2(150, 104, 852, 26)
	draw_rect(bar.grow(3), Color(0, 0, 0, 0.9))
	draw_rect(bar, Color(0.3, 0.62, 0.35))  # Gaétan's
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * share / 100.0, bar.size.y)), GodUI.GOLD)
	GodUI.text(self, Vector2(bar.position.x - 12 - GodUI.font().get_string_size(tr("YOU"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x, bar.end.y - 6), tr("YOU"), 18, GodUI.GOLD)
	GodUI.text(self, Vector2(bar.end.x + 12, bar.end.y - 6), "GAÉTAN", 18, Color(0.45, 0.85, 0.5))
	var label := "%d%%  (%s%d)" % [int(round(share)), "+" if moved >= 0 else "", moved]
	GodUI.text(self, Vector2(bar.position.x + 10, bar.end.y - 6), label, 17, GodUI.INK)
	var theirs := "%d%%" % (100 - int(round(share)))
	GodUI.text(self, Vector2(bar.end.x - 10 - GodUI.font().get_string_size(theirs, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x, bar.end.y - 6), theirs, 17, GodUI.INK)
	var rep: float = night.get("rep_to", run.reputation if run else 50.0)
	var rep_moved: float = rep - night.get("rep_from", rep)
	GodUI.text(self, Vector2(576, 152), tr("MARKET SHARE  ·  reputation %d (%s%.1f)  ·  %d cars went to Gaétan today") % [int(round(rep)), "+" if rep_moved >= 0.0 else "", rep_moved, report.get("rival_cars", 0)], 14, Color(GodUI.CREAM, 0.75), true)
	GodUI.text(self, Vector2(576, 180), "Papa: \"%s\"" % tr(dad_line()), 17, GodUI.CREAM, true)


func _row(r: Rect2, y: float, label: String, value: String, col := GodUI.CREAM, size := 15) -> void:
	GodUI.text(self, Vector2(r.position.x, y), label, size, Color(GodUI.CREAM, 0.85))
	GodUI.text(self, Vector2(r.end.x - GodUI.font().get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x, y), value, size, col)


func _draw_day(r: Rect2) -> void:
	GodUI.text(self, Vector2(r.get_center().x, r.position.y + 14), tr("THE DAY"), 18, GodUI.GOLD, true)
	var y := r.position.y + 46
	_row(r, y, tr("Accuracy"), "%d%%" % int(report.get("accuracy", 0.0) * 100.0), GodUI.GOLD)
	y += 26
	_row(r, y, tr("Cars fueled"), str(report.get("cars", 0)), GodUI.GOLD)
	y += 26
	_row(r, y, tr("Best combo"), "x%d" % report.get("best_combo", 1), GodUI.GOLD)
	y += 26
	_row(r, y, tr("XP"), "+%d" % report.get("xp", 0), GodUI.GOLD)
	y += 20
	var sum := tr("%.0f L x %d combo x %d%%") % [report.get("litres", 0.0), report.get("combo_points", 0), int(report.get("accuracy", 0.0) * 100.0)]
	GodUI.text(self, Vector2(r.end.x - GodUI.font().get_string_size(sum, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x, y), sum, 12, Color(GodUI.CREAM, 0.6))
	var tiers: Dictionary = report.get("tiers", {})
	var grades := [[ScoreTiers.SUPER_PERFECT, "SUPER"], [ScoreTiers.PERFECT, "PERFECT"], [ScoreTiers.GOOD, "GOOD"],
		[ScoreTiers.OK, "OK"], [ScoreTiers.MISS, "OVERFILLED"], [ScoreTiers.UNSERVED, "UNSERVED"]]
	for i in grades.size():
		var x := r.position.x + 27.0 + i * 55.0
		var col: Color = GodPump.TIER_COLORS[grades[i][0]]
		GodUI.text(self, Vector2(x, y + 50), str(tiers.get(grades[i][0], 0)), 24, col, true)
		GodUI.text(self, Vector2(x, y + 68), tr(grades[i][1]), 9, Color(col, 0.8), true)
	GodUI.text(self, Vector2(r.get_center().x, r.end.y - 12), tr("Gas left in the tank: $%.0f") % report.get("tank_left", 0.0), 14, Color(GodUI.CREAM, 0.7), true)


## Today's results (the P&L, playtest 11): what came in, what the gas cost at the truck's price.
func _draw_results(r: Rect2) -> void:
	var b := run.books(report) if run else {}
	if b.is_empty():
		return
	GodUI.text(self, Vector2(r.get_center().x, r.position.y + 14), tr("TODAY'S RESULTS"), 18, GodUI.GOLD, true)
	var y := r.position.y + 46
	for row in [[tr("Sales"), b.sales], [tr("Tips"), b.tips], [tr("Gas sold, at cost"), -b.gas_sold],
			[tr("Spilled gas"), -b.spills], [tr("Drone gas"), -b.drones], [tr("Fines"), -b.fines]]:
		if absf(row[1]) < 0.5 and row[0] in [tr("Drone gas"), tr("Fines")]:
			continue
		_row(r, y, row[0], _money(row[1]), GodUI.CREAM if row[1] >= 0.0 else GodUI.RED, 14)
		y += 22
	draw_line(Vector2(r.position.x, y - 14), Vector2(r.end.x, y - 14), Color(GodUI.GOLD_DIM, 0.8), 1.0)
	_row(r, y + 2, tr("Net profit"), _money(b.net), GodUI.GREEN if b.net >= 0.0 else GodUI.RED, 16)


## Tonight's balance sheet, like a real business: assets = liabilities + equity (Dad's capital, plus
## what the gaz bar has earned since).
func _draw_balance(r: Rect2) -> void:
	var b := run.books(report) if run else {}
	if b.is_empty():
		return
	GodUI.text(self, Vector2(r.get_center().x, r.position.y + 14), tr("BALANCE SHEET"), 18, GodUI.GOLD, true)
	var y := r.position.y + 42
	GodUI.text(self, Vector2(r.position.x, y), tr("ASSETS"), 12, Color(GodUI.GOLD, 0.8))
	y += 18
	for row in [[tr("Cash"), b.cash], [tr("Gas in the tank"), b.gas_in_tank], [tr("Equipment"), b.equipment]]:
		_row(r, y, row[0], _money(row[1]), GodUI.CREAM, 13)
		y += 18
	_row(r, y, tr("Total assets"), _money(b.assets), GodUI.GOLD, 14)
	y += 28
	GodUI.text(self, Vector2(r.position.x, y), tr("LIABILITIES"), 12, Color(GodUI.GOLD, 0.8))
	y += 18
	_row(r, y, tr("Cousin's loan"), _money(-b.loan) if b.loan > 0.0 else "$0", GodUI.RED if b.loan > 0.0 else GodUI.CREAM, 13)
	y += 18
	_row(r, y, tr("Total liabilities"), _money(b.liabilities), GodUI.GOLD, 14)
	y += 28
	GodUI.text(self, Vector2(r.position.x, y), tr("EQUITY"), 12, Color(GodUI.GOLD, 0.8))
	y += 18
	_row(r, y, tr("Dad's capital"), _money(b.capital), GodUI.CREAM, 13)
	y += 18
	_row(r, y, tr("Retained earnings"), _money(b.retained), GodUI.GREEN if b.retained >= 0.0 else GodUI.RED, 13)
	y += 18
	_row(r, y, tr("Total equity"), _money(b.equity), GodUI.GOLD, 14)
	y += 22
	GodUI.text(self, Vector2(r.get_center().x, y + 4), tr("Assets = liabilities + equity"), 11, Color(GodUI.CREAM, 0.5), true)


static func _money(v: float) -> String:
	return ("-$%.0f" % absf(v)) if v < -0.5 else "$%.0f" % maxf(v, 0.0)


## Playtest 10: the visitor's chat, read after closing instead of over the pour, to keep the story going.
func _draw_chat(r: Rect2) -> void:
	GodUI.text(self, Vector2(r.get_center().x, r.position.y + 14), tr("OVERHEARD TODAY"), 18, GodUI.GOLD, true)
	var chat: Array = report.get("chat", [])
	if chat.is_empty():
		GodUI.text(self, Vector2(r.get_center().x, r.position.y + 60), tr("Nobody came by to chat."), 14, Color(GodUI.CREAM, 0.5), true)
		return
	var y := r.position.y + 46
	for line in chat:
		var parts := String(line).split(": ", true, 1)
		if parts.size() == 2:
			GodUI.text(self, Vector2(r.position.x, y), parts[0], 14, GodUI.GOLD)
			y += 18
			y += GodUI.para_in(self, GodUI.font(), Vector2(r.position.x + 12, y), parts[1], 14, r.size.x - 16, GodUI.CREAM) + 6
		else:
			y += GodUI.para_in(self, GodUI.font(), Vector2(r.position.x, y), line, 14, r.size.x - 10, GodUI.CREAM) + 6
		if y > r.end.y - 20:
			break
