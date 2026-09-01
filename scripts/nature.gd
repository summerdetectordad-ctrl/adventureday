class_name Nature
extends Node
## All the world pieces, drawn in code. Each is based on a real Adventure Day:
## the treehouse build, blackberry hunt, catching frogs, tadpoles and the
## bird's nest, bike adventures, picnics in the park. Interactable pieces have
## try_tap(world_pos) -> bool: return true if the tap was theirs.


## Full-screen sky, fixed to the screen on its own CanvasLayer. A shader does
## the per-pixel work (gradient, sun glow, drifting fbm clouds); the distant
## hills are drawn on top and parallax gently against the camera.
class SkyBackdrop extends Control:
	var sky_mat: ShaderMaterial
	var hills: SkyHills

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		sky_mat = Paint.sky_material()
		var shader_rect := ColorRect.new()
		shader_rect.material = sky_mat
		shader_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shader_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(shader_rect)
		hills = SkyHills.new()
		hills.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(hills)
		_fit()
		get_viewport().size_changed.connect(_fit)

	func _fit() -> void:
		position = Vector2.ZERO
		size = get_viewport().get_visible_rect().size
		sky_mat.set_shader_parameter("sun_pos", Vector2((size.x - 170.0) / size.x, 130.0 / size.y))
		sky_mat.set_shader_parameter("aspect", size.x / maxf(size.y, 1.0))

	func _process(_delta: float) -> void:
		var ct := get_viewport().canvas_transform
		hills.scroll = -ct.origin.x / maxf(ct.get_scale().x, 0.001)
		hills.queue_redraw()


## The rolling distant hills, drawn over the shader sky with aerial
## perspective — bluer and paler the further away.
class SkyHills extends Control:
	const HORIZON := 586.0      # screen y where the grass line sits (camera y is fixed)
	var scroll := 0.0           # world-space camera scroll, for the parallax

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	## Rolling hill silhouette height at world-ish coordinate x.
	static func _hill_y(x: float, base: float, a1: float, a2: float, ph: float) -> float:
		return base - a1 * (0.5 + 0.5 * sin(x * 0.0042 + ph)) - a2 * (0.5 + 0.5 * sin(x * 0.0011 + ph * 1.7))

	func _hill_band(factor: float, base: float, a1: float, a2: float, ph: float, col: Color) -> void:
		var pts := PackedVector2Array()
		var w := size.x
		var step := 32.0
		var x := 0.0
		while x <= w + step:
			pts.append(Vector2(x, _hill_y(x + scroll * factor, base, a1, a2, ph)))
			x += step
		pts.append(Vector2(w + step, size.y))
		pts.append(Vector2(0, size.y))
		draw_polygon(pts, PackedColorArray([col]))

	func _draw() -> void:
		var vs := size
		# distant hills — bluer and paler the further away (aerial perspective)
		_hill_band(0.1, HORIZON - 10.0, 46.0, 90.0, 1.3, Color("b9d3c2"))
		_hill_band(0.24, HORIZON - 2.0, 38.0, 62.0, 4.1, Color("aacba4"))
		# tiny far trees dotted along the nearer hill line
		var tree_col := Color("8fb489")
		var k0 := floori((scroll * 0.24 - 100.0) / 240.0)
		for k in range(k0, k0 + 8):
			var xw := k * 240.0 + fmod(absf(sin(k * 12.9898) * 43758.55), 150.0)
			var xs := xw - scroll * 0.24
			if xs < -40.0 or xs > vs.x + 40.0:
				continue
			var hy := _hill_y(xw, HORIZON - 2.0, 38.0, 62.0, 4.1)
			draw_line(Vector2(xs, hy + 3.0), Vector2(xs, hy - 8.0), tree_col.darkened(0.25), 2.0)
			DrawKit.blob(self, Vector2(xs, hy - 13.0), 9.0, 8.0, tree_col, k * 7 + 3)
		# haze where land meets sky
		DrawKit.vgrad(self, Rect2(0, HORIZON - 46.0, vs.x, 46.0),
			Color(1, 1, 1, 0.0), Color(0.99, 0.97, 0.9, 0.4))


## Static ground, hills, flowers and grass across the whole world width.
class WorldBG extends Node2D:
	## The ground each zone stands on. `palette` swaps the whole colour set, so
	## Dino Land reads as a dry prehistoric valley and the cove as sand, without
	## a second copy of all this drawing.
	const PALETTES := {
		"meadow": {
			"rise": "9bc893", "shrub": "8bbc84", "turf": "a8d5a2",
			"dirt_top": "b9906b", "dirt_bottom": "77573d", "pebble": "a67c58",
			"grain_dark": "55381f", "grain_light": "d9b485",
			"turf_dark": "46703f", "turf_light": "cfe8b8",
			"mottle_a": Color(0.5, 0.72, 0.47, 0.22), "mottle_b": Color(0.74, 0.9, 0.68, 0.25),
			"turf_deep": "74a86e", "blade": "7fb87a", "flora": 1.0,
		},
		"dino": {
			"rise": "b5ab74", "shrub": "9d9a5e", "turf": "c9bd83",
			"dirt_top": "b08556", "dirt_bottom": "6d5133", "pebble": "9c7a54",
			"grain_dark": "4a3218", "grain_light": "d4b478",
			"turf_dark": "7a7040", "turf_light": "e2d9a6",
			"mottle_a": Color(0.62, 0.58, 0.34, 0.22), "mottle_b": Color(0.85, 0.82, 0.58, 0.25),
			"turf_deep": "9a9152", "blade": "b0a768", "flora": 0.35,
		},
		"cove": {
			"rise": "e0d2ac", "shrub": "cfc194", "turf": "eaddb8",
			"dirt_top": "d8c298", "dirt_bottom": "a8895f", "pebble": "c3ab86",
			"grain_dark": "8a6a44", "grain_light": "f4e6c6",
			"turf_dark": "b8a878", "turf_light": "f7eed4",
			"mottle_a": Color(0.82, 0.74, 0.55, 0.22), "mottle_b": Color(0.95, 0.9, 0.76, 0.25),
			"turf_deep": "cfbf95", "blade": "ddcda2", "flora": 0.0,
		},
	}

	var world_w := 4200.0
	var ground_y := 600.0
	var palette := "meadow"

	## One colour from the current palette.
	func p(key: String) -> Color:
		var set: Dictionary = PALETTES.get(palette, PALETTES["meadow"])
		var v = set.get(key, "9bc893")
		return v if v is Color else Color(str(v))

	func _ready() -> void:
		# per-pixel grain over the big flat fills — the texture polygons lack.
		# (children draw above this node's own _draw, below later siblings)
		add_child(Paint.grain(Rect2(0, ground_y + 14, world_w, 306), 34.0, 0.16,
			p("grain_dark"), p("grain_light")))
		add_child(Paint.grain(Rect2(0, ground_y - 8, world_w, 22), 14.0, 0.12,
			p("turf_dark"), p("turf_light")))

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		# gentle meadow rise just behind the play line (the far hills live on
		# the sky layer now, with parallax)
		var rise := PackedVector2Array()
		var x := 0.0
		while x <= world_w + 60.0:
			rise.append(Vector2(x, ground_y - 26.0 - 22.0 * (0.5 + 0.5 * sin(x * 0.006 + 1.0))
				- 10.0 * (0.5 + 0.5 * sin(x * 0.0021 + 3.0))))
			x += 60.0
		rise.append(Vector2(world_w + 60.0, ground_y + 10.0))
		rise.append(Vector2(0, ground_y + 10.0))
		draw_polygon(rise, PackedColorArray([p("rise")]))
		# hedgerow shrubs and little background trees dotted along the crest
		for i in 26:
			var sx := rng.randf_range(40.0, world_w - 40.0)
			var crest := ground_y - 26.0 - 22.0 * (0.5 + 0.5 * sin(sx * 0.006 + 1.0)) \
				- 10.0 * (0.5 + 0.5 * sin(sx * 0.0021 + 3.0))
			var tone := p("shrub").darkened(rng.randf_range(0.0, 0.08))
			if i % 3 == 0:
				# background tree: stick trunk + round crown
				var th := rng.randf_range(14.0, 24.0)
				draw_line(Vector2(sx, crest + 8.0), Vector2(sx, crest - th), Color("7d6248"), 2.5)
				DrawKit.blob(self, Vector2(sx, crest - th - 8.0), rng.randf_range(10.0, 16.0),
					rng.randf_range(9.0, 13.0), tone, rng.randi())
			else:
				DrawKit.blob(self, Vector2(sx, crest + 3.0), rng.randf_range(14.0, 30.0),
					rng.randf_range(7.0, 12.0), tone, rng.randi())
		# soft mottling on the rise
		for i in 60:
			var mx := rng.randf_range(0.0, world_w)
			DrawKit.ellipse(self, Vector2(mx, ground_y - 22.0 - rng.randf_range(0.0, 16.0)),
				rng.randf_range(30.0, 80.0), rng.randf_range(5.0, 10.0),
				p("mottle_a") if i % 2 == 0 else p("mottle_b"))

		# dirt cutaway, darker with depth
		DrawKit.vgrad(self, Rect2(0, ground_y, world_w, 320), p("dirt_top"), p("dirt_bottom"))
		# faint strata bands
		for s in 3:
			var sy := ground_y + 70.0 + s * 80.0
			var band := PackedVector2Array()
			x = 0.0
			while x <= world_w + 90.0:
				band.append(Vector2(x, sy + 9.0 * sin(x * 0.004 + s * 2.0)))
				x += 90.0
			draw_polyline(band, Color(0.45, 0.32, 0.2, 0.13), 10.0)
		# buried pebbles, shaded
		for i in 60:
			var pp := Vector2(rng.randf_range(0, world_w), rng.randf_range(ground_y + 40, ground_y + 300))
			var pr := rng.randf_range(3.0, 8.0)
			var pc := p("pebble").lightened(rng.randf_range(-0.06, 0.1))
			DrawKit.ellipse(self, pp, pr, pr * 0.75, pc)
			DrawKit.ellipse(self, pp + Vector2(pr * 0.2, -pr * 0.25), pr * 0.5, pr * 0.35, pc.lightened(0.09))
		# fine speckles
		for i in 150:
			draw_circle(Vector2(rng.randf_range(0, world_w), rng.randf_range(ground_y + 24, ground_y + 300)),
				rng.randf_range(1.2, 3.0), Color(0.5, 0.36, 0.23, 0.35))
		# a few fine roots reaching down from the turf
		for i in 10:
			var rx := rng.randf_range(0.0, world_w)
			var p := Vector2(rx, ground_y + 10.0)
			for s in 3:
				var np := p + Vector2(rng.randf_range(-6.0, 6.0), rng.randf_range(7.0, 13.0))
				draw_line(p, np, Color(0.45, 0.33, 0.21, 0.3), 1.8 - s * 0.4)
				p = np

		# turf band with a wobbly top edge and a lit-top gradient
		var top_pts := PackedVector2Array()
		x = 0.0
		while x <= world_w + 46.0:
			top_pts.append(Vector2(x, ground_y - 13.0 + 2.6 * sin(x * 0.05) + 1.8 * sin(x * 0.013 + 2.0)))
			x += 46.0
		var turf := PackedVector2Array()
		var turf_cols := PackedColorArray()
		for p in top_pts:
			turf.append(p)
			turf_cols.append(p("turf"))
		for i in range(top_pts.size() - 1, -1, -1):
			turf.append(Vector2(top_pts[i].x, ground_y + 16.0))
			turf_cols.append(p("turf_deep"))
		draw_polygon(turf, turf_cols)
		# shadowed soil lip right under the turf
		draw_rect(Rect2(0, ground_y + 12, world_w, 8), Color(0.35, 0.24, 0.15, 0.35))

		# grass blades along the edge — sparser and drier away from the meadow
		var flora: float = float(PALETTES.get(palette, PALETTES["meadow"]).get("flora", 1.0))
		for i in int(240 * maxf(flora, 0.25)):
			var gx := rng.randf_range(10.0, world_w - 10.0)
			DrawKit.tuft(self, Vector2(gx, ground_y - 6.0 + rng.randf_range(-4.0, 4.0)),
				rng.randf_range(14.0, 26.0) * (0.6 + flora * 0.4),
				p("blade").lightened(rng.randf_range(-0.05, 0.1)), rng.randi())

		# flowers with stems, leaves and layered petals — meadow only
		var petals := [Color("f2b8cf"), Color("ffe6b3"), Color("c4b8e8"), Color("ffffff"), Color("f2a0a0")]
		for i in int(56 * flora):
			var fpos := Vector2(rng.randf_range(30, world_w - 30), ground_y - 26 - rng.randf_range(0, 10))
			var lean2 := rng.randf_range(-3.0, 3.0)
			draw_line(fpos + Vector2(0, 16), fpos + Vector2(lean2, 0), p("turf_deep"), 2.2)
			DrawKit.ellipse(self, fpos + Vector2(-4, 11), 4.5, 2.0, p("blade"))
			DrawKit.ellipse(self, fpos + Vector2(4, 13), 4.0, 1.8, p("turf_deep"))
			var pc: Color = petals[rng.randi() % petals.size()]
			var fc := fpos + Vector2(lean2, 0)
			for pa in 6:
				var ang := TAU * pa / 6.0 + rng.randf_range(-0.1, 0.1)
				DrawKit.ellipse(self, fc + Vector2.from_angle(ang) * 4.6, 3.4, 2.6, pc)
				DrawKit.ellipse(self, fc + Vector2.from_angle(ang) * 4.0, 2.2, 1.7, pc.lightened(0.1))
			draw_circle(fc, 2.8, Color("e8b45c"))
			draw_circle(fc + Vector2(-0.7, -0.7), 1.3, Color("ffe6b3"))
		# a few dandelion puffs
		for i in int(10 * flora):
			var dp := Vector2(rng.randf_range(60, world_w - 60), ground_y - 32 - rng.randf_range(0, 6))
			draw_line(dp + Vector2(0, 22), dp, Color("9db877"), 2.0)
			draw_circle(dp, 7.5, Color(1, 1, 1, 0.5))
			draw_circle(dp, 5.0, Color(1, 1, 1, 0.65))
			draw_circle(dp, 2.2, Color("e8e0c8"))


## Big background tree (non-interactive).
class MeadowTree extends Node2D:
	var tint := 0.0

	func _draw() -> void:
		var seed_v := int(absf(global_position.x))
		DrawKit.soft_shadow(self, Vector2(0, 2), 58.0)
		DrawKit.trunk(self, Vector2.ZERO, 160.0, 13.0, 8.0, Color("806048"), seed_v)
		# a branch or two disappearing into the leaves
		draw_line(Vector2(2, -120), Vector2(34, -160), Color("806048"), 6.0)
		draw_line(Vector2(-2, -140), Vector2(-28, -172), Color("77573d"), 5.0)
		var leaf := Color("94c489").darkened(tint)
		DrawKit.canopy(self, Vector2(0, -196), 84.0, 70.0, leaf, seed_v + 1)
		DrawKit.tuft(self, Vector2(-14, 2), 15.0, Color("7fb87a"), seed_v + 40)
		DrawKit.tuft(self, Vector2(15, 3), 13.0, Color("74a86e"), seed_v + 41)


class BerryBush extends Node2D:
	var berries: Array = []

	func _init() -> void:
		for i in 8:
			berries.append({
				"off": Vector2(randf_range(-52.0, 52.0), randf_range(-64.0, -20.0)),
				"ripe": true,
				"t": 0.0,
			})

	func _process(delta: float) -> void:
		var changed := false
		for b in berries:
			if not b["ripe"]:
				b["t"] -= delta
				if b["t"] <= 0.0:
					b["ripe"] = true
					changed = true
		if changed:
			queue_redraw()

	## How centrally this tap lands on us, 0..1 — a dead-on berry beats the
	## edge of any overlapping hitbox (see main.gd's weighted picking).
	func tap_score(wp: Vector2) -> float:
		var lp := wp - global_position
		var best := 0.0
		for b in berries:
			if b["ripe"]:
				best = maxf(best, 1.0 - lp.distance_to(b["off"]) / 60.0)
		# the leafy bush counts half, so a tap on it still walks her over
		best = maxf(best, (1.0 - lp.distance_to(Vector2(0, -40)) / 95.0) * 0.5)
		return clampf(best, 0.0, 1.0)

	func try_tap(wp: Vector2) -> bool:
		var lp := wp - global_position
		var best = null
		var best_d := 55.0
		for b in berries:
			if b["ripe"]:
				var d: float = lp.distance_to(b["off"])
				if d < best_d:
					best_d = d
					best = b
		if best == null:
			# a tap on the leaves shouldn't send her marching off
			return lp.distance_to(Vector2(0, -40)) < 95.0
		best["ripe"] = false
		best["t"] = randf_range(20.0, 35.0)
		Sound.pop()
		Fx.sparkles(get_parent(), wp, 5, Color("b78ad4"))
		# blackberries count as fruit, same as the fruit trees — they are the
		# market's currency, and a handful takes the edge off being peckish
		GameState.add_fruit(1)
		GameState.hunger_accum = maxf(0.0, GameState.hunger_accum - 20.0)
		# and the running count, purely for the counting practice
		GameState.berries_picked = (GameState.berries_picked % 20) + 1
		Fx.float_number(get_parent(), wp + Vector2(0, -24), GameState.berries_picked)
		queue_redraw()
		return true

	func _draw() -> void:
		var seed_v := int(absf(global_position.x)) + 5
		DrawKit.soft_shadow(self, Vector2(0, 2), 62.0)
		# woody little stems peeking out at the bottom
		draw_line(Vector2(-8, 0), Vector2(-16, -22), Color("77573d"), 3.5)
		draw_line(Vector2(6, 0), Vector2(14, -20), Color("806048"), 3.5)
		# layered leafy mass, shaded low-left and sunlit up-right
		var leaf := Color("85b97a")
		DrawKit.blob(self, Vector2(-4, -30), 58.0, 36.0, leaf.darkened(0.18), seed_v)
		DrawKit.blob(self, Vector2(-26, -40), 34.0, 28.0, leaf, seed_v + 1)
		DrawKit.blob(self, Vector2(26, -38), 34.0, 28.0, leaf.lightened(0.05), seed_v + 2)
		DrawKit.blob(self, Vector2(0, -52), 38.0, 28.0, leaf.lightened(0.1), seed_v + 3)
		DrawKit.blob(self, Vector2(16, -58), 24.0, 18.0, leaf.lightened(0.16), seed_v + 4)
		# a few drawn leaves for texture
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_v + 8
		for i in 9:
			var lp := Vector2(rng.randf_range(-44.0, 44.0), rng.randf_range(-66.0, -22.0))
			var la := rng.randf_range(-0.6, 0.6)
			var tone := leaf.lightened(rng.randf_range(-0.08, 0.16))
			DrawKit.ellipse(self, lp, 6.5, 3.0, tone)
			draw_line(lp - Vector2.from_angle(la) * 5.0, lp + Vector2.from_angle(la) * 5.0,
				tone.darkened(0.15), 1.0)
		for b in berries:
			var off: Vector2 = b["off"]
			if b["ripe"]:
				# blackberry: a cluster of drupelets with a glint
				draw_circle(off, 7.2, Color("4a2c5e"))
				for d in 5:
					var da := TAU * d / 5.0
					draw_circle(off + Vector2.from_angle(da) * 3.4, 2.6, Color("6d4788"))
				draw_circle(off, 2.6, Color("5e3a75"))
				draw_circle(off + Vector2(-2.2, -2.4), 1.6, Color("b592cc"))
				draw_line(off + Vector2(0, -7), off + Vector2(2, -11), Color("5c8a4d"), 1.6)
			else:
				draw_circle(off, 4.0, Color("a8c48f"))
				draw_circle(off + Vector2(-1, -1), 1.4, Color("c2d8a8"))


class Frog extends Node2D:
	var hopping := false

	func hop() -> void:
		if hopping:
			return
		hopping = true
		Sound.ribbit()
		var home_y := position.y
		var tw := create_tween()
		tw.tween_property(self, "position:y", home_y - 42.0, 0.22) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(self, "position:y", home_y, 0.22) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func() -> void: hopping = false)

	func _draw() -> void:
		var green := Color("83b86f")
		DrawKit.soft_shadow(self, Vector2(0, 2), 20.0, 0.12)
		# body with a darker back and a pale belly
		DrawKit.ellipse(self, Vector2(0, -10), 20.0, 14.0, green.darkened(0.1))
		DrawKit.ellipse(self, Vector2(1, -9), 18.0, 12.0, green)
		DrawKit.ellipse(self, Vector2(0, -6), 13.0, 7.0, Color("c8dfb2"))
		# mottled spots on the back
		for sp in [Vector2(-8, -16), Vector2(4, -19), Vector2(10, -14)]:
			draw_circle(sp, 2.0, green.darkened(0.2))
		# eyes up on top, with glints
		draw_circle(Vector2(-9, -24), 7.0, green)
		draw_circle(Vector2(9, -24), 7.0, green)
		draw_circle(Vector2(-9, -25), 3.6, Color.WHITE)
		draw_circle(Vector2(9, -25), 3.6, Color.WHITE)
		draw_circle(Vector2(-9, -25), 1.8, Color("3a3a44"))
		draw_circle(Vector2(9, -25), 1.8, Color("3a3a44"))
		draw_circle(Vector2(-10, -26), 0.7, Color.WHITE)
		draw_circle(Vector2(8, -26), 0.7, Color.WHITE)
		draw_arc(Vector2(0, -12), 7.0, 0.4, PI - 0.4, 8, Color("5c8a4d"), 2.0, true)
		# folded legs with toes
		DrawKit.ellipse(self, Vector2(-16, -3), 8.0, 5.0, green.darkened(0.12))
		DrawKit.ellipse(self, Vector2(16, -3), 8.0, 5.0, green.darkened(0.12))
		for tx in [-22.0, -19.0, 19.0, 22.0]:
			draw_line(Vector2(tx, 0), Vector2(tx + signf(tx) * 2.5, 1.5), green.darkened(0.18), 1.8)


## Pond with wiggling tadpoles, lily pads and two frogs to tap.
class Pond extends Node2D:
	var tads: Array = []
	var t := 0.0

	func _init() -> void:
		for i in 5:
			tads.append({
				"a": randf() * TAU,
				"sp": randf_range(0.3, 0.6),
				"r": randf_range(45.0, 110.0),
				"ph": randf() * TAU,
			})

	func _ready() -> void:
		for fpos in [Vector2(-165, -8), Vector2(175, -4)]:
			var f := Frog.new()
			f.position = fpos
			add_child(f)

	func _process(delta: float) -> void:
		t += delta
		for td in tads:
			td["a"] += td["sp"] * delta
			td["ph"] += delta * 8.0
		queue_redraw()

	func frog_at(wp: Vector2) -> Frog:
		for child in get_children():
			if child is Frog and (wp - child.global_position).length() < 55.0:
				return child
		return null

	func tap_score(wp: Vector2) -> float:
		var best := 0.0
		for child in get_children():
			if child is Frog:
				best = maxf(best, 1.0 - (wp - child.global_position).length() / 55.0)
		var lp := wp - global_position
		if absf(lp.x) < 200.0 and absf(lp.y + 6.0) < 55.0:
			best = maxf(best, 0.3)   # open water: fun, but low priority
		return clampf(best, 0.0, 1.0)

	func try_tap(wp: Vector2) -> bool:
		var f := frog_at(wp)
		if f != null:
			f.hop()
			return true
		var lp := wp - global_position
		if absf(lp.x) < 200.0 and absf(lp.y + 6.0) < 55.0:
			Sound.pop()
			Fx.sparkles(get_parent(), wp, 4, Color("a9d7e8"))
			return true
		return false

	func _draw() -> void:
		# muddy bank ring around the water
		DrawKit.ellipse(self, Vector2(0, -2), 220.0, 60.0, Color("9d7a55"))
		DrawKit.ellipse(self, Vector2(0, -3), 212.0, 55.0, Color("8a6a48"))
		# water: deep centre, paler sunlit shallows at the rim
		DrawKit.ellipse(self, Vector2(0, -4), 205.0, 52.0, Color("6fa8c2"))
		DrawKit.ellipse(self, Vector2(0, -6), 190.0, 44.0, Color("8ac0d6"))
		DrawKit.ellipse(self, Vector2(0, -8), 160.0, 34.0, Color("a9d7e8"))
		DrawKit.ellipse(self, Vector2(-20, -10), 110.0, 22.0, Color("bfe3f0"))
		# drifting ripple highlights
		for i in 4:
			var rp := Vector2(-120.0 + i * 76.0 + sin(t * 0.4 + i * 1.7) * 18.0,
				-10.0 + sin(t * 0.55 + i) * 5.0)
			var rw := 26.0 + 8.0 * sin(t * 0.7 + i * 2.1)
			draw_line(rp + Vector2(-rw, 0), rp + Vector2(rw, 0), Color(1, 1, 1, 0.28), 2.0)
			draw_line(rp + Vector2(-rw * 0.5, 3.5), rp + Vector2(rw * 0.5, 3.5), Color(1, 1, 1, 0.16), 1.5)
		# sun glitter on the right, toward the light
		for i in 5:
			var gp := Vector2(90.0 + i * 16.0, -14.0 + (i % 3) * 5.0)
			draw_circle(gp + Vector2(sin(t * 1.1 + i * 2.0) * 4.0, 0), 1.6, Color(1, 1, 1, 0.5))
		# stones along the near bank
		for st in [[-150.0, 26.0, 8.0], [-96.0, 34.0, 6.0], [128.0, 32.0, 7.0], [176.0, 22.0, 5.5]]:
			DrawKit.ellipse(self, Vector2(st[0], st[1]), st[2], st[2] * 0.7, Color("a8988a"))
			DrawKit.ellipse(self, Vector2(st[0] - 1.0, st[1] - 1.5), st[2] * 0.55, st[2] * 0.35, Color("bcaf9f"))
		# reeds with cattail heads, a couple leaning
		for spec in [[-195.0, -46.0, 3.0], [-181.0, -58.0, -4.0], [188.0, -50.0, 4.0], [201.0, -40.0, -2.0], [212.0, -54.0, 5.0]]:
			var rx: float = spec[0]
			var tip := Vector2(rx + spec[2], spec[1])
			draw_line(Vector2(rx, 2), tip, Color("6da368"), 3.0)
			draw_line(Vector2(rx, 2), tip + Vector2(spec[2] * 0.4, 4.0), Color("5c8a4d"), 1.5)
			DrawKit.ellipse(self, tip + Vector2(0, -6.0), 4.5, 10.0, Color("8a6242"))
			DrawKit.ellipse(self, tip + Vector2(-1.2, -8.0), 2.0, 6.0, Color("a9825c"))
		# lily pads with a notch, veins and a little flower
		for pad in [[-60.0, -14.0, 24.0, 0], [90.0, -2.0, 20.0, 1], [30.0, -22.0, 14.0, 2]]:
			var pp := Vector2(pad[0], pad[1] + sin(t * 0.8 + pad[3] * 2.0) * 1.2)
			var pr: float = pad[2]
			var pc := Color("7fbf83").darkened(0.04 * pad[3])
			DrawKit.ellipse(self, pp + Vector2(2, 2), pr, pr * 0.42, Color(0.2, 0.4, 0.45, 0.25))
			DrawKit.ellipse(self, pp, pr, pr * 0.42, pc)
			draw_polygon(PackedVector2Array([
				pp, pp + Vector2(pr * 0.95, -pr * 0.16), pp + Vector2(pr * 0.8, pr * 0.28),
			]), PackedColorArray([Color("a9d7e8")]))
			for v in 3:
				var va := PI * 0.55 + v * 0.5
				draw_line(pp, pp + Vector2(cos(va) * pr * 0.8, sin(va) * pr * 0.32), pc.darkened(0.12), 1.2)
			if pad[3] == 0:
				for fp in 5:
					DrawKit.ellipse(self, pp + Vector2(-6, -5) + Vector2.from_angle(TAU * fp / 5.0) * 4.0,
						3.2, 2.2, Color("f6d7e4"))
				draw_circle(pp + Vector2(-6, -5), 2.0, Color("ffd98a"))
		# tadpoles
		for td in tads:
			var p := Vector2(cos(td["a"]) * td["r"], -8.0 + sin(td["a"]) * td["r"] * 0.18)
			var tail := p + Vector2(-cos(td["a"] + PI / 2) * 10.0, sin(td["ph"]) * 3.0)
			draw_line(p, tail, Color("4a5a44"), 2.5)
			draw_circle(p, 4.5, Color("4a5a44"))
			draw_circle(p + Vector2(-1, -1.2), 1.4, Color("6b7a62"))


## Tree with the bird's nest from the "Tadpoles, Bird Nest and a Secret
## Location" day. Tap the nest and the birds sing.
class BirdTree extends Node2D:
	var flutter_t := 0.0    # >0 while the parent bird hops and flaps

	func nest_pos() -> Vector2:
		return global_position + Vector2(52, -158)

	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - nest_pos()).length() / 75.0, 0.0, 1.0)

	func try_tap(wp: Vector2) -> bool:
		if (wp - nest_pos()).length() < 75.0:
			Sound.chirp()
			flutter_t = 1.1
			Fx.hearts(get_parent(), nest_pos() + Vector2(0, -20))
			return true
		return false

	func _process(delta: float) -> void:
		if flutter_t > 0.0:
			flutter_t = maxf(0.0, flutter_t - delta)
			queue_redraw()

	func _draw() -> void:
		var seed_v := int(absf(global_position.x)) + 11
		DrawKit.soft_shadow(self, Vector2(0, 2), 52.0)
		DrawKit.trunk(self, Vector2.ZERO, 150.0, 12.0, 7.0, Color("8a6a52"), seed_v)
		# the nest branch, thicker at the trunk
		draw_line(Vector2(4, -120), Vector2(34, -140), Color("77573d"), 9.0)
		draw_line(Vector2(30, -138), Vector2(58, -152), Color("806048"), 7.0)
		draw_line(Vector2(8, -122), Vector2(30, -136), Color("9a7a5e"), 3.0)
		var leaf := Color("94c489")
		DrawKit.canopy(self, Vector2(-8, -186), 66.0, 56.0, leaf, seed_v + 1)
		DrawKit.blob(self, Vector2(34, -204), 34.0, 28.0, leaf.lightened(0.08), seed_v + 2)
		# woven nest: twiggy strands criss-crossing
		var nest := Vector2(52, -158)
		DrawKit.blob(self, nest + Vector2(0, 3), 18.0, 12.0, Color("8a6242"), seed_v + 3, 0.08)
		draw_arc(nest + Vector2(0, 1), 15.0, -0.2, PI + 0.2, 14, Color("a9825c"), 6.0, true)
		draw_arc(nest + Vector2(0, 4), 13.0, -0.1, PI + 0.1, 12, Color("77573d"), 3.0, true)
		for i in 5:
			var wa := -0.3 + i * 0.75
			draw_line(nest + Vector2(cos(wa) * 16.0, 1 + sin(wa) * 7.0),
				nest + Vector2(cos(wa + 0.9) * 13.0, 4 + sin(wa + 0.9) * 6.0), Color("9a7048"), 1.8)
		# speckled eggs peeking over the rim
		for egg in [[-5.0, Color("cfe4ea")], [5.0, Color("d8ecdf")]]:
			var ep := nest + Vector2(egg[0], -5.0)
			DrawKit.ellipse(self, ep, 5.0, 6.5, egg[1])
			DrawKit.ellipse(self, ep + Vector2(-1.2, -1.5), 2.6, 3.4, Color(egg[1]).lightened(0.08))
			for sdot in 3:
				draw_circle(ep + Vector2(sin(sdot * 2.7) * 3.0, cos(sdot * 1.9) * 3.5), 0.7,
					Color(0.55, 0.58, 0.6, 0.5))
		# parent bird: shaded body, folded wing (or fluttering when greeted),
		# tail feathers
		var bp := Vector2(24, -142)
		if flutter_t > 0.0:
			bp += Vector2(0, -absf(sin(flutter_t * 9.0)) * 6.0)
		var plume := Color("8fb7d9")
		draw_polygon(PackedVector2Array([
			bp + Vector2(-8, 0), bp + Vector2(-17, 5), bp + Vector2(-15, -3),
		]), PackedColorArray([plume.darkened(0.15)]))
		DrawKit.ellipse(self, bp, 9.0, 7.0, plume)
		DrawKit.ellipse(self, bp + Vector2(-1, 2.5), 6.5, 4.0, Color("d8e6f2"))
		if flutter_t > 0.0:
			var wa := absf(sin(flutter_t * 14.0))
			draw_set_transform(bp + Vector2(-2, -2), -0.4 - wa * 0.9, Vector2.ONE)
			DrawKit.ellipse(self, Vector2(-5, 0), 7.0, 3.5, plume.darkened(0.1))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			DrawKit.ellipse(self, bp + Vector2(-2, -1), 6.0, 4.0, plume.darkened(0.1))
		draw_circle(bp + Vector2(7, -6), 5.0, plume)
		draw_polygon(PackedVector2Array([
			bp + Vector2(11, -7), bp + Vector2(16, -5), bp + Vector2(11, -3),
		]), PackedColorArray([Color("ffc46b")]))
		draw_circle(bp + Vector2(8, -7), 1.3, Color("3a3a44"))
		draw_circle(bp + Vector2(7.6, -7.4), 0.5, Color.WHITE)
		for lx in [-1.0, 3.0]:
			draw_line(bp + Vector2(lx, 6), bp + Vector2(lx, 10), Color("d99a4e"), 1.5)


## Summer's bike, leaning near the treehouse — tap for a bell ding.
class Bike extends Node2D:
	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position - Vector2(0, -26)).length() / 62.0, 0.0, 1.0)

	func try_tap(wp: Vector2) -> bool:
		if (wp - global_position - Vector2(0, -26)).length() < 62.0:
			Sound.bell()
			Fx.sparkles(get_parent(), global_position + Vector2(18, -52), 4, Color("ffe6b3"))
			return true
		return false

	func _draw() -> void:
		var frame := Color("d97f7a")
		var wheel := Color("50505c")
		DrawKit.soft_shadow(self, Vector2(0, 1), 40.0, 0.12)
		# tyres with rims and spokes
		for hub in [Vector2(-26, -14), Vector2(26, -14)]:
			draw_arc(hub, 14.0, 0, TAU, 24, wheel, 4.5, true)
			draw_arc(hub, 10.5, 0, TAU, 20, Color("9aa2ac"), 1.6, true)
			for sp in 6:
				var sa := TAU * sp / 6.0 + 0.3
				draw_line(hub, hub + Vector2.from_angle(sa) * 12.0, Color("b8bec6"), 1.2)
			draw_circle(hub, 2.6, Color("7a8b9c"))
		# frame with a highlight pass
		draw_line(Vector2(-26, -14), Vector2(-6, -38), frame, 4.0)
		draw_line(Vector2(-6, -38), Vector2(20, -38), frame, 4.0)
		draw_line(Vector2(20, -38), Vector2(26, -14), frame, 4.0)
		draw_line(Vector2(-6, -38), Vector2(0, -14), frame, 4.0)
		draw_line(Vector2(0, -14), Vector2(-26, -14), frame, 4.0)
		draw_line(Vector2(-6, -38), Vector2(19, -38), frame.lightened(0.16), 1.5)
		# pedals and crank
		draw_circle(Vector2(0, -14), 3.5, Color("6e6a72"))
		draw_line(Vector2(0, -14), Vector2(5, -8), Color("6e6a72"), 2.5)
		draw_line(Vector2(3, -8), Vector2(9, -8), Color("3f3d46"), 3.0)
		# handlebars, saddle, bell
		draw_line(Vector2(22, -38), Vector2(18, -50), frame, 3.5)
		draw_line(Vector2(12, -50), Vector2(24, -50), frame, 3.5)
		draw_line(Vector2(11, -50), Vector2(14, -50), Color("3f3d46"), 4.5)   # grip
		draw_line(Vector2(-8, -38), Vector2(-12, -46), frame, 3.5)
		DrawKit.ellipse(self, Vector2(-12, -47), 6.0, 3.0, Color("77573d"))    # saddle
		DrawKit.ellipse(self, Vector2(-13, -48), 4.0, 1.6, Color("8a6a44"))
		draw_circle(Vector2(24, -48), 3.0, Color("ffd98a"))
		draw_circle(Vector2(23, -49), 1.2, Color("fff3d0"))
		# wicker basket on the front
		DrawKit.rounded_rect(self, Rect2(28, -46, 14, 10), 3.0, Color("c9a06c"))
		draw_line(Vector2(29, -43), Vector2(41, -43), Color("a97e54"), 1.5)
		draw_line(Vector2(29, -40), Vector2(41, -40), Color("a97e54"), 1.5)
		# stabilisers — she's nearly six!
		draw_arc(Vector2(32, -10), 7.0, 0, TAU, 14, wheel, 3.0, true)
		draw_arc(Vector2(32, -10), 4.5, 0, TAU, 10, Color("9aa2ac"), 1.2, true)
		draw_line(Vector2(26, -14), Vector2(32, -12), Color("8d99ae"), 2.5)


## Picnic blanket — so many picnic Adventure Days.
class PicnicBlanket extends Node2D:
	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position - Vector2(0, -14)).length() / 80.0, 0.0, 1.0)

	func try_tap(wp: Vector2) -> bool:
		if (wp - global_position - Vector2(0, -14)).length() < 80.0:
			Sound.card_sound()
			Fx.hearts(get_parent(), global_position + Vector2(0, -34), 2)
			return true
		return false

	func _draw() -> void:
		DrawKit.soft_shadow(self, Vector2(0, 2), 78.0, 0.1)
		# gingham blanket in soft perspective — checkered quads
		var rows := 4
		var cols := 6
		for r in rows:
			for cc in cols:
				var v0 := r / float(rows)
				var v1 := (r + 1) / float(rows)
				var u0 := cc / float(cols)
				var u1 := (cc + 1) / float(cols)
				var quad := PackedVector2Array([
					_bpt(u0, v0), _bpt(u1, v0), _bpt(u1, v1), _bpt(u0, v1),
				])
				var tone := Color("f2c9c9") if (r + cc) % 2 == 0 else Color("fbe9e4")
				draw_polygon(quad, PackedColorArray([tone.darkened(0.03 * (rows - r))]))
		# a soft fold across the middle
		draw_line(_bpt(0.06, 0.5), _bpt(0.94, 0.48), Color(0.7, 0.5, 0.5, 0.18), 3.0)
		# picnic basket with woven texture and an open lid
		DrawKit.rounded_rect(self, Rect2(-17, -45, 34, 24), 6.0, Color("c9915c"))
		for wy in 2:
			draw_line(Vector2(-15, -38 + wy * 8.0), Vector2(15, -38 + wy * 8.0), Color("a9744a"), 1.8)
		for wx in 4:
			draw_line(Vector2(-12 + wx * 8.0, -44), Vector2(-12 + wx * 8.0, -22), Color("a9744a"), 1.5)
		DrawKit.rounded_rect(self, Rect2(-17, -47, 34, 6), 3.0, Color("b8804e"))
		draw_arc(Vector2(0, -46), 11.0, PI, TAU, 10, Color("8a6a44"), 3.5, true)
		# checked cloth peeking out
		draw_polygon(PackedVector2Array([
			Vector2(6, -46), Vector2(16, -46), Vector2(18, -38),
		]), PackedColorArray([Color("fbe9e4")]))
		# apple with a blush and a shine, cup, and two strawberries
		draw_circle(Vector2(30, -9), 6.5, Color("d96b60"))
		draw_circle(Vector2(28.5, -10.5), 3.0, Color("e8918c"))
		draw_circle(Vector2(27.5, -11.5), 1.2, Color(1, 1, 1, 0.7))
		draw_line(Vector2(30, -15), Vector2(32, -19), Color("77573d"), 2.0)
		DrawKit.ellipse(self, Vector2(33, -18), 3.0, 1.6, Color("7fb87a"))
		DrawKit.rounded_rect(self, Rect2(-40, -17, 12, 13), 3.0, Color("a9c9e8"))
		DrawKit.ellipse(self, Vector2(-34, -17), 6.0, 2.0, Color("c8def0"))
		draw_line(Vector2(-36, -13), Vector2(-32, -13), Color(1, 1, 1, 0.5), 1.5)
		for sb in [Vector2(-24, -6), Vector2(-17, -3)]:
			draw_polygon(PackedVector2Array([
				sb + Vector2(-3.4, -2), sb + Vector2(3.4, -2), sb + Vector2(0, 4),
			]), PackedColorArray([Color("d96b60")]))
			DrawKit.ellipse(self, sb + Vector2(0, -2.5), 3.0, 1.5, Color("7fb87a"))

	## Point on the blanket: u across, v from back (0) to front (1).
	func _bpt(u: float, v: float) -> Vector2:
		var half := lerpf(52.0, 70.0, v)
		return Vector2(lerpf(-half, half, u), lerpf(-30.0, 0.0, v))


## Indy and Star, the two lurchers. They trot along behind Summer, slender
## greyhound shapes with long legs and happy tails. Tap one for a soft woof,
## a bounce and some hearts.
class Dog extends Node2D:
	var kind := "indy"          # "indy" (white, brown eye patch) or "star" (black)
	var follow: Node2D = null
	var trail := 110.0          # how far behind Summer this dog walks
	var t := 0.0
	var facing := 1
	var moving := false
	var bouncing := false
	var rest := 0.0             # seconds stood still; past 3 s the dog dozes off

	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position - Vector2(0, -30)).length() / 60.0, 0.0, 1.0)

	func try_tap(wp: Vector2) -> bool:
		if (wp - global_position - Vector2(0, -30)).length() < 60.0:
			Sound.woof()
			Fx.hearts(get_parent(), global_position + Vector2(0, -70), 2)
			if not bouncing:
				bouncing = true
				var home_y := position.y
				var tw := create_tween()
				tw.tween_property(self, "position:y", home_y - 30.0, 0.18) \
					.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
				tw.tween_property(self, "position:y", home_y, 0.18) \
					.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
				tw.tween_callback(func() -> void: bouncing = false)
			return true
		return false

	func _process(delta: float) -> void:
		t += delta
		if follow != null and not bouncing:
			var target: float = follow.position.x - follow.facing * trail
			var dx := target - position.x
			moving = absf(dx) > 26.0
			if moving:
				facing = 1 if dx > 0.0 else -1
				position.x = move_toward(position.x, target, 260.0 * delta)
				rest = 0.0
			else:
				# she has stopped — settle, and after a moment doze off
				rest = minf(rest + delta, 6.0)
			# dogs come up onto the decks with her, and settle there too
			position.y = move_toward(position.y, follow.position.y, 220.0 * delta)
		queue_redraw()

	## Curled up and dozing once she has been still a while.
	func napping() -> bool:
		return rest > 3.0 and not bouncing

	func _draw() -> void:
		var fx := float(facing)
		var body := Color("f3f0e8") if kind == "indy" else Color("43404a")
		var patch := Color("a5764f")
		if napping():
			_draw_napping(fx, body, patch)
			return
		var bob := -absf(sin(t * 10.0)) * 2.5 if moving else sin(t * 2.2) * 1.0
		var swing := sin(t * 10.0) * 8.0 if moving else 0.0

		DrawKit.soft_shadow(self, Vector2(0, 1), 30.0, 0.12)
		# long thin legs with little paws (far pair a shade darker)
		for leg in [[-22.0, swing, true], [-16.0, -swing, false], [16.0, -swing, false], [22.0, swing, true]]:
			var lx: float = leg[0] * fx
			var ls: float = leg[1] * fx * 0.35
			var lc := body.darkened(0.1) if leg[2] else body
			draw_line(Vector2(lx, -30 + bob), Vector2(lx + ls, 0), lc, 4.5)
			draw_circle(Vector2(lx + ls, -1), 2.8, lc)
		# slender body: deep chest, tucked waist, arched back
		DrawKit.ellipse(self, Vector2(14 * fx, -36 + bob), 16.0, 14.0, body)
		DrawKit.ellipse(self, Vector2(-16 * fx, -35 + bob), 13.0, 11.0, body)
		draw_polygon(PackedVector2Array([
			Vector2(-16 * fx, -46 + bob), Vector2(14 * fx, -50 + bob),
			Vector2(14 * fx, -26 + bob), Vector2(-16 * fx, -28 + bob),
		]), PackedColorArray([body]))
		# shading along the back, lighter tummy
		draw_polygon(PackedVector2Array([
			Vector2(-16 * fx, -46 + bob), Vector2(14 * fx, -50 + bob),
			Vector2(14 * fx, -44 + bob), Vector2(-16 * fx, -41 + bob),
		]), PackedColorArray([body.darkened(0.08)]))
		DrawKit.ellipse(self, Vector2(6 * fx, -28 + bob), 12.0, 5.0, body.lightened(0.1))
		# long neck and narrow head
		draw_line(Vector2(20 * fx, -44 + bob), Vector2(30 * fx, -62 + bob), body, 8.0)
		DrawKit.ellipse(self, Vector2(32 * fx, -64 + bob), 8.5, 6.5, body)
		# soft floppy ear
		draw_polygon(PackedVector2Array([
			Vector2(29 * fx, -70 + bob), Vector2(33 * fx, -68 + bob), Vector2(28 * fx, -60 + bob),
		]), PackedColorArray([body.darkened(0.12)]))
		draw_line(Vector2(37 * fx, -62 + bob), Vector2(47 * fx, -59 + bob), body, 5.0)
		draw_circle(Vector2(48 * fx, -59 + bob), 2.2, Color("2e2a28"))
		draw_circle(Vector2(47.4 * fx, -59.6 + bob), 0.8, Color(1, 1, 1, 0.6))
		# collar: red for Indy, gold for Star
		draw_line(Vector2(24 * fx, -52 + bob), Vector2(30 * fx, -57 + bob),
			Color("c85f56") if kind == "indy" else Color("d9b45c"), 3.0)
		# tail: long, thin, always a little waggy
		var wag := sin(t * 6.0) * 6.0
		var tail_base := Vector2(-27 * fx, -38 + bob)
		draw_line(tail_base, tail_base + Vector2(-12 * fx, 8 + wag * 0.3), body, 3.5)
		draw_line(tail_base + Vector2(-12 * fx, 8 + wag * 0.3),
			tail_base + Vector2(-20 * fx, 2 + wag), body, 3.0)
		if kind == "indy":
			# brown patch over one eye, brown ear on the opposite side
			draw_circle(Vector2(34 * fx, -66 + bob), 4.5, patch)
			draw_polygon(PackedVector2Array([
				Vector2(26 * fx, -70 + bob), Vector2(31 * fx, -68 + bob), Vector2(27 * fx, -78 + bob),
			]), PackedColorArray([patch]))
			draw_circle(Vector2(34 * fx, -65 + bob), 1.8, Color("2e2a28"))
		else:
			# Star: a little white star on her chest, for the name
			draw_polygon(PackedVector2Array([
				Vector2(26 * fx, -70 + bob), Vector2(31 * fx, -68 + bob), Vector2(27 * fx, -78 + bob),
			]), PackedColorArray([body.darkened(0.1)]))
			draw_circle(Vector2(34 * fx, -65 + bob), 1.8, Color("e8e4da"))
			DrawKit.star(self, Vector2(20 * fx, -30 + bob), 5.0, Color("efece4"))


## Something sturdy to clamber over — a crate, a mossy rock or a fallen log.
## Summer can't walk through it; a double-tap jump takes her up and over,

	## Curled up asleep — nose tucked under, sides rising and falling. Turns up
	## on the deck once she has built one and stops to look at the view.
	func _draw_napping(fx: float, body: Color, patch: Color) -> void:
		var breathe := sin(t * 1.5) * 1.3
		DrawKit.soft_shadow(self, Vector2(0, 1), 34.0, 0.13)
		# a comma of a dog: body curled, tail wrapped round
		DrawKit.ellipse(self, Vector2(0, -14 + breathe), 34.0, 15.0 + breathe * 0.3, body)
		DrawKit.ellipse(self, Vector2(-4 * fx, -10 + breathe), 26.0, 10.0, body.lightened(0.05))
		var tail := PackedVector2Array()
		for i in 8:
			var u := i / 7.0
			tail.append(Vector2((-30.0 - u * 22.0) * fx, -8.0 + sin(u * PI) * 12.0))
		draw_polyline(tail, body.darkened(0.06), 6.0)
		# head resting on its paws
		DrawKit.ellipse(self, Vector2(26 * fx, -10 + breathe), 15.0, 12.0, body)
		DrawKit.ellipse(self, Vector2(34 * fx, -5 + breathe), 11.0, 7.0, body)
		draw_polygon(PackedVector2Array([
			Vector2(20 * fx, -20 + breathe), Vector2(28 * fx, -30 + breathe),
			Vector2(31 * fx, -18 + breathe),
		]), PackedColorArray([body.darkened(0.1) if kind == "indy" else body.lightened(0.08)]))
		if kind == "indy":
			DrawKit.ellipse(self, Vector2(24 * fx, -13 + breathe), 6.0, 5.0, patch)
		else:
			DrawKit.star(self, Vector2(-6 * fx, -14 + breathe), 5.0, Color("efece4"))
		draw_circle(Vector2(42 * fx, -4 + breathe), 2.6, Color("3a3a44"))
		# a closed eye, and paws tucked in front
		draw_arc(Vector2(31 * fx, -12 + breathe), 3.4, 0.2, PI - 0.2, 8, Color("3a3a44"), 1.6, true)
		for px in [16.0, 26.0]:
			DrawKit.ellipse(self, Vector2(px * fx, -1), 7.0, 4.0, body.darkened(0.04))
		# sleepy zeds drifting up
		var font := ThemeDB.fallback_font
		for i in 2:
			var u := fmod(t * 0.4 + i * 0.5, 1.0)
			draw_string(font, Vector2(34 * fx + u * 12.0, -34 - u * 26.0), "z",
				HORIZONTAL_ALIGNMENT_LEFT, -1, int(13 + u * 7),
				Color(0.36, 0.34, 0.3, (1.0 - u) * 0.55))

## and she can stand on top. Not interactable — the world handles collision.
class Block extends Node2D:
	var kind := "crate"    # crate | rock | log
	var w := 120.0
	var h := 70.0

	func rect() -> Rect2:
		return Rect2(global_position + Vector2(-w * 0.5, -h), Vector2(w, h))

	func _draw() -> void:
		DrawKit.soft_shadow(self, Vector2(0, 1), w * 0.55, 0.13)
		match kind:
			"crate":
				var wood := Color("c9a06c")
				DrawKit.rounded_rect(self, Rect2(-w * 0.5, -h, w, h), 7.0, wood)
				# horizontal slats with grain and gaps
				var slats := 3
				for i in slats:
					var sy := -h + 6.0 + i * (h - 12.0) / slats
					var sh := (h - 12.0) / slats - 3.0
					DrawKit.vgrad(self, Rect2(-w * 0.5 + 6, sy, w - 12, sh),
						Color("c59a63"), Color("b1854f"))
					draw_line(Vector2(-w * 0.5 + 10, sy + sh * 0.4), Vector2(w * 0.5 - 14, sy + sh * 0.42),
						Color(0.55, 0.4, 0.24, 0.4), 1.5)
				# corner braces and nail heads
				draw_rect(Rect2(-w * 0.5 + 3, -h + 3, 9, h - 6), Color("a97e54"))
				draw_rect(Rect2(w * 0.5 - 12, -h + 3, 9, h - 6), Color("b98d5c"))
				for nx in [-w * 0.5 + 7.5, w * 0.5 - 7.5]:
					for ny in [-h + 9.0, -9.0]:
						draw_circle(Vector2(nx, ny), 1.8, Color("77573d"))
						draw_circle(Vector2(nx - 0.6, ny - 0.6), 0.8, Color("d9c8a8"))
				# lit top edge
				draw_rect(Rect2(-w * 0.5 + 3, -h, w - 6, 4), wood.lightened(0.15))
			"rock":
				var stone := Color("a8b2b8")
				# craggy silhouette with facet shading
				DrawKit.blob(self, Vector2(0, -h * 0.5), w * 0.52, h * 0.54, stone.darkened(0.12), int(absf(global_position.x)), 0.1)
				DrawKit.blob(self, Vector2(1, -h * 0.52), w * 0.47, h * 0.48, stone, int(absf(global_position.x)) + 1, 0.1)
				draw_polygon(PackedVector2Array([
					Vector2(w * 0.05, -h), Vector2(w * 0.4, -h * 0.6),
					Vector2(w * 0.1, -h * 0.4), Vector2(-w * 0.1, -h * 0.7),
				]), PackedColorArray([stone.lightened(0.12)]))
				draw_polygon(PackedVector2Array([
					Vector2(-w * 0.38, -h * 0.5), Vector2(-w * 0.1, -h * 0.6),
					Vector2(-w * 0.14, -h * 0.2), Vector2(-w * 0.4, -h * 0.25),
				]), PackedColorArray([stone.darkened(0.08)]))
				# cracks and speckles
				draw_line(Vector2(-w * 0.05, -h * 0.85), Vector2(w * 0.08, -h * 0.5), stone.darkened(0.25), 1.5)
				draw_line(Vector2(w * 0.08, -h * 0.5), Vector2(w * 0.02, -h * 0.3), stone.darkened(0.25), 1.2)
				for i in 6:
					draw_circle(Vector2(sin(i * 2.3) * w * 0.3, -h * (0.3 + 0.1 * i)), 1.4,
						stone.darkened(0.15) if i % 2 == 0 else stone.lightened(0.1))
				# mossy top
				DrawKit.blob(self, Vector2(-w * 0.08, -h + 6.0), w * 0.32, 8.0, Color("8cc188"), 31, 0.2)
				DrawKit.blob(self, Vector2(w * 0.2, -h + 8.0), w * 0.14, 6.0, Color("9ccf8f"), 32, 0.2)
			"log":
				var bark := Color("a97e54")
				DrawKit.rounded_rect(self, Rect2(-w * 0.5, -h, w, h), h * 0.4, bark)
				# bark ridges wrapping the barrel
				for i in 4:
					var yy := -h + 9.0 + i * (h - 16.0) / 3.0
					draw_line(Vector2(-w * 0.5 + 8, yy), Vector2(w * 0.5 - 20, yy + 2.0),
						bark.darkened(0.14), 2.5)
					draw_line(Vector2(-w * 0.5 + 12, yy + 3.0), Vector2(w * 0.42 - 20, yy + 4.5),
						bark.lightened(0.08), 1.2)
				# lit top and shaded belly of the barrel
				DrawKit.rounded_rect(self, Rect2(-w * 0.5, -h, w, 8), h * 0.35, bark.lightened(0.12))
				DrawKit.rounded_rect(self, Rect2(-w * 0.5, -9, w, 9), h * 0.3, bark.darkened(0.12))
				# sawn end with growth rings
				DrawKit.ellipse(self, Vector2(w * 0.5 - 9.0, -h * 0.5), 10.0, h * 0.42, Color("d9b485"))
				for ring in 3:
					var rr := 1.0 - ring * 0.28
					draw_arc(Vector2(w * 0.5 - 9.0, -h * 0.5), 8.0 * rr, 0, TAU, 14,
						Color("b98d5c").darkened(ring * 0.05), 1.3, true)
				draw_circle(Vector2(w * 0.5 - 9.0, -h * 0.5), 1.5, Color("a97e54"))
				# little sprout and a mushroom
				draw_line(Vector2(-w * 0.25, -h), Vector2(-w * 0.25 - 4, -h - 12), Color("7fb87a"), 2.5)
				DrawKit.ellipse(self, Vector2(-w * 0.25 - 6, -h - 13), 4.5, 2.5, Color("9ccf8f"))
				DrawKit.ellipse(self, Vector2(-w * 0.25 - 1, -h - 12), 3.5, 2.0, Color("8cc188"))
				draw_line(Vector2(w * 0.15, -h), Vector2(w * 0.15, -h - 5), Color("e8dcc8"), 2.5)
				DrawKit.ellipse(self, Vector2(w * 0.15, -h - 5), 5.0, 2.8, Color("d98f7a"))
				draw_circle(Vector2(w * 0.14, -h - 6), 1.0, Color(1, 1, 1, 0.8))


## A leafy vine hanging from a canopy. Summer grabs it mid-jump; single taps
## beside her pump up a swing, taps above/below shimmy her along it, and a
## double-tap launches her off toward the tap (with the swing's momentum).
class Vine extends Node2D:
	var length := 130.0
	var t := randf() * TAU
	var swing_amp := 0.0        # pumped by Summer, decays gently
	var swing_ph := 0.0
	var ang_vel := 0.0          # rad/s — launch momentum for the player
	var _prev_angle := 0.0

	func min_d() -> float:
		return 26.0

	func max_d() -> float:
		return length - 4.0

	func _process(delta: float) -> void:
		t += delta
		swing_ph += delta * 2.4
		swing_amp = maxf(0.0, swing_amp - delta * 0.1)
		var a := angle()
		ang_vel = (a - _prev_angle) / maxf(delta, 0.0001)
		_prev_angle = a
		queue_redraw()

	## Push the swing toward dir (+1 right, -1 left). Positive vine angle
	## tilts the tip LEFT (see point_at), hence the inverted phase seeding.
	func pump(dir: float) -> void:
		if swing_amp < 0.06:
			swing_ph = PI if dir > 0.0 else 0.0
		swing_amp = minf(swing_amp + 0.17, 0.5)

	func angle() -> float:
		return sin(t * 0.8) * 0.07 + sin(swing_ph) * swing_amp

	## Global position of the rope at distance d below the anchor.
	func point_at(d: float) -> Vector2:
		return global_position + Vector2.from_angle(PI / 2.0 + angle() * d / length) * d

	## Is a reaching hand close enough to the rope to grab it?
	func near(hand: Vector2) -> bool:
		var d := (hand - global_position).length()
		if d < min_d() - 10.0 or d > max_d() + 16.0:
			return false
		var p := point_at(clampf(d, min_d(), max_d()))
		return absf(hand.x - p.x) < 34.0 and hand.y > global_position.y + 10.0

	## A pointed leaf at p, angled a, length l.
	func _leaf(p: Vector2, a: float, l: float, col: Color) -> void:
		var dirv := Vector2.from_angle(a)
		var norm := dirv.orthogonal()
		draw_polygon(PackedVector2Array([
			p, p + dirv * l * 0.4 + norm * l * 0.24, p + dirv * l,
			p + dirv * l * 0.4 - norm * l * 0.24,
		]), PackedColorArray([col]))
		draw_line(p, p + dirv * l * 0.85, col.darkened(0.14), 1.0)

	func _draw() -> void:
		var rope := Color("6f9a5d")
		var leaf := Color("8cc188")
		var prev := Vector2.ZERO
		var segs := 7
		for i in range(1, segs + 1):
			var d := length * float(i) / float(segs)
			var p := Vector2.from_angle(PI / 2.0 + angle() * d / length) * d
			draw_line(prev, p, rope, 5.5)
			draw_line(prev, p, rope.darkened(0.18), 1.8)   # twisted strand
			draw_line(prev + Vector2(1.5, 0), p + Vector2(1.5, 0), rope.lightened(0.12), 1.2)
			var seg_a := (p - prev).angle()
			if i % 2 == 0:
				_leaf(p, seg_a - 1.9, 13.0, leaf)
				_leaf(p, seg_a - 2.5, 10.0, leaf.lightened(0.08))
			else:
				_leaf(p, seg_a + 1.9, 12.0, leaf.darkened(0.08))
			prev = p
		draw_circle(prev, 5.0, rope.darkened(0.1))   # curled tip
		_leaf(prev, PI * 0.35, 11.0, leaf)
		_leaf(prev, PI * 0.75, 11.0, leaf.darkened(0.06))
		draw_circle(Vector2.ZERO, 6.0, Color("8a6a52"))  # knot at the branch
		draw_circle(Vector2(-1.5, -1.5), 2.2, Color("9a7a5e"))


## A little wooden lookout perch — a one-way platform. Summer can land on it
## from above (vine launch or a block hop) but walks freely underneath it.
class Platform extends Node2D:
	var w := 170.0

	## The stand-on surface (thin), in global space. position is the plank top.
	func rect() -> Rect2:
		return Rect2(global_position + Vector2(-w * 0.5, 0), Vector2(w, 10))

	func _draw() -> void:
		var wood := Color("a97e54")
		var to_ground := 600.0 - global_position.y
		DrawKit.soft_shadow(self, Vector2(0, to_ground + 1.0), w * 0.42, 0.1)
		# stilts reach down to the meadow floor (parent places us above it)
		for sx in [-w * 0.5 + 18.0, w * 0.5 - 18.0]:
			draw_line(Vector2(sx, 8), Vector2(sx * 0.85, to_ground), wood.darkened(0.16), 9.0)
			draw_line(Vector2(sx - 2, 8), Vector2(sx * 0.85 - 2, to_ground), wood.darkened(0.28), 2.5)
			draw_line(Vector2(sx + 2.5, 8), Vector2(sx * 0.85 + 2.5, to_ground), wood.darkened(0.04), 2.0)
		draw_line(Vector2(-w * 0.35, to_ground * 0.55), Vector2(w * 0.35, to_ground * 0.3), wood.darkened(0.22), 5.0)
		draw_line(Vector2(w * 0.35, to_ground * 0.55), Vector2(-w * 0.35, to_ground * 0.3), wood.darkened(0.3), 4.0)
		# plank deck: lit top, shaded lip, board seams
		DrawKit.rounded_rect(self, Rect2(-w * 0.5, -6, w, 16), 6.0, Color("c9a06c"))
		DrawKit.rounded_rect(self, Rect2(-w * 0.5, -6, w, 5), 4.0, Color("d9b485"))
		DrawKit.rounded_rect(self, Rect2(-w * 0.5, 6, w, 4), 3.0, Color("a97e54"))
		for i in 4:
			var lx := -w * 0.5 + 14.0 + i * (w - 28.0) / 3.0
			draw_line(Vector2(lx, -4), Vector2(lx, 8), Color("b58d5c"), 3.0)
			draw_circle(Vector2(lx, -1), 1.2, Color("8a6a44"))
		# bunting, because every lookout needs bunting
		var cols := [Color("f2b8cf"), Color("ffe6b3"), Color("a9c9e8")]
		draw_arc(Vector2(0, 2), w * 0.36, PI * 0.15, PI * 0.85, 12, Color("d9c8a8"), 1.5, true)
		for i in 3:
			var bx := -w * 0.3 + i * w * 0.3
			var flag := PackedVector2Array([
				Vector2(bx - 9, -6), Vector2(bx + 9, -6), Vector2(bx, 12),
			])
			draw_polygon(flag, PackedColorArray([cols[i]]))
			draw_polygon(PackedVector2Array([
				Vector2(bx - 9, -6), Vector2(bx - 2, -6), Vector2(bx - 1, 6),
			]), PackedColorArray([Color(cols[i]).darkened(0.07)]))


## A butterfly fluttering near the flowers. With the net out and Summer close,
## a tap catches it for a moment of wonder — then it flutters free again
## (everything in this game is catch-and-release). Without the net it just
## dances out of reach.
class Butterfly extends Node2D:
	var home := Vector2.ZERO
	var t := randf() * TAU
	var away_t := 0.0          # >0 while caught/released and off having a rest
	var wing_col := Color("c4a8e0")

	func _ready() -> void:
		home = position
		if randf() < 0.5:
			wing_col = Color("f2b8cf")

	func _process(delta: float) -> void:
		t += delta
		if away_t > 0.0:
			away_t -= delta
			if away_t <= 0.0:
				position = home
				modulate.a = 0.0
				show()
				create_tween().tween_property(self, "modulate:a", 1.0, 1.2)
			return
		position = home + Vector2(sin(t * 0.7) * 60.0, sin(t * 1.3) * 28.0 + cos(t * 0.4) * 14.0)
		queue_redraw()

	func tap_score(wp: Vector2) -> float:
		if not visible or away_t > 0.0:
			return 0.0
		return clampf(1.0 - (wp - global_position).length() / 70.0, 0.0, 1.0)

	## Tapped without the net: it playfully dips away. (Catching is main.gd's
	## job, because it needs to know about the net.)
	func try_tap(_wp: Vector2) -> bool:
		var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "home", home + Vector2(randf_range(-40, 40), -30.0), 0.5)
		tw.tween_property(self, "home", home, 1.2)
		return true

	func get_caught(net_pos: Vector2, parent: Node) -> void:
		Fx.sparkles(parent, global_position, 6, wing_col)
		Fx.hearts(parent, net_pos + Vector2(0, -30), 2)
		var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "position", net_pos, 0.35)
		tw.tween_interval(1.1)
		tw.tween_property(self, "position", net_pos + Vector2(randf_range(-60, 60), -260.0), 1.4)
		tw.parallel().tween_property(self, "modulate:a", 0.0, 1.4)
		tw.tween_callback(func() -> void:
			hide()
			modulate.a = 1.0
			away_t = randf_range(24.0, 45.0))

	func _draw() -> void:
		var flap := absf(sin(t * 9.0))
		var spread := 0.35 + 0.65 * flap
		# each side: a big upper wing lobe and a smaller lower one, with
		# darker edging and a pale spot — squashed by the flap
		for side in [-1.0, 1.0]:
			var sx: float = side * spread
			draw_polygon(PackedVector2Array([
				Vector2(0, -4), Vector2(sx * 9.0, -12), Vector2(sx * 14.0, -6),
				Vector2(sx * 11.0, 0), Vector2(sx * 3.0, 0),
			]), PackedColorArray([wing_col.darkened(0.12)]))
			draw_polygon(PackedVector2Array([
				Vector2(0, -4), Vector2(sx * 8.0, -10.5), Vector2(sx * 12.0, -6),
				Vector2(sx * 9.5, -0.5), Vector2(sx * 3.0, -0.5),
			]), PackedColorArray([wing_col]))
			draw_polygon(PackedVector2Array([
				Vector2(0, 0), Vector2(sx * 8.0, 2.0), Vector2(sx * 6.5, 7.0), Vector2(sx * 1.5, 4.0),
			]), PackedColorArray([wing_col.lightened(0.12)]))
			draw_circle(Vector2(sx * 8.0, -6.0), 2.0 * spread, wing_col.lightened(0.25))
			draw_circle(Vector2(sx * 5.0, 3.0), 1.2 * spread, Color(1, 1, 1, 0.6))
		# segmented body, little head, curled antennae
		DrawKit.ellipse(self, Vector2(0, -1), 1.9, 6.0, Color("6e5a48"))
		DrawKit.ellipse(self, Vector2(0, 2), 1.5, 3.0, Color("5c4a3a"))
		draw_circle(Vector2(0, -7), 2.0, Color("6e5a48"))
		draw_line(Vector2(-0.5, -8.5), Vector2(-3.0, -12.0), Color("6e5a48"), 0.9)
		draw_line(Vector2(0.5, -8.5), Vector2(3.0, -12.0), Color("6e5a48"), 0.9)
		draw_circle(Vector2(-3.2, -12.2), 0.8, Color("6e5a48"))
		draw_circle(Vector2(3.2, -12.2), 0.8, Color("6e5a48"))


## Gentle water-drop thought bubble — Summer is a little thirsty. Tapping it
## (or the bottle in her backpack) gives her a sip. Nothing happens if it's
## ignored; being thirsty is never a problem, just a nudge.
class ThirstBubble extends Node2D:
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func try_tap(wp: Vector2) -> bool:
		return (wp - global_position).length() < 55.0

	func _draw() -> void:
		var r := 34.0 + sin(t * 3.0) * 2.0
		draw_circle(Vector2(0, 3), r, Color(0, 0, 0, 0.06))
		draw_circle(Vector2.ZERO, r, Color(1, 1, 1, 0.9))
		draw_circle(Vector2(-r * 0.7, r * 0.75), 7.0, Color(1, 1, 1, 0.9))
		draw_circle(Vector2(-r * 0.95, r * 1.1), 4.0, Color(1, 1, 1, 0.9))
		# the water drop
		var blue := Color("8ac0d6")
		draw_circle(Vector2(0, 4), 13.0, blue)
		draw_polygon(PackedVector2Array([
			Vector2(-9, -2), Vector2(9, -2), Vector2(0, -20),
		]), PackedColorArray([blue]))
		draw_circle(Vector2(-4, 2), 3.5, Color("cfe9f4"))


## The same gentle nudge, for a snack. Tapping it opens the picnic so she can
## build a sandwich and eat it. Like the thirst bubble it never nags — it just
## floats there being friendly, and drifts off once she has eaten.
class HungerBubble extends Node2D:
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func try_tap(wp: Vector2) -> bool:
		return (wp - global_position).length() < 55.0

	func _draw() -> void:
		var r := 34.0 + sin(t * 2.6) * 2.0
		draw_circle(Vector2(0, 3), r, Color(0, 0, 0, 0.06))
		draw_circle(Vector2.ZERO, r, Color(1, 1, 1, 0.9))
		draw_circle(Vector2(r * 0.7, r * 0.75), 7.0, Color(1, 1, 1, 0.9))
		draw_circle(Vector2(r * 0.95, r * 1.1), 4.0, Color(1, 1, 1, 0.9))
		# a little sandwich
		draw_polygon(PackedVector2Array([
			Vector2(-15, -3), Vector2(15, -3), Vector2(12, -14), Vector2(-12, -14),
		]), PackedColorArray([Color("e8c88a")]))
		draw_rect(Rect2(-15, -3, 30, 5), Color("8fc48a"))
		draw_rect(Rect2(-15, 2, 30, 8), Color("e8c88a"))
		draw_rect(Rect2(-15, 10, 30, 2), Color("d9b678"))


## A building bit lying in the meadow — a stick, a plank or a coil of rope
## vine. Tap to collect it for the treehouse.
class MaterialPickup extends Node2D:
	var kind := "stick"

	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position - Vector2(0, -10.0)).length() / 60.0, 0.0, 1.0)

	func try_tap(wp: Vector2) -> bool:
		return (wp - global_position - Vector2(0, -10.0)).length() < 60.0

	func _draw() -> void:
		DrawKit.soft_shadow(self, Vector2(0, 1), 22.0, 0.1)
		match kind:
			"stick":
				draw_line(Vector2(-20, -2), Vector2(20, -12), Color("55381f"), 7.0)
				draw_line(Vector2(-20, -2), Vector2(20, -12), Color("8a6242"), 4.5)
				draw_line(Vector2(-2, -7), Vector2(10, -20), Color("8a6242"), 3.0)
				draw_line(Vector2(6, -9), Vector2(14, -6), Color("77573d"), 2.5)
				DrawKit.ellipse(self, Vector2(12, -22), 4.0, 2.5, Color("8cc188"))
			"plank":
				draw_set_transform(Vector2(0, -7), -0.12, Vector2.ONE)
				DrawKit.rounded_rect(self, Rect2(-24, -6, 48, 12), 3.5, Color("55381f"))
				DrawKit.rounded_rect(self, Rect2(-22.5, -4.8, 45, 9.6), 3.0, Color("c9a06c"))
				draw_line(Vector2(-16, -1), Vector2(17, 0), Color("a97e54"), 1.6)
				draw_line(Vector2(-14, 2), Vector2(10, 2.5), Color("b98d5c"), 1.2)
				draw_circle(Vector2(-18, -1), 1.5, Color("8a6a44"))
				draw_circle(Vector2(18, -1), 1.5, Color("8a6a44"))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"rope":
				DrawKit.ellipse(self, Vector2(0, -8), 15.0, 11.0, Color("3f5c30"))
				DrawKit.ellipse(self, Vector2(0, -8), 12.5, 8.8, Color("6f9a5d"))
				DrawKit.ellipse(self, Vector2(0, -8), 8.0, 5.5, Color("55763f"))
				DrawKit.ellipse(self, Vector2(0, -8), 4.5, 3.0, Color("8fc48a"))
				draw_line(Vector2(10, -14), Vector2(20, -20), Color("6f9a5d"), 3.0)
				draw_circle(Vector2(20, -20), 2.0, Color("55763f"))
				draw_line(Vector2(-4, -14), Vector2(4, -13), Color("3f5c30"), 2.0)


## A round little owl perched on a branch stub — blinks slowly, and gives a
## soft hoot (and a flap) when tapped.
class Owl extends Node2D:
	var t := randf() * TAU
	var blink_t := 0.0
	var blink_in := 3.0
	var flap_t := 0.0
	var tilt := 0.0

	func _process(delta: float) -> void:
		t += delta
		flap_t = maxf(0.0, flap_t - delta)
		tilt = move_toward(tilt, 0.0, delta * 0.25)
		if blink_t > 0.0:
			blink_t = maxf(0.0, blink_t - delta)
		else:
			blink_in -= delta
			if blink_in <= 0.0:
				blink_t = 0.16
				blink_in = randf_range(2.5, 6.0)
		queue_redraw()

	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position - Vector2(0, -20.0)).length() / 65.0, 0.0, 1.0)

	func try_tap(wp: Vector2) -> bool:
		if (wp - global_position - Vector2(0, -20.0)).length() < 65.0:
			Sound.hoot()
			flap_t = 0.9
			tilt = randf_range(-0.22, 0.22)
			Fx.hearts(get_parent(), global_position + Vector2(0, -55.0), 2)
			return true
		return false

	func _draw() -> void:
		var body := Color("9a7a5e")
		var breast := Color("e8dcc8")
		var bob := sin(t * 1.6) * 1.2
		# the branch stub she perches on
		draw_line(Vector2(-26, 2), Vector2(26, -2), Color("55381f"), 9.0)
		draw_line(Vector2(-26, 2), Vector2(26, -2), Color("8a6242"), 6.0)
		draw_line(Vector2(18, -3), Vector2(30, -10), Color("8a6242"), 4.0)
		# wings: folded at her sides, or flapping up when tapped
		var wing_a := 0.0
		if flap_t > 0.0:
			wing_a = absf(sin(flap_t * 12.0)) * 1.1
		for side in [-1.0, 1.0]:
			draw_set_transform(Vector2(side * 11.0, -18.0 + bob), -side * wing_a, Vector2.ONE)
			DrawKit.ellipse(self, Vector2(side * 2.0, 0), 6.5, 13.0, body.darkened(0.35))
			DrawKit.ellipse(self, Vector2(side * 2.0, 0), 5.5, 12.0, body.darkened(0.14))
			for f in 2:
				draw_arc(Vector2(side * 2.0, 3.0 + f * 4.0), 4.0, PI * 0.15, PI * 0.85, 6,
					body.darkened(0.28), 1.4, true)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# plump body with a cream breast and chevron feathers
		DrawKit.ellipse(self, Vector2(0, -17 + bob), 13.5, 16.5, body.darkened(0.35))
		DrawKit.ellipse(self, Vector2(0, -17 + bob), 12.5, 15.5, body)
		DrawKit.ellipse(self, Vector2(0, -14 + bob), 8.0, 11.0, breast)
		for row in 3:
			for cc in 2 + row % 2:
				var chx := (cc - (0.5 + (row % 2) * 0.5)) * 7.0
				var chp := Vector2(chx, -20.0 + row * 5.0 + bob)
				draw_arc(chp, 2.6, PI * 0.15, PI * 0.85, 6, Color("c9b393"), 1.3, true)
		# head — drawn with a little tilt when she's curious
		draw_set_transform(Vector2(0, -30 + bob), tilt, Vector2.ONE)
		draw_circle(Vector2.ZERO, 11.8, body.darkened(0.35))
		draw_circle(Vector2.ZERO, 10.8, body)
		# ear tufts
		for side in [-1.0, 1.0]:
			draw_polygon(PackedVector2Array([
				Vector2(side * 4.0, -8.0), Vector2(side * 12.0, -15.0), Vector2(side * 8.5, -5.5),
			]), PackedColorArray([body.darkened(0.12)]))
		# big facial-disc eyes with amber irises
		for side in [-1.0, 1.0]:
			var ec := Vector2(side * 5.2, -1.0)
			draw_circle(ec, 5.4, body.darkened(0.25))
			draw_circle(ec, 4.6, Color("f6f1e4"))
			if blink_t > 0.0:
				draw_arc(ec, 2.6, PI * 0.1, PI * 0.9, 8, Color("4a3a30"), 1.6, true)
			else:
				draw_circle(ec, 2.9, Color("d9a940"))
				draw_circle(ec, 1.7, Color("3a3028"))
				draw_circle(ec + Vector2(-0.6, -0.7), 0.7, Color.WHITE)
		# beak
		draw_polygon(PackedVector2Array([
			Vector2(-2.2, 2.5), Vector2(2.2, 2.5), Vector2(0, 7.0),
		]), PackedColorArray([Color("e8a83c")]))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# little feet gripping the branch
		for tx in [-5.0, 1.0, 7.0]:
			draw_line(Vector2(tx, -3 + bob * 0.3), Vector2(tx - 1.0, 1.0), Color("e8a83c"), 2.0)


## The hole left after a dig — fades away slowly on its own.
class Hole extends Node2D:
	func _draw() -> void:
		# rim, then deepening shadow inside
		DrawKit.ellipse(self, Vector2.ZERO, 27.0, 11.0, Color("8a6a48"))
		DrawKit.ellipse(self, Vector2.ZERO, 25.0, 10.0, Color("6e5138"))
		DrawKit.ellipse(self, Vector2(0, -1.0), 20.0, 7.5, Color("543d2a"))
		DrawKit.ellipse(self, Vector2(0, -1.5), 13.0, 4.5, Color("3e2c1e"))
		# lit inner lip at the back
		draw_arc(Vector2(0, -2), 21.0, PI + 0.4, TAU - 0.4, 12, Color("9d7a55"), 2.5, true)
		# heaped spoil either side, shaded
		for mound in [[-31.0, -3.0, 8.0], [33.0, -2.0, 9.0], [40.0, -7.0, 5.0]]:
			DrawKit.blob(self, Vector2(mound[0], mound[1]), mound[2], mound[2] * 0.7,
				Color("a67c58"), int(mound[0]) + 50, 0.2)
			DrawKit.blob(self, Vector2(mound[0] + 1.5, mound[1] - 2.0), mound[2] * 0.55, mound[2] * 0.4,
				Color("b98d68"), int(mound[0]) + 51, 0.2)
		# a few crumbs
		for i in 5:
			draw_circle(Vector2(-40.0 + i * 19.0, 4.0 + sin(i * 2.0) * 2.0), 1.8, Color("a67c58"))


## Soft twinkle over a buried spot — fades in as Summer gets close, so she
## always has a visual hint as well as the tone.
class HintSparkle extends Node2D:
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		rotation = sin(t * 1.5) * 0.2
		queue_redraw()

	func _draw() -> void:
		var s := 8.0 + sin(t * 4.0) * 2.5
		DrawKit.star(self, Vector2.ZERO, s, Color("ffd98a"))
		DrawKit.star(self, Vector2(14, -10), s * 0.5, Color("ffe6b3"))
