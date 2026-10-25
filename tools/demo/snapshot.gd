extends SceneTree
## A screenshot of a GOD PUMP day in progress, for the Committee to look at the layout without playing:
##
##     godot --path . -s tools/demo/snapshot.gd -- <out.png> [seconds] [day | report]
##
## day (default): opens a day (two drones, the twin stream, cars waiting), lets it run `seconds` with the
## stream on a car, then saves the frame. report: plays a real run's first day for `seconds`, closes it
## and saves the day report. Needs a window (not --headless): the frame must be drawn.

var day: GodPump
var out := "user://snapshot.png"
var seconds := 6.0
var f := 0
var mode := "day"
var game: GodGame


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		seconds = float(args[1])
	if args.size() > 2:
		mode = args[2]
	DisplayServer.window_set_size(Vector2i(1152, 648))
	if mode in ["report", "night"]:
		game = load("res://scenes/god/god_game.tscn").instantiate()
		game.meta_path = ""
		game.sound_on = false
		game.autostart = true
		game.cash_in_time = 0.0
		root.add_child(game)
		return
	day = load("res://scenes/god/day/god_pump.tscn").instantiate()
	day.sound_on = false
	root.add_child(day)


func _open() -> void:
	var m := GodData.BASE.duplicate()
	m.drones = 2
	m.twin_stream = 1
	m.herd_dog = 1
	m.puddle_vacuum = 1
	m.queue = 4
	m.close_hour = 23.0
	day.start_day(m, 700.0, 3, ["sedan", "pickup", "cadillac"])
	day.regulars[0].cheer = 1.0
	day.stacks = {1: 7, 5: 4, 20: 3, 50: 1}  # a morning's chips already in the tray


func _process(_dt: float) -> bool:
	f += 1
	if mode == "report":
		return _report_frame()
	if mode == "night":
		return _night_frame()
	if f == 2:
		_open()
	if f < 3:
		return false
	if f < int(seconds * 30.0):
		var target: ProtoCar = day.nearest_customer(Vector2(576, 380), 2000.0)
		if target:
			day.aim(target.position)
		day.set_pouring(f % 90 < 60)
		if f == int(seconds * 30.0) - 40 and target:  # a car pays just before the shot: chips in the air
			target.amount = target.target
			day._settle(target)
		return false
	if f == int(seconds * 30.0) + 3:
		root.get_viewport().get_texture().get_image().save_png(out)
		print("saved ", out)
		return true
	return false


func _report_frame() -> bool:
	if not game.day or not game.run:
		return false
	if f < int(seconds * 30.0):
		var target: ProtoCar = game.day.nearest_customer(Vector2(576, 380), 2000.0)
		if target:
			game.day.aim(target.position)
		game.day.set_pouring(f % 90 < 70)
		return false
	if f == int(seconds * 30.0):
		game.day.visit = Visitors.beat_for(3)
		game.day.chat_log.assign(["Papa: How's my pump, kid? Don't look at my hands.", "Bertrand: Thirty years, he topped off to the cent.", "Papa: To the CENT."])
		game.day.end_round()
	if f == int(seconds * 30.0) + 10:
		root.get_viewport().get_texture().get_image().save_png(out)
		print("saved ", out)
		return true
	return false


## The night shop with a few branches bought, MULTI-JET and DÉGÂTS opened.
func _night_frame() -> bool:
	if not game.day or not game.run:
		return false
	if f == 5:
		game.run.cash = 3000.0
		for b in ["nozzle", "multi", "multi", "tank", "spill", "hours", "service"]:
			game.run.buy(b)
		game.day.end_round()
	if f == 8:
		game._after_report()
	if f == 20:
		root.get_viewport().get_texture().get_image().save_png(out)
		print("saved ", out)
		return true
	return false
