class_name Treehouse
extends Node2D
## A tree Summer builds in. Draws itself from the set of parts in
## GameState.built rather than from a level number, so any combination of
## builds looks right. Three of these stand in the home grove: the home tree,
## the second tree across the rope bridge, and the far third tree.
##
## `site` picks which parts belong to this tree ("home", "two", "three");
## the home tree also draws the "ground" parts scattered round its base.
##
## Set `preview_id` to draw one unbuilt part as a translucent ghost — that is
## how the build board shows her what she is about to make.

const TRUNK := Color("8a6a52")
const LEAF := Color("94c489")
const PLANK := Color("c9a06c")

## Where each storey sits. The roof always caps whatever is tallest. Kept
## compact enough that the finished mansion still fits on screen with her
## standing at the foot of the tree.
const CABIN_TOP := -340.0
const STOREY2_TOP := -420.0
const TOWER_TOP := -488.0

var site := "home"
var preview_id := ""
var ghost := false          ## draw the whole tree faded (the board's backdrop)
var ghost_only := false     ## draw ONLY preview_id — the build board's ghost layer

var _motion: Motion = null


func _ready() -> void:
	_motion = Motion.new()
	_motion.house = self
	add_child(_motion)


## The museum door, only on the home tree. Generous, because it is tapped
## directly in the world rather than through a HUD button.
func door_rect() -> Rect2:
	return Rect2(global_position + Vector2(-52, -116), Vector2(104, 116))


func has(id: String) -> bool:
	if id == preview_id:
		return false
	return GameState.has_built(id)


## Local position of a part's build spot — where the board puts its badge and
## where pieces fly to during a build.
func spot(id: String) -> Vector2:
	return BuildDefs.spot_of(id)


func refresh() -> void:
	queue_redraw()
	if _motion != null:
		_motion.queue_redraw()


## Does a part belong to this tree?
func _mine(id: String) -> bool:
	var s := BuildDefs.site_of(id)
	if site == "home":
		return s == "home" or s == "ground"
	return s == site


## The colour a part is made of, by material tier.
func _mat(id: String) -> Color:
	match GameState.tier_of(id):
		1: return Color("b3936a")
		3: return Color("a87c4e")
		4: return Color(str(GameState.paint_colours.get(id, "e8918c")))
		_: return PLANK


## How tall the house has grown — the roof sits here.
func _top() -> float:
	var pre := "" if site == "home" else site
	if site == "home":
		if has("tower"): return TOWER_TOP
		if has("storey2"): return STOREY2_TOP
		if has("cabin"): return CABIN_TOP
	elif site == "two":
		if has("tree2_cabin"): return CABIN_TOP
	elif site == "three":
		if has("tree3_tower"): return STOREY2_TOP
		if has("tree3_platform"): return CABIN_TOP
	return 0.0


func _draw() -> void:
	if ghost_only:
		# Only the part she is about to build, drawn translucent exactly where
		# it will go. The board stacks one of these over the real tree.
		if preview_id != "" and _mine(preview_id):
			_draw_part(preview_id)
		return

	var fade := 0.45 if ghost else 1.0
	modulate.a = fade

	DrawKit.soft_shadow(self, Vector2(0, 3), 92.0 if site == "home" else 74.0, 0.16)
	_draw_trunk()
	_draw_canopy()

	if site == "home":
		_draw_home()
	elif site == "two":
		_draw_second()
	else:
		_draw_third()

	# a couple of leafy blobs in front, so the house nestles into the tree
	DrawKit.blob(self, Vector2(-104, -300), 40.0, 34.0, LEAF.darkened(0.14), 41)
	DrawKit.blob(self, Vector2(108, -312), 36.0, 30.0, LEAF.darkened(0.08), 42)


# --- the tree itself ---------------------------------------------------------

func _draw_trunk() -> void:
	var w := 1.0 if site == "home" else 0.82
	draw_polygon(PackedVector2Array([
		Vector2(-48 * w, 2), Vector2(-30 * w, -26), Vector2(-26 * w, -300),
		Vector2(26 * w, -300), Vector2(32 * w, -26), Vector2(50 * w, 2),
	]), PackedColorArray([TRUNK]))
	draw_polygon(PackedVector2Array([
		Vector2(-48 * w, 2), Vector2(-30 * w, -26), Vector2(-26 * w, -300),
		Vector2(-12 * w, -300), Vector2(-16 * w, -30), Vector2(-30 * w, 2),
	]), PackedColorArray([TRUNK.darkened(0.14)]))
	draw_polygon(PackedVector2Array([
		Vector2(14 * w, -300), Vector2(26 * w, -300), Vector2(32 * w, -26),
		Vector2(40 * w, 2), Vector2(26 * w, 2), Vector2(22 * w, -30),
	]), PackedColorArray([TRUNK.lightened(0.09)]))
	for bark in [[-8.0, -130.0, -5.0, -250.0], [6.0, -110.0, 9.0, -210.0], [-2.0, -30.0, -6.0, -110.0]]:
		draw_line(Vector2(bark[0] * w, bark[1]), Vector2(bark[2] * w, bark[3]), TRUNK.darkened(0.22), 2.5)
	DrawKit.ellipse(self, Vector2(14 * w, -150), 6.0, 8.5, TRUNK.darkened(0.25))
	DrawKit.ellipse(self, Vector2(14 * w, -150), 3.0, 4.5, TRUNK.darkened(0.4))
	DrawKit.tuft(self, Vector2(-34, 2), 14.0, Color("7fb87a"), 91)
	DrawKit.tuft(self, Vector2(52, 4), 12.0, Color("74a86e"), 92)


func _draw_canopy() -> void:
	var top := _top()
	var cy := minf(-330.0, top - 30.0)
	DrawKit.canopy(self, Vector2(-6, cy), 128.0, 100.0, LEAF, 21)
	DrawKit.blob(self, Vector2(-100, cy + 60.0), 52.0, 44.0, LEAF.darkened(0.1), 22)
	DrawKit.blob(self, Vector2(102, cy + 52.0), 48.0, 42.0, LEAF.lightened(0.06), 23)
	if top < STOREY2_TOP:
		DrawKit.blob(self, Vector2(-86, cy + 130.0), 44.0, 36.0, LEAF.darkened(0.05), 24)
		DrawKit.blob(self, Vector2(92, cy + 140.0), 40.0, 34.0, LEAF.darkened(0.12), 25)


# --- the home tree -----------------------------------------------------------

func _draw_home() -> void:
	if has("workshop"):
		_draw_workshop()
	if has("platform"):
		_draw_platform("platform", -262.0, 88.0)
	if has("deck_side"):
		_draw_deck("deck_side", -1.0)
	if has("deck_front"):
		_draw_deck("deck_front", 1.0)
	if has("balcony"):
		_draw_balcony()

	if has("cabin"):
		_draw_storey("cabin", CABIN_TOP, -260.0, 62.0)
	if has("storey2"):
		_draw_storey("storey2", STOREY2_TOP, CABIN_TOP, 56.0)
	if has("tower"):
		_draw_storey("tower", TOWER_TOP, STOREY2_TOP, 42.0)
	if has("cabin"):
		_draw_roof(_top(), has("mansion_roof"))

	_draw_access()
	_draw_door()
	_draw_decorations()


func _draw_second() -> void:
	if has("tree2_platform"):
		_draw_platform("tree2_platform", -262.0, 74.0)
	if has("tree2_deck"):
		_draw_deck("tree2_deck", -1.0)
	if has("tree2_cabin"):
		_draw_storey("tree2_cabin", CABIN_TOP, -260.0, 52.0)
	if has("tree2_loft"):
		_draw_storey("tree2_loft", STOREY2_TOP, CABIN_TOP, 44.0)
	if has("tree2_cabin"):
		_draw_roof(_top(), has("tree2_roof"))
	if has("crows_nest"):
		_draw_crows_nest()
	if has("tree2_spyglass"):
		_draw_spyglass()
	if has("tree2_platform"):
		_draw_rope_ladder(-60.0, -252.0, 0.0)
	if has("tree2_net"):
		_draw_net(-64.0, -252.0)
	if has("tree2_pole"):
		_draw_pole(58.0)
	if has("tree2_swing"):
		_draw_swing()
	if has("tree2_hammock"):
		_draw_hammock()
	if has("tree2_bunk"):
		_draw_window(Vector2(-30, -300), 16.0)
	_draw_decorations()


func _draw_third() -> void:
	if has("tree3_platform"):
		_draw_platform("tree3_platform", -262.0, 78.0)
	if has("tree3_deck"):
		_draw_deck("tree3_deck", 1.0)
	if has("tree3_netbridge"):
		_draw_rope_walk()
	if has("tree3_tower"):
		_draw_storey("tree3_tower", STOREY2_TOP, -260.0, 50.0)
	if has("tree3_top"):
		_draw_storey("tree3_top", TOWER_TOP, STOREY2_TOP, 40.0)
	if has("tree3_tower"):
		_draw_roof(_top(), true)
	if has("tree3_spire"):
		_draw_spire()
	if has("tree3_telescope"):
		_draw_big_telescope()
	if has("tree3_lookout"):
		_draw_window(Vector2(-34, -390), 15.0)
	if has("tree3_beds"):
		_draw_window(Vector2(-32, -300), 16.0)
	if has("tree3_stairs"):
		_draw_spiral()
	if has("tree3_platform"):
		_draw_rope_ladder(-60.0, -252.0, 0.0)
	if has("tree3_rope"):
		_draw_knot_rope()
	if has("tree3_zip"):
		_draw_zip_home()
	_draw_decorations()


# --- parts -------------------------------------------------------------------

func _draw_platform(id: String, y: float, half: float) -> void:
	var c := _mat(id)
	draw_rect(Rect2(-half, y, half * 2.0, 13), c.darkened(0.18))
	draw_rect(Rect2(-half, y, half * 2.0, 5), c.darkened(0.05))
	for jx in [-half * 0.8, -half * 0.27, half * 0.27, half * 0.8]:
		draw_line(Vector2(jx, y + 13), Vector2(jx * 0.55, y + 47), c.darkened(0.3), 6.0)
	if GameState.tier_of(id) >= 3:
		draw_line(Vector2(-half, y + 13), Vector2(half, y + 13), c.darkened(0.34), 2.5)


func _draw_storey(id: String, top: float, bottom: float, half: float) -> void:
	var c := _mat(id)
	var h := bottom - top
	DrawKit.rounded_rect(self, Rect2(-half, top, half * 2.0, h), 8.0, c)
	var rows := int(h / 21.0)
	for i in rows:
		var py := top + 8.0 + i * 21.0
		draw_line(Vector2(-half + 4, py), Vector2(half - 4, py), c.darkened(0.16), 2.0)
		draw_line(Vector2(-half + 4, py + 2), Vector2(half - 4, py + 2), c.lightened(0.1), 1.2)
	draw_rect(Rect2(-half, top, 7, h), c.darkened(0.12))
	draw_rect(Rect2(half - 7, top, 7, h), c.lightened(0.06))
	if GameState.tier_of(id) >= 3:
		# good timber gets proper corner trim
		draw_rect(Rect2(-half - 3, top, 3, h), c.darkened(0.3))
		draw_rect(Rect2(half, top, 3, h), c.darkened(0.3))
	_draw_window(Vector2(0, top + h * 0.5), minf(23.0, half * 0.42))


func _draw_window(p: Vector2, r: float) -> void:
	draw_circle(p, r, Color("8a6a44"))
	draw_circle(p, r * 0.83, Color("ffe9b8"))
	draw_circle(p, r * 0.57, Color("ffdf98"))
	draw_line(p - Vector2(r * 0.83, 0), p + Vector2(r * 0.83, 0), Color("8a6a44"), 2.5)
	draw_line(p - Vector2(0, r * 0.83), p + Vector2(0, r * 0.83), Color("8a6a44"), 2.5)
	draw_arc(p, r * 0.67, PI * 1.1, PI * 1.5, 8, Color(1, 1, 1, 0.55), 2.5, true)


func _draw_roof(top: float, mansion: bool) -> void:
	var half := 78.0
	var peak := top - 54.0
	if mansion:
		half = 92.0
		peak = top - 60.0
	draw_polygon(PackedVector2Array([
		Vector2(-half, top), Vector2(half, top), Vector2(0, peak),
	]), PackedColorArray([Color("a9743f")]))
	draw_polygon(PackedVector2Array([
		Vector2(-half * 0.85, top - 4), Vector2(0, peak + 4), Vector2(0, peak + 20),
	]), PackedColorArray([Color("b57f4d")]))
	draw_polygon(PackedVector2Array([
		Vector2(half * 0.85, top - 4), Vector2(0, peak + 4), Vector2(half * 0.38, peak + 26),
	]), PackedColorArray([Color("c28a56")]))
	draw_line(Vector2(-half, top), Vector2(half, top), Color(0.35, 0.24, 0.15, 0.4), 4.0)
	if mansion:
		# gables and a finial — the silhouette that says "mansion"
		for sx in [-1.0, 1.0]:
			draw_polygon(PackedVector2Array([
				Vector2(sx * 30, top - 18), Vector2(sx * 66, top - 18), Vector2(sx * 48, top - 44),
			]), PackedColorArray([Color("b57f4d")]))
			_draw_window(Vector2(sx * 48, top - 26), 8.0)
		draw_line(Vector2(0, peak), Vector2(0, peak - 12), Color("8a6a44"), 3.0)
		DrawKit.star(self, Vector2(0, peak - 16), 7.0, Color("ffd98a"))


func _draw_deck(id: String, dir: float) -> void:
	var c := _mat(id)
	var x0 := 60.0 * dir
	var x1 := 122.0 * dir
	draw_line(Vector2(x1 * 0.92, -246), Vector2(30 * dir, -180), c.darkened(0.3), 7.0)
	var left := minf(x0, x1)
	draw_rect(Rect2(left, -262, absf(x1 - x0), 13), c.darkened(0.18))
	draw_rect(Rect2(left, -262, absf(x1 - x0), 5), c.darkened(0.02))
	for i in 3:
		var rx := lerpf(x0, x1, i / 2.0)
		draw_line(Vector2(rx, -262), Vector2(rx, -288), c.darkened(0.25), 4.0)
	draw_line(Vector2(x0, -288), Vector2(x1, -288), c.darkened(0.1), 5.0)
	draw_line(Vector2(x0, -290), Vector2(x1, -290), c.lightened(0.1), 1.5)
	if dir > 0.0:
		DrawKit.rounded_rect(self, Rect2(96, -300, 9, 9), 2.0, Color("e8918c"))
		draw_arc(Vector2(106, -295), 3.0, -PI * 0.5, PI * 0.5, 6, Color("d97f7a"), 1.6, true)


func _draw_balcony() -> void:
	var c := _mat("balcony")
	draw_rect(Rect2(-62, -252, 124, 10), c.darkened(0.2))
	for i in 9:
		var rx := lerpf(-58.0, 58.0, i / 8.0)
		draw_line(Vector2(rx, -252), Vector2(rx, -274), c.darkened(0.25), 3.0)
	draw_line(Vector2(-62, -274), Vector2(62, -274), c.darkened(0.08), 4.5)
	draw_line(Vector2(-62, -276), Vector2(62, -276), c.lightened(0.12), 1.5)


func _draw_access() -> void:
	if has("stairs_spiral"):
		_draw_spiral()
	elif has("stairs_wood"):
		_draw_stairs()
	else:
		_draw_ladder()
	if has("lift_bucket"):
		_draw_lift()
	if has("slide"):
		_draw_slide()


func _draw_ladder() -> void:
	draw_line(Vector2(-17, -44), Vector2(-17, -252), PLANK.darkened(0.28), 5.0)
	draw_line(Vector2(17, -44), Vector2(17, -252), PLANK.darkened(0.28), 5.0)
	draw_line(Vector2(-15, -44), Vector2(-15, -252), PLANK.darkened(0.1), 2.0)
	draw_line(Vector2(19, -44), Vector2(19, -252), PLANK.darkened(0.1), 2.0)
	for i in 6:
		var ly := -60.0 - i * 34.0
		draw_line(Vector2(-16, ly), Vector2(16, ly), PLANK.darkened(0.24), 5.0)
		draw_line(Vector2(-16, ly - 2), Vector2(16, ly - 2), PLANK.lightened(0.06), 1.8)


func _draw_rope_ladder(x: float, top: float, bottom: float) -> void:
	for lx in [x, x + 20.0]:
		draw_line(Vector2(lx, top), Vector2(lx + 3, bottom), Color("55763f"), 3.0)
	var n := int((bottom - top) / 26.0)
	for i in n:
		var ly := top + 12.0 + i * 26.0
		draw_line(Vector2(x - 1 + i * 0.6, ly), Vector2(x + 21 + i * 0.6, ly), Color("a97e54"), 4.0)


func _draw_stairs() -> void:
	var c := _mat("stairs_wood")
	var steps := 9
	for i in steps:
		var u := i / float(steps - 1)
		var sx := lerpf(-96.0, -14.0, u)
		var sy := lerpf(-6.0, -252.0, u)
		draw_rect(Rect2(sx - 16, sy, 34, 8), c.darkened(0.16))
		draw_rect(Rect2(sx - 16, sy, 34, 3), c.lightened(0.06))
		draw_line(Vector2(sx - 12, sy + 8), Vector2(sx - 12, sy + 26), c.darkened(0.34), 3.0)
	draw_line(Vector2(-104, -22), Vector2(-20, -268), c.darkened(0.22), 4.0)
	for i in 5:
		var u := i / 4.0
		draw_line(Vector2(lerpf(-100.0, -16.0, u), lerpf(-10.0, -256.0, u)),
			Vector2(lerpf(-104.0, -20.0, u), lerpf(-30.0, -276.0, u)), c.darkened(0.28), 2.5)


func _draw_spiral() -> void:
	var c := _mat("stairs_spiral")
	draw_line(Vector2(0, -10), Vector2(0, -256), c.darkened(0.35), 7.0)
	for i in 14:
		var u := i / 13.0
		var a := u * TAU * 1.6
		var sy := lerpf(-16.0, -252.0, u)
		var sx := cos(a) * 34.0
		var depth := (sin(a) + 1.0) * 0.5
		var col := c.darkened(0.28 - depth * 0.22)
		draw_rect(Rect2(sx - 17, sy, 34, 7), col)
		draw_rect(Rect2(sx - 17, sy, 34, 2.5), col.lightened(0.12))
	draw_line(Vector2(0, -10), Vector2(0, -256), c.darkened(0.1), 2.0)


func _draw_lift() -> void:
	var rope := Color("9a8055")
	draw_line(Vector2(-104, -252), Vector2(-104, -300), rope, 2.5)
	draw_line(Vector2(-118, -300), Vector2(-90, -300), PLANK.darkened(0.3), 5.0)
	draw_circle(Vector2(-104, -300), 7.0, Color("7a8b9c"))
	draw_circle(Vector2(-104, -300), 3.0, Color("aab8c4"))
	draw_line(Vector2(-104, -293), Vector2(-104, -206), rope, 2.5)
	var c := _mat("lift_bucket")
	DrawKit.rounded_rect(self, Rect2(-124, -206, 40, 34), 5.0, c.darkened(0.1))
	draw_rect(Rect2(-124, -206, 40, 6), c.lightened(0.08))
	draw_arc(Vector2(-104, -206), 20.0, PI, TAU, 12, c.darkened(0.34), 3.0, true)


func _draw_slide() -> void:
	var c := Color(str(GameState.paint_colours.get("slide", "6fb3d2")))
	var pts := PackedVector2Array()
	var under := PackedVector2Array()
	for i in 13:
		var u := i / 12.0
		var sx := lerpf(122.0, 214.0, u)
		var sy := lerpf(-254.0, -6.0, u * u * 0.82 + u * 0.18)
		pts.append(Vector2(sx, sy))
		under.append(Vector2(sx + 9, sy + 9))
	draw_polyline(under, c.darkened(0.3), 13.0)
	draw_polyline(pts, c, 11.0)
	draw_polyline(pts, c.lightened(0.22), 3.5)
	draw_line(Vector2(196, -70), Vector2(196, -6), PLANK.darkened(0.3), 5.0)


func _draw_door() -> void:
	var arch := Color("5e4433")
	var face := Color("7d5c44")
	if has("painted_door"):
		face = Color(str(GameState.paint_colours.get("painted_door", "e8918c")))
		arch = face.darkened(0.34)
	DrawKit.rounded_rect(self, Rect2(-29, -90, 58, 90), 22.0, arch)
	DrawKit.rounded_rect(self, Rect2(-22, -84, 44, 84), 17.0, face)
	for dx in [-11.0, 0.0, 11.0]:
		draw_line(Vector2(dx, -80), Vector2(dx, -2), face.darkened(0.16), 2.0)
	draw_arc(Vector2(0, -62), 16.0, PI, TAU, 12, arch.darkened(0.12), 2.5, true)
	draw_circle(Vector2(13, -40), 4.0, Color("d9b45c"))
	draw_circle(Vector2(12, -41), 1.8, Color("f0d9a0"))
	for st in [[-40.0, 4.0, 7.0], [42.0, 6.0, 6.0], [-52.0, 8.0, 4.5]]:
		DrawKit.ellipse(self, Vector2(st[0], st[1]), st[2], st[2] * 0.6, Color("b8a58c"))
		DrawKit.ellipse(self, Vector2(st[0] - 1, st[1] - 1.5), st[2] * 0.6, st[2] * 0.35, Color("cbb59a"))


func _draw_workshop() -> void:
	# Sits well clear of the trunk so the bucket lift and the stairs have room.
	var c := _mat("workshop")
	DrawKit.rounded_rect(self, Rect2(-320, -118, 108, 118), 6.0, c.darkened(0.06))
	for i in 4:
		var py := -108.0 + i * 26.0
		draw_line(Vector2(-316, py), Vector2(-216, py), c.darkened(0.2), 2.0)
	draw_polygon(PackedVector2Array([
		Vector2(-330, -118), Vector2(-202, -118), Vector2(-266, -158),
	]), PackedColorArray([Color("a9743f")]))
	draw_rect(Rect2(-300, -84, 34, 84), Color("6e5039"))
	draw_rect(Rect2(-296, -80, 26, 80), Color("8a6a52"))
	_draw_window(Vector2(-238, -80), 15.0)
	# a workbench with a saw leaning against the wall
	draw_rect(Rect2(-206, -46, 44, 8), c.darkened(0.24))
	draw_line(Vector2(-200, -38), Vector2(-200, 0), c.darkened(0.32), 4.0)
	draw_line(Vector2(-168, -38), Vector2(-168, 0), c.darkened(0.32), 4.0)
	draw_line(Vector2(-194, -46), Vector2(-188, -84), Color("9a7a55"), 4.0)
	draw_polygon(PackedVector2Array([
		Vector2(-190, -84), Vector2(-176, -92), Vector2(-174, -78),
	]), PackedColorArray([Color("8a95a0")]))


func _draw_crows_nest() -> void:
	var c := Color("a87c4e")
	draw_line(Vector2(0, -352), Vector2(0, -424), TRUNK.darkened(0.1), 9.0)
	draw_rect(Rect2(-32, -434, 64, 12), c.darkened(0.16))
	for i in 7:
		var rx := lerpf(-28.0, 28.0, i / 6.0)
		draw_line(Vector2(rx, -434), Vector2(rx, -458), c.darkened(0.24), 3.0)
	draw_line(Vector2(-32, -458), Vector2(32, -458), c.darkened(0.06), 4.5)
	DrawKit.star(self, Vector2(0, -474), 8.0, Color("ffd98a"))


func _draw_decorations() -> void:
	for id in BuildDefs.ids_on_track("decoration"):
		if _mine(id) and has(id):
			_draw_decoration(id)


## One decoration. Split out so the build board's ghost layer can draw a single
## part on its own, exactly where it would land.
func _draw_decoration(id: String) -> void:
	match id:
		"tree2_flag":
			# a flag on the loft gable
			draw_line(Vector2(-46, -376), Vector2(-46, -424), Color("8a7355"), 3.0)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-46, -422), Vector2(-14, -414), Vector2(-46, -406),
			]), Color("e8918c"))
		"tree2_lanterns":
			# little lanterns strung along the platform edge
			for i in 5:
				var lx := -56.0 + i * 28.0
				draw_line(Vector2(lx, -262), Vector2(lx, -252), Color("8a7355"), 1.6)
				DrawKit.ellipse(self, Vector2(lx, -246), 6.0, 8.0,
					[Color("ffd98a"), Color("f2b8cf"), Color("a8d5a2")][i % 3])
				draw_circle(Vector2(lx, -246), 2.6, Color("fff8ec"))
		"tree2_bunting":
			for i in 7:
				var v := i / 6.0
				var bx := -56.0 + 112.0 * v
				var by := -330.0 + sin(v * PI) * 9.0
				draw_colored_polygon(PackedVector2Array([
					Vector2(bx - 6, by), Vector2(bx + 6, by), Vector2(bx, by + 12),
				]), [Color("e8918c"), Color("8fc48a"), Color("6fb3d2")][i % 3])
			draw_line(Vector2(-56, -330), Vector2(56, -330), Color("9a8055"), 1.6)
		"tree2_windsock":
			# a windsock on a pole, always pointing away from the tree
			draw_line(Vector2(74, -290), Vector2(74, -256), Color("8a7355"), 3.0)
			for i in 4:
				var w := 11.0 - i * 2.0
				DrawKit.ellipse(self, Vector2(78.0 + i * 11.0, -288.0), 5.0, w,
					Color("e8918c") if i % 2 == 0 else Color("fff8ec"))
		"tree3_flag":
			draw_line(Vector2(-44, -444), Vector2(-44, -492), Color("8a7355"), 3.0)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-44, -490), Vector2(-10, -482), Vector2(-44, -474),
			]), Color("6fb3d2"))
		"tree3_lights":
			# a string of lights looped along the platform
			for i in 9:
				var v := i / 8.0
				var lx := -70.0 + 140.0 * v
				var ly := -266.0 + sin(v * PI) * 12.0
				draw_circle(Vector2(lx, ly), 3.6,
					[Color("ffd98a"), Color("f2b8cf"), Color("a8d5a2"), Color("8fb7d9")][i % 4])
			var wire := PackedVector2Array()
			for i in 9:
				var v := i / 8.0
				wire.append(Vector2(-70.0 + 140.0 * v, -270.0 + sin(v * PI) * 12.0))
			draw_polyline(wire, Color("9a8055"), 1.5)
		"tree3_vane":
			draw_line(Vector2(46, -466), Vector2(46, -504), Color("8a7355"), 3.0)
			draw_line(Vector2(30, -496), Vector2(62, -496), Color("8a7355"), 2.0)
			draw_colored_polygon(PackedVector2Array([
				Vector2(46, -512), Vector2(62, -502), Vector2(46, -496),
			]), Color("c9915c"))
		"name_sign":
			# hangs under the platform, so it stays put however tall she builds
			var c := _mat("name_sign")
			DrawKit.rounded_rect(self, Rect2(-52, -246, 104, 22), 5.0, c.darkened(0.08))
			DrawKit.rounded_rect(self, Rect2(-48, -243, 96, 16), 4.0, c.lightened(0.12))
			var font := ThemeDB.fallback_font
			var w := font.get_string_size("summer", HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
			draw_string(font, Vector2(-w / 2.0, -229), "summer",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("6b4f38"))
		"flower_box":
			draw_rect(Rect2(-60, -292, 30, 8), Color("8a6242"))
			for i in 3:
				var fxp := -54.0 + i * 9.0
				draw_circle(Vector2(fxp, -294), 3.4, [Color("f2b8cf"), Color("ffe6b3"), Color("c4b8e8")][i])
				draw_circle(Vector2(fxp, -294), 1.4, Color("ffd98a"))
		"bird_box":
			DrawKit.rounded_rect(self, Rect2(-108, -344, 22, 20), 3.0, Color("d9b45c"))
			draw_polygon(PackedVector2Array([
				Vector2(-111, -344), Vector2(-83, -344), Vector2(-97, -358),
			]), PackedColorArray([Color("a9743f")]))
			draw_circle(Vector2(-97, -335), 4.0, Color("5e4433"))
			draw_line(Vector2(-97, -324), Vector2(-97, -312), Color("8a6a52"), 3.0)
		"hammock":
			var a := Vector2(64, -286)
			var b := Vector2(140, -278)
			var hp := PackedVector2Array()
			for i in 13:
				var u := i / 12.0
				hp.append(a.lerp(b, u) + Vector2(0, sin(u * PI) * 22.0))
			draw_polyline(hp, Color("e8b6a0"), 9.0)
			draw_polyline(hp, Color("f2cdb8"), 4.0)
		"tyre_swing":
			draw_line(Vector2(112, -300), Vector2(112, -142), Color("6b5a3f"), 3.0)
			draw_arc(Vector2(112, -122), 20.0, 0, TAU, 22, Color("4a4a4f"), 8.0, true)
			draw_arc(Vector2(112, -122), 20.0, PI * 1.1, PI * 1.6, 8, Color("6a6a70"), 3.0, true)
		"lantern":
			draw_line(Vector2(-46, -104), Vector2(-46, -96), Color("6b5a3f"), 2.5)
			DrawKit.rounded_rect(self, Rect2(-54, -96, 16, 20), 3.0, Color("8a95a0"))
			draw_rect(Rect2(-51, -93, 10, 14), Color("ffdf98"))
			draw_circle(Vector2(-46, -86), 9.0, Color(1.0, 0.87, 0.6, 0.22))
		"letterbox":
			draw_line(Vector2(96, -40), Vector2(96, 2), Color("8a6a52"), 6.0)
			DrawKit.rounded_rect(self, Rect2(82, -62, 28, 24), 5.0, Color("c85f56"))
			draw_rect(Rect2(86, -54, 20, 4), Color("8f3f38"))
			draw_line(Vector2(110, -60), Vector2(110, -72), Color("d9b45c"), 3.0)
		"welcome_mat":
			DrawKit.rounded_rect(self, Rect2(-26, 2, 52, 13), 3.0, Color("a98a5f"))
			for i in 5:
				draw_line(Vector2(-22 + i * 11, 3), Vector2(-22 + i * 11, 14), Color("8f7350"), 1.6)
		"pet_bowls":
			for i in 2:
				var bx := -92.0 + i * 26.0
				DrawKit.ellipse(self, Vector2(bx, -4), 11.0, 5.0, [Color("6fb3d2"), Color("e8918c")][i])
				DrawKit.ellipse(self, Vector2(bx, -6), 8.0, 3.4, Color("f4f0e6"))
		"plant_pots":
			for i in 2:
				var px := 52.0 + i * 22.0
				draw_polygon(PackedVector2Array([
					Vector2(px - 9, -2), Vector2(px + 9, -2), Vector2(px + 7, -18), Vector2(px - 7, -18),
				]), PackedColorArray([Color("c07a5c")]))
				draw_circle(Vector2(px, -22), 7.0, Color("83b86f"))
				draw_circle(Vector2(px - 3, -26), 3.0, Color("f2b8cf"))
		"chalkboard":
			DrawKit.rounded_rect(self, Rect2(-152, -84, 46, 40), 3.0, Color("6b5a3f"))
			draw_rect(Rect2(-148, -80, 38, 32), Color("3f4a42"))
			# tomorrow's build, in chalk
			draw_line(Vector2(-142, -58), Vector2(-116, -58), Color("d8e4d8"), 2.0)
			draw_rect(Rect2(-140, -74, 10, 10), Color("d8e4d8"))
			draw_line(Vector2(-124, -74), Vector2(-116, -64), Color("d8e4d8"), 2.0)
		"painted_door":
			pass   # the door itself changes colour; nothing extra to draw
		"bunting", "flag", "weather_vane", "wind_chime":
			pass   # these live in the Motion child, since they move


## Draw one part on its own — used by the build board's translucent ghost.
func _draw_part(id: String) -> void:
	match id:
		"platform": _draw_platform(id, -262.0, 88.0)
		"tree2_platform": _draw_platform(id, -262.0, 74.0)
		"tree3_platform": _draw_platform(id, -262.0, 78.0)
		"cabin":
			_draw_storey(id, CABIN_TOP, -260.0, 62.0)
			_draw_roof(CABIN_TOP, false)
		"tree2_cabin":
			_draw_storey(id, CABIN_TOP, -260.0, 52.0)
			_draw_roof(CABIN_TOP, false)
		"tree3_tower":
			_draw_storey(id, STOREY2_TOP, -260.0, 50.0)
			_draw_roof(STOREY2_TOP, true)
		"storey2":
			_draw_storey(id, STOREY2_TOP, CABIN_TOP, 56.0)
			_draw_roof(STOREY2_TOP, false)
		"tower":
			_draw_storey(id, TOWER_TOP, STOREY2_TOP, 42.0)
			_draw_roof(TOWER_TOP, false)
		"mansion_roof": _draw_roof(_top(), true)
		"deck_front": _draw_deck(id, 1.0)
		"deck_side": _draw_deck(id, -1.0)
		"balcony": _draw_balcony()
		"stairs_wood": _draw_stairs()
		"stairs_spiral": _draw_spiral()
		"ladder_rope": _draw_ladder()
		"lift_bucket": _draw_lift()
		"slide": _draw_slide()
		"workshop": _draw_workshop()
		"crows_nest": _draw_crows_nest()
		"bridge2", "bridge3":
			# the bridge lives in the world, not on the tree — show a stub
			var p := BuildDefs.spot_of(id)
			for i in 5:
				draw_rect(Rect2(p.x + i * 22.0, p.y - 4, 16, 9), Color("c9a06c"))
			draw_line(p + Vector2(0, -34), p + Vector2(110, -34), Color("9a8055"), 3.0)
		"zipline":
			draw_line(Vector2(30, -420), Vector2(300, -150), Color("9a8055"), 3.0)
		"tree2_roof": _draw_roof(CABIN_TOP, true)
		"tree2_loft":
			_draw_storey(id, STOREY2_TOP, CABIN_TOP, 44.0)
			_draw_roof(STOREY2_TOP, false)
		"tree2_deck": _draw_deck(id, -1.0)
		"tree2_net": _draw_net(-64.0, -252.0)
		"tree2_pole": _draw_pole(58.0)
		"tree2_swing": _draw_swing()
		"tree2_hammock": _draw_hammock()
		"tree2_spyglass": _draw_spyglass()
		"tree3_top":
			_draw_storey(id, TOWER_TOP, STOREY2_TOP, 40.0)
			_draw_roof(TOWER_TOP, true)
		"tree3_spire": _draw_spire()
		"tree3_deck": _draw_deck(id, 1.0)
		"tree3_netbridge": _draw_rope_walk()
		"tree3_stairs": _draw_spiral()
		"tree3_rope": _draw_knot_rope()
		"tree3_zip": _draw_zip_home()
		"tree3_telescope": _draw_big_telescope()
		"shelves", "den", "kitchen", "art_room", "telescope", "tree2_bunk", "tree3_beds", "tree3_lookout":
			# interiors — show the window lighting up where the room will be
			var p := BuildDefs.spot_of(id)
			_draw_window(p, 18.0)
		_:
			_draw_decoration(id)


## The few parts that move. Kept in a child node so the big static treehouse
## does not have to redraw every frame.
class Motion extends Node2D:
	var house: Treehouse = null
	var t := 0.0

	func _ready() -> void:
		z_index = 1

	func _process(delta: float) -> void:
		t += delta
		if house != null and house.site == "home" \
				and (house.has("flag") or house.has("weather_vane") or house.has("wind_chime")
					or house.has("bunting")):
			queue_redraw()
		elif house != null and house.site == "two" and house.has("zipline"):
			queue_redraw()

	func _draw() -> void:
		if house == null:
			return
		var breeze := sin(t * 0.9) * 0.5 + sin(t * 2.3) * 0.2
		if house.site == "two" and house.has("zipline"):
			draw_line(Vector2(30, -420), Vector2(300, -150), Color("9a8055"), 3.0)
			draw_circle(Vector2(40 + sin(t * 0.7) * 4.0, -412), 5.0, Color("7a8b9c"))
			return
		if house.site != "home":
			return
		# These all hang off the roofline, so they follow the house up as she
		# builds — a flag left at a fixed height would end up floating in mid-air.
		var top := house._top()
		if house.has("bunting"):
			var by := top + 14.0
			var cols := [Color("e8918c"), Color("ffd98a"), Color("a9c9e8"), Color("c4b8e8"), Color("f2b8cf")]
			for i in 6:
				var u := i / 5.0
				var bp := Vector2(lerpf(-84.0, 84.0, u), by + sin(u * PI) * (14.0 + breeze * 3.0))
				if i > 0:
					var pu := (i - 1) / 5.0
					draw_line(Vector2(lerpf(-84.0, 84.0, pu), by + sin(pu * PI) * (14.0 + breeze * 3.0)),
						bp, Color(0.4, 0.34, 0.26, 0.6), 1.5)
				draw_polygon(PackedVector2Array([
					bp + Vector2(-6, 0), bp + Vector2(6, 0), bp + Vector2(0, 13),
				]), PackedColorArray([cols[i % cols.size()]]))
		if house.has("flag"):
			var fy := top - 22.0
			draw_line(Vector2(66, fy), Vector2(66, fy - 46), Color("8a6a44"), 3.0)
			var wave := breeze * 5.0
			draw_polygon(PackedVector2Array([
				Vector2(66, fy - 46), Vector2(94 + wave, fy - 39 + wave * 0.4), Vector2(66, fy - 32),
			]), PackedColorArray([Color("e8918c")]))
			draw_polygon(PackedVector2Array([
				Vector2(66, fy - 43), Vector2(86 + wave, fy - 39), Vector2(66, fy - 35),
			]), PackedColorArray([Color("f2b8cf")]))
		if house.has("weather_vane"):
			var vy := top - 20.0
			draw_line(Vector2(-52, vy), Vector2(-52, vy - 34), Color("7a8b9c"), 2.5)
			var a := breeze * 0.7
			var d := Vector2(cos(a), sin(a) * 0.35)
			var vt := Vector2(-52, vy - 34)
			draw_line(vt - d * 14.0, vt + d * 14.0, Color("8a95a0"), 3.0)
			draw_polygon(PackedVector2Array([
				vt + d * 18.0,
				vt + d * 9.0 + Vector2(-d.y, d.x) * 5.0,
				vt + d * 9.0 - Vector2(-d.y, d.x) * 5.0,
			]), PackedColorArray([Color("d9b45c")]))
		if house.has("wind_chime"):
			draw_line(Vector2(62, -300), Vector2(62, -292), Color("6b5a3f"), 2.0)
			draw_arc(Vector2(62, -292), 9.0, 0, PI, 8, Color("a9743f"), 3.0, true)
			for i in 4:
				var cx := 55.0 + i * 4.5 + breeze * (1.0 + i * 0.35)
				draw_line(Vector2(55.0 + i * 4.5, -290), Vector2(cx, -270 - i * 3.0), Color("c2c8cc"), 2.2)


# --- tree two and tree three -------------------------------------------------
# Both used to be a platform and a box. They are proper places now, with their
# own ways up, their own comforts and their own decorations.

## A net of knotted rope up the trunk — the fun way to the platform.
func _draw_net(x: float, top: float) -> void:
	var rope := Color("9a8055")
	for i in 5:
		var rx := x - 26.0 + i * 13.0
		draw_line(Vector2(rx, top), Vector2(rx * 0.7, 2), rope, 2.6)
	for j in 7:
		var v := j / 6.0
		var y := lerpf(top, 2.0, v)
		var half := lerpf(26.0, 18.0, v)
		draw_line(Vector2(x - half, y), Vector2(x + half, y), rope.lightened(0.08), 2.4)
	for j in 6:
		draw_circle(Vector2(x, lerpf(top, 2.0, j / 5.0)), 2.4, rope.darkened(0.2))


## A smooth pole down from the deck — the fast way off.
func _draw_pole(x: float) -> void:
	draw_line(Vector2(x, -258), Vector2(x, 2), Color("b8b0a0"), 6.0)
	draw_line(Vector2(x - 2.0, -258), Vector2(x - 2.0, 2), Color("d5cec0"), 2.0)
	draw_circle(Vector2(x, -262), 5.0, Color("9aa7b5"))


## A rope swing off a low branch, swaying by itself.
func _draw_swing() -> void:
	var rope := Color("9a8055")
	# the treehouse only redraws when something changes, so the rope hangs
	# still here; Motion is where anything that actually moves belongs
	var sway := 0.0
	draw_line(Vector2(80, -252), Vector2(96 + sway, -132), rope, 2.6)
	draw_line(Vector2(112, -252), Vector2(122 + sway, -132), rope, 2.6)
	DrawKit.rounded_rect(self, Rect2(90 + sway, -134, 38, 9), 3.0, Color("c9a06c"))


## A hammock slung under the platform.
func _draw_hammock() -> void:
	var cloth := Color("e8918c")
	var pts := PackedVector2Array()
	for i in 13:
		var v := i / 12.0
		pts.append(Vector2(-56.0 + 112.0 * v, -246.0 + sin(v * PI) * 26.0))
	for i in 13:
		var v := 1.0 - i / 12.0
		pts.append(Vector2(-56.0 + 112.0 * v, -258.0 + sin(v * PI) * 26.0))
	draw_colored_polygon(pts, cloth)
	for side in [-1.0, 1.0]:
		draw_line(Vector2(side * 56.0, -252), Vector2(side * 72.0, -262),
			Color("9a8055"), 2.4)


## A little spyglass on a stand up in the crow's nest.
func _draw_spyglass() -> void:
	draw_line(Vector2(30, -434), Vector2(30, -452), Color("8a7355"), 3.0)
	draw_line(Vector2(24, -456), Vector2(48, -466), Color("b8b0a0"), 7.0)
	draw_circle(Vector2(49, -467), 4.4, Color("9aa7b5"))
	draw_circle(Vector2(23, -455), 3.2, Color("d5cec0"))


## The tall spire on tree three, with a star on the point.
func _draw_spire() -> void:
	var c := _mat("tree3_spire")
	var base := _top() - 8.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(-30, base), Vector2(30, base), Vector2(0, base - 78.0),
	]), c)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-30, base), Vector2(0, base), Vector2(0, base - 78.0),
	]), c.darkened(0.12))
	DrawKit.star(self, Vector2(0, base - 88.0), 9.0, Color("ffd98a"))


## A proper telescope on the tower deck, pointed at the sky.
func _draw_big_telescope() -> void:
	var body := Color("8fb7d9")
	draw_line(Vector2(40, -430), Vector2(40, -452), Color("8a7355"), 4.0)
	draw_line(Vector2(30, -448), Vector2(50, -448), Color("8a7355"), 3.0)
	draw_line(Vector2(28, -452), Vector2(62, -476), body, 11.0)
	draw_line(Vector2(28, -452), Vector2(38, -445), body.darkened(0.2), 9.0)
	draw_circle(Vector2(63, -477), 6.4, Color("d5e6f2"))


## A knotted climbing rope hanging from the platform.
func _draw_knot_rope() -> void:
	var rope := Color("9a8055")
	var sway := 0.0
	for i in 8:
		var v := i / 7.0
		var y := lerpf(-252.0, 2.0, v)
		draw_circle(Vector2(-70.0 + sway * v, y), 4.2, rope.darkened(0.16))
	draw_line(Vector2(-70, -252), Vector2(-70.0 + sway, 2), rope, 3.4)


## The zip wire back toward the home tree.
func _draw_zip_home() -> void:
	draw_line(Vector2(-40, -392), Vector2(-320, -190), Color("9a8055"), 3.0)
	draw_circle(Vector2(-46, -390), 5.0, Color("b8b0a0"))
	DrawKit.rounded_rect(self, Rect2(-56, -388, 22, 8), 3.0, Color("c9a06c"))


## A rope walk out from the platform: two hand ropes and slats.
func _draw_rope_walk() -> void:
	var rope := Color("9a8055")
	draw_line(Vector2(-78, -256), Vector2(-186, -246), rope, 2.6)
	draw_line(Vector2(-78, -300), Vector2(-186, -290), rope, 2.6)
	for i in 6:
		var v := i / 5.0
		var x := lerpf(-84.0, -180.0, v)
		var y := lerpf(-254.0, -244.0, v)
		draw_rect(Rect2(x - 7, y, 14, 6), Color("c9a06c"))
		draw_line(Vector2(x, y), Vector2(x + 2.0, y - 44.0), rope.lightened(0.1), 1.6)
