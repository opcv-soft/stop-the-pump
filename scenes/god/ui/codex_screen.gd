class_name CodexScreen
extends Control
## The car codex (round 10 D, playtest 9: "it's unclear what each car type does"): every car type, drawn
## in the cartoon look, with its rule and the run XP that brings it to the lot. The types are a
## difficulty ladder that unlocks during each run; the ones this run has unlocked are lit, the rest dim.
## Opened from the night screen; ESC, ENTER or a click closes it. Serves: readability (Mastery).

signal closed

var run: RunState
var _t := 0.0


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func open(the_run: RunState) -> void:
	run = the_run
	visible = true
	queue_redraw()


func close() -> void:
	visible = false
	closed.emit()


func _process(dt: float) -> void:
	if visible:
		_t += dt
		queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		accept_event()
		close()


func _unhandled_input(e: InputEvent) -> void:
	if visible and e is InputEventKey and e.pressed and not e.echo and e.physical_keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		close()


func _draw() -> void:
	GodUI.dim(self, size, 0.8)
	CartoonArt.box(self, Rect2(24, 16, 1104, 616), Color(0.98, 0.95, 0.88), 18.0, 5.0)
	CartoonArt.label(self, Vector2(576, 56), tr("CAR CODEX"), 30, Color(1.0, 0.55, 0.24))
	var xp := run.xp if run else 0
	var nxt := run.next_unlock() if run else {}
	var sub := tr("This run: %d XP. New car types come as you earn XP.") % xp
	if not nxt.is_empty():
		sub += "  " + tr("Next: %s at %d XP.") % [nxt.name, nxt.need]
	GodUI.text(self, Vector2(576, 82), sub, 14, CartoonArt.INK, true)
	var cols := 5
	var cw := 208.0
	var ch := 168.0
	for i in GodData.CAR_ORDER.size():
		var id: String = GodData.CAR_ORDER[i]
		var t: Dictionary = GodData.CAR_TYPES[id]
		var r := Rect2(40 + (i % cols) * (cw + 6), 98 + (i / cols) * (ch + 6), cw, ch)
		var have := xp >= int(t.unlock)
		CartoonArt.box(self, r, Color(1, 1, 1) if have else Color(0.86, 0.84, 0.8), 12.0, 3.0)
		var col: Color = CartoonArt.paint(id, i) if have else Color(0.55, 0.55, 0.6)
		CartoonArt.car(self, r.position + Vector2(cw * 0.5, 40), 0.0, id, col, Vector2.ONE, 0.0, _t, 0.8 if id in ["tank", "trio"] else 1.0)
		GodUI.text(self, r.position + Vector2(cw * 0.5, 86), t.name, 15, CartoonArt.INK, true)
		GodUI.text(self, r.position + Vector2(cw * 0.5, 104), tr("unlocked") if have else tr("at %d XP") % int(t.unlock), 12,
			Color(0.1, 0.55, 0.25) if have else Color(0.6, 0.25, 0.2), true)
		GodUI.para_in(self, GodUI.font(), r.position + Vector2(10, 124), tr(t.helps), 11, cw - 20, CartoonArt.INK, 1.2)
	GodUI.text(self, Vector2(576, 624), tr("Click or press ESC to close"), 12, Color(CartoonArt.INK, 0.6), true)
