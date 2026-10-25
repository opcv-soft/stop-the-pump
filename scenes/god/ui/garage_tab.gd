class_name GarageTab
extends Control
## The Garage, a tab of the night (round 11, playtest 12: "fold the permanent upgrades into a tab, in the
## run"). Paid with this run's XP, so your chains are tonight's money; nothing carries over between runs.
##   The nozzle ladder: each nozzle replaces the last, faster and with a bigger ring, plus a perk.
##   Bling: bought once, always on. Perks: tiers.
## Click a card to buy it; hover it to read what it does. Serves: Advancement (the build) and Mastery
## (chaining pays).

signal bought

var run: RunState
var area := Rect2(250, 92, 880, 478)
var hover := ""
var _t := 0.0
var _pops := {}


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS


## Every card: {key, rect, kind, item, state ("owned", "next", "locked", "max"), price}.
func cards() -> Array:
	var out := []
	if not run:
		return out
	var y := area.position.y + 52
	var w := (area.size.x - 4 * 10.0) / 5.0
	for i in GodData.NOZZLES.size():
		var n: Dictionary = GodData.NOZZLES[i]
		var st := "owned" if i <= run.nozzle_tier else ("next" if i == run.nozzle_tier + 1 else "locked")
		out.append({"key": "nozzle:%d" % i, "rect": Rect2(area.position.x + i * (w + 10), y, w, 112), "kind": "nozzle",
			"item": n, "state": st, "price": n.price, "tier": i})
	y += 140
	var bw := (area.size.x - 7 * 8.0) / 8.0
	for i in GodData.BLING.size():
		var b: Dictionary = GodData.BLING[i]
		out.append({"key": "bling:" + b.id, "rect": Rect2(area.position.x + i * (bw + 8), y, bw, 100), "kind": "bling",
			"item": b, "state": "owned" if b.id in run.bling else "next", "price": b.price})
	y += 132
	for i in GodData.PERKS.size():
		var p: Dictionary = GodData.PERKS[i]
		var price := run.perk_price(p.id)
		out.append({"key": "perk:" + p.id, "rect": Rect2(area.position.x + i * (bw + 8), y, bw, 100), "kind": "perk",
			"item": p, "state": "max" if price < 0 else "next", "price": maxi(price, 0), "tier": run.perk_tiers.get(p.id, 0)})
	return out


func press(key: String) -> bool:
	var parts := key.split(":")
	var ok := false
	match parts[0]:
		"nozzle":
			ok = int(parts[1]) == run.nozzle_tier + 1 and run.buy_nozzle()
		"bling":
			ok = run.buy_bling(parts[1])
		"perk":
			ok = run.buy_perk(parts[1])
	if ok:
		_pops[key] = 0.0
		bought.emit()
	queue_redraw()
	return ok


func _gui_input(e: InputEvent) -> void:
	if not visible or not run:
		return
	if e is InputEventMouseMotion:
		hover = ""
		for c in cards():
			if c.rect.has_point(e.position):
				hover = c.key
		queue_redraw()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and hover != "":
		press(hover)


func _process(dt: float) -> void:
	if visible:
		_t += dt
		for k in _pops.keys():
			_pops[k] += dt
			if _pops[k] > 0.6:
				_pops.erase(k)
		queue_redraw()


func _draw() -> void:
	if not run:
		return
	var ink := CartoonArt.INK
	CartoonArt.label(self, Vector2(area.get_center().x, area.position.y + 22), tr("THE GARAGE  ·  XP to spend: %d") % run.xp_left(), 22, Color(1.0, 0.8, 0.3))
	GodUI.text(self, Vector2(area.position.x, area.position.y + 46), tr("NOZZLES"), 13, Color(GodUI.GOLD, 0.8))
	GodUI.text(self, Vector2(area.position.x, area.position.y + 186), tr("BLING  ·  bought once, always on"), 13, Color(GodUI.GOLD, 0.8))
	GodUI.text(self, Vector2(area.position.x, area.position.y + 318), tr("PERKS"), 13, Color(GodUI.GOLD, 0.8))
	for c in cards():
		var r: Rect2 = c.rect
		var pop: float = _pops.get(c.key, 1.0)
		var s := 1.0 + 0.15 * sin(clampf(pop / 0.6, 0.0, 1.0) * PI) if _pops.has(c.key) else 1.0
		if c.key == hover:
			s *= 1.04
		r = Rect2(r.get_center() - r.size * 0.5 * s, r.size * s)
		var can: bool = c.state == "next" and run.xp_left() >= c.price
		var fill := Color(1.0, 0.97, 0.9)
		match c.state:
			"owned", "max":
				fill = Color(0.85, 0.96, 0.85)
			"locked":
				fill = Color(0.55, 0.52, 0.5)
		if c.state == "next" and not can:
			fill = Color(0.8, 0.78, 0.74)
		CartoonArt.box(self, r, fill, 10.0, 3.0)
		if can:
			draw_rect(r.grow(3), Color(1.0, 0.8, 0.3, 0.35 + 0.25 * sin(_t * 4.0)), false, 3.0)
		var it: Dictionary = c.item
		if c.kind == "nozzle":  # the nozzle itself, redder and shinier up the ladder
			CartoonArt.nozzle(self, r.position + Vector2(r.size.x * 0.5 + 30, 44), false, 0.0, 0.0, 0.5 + 0.05 * c.tier)
			GodUI.text(self, Vector2(r.get_center().x, r.position.y + 18), it.name, 14, ink, true)
			var t: int = c.tier
			GodUI.text(self, Vector2(r.get_center().x, r.end.y - 22), tr("speed x%.1f · ring +%d") % [1.0 + 0.2 * t, 8 * t], 11, ink, true)
		else:
			var tex := GodUI.icon(it.id)
			if tex:
				draw_texture_rect(tex, Rect2(r.position + Vector2(r.size.x * 0.5 - 22, 8), Vector2(44, 44)), false, Color.WHITE if c.state != "locked" else Color(0.5, 0.5, 0.5))
			var fs := 12
			while fs > 9 and GodUI.font().get_string_size(it.name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > r.size.x - 8:
				fs -= 1
			GodUI.text(self, Vector2(r.get_center().x, r.position.y + 66), it.name, fs, ink, true)
		var foot := ""
		match c.state:
			"owned":
				foot = tr("IN HAND") if c.kind == "nozzle" and c.tier == run.nozzle_tier else tr("OWNED")
			"max":
				foot = tr("MAX")
			"locked":
				foot = tr("%d XP") % c.price
			_:
				foot = tr("%d XP") % c.price
				if c.kind == "perk" and c.tier > 0:
					foot = tr("tier %d · %d XP") % [c.tier + 1, c.price]
		GodUI.text(self, Vector2(r.get_center().x, r.end.y - 6), foot, 12, Color(0.1, 0.5, 0.2) if c.state in ["owned", "max"] else (ink if can else Color(0.55, 0.2, 0.15)), true)
	if hover != "":
		for c in cards():
			if c.key == hover:
				_tooltip(c)


func _tooltip(c: Dictionary) -> void:
	var text := "%s: %s" % [c.item.name, tr(c.item.helps)]
	var w := minf(GodUI.font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 24, 520)
	var at := Vector2(clampf(c.rect.get_center().x - w * 0.5, 10, 1142 - w), c.rect.end.y + 6)
	if at.y > 600:
		at.y = c.rect.position.y - 46
	CartoonArt.box(self, Rect2(at, Vector2(w, 40)), CartoonArt.INK, 8.0, 2.0)
	GodUI.para_in(self, GodUI.font(), at + Vector2(12, 18), text, 14, w - 24, Color.WHITE, 1.2)
