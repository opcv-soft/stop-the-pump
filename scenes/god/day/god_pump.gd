class_name GodPump
extends Node2D
## A GOD PUMP day (docs/GOD_PUMP_PLAN.md): you are a giant nozzle above the lot of your late father's
## gaz bar. Hold the mouse to pour; the stream lands on whatever is below. Cars flow along the road
## both ways; some pull in and drive around in readable patterns until filled. A car leaves once it is
## 80% full and the stream moves off it: Topped off / Perfect / Good / OK, or a Miss for an overfill;
## the regulars react, the neon flashes, bills (the sale) and coins (the tip) drop on the lot and fly
## to the bill pile and the tip jar. Gas comes from the station's tank; the clock ends the day.
## GodGame starts each day (start_day: the run's mods, tank, car types) and listens for day_over.
## Views (I): HD-2D (default), the three-quarter pixel view, flat. Serves: Mastery (aim, juggle, stop on
## the dollar), Comedy (the cast of cars and regulars), Advancement (everything the run owns shows here).

const WIDTH := 1152.0
const HEIGHT := 648.0
const ROAD_Y := 78.0
const LOT := Rect2(120, 170, 912, 420)
const ENTRANCE := Vector2(300, ROAD_Y)
const EXIT := Vector2(900, 180)
## Round 9: where a visitor parks to chat (by the store), when it arrives, and how long a line shows.
## Round 10 batch B: Chez Gaétan, across the road (his kiosk stands at RIVAL_AT, his pumps in front).
const RIVAL_AT := Vector2(470, -40)
const RIVAL_TURN_X := 470.0
const RIVAL_PUMPS := [Vector2(425, 14), Vector2(515, 14)]
const VISITOR_SPOT := Vector2(150, 200)  # the lot's corner by the store, out of the way (playtest 9)
const VISITOR_AT := 3.0
const CHAT_LINE := 3.2
## The tube man (Bonhomme gonflable, round 8) dances here, by the road left of the entrance.
const TUBE_AT := Vector2(1060, 138)
const TUBE_EVERY := 8.0
const TUBE_REACH := 240.0
const CASH_AT := Vector2(70, 26)
## Where tips and sales land on screen: the tip jar, and the pile of bills beside it.
## Round 10: coins by value (playtest 10: coins, not poker chips), stacked in a tray bottom right.
const COIN_VALUES := [50, 20, 5, 1]
const COIN_COLORS := {1: Color(0.25, 0.55, 1.0), 5: Color(0.25, 0.8, 0.35), 20: Color(0.95, 0.22, 0.22), 50: Color(0.68, 0.35, 0.95)}
const TRAY_AT := Vector2(872, 632)  # the tray's left end, on the grass below the lot
const REGISTER_AT := Vector2(1092, 600)
const NOZZLE_RAISE := Vector2(-20, -96)  # the nozzle hovers up-left of where its stream lands
const CAR_COLORS := [Color(0.45, 0.55, 0.7), Color(0.7, 0.42, 0.36), Color(0.5, 0.62, 0.45),
	Color(0.72, 0.66, 0.48), Color(0.55, 0.48, 0.66), Color(0.8, 0.8, 0.78), Color(0.82, 0.42, 0.17)]
const TIER_COLORS := {
	ScoreTiers.SUPER_PERFECT: Color(1.0, 0.85, 0.3), ScoreTiers.PERFECT: Color(0.35, 0.9, 0.45),
	ScoreTiers.GOOD: Color(0.6, 0.8, 1.0), ScoreTiers.OK: Color(0.95, 0.85, 0.4), ScoreTiers.MISS: Color(0.95, 0.35, 0.3),
	ScoreTiers.UNSERVED: Color(0.62, 0.6, 0.58),
}
const GAS := Color(0.98, 0.76, 0.18)
## Pixel art from claude-pxl (assets/art/pixel/god_pump.px.js), shown at 2x with nearest filtering.
const PIXEL := "res://assets/art/pixel/out/sprites/%s.png"
const CAR_SPRITES := ["car", "car_red", "car_green", "car_cream", "car_purple", "car_white", "car_orange"]
const NOZZLE_TIP := Vector2(110, 74)  # the spout's tip in the nozzle sprite, at 2x
const NOZZLE_HOSE := Vector2(2, 90)  # where the hose leaves the handle, at 2x
## The vintage pump on screen (bottom left): it shows the round's gas on its dial, and its hose runs
## to the nozzle in your hand.
const PUMP_AT := Vector2(18, 474)
## Isometric try (#36): the world is drawn into a half-resolution viewport and doubled on screen.
const ISO_VIEWPORT := Vector2(576, 324)
const STACKS := ["blue", "red", "green", "cream", "purple", "white", "orange"]

@export var flow_rate := 4.0
## A safeguard: the round's gas is what really ends it.
@export var round_seconds := 45.0
## Gas the round starts with, in pump dollars.
@export var tank_size := 75.0  # god-pump playtest 2: $150 took too long
## Tip at 100% full; a top-off without spilling adds the bonus.
@export var max_tip := 6.0
@export var topoff_bonus := 2.0
@export var customer_chance := 0.5
@export var max_in_lot := 5
@export var traffic_gap := Vector2(0.5, 1.4)
## Round 10 B: cars both ways now want gas, split with Gaétan. At 50% you get round 9's traffic
## (only eastbound cars, 55% of them, used to pull in).
const WANTS_MULT := 1.1
@export var orders: Array[float] = [10.0, 15.0, 20.0, 25.0, 30.0]
## Tests switch these off.
var auto_traffic := true
## Round 10 batch B: the share of the cars wanting gas that pick you (0–100). GodGame sets it each morning.
var market_share := GodData.START_SHARE
var rival_cars := 0
var sound_on := true

## GOD PUMP (docs/GOD_PUMP_PLAN.md): GodGame runs the day through start_day() and listens for day_over;
## unmanaged (tests, the old prototype) the day shows its own summary.
signal day_over(report: Dictionary)
var managed := false
## The numbers this day runs on (GodMods.compute): upgrades, cards, Papa's Garage.
var mods := GodData.BASE.duplicate()
## Car types that can show up today (unlocked in the meta).
var car_pool: Array = ["sedan"]
## The night-shop upgrades owned (GodGame sets it at opening): the station shows them as props.
var owned := {}
## Round 8: the two-parent upgrades and Papa's Garage perks (tiers) and bling the lot and nozzle show.
var links: Array = []
var perks := {}
var bling: Array = []
var bling_owned: Array = []
## The bling hanging off and standing on the nozzle (round 8): a component that swings with it.
var nozzle_bling := NozzleBling.new()
var day_num := 1
## Drone nozzles: each {pos, car, state, goal}.
var drones: Array[Dictionary] = []
var _first_car_done := false
var _cars_today := 0
var _saves_left := 0
## Round 8: today is hockey night (Soirée du hockey), and the low-gas alarm has spoken (Jauge d'alarme).
var hockey_night := false
var _alarm_said := false
## Round 9, the lore: today's visit (Visitors.beat_for, set by GodGame), the visitor's car, the chat
## in progress ({i, t}: the line showing and its seconds left) and the visitor's own bubble.
var visit := {}
var visitor_car: ProtoCar
var chat_line := {}
## Today's visitor chat, line by line ("Gaétan: ..."): shown beside the day report (playtest 10).
var chat_log: Array[String] = []
var _chat := {}
var _visit_t := 0.0
var _visit_done := false
## The tube man: seconds to his next grab, and what he brought in today.
var _tube_cd := 3.0
var tube_gas := 0.0
var tube_grabs := 0
## Gold blobs he spits toward the pump: {t, from, to} in screen space.
var _spits: Array[Dictionary] = []
## Below this much gas, the alarm (Jauge d'alarme) blinks on the pump and a regular says so.
const LOW_GAS := 60.0
var _best_combo := 1
var fines := 0.0
var stolen := 0.0
var applause := 0
const DRONE_FLOW := 2.2
const DRONE_SPEED := 260.0
## Round 10: each drone burns this much gas ($/s) from the tank while it flies or pours.
const DRONE_BURN := 0.3
var drone_gas := 0.0

var rng := RandomNumberGenerator.new()
var tiers := ScoreTiers.new()
var economy := FuelEconomy.new()
var combo := ComboComponent.new()
var cars: Array[ProtoCar] = []
var puddles: Array[Dictionary] = []
var round_num := 1
var round_t := 0.0
var round_over := false
var round_earned := 0.0
var round_wasted := 0.0
var round_poured := 0.0
var cash := 0.0
var shown_cash := 0.0
var cars_spawned := 0
var customers_arrived := 0
var pouring := false
var tank := 75.0
var round_tips := 0.0
## This round's tips, in the jar, and sales, as a pile of bills beside it (#36): no running cash
## counter during the round; the summary adds it all up.
var tip_jar := 0.0
var round_sales := 0.0
## Coins landed in the tray today, by value. They slide into the register at closing.
var stacks := {1: 0, 5: 0, 20: 0, 50: 0}
## Closing: seconds left while the stacks go into the register; the report waits for it.
@export var cash_in_time := 2.2
## Round 11: the first day's tutorial (null once it's done), and the chain on screen: the multipliers paid
## by the chain running now, its pop when it climbs, its break.
var tutorial: Tutorial
var chain: Array[int] = []
var _combo_pop := 0.0
var _combo_break := 0.0
var _chain_fly := {}  # a broken chain's value flying to today's total: {"value", "t"}
## Round 11: the big OUVERT / FERMÉ sign over the lot: {"open": bool, "t": seconds since it swung in}.
var banner := {}
var _cash_in := 0.0
var _reported := false  # round 11D: the report opens while the coins are still pouring in
## The GAZ BAR neon flashes like a pinball machine on Good or better (seconds left, and the grade).
var neon_flash := 0.0
var neon_tier := ""
## The regulars on the bench by the dépanneur, and what one of them just said.
var regulars: Array[Dictionary] = []
## Round 8: their routines (RegularsCrew): bench, a look at the lot, a coffee inside, a smoke.
var crew: RegularsCrew
var quip_text := ""
var quip_who := 0
var quip_t := 0.0
var _next_idle_quip := 6.0
var _spill_quipped := 0.0
## The opening sign on the door: the clock reads 7 h at the start of a round and 13 h at the
## safeguard; the round's length doesn't change.
const OPEN_HOUR := 7.0
const CLOSE_HOUR := 13.0
const QUIPS := {
	ScoreTiers.SUPER_PERFECT: ["WOW, MON HOMME!", "ÇA C'EST DE L'OUVRAGE!", "PILE POIL!", "Y'A DU TALENT, LE JEUNE!"],
	ScoreTiers.PERFECT: ["BELLE JOB!", "PAS PIRE PANTOUTE!", "PLEIN COMME UN OEUF!"],
	ScoreTiers.GOOD: ["C'EST BEAU, ÇA.", "CORRECT.", "PAS MAL."],
	"spill": ["AYOYE...", "VOYONS DONC!", "Y'EN A PARTOUT!", "TON PÈRE FAISAIT PAS ÇA."],
	"idle": ["Y FAIT BEAU À MATIN.", "T'AS-TU VU LE PRIX DU GAZ?", "MON BEAU-FRÈRE A UN CHAR DE MÊME.",
		"TON PÈRE, LUI, Y'ALLAIT À PÊCHE.", "UNE AUTRE PETITE BIÈRE?",
		# round 8, the lore: the town talks about the kid, and about Dad
		"J'TE JURE, J'AI VU TON PÈRE AU LAC!", "Y'EST PAS MORT, TON PÈRE. J'LE SAIS.", "Y DEVIENT BON, LE P'TIT.",
		"Y'É-TU CÉLIBATAIRE, LUI?", "LE GARS D'EN FACE A MONTÉ SES PRIX.", "LE NOTAIRE A L'AIR NERVEUX."],
	"low_gas": ["LE GAZ BAISSE, MON GRAND!", "Y RESTE PU BEN BEN D'GAZ!", "APPELLE LE CAMION!"],
	"hockey": ["LE MATCH COMMENCE À SOIR!", "C'EST SOIR DE HOCKEY!", "TOUTE LA PAROISSE EST SUR LA ROUTE!"],
}

var _aim := Vector2(WIDTH * 0.5, 380)
var _nozzle := _aim
## The cars inside the nozzle ring taking gas now (one, or more with Double jet).
var stream_cars: Array[ProtoCar] = []
var _next_car := 0.0
## Cash dropped by cars (#36): bills for the sale, coins for the tip. They fall out of the car,
## bounce, lie on the lot for a beat, then get pulled into the cash counter.
var money: Array[Dictionary] = []
var _bits: Array[Dictionary] = []
var _floaters: Array[Dictionary] = []
var _shake := 0.0
var _t := 0.0
var _overlay: Node2D
var _sfx := {}
var _glug: AudioStreamPlayer
var _tex := {}
## Which view draws the lot (I cycles them): "hd" (HD-2D: pixel art in a lit 3D scene, the try after
## god-pump playtest 5), "pixel" (the three-quarter pixel view) or "flat" (top-down greybox).
@export var view := "cartoon"
## Round 10 C: the cartoon view maps the world a little smaller and lower, so Gaétan's station across the
## road fits under the HUD and the lot clears the tray.
const CARTOON_XF := Transform2D(Vector2(0.85, 0), Vector2(0, 0.85), Vector2(86, 85))
const CARTOON_K := 0.85
## Each sprite stack's paint in the cartoon view (visitors and sedans).
const STACK_PAINTS := {"blue": Color(0.24, 0.55, 1.0), "red": Color(1.0, 0.36, 0.33), "green": Color(0.49, 0.87, 0.36),
	"cream": Color(1.0, 0.93, 0.7), "purple": Color(0.68, 0.45, 0.95), "white": Color(0.95, 0.95, 0.97),
	"orange": Color(1.0, 0.6, 0.18), "papa": Color(1.0, 0.55, 0.15)}
var _prop_t := {}  # upgrade id -> seconds since its prop popped in (cartoon view)
## True while the three-quarter pixel view is up; `hd` while the HD-2D view is.
var iso := false
var hd := false
var _hd_vp: SubViewport
var _hd_view: HD2DView
var _hd_sprite: Sprite2D
## World (top-down) to iso viewport pixels: x runs down-right, y down-left, at 0.4 scale.
## World (top-down) to the scene view's pixels: a high-angle three-quarter camera, the ground
## foreshortened to 0.8 (designer's ask after the isometric try).
var iso_xf := Transform2D(Vector2(0.5, 0), Vector2(0, 0.4), Vector2(0, 52))
## The OUVERT/FERMÉ sign's flip (1 = just flipped, 0 = settled).
var sign_flip := 0.0
var _kick := 0.0
var _music: AudioStreamPlayer
var _iso_vp: SubViewport
var _iso_view: IsoView
var _iso_sprite: Sprite2D


func _ready() -> void:
	rng.randomize()
	tank = tank_size
	# The regulars (round 8): Ti-Guy, Mme Gagnon, Bertrand and Le Grand, with their routines.
	crew = RegularsCrew.new(rng)
	regulars = crew.list
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # crisp pixels; cars and the overlay inherit it
	for id in CAR_SPRITES + ["nozzle", "bill", "coin_0", "coin_1", "coin_2", "coin_3", "puddle_s", "puddle_m",
			"puddle_l", "sparkle", "asphalt", "road", "dirt", "neon_gazbar", "neon_gazbar_off", "neon_gaz", "neon_bar",
			"nozzle_idle", "nozzle_squeeze", "pump_hud", "tip_jar", "gauge_face", "bench", "clock_face",
			"sign_ouvert", "sign_ferme", "storefront", "dirt2", "grass_a", "grass_b", "grass_c", "oil_stain", "crack",
			"hatch", "concrete", "tree", "tire_pile", "dumpster", "regular_0_clap", "regular_1_clap", "regular_2_clap",
			"regular_3_clap", "drone_0", "drone_1", "prop_traffic_light", "prop_sandwich", "prop_antenna", "prop_billboard",
			"prop_grocery", "prop_car_wash", "prop_loto", "prop_fuel_tank", "prop_lamp", "prop_cousin", "prop_thermos",
			"prop_coffee", "prop_tip_sign", "prop_bucket", "prop_boombox", "prop_cooler", "prop_jukebox", "badge_thief", "badge_electric", "badge_sweeper", "badge_clumsy", "regular_0", "regular_1", "regular_2", "regular_3", "regular_0_cheer",
			"regular_1_cheer", "regular_2_cheer", "regular_3_cheer"]:
		var path := PIXEL % id
		if ResourceLoader.exists(path):
			_tex[id] = load(path)
	for body in STACKS + ["rust"] + GodData.CAR_ORDER:
		for i in 8:
			var path := PIXEL % ("stack_%s_%d" % [body, i])
			if ResourceLoader.exists(path):
				_tex["stack_%s_%d" % [body, i]] = load(path)
	add_child(combo)
	_overlay = Node2D.new()
	_overlay.z_index = 10
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	_build_iso()
	_build_hd()
	set_view(view)
	ProtoCar.gauge_tex = _tex.get("gauge_face")
	if sound_on:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN  # the nozzle is the cursor
		for id in ["sfx_super_perfect", "sfx_perfect", "sfx_good", "sfx_ok", "sfx_miss", "pop", "counter_1", "counter_2", "counter_3",
				"applause", "cash", "horn", "truck"]:
			var p := AudioStreamPlayer.new()
			p.stream = load("res://assets/audio/placeholder/%s.wav" % id)
			add_child(p)
			_sfx[id] = p
		_music = AudioStreamPlayer.new()  # "Roadside At Two", looped
		_music.stream = load("res://assets/audio/music/roadside_at_two.mp3")
		_music.volume_db = -12.0
		_music.finished.connect(_music.play)
		add_child(_music)
		_music.play()
		_glug = AudioStreamPlayer.new()
		_glug.stream = load("res://assets/audio/placeholder/glug_loop.wav")
		_glug.volume_db = -8.0
		add_child(_glug)


func _build_iso() -> void:
	_iso_vp = SubViewport.new()
	_iso_vp.size = Vector2i(ISO_VIEWPORT)
	_iso_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_iso_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_iso_vp)
	_iso_view = IsoView.new()
	_iso_view.game = self
	_iso_vp.add_child(_iso_view)
	_iso_sprite = Sprite2D.new()
	_iso_sprite.texture = _iso_vp.get_texture()
	_iso_sprite.centered = false
	_iso_sprite.scale = Vector2(2, 2)
	_iso_sprite.visible = iso  # in case the view was switched before the game was ready
	add_child(_iso_sprite)
	move_child(_iso_sprite, _overlay.get_index())


## The HD-2D scene renders at twice the base resolution and is shown at half size: crisp on any screen.
func _build_hd() -> void:
	_hd_vp = SubViewport.new()
	_hd_vp.size = Vector2i(int(WIDTH) * 2, int(HEIGHT) * 2)
	_hd_vp.own_world_3d = true
	_hd_vp.msaa_3d = Viewport.MSAA_4X
	_hd_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_hd_vp)
	_hd_view = HD2DView.new()
	_hd_vp.add_child(_hd_view)
	_hd_view.setup(self)
	_hd_sprite = Sprite2D.new()
	_hd_sprite.texture = _hd_vp.get_texture()
	_hd_sprite.centered = false
	_hd_sprite.scale = Vector2(0.5, 0.5)
	_hd_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_hd_sprite.visible = false
	add_child(_hd_sprite)
	move_child(_hd_sprite, _overlay.get_index())


func set_view(v: String) -> void:
	view = v
	iso = v == "pixel"
	hd = v == "hd"
	if _iso_sprite:
		_iso_sprite.visible = iso
	if _hd_sprite:
		_hd_sprite.visible = hd
	if _hd_vp:
		_hd_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if hd else SubViewport.UPDATE_DISABLED
	for car in cars:
		car.visible = v == "flat"
	queue_redraw()


func cycle_view() -> void:
	set_view({"cartoon": "hd", "hd": "pixel", "pixel": "flat", "flat": "cartoon"}[view])


## Where a car's roof is on screen, in the current view.
func car_top(car: ProtoCar) -> Vector2:
	var lift: float = car.anim_offsets().lift
	if hd and _hd_view:
		return _hd_view.screen(car.position, 0.5 + lift * HD2DView.K)
	if iso:
		return scr(car.position) - Vector2(0, 16 + lift * 0.8)
	if view == "cartoon":
		return scr(car.position) - Vector2(0, 14 + lift)
	return car.position - Vector2(0, 16 + lift)


## Where regular `i`'s head is on screen (for speech bubbles), or null in the flat view.
func regular_head(i: int) -> Variant:
	if hd and _hd_view:
		return _hd_view.regular_head(i)
	if iso and _iso_view:
		return _iso_view.seat_screen(i)
	if view == "cartoon":
		return scr(regulars[i].pos) + Vector2(0, -42)
	return null


## The gaz bar's name goes up on the sign (HD-2D view).
func set_station_name(text: String) -> void:
	if _hd_view:
		_hd_view.set_station_name(text)


## A claude-pxl sprite by name, loaded the first time it's asked for (round 8: many props).
func tex(id: String) -> Texture2D:
	if not _tex.has(id):
		var path := PIXEL % id
		_tex[id] = load(path) if ResourceLoader.exists(path) else null
	return _tex[id]


## A claude-pxl animation strip (assets/art/pixel/out/anims/<id>.png), frames side by side.
func anim_tex(id: String) -> Texture2D:
	var key := "anim:" + id
	if not _tex.has(key):
		var path := "res://assets/art/pixel/out/anims/%s.png" % id
		_tex[key] = load(path) if ResourceLoader.exists(path) else null
	return _tex[key]


## Everything the station owns that shows on the lot (round 8): shop nodes, links and Garage perks.
## GodGame hands the day `owned`, `links` and `perks` each morning.
func owns_upgrade(id: String) -> bool:
	if id in links or perks.get(id, 0) > 0:
		return true
	for b in GodData.BRANCHES:
		var level: int = owned.get(b.id, 0)
		for i in mini(level, b.nodes.size()):
			if b.nodes[i].id == id:
				return true
	return false


## World point to screen point in the current view.
func scr(w: Vector2) -> Vector2:
	if hd and _hd_view:
		return _hd_view.screen(w)
	if view == "cartoon":
		return CARTOON_XF * w
	return (iso_xf * w) * 2.0 if iso else w


## Screen point (the mouse) to the world point on the ground beneath it.
func to_world(sp: Vector2) -> Vector2:
	if hd and _hd_view:
		return _hd_view.ground_at(sp)
	if view == "cartoon":
		return CARTOON_XF.affine_inverse() * sp
	return iso_xf.affine_inverse() * (sp / 2.0) if iso else sp


## Kept for the older tests: on = the three-quarter pixel view, off = flat.
func set_iso(on: bool) -> void:
	set_view("pixel" if on else "flat")


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		aim(to_world(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		aim(to_world(event.position))
		set_pouring(event.pressed)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and round_over and not managed:
			next_round()
		elif event.physical_keycode == KEY_ESCAPE and not managed:
			get_tree().quit()
		elif event.physical_keycode == KEY_I:
			cycle_view()


func _process(delta: float) -> void:
	step(delta)


# --- Controls -----------------------------------------------------------------------------------

## Where the stream lands (the mouse).
func aim(p: Vector2) -> void:
	_aim = p


func set_pouring(on: bool) -> void:
	if pouring and not on:
		_release_streams()
	if on and not pouring and not round_over:
		_kick = 1.0  # the hand squeezes: a little jolt
	pouring = on and not round_over
	if _glug:
		if pouring and not _glug.playing:
			_glug.play()
		elif not pouring:
			_glug.stop()


# --- Simulation ---------------------------------------------------------------------------------

func step(dt: float) -> void:
	_t += dt
	_nozzle = _nozzle.lerp(_aim, minf(dt * 18.0, 1.0))
	nozzle_bling.equipped = bling
	nozzle_bling.owned = bling_owned
	nozzle_bling.step(dt, _nozzle)
	if tutorial:
		tutorial.tick(dt)
	_combo_pop = maxf(_combo_pop - dt * 3.0, 0.0)
	_combo_break = maxf(_combo_break - dt * 2.0, 0.0)
	if not _chain_fly.is_empty():
		_chain_fly.t += dt
		if _chain_fly.t > 0.9:
			_chain_fly = {}
	if not round_over:
		if not (tutorial and tutorial.holds_clock()):  # the tutorial holds the clock: no rush
			round_t += dt
		if auto_traffic:
			_next_car -= dt
			if _next_car <= 0.0:
				spawn_road_car()
				_next_car = rng.randf_range(traffic_gap.x, traffic_gap.y)
		_pour(dt)
		if round_t >= round_seconds:
			end_round()
	for car in cars.duplicate():
		car.step(dt, self)
		if car.phase == ProtoCar.Phase.GONE:
			cars.erase(car)
			car.queue_free()
	if not round_over:
		_step_patience(dt)
		_step_roles(dt)
		_step_drones(dt)
		_step_tube_man(dt)
		_step_vacuum(dt)
		_step_herd(dt)
		_step_visit(dt)
		if int(mods.get("tank_alarm", 0)) > 0 and tank < LOW_GAS and not _alarm_said:
			_alarm_said = true  # Jauge d'alarme: the regulars notice before you run dry
			say(QUIPS.low_gas)
	if _cash_in > 0.0:
		_cash_in -= dt
		if not _reported and cash_in_progress() >= 0.55:
			_report_now()  # the report opens as the stacks start pouring into the register
		if _cash_in <= 0.0:
			_finish_day()
	if not banner.is_empty():
		banner.t += dt
	_step_fx(dt)
	for id in _prop_t:
		_prop_t[id] += dt
	queue_redraw()
	_overlay.queue_redraw()
	if iso and _iso_view:
		_iso_view.queue_redraw()


func _pour(dt: float) -> void:
	if not pouring:
		return
	for c in cars:  # pouring on the thief scares it; on the electric car, a fine
		if c.role in ["thief", "electric"] and c.accepts_fuel() and _aim.distance_to(c.position) <= ring_radius():
			_react(c)
	var targets := cars_in_ring()
	if targets.is_empty() and mods.auto_aim > 0.0:  # auto-aim: the stream bends toward a car nearby
		var near := nearest_customer(_aim, mods.auto_aim + ProtoCar.SIZE.x * 0.55)
		if near:
			targets = [near]
	targets = targets.slice(0, streams())
	for c in stream_cars:
		if not c in targets and not drone_on(c):
			_settle(c)  # the ring slid off: a car 80% full or more settles now (unless a drone still pours)
	stream_cars = targets
	if targets.is_empty():  # no car in the ring: it all runs onto the ground
		var spilt: float = minf(flow_rate * dt, tank) * mods.spill_mult  # gas saver: less runs onto the ground
		tank -= spilt
		round_poured += spilt
		_waste(spilt, _aim)
	if tutorial and not targets.is_empty():
		tutorial.event("poured")
	for car in targets:  # each car in the ring gets a full stream (Double jet: twice the gas per second)
		var dollars := minf(flow_rate * dt * car.fill_speed, tank)
		if car.amount >= car.target:
			dollars *= mods.spill_mult
		tank -= dollars
		round_poured += dollars
		var overflow := car.receive(dollars)
		if overflow > 0.0:  # the tank is full: it runs down the side of the car
			_waste(overflow, car.position + Vector2(rng.randf_range(-24, 24), rng.randf_range(12, 22)))
	if tank <= 0.0001:
		tank = 0.0
		_floaters.append({"text": "PLUS DE GAZ!", "pos": Vector2(WIDTH * 0.5, 260), "life": 2.5, "color": Color(1, 0.4, 0.3), "size": 40})
		end_round()  # out of gas
		return
	if rng.randf() < 0.6:
		_bits.append({"pos": scr(_aim), "vel": Vector2(rng.randf_range(-60, 60), rng.randf_range(-90, -30)),
			"life": 0.35, "color": GAS, "size": 2.5})


## How far the nozzle reaches from where it points (the ring on the ground). A wider nozzle grows it.
func ring_radius() -> float:
	return ProtoCar.SIZE.x * 0.55 + float(mods.get("stream_radius", 0.0))


## How many cars the nozzle fills at once: one, plus Double jet.
func streams() -> int:
	return 1 + int(mods.get("twin_stream", 0))


## The customers inside the ring still taking gas, nearest first.
func cars_in_ring() -> Array[ProtoCar]:
	var inside: Array[ProtoCar] = []
	for car in cars:
		if car.customer and car.accepts_fuel() and _aim.distance_to(car.position) <= ring_radius():
			inside.append(car)
	inside.sort_custom(func(a: ProtoCar, b: ProtoCar) -> bool: return _aim.distance_to(a.position) < _aim.distance_to(b.position))
	return inside


## Letting go: every car the nozzle was filling settles.
func _release_streams() -> void:
	for c in stream_cars:
		if not drone_on(c):  # playtest 12: a drone still pouring keeps it here; the drone settles it
			_settle(c)
	stream_cars.clear()


## Is a drone pouring into this car (or hovering over it, waiting for you to let go)?
func drone_on(car: ProtoCar) -> bool:
	return drones.any(func(d: Dictionary) -> bool: return d.car == car and d.state in ["pouring", "waiting"])


func car_at(p: Vector2) -> ProtoCar:
	var reach := ProtoCar.SIZE.x * 0.55 + float(mods.get("stream_radius", 0.0))
	for car in cars:
		if (car.customer or car.role in ["thief", "electric"]) and car.accepts_fuel() and p.distance_to(car.position) <= reach:
			return car
	return null


## The nearest customer still taking fuel within `reach` of `p` (auto-aim, twin stream, drones).
func nearest_customer(p: Vector2, reach: float, except: ProtoCar = null) -> ProtoCar:
	var best: ProtoCar = null
	var best_d := reach
	for car in cars:
		if car == except or not car.customer or not car.accepts_fuel():
			continue
		var d := p.distance_to(car.position)
		if d <= best_d:
			best_d = d
			best = car
	return best


## Spilled gas: a puddle, counted as wasted (the recycler sends some back to the tank).
func _waste(dollars: float, at: Vector2) -> void:
	round_wasted += dollars
	_spill(at, dollars)
	if int(mods.get("recycle", 0)) > 0:
		tank += dollars * 0.7


## Pouring on the thief scares it off; pouring on the electric car earns a fine.
func _react(car: ProtoCar) -> void:
	if car.angry:
		return
	car.angry = true
	var top := scr(car.position) + Vector2(0, -60)
	if car.role == "thief":
		if int(mods.get("clamp_thief", 0)) > 0:
			_clamp_thief(car)
			return
		_floaters.append({"text": "SAUVE-TOI!", "pos": top, "life": 1.6, "color": Color(1, 0.6, 0.3), "size": 22})
	else:
		fines += 10.0
		cash -= 10.0
		_floaters.append({"text": "JE SUIS ÉLECTRIQUE! -$10", "pos": top, "life": 1.8, "color": Color(0.5, 1, 0.6), "size": 20})
		_play("horn")
	car.leave(self)


func spawn_road_car() -> ProtoCar:
	# Two-way traffic (playtest 6): cars heading east ride the near lane and may pull in; westbound
	# cars on the far lane just drive by.
	var east := rng.randf() < 0.55
	var car := _new_car(Vector2(-60, ROAD_Y + 12 + rng.randf_range(-3, 3)) if east else Vector2(WIDTH + 60, ROAD_Y - 14 + rng.randf_range(-3, 3)))
	car.road_dir = 1.0 if east else -1.0
	car.heading = 0.0 if east else PI
	car.pattern = ProtoCar.PATTERNS[rng.randi() % ProtoCar.PATTERNS.size()]
	car.target = orders[rng.randi() % orders.size()]
	if rng.randf() < customer_chance * WANTS_MULT:  # it wants gas: a low gauge, then you or Gaétan
		car.set_type(_pick_type(), rng)  # a customer, or one of the troublemakers
		car.low_fuel = car.customer
		if rng.randf() * 100.0 < market_share or rng.randf() < mods.get("poach", 0.0):  # Vol de clients
			car.wants_in = true
		else:
			car.to_rival = true
			car.customer = false
			rival_cars += 1
	else:
		car.customer = false
	car.patience = 24.0 * mods.patience_mult * car.patience_k
	cars_spawned += 1
	return car


## Where a car parks at Gaétan's: by one of his two pumps.
func rival_spot(car: ProtoCar) -> Vector2:
	var free: Array = RIVAL_PUMPS.filter(func(p: Vector2) -> bool: return not cars.any(func(c: ProtoCar) -> bool: return c != car and c.phase == ProtoCar.Phase.RIVAL and c.position.distance_to(p) < 30.0))
	var spot: Vector2 = free[0] if not free.is_empty() else RIVAL_PUMPS[rng.randi() % RIVAL_PUMPS.size()]
	return spot + Vector2(rng.randf_range(-6, 6), rng.randf_range(-4, 4))


## Sabot de Denver: the thief is clamped where it stands, and everything it stole goes back in the tank.
func _clamp_thief(car: ProtoCar) -> void:
	if car.clamped:
		return
	car.clamped = true
	car.angry = true
	car.moving = false
	tank += car.stolen
	stolen = maxf(stolen - car.stolen, 0.0)
	_floaters.append({"text": "SABOT! +$%d DE GAZ" % int(car.stolen), "pos": scr(car.position) + Vector2(0, -60), "life": 1.6, "color": Color(1, 0.85, 0.2), "size": 22})
	car.stolen = 0.0
	_play("horn")


## Today's visitor: drives in, parks by the store, the lines play one by one, then it drives off.
func _step_visit(dt: float) -> void:
	if visit.is_empty() or _visit_done:
		return
	if not visitor_car:
		_visit_t += dt
		if _visit_t >= VISITOR_AT:
			visitor_car = _new_car(Vector2(-60, ROAD_Y + 12))
			visitor_car.road_dir = 1.0
			visitor_car.customer = false
			visitor_car.wants_in = true
			visitor_car.visitor = true
			visitor_car.stack = Visitors.CAST[visit.who].stack
		return
	if not visitor_car.parked:
		return
	if _chat.is_empty():
		_chat = {"i": -1, "t": 0.0}
	_chat.t -= dt
	if _chat.t > 0.0:
		return
	_chat.i += 1
	var lines: Array = visit.lines
	if _chat.i >= lines.size():
		_visit_done = true
		chat_line = {}
		visitor_car.leave(self)
		return
	var who: String = lines[_chat.i][0]
	var text := "%s: %s" % [tr(Visitors.speaker_name(who)), tr(lines[_chat.i][1])]
	chat_log.append(text)
	_chat.t = CHAT_LINE
	if Visitors.CAST.has(who):
		chat_line = {"text": text}
		return
	chat_line = {}
	var idx := RegularsCrew.NAMES.find(who)
	if idx >= 0:
		var r: Dictionary = regulars[idx]
		if r.state == "inside":  # they step out to answer
			r.pos = RegularsCrew.DOOR
			r.state = "stand"
			r.t = CHAT_LINE + 1.0
		quip_who = idx
		quip_text = text
		quip_t = CHAT_LINE


func chatting() -> bool:
	return not _chat.is_empty() and not _visit_done


## The tube man (Bonhomme gonflable): every few seconds he grabs a car driving by within his reach.
func _step_tube_man(dt: float) -> void:
	for s in _spits.duplicate():
		s.t += dt
		if s.t > 0.7:
			_spits.erase(s)
	var tier := int(mods.get("tube_man", 0))
	if tier <= 0:
		return
	_tube_cd -= dt
	if _tube_cd > 0.0:
		return
	for car in cars:
		if car.phase == ProtoCar.Phase.ROAD and not car.wants_in and absf(car.position.x - TUBE_AT.x) < TUBE_REACH:
			car.grab(self, tier >= 2)
			_tube_cd = TUBE_EVERY
			return


## Round 10 E, the spill branch: the Aspirateur gonflable, a second tube man by the lot. Every few seconds
## he sucks up the biggest puddle and puts most of it back in the tank. Serves: Mastery (spills hurt less).
const VACUUM_AT := Vector2(1060, 560)
const VACUUM_EVERY := 4.0
const VACUUM_RETURN := 0.7
const VACUUM_SLURP := 1.4  # how long the slurp plays: lean over, suck, swallow
var _vacuum_cd := VACUUM_EVERY
var vacuumed := 0.0
## The puddle he's sucking up now (for the drawing), and how long the slurp has left.
var vacuum_slurp := {}


func _step_vacuum(dt: float) -> void:
	if not vacuum_slurp.is_empty():
		vacuum_slurp.t -= dt
		if vacuum_slurp.t <= 0.0:
			vacuum_slurp = {}
	if int(mods.get("puddle_vacuum", 0)) <= 0:
		return
	_vacuum_cd -= dt
	if _vacuum_cd > 0.0 or puddles.is_empty():
		return
	_vacuum_cd = VACUUM_EVERY
	var biggest: Dictionary = puddles[0]
	for p in puddles:
		if p.get("gas", 0.0) > biggest.get("gas", 0.0):
			biggest = p
	var back: float = biggest.get("gas", 0.0) * VACUUM_RETURN
	tank += back
	vacuumed += back
	round_wasted = maxf(round_wasted - back, 0.0)  # the books count only what's really lost
	vacuum_slurp = {"pos": biggest.pos, "t": VACUUM_SLURP, "r": biggest.r}
	puddles.erase(biggest)


## Round 10 E, the MULTI-JET branch: the Chien de berger robot. Every HERD_EVERY seconds he runs out and
## rounds your customers up into a tight circle around where the nozzle points, so one ring can reach two
## or three of them; then they go back to their rounds. Serves: Mastery (set up the multi-fill).
const HERD_EVERY := 12.0
const HERD_SECONDS := 2.6
var _herd_cd := HERD_EVERY
var herd_t := 0.0
var herd_centre := Vector2.ZERO
var dog_pos := Vector2(216, 190)


func _step_herd(dt: float) -> void:
	if int(mods.get("herd_dog", 0)) <= 0:
		return
	if herd_t > 0.0:
		herd_t -= dt
		dog_pos = dog_pos.lerp(herd_centre + Vector2.from_angle(_t * 6.0) * ring_radius() * 1.6, minf(dt * 6.0, 1.0))  # he runs circles round them
		if herd_t <= 0.0:
			for car in cars:
				if car.herded:
					car.herded = false
					car.start_pattern(self)
		return
	dog_pos = dog_pos.lerp(Vector2(216, 190), minf(dt * 3.0, 1.0))  # back by the door
	_herd_cd -= dt
	if _herd_cd > 0.0:
		return
	_herd_cd = HERD_EVERY
	herd()


## The dog rounds the customers up now, around the nozzle's aim.
func herd() -> void:
	herd_centre = _aim.clamp(LOT.position + Vector2(60, 50), LOT.end - Vector2(60, 50))
	herd_t = HERD_SECONDS
	var flock := cars.filter(func(c: ProtoCar) -> bool: return c.customer and c.accepts_fuel() and c.phase == ProtoCar.Phase.WANDER and not c.clamped)
	var r := maxf(ring_radius() * 0.75, 24.0)
	for i in flock.size():
		var car: ProtoCar = flock[i]
		car.herded = true
		car.herd_to = herd_centre + Vector2.from_angle(TAU * i / flock.size()) * (r if flock.size() > 1 else 0.0)


## He's got it: its gas goes into the tank (spat as gold blobs at the pump).
func tube_siphon(car: ProtoCar) -> void:
	var gas := rng.randf_range(8.0, 16.0)
	tank += gas
	tube_gas += gas
	tube_grabs += 1
	_floaters.append({"text": "+$%d DE GAZ" % int(gas), "pos": scr(TUBE_AT) + Vector2(-130, -40), "life": 1.4, "color": GAS, "size": 20})
	var mouth := scr(TUBE_AT) + Vector2(0, -150)
	for i in 6:
		_spits.append({"t": -i * 0.09, "from": mouth, "to": PUMP_AT + Vector2(36, 24)})
	_play("pop")


## Tier 2: he sets the emptied car down on the lot, where it wants a fill like any customer.
func tube_drop(car: ProtoCar) -> void:
	car.set_type(_pick_type(true), rng)
	car.customer = true
	car.amount = 0.0
	car.spilled = 0.0
	car.waited = 0.0
	car.patience = 24.0 * mods.patience_mult
	car.phase = ProtoCar.Phase.WANDER
	car.pattern = ProtoCar.PATTERNS[rng.randi() % ProtoCar.PATTERNS.size()]
	car.start_pattern(self)
	customers_arrived += 1


## A customer already parked in the lot (tests, and handy for tuning).
func park_customer(target: float, at: Vector2) -> ProtoCar:
	var car := _new_car(at)
	car.customer = true
	car.target = target
	car.phase = ProtoCar.Phase.WANDER
	car.pattern = ProtoCar.PATTERNS[rng.randi() % ProtoCar.PATTERNS.size()]
	car.start_pattern(self)
	return car


func _new_car(at: Vector2) -> ProtoCar:
	var car := ProtoCar.new()
	car.position = at
	car.tiers = tiers
	var look := rng.randi() % CAR_COLORS.size()
	car.color = CAR_COLORS[look]
	car.sprite = _tex.get(CAR_SPRITES[look % CAR_SPRITES.size()])
	car.stack = STACKS[look % STACKS.size()]
	car.look = look
	car.visible = view == "flat"
	car.spill_grace = 0.25 + float(mods.get("overfill_grace", 0.0))
	add_child(car)
	move_child(car, _overlay.get_index())  # cars draw under the stream and HUD
	cars.append(car)
	return car


func lot_has_room() -> bool:
	if round_over:
		return false  # closed: cars on the road drive past
	var n := 0
	for car in cars:
		if car.phase in [ProtoCar.Phase.ENTERING, ProtoCar.Phase.WANDER, ProtoCar.Phase.CELEBRATE]:
			n += 1
	return n < max_in_lot


func random_lot_point() -> Vector2:
	return Vector2(rng.randf_range(LOT.position.x + 60, LOT.end.x - 60), rng.randf_range(LOT.position.y + 70, LOT.end.y - 50))


## Cars nudge apart so they don't stack.
func separation(me: ProtoCar) -> Vector2:
	var push := Vector2.ZERO
	for other in cars:
		if other != me and other.phase == ProtoCar.Phase.WANDER:
			var d := me.position - other.position
			if d.length() < 70.0 and d.length() > 0.01:
				push += d.normalized() * (70.0 - d.length()) * 2.0
	return push


## The tip grows from nothing at 80% to max_tip at 100% (squared, so the last few percent count most);
## topping off adds a bonus; overfilling (a spill over $0.25) loses the tip altogether.
## Everything that multiplies a car's tip today: the car type, the shop, cards, the meta, procs.
func _tip_mult(car: ProtoCar) -> float:
	var m: float = car.tip_mult * mods.tip_mult
	if car.by_drone:
		m *= 0.5
	if int(mods.happy_hour) > 0 and hour_now() < GodData.OPEN_HOUR + 2.0:
		m *= 3.0  # round 11: the card is a big deal now
	if not _first_car_done:
		_first_car_done = true
		m *= mods.first_car_tip_mult
	if int(mods.get("bobblehead", 0)) > 0:
		m *= 1.0 + 0.05 * combo.multiplier
	var every := int(mods.get("loyalty_every", 0))
	if every > 0 and (_cars_today + 1) % every == 0:  # Carte fidélité: a regular, who tips double
		m *= 2.0
		_floaters.append({"text": "UN HABITUÉ! x2", "pos": scr(car.position) + Vector2(0, -150), "life": 1.4, "color": Color(0.6, 0.9, 1.0), "size": 18})
	if hour_now() >= 19.0:
		m *= mods.get("night_tip_mult", 1.0)  # Néons de nuit
	var luck: float = 1.0 + mods.luck / 100.0  # luck raises every proc's odds
	if mods.golden_chance > 0.0 and rng.randf() < mods.golden_chance * luck:
		m *= 3.0
		_floaters.append({"text": "DORÉ!", "pos": scr(car.position) + Vector2(0, -130), "life": 1.4, "color": Color(1, 0.85, 0.2), "size": 24})
	if mods.jackpot_chance > 0.0 and rng.randf() < mods.jackpot_chance * luck:
		m *= 4.0
		_floaters.append({"text": "JACKPOT!", "pos": scr(car.position) + Vector2(0, -130), "life": 1.6, "color": Color(1, 0.5, 0.9), "size": 26})
	return m


func tip_for(fill: float, spilled: float) -> float:
	if fill < 0.9 or spilled > 0.25:
		return 0.0  # OK fills and overfills don't tip
	var k := clampf((fill - 0.9) / 0.1, 0.0, 1.0)
	var tip := max_tip * pow(k, 1.5)
	if fill >= 0.995:
		tip += mods.get("topoff_bonus", topoff_bonus)
	return tip


func _settle(car: ProtoCar) -> void:
	var t := car.stream_left()
	if t == "":
		return
	var breaks := not combo.tiers.extends_combo(t)
	if t == ScoreTiers.OK and int(mods.combo_lock) > 0:
		breaks = false  # combo lock: an OK keeps the chain
	if t == ScoreTiers.MISS and _saves_left > 0:
		_saves_left -= 1  # Saint Christophe: an overfill forgiven
		breaks = false
	var paid_mult := 0
	if not car.by_drone and (breaks or combo.tiers.extends_combo(t)):
		paid_mult = combo.register(t)
	_best_combo = maxi(_best_combo, combo.multiplier)
	_count(car, t, paid_mult if combo.tiers.extends_combo(t) else 0)
	if paid_mult > 0 and combo.tiers.extends_combo(t):  # the chain climbs
		chain.append(paid_mult)
		_combo_pop = 1.0
		if tutorial and chain.size() >= 2:
			tutorial.event("chain2")
	elif breaks and not car.by_drone and not chain.is_empty():  # the chain breaks: its value banks into today's total
		_break_chain()
	if tutorial:
		tutorial.event("settled")
	var miss_fine: float = GodData.CAR_TYPES.get(car.type_id, {}).get("miss_fine", 0.0)
	if t == ScoreTiers.MISS and miss_fine > 0.0:  # the trio elétrico: the samba is ruined
		fines += miss_fine
		cash -= miss_fine
		_floaters.append({"text": tr("SAMBA RUINED! -$%d") % int(miss_fine), "pos": scr(car.position) + Vector2(0, -120), "life": 1.8, "color": Color(1, 0.35, 0.3), "size": 26})
	var tips_ok := not (car.by_drone or car.drone_touched)  # playtest 10: a car a drone touched never tips
	car.tip = tip_for(car.fill(), car.spilled) * _tip_mult(car) if tips_ok else 0.0
	if t in [ScoreTiers.SUPER_PERFECT, ScoreTiers.PERFECT]:
		if tips_ok:
			car.tip += mods.perfect_bonus + mods.applause_bonus
		applause += 1
	if t == ScoreTiers.SUPER_PERFECT and tips_ok:
		if int(mods.get("double_or_nothing", 0)) > 0:
			car.tip *= 3.0  # Double ou rien: a top-off triples
		car.tip += mods.get("topoff_coin", 0.0)  # Pluie de pièces: a $20 coin on top
	if tips_ok and mods.loto_chance > 0.0 and rng.randf() < mods.loto_chance * (1.0 + mods.luck / 100.0):
		car.tip += 20.0
		_floaters.append({"text": "LOTO! +$20", "pos": scr(car.position) + Vector2(0, -110), "life": 1.6, "color": Color(1, 0.9, 0.3), "size": 22})
	var sale: float = minf(car.amount, car.target) * car.pay_share * mods.get("sale_mult", 1.0) + mods.per_car_bonus
	if t == ScoreTiers.MISS and int(mods.get("double_or_nothing", 0)) > 0:
		sale = 0.0  # Double ou rien: an overfilled car pays nothing
		car.tip = 0.0
		_floaters.append({"text": tr("NOTHING!"), "pos": scr(car.position) + Vector2(0, -120), "life": 1.4, "color": Color(1, 0.35, 0.3), "size": 24})
	if mods.get("coffee_sale", 0.0) > 0.0 and car.waited > 3.0:  # Fenêtre au volant: a coffee while they waited
		sale += mods.coffee_sale
		_floaters.append({"text": "CAFÉ +$%d" % int(mods.coffee_sale), "pos": scr(car.position) + Vector2(30, -40), "life": 1.0, "color": Color(0.85, 0.65, 0.4), "size": 15})
	if car.by_drone:
		sale += mods.get("drone_bonus", 0.0)  # Hangar à drones
	_cars_today += 1
	if int(mods.refund_every) > 0 and _cars_today % int(mods.refund_every) == 0:
		tank += car.amount  # rabbit's foot: this car's gas goes back in the tank
	car.paid = sale + car.tip
	round_earned += car.paid
	round_tips += car.tip
	round_sales += sale
	tip_jar += car.tip
	cash += car.paid
	if t in [ScoreTiers.SUPER_PERFECT, ScoreTiers.PERFECT, ScoreTiers.GOOD]:
		neon_flash = {ScoreTiers.SUPER_PERFECT: 1.8, ScoreTiers.PERFECT: 1.1, ScoreTiers.GOOD: 0.6}[t]
		neon_tier = t
		say(QUIPS[t])
	# The regulars: everyone throws their arms up for a top-off and applauds a Perfect.
	if t in [ScoreTiers.SUPER_PERFECT, ScoreTiers.PERFECT]:
		_play("applause")
	for r in regulars:
		if t == ScoreTiers.SUPER_PERFECT:
			r.cheer = 1.3
		elif t == ScoreTiers.PERFECT:
			r.clap = 1.3
	if t == ScoreTiers.MISS:
		say(QUIPS.spill)
		regulars[quip_who].cheer = 0.0
	_burst(car, t)


## The day's numbers for the report (GOD PUMP plan): grades, cars, accuracy, loot.
var day_stats := {}


func reset_day_stats() -> void:
	day_stats = {"tiers": {ScoreTiers.SUPER_PERFECT: 0, ScoreTiers.PERFECT: 0, ScoreTiers.GOOD: 0,
		ScoreTiers.OK: 0, ScoreTiers.MISS: 0, ScoreTiers.UNSERVED: 0}, "cars": 0, "accuracy_sum": 0.0, "xp": 0,
		"litres": 0.0, "combo_points": 0, "rep": 0.0}


## Counts one car for the day. `combo_paid`: the combo multiplier a hand-poured Good-or-better fill was
## paid at (0 otherwise), summed into the day's combo points.
func _count(car: ProtoCar, t: String, combo_paid := 0) -> void:
	if day_stats.is_empty():
		reset_day_stats()
	day_stats.tiers[t] += 1
	day_stats.rep += GodData.REPUTATION.get(t, 0.0) * GodData.CAR_TYPES.get(car.type_id, {}).get("rep_mult", 1.0)
	if t == ScoreTiers.UNSERVED:
		return  # left without its fill: not a car fueled, not a pour to judge, no XP
	day_stats.cars += 1
	day_stats.accuracy_sum += car.accuracy()
	day_stats.litres += minf(car.amount, car.target) / economy.price_per_liter
	day_stats.combo_points += combo_paid
	day_stats.xp = xp_formula(day_stats.litres, day_stats.combo_points, day_accuracy())


## Round 10 (playtest 11): a day's XP = litres put in cars × the sum of the day's chains × accuracy. A
## chain's value is the sum of the multipliers it paid (x1 + x2 + x3 + x4 = 10), so one chain of 6 (20)
## beats three chains of 2 (9): it pays to keep chaining. The chains' sum is the day's combo points.
static func xp_formula(litres: float, combo_points: int, accuracy: float) -> int:
	return int(round(litres * combo_points * accuracy))


func day_accuracy() -> float:
	return day_stats.accuracy_sum / day_stats.cars if not day_stats.is_empty() and day_stats.cars > 0 else 0.0


## The regulars react to something (`pool` was what they used to say). Playtest 9: no more speech
## bubbles over the pour; one of them hops instead.
func say(_pool: Array) -> void:
	if regulars.is_empty() or chatting():
		return  # they're busy with a visitor
	var out_here := range(regulars.size()).filter(func(i: int) -> bool: return regulars[i].state != "inside")
	quip_who = out_here[rng.randi() % out_here.size()] if not out_here.is_empty() else 0
	regulars[quip_who].cheer = maxf(regulars[quip_who].cheer, 0.9)


## How far through today's opening hours the clock is (0 at opening, 1 at closing): the day bar.
func day_progress() -> float:
	return clampf(round_t / round_seconds, 0.0, 1.0)


## The time on the store's clock: 7 h at opening, the closing hour at the end (13 h, later with the
## HEURES branch). A game hour is always GodData.HOUR_SECONDS.
func hour_now() -> float:
	return lerpf(OPEN_HOUR, mods.get("close_hour", CLOSE_HOUR), clampf(round_t / round_seconds, 0.0, 1.0))


func is_open() -> bool:
	return not round_over


func end_round() -> void:
	if _cash_in > 0.0:
		return  # already closing
	_release_streams()
	pouring = false
	if _glug:
		_glug.stop()
	round_over = true
	sign_flip = 1.0  # OUVERT -> FERMÉ
	for car in cars:
		if car.customer and car.accepts_fuel() and car.fill() >= ProtoCar.LEAVE_AT:
			_settle(car)  # 80% or more: settles as usual
			continue
		if car.customer and car.accepts_fuel():
			_count(car, ScoreTiers.UNSERVED)  # still under 80% at closing
			var partial: float = minf(car.amount, car.target) * car.pay_share * mods.get("sale_mult", 1.0)  # they pay for what they got, no tip
			round_earned += partial
			round_sales += partial
			cash += partial
			if partial > 0.0:
				drop_cash(car.position, partial, 0.0)
			car.leave(self)
	for m in money:  # playtest 12: closing pays everything, visibly: every coin flies to the tray now
		if m.state != "fly":
			m.from = scr(m.pos) + Vector2(0, -m.get("z", 0.0))
			m.state = "fly"
			m.t = minf(m.t, 0.0)
			m.screen = true
	banner = {"open": false, "t": 0.0}  # the sign flips to FERMÉ
	_reported = false
	_cash_in = cash_in_time
	if _cash_in <= 0.0:
		_finish_day()


## The stacks are in the register: the day is over for GodGame.
## The chain breaks: its value flies from the pill to today's total, the pill shatters.
func _break_chain() -> void:
	var value := 0
	for v in chain:
		value += v
	if chain.size() >= 2:
		_chain_fly = {"value": value, "t": 0.0}
		_combo_break = 1.0
		_shake = maxf(_shake, 0.3)
	chain.clear()


func _finish_day() -> void:
	_cash_in = 0.0
	for v in stacks:
		stacks[v] = 0
	money.clear()
	shown_cash = cash
	_play("cash")
	if not _reported:
		_report_now()


## The day is over for GodGame: the report opens (the coins may still be pouring into the register).
func _report_now() -> void:
	_reported = true
	if managed:
		day_over.emit(day_report())


## Where the closing stands: 0 while open, rising to 1 as the stacks reach the register.
func cash_in_progress() -> float:
	return 1.0 - _cash_in / cash_in_time if _cash_in > 0.0 and cash_in_time > 0.0 else 0.0


## Opens a day for GodGame: today's mods, the gas in the station's tank, the day number and the car
## types that can show up. The clock limits the day (7 h to the closing hour); the tank can end it early.
func start_day(m: Dictionary, tank_dollars: float, day_n: int, pool: Array) -> void:
	banner = {"open": true, "t": 0.0}  # a big OUVERT swings in
	mods = m.duplicate()
	car_pool = pool
	day_num = day_n
	flow_rate = 4.0 * mods.flow_mult
	round_seconds = (mods.close_hour - GodData.OPEN_HOUR) * GodData.HOUR_SECONDS
	customer_chance = mods.customer_chance
	combo.max_multiplier = int(mods.combo_max)
	next_round()
	round_num = day_n
	tank = tank_dollars
	_first_car_done = false
	_cars_today = 0
	_saves_left = int(mods.overfill_saves)
	_alarm_said = false
	visitor_car = null
	chat_line = {}
	chat_log.clear()
	_chat = {}
	_visit_t = 0.0
	_visit_done = false
	_tube_cd = 3.0
	_vacuum_cd = VACUUM_EVERY
	vacuumed = 0.0
	vacuum_slurp = {}
	_herd_cd = HERD_EVERY
	herd_t = 0.0
	tube_gas = 0.0
	tube_grabs = 0
	_spits.clear()
	var hockey_every := int(mods.get("hockey_every", 0))
	hockey_night = hockey_every > 0 and day_n % hockey_every == 0
	if hockey_night:  # Soirée du hockey: the whole town drives by
		mods.queue = int(mods.queue) + 3
		customer_chance = minf(customer_chance + 0.3, 0.95)
		_floaters.append({"text": "SOIRÉE DU HOCKEY!", "pos": Vector2(WIDTH * 0.5, 150), "life": 3.0, "color": Color(0.95, 0.3, 0.3), "size": 34})
		say(QUIPS.hockey)
	_best_combo = 1
	chain.clear()
	_chain_fly = {}
	rival_cars = 0
	fines = 0.0
	stolen = 0.0
	applause = 0
	for car in cars.duplicate():
		cars.erase(car)
		car.queue_free()
	for i in int(mods.queue):  # cars already waiting when you open (marketing)
		var car := park_customer(0.0, random_lot_point())
		car.set_type(_pick_type(true), rng)
		car.patience = 24.0 * mods.patience_mult * car.patience_k
	drones.clear()
	for i in int(mods.drones):
		drones.append({"pos": Vector2(WIDTH * 0.5 + i * 40, 140), "car": null, "state": "idle", "goal": 0.0})


## Today's report for GodGame and the end-of-day screen.
func day_report() -> Dictionary:
	if day_stats.is_empty():
		reset_day_stats()
	return {"day": day_num, "loot": round_earned - fines, "sales": round_sales, "tips": round_tips,
		"tank_left": tank, "xp": day_stats.xp, "cars": day_stats.cars, "tiers": day_stats.tiers.duplicate(),
		"accuracy": day_accuracy(), "best_combo": _best_combo, "wasted": round_wasted, "fines": fines,
		"stolen": stolen, "out_of_gas": tank <= 0.0001, "hockey": hockey_night,
		"tube_gas": tube_gas, "tube_grabs": tube_grabs, "litres": day_stats.litres,
		"combo_points": day_stats.combo_points, "drone_gas": drone_gas,
		"chat": chat_log.duplicate(), "rep": day_stats.rep, "rival_cars": rival_cars}


## A car type for a new car, weighted; troublemakers ramp in over the first days.
func _pick_type(customers_only := false) -> String:
	var total := 0.0
	var weights := {}
	for id in car_pool:
		var t: Dictionary = GodData.CAR_TYPES[id]
		if customers_only and not t.get("customer", true):
			continue
		var w: float = t.weight
		if t.has("role") and t.role != "clumsy":
			w *= clampf(day_num / 6.0, 0.25, 1.0)
		weights[id] = w
		total += w
	var pick := rng.randf() * total
	for id in weights:
		pick -= weights[id]
		if pick <= 0.0:
			return id
	return "sedan"


func next_round() -> void:
	round_num += 1
	round_t = 0.0
	round_over = false
	round_earned = 0.0
	round_wasted = 0.0
	round_poured = 0.0
	round_tips = 0.0
	tip_jar = 0.0
	round_sales = 0.0
	for v in stacks:
		stacks[v] = 0
	_cash_in = 0.0
	drone_gas = 0.0
	puddles.clear()  # the lot is hosed down between rounds
	sign_flip = 1.0  # FERMÉ -> OUVERT
	_spill_quipped = 0.0
	reset_day_stats()
	tank = tank_size
	combo.reset()


func round_fuel_cost() -> float:
	return economy.refill_cost(round_poured / economy.price_per_liter)


# --- Effects ------------------------------------------------------------------------------------

func _spill(at: Vector2, dollars: float) -> void:
	for p in puddles:
		if p.pos.distance_to(at) < p.r * 0.8:
			p.gas = p.get("gas", 0.0) + dollars
			p.r = minf(p.r + dollars * 9.0, 46.0)
			p.life = 9.0
			return
	puddles.append({"pos": at + Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3)), "r": 7.0, "life": 9.0, "gas": dollars})


func _burst(car: ProtoCar, t: String) -> void:
	var col: Color = TIER_COLORS[t]
	var n := 26 if t == ScoreTiers.SUPER_PERFECT else (16 if t == ScoreTiers.PERFECT else 8)
	for i in n:
		var a := rng.randf() * TAU
		_bits.append({"pos": scr(car.position), "vel": Vector2.from_angle(a) * rng.randf_range(80, 260),
			"life": rng.randf_range(0.4, 0.8), "color": col, "size": rng.randf_range(2.5, 5.0)})
	if t == ScoreTiers.SUPER_PERFECT or t == ScoreTiers.PERFECT:
		for i in (10 if t == ScoreTiers.SUPER_PERFECT else 5):
			_bits.append({"pos": scr(car.position) + Vector2(rng.randf_range(-30, 30), rng.randf_range(-30, 10)),
				"vel": Vector2(rng.randf_range(-40, 40), rng.randf_range(-160, -60)), "life": rng.randf_range(0.6, 1.0),
				"color": Color.WHITE, "size": 0.0, "sparkle": true})
	if t == ScoreTiers.MISS:  # overflow: gas sprays out of the tank
		for i in 18:
			_bits.append({"pos": scr(car.position), "vel": Vector2(rng.randf_range(-120, 120), rng.randf_range(-260, -80)),
				"life": 0.7, "color": GAS, "size": 4.0})
		_spill(car.position + Vector2(rng.randf_range(-20, 20), 20), 0.8)
	drop_cash(car.position, car.paid - car.tip, car.tip)
	# Say exactly what was achieved: how full, what grade, what the tip was.
	var top := scr(car.position) + Vector2(0, -64)
	_floaters.append({"text": "%d%%" % int(car.fill() * 100.0), "pos": top, "life": 1.4, "color": col, "size": 34})
	_floaters.append({"text": tr(ProtoCar.grade_name(t)), "pos": top + Vector2(0, 26), "life": 1.4, "color": col,
		"size": 24 if t == ScoreTiers.SUPER_PERFECT else 18})
	if car.tip >= 0.01:
		_floaters.append({"text": "+$%.2f TIP" % car.tip, "pos": top + Vector2(0, 48), "life": 1.4,
			"color": Color(1.0, 0.85, 0.3), "size": 18})
	_shake = maxf(_shake, 0.8 if t == ScoreTiers.SUPER_PERFECT else (0.6 if t == ScoreTiers.MISS else 0.2))
	_play("sfx_" + t.to_lower().replace(" ", "_"))
	_play("pop")


const MONEY_REST := 3.45  # coins lie on the lot a while before they're collected (god-pump playtest 5, back in playtest 10)
const MONEY_FLY := 0.55


## The coins for an amount, biggest first: $27 is a red $20, a green $5 and two blue $1.
static func coins_for(dollars: float) -> Array:
	var left := int(round(dollars))
	var out := []
	for v in COIN_VALUES:
		while left >= v:
			out.append(v)
			left -= v
	return out


## The car pays: its sale and tip spill out as coins that bounce, lie on the lot (under the cars) a few
## seconds, then fly to the tray. (`tip_coins` is kept for callers.)
func drop_cash(from: Vector2, sale: float, tip: float, _tip_coins := 4) -> void:
	var coins := coins_for(sale + tip)
	for i in coins.size():
		money.append({"kind": "coin", "value": coins[i], "pos": from, "z": 8.0, "state": "drop", "t": -i * 0.03,
			"vel": Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(90, 200), "vz": rng.randf_range(220, 320),
			"rot": rng.randf() * TAU, "from": from})


## Where the top of a stack is in the tray now.
func stack_top(v: int) -> Vector2:
	var i := COIN_VALUES.size() - 1 - COIN_VALUES.find(v)  # $1 at the left, $50 at the right
	return TRAY_AT + Vector2(22 + i * 40, -6 - mini(stacks[v], 24) * 3)


func _step_money(dt: float) -> void:
	for m in money.duplicate():
		m.t += dt
		if m.t < 0.0:
			continue
		match m.state:
			"drop":
				m.pos += m.vel * dt
				m.vel *= 1.0 - 1.6 * dt
				m.vz -= 900.0 * dt
				m.z += m.vz * dt
				m.rot += dt * 15.0
				if m.z <= 0.0:
					m.z = 0.0
					if m.vz < -80.0:
						m.vz = -m.vz * 0.45  # coins bounce
						_play("counter_%d" % (rng.randi() % 3 + 1))
					else:
						m.state = "rest"
						m.t = 0.0
			"rest":
				if m.t >= MONEY_REST:
					m.state = "fly"
					m.t = 0.0
					m.from = scr(m.pos)  # from here on it travels on the screen, over everything
					m.screen = true
			"fly":
				var k: float = clampf(m.t / MONEY_FLY, 0.0, 1.0)
				var j := k * k  # pulled in, faster and faster
				var to := stack_top(m.value)
				var mid: Vector2 = (m.from + to) * 0.5 + Vector2(0, -90)
				m.pos = m.from.lerp(mid, j).lerp(mid.lerp(to, j), j)
				m.rot += dt * 9.0
				if k >= 1.0:
					stacks[m.value] += 1
					shown_cash += m.value
					money.erase(m)
					_play("counter_%d" % (rng.randi() % 3 + 1))
	if money.is_empty():
		shown_cash = cash


## The coins still on the ground (falling, bouncing or lying there): the views draw them under the cars.
func coins_on_lot() -> Array:
	return money.filter(func(m: Dictionary) -> bool: return m.state != "fly" and m.t >= 0.0)


## What the coins in the tray are worth.
func stacks_value() -> int:
	var total := 0
	for v in stacks:
		total += v * stacks[v]
	return total


## A customer left waiting too long drives off unserved (they pay for what they got).
func _step_patience(dt: float) -> void:
	for car in cars:
		if not car.customer or car.phase != ProtoCar.Phase.WANDER or car in stream_cars:
			continue
		car.waited += dt
		if car.waited > car.patience:
			if car.fill() >= ProtoCar.LEAVE_AT:
				_settle(car)
				continue
			if int(mods.get("clamp_wait", 0)) > 0 and not car.clamped:  # Sabot de Denver II: not so fast
				car.clamped = true
				car.waited = 0.0
				car.patience *= 0.6
				_floaters.append({"text": "SABOT!", "pos": scr(car.position) + Vector2(0, -60), "life": 1.2, "color": Color(1, 0.85, 0.2), "size": 22})
				continue
			_count(car, ScoreTiers.UNSERVED)
			var partial: float = minf(car.amount, car.target) * car.pay_share * mods.get("sale_mult", 1.0)
			round_earned += partial
			round_sales += partial
			cash += partial
			if partial > 0.0:
				drop_cash(car.position, partial, 0.0)
			_floaters.append({"text": "TROP LONG!", "pos": scr(car.position) + Vector2(0, -60), "life": 1.4, "color": Color(1, 0.4, 0.3), "size": 20})
			_play("horn")
			combo.register(ScoreTiers.MISS)
			car.leave(self)


## The troublemakers and helpers (GodData.CAR_TYPES roles).
func _step_roles(dt: float) -> void:
	for car in cars:
		if car.phase != ProtoCar.Phase.WANDER:
			continue
		car.role_t += dt
		match car.role:
			"sweeper":  # cleans the puddles it drives over, then leaves
				for p in puddles.duplicate():
					if p.pos.distance_to(car.position) < 46.0:
						puddles.erase(p)
				if car.role_t > 14.0:
					car.leave(self)
			"electric":  # wanders a while, then leaves; it never wanted gas
				if car.role_t > 10.0:
					car.leave(self)
			"thief":  # siphons gas from a customer, then flees with it
				if car.clamped:  # clamped: waits for the tow truck
					car.clamp_t += dt
					if car.clamp_t > 3.5:
						car.leave(self)
					continue
				if not car.victim or not is_instance_valid(car.victim) or not car.victim.accepts_fuel():
					car.victim = nearest_customer(car.position, 2000.0, car)
				if car.victim:
					car.moving = car.position.distance_to(car.victim.position) > 60.0
					if car.moving:
						car.heading = rotate_toward(car.heading, (car.victim.position - car.position).angle(), 3.0 * dt)
						car.position += Vector2.from_angle(car.heading) * 120.0 * dt
					else:
						var take := minf(3.0 * dt, car.victim.amount)
						if take > 0.0 and car.stolen == 0.0:
							_floaters.append({"text": "VOLEUR!", "pos": scr(car.position) + Vector2(0, -60), "life": 1.4, "color": Color(1, 0.3, 0.3), "size": 22})
						car.victim.amount -= take
						car.stolen += take
						stolen += take
				if car.role_t > 7.0 or car.stolen > 12.0:
					if int(mods.get("clamp_thief", 0)) > 0:
						_clamp_thief(car)
					else:
						car.leave(self)
			"bumper":  # the bumper car: knocks the cars it hits out of the way (and out of your ring)
				car.bump_cool = maxf(car.bump_cool - dt, 0.0)
				if car.bump_cool <= 0.0:
					for other in cars:
						if other != car and other.phase == ProtoCar.Phase.WANDER and other.position.distance_to(car.position) < 50.0:
							var away := (other.position - car.position).normalized()
							other.position = (other.position + away * 46.0).clamp(LOT.position + Vector2(24, 20), LOT.end - Vector2(24, 20))
							car.heading = (-away).angle() + rng.randf_range(-0.6, 0.6)
							_floaters.append({"text": "BOING!", "pos": scr(other.position) + Vector2(0, -60), "life": 1.0, "color": Color(0.55, 0.85, 1.0), "size": 22})
							car.bump_cool = 0.8
							break
			"clumsy":  # bumps into cars, who spill some of their gas
				car.bump_cool = maxf(car.bump_cool - dt, 0.0)
				if car.bump_cool <= 0.0:
					for other in cars:
						if other != car and other.customer and other.accepts_fuel() and other.amount > 1.0 \
								and other.position.distance_to(car.position) < 52.0:
							var lost: float = other.amount * 0.25
							other.amount -= lost
							_waste(lost, other.position + Vector2(0, 16))
							_floaters.append({"text": "BANG!", "pos": scr(other.position) + Vector2(0, -60), "life": 1.2, "color": Color(1, 0.7, 0.3), "size": 24})
							car.bump_cool = 3.0
							break


## Drone nozzles: each flies to a customer nobody is pouring on, fills it to a good-but-not-perfect
## level on its own (slower than you, half the tip, no combo), and moves on. The automation.
func _step_drones(dt: float) -> void:
	for d in drones:
		var car: ProtoCar = d.car
		if car and (not is_instance_valid(car) or not car.accepts_fuel()):
			car = null
			d.car = null
		if not car:
			for c in cars:
				if c.customer and c.accepts_fuel() and not c.drone_target and not c in stream_cars and c.amount < c.target * 0.8:
					car = c
					c.drone_target = true
					d.car = c
					d.goal = rng.randf_range(0.86, 0.995)
					break
			if not car:
				continue
		var burn := minf(DRONE_BURN * dt, tank)  # a drone in the air burns gas, flying or pouring
		tank -= burn
		round_poured += burn
		drone_gas += burn
		var gap: Vector2 = car.position - d.pos
		if gap.length() > 8.0:
			d.pos += gap.normalized() * minf(DRONE_SPEED * dt, gap.length())
			d.state = "flying"
			continue
		if car in stream_cars:
			d.state = "waiting"  # you're pouring on it: the drone hovers, and resumes when you let go
			continue
		d.state = "pouring"
		var dollars := minf(DRONE_FLOW * dt * car.fill_speed, tank)
		tank -= dollars
		round_poured += dollars
		car.receive(dollars)
		car.drone_touched = true
		if car.fill() >= d.goal or car.amount >= car.target:
			car.by_drone = true
			_settle(car)
			d.car = null
			d.state = "idle"
		if tank <= 0.0001:
			tank = 0.0
			end_round()
			return


func _step_fx(dt: float) -> void:
	_step_money(dt)
	for b in _bits.duplicate():
		b.life -= dt
		b.pos += b.vel * dt
		b.vel.y += 420.0 * dt
		if b.life <= 0.0:
			_bits.erase(b)
	for f in _floaters.duplicate():
		f.life -= dt
		f.pos.y -= 40.0 * dt
		if f.life <= 0.0:
			_floaters.erase(f)
	# Puddles stay all round (cleared by next_round).
	neon_flash = maxf(neon_flash - dt, 0.0)
	sign_flip = maxf(sign_flip - dt * 2.0, 0.0)
	_kick = maxf(_kick - dt * 6.0, 0.0)
	quip_t = maxf(quip_t - dt, 0.0)
	crew.step(dt, rng, not round_over)
	if not round_over and not regulars.is_empty():
		_next_idle_quip -= dt
		if _next_idle_quip <= 0.0 and quip_t <= 0.0 and not chatting():
			say(QUIPS.idle)
			regulars[quip_who].cheer = 0.0
			_next_idle_quip = rng.randf_range(7.0, 11.0)
		if round_wasted - _spill_quipped >= 4.0:
			_spill_quipped = round_wasted
			say(QUIPS.spill)
			regulars[quip_who].cheer = 0.0
	_shake = maxf(_shake - dt * 2.5, 0.0)
	position = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * _shake * 8.0


func _play(id: String) -> void:
	if _sfx.has(id):
		_sfx[id].play()


# --- Drawing ------------------------------------------------------------------------------------

## The table: dark ground, the road along the top, the lot, the gold puddles.
func _draw() -> void:
	if view == "cartoon":
		_draw_cartoon()
		return
	if view != "flat":
		return  # a scene view draws the world
	draw_rect(Rect2(-20, -20, WIDTH + 40, HEIGHT + 40), Color(0.16, 0.13, 0.10))
	if _tex.has("dirt"):
		_tile("dirt", Rect2(-20, -20, WIDTH + 40, HEIGHT + 40))
	draw_rect(Rect2(-20, ROAD_Y - 34, WIDTH + 40, 68), Color(0.12, 0.12, 0.13))
	if _tex.has("road"):
		_tile("road", Rect2(-20, ROAD_Y - 32, WIDTH + 40, 64))
	var x := -20.0 + fmod(-_t * 40.0, 60.0)
	while x < WIDTH:
		draw_rect(Rect2(x, ROAD_Y - 2, 30, 4), Color(0.85, 0.8, 0.5, 0.6))
		x += 60.0
	var lot := StyleBoxFlat.new()
	lot.bg_color = Color(0.21, 0.20, 0.20)
	lot.set_corner_radius_all(14)
	draw_style_box(lot, LOT)
	if _tex.has("asphalt"):
		_tile("asphalt", LOT.grow(-6))
	draw_rect(Rect2(ENTRANCE.x - 40, ROAD_Y + 30, 80, LOT.position.y - ROAD_Y - 20), Color(0.21, 0.20, 0.20))
	draw_rect(Rect2(EXIT.x - 40, ROAD_Y + 30, 80, LOT.position.y - ROAD_Y - 20), Color(0.21, 0.20, 0.20))
	for i in 9:
		var lx := LOT.position.x + 70 + i * 98
		draw_rect(Rect2(lx, LOT.end.y - 70, 3, 60), Color(1, 1, 1, 0.12))
	for p in puddles:
		var a := clampf(p.life / 3.0, 0.0, 1.0)
		var size_id := "puddle_s" if p.r < 13.0 else ("puddle_m" if p.r < 28.0 else "puddle_l")
		if _tex.has(size_id):
			var tex: Texture2D = _tex[size_id]
			var k: float = 2.0 * clampf(p.r / (tex.get_width() * 0.9), 0.6, 1.6)
			draw_set_transform(p.pos, 0.0, Vector2(k, k))
			draw_texture(tex, -tex.get_size() * 0.5, Color(1, 1, 1, a))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			continue
		draw_set_transform(p.pos, 0.0, Vector2(1.0, 0.62))
		draw_circle(Vector2.ZERO, p.r, Color(GAS.darkened(0.25), 0.75 * a))
		draw_circle(Vector2(-p.r * 0.15, -p.r * 0.2), p.r * 0.7, Color(GAS, 0.8 * a))
		draw_circle(Vector2(-p.r * 0.35, -p.r * 0.35), p.r * 0.22, Color(1, 1, 0.85, 0.7 * a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Chez Gaétan, across the road (round 10 B): his apron and two pumps.
	draw_rect(Rect2(RIVAL_AT.x - 110, -20, 220, 64), Color(0.2, 0.19, 0.19))
	for p in RIVAL_PUMPS:
		draw_rect(Rect2(p + Vector2(-8, -26), Vector2(16, 12)), Color(0.75, 0.16, 0.14))
	GodUI.text(self, Vector2(RIVAL_AT.x, -26), "CHEZ GAÉTAN", 14, Color(0.95, 0.9, 0.8), true, 4)
	for m in coins_on_lot():  # drawn before the cars (child nodes), so the cars stay in front
		draw_circle(m.pos + Vector2(0, 3), 7.0, Color(0, 0, 0, 0.25))
		draw_coin(self, m.pos + Vector2(0, -m.z), m.value, absf(cos(m.rot)), 8.0)


## Round 10 C: the world in the cartoon look (CartoonArt), under the overlay: grass, the avenue, Chez
## Gaétan, the lot, puddles and coins, the gaz bar, then everything standing on the ground sorted by depth
## (cars, the regulars, the upgrades' props), so nearer things cover further ones.
func _draw_cartoon() -> void:
	draw_rect(Rect2(-20, -20, WIDTH + 40, HEIGHT + 40), Color(0.56, 0.82, 0.42))
	for b in [Rect2(10, 560, 180, 60), Rect2(420, 600, 280, 50), Rect2(1040, 200, 100, 180), Rect2(20, 300, 80, 140), Rect2(820, 4, 220, 36)]:
		draw_set_transform(b.get_center(), 0.0, b.size / 100.0)
		draw_circle(Vector2.ZERO, 50.0, Color(0.48, 0.75, 0.34))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var rt := scr(Vector2(0, ROAD_Y - 34)).y
	var rb := scr(Vector2(0, ROAD_Y + 34)).y
	draw_rect(Rect2(-20, rt - 8, WIDTH + 40, 8), Color(0.94, 0.89, 0.77))
	draw_rect(Rect2(-20, rb, WIDTH + 40, 8), Color(0.94, 0.89, 0.77))
	draw_rect(Rect2(-20, rt, WIDTH + 40, rb - rt), Color(0.27, 0.29, 0.35))
	var x := -20.0
	while x < WIDTH:
		draw_rect(Rect2(x, (rt + rb) * 0.5 - 3, 40, 6), Color(1.0, 0.82, 0.25))
		x += 90.0
	var pumps := RIVAL_PUMPS.map(func(p: Vector2) -> Vector2: return scr(p))
	CartoonArt.rival(self, scr(Vector2(RIVAL_AT.x, 0)), pumps, CARTOON_K)
	var on_lot: Array[ProtoCar] = []
	for car in cars:  # the avenue and Gaétan's first: the store and the lot stand in front of them
		if car.phase in [ProtoCar.Phase.ROAD, ProtoCar.Phase.RIVAL] or (car.phase == ProtoCar.Phase.LEAVING and car.position.y < ROAD_Y + 30):
			_cartoon_car(car)
		elif car.phase != ProtoCar.Phase.GRABBED:
			on_lot.append(car)
	var lot := Rect2(scr(LOT.position), LOT.size * CARTOON_K)
	draw_rect(Rect2(scr(Vector2(ENTRANCE.x - 40, ROAD_Y + 30)), Vector2(80, LOT.position.y - ROAD_Y) * CARTOON_K), Color(0.36, 0.38, 0.45))
	draw_rect(Rect2(scr(Vector2(EXIT.x - 40, ROAD_Y + 30)), Vector2(80, LOT.position.y - ROAD_Y) * CARTOON_K), Color(0.36, 0.38, 0.45))
	CartoonArt.box(self, lot, Color(0.36, 0.38, 0.45), 22.0, 5.0)
	for i in 9:
		var lx := LOT.position.x + 70 + i * 98
		draw_line(scr(Vector2(lx, LOT.end.y - 70)), scr(Vector2(lx, LOT.end.y - 12)), Color(0.96, 0.95, 0.9, 0.8), 5.0, true)
	for p in puddles:
		var a := clampf(p.life / 3.0, 0.0, 1.0)
		var c := scr(p.pos)
		draw_set_transform(c, 0.0, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, p.r + 3.0, Color(CartoonArt.INK, a))
		draw_circle(Vector2.ZERO, p.r, Color(GAS, a))
		draw_circle(Vector2(-p.r * 0.3, -p.r * 0.3), p.r * 0.35, Color(1.0, 0.97, 0.7, a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for m in coins_on_lot():
		draw_circle(scr(m.pos) + Vector2(0, 4), 8.0, Color(0, 0, 0, 0.2))
		CartoonArt.coin(self, scr(m.pos) + Vector2(0, -m.z), COIN_COLORS[m.value], absf(cos(m.rot)), 8.0)
	var store := Rect2(scr(Vector2(16, 100)), Vector2(262, 66) * CARTOON_K)
	CartoonArt.store(self, store, is_open(), neon_flash, _t)
	# Everything standing on the ground, back to front.
	var things := []
	for car in on_lot:
		things.append({"y": car.position.y, "car": car})
	for r in regulars:
		if RegularsCrew.pose(r) != "":
			things.append({"y": r.pos.y, "who": r})
	things.append({"y": RegularsCrew.BENCH.y - 1.0, "bench": true})
	for id in HD2DView.PROPS.keys() + HD2DView.LOT_PROPS.keys():
		if owns_upgrade(id):
			var spot: Vector2 = (HD2DView.PROPS[id] if HD2DView.PROPS.has(id) else HD2DView.LOT_PROPS[id])[1]
			things.append({"y": spot.y, "prop": id, "at": spot})
	things.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.y < b.y)
	for th in things:
		if th.has("car"):
			_cartoon_car(th.car)
		elif th.has("who"):
			var r: Dictionary = th.who
			var hop := 7.0 * absf(sin(r.cheer * 12.0)) if r.cheer > 0.0 else 0.0
			CartoonArt.person(self, scr(r.pos) + Vector2(0, -hop), r.name, RegularsCrew.pose(r), _t + r.bob, r.flip)
		elif th.has("bench"):
			var bp := scr(RegularsCrew.BENCH + Vector2(80, 4))
			CartoonArt.box(self, Rect2(bp + Vector2(-80, -6), Vector2(160, 10)), Color(0.71, 0.4, 0.23), 4.0, 3.0)
		else:
			_prop_t[th.prop] = _prop_t.get(th.prop, 0.0)
			CartoonArt.prop(self, th.prop, scr(th.at), _t, clampf(_prop_t[th.prop] / 0.9, 0.0, 1.0))
	if int(mods.get("tube_man", 0)) > 0 or perks.get("tube_man", 0) > 0:
		var holding := cars.any(func(c: ProtoCar) -> bool: return c.phase == ProtoCar.Phase.GRABBED)
		var base := scr(TUBE_AT)
		var head := base + Vector2(sin(_t * 5.0) * 16.0 * (0.0 if holding else 1.0), -150)
		CartoonArt.tube_man(self, base, head, Color(1.0, 0.3, 0.25), 1.0 if holding else 0.0, _t)
	for car in cars:  # held up high by the tube man
		if car.phase == ProtoCar.Phase.GRABBED:
			_cartoon_car(car)


## One car in the cartoon look, with its animation (lift, spin, swelling as it fills).
func _cartoon_car(car: ProtoCar) -> void:
	var anim := car.anim_offsets()
	var col: Color = CartoonArt.CARS[car.type_id].get("paint", STACK_PAINTS.get(car.stack, CartoonArt.PAINTS[car.look % CartoonArt.PAINTS.size()])) if CartoonArt.CARS.has(car.type_id) else STACK_PAINTS.get(car.stack, CartoonArt.PAINTS[car.look % CartoonArt.PAINTS.size()])
	if car.visitor:
		col = STACK_PAINTS.get(car.stack, col)
	CartoonArt.car(self, scr(car.position), car.heading + anim.spin, car.type_id, col, anim.squash, anim.lift, _t, CARTOON_K)


## Tiles a 32 px texture over `r` at 2x.
func _tile(id: String, r: Rect2) -> void:
	draw_set_transform(r.position, 0.0, Vector2(2, 2))
	draw_texture_rect(_tex[id], Rect2(Vector2.ZERO, r.size * 0.5), true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Above the cars: the stream, the god nozzle, coins in flight, bursts, words and the HUD.
func _draw_overlay() -> void:
	var o := _overlay
	var lands: Array[Vector2] = []  # one stream per car in the ring, landing on its roof
	for c in stream_cars:
		lands.append(car_top(c) if view != "flat" else c.position)
	if lands.is_empty():
		lands.append(scr(_aim))
	var tip := scr(_nozzle) + NOZZLE_RAISE + Vector2(-4, 6) * _kick
	if view != "flat":  # gauges float over the cars
		for car in cars:
			if car.customer and car.accepts_fuel():
				if view == "cartoon":
					CartoonArt.gauge(o, car_top(car) + Vector2(0, -30), car.fill(), car.target)
				else:
					car.draw_meter_at(o, car_top(car) + Vector2(0, -46))
	_draw_road_gauges(o)
	_draw_badges(o)
	_draw_vacuum(o)
	_draw_dog(o)
	if not hd and view != "cartoon":
		_draw_tube_man_2d(o)
	_draw_drones(o)
	draw_shadow_ring(o)
	_draw_pump(o, tip)
	if pouring:
		for land in lands:
			var prev := tip
			for i in range(1, 11):
				var k := i / 10.0
				var p := tip.lerp(land, k) + Vector2(sin(_t * 30.0 + i) * 2.0 * k, 0)
				if view == "cartoon":  # a chunky outlined stream
					o.draw_line(prev, p, CartoonArt.INK, 12.0 - k * 3.0, true)
				o.draw_line(prev, p, GAS, (8.0 if view == "cartoon" else 6.0) - k * 2.0, true)
				prev = p
			for i in 4:
				var k := fmod(_t * 3.0 + i * 0.25, 1.0)
				o.draw_circle(tip.lerp(land, k) + Vector2(sin(_t * 20.0 + i * 2.0) * 3.0, 0), 3.0, GAS.lightened(0.2))
			o.draw_circle(land, 7.0 + sin(_t * 25.0) * 1.5, Color(GAS, 0.6))
	_draw_nozzle(o, tip)
	for b in _bits:
		if b.get("sparkle", false) and _tex.has("sparkle"):
			o.draw_set_transform(b.pos, _t * 3.0, Vector2(2, 2))
			o.draw_texture(_tex["sparkle"], Vector2(-3.5, -3.5), Color(1, 1, 1, clampf(b.life * 2.0, 0.0, 1.0)))
			o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			continue
		o.draw_circle(b.pos, b.size, Color(b.color, clampf(b.life * 2.0, 0.0, 1.0)))
	var font := ThemeDB.fallback_font
	for f in _floaters:
		var w := font.get_string_size(f.text, HORIZONTAL_ALIGNMENT_LEFT, -1, f.size).x
		o.draw_string_outline(font, f.pos - Vector2(w * 0.5, 0), f.text, HORIZONTAL_ALIGNMENT_LEFT, -1, f.size, 9 if view == "cartoon" else 6, Color(CartoonArt.INK, clampf(f.life * 2.0, 0.0, 1.0)) if view == "cartoon" else Color(0, 0, 0, 0.8))
		o.draw_string(font, f.pos - Vector2(w * 0.5, 0), f.text, HORIZONTAL_ALIGNMENT_LEFT, -1, f.size, Color(f.color, clampf(f.life * 2.0, 0.0, 1.0)))
	_draw_spits(o)
	_draw_hud(o, font)


## The tube man in the flat and pixel views (the HD-2D view stands him up in 3D).
func _draw_tube_man_2d(o: Node2D) -> void:
	if int(mods.get("tube_man", 0)) <= 0:
		return
	var strip := anim_tex("tube_man")
	if not strip:
		return
	var fw := strip.get_width() / 8.0
	var at := scr(TUBE_AT) - Vector2(fw, strip.get_height() * 2.0) + Vector2(0, 8)
	o.draw_texture_rect_region(strip, Rect2(at, Vector2(fw, strip.get_height()) * 2.0), Rect2(fw * (int(_t * 10.0) % 8), 0, fw, strip.get_height()))


## What the tube man spits: gold blobs arcing from his mouth to the pump.
func _draw_spits(o: Node2D) -> void:
	for s in _spits:
		if s.t < 0.0:
			continue
		var k: float = clampf(s.t / 0.7, 0.0, 1.0)
		var p: Vector2 = s.from.lerp(s.to, k) + Vector2(0, -sin(k * PI) * 160.0)
		o.draw_circle(p, 7.0 - k * 2.0, GAS)
		o.draw_circle(p + Vector2(-2, -2), 2.5, GAS.lightened(0.5))


## Drone nozzles hover over the lot with a shadow beneath; when one pours, a thin gold stream.
func _draw_drones(o: Node2D) -> void:
	for i in drones.size():
		var d: Dictionary = drones[i]
		var ground := scr(d.pos)
		var air := ground + Vector2(46, -118 + sin(_t * 3.0 + i) * 4.0)  # beside and above the gauge
		o.draw_set_transform(ground, 0.0, Vector2(1.0, 0.4))
		o.draw_circle(Vector2.ZERO, 14.0, Color(0, 0, 0, 0.25))
		o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if d.state == "pouring" and d.car and is_instance_valid(d.car):
			var land: Vector2 = car_top(d.car) if view != "flat" else d.car.position
			o.draw_line(air + Vector2(0, 26), land, GAS, 3.0, true)
			o.draw_circle(land, 4.0 + sin(_t * 25.0), Color(GAS, 0.6))
		if view == "cartoon":
			CartoonArt.drone(o, air, _t + i, d.state == "pouring")
			continue
		var tex: Texture2D = _tex.get("drone_%d" % (int(_t * 20.0) % 2))
		if tex:
			o.draw_set_transform(air, 0.0, Vector2(2, 2))
			o.draw_texture(tex, -tex.get_size() * 0.5)
			o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Troublemakers wear a badge (a mask, a lightning bolt, a broom, dizzy stars); Dad wears his name.
## The Aspirateur gonflable (playtest 11: "an animation that he sucks"): a blue inflatable tube man by the
## lot's corner, drawn as a wobbly tube of segments with a face. Idle he dances. When he slurps a puddle
## he leans over it, his mouth opens wide, the puddle shrinks, and gold bulges run down his tube to the
## tank at his feet.
func _draw_vacuum(o: Node2D) -> void:
	if int(mods.get("puddle_vacuum", 0)) <= 0:
		return
	var base := scr(VACUUM_AT)
	var k := 0.0  # 0 idle .. 1 fully leaning over the puddle
	var target := base + Vector2(-40, -150)
	var slurp := not vacuum_slurp.is_empty()
	if slurp:
		var left: float = vacuum_slurp.t / VACUUM_SLURP
		k = smoothstep(1.0, 0.75, left) * smoothstep(0.0, 0.2, left)  # lean in, hold, straighten
		var puddle := scr(vacuum_slurp.pos)
		var r: float = vacuum_slurp.get("r", 20.0) * clampf((left - 0.2) / 0.6, 0.0, 1.0)
		if r > 1.0:  # the puddle shrinks as he sucks it up
			o.draw_set_transform(puddle, 0.0, Vector2(1.0, 0.45))
			o.draw_circle(Vector2.ZERO, r + 3.0, Color(0.11, 0.1, 0.17))
			o.draw_circle(Vector2.ZERO, r, GAS)
			o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		target = target.lerp(puddle + Vector2(0, -22), k * 0.75)
	var sway := Vector2(sin(_t * 5.0) * 18.0, sin(_t * 7.3) * 6.0) * (1.0 - k)
	var head := target + sway
	CartoonArt.tube_man(o, base, head, Color(0.3, 0.62, 1.0), k, _t, slurp, k)
	if slurp and k > 0.3:  # the gas going in
		var from := scr(vacuum_slurp.pos)
		for i in 6:
			var u := fmod(_t * 3.0 + i / 6.0, 1.0)
			o.draw_circle(from.lerp(head + Vector2(0, 7), u), 4.0 * (1.0 - u * 0.5), Color(GAS, 0.95))


## The Chien de berger robot: a little grey robot dog, legs going, a red eye. He waits by the door and
## runs circles round the customers when he herds them.
func _draw_dog(o: Node2D) -> void:
	if int(mods.get("herd_dog", 0)) <= 0:
		return
	var at := scr(dog_pos)
	var run := herd_t > 0.0
	var leg := sin(_t * (22.0 if run else 4.0)) * (5.0 if run else 1.0)
	var steel := Color(0.72, 0.75, 0.8)
	var dark := Color(0.1, 0.1, 0.12)
	for x in [-9.0, 9.0]:  # legs
		o.draw_line(at + Vector2(x, 2), at + Vector2(x + leg * (1 if x < 0 else -1), 12), dark, 4.0)
	o.draw_rect(Rect2(at + Vector2(-14, -8), Vector2(28, 12)), dark)
	o.draw_rect(Rect2(at + Vector2(-12, -6), Vector2(24, 8)), steel)
	o.draw_rect(Rect2(at + Vector2(10, -16), Vector2(12, 11)), dark)  # head
	o.draw_rect(Rect2(at + Vector2(12, -14), Vector2(8, 7)), steel)
	o.draw_circle(at + Vector2(18, -11), 2.0, Color(1.0, 0.2, 0.15))
	o.draw_line(at + Vector2(-14, -6), at + Vector2(-20, -14 + leg * 0.5), dark, 3.0)  # tail wags


## Round 10 batch B: a small fuel gauge over each car on the avenue that wants gas (low, red), and over
## Gaétan's customers driving away (full, green). That's all you see of his business.
func _draw_road_gauges(o: Node2D) -> void:
	for car in cars:
		var low := car.low_fuel and car.phase in [ProtoCar.Phase.ROAD, ProtoCar.Phase.RIVAL]
		var full := car.rival_full and car.phase in [ProtoCar.Phase.ROAD, ProtoCar.Phase.RIVAL]
		if not low and not full:
			continue
		var at := car_top(car) + Vector2(-14, -26)
		o.draw_rect(Rect2(at, Vector2(28, 8)), Color(0, 0, 0, 0.85))
		var k := 0.15 if low else 1.0
		o.draw_rect(Rect2(at + Vector2(2, 2), Vector2(24 * k, 4)), Color(0.95, 0.2, 0.15) if low else Color(0.35, 0.95, 0.4))
		GodUI.text(o, at + Vector2(-9, 8), "E" if low else "F", 11, Color(0.95, 0.3, 0.25) if low else Color(0.45, 1.0, 0.5), false, 3)


func _draw_badges(o: Node2D) -> void:
	for car in cars:
		if car.clamped and car.phase == ProtoCar.Phase.WANDER:  # the yellow boot on its wheel
			var clamp: Texture2D = tex("badge_clamp")
			if clamp:
				o.draw_set_transform(car_top(car) + Vector2(22, 18), 0.0, Vector2(2, 2))
				o.draw_texture(clamp, -clamp.get_size() * 0.5)
				o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if not car.accepts_fuel() or (car.role == "" and car.type_id != "papa"):
			continue
		var top := car_top(car) + Vector2(0, (-96.0 if car.customer else -22.0) + sin(_t * 4.0 + car.position.x) * 3.0)
		if car.type_id == "papa":
			GodUI.text(o, top + Vector2(0, -6), "PAPA", 22, Color(1.0, 0.85, 0.3), true, 6)
			continue
		var tex: Texture2D = _tex.get("badge_" + car.role)
		if tex:
			o.draw_set_transform(top, 0.0, Vector2(2, 2))
			o.draw_texture(tex, -tex.get_size() * 0.5)
			o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The nozzle ring (playtest 9): the area the nozzle covers, lying on the ground. Faint when empty (the
## gas would spill), gold around one car, bright and pulsing around two or more (Double jet).
func draw_shadow_ring(o: Node2D) -> void:
	var inside := cars_in_ring().size()
	var col := Color(1, 1, 1, 0.4)
	if inside >= 2 and streams() >= 2:
		col = Color(0.55, 1.0, 0.45, 0.75 + 0.2 * sin(_t * 12.0))
	elif inside >= 1:
		col = Color(1.0, 0.85, 0.3, 0.8)
	var pts := PackedVector2Array()
	for i in 33:
		pts.append(scr(_aim + Vector2.from_angle(i / 32.0 * TAU) * ring_radius()))
	o.draw_colored_polygon(pts.slice(0, 32), Color(col, col.a * 0.12))
	o.draw_polyline(pts, col, 3.0 if inside > 0 else 2.0, true)


## A giant hand holding a pump nozzle, hovering above where the stream lands.
func _draw_nozzle(o: Node2D, tip: Vector2) -> void:
	if view == "cartoon":
		CartoonArt.nozzle(o, tip, pouring, _kick)
		nozzle_bling.draw(o, tip - NOZZLE_TIP, 2.0, tex)
		return
	var id := "nozzle_squeeze" if pouring else "nozzle_idle"  # the hand squeezes the lever to pour
	if _tex.has(id):
		o.draw_set_transform(tip - NOZZLE_TIP, 0.0, Vector2(2, 2))
		o.draw_texture(_tex[id], Vector2.ZERO)
		o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		nozzle_bling.draw(o, tip - NOZZLE_TIP, 2.0, tex)
		return
	var hand := tip + Vector2(-58, -30)
	o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	o.draw_line(hand + Vector2(20, 10), tip + Vector2(-6, -6), Color(0.15, 0.15, 0.17), 12.0, true)  # spout
	o.draw_line(hand + Vector2(-30, 4), hand + Vector2(20, 10), Color(0.8, 0.12, 0.1), 16.0, true)  # red grip
	o.draw_circle(hand + Vector2(-38, 2), 22.0, Color(0.93, 0.62, 0.45))  # the hand
	o.draw_circle(hand + Vector2(-20, -10), 10.0, Color(0.93, 0.62, 0.45))
	o.draw_circle(tip, 5.0, Color(0.1, 0.1, 0.1))


## The vintage pump (bottom left) with its dial on the round's gas, shaking while it pumps, and the
## hose sagging from its side to the nozzle in your hand.
func _draw_pump(o: Node2D, tip: Vector2) -> void:
	if view == "cartoon":
		var outlet := PUMP_AT + Vector2(70, 80)
		var sag := (outlet + tip) * 0.5 + Vector2(0, 150)
		var prev := outlet
		for i in range(1, 25):
			var k := i / 24.0
			var p := outlet.lerp(sag, k).lerp(sag.lerp(tip + Vector2(-96, 0).rotated(1.15), k), k)  # into the grip's end
			o.draw_line(prev, p, CartoonArt.INK, 13.0, true)
			o.draw_line(prev, p, Color(0.29, 0.3, 0.36), 5.0, true)
			prev = p
		var alarm := int(mods.get("tank_alarm", 0)) > 0 and tank < LOW_GAS and fmod(_t, 0.5) < 0.3
		CartoonArt.old_pump(o, PUMP_AT + Vector2(36, 44), tank / tank_full(), sin(_t * 60.0) * (1.5 if pouring else 0.0), alarm)
		return
	var tex: Texture2D = _tex.get("pump_hud")
	var shake := Vector2(sin(_t * 60.0), 0) * (1.5 if pouring else 0.0)
	var at := PUMP_AT + shake
	var outlet := at + Vector2(34, 46) * 2.0
	var hand := tip - NOZZLE_TIP + NOZZLE_HOSE
	var sag := (outlet + hand) * 0.5 + Vector2(0, 160)
	var prev := outlet
	for i in range(1, 25):
		var k := i / 24.0
		var p := outlet.lerp(sag, k).lerp(sag.lerp(hand, k), k)
		o.draw_line(prev, p, Color(0.08, 0.08, 0.09), 9.0, true)
		o.draw_line(prev + Vector2(-1, -2), p + Vector2(-1, -2), Color(0.25, 0.25, 0.28), 2.0, true)
		prev = p
	if tex:
		o.draw_set_transform(at, 0.0, Vector2(2, 2))
		o.draw_texture(tex, Vector2.ZERO)
		o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if int(mods.get("tank_alarm", 0)) > 0 and tank < LOW_GAS and fmod(_t, 0.5) < 0.3:
		o.draw_circle(at + Vector2(17, 10) * 2.0, 14.0, Color(1.0, 0.15, 0.1, 0.55))  # the globe blinks red
	var c := at + Vector2(18, 42) * 2.0
	var a := PI * (1.0 - clampf(tank / tank_full(), 0.0, 1.0))
	o.draw_line(c, c + Vector2(cos(a), -sin(a)) * 13.0, Color(0.75, 0.1, 0.08), 2.0, true)
	o.draw_circle(c, 2.5, Color(0.1, 0.1, 0.1))


## One coin seen from above, `squash` for its spin: a coloured disc with a bright rim and a shine.
## $1 blue, $5 green, $20 red, $50 purple. Static so the pixel view can draw them too.
static func draw_coin(o: CanvasItem, at: Vector2, v: int, squash := 1.0, r := 9.0, _a := 1.0) -> void:
	CartoonArt.coin(o, at, COIN_COLORS[v], squash, r)


## A coin lying flat in a stack, seen at an angle.
func _draw_stacked_coin(o: Node2D, at: Vector2, v: int, a := 1.0) -> void:
	var col: Color = COIN_COLORS[v]
	o.draw_set_transform(at, 0.0, Vector2(1.0, 0.42))
	o.draw_circle(Vector2(0, 6), 16.5, Color(CartoonArt.INK, a))
	o.draw_circle(Vector2.ZERO, 16.5, Color(CartoonArt.INK, a))
	o.draw_circle(Vector2(0, 6), 14.0, Color(col.darkened(0.45), a))
	o.draw_circle(Vector2.ZERO, 14.0, Color(col.lightened(0.3), a))
	o.draw_circle(Vector2.ZERO, 11.0, Color(col, a))
	o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The coins flying in, and the tray: four stacks ($1, $5, $20, $50) beside the cash register.
## At closing the stacks slide into the register.
func _draw_tray(o: Node2D) -> void:
	var font := GodUI.font()
	var tray := StyleBoxFlat.new()
	tray.bg_color = Color(0.12, 0.1, 0.09, 0.85)
	tray.set_corner_radius_all(8)
	tray.set_border_width_all(2)
	tray.border_color = Color(0.0, 0.0, 0.0, 0.9)
	o.draw_style_box(tray, Rect2(TRAY_AT + Vector2(0, -10), Vector2(168, 22)))
	var k := smoothstep(0.6, 1.0, cash_in_progress())
	for v in [1, 5, 20, 50]:
		var n: int = stacks[v]
		var base := stack_top(v) + Vector2(0, mini(n, 24) * 3)
		var at := base.lerp(REGISTER_AT + Vector2(-6, -6), k)
		for i in mini(n, 24):
			_draw_stacked_coin(o, at + Vector2(0, -i * 3), v, 1.0 - k * 0.6)
	_draw_register(o, font)
	for m in money:
		if m.state == "fly":
			draw_coin(o, m.pos, m.value, absf(cos(m.rot)), 11.0)


## A chunky cash register; its display shows the bank (what's in the tray isn't in yet).
func _draw_register(o: Node2D, _font: Font) -> void:
	var at := REGISTER_AT
	var slide := smoothstep(0.6, 1.0, cash_in_progress())
	var pop := 1.0 + 0.25 * sin(slide * PI) if _cash_in > 0.0 else 1.0
	CartoonArt.box(o, Rect2(at + Vector2(-36, -20) * pop, Vector2(72, 46) * pop), Color(0.91, 0.26, 0.23), 8.0, 3.0)
	CartoonArt.box(o, Rect2(at + Vector2(-40, 20), Vector2(80, 12)), Color(0.6, 0.14, 0.12), 4.0, 2.0)  # the drawer
	var screen := Rect2(at + Vector2(-44, -50), Vector2(88, 26))
	CartoonArt.box(o, screen, Color(0.08, 0.16, 0.1), 5.0, 3.0)
	var today := stacks_value()
	var bank := shown_cash - today * (1.0 - slide)  # the tray's coins count in as they pour in
	CartoonArt.label(o, screen.get_center() + Vector2(0, 7), "$%d" % int(bank), 18, Color(0.45, 1.0, 0.5), true, 3)
	CartoonArt.label(o, at + Vector2(0, 14), tr("CASH"), 15, Color.WHITE, true, 4)
	if today > 0 and slide < 0.99:  # today's coins, still in the tray
		CartoonArt.label(o, TRAY_AT + Vector2(84, -40 - mini(stacks.values().max(), 24) * 3), tr("TODAY +$%d") % today, 15, Color(1.0, 0.85, 0.3), true, 4)


## The combo pill and the chain (round 11, playtest 12: "make the number move and pop as it increases"):
## the pill swells with each step and burns hotter, flames lick it from x3; under it the chain's sum runs
## ("1+2+3 = 6") with today's combo total; when the chain breaks the pill shakes red and the chain's value
## flies into the total.
func _draw_chain_hud(o: Node2D) -> void:
	var hot := clampf((combo.multiplier - 1) / 4.0, 0.0, 1.0)
	var centre := Vector2(WIDTH - 90, 30)
	var s := 1.0 + 0.45 * _combo_pop * _combo_pop + 0.04 * hot * sin(_t * 10.0)
	var jolt := Vector2(sin(_t * 70.0) * 6.0 * _combo_break, 0)
	if combo.multiplier >= 3:  # flames
		for i in 7:
			var fx := -70.0 + i * 23.0
			var h := (10.0 + 10.0 * hot) * (0.7 + 0.3 * sin(_t * 14.0 + i * 1.7))
			var base := centre + Vector2(fx, -14) * s
			o.draw_colored_polygon(PackedVector2Array([base + Vector2(-8, 0), base + Vector2(0, -h * s), base + Vector2(8, 0)]), Color(1.0, 0.75, 0.2, 0.9))
			o.draw_colored_polygon(PackedVector2Array([base + Vector2(-4, 0), base + Vector2(0, -h * 0.6 * s), base + Vector2(4, 0)]), Color(1.0, 0.95, 0.6))
	var fill := Color(1.0, 0.55, 0.24).lerp(Color(1.0, 0.22, 0.18), hot)
	if _combo_break > 0.0:
		fill = fill.lerp(Color(0.5, 0.5, 0.55), _combo_break)
	var r := Rect2(centre + jolt - Vector2(78, 20) * s, Vector2(156, 40) * s)
	CartoonArt.box(o, r, fill, 20.0 * s, 4.0)
	CartoonArt.label(o, centre + jolt + Vector2(0, 8 * s), tr("x%d COMBO") % combo.multiplier, int(22 * s), Color.WHITE)
	var today: int = day_stats.get("combo_points", 0) if not day_stats.is_empty() else 0
	var line := ""
	if chain.size() >= 1:
		var steps := []
		for v in chain.slice(maxi(0, chain.size() - 6)):
			steps.append(str(v))
		var sum := 0
		for v in chain:
			sum += v
		line = ("…+" if chain.size() > 6 else "") + "+".join(steps) + " = %d" % sum
	CartoonArt.label(o, Vector2(WIDTH - 90, 70), tr("CHAIN %s") % line if line != "" else tr("no chain yet"), 14, Color(1.0, 0.92, 0.6) if line != "" else Color(1, 1, 1, 0.7), true, 4)
	CartoonArt.label(o, Vector2(WIDTH - 90, 90), tr("TODAY %d combo") % today, 13, Color.WHITE, true, 4)
	if not _chain_fly.is_empty():
		var k: float = _chain_fly.t / 0.9
		var p := centre.lerp(Vector2(WIDTH - 90, 90), k) + Vector2(0, -40 * sin(k * PI))
		CartoonArt.label(o, p, "+%d" % _chain_fly.value, int(30 - 10 * k), Color(1.0, 0.85, 0.3))


## The tutorial's card (round 11): what to do now, and an arrow at what it's about.
func _draw_tutorial(o: Node2D) -> void:
	if not tutorial or tutorial.step().is_empty() or tutorial.step().point == "tabs":
		return
	var st: Dictionary = tutorial.step()
	var text := tr(st.text)
	var w := 560.0
	var box := Rect2(Vector2(WIDTH * 0.5 - w * 0.5, 96), Vector2(w, 64))
	var bob := sin(_t * 3.0) * 2.0
	CartoonArt.box(o, box.grow(2) , Color(1.0, 0.97, 0.88), 14.0, 4.0)
	GodUI.para_in(o, GodUI.font(), box.position + Vector2(16, 26 + bob * 0), text, 16, w - 32, CartoonArt.INK, 1.25)
	GodUI.text(o, box.position + Vector2(w - 70, 14), "%d / %d" % [tutorial.index + 1, Tutorial.STEPS.size()], 11, Color(CartoonArt.INK, 0.5))
	var target := Vector2.ZERO
	match st.point:
		"ring":
			target = scr(_aim) + Vector2(0, -30)
		"gauge":
			var c: ProtoCar = stream_cars[0] if not stream_cars.is_empty() else nearest_customer(_aim, 2000.0)
			target = car_top(c) + Vector2(0, -60) if c else Vector2.ZERO
		"pill":
			target = Vector2(WIDTH - 170, 40)
		"road":
			target = scr(Vector2(700, ROAD_Y))
		"bar":
			target = Vector2(560, 36)
	if target != Vector2.ZERO:  # a bouncing arrow from the card toward it
		var from := box.get_center() + (target - box.get_center()).normalized() * 40.0
		from = Vector2(clampf(target.x, box.position.x + 20, box.end.x - 20), box.end.y if target.y > box.end.y else box.position.y)
		var dir := (target - from).normalized()
		var tip := target - dir * (14.0 + bob * 3.0)
		o.draw_line(from, tip, CartoonArt.INK, 9.0, true)
		o.draw_line(from, tip, Color(1.0, 0.8, 0.25), 5.0, true)
		CartoonArt.poly(o, PackedVector2Array([tip + dir * 16.0, tip + dir.orthogonal() * 11.0, tip - dir.orthogonal() * 11.0]), Color(1.0, 0.8, 0.25), 3.0)


## What a full station tank holds today (the tank gauge's 100%).
func tank_full() -> float:
	return float(mods.get("tank_capacity", tank_size))


## The big OUVERT / FERMÉ sign (playtest 12: it wasn't obvious when the day opened or closed). OUVERT swings
## in on a chain at opening and lifts away; at closing it flips round to FERMÉ and hangs there.
func _draw_banner(o: Node2D) -> void:
	if banner.is_empty():
		return
	var t: float = banner.t
	var open: bool = banner.open
	var lift := 0.0
	if open:
		if t > 2.2:
			return
		lift = smoothstep(1.6, 2.2, t) * 260.0
	var drop := (1.0 - exp(-t * 6.0)) * 200.0 - lift
	var swing := sin(t * 7.0) * exp(-t * 2.5) * 0.3
	var flip := 1.0
	var showing_open := open
	if not open:  # flips from OUVERT to FERMÉ
		flip = absf(cos(clampf(t / 0.5, 0.0, 1.0) * PI))
		showing_open = t < 0.25
	var top := Vector2(WIDTH * 0.5, drop - 60)
	o.draw_set_transform(top, swing, Vector2(maxf(flip, 0.05), 1.0))
	o.draw_line(Vector2(-90, -200), Vector2(-90, 0), CartoonArt.INK, 4.0)
	o.draw_line(Vector2(90, -200), Vector2(90, 0), CartoonArt.INK, 4.0)
	var col := Color(0.24, 0.78, 0.4) if showing_open else Color(0.91, 0.26, 0.23)
	CartoonArt.box(o, Rect2(-150, 0, 300, 96), Color(1.0, 0.97, 0.9), 18.0, 6.0)
	CartoonArt.box(o, Rect2(-138, 10, 276, 76), col, 12.0, 4.0)
	CartoonArt.label(o, Vector2(0, 66), "OUVERT" if showing_open else "FERMÉ", 54, Color.WHITE, true, 8)
	o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Today's visitor chatting with the regulars (round 9), kept in the background (playtest 9): small,
## faded bubbles with no words to read. The lines themselves go to the menu's scrapbook.
func _draw_quip(o: Node2D, font: Font) -> void:
	if visitor_car and is_instance_valid(visitor_car) and visitor_car.phase != ProtoCar.Phase.GONE:
		if not chat_line.is_empty() and _chat.get("t", 0.0) > 0.0:
			_murmur(o, font, car_top(visitor_car) + Vector2(0, -10), _chat.get("i", 0), minf(_chat.t * 3.0, 1.0))
	if quip_t <= 0.0 or quip_text == "":
		return
	var where: Variant = regular_head(quip_who)
	if where != null:
		_murmur(o, font, where, _chat.get("i", 0) + 1, minf(quip_t * 3.0, 1.0))


const MURMURS := ["...", "ha ha", "!", "?!", "hm hm"]


## A small faded speech bubble with no words: someone chatting, not something to read.
func _murmur(o: Node2D, font: Font, head: Vector2, i: int, a: float) -> void:
	var text: String = MURMURS[i % MURMURS.size()]
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 12
	var box := Rect2(head + Vector2(-w * 0.5, -30), Vector2(w, 17))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.96, 0.9, 0.55 * a)
	sb.set_corner_radius_all(8)
	o.draw_style_box(sb, box)
	o.draw_string(font, box.position + Vector2(6, 13), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.1, 0.09, 0.08, 0.6 * a))


var _vignette: GradientTexture2D


## HD-2D's soft dark edges.
func _draw_vignette(o: Node2D) -> void:
	if not _vignette:
		var g := Gradient.new()
		g.set_color(0, Color(0, 0, 0, 0))
		g.set_color(1, Color(0.05, 0.03, 0.02, 0.55))
		g.set_offset(0, 0.55)
		_vignette = GradientTexture2D.new()
		_vignette.gradient = g
		_vignette.fill = GradientTexture2D.FILL_RADIAL
		_vignette.fill_from = Vector2(0.5, 0.5)
		_vignette.fill_to = Vector2(1.05, 1.05)
		_vignette.width = 256
		_vignette.height = 144
	o.draw_texture_rect(_vignette, Rect2(0, 0, WIDTH, HEIGHT), false)


## The day bar (playtest 9): opening hour at the left end, closing hour at the right, filling as the day goes.
func _draw_day_bar(o: Node2D) -> void:
	var bar := Rect2(376, 14, 400, 18)
	var close_h: float = mods.get("close_hour", CLOSE_HOUR)
	GodUI.text(o, Vector2(bar.position.x - 140, bar.end.y), tr("DAY %d") % round_num, 22, Color.WHITE, false, 6)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.05, 0.05, 0.08, 0.8)
	back.set_corner_radius_all(9)
	back.set_border_width_all(2)
	back.border_color = Color(0, 0, 0, 0.9)
	o.draw_style_box(back, bar.grow(2))
	var k := day_progress()
	if k > 0.0:
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color(1.0, 0.72, 0.2).lerp(Color(0.95, 0.35, 0.25), k)  # morning gold to evening red
		fill.set_corner_radius_all(9)
		o.draw_style_box(fill, Rect2(bar.position, Vector2(maxf(bar.size.x * k, 18.0), bar.size.y)))
	var sun := bar.position + Vector2(bar.size.x * k, bar.size.y * 0.5)
	o.draw_circle(sun, 11.0, Color(0, 0, 0, 0.9))
	o.draw_circle(sun, 9.0, Color(1.0, 0.9, 0.35))
	GodUI.text(o, Vector2(bar.position.x - 10 - 34, bar.end.y - 1), "%d h" % int(OPEN_HOUR), 16, Color.WHITE, false, 5)
	GodUI.text(o, Vector2(bar.end.x + 10, bar.end.y - 1), "%d h" % int(close_h), 16, Color.WHITE, false, 5)


func _draw_hud(o: Node2D, font: Font) -> void:
	if hd:
		_draw_vignette(o)
	_draw_day_bar(o)
	_draw_tray(o)
	_draw_banner(o)
	_draw_quip(o, font)
	var combo_text := tr("x%d COMBO") % combo.multiplier
	if view == "cartoon":
		_draw_chain_hud(o)
		_draw_tutorial(o)
	else:
		o.draw_string(font, Vector2(WIDTH - 150, 30), combo_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.9))
	if round_wasted > 0.05:
		o.draw_string(font, Vector2(WIDTH - 150, 116 if view == "cartoon" else 56), "wasted $%.2f" % round_wasted, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(GAS, 0.9))
	if round_over and not managed:
		o.draw_rect(Rect2(0, 0, WIDTH, HEIGHT), Color(0, 0, 0, 0.55))
		var lines := ["FERMÉ   ROUND %d" % round_num, "",
			"Sales (the bills)      $%.2f" % round_sales,
			"Tips (the jar)          $%.2f" % round_tips,
			"Gas used               -$%.2f   (wasted $%.2f)" % [round_fuel_cost(), round_wasted],
			"Net                      $%.2f" % (round_earned - round_fuel_cost()),
			"In the bank           $%.2f" % (cash - round_fuel_cost()), "",
			"ENTER  open again        ESC  quit"]
		for i in lines.size():
			var lw := font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 26 if i == 0 else 20).x
			o.draw_string(font, Vector2((WIDTH - lw) * 0.5, 230 + i * 34), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 26 if i == 0 else 20,
				Color(1.0, 0.85, 0.3) if i == 0 else Color.WHITE)
