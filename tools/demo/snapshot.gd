extends SceneTree
## A screenshot of a GOD PUMP day in progress, for the Committee to look at the layout without playing:
##
##     godot --path . -s tools/demo/snapshot.gd -- <out.png> [seconds]
##
## Opens a day (two drones, the twin stream, cars waiting), lets it run `seconds` (default 6) with the
## stream on a car, then saves the frame. Needs a window (not --headless): the frame must be drawn.

var day: GodPump
var out := "user://snapshot.png"
var seconds := 6.0
var f := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		seconds = float(args[1])
	DisplayServer.window_set_size(Vector2i(1152, 648))
	day = load("res://scenes/god/day/god_pump.tscn").instantiate()
	day.sound_on = false
	root.add_child(day)


func _open() -> void:
	var m := GodData.BASE.duplicate()
	m.drones = 2
	m.twin_stream = 1
	m.queue = 4
	m.close_hour = 23.0
	day.start_day(m, 700.0, 3, ["sedan", "pickup", "cadillac"])
	day.regulars[0].cheer = 1.0
	day.stacks = {1: 7, 5: 4, 20: 3, 50: 1}  # a morning's chips already in the tray


func _process(_dt: float) -> bool:
	f += 1
	if f == 2:
		_open()
	if f < 3:
		return false
	if f < int(seconds * 30.0):
		var target: ProtoCar = day.nearest_customer(Vector2(576, 380), 2000.0)
		if target:
			day.aim(target.position)
		day.set_pouring(f % 90 < 60)
		if f == int(seconds * 30.0) - 12 and target:  # a car pays just before the shot: chips in the air
			target.amount = target.target
			day._settle(target)
		return false
	if f == int(seconds * 30.0) + 3:
		root.get_viewport().get_texture().get_image().save_png(out)
		print("saved ", out)
		return true
	return false
