class_name CartoonArt
extends RefCounted
## GOD PUMP's 2D cartoon look (round 10 batch C, approved 2026-10-25; the look test is
## docs/art/look_test_cartoon.png): chunky shapes with a thick dark outline, flat colours with one shade
## and one shine, exaggerated effects, shiny loot. Everything is drawn in code from shapes, no textures,
## so any view or screen can use it and a new car type is a few lines of data, not a sprite sheet.
## Composition: GodPump's cartoon view, the HUD and the screens all call this one kit.
## Serves: readability (Mastery: you see what you aim at) and Comedy (the cast's exaggerated looks).

const INK := Color(0.114, 0.102, 0.169)
const OUTLINE := 3.0
const GLASS := Color(0.17, 0.25, 0.4)
const SHINE := Color(1, 1, 1, 0.55)
const GOLD := Color(1.0, 0.79, 0.24)
const GAS := Color(1.0, 0.79, 0.24)
const GREEN := Color(0.24, 0.88, 0.48)
const RED := Color(1.0, 0.29, 0.24)
## Bright car paints (a sedan's colour comes from its look number).
const PAINTS := [Color(0.24, 0.55, 1.0), Color(1.0, 0.6, 0.18), Color(0.49, 0.87, 0.36), Color(1.0, 0.56, 0.78),
	Color(0.44, 0.83, 1.0), Color(1.0, 0.84, 0.25), Color(0.68, 0.45, 0.95), Color(0.95, 0.95, 0.97)]
## Each car type's silhouette (top-down, facing +x, in world px) and colours.
##   len, wid: body size. cab: cabin length and offset. kind: extra details to draw.
const CARS := {
	"sedan": {"len": 64.0, "wid": 32.0, "cab": Vector2(26, -2), "kind": "sedan"},
	"pickup": {"len": 78.0, "wid": 32.0, "cab": Vector2(22, 12), "kind": "pickup", "paint": Color(1.0, 0.6, 0.18)},
	"cadillac": {"len": 86.0, "wid": 32.0, "cab": Vector2(30, 0), "kind": "cadillac", "paint": Color(1.0, 0.56, 0.78)},
	"bazou": {"len": 60.0, "wid": 30.0, "cab": Vector2(24, -2), "kind": "bazou", "paint": Color(0.62, 0.5, 0.36)},
	"racer": {"len": 66.0, "wid": 28.0, "cab": Vector2(18, -4), "kind": "racer", "paint": Color(1.0, 0.23, 0.23)},
	"sweeper": {"len": 70.0, "wid": 34.0, "cab": Vector2(20, 14), "kind": "sweeper", "paint": Color(1.0, 0.62, 0.1)},
	"thief": {"len": 62.0, "wid": 30.0, "cab": Vector2(24, -2), "kind": "thief", "paint": Color(0.18, 0.17, 0.24)},
	"clumsy": {"len": 72.0, "wid": 36.0, "cab": Vector2(16, 22), "kind": "van", "paint": Color(0.62, 0.78, 0.86)},
	"electric": {"len": 50.0, "wid": 28.0, "cab": Vector2(22, -2), "kind": "electric", "paint": Color(0.36, 0.95, 0.6)},
	"papa": {"len": 58.0, "wid": 32.0, "cab": Vector2(28, -6), "kind": "papa", "paint": Color(1.0, 0.55, 0.15)},
}


## A rounded box with the thick outline.
static func box(ci: CanvasItem, r: Rect2, fill: Color, radius := 8.0, outline := OUTLINE) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(int(radius))
	sb.set_border_width_all(int(outline))
	sb.border_color = INK
	sb.anti_aliasing = true
	ci.draw_style_box(sb, r)


## A filled circle with the outline.
static func disc(ci: CanvasItem, at: Vector2, r: float, fill: Color, outline := OUTLINE) -> void:
	ci.draw_circle(at, r + outline, INK)
	ci.draw_circle(at, r, fill)


## A polygon with the outline.
static func poly(ci: CanvasItem, pts: PackedVector2Array, fill: Color, outline := OUTLINE) -> void:
	ci.draw_colored_polygon(pts, fill)
	var loop := pts.duplicate()
	loop.append(pts[0])
	ci.draw_polyline(loop, INK, outline, true)


## Text with a thick dark outline, the cartoon way.
static func label(ci: CanvasItem, at: Vector2, s: String, size: int, col: Color, centred := true, outline := 0) -> void:
	var f := GodUI.font()
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p := at - Vector2(w * 0.5 if centred else 0.0, 0)
	var o := outline if outline > 0 else maxi(4, size / 4)
	ci.draw_string_outline(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, o, INK)
	ci.draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


# --- Cars -----------------------------------------------------------------------------------------

## The paint for a car: its type's colour, or a bright sedan paint from its look number.
static func paint(type_id: String, look: int) -> Color:
	var spec: Dictionary = CARS.get(type_id, {})
	return spec.get("paint", PAINTS[look % PAINTS.size()])


## A car from above at `at`, turned by `heading`, squashed by `squash`, lifted `lift` px (its shadow
## stays on the ground). Unknown types draw as a sedan in their stack's colour.
static func car(ci: CanvasItem, at: Vector2, heading: float, type_id: String, col: Color, squash := Vector2.ONE,
		lift := 0.0, t := 0.0, scale := 1.0) -> void:
	var spec: Dictionary = CARS.get(type_id, CARS.sedan)
	var ln: float = spec.len
	var wid: float = spec.wid
	ci.draw_set_transform(at + Vector2(0, 7), heading, squash * scale * (1.0 - lift / 260.0))
	ci.draw_rect(Rect2(-ln * 0.5 + 2, -wid * 0.5 + 2, ln - 4, wid - 4), Color(0, 0, 0, 0.22))  # its shadow
	ci.draw_set_transform(at + Vector2(0, -lift), heading, squash * scale)
	var hl := ln * 0.5
	var hw := wid * 0.5
	for x in [-hl * 0.55, hl * 0.5]:  # wheels poke out
		for y in [-hw - 3.0, hw - 4.0]:
			ci.draw_rect(Rect2(x - 7, y, 14, 7), INK)
	match spec.kind:
		"cadillac":  # long, with tail fins
			poly(ci, PackedVector2Array([Vector2(-hl, -hw - 3), Vector2(-hl + 22, -hw), Vector2(hl - 10, -hw), Vector2(hl, -hw + 8),
				Vector2(hl, hw - 8), Vector2(hl - 10, hw), Vector2(-hl + 22, hw), Vector2(-hl, hw + 3), Vector2(-hl + 6, 0)]), col)
		"racer":
			poly(ci, PackedVector2Array([Vector2(-hl, -hw), Vector2(hl - 12, -hw + 2), Vector2(hl, -4), Vector2(hl, 4),
				Vector2(hl - 12, hw - 2), Vector2(-hl, hw)]), col)
		"van", "sweeper":
			box(ci, Rect2(-hl, -hw, ln, wid), col, 6.0)
		_:
			box(ci, Rect2(-hl, -hw, ln, wid), col, 12.0)
	ci.draw_rect(Rect2(-hl + 4, hw * 0.35, ln - 8, hw * 0.45), Color(0, 0, 0, 0.16))  # one shade
	var cab: Vector2 = spec.cab  # x: cabin length, y: offset from the centre
	match spec.kind:
		"pickup":  # an open bed behind the cab
			box(ci, Rect2(-hl + 5, -hw + 5, ln * 0.45, wid - 10), col.darkened(0.35), 3.0, 2.0)
			box(ci, Rect2(-hl + 12, -6, 12, 12), Color(0.78, 0.63, 0.42), 2.0, 2.0)
		"sweeper":  # the round brush at the front, spinning
			disc(ci, Vector2(hl + 6, 0), hw * 0.75, Color(0.98, 0.85, 0.2))
			for i in 6:
				var a := t * 12.0 + i * TAU / 6.0
				ci.draw_line(Vector2(hl + 6, 0), Vector2(hl + 6, 0) + Vector2.from_angle(a) * hw * 0.7, INK, 2.0)
			for i in 4:  # hazard stripes
				ci.draw_rect(Rect2(-hl + 6 + i * 10, -hw + 3, 5, wid - 6), Color(0.15, 0.13, 0.2, 0.35))
		"racer":
			ci.draw_rect(Rect2(-hl, -4, ln - 4, 3), Color.WHITE)
			ci.draw_rect(Rect2(-hl, 2, ln - 4, 3), Color.WHITE)
			box(ci, Rect2(-hl - 6, -hw, 8, wid), col.darkened(0.2), 3.0, 2.0)  # spoiler
		"bazou":  # rust spots and a dent
			for p in [Vector2(-hl * 0.5, -hw * 0.4), Vector2(hl * 0.35, hw * 0.3), Vector2(-hl * 0.1, hw * 0.45)]:
				ci.draw_circle(p, 4.0, Color(0.55, 0.28, 0.12))
		"electric":
			poly(ci, PackedVector2Array([Vector2(-6, -9), Vector2(2, -9), Vector2(-1, -1), Vector2(6, -1), Vector2(-4, 10), Vector2(-1, 2), Vector2(-7, 2)]), Color(1.0, 0.92, 0.2), 1.5)
		"papa":  # a fishing rod on the roof
			ci.draw_line(Vector2(-hl + 4, -hw + 6), Vector2(hl + 18, -hw - 10), INK, 2.5)
	var cx: float = cab.y
	var cl: float = cab.x
	box(ci, Rect2(cx - cl * 0.5, -hw + 5, cl, wid - 10), col.lerp(Color.WHITE, 0.4), 7.0, 2.5)  # the roof
	poly(ci, PackedVector2Array([Vector2(cx + cl * 0.5 - 2, -hw + 6), Vector2(cx + cl * 0.5 + 7, -hw + 9),
		Vector2(cx + cl * 0.5 + 7, hw - 9), Vector2(cx + cl * 0.5 - 2, hw - 6)]), GLASS, 2.0)  # windshield
	ci.draw_line(Vector2(cx + cl * 0.5 + 1, -hw + 9), Vector2(cx + cl * 0.5 + 4, -2), Color(0.62, 0.82, 1.0), 2.0)
	if spec.kind == "thief":  # a burglar mask on the roof
		ci.draw_rect(Rect2(cx - 9, -6, 18, 7), INK)
		ci.draw_circle(Vector2(cx - 4, -3), 2.0, Color.WHITE)
		ci.draw_circle(Vector2(cx + 4, -3), 2.0, Color.WHITE)
	for y in [-hw + 6.0, hw - 6.0]:  # headlights
		disc(ci, Vector2(hl - 2, y), 3.0, Color(1.0, 0.97, 0.7), 1.5)
	ci.draw_line(Vector2(hl * 0.35, -hw + 4), Vector2(hl - 6, -hw + 6), SHINE, 3.0)  # one shine
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The fuel gauge over a car (playtest 6: a dial, not a bar), cartoon: the order on a dark tag, a cream
## dial with red to green, the needle, gold once full.
static func gauge(ci: CanvasItem, at: Vector2, f: float, order: float) -> void:
	var text := "$%.0f" % order
	var font := GodUI.font()
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 14
	box(ci, Rect2(at + Vector2(-w * 0.5, -34), Vector2(w, 20)), INK, 10.0, 2.0)
	ci.draw_string(font, at + Vector2(-w * 0.5 + 7, -19), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	var c := at + Vector2(0, 8)
	var r := 17.0
	var pts := PackedVector2Array([c + Vector2(-r - 3, 2)])
	for i in 13:
		pts.append(c + Vector2.from_angle(PI + PI * i / 12.0) * (r + 3))
	pts.append(c + Vector2(r + 3, 2))
	ci.draw_colored_polygon(pts, INK)
	var inner := PackedVector2Array([c + Vector2(-r, 0)])
	for i in 13:
		inner.append(c + Vector2.from_angle(PI + PI * i / 12.0) * r)
	inner.append(c + Vector2(r, 0))
	ci.draw_colored_polygon(inner, Color(1.0, 0.98, 0.94) if f < 0.995 else Color(1.0, 0.92, 0.55))
	ci.draw_arc(c, r - 5, PI, PI * 1.55, 8, RED, 4.0)
	ci.draw_arc(c, r - 5, PI * 1.8, TAU, 8, GREEN, 4.0)
	var a := PI * (1.0 + clampf(f, 0.0, 1.05))
	ci.draw_line(c, c + Vector2.from_angle(a) * (r - 3), INK, 2.5, true)
	ci.draw_circle(c, 3.0, INK)


## A coin seen from above, `squash` for its spin: $1 blue, $5 green, $20 red, $50 purple.
static func coin(ci: CanvasItem, at: Vector2, col: Color, squash := 1.0, r := 9.0) -> void:
	ci.draw_set_transform(at, 0.0, Vector2(maxf(squash, 0.2), 1.0))
	ci.draw_circle(Vector2(0, r * 0.25), r + 2.0, INK)
	ci.draw_circle(Vector2.ZERO, r + 2.0, INK)
	ci.draw_circle(Vector2.ZERO, r, col)
	ci.draw_arc(Vector2.ZERO, r * 0.65, 0, TAU, 14, Color(1, 1, 1, 0.55), maxf(r * 0.14, 1.0))
	if r >= 7.0:
		var f := GodUI.font()
		var s := int(r * 1.1)
		ci.draw_string(f, Vector2(-f.get_string_size("$", HORIZONTAL_ALIGNMENT_LEFT, -1, s).x * 0.5, s * 0.36), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, s, Color.WHITE)
	ci.draw_arc(Vector2.ZERO, r * 0.8, PI * 1.1, PI * 1.45, 4, Color.WHITE, 2.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A four-point sparkle.
static func sparkle(ci: CanvasItem, at: Vector2, r: float, a := 1.0) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var rr := r if i % 2 == 0 else r * 0.25
		pts.append(at + Vector2.from_angle(i * TAU / 8.0 - PI * 0.5) * rr)
	ci.draw_colored_polygon(pts, Color(1.0, 0.98, 0.76, a))
	var loop := pts.duplicate()
	loop.append(pts[0])
	ci.draw_polyline(loop, Color(INK, a), 1.5, true)


# --- People ---------------------------------------------------------------------------------------

## The cast, as chunky little figures: skin, shirt, trousers, hair and hat, and a trait.
const PEOPLE := {
	"tiguy": {"skin": Color(0.95, 0.71, 0.55), "shirt": Color(0.86, 0.2, 0.2), "pants": Color(0.25, 0.35, 0.6), "hat": Color(0.2, 0.45, 0.25), "trait": "plaid", "h": 1.0},
	"gagnon": {"skin": Color(0.96, 0.8, 0.68), "shirt": Color(1.0, 0.62, 0.78), "pants": Color(0.45, 0.4, 0.55), "hair": Color(0.8, 0.8, 0.84), "trait": "bun", "h": 0.95},
	"bertrand": {"skin": Color(0.9, 0.66, 0.52), "shirt": Color(0.95, 0.95, 0.9), "pants": Color(0.35, 0.3, 0.25), "trait": "belly", "h": 1.0},
	"legrand": {"skin": Color(0.95, 0.75, 0.6), "shirt": Color(0.2, 0.18, 0.2), "pants": Color(0.2, 0.3, 0.55), "hair": Color(0.45, 0.28, 0.12), "trait": "mullet", "h": 1.3},
	"papa": {"skin": Color(0.93, 0.72, 0.58), "shirt": Color(0.95, 0.55, 0.15), "pants": Color(0.3, 0.3, 0.35), "hair": Color(0.92, 0.92, 0.95), "trait": "cap", "h": 1.0},
	"rejean": {"skin": Color(0.92, 0.7, 0.55), "shirt": Color(0.3, 0.5, 0.85), "pants": Color(0.25, 0.25, 0.3), "hair": Color(0.25, 0.18, 0.1), "trait": "", "h": 1.05},
}


## A person standing on `feet` (screen px). pose: sit, stand, walk_0..3, cheer, clap, coffee, and the
## sit_ variants (RegularsCrew.pose). `flip` faces left. `s` scales the figure.
static func person(ci: CanvasItem, feet: Vector2, who: String, pose: String, t := 0.0, flip := false, s := 1.0) -> void:
	var p: Dictionary = PEOPLE.get(who, PEOPLE.tiguy)
	var h: float = p.h
	var seated := pose.begins_with("sit")
	var react := pose.replace("sit_", "")
	var leg := 0.0
	if pose.begins_with("walk"):
		leg = sin(t * 14.0) * 5.0
	var hip := feet + Vector2(0, -16.0 * h * s if not seated else -10.0 * s)
	var neck := hip + Vector2(0, -16.0 * h * s)
	ci.draw_circle(feet + Vector2(0, 1), 9.0 * s, Color(0, 0, 0, 0.18))
	# legs
	if seated:
		ci.draw_line(hip, hip + Vector2(8 * s, 0), INK, 7.0 * s, true)
		ci.draw_line(hip + Vector2(8 * s, 0), hip + Vector2(8 * s, 9 * s), INK, 7.0 * s, true)
		ci.draw_line(hip, hip + Vector2(8 * s, 0), p.pants, 4.0 * s, true)
	else:
		for side in [-1.0, 1.0]:
			var foot := feet + Vector2(side * 4.0 * s + leg * side, 0)
			ci.draw_line(hip + Vector2(side * 3.0 * s, 0), foot, INK, 7.0 * s, true)
			ci.draw_line(hip + Vector2(side * 3.0 * s, 0), foot, p.pants, 4.0 * s, true)
	# body
	var belly := 4.0 * s if p.trait == "belly" else 0.0
	box(ci, Rect2(neck + Vector2(-8 * s - belly, 0), Vector2(16 * s + belly * 2.0, hip.y - neck.y + 2)), p.shirt, 6.0 * s, 2.5)
	if p.trait == "plaid":
		for i in 3:
			ci.draw_line(neck + Vector2(-7 * s, (4 + i * 5) * s), neck + Vector2(7 * s, (4 + i * 5) * s), Color(0.5, 0.08, 0.08), 1.5)
	if p.trait == "belly":  # suspenders
		for side in [-1.0, 1.0]:
			ci.draw_line(neck + Vector2(side * 5 * s, 0), hip + Vector2(side * 6 * s, 0), Color(0.75, 0.18, 0.15), 2.0)
	# arms
	var shoulder := neck + Vector2(0, 4 * s)
	for side in [-1.0, 1.0]:
		var hand: Vector2
		match react:
			"cheer":
				hand = shoulder + Vector2(side * 10 * s, -16 * s + sin(t * 18.0 + side) * 2.0 * s)
			"clap":
				hand = shoulder + Vector2(side * (2.0 + absf(sin(t * 16.0)) * 6.0) * s, -2 * s)
			"coffee":
				hand = shoulder + Vector2(side * 9 * s, 8 * s) if side < 0.0 else shoulder + Vector2(9 * s, 2 * s)
			_:
				hand = shoulder + Vector2(side * 10 * s, 12 * s)
		ci.draw_line(shoulder + Vector2(side * 6 * s, 0), hand, INK, 6.0 * s, true)
		ci.draw_line(shoulder + Vector2(side * 6 * s, 0), hand, p.shirt, 3.0 * s, true)
		ci.draw_circle(hand, 2.5 * s, p.skin)
		if react == "coffee" and side > 0.0:
			box(ci, Rect2(hand + Vector2(-3 * s, -6 * s), Vector2(7 * s, 8 * s)), Color.WHITE, 2.0, 1.5)
	# head
	var head := neck + Vector2(0, -8 * s)
	if p.trait == "mullet":
		ci.draw_rect(Rect2(head + Vector2(-8 * s, -2 * s), Vector2(16 * s, 12 * s)), p.hair)
	disc(ci, head, 8.0 * s, p.skin, 2.5)
	var dir := -1.0 if flip else 1.0
	ci.draw_circle(head + Vector2(3 * s * dir, -1 * s), 1.6 * s, INK)
	ci.draw_circle(head + Vector2(-1 * s * dir, -1 * s), 1.6 * s, INK)
	if react == "cheer":
		ci.draw_circle(head + Vector2(dir * s, 4 * s), 2.5 * s, INK)  # mouth open
	match p.trait:
		"plaid", "cap":  # a cap
			var col: Color = p.get("hat", p.get("shirt"))
			box(ci, Rect2(head + Vector2(-8 * s, -10 * s), Vector2(16 * s, 6 * s)), col, 3.0, 2.0)
			ci.draw_rect(Rect2(head + Vector2((2 if dir > 0 else -11) * s, -6 * s), Vector2(9 * s, 3 * s)), col.darkened(0.3))
			if p.trait == "plaid":
				ci.draw_line(head + Vector2(-5 * s, 3 * s), head + Vector2(5 * s, 3 * s), Color(0.35, 0.22, 0.12), 2.5)  # moustache
		"bun":
			disc(ci, head + Vector2(0, -9 * s), 4.0 * s, p.hair, 2.0)
			ci.draw_arc(head + Vector2(-3 * s, -1 * s), 2.5 * s, 0, TAU, 8, INK, 1.2)
			ci.draw_arc(head + Vector2(3 * s, -1 * s), 2.5 * s, 0, TAU, 8, INK, 1.2)
		"mullet":
			ci.draw_rect(Rect2(head + Vector2(-8 * s, -8 * s), Vector2(16 * s, 5 * s)), p.hair)
		_:
			if p.has("hair"):
				ci.draw_arc(head, 7.5 * s, PI * 1.1, PI * 1.9, 8, p.hair, 3.0 * s)


# --- Places ---------------------------------------------------------------------------------------

## The gaz bar: a red and white awning, the cream storefront with two windows and the door, the GAZ BAR
## neon on the roof (glowing when open, flashing on a good fill). `r` is its rect on screen.
static func store(ci: CanvasItem, r: Rect2, open: bool, flash: float, t: float) -> void:
	var glow := 0.45 + 0.1 * sin(t * 3.0) + flash * 0.4 if open else 0.0
	if glow > 0.0:
		ci.draw_circle(Vector2(r.get_center().x, r.position.y - 14), r.size.x * 0.22, Color(1.0, 0.35, 0.3, 0.12 * glow))
	box(ci, r, Color(1.0, 0.95, 0.84), 8.0, 4.0)
	var awning := Rect2(r.position, Vector2(r.size.x, r.size.y * 0.3))
	ci.draw_rect(awning, Color(0.91, 0.26, 0.23))
	var x := awning.position.x + 8.0
	while x < awning.end.x - 8.0:
		ci.draw_rect(Rect2(x, awning.position.y, 10, awning.size.y), Color.WHITE)
		x += 22.0
	box(ci, awning, Color(0, 0, 0, 0), 8.0, 4.0)
	var wy := awning.end.y + 6.0
	var wh := r.end.y - wy - 6.0
	box(ci, Rect2(r.position.x + 12, wy, r.size.x * 0.28, wh), Color(0.62, 0.82, 1.0), 4.0)
	box(ci, Rect2(r.position.x + 20 + r.size.x * 0.28, wy, r.size.x * 0.28, wh), Color(0.62, 0.82, 1.0), 4.0)
	for gx in [r.position.x + 20.0, r.position.x + 28 + r.size.x * 0.28]:  # window shine
		ci.draw_line(Vector2(gx, wy + 4), Vector2(gx + 8, wy + 4), SHINE, 3.0)
	box(ci, Rect2(r.end.x - 16 - r.size.x * 0.13, wy - 2, r.size.x * 0.13, wh + 8), Color(0.71, 0.4, 0.23), 4.0)
	var neon := Color(1.0, 0.36, 0.3) if open else Color(0.45, 0.2, 0.2)
	if flash > 0.0 and int(t * 12.0) % 2 == 0:
		neon = Color(1.0, 0.85, 0.3)
	label(ci, Vector2(r.get_center().x, r.position.y - 6), "GAZ BAR", 26, neon, true, 6)


## Chez Gaétan across the road: his green canopy over two pumps and his price sign. `centre` is the
## canopy's centre on screen; `pumps` where his two pumps stand.
static func rival(ci: CanvasItem, centre: Vector2, pumps: Array, k: float) -> void:
	box(ci, Rect2(centre + Vector2(-125, -44) * k, Vector2(250, 80) * k), Color(0.36, 0.38, 0.45), 10.0, 3.0)  # his apron
	box(ci, Rect2(centre + Vector2(-110, -40) * k, Vector2(220, 34) * k), Color(0.17, 0.71, 0.45), 6.0, 4.0)
	ci.draw_rect(Rect2(centre + Vector2(-108, -18) * k, Vector2(216, 6) * k), Color.WHITE)
	label(ci, centre + Vector2(0, -21) * k, "CHEZ GAÉTAN", int(15 * k), Color.WHITE, true, 4)
	for p in pumps:  # in front of the canopy, where his customers stop
		box(ci, Rect2(p + Vector2(-9, -22) * k, Vector2(18, 20) * k), Color(0.11, 0.54, 0.33), 3.0)
		box(ci, Rect2(p + Vector2(-6, -19) * k, Vector2(12, 7) * k), Color(1.0, 0.98, 0.9), 2.0, 1.5)
	var sign := centre + Vector2(150, -10) * k
	ci.draw_line(sign, sign + Vector2(0, 40) * k, INK, 6.0)
	box(ci, Rect2(sign + Vector2(-28, -24) * k, Vector2(56, 26) * k), Color(0.17, 0.71, 0.45), 5.0, 3.0)
	label(ci, sign + Vector2(0, -5) * k, "$1.99", int(13 * k), Color.WHITE, true, 3)


## The old pump in the corner (bottom left of the screen) with its dial on the tank.
static func old_pump(ci: CanvasItem, at: Vector2, tank_k: float, shake: float, alarm: bool) -> void:
	var p := at + Vector2(shake, 0)
	box(ci, Rect2(p + Vector2(-26, -10), Vector2(60, 100)), Color(0.91, 0.26, 0.23), 12.0, 4.0)
	disc(ci, p + Vector2(4, -22), 18.0, Color(1.0, 0.3, 0.25) if alarm else Color(1.0, 0.95, 0.84), 4.0)
	label(ci, p + Vector2(4, -16), "GAZ", 13, Color(0.91, 0.26, 0.23) if not alarm else Color.WHITE, true, 3)
	disc(ci, p + Vector2(4, 32), 17.0, Color(1.0, 0.98, 0.94), 3.0)
	var a := PI * (1.0 + clampf(tank_k, 0.0, 1.0))
	ci.draw_line(p + Vector2(4, 36), p + Vector2(4, 36) + Vector2.from_angle(a) * 12.0, RED, 3.0, true)
	ci.draw_circle(p + Vector2(4, 36), 3.0, INK)
	ci.draw_line(p + Vector2(-16, 70), p + Vector2(-4, 70), SHINE, 3.0)


## The God Pump's nozzle: a big red grip, a steel spout ending at `tip`, the lever squeezed when pouring.
static func nozzle(ci: CanvasItem, tip: Vector2, squeeze: bool, kick: float) -> void:
	ci.draw_set_transform(tip, 1.15, Vector2.ONE)  # hanging down toward where it pours
	box(ci, Rect2(-34, -10, 30, 14), Color(0.8, 0.82, 0.88), 5.0)  # the spout
	box(ci, Rect2(-96, -18, 66, 32), Color(0.91, 0.26, 0.23), 12.0, 4.0)  # the grip
	ci.draw_rect(Rect2(-90, -13, 34, 6), SHINE)
	var lever := 22.0 if not squeeze else 14.0
	ci.draw_arc(Vector2(-60, 14), lever, 0.2, PI - 0.2, 10, INK, 6.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A drone: blue rotors, a red body, a little light.
static func drone(ci: CanvasItem, at: Vector2, t: float, pouring: bool) -> void:
	var spin := absf(sin(t * 40.0))
	box(ci, Rect2(at + Vector2(-28, -8), Vector2(56, 8)), Color(0.62, 0.82, 1.0), 4.0, 2.5)
	ci.draw_line(at + Vector2(-26 * spin, -12), at + Vector2(-26 + 26 * (1.0 - spin), -12), Color(INK, 0.6), 2.0)
	box(ci, Rect2(at + Vector2(-12, -6), Vector2(24, 18)), Color(0.91, 0.26, 0.23), 6.0, 3.0)
	ci.draw_circle(at + Vector2(0, 4), 3.0, Color(1.0, 0.97, 0.7) if not pouring else GAS)


## An inflatable tube man: a wobbly tube from `base` to `head` with a face and flailing arms. `col`: his
## colour. `k`: 0 dancing .. 1 bent over (sucking or holding). `gulps`: gold bulges running down the tube.
static func tube_man(ci: CanvasItem, base: Vector2, head: Vector2, col: Color, k: float, t: float, gulps := false, open_mouth := 0.0) -> void:
	var mid := base.lerp(head, 0.5) + Vector2(cos(t * 4.0) * 22.0, -20) * (1.0 - k) + Vector2(0, -20) * k
	box(ci, Rect2(base + Vector2(-20, -12), Vector2(40, 18)), Color(0.82, 0.84, 0.9), 4.0)  # his blower
	var n := 14
	var pts: Array[Vector2] = []
	for i in n + 1:
		var u := float(i) / n
		pts.append(base.lerp(mid, u).lerp(mid.lerp(head, u), u))
	for pass_i in 2:
		for i in n + 1:
			var u := float(i) / n
			var w := 13.0
			if gulps:
				for g in 3:
					var at := fmod(t * 1.8 + g / 3.0, 1.0)
					w += 7.0 * exp(-pow((1.0 - u - at) * 9.0, 2.0)) * k
			ci.draw_circle(pts[i], w + (3.0 if pass_i == 0 else 0.0), INK if pass_i == 0 else col)
	if gulps:
		for g in 3:
			var at := fmod(t * 1.8 + g / 3.0, 1.0)
			ci.draw_circle(pts[clampi(int((1.0 - at) * n), 0, n)], 6.0 * k, Color(GAS, 0.9))
	for side in [-1.0, 1.0]:
		var shoulder := pts[n - 3]
		var hand := shoulder + Vector2(side * 30.0, -10.0 + sin(t * 9.0 + side) * 16.0 * (1.0 - k) + 18.0 * k)
		ci.draw_line(shoulder, hand, INK, 11.0, true)
		ci.draw_line(shoulder, hand, col, 6.0, true)
	disc(ci, head, 16.0, col.lightened(0.15))
	for side in [-1.0, 1.0]:
		ci.draw_circle(head + Vector2(side * 6.0, -5.0), 4.5, Color.WHITE)
		ci.draw_circle(head + Vector2(side * 6.0 + 1.0, -4.0), 2.2, INK)
	ci.draw_circle(head + Vector2(0, 7), 3.0 + 7.0 * open_mouth, INK)


# --- Upgrade props on the lot ---------------------------------------------------------------------

## How each upgrade shows on the lot: [shape, colour, text]. Shapes: sign (a board on a post), board
## (a sandwich board), machine (a box with a screen), tank (a horizontal fuel tank), pole (a lamp or an
## antenna), light (a traffic light), crate (a small thing on the ground), truck, net, arch, person.
const PROPS := {
	"flyers": ["board", Color(1.0, 0.85, 0.3), "PROMO"], "radio_ad": ["pole", Color(0.8, 0.82, 0.88), ""],
	"billboard": ["sign", Color(1.0, 0.85, 0.3), "GOD PUMP"], "traffic_light": ["light", Color(0.3, 0.3, 0.35), ""],
	"grocery": ["machine", Color(0.36, 0.7, 0.36), "ÉPICERIE"], "car_wash": ["arch", Color(0.4, 0.75, 1.0), "LAVE-AUTO"],
	"loto": ["machine", Color(0.68, 0.35, 0.95), "LOTO"], "tank_1": ["tank", Color(0.92, 0.92, 0.95), ""],
	"tank_2": ["tank", Color(0.92, 0.92, 0.95), ""], "tank_3": ["tank", Color(0.92, 0.92, 0.95), ""],
	"thermos": ["crate", Color(0.2, 0.55, 0.85), ""], "mom_lunch": ["crate", Color(0.9, 0.3, 0.3), ""],
	"permit": ["pole", Color(1.0, 0.9, 0.5), ""], "cousin": ["person", Color(0.3, 0.5, 0.85), "rejean"],
	"tip_sign": ["sign", Color(0.36, 0.8, 0.45), "TIPS"], "squeegee": ["crate", Color(0.4, 0.6, 0.95), ""],
	"coffee": ["machine", Color(0.55, 0.35, 0.2), "CAFÉ"], "radio": ["crate", Color(0.25, 0.25, 0.3), ""],
	"jukebox": ["machine", Color(1.0, 0.45, 0.65), "JUKE"], "lucky": ["sign", Color(1.0, 0.85, 0.3), "LUCK"],
	"morning_rush": ["crate", Color(1.0, 0.95, 0.9), ""], "jackpot": ["machine", Color(1.0, 0.3, 0.3), "777"],
	"nest_egg": ["crate", Color(0.9, 0.85, 0.7), ""], "contract": ["sign", Color(0.95, 0.95, 0.9), "CONTRAT"],
	"premium": ["sign", Color(0.95, 0.25, 0.25), "SUPER"], "truck_friend": ["truck", Color(0.92, 0.92, 0.95), "31"],
	"big_cards": ["crate", Color(0.3, 0.6, 0.35), ""], "reroll": ["crate", Color(1.0, 1.0, 1.0), ""],
	"slot": ["machine", Color(0.95, 0.8, 0.4), "BLING"], "head_start": ["machine", Color(0.45, 0.5, 0.6), "DRONE"],
	"drive_thru": ["machine", Color(0.55, 0.35, 0.2), "AU VOLANT"], "hockey": ["net", Color(0.95, 0.25, 0.25), ""],
	"loyalty": ["sign", Color(1.0, 0.56, 0.78), "FIDÉLITÉ"], "night_neons": ["sign", Color(0.3, 0.9, 1.0), "OUVERT"],
	"drone_hangar": ["machine", Color(0.45, 0.5, 0.6), "HANGAR"], "chip_truck": ["truck", Color(1.0, 0.85, 0.3), "PATATES"],
	"price_board": ["sign", Color(0.95, 0.95, 0.9), "$1.89"], "forward_contract": ["sign", Color(0.95, 0.95, 0.9), "TERME"],
	"bulk": ["crate", Color(0.35, 0.55, 0.35), ""], "used_tanker": ["truck", Color(0.7, 0.65, 0.55), "USAGÉ"],
	"tank_gauge": ["pole", Color(1.0, 0.3, 0.25), ""], "clamp_1": ["crate", Color(1.0, 0.85, 0.2), ""],
	"clamp_2": ["crate", Color(1.0, 0.85, 0.2), ""], "litter": ["crate", Color(0.85, 0.75, 0.55), ""],
}


## An upgrade's prop standing on `feet` (screen px), popping in by `pop` (0..1, elastic).
static func prop(ci: CanvasItem, id: String, feet: Vector2, t: float, pop := 1.0) -> void:
	var spec: Array = PROPS.get(id, ["crate", Color(0.8, 0.8, 0.8), ""])
	var s := 1.0 + 0.3 * exp(-5.0 * pop) * sin(pop * PI * 4.0) if pop < 1.0 else 1.0
	var col: Color = spec[1]
	var text: String = spec[2]
	ci.draw_circle(feet + Vector2(0, 1), 12.0 * s, Color(0, 0, 0, 0.18))
	match spec[0]:
		"sign":
			ci.draw_line(feet, feet + Vector2(0, -30 * s), INK, 5.0)
			var w := maxf(GodUI.font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 14.0, 30.0) * s
			box(ci, Rect2(feet + Vector2(-w * 0.5, -52 * s), Vector2(w, 24 * s)), col, 5.0, 3.0)
			ci.draw_string(GodUI.font(), feet + Vector2(-w * 0.5 + 7 * s, -35 * s), text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(11 * s), INK)
		"board":
			poly(ci, PackedVector2Array([feet + Vector2(-14, 0) * s, feet + Vector2(-8, -34) * s, feet + Vector2(8, -34) * s, feet + Vector2(14, 0) * s]), col)
			ci.draw_string(GodUI.font(), feet + Vector2(-13, -16) * s, text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(8 * s), INK)
		"machine":
			box(ci, Rect2(feet + Vector2(-16, -44) * s, Vector2(32, 44) * s), col, 6.0, 3.0)
			box(ci, Rect2(feet + Vector2(-11, -38) * s, Vector2(22, 14) * s), Color(0.62, 0.82, 1.0), 3.0, 2.0)
			var w := GodUI.font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			ci.draw_string(GodUI.font(), feet + Vector2(-w * 0.5, -12 * s), text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(8 * s), Color.WHITE)
		"tank":
			box(ci, Rect2(feet + Vector2(-30, -26) * s, Vector2(60, 24) * s), col, 12.0, 3.0)
			ci.draw_rect(Rect2(feet + Vector2(-30, -16) * s, Vector2(60, 5) * s), Color(0.91, 0.26, 0.23))
			for x in [-18.0, 18.0]:
				ci.draw_line(feet + Vector2(x, -4) * s, feet + Vector2(x, 0) * s, INK, 4.0)
		"pole":
			ci.draw_line(feet, feet + Vector2(0, -56 * s), INK, 5.0)
			disc(ci, feet + Vector2(0, -58 * s), 7.0 * s, col, 2.5)
		"light":
			ci.draw_line(feet, feet + Vector2(0, -40 * s), INK, 5.0)
			box(ci, Rect2(feet + Vector2(-8, -70) * s, Vector2(16, 34) * s), col, 4.0, 3.0)
			var lit := int(t) % 3
			for i in 3:
				ci.draw_circle(feet + Vector2(0, (-64 + i * 10) * s), 3.5 * s, [Color(1, 0.3, 0.25), Color(1, 0.85, 0.2), Color(0.3, 0.95, 0.45)][i] if i == lit else Color(0.2, 0.2, 0.22))
		"truck":
			box(ci, Rect2(feet + Vector2(-34, -30) * s, Vector2(48, 26) * s), col, 6.0, 3.0)
			box(ci, Rect2(feet + Vector2(14, -26) * s, Vector2(20, 22) * s), col.darkened(0.15), 5.0, 3.0)
			box(ci, Rect2(feet + Vector2(20, -23) * s, Vector2(10, 8) * s), GLASS, 2.0, 2.0)
			for x in [-22.0, 22.0]:
				disc(ci, feet + Vector2(x, -3) * s, 5.0 * s, Color(0.3, 0.3, 0.33), 2.0)
			ci.draw_string(GodUI.font(), feet + Vector2(-30, -12) * s, text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(9 * s), INK)
		"arch":
			box(ci, Rect2(feet + Vector2(-34, -56) * s, Vector2(68, 14) * s), col, 5.0, 3.0)
			for x in [-30.0, 30.0]:
				box(ci, Rect2(feet + Vector2(x - 4, -44) * s, Vector2(8, 44) * s), col.darkened(0.2), 3.0, 2.5)
			ci.draw_string(GodUI.font(), feet + Vector2(-30, -46) * s, text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(8 * s), Color.WHITE)
		"net":
			box(ci, Rect2(feet + Vector2(-20, -24) * s, Vector2(40, 24) * s), Color(1, 1, 1, 0.5), 4.0, 3.0)
			box(ci, Rect2(feet + Vector2(-20, -24) * s, Vector2(40, 5) * s), col, 2.0, 2.0)
		"person":
			person(ci, feet, text, "stand", t, false, s)
		_:
			box(ci, Rect2(feet + Vector2(-11, -18) * s, Vector2(22, 18) * s), col, 4.0, 3.0)
			ci.draw_line(feet + Vector2(-6, -14) * s, feet + Vector2(4, -14) * s, SHINE, 2.5)
