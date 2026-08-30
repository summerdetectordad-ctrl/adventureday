class_name Nature
extends Node
## All the world pieces, drawn in code. Each is based on a real Adventure Day:
## the treehouse build, blackberry hunt, catching frogs, tadpoles and the
## bird's nest, bike adventures, picnics in the park. Interactable pieces have
## try_tap(world_pos) -> bool: return true if the tap was theirs.


## Full-screen sky with drifting clouds and a soft sun. Lives on its own
## CanvasLayer behind the world, fixed to the screen.
class SkyBackdrop extends Control:
	var clouds: Array = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fit()
		get_viewport().size_changed.connect(_fit)
		for i in 4:
			clouds.append({
				"p": Vector2(randf_range(0, 1400), randf_range(50, 260)),
				"sp": randf_range(6.0, 14.0),
				"s": randf_range(0.7, 1.3),
			})

	func _fit() -> void:
		position = Vector2.ZERO
		size = get_viewport().get_visible_rect().size

	func _process(delta: float) -> void:
		var w := size.x
		for cl in clouds:
			var p: Vector2 = cl["p"]
			p.x += cl["sp"] * delta
			if p.x > w + 160.0:
				p.x = -160.0
			cl["p"] = p
		queue_redraw()

	func _draw() -> void:
		var vs := size
		draw_polygon(PackedVector2Array([
			Vector2.ZERO, Vector2(vs.x, 0), vs, Vector2(0, vs.y),
		]), PackedColorArray([
			Color("c3e2f2"), Color("c3e2f2"), Color("eef7fb"), Color("eef7fb"),
		]))
		var sun := Vector2(vs.x - 170, 130)
		draw_circle(sun, 78.0, Color(1.0, 0.87, 0.6, 0.25))
		draw_circle(sun, 55.0, Color("ffd98a"))
		draw_circle(sun, 42.0, Color("ffe6b3"))
		for cl in clouds:
			var p: Vector2 = cl["p"]
			var s: float = 34.0 * cl["s"]
			var col := Color(1, 1, 1, 0.85)
			draw_circle(p, s, col)
			draw_circle(p + Vector2(-s, s * 0.3), s * 0.7, col)
			draw_circle(p + Vector2(s, s * 0.3), s * 0.7, col)


## Static ground, hills, flowers and grass across the whole world width.
class WorldBG extends Node2D:
	var world_w := 4200.0
	var ground_y := 600.0

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		# soft distant hills — the windy hills of the Roman coin hunt
		for i in 9:
			var hx := i * 520.0 + rng.randf_range(-120.0, 120.0)
			DrawKit.ellipse(self, Vector2(hx, ground_y + 60.0), rng.randf_range(320.0, 460.0),
				rng.randf_range(110.0, 170.0), Color("bcd9b4"))
		# ground
		draw_rect(Rect2(0, ground_y, world_w, 320), Color("b9906b"))
		draw_rect(Rect2(0, ground_y - 14, world_w, 26), Color("8fc48a"))
		# buried-layer speckles
		for i in 170:
			draw_circle(Vector2(rng.randf_range(0, world_w), rng.randf_range(ground_y + 34, ground_y + 300)),
				rng.randf_range(2.0, 5.0), Color("a67c58"))
		# grass tufts
		for i in 110:
			var gx := rng.randf_range(20, world_w - 20)
			for b in 3:
				var lean := (b - 1) * 4.0
				draw_line(Vector2(gx + lean, ground_y - 10), Vector2(gx + lean * 1.8, ground_y - 24 - rng.randf_range(0, 6)),
					Color("7fb87a"), 2.5)
		# little flowers
		var petals := [Color("f2b8cf"), Color("ffe6b3"), Color("c4b8e8"), Color("ffffff")]
		for i in 46:
			var fpos := Vector2(rng.randf_range(30, world_w - 30), ground_y - 26 - rng.randf_range(0, 8))
			draw_line(fpos + Vector2(0, 14), fpos, Color("7fb87a"), 2.0)
			var pc: Color = petals[rng.randi() % petals.size()]
			for pa in 5:
				draw_circle(fpos + Vector2.from_angle(TAU * pa / 5.0) * 4.5, 3.2, pc)
			draw_circle(fpos, 2.6, Color("ffd98a"))


## Big background tree (non-interactive).
class MeadowTree extends Node2D:
	var tint := 0.0

	func _draw() -> void:
		draw_polygon(PackedVector2Array([
			Vector2(-14, 0), Vector2(14, 0), Vector2(8, -150), Vector2(-8, -150),
		]), PackedColorArray([Color("8a6a52")]))
		var leaf := Color("9ccf8f").darkened(tint)
		draw_circle(Vector2(0, -190), 62.0, leaf)
		draw_circle(Vector2(-48, -160), 46.0, leaf.darkened(0.05))
		draw_circle(Vector2(48, -160), 46.0, leaf.lightened(0.05))
		draw_circle(Vector2(0, -140), 40.0, leaf)


## The treehouse — home, and the door to the museum. Built together over two
## real Adventure Days.
class Treehouse extends Node2D:
	func door_rect() -> Rect2:
		return Rect2(global_position + Vector2(-40, -104), Vector2(80, 104))

	func _draw() -> void:
		var trunk := Color("8a6a52")
		var leaf := Color("9ccf8f")
		var plank := Color("c9a06c")
		# trunk
		draw_polygon(PackedVector2Array([
			Vector2(-34, 0), Vector2(34, 0), Vector2(22, -280), Vector2(-22, -280),
		]), PackedColorArray([trunk]))
		draw_line(Vector2(-6, -40), Vector2(-2, -150), trunk.darkened(0.12), 4.0)
		# canopy
		draw_circle(Vector2(0, -330), 105.0, leaf)
		draw_circle(Vector2(-85, -290), 70.0, leaf.darkened(0.06))
		draw_circle(Vector2(85, -290), 70.0, leaf.lightened(0.06))
		draw_circle(Vector2(0, -255), 60.0, leaf.darkened(0.03))
		# platform + house nestled in the canopy
		draw_rect(Rect2(-85, -262, 170, 12), plank.darkened(0.1))
		DrawKit.rounded_rect(self, Rect2(-62, -352, 124, 92), 10.0, plank)
		draw_polygon(PackedVector2Array([
			Vector2(-74, -352), Vector2(74, -352), Vector2(0, -404),
		]), PackedColorArray([Color("b57f4d")]))
		draw_circle(Vector2(0, -310), 20.0, Color("8fd7e8"))
		draw_arc(Vector2(0, -310), 20.0, 0, TAU, 20, Color("8a6a44"), 3.5, true)
		draw_line(Vector2(-20, -310), Vector2(20, -310), Color("8a6a44"), 2.5)
		draw_line(Vector2(0, -330), Vector2(0, -290), Color("8a6a44"), 2.5)
		# ladder up the trunk
		for i in 6:
			var ly := -60.0 - i * 34.0
			draw_line(Vector2(-16, ly), Vector2(16, ly), plank.darkened(0.2), 5.0)
		draw_line(Vector2(-16, -46), Vector2(-16, -252), plank.darkened(0.25), 4.0)
		draw_line(Vector2(16, -46), Vector2(16, -252), plank.darkened(0.25), 4.0)
		# door at the base — into the museum
		var arch := Color("6b4f3a")
		DrawKit.rounded_rect(self, Rect2(-26, -88, 52, 88), 20.0, arch)
		DrawKit.rounded_rect(self, Rect2(-20, -82, 40, 82), 16.0, Color("7d5c44"))
		draw_circle(Vector2(12, -40), 3.5, Color("d9b45c"))
		# welcome pebbles
		draw_circle(Vector2(-38, 4), 5.0, Color("cbb59a"))
		draw_circle(Vector2(40, 6), 4.0, Color("cbb59a"))


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
		GameState.berries_picked = (GameState.berries_picked % 20) + 1
		Fx.float_number(get_parent(), wp + Vector2(0, -24), GameState.berries_picked)
		queue_redraw()
		return true

	func _draw() -> void:
		draw_circle(Vector2(-30, -34), 40.0, Color("7fbf83"))
		draw_circle(Vector2(30, -34), 40.0, Color("8cc188"))
		draw_circle(Vector2(0, -52), 44.0, Color("9ccf8f"))
		for b in berries:
			var off: Vector2 = b["off"]
			if b["ripe"]:
				draw_circle(off, 7.0, Color("6d4788"))
				draw_circle(off + Vector2(-2, -2), 2.2, Color("9a72b5"))
			else:
				draw_circle(off, 4.0, Color("a8c48f"))


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
		DrawKit.ellipse(self, Vector2(0, -10), 20.0, 14.0, green)
		draw_circle(Vector2(-9, -24), 7.0, green)
		draw_circle(Vector2(9, -24), 7.0, green)
		draw_circle(Vector2(-9, -25), 3.6, Color.WHITE)
		draw_circle(Vector2(9, -25), 3.6, Color.WHITE)
		draw_circle(Vector2(-9, -25), 1.8, Color("3a3a44"))
		draw_circle(Vector2(9, -25), 1.8, Color("3a3a44"))
		draw_arc(Vector2(0, -12), 7.0, 0.4, PI - 0.4, 8, Color("5c8a4d"), 2.0, true)
		DrawKit.ellipse(self, Vector2(-16, -2), 8.0, 4.5, green.darkened(0.08))
		DrawKit.ellipse(self, Vector2(16, -2), 8.0, 4.5, green.darkened(0.08))


## Pond with wiggling tadpoles, lily pads and two frogs to tap.
class Pond extends Node2D:
	var tads: Array = []

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
		for td in tads:
			td["a"] += td["sp"] * delta
			td["ph"] += delta * 8.0
		queue_redraw()

	func try_tap(wp: Vector2) -> bool:
		for child in get_children():
			if child is Frog and (wp - child.global_position).length() < 55.0:
				child.hop()
				return true
		var lp := wp - global_position
		if absf(lp.x) < 200.0 and absf(lp.y + 6.0) < 55.0:
			Sound.pop()
			Fx.sparkles(get_parent(), wp, 4, Color("a9d7e8"))
			return true
		return false

	func _draw() -> void:
		DrawKit.ellipse(self, Vector2(0, -4), 205.0, 52.0, Color("8ac0d6"))
		DrawKit.ellipse(self, Vector2(0, -6), 190.0, 44.0, Color("a9d7e8"))
		# reeds
		for rx in [-195.0, -180.0, 188.0, 200.0]:
			draw_line(Vector2(rx, 0), Vector2(rx + 4.0, -46.0), Color("7fb87a"), 3.5)
			DrawKit.ellipse(self, Vector2(rx + 5.0, -50.0), 5.0, 10.0, Color("a9825c"))
		# lily pads
		DrawKit.ellipse(self, Vector2(-60, -14), 24.0, 10.0, Color("7fbf83"))
		DrawKit.ellipse(self, Vector2(90, -2), 20.0, 8.0, Color("8cc188"))
		# tadpoles
		for td in tads:
			var p := Vector2(cos(td["a"]) * td["r"], -8.0 + sin(td["a"]) * td["r"] * 0.18)
			var tail := p + Vector2(-cos(td["a"] + PI / 2) * 10.0, sin(td["ph"]) * 3.0)
			draw_line(p, tail, Color("4a5a44"), 2.5)
			draw_circle(p, 4.5, Color("4a5a44"))


## Tree with the bird's nest from the "Tadpoles, Bird Nest and a Secret
## Location" day. Tap the nest and the birds sing.
class BirdTree extends Node2D:
	func nest_pos() -> Vector2:
		return global_position + Vector2(52, -158)

	func try_tap(wp: Vector2) -> bool:
		if (wp - nest_pos()).length() < 75.0:
			Sound.chirp()
			Fx.hearts(get_parent(), nest_pos() + Vector2(0, -20))
			return true
		return false

	func _draw() -> void:
		draw_polygon(PackedVector2Array([
			Vector2(-13, 0), Vector2(13, 0), Vector2(7, -140), Vector2(-7, -140),
		]), PackedColorArray([Color("8a6a52")]))
		draw_line(Vector2(4, -120), Vector2(56, -152), Color("8a6a52"), 8.0)
		var leaf := Color("9ccf8f")
		draw_circle(Vector2(-6, -180), 55.0, leaf)
		draw_circle(Vector2(-50, -150), 40.0, leaf.darkened(0.05))
		draw_circle(Vector2(30, -196), 38.0, leaf.lightened(0.05))
		# nest
		var nest := Vector2(52, -158)
		draw_circle(nest + Vector2(0, 2), 17.0, Color("a9825c"))
		draw_arc(nest + Vector2(0, 0), 15.0, 0, PI, 12, Color("8a6a44"), 6.0, true)
		DrawKit.ellipse(self, nest + Vector2(-5, -4), 5.0, 6.5, Color("cfe4ea"))
		DrawKit.ellipse(self, nest + Vector2(5, -4), 5.0, 6.5, Color("d8ecdf"))
		# parent bird on the branch
		var bp := Vector2(24, -142)
		DrawKit.ellipse(self, bp, 9.0, 7.0, Color("8fb7d9"))
		draw_circle(bp + Vector2(7, -6), 5.0, Color("8fb7d9"))
		draw_polygon(PackedVector2Array([
			bp + Vector2(11, -7), bp + Vector2(16, -5), bp + Vector2(11, -3),
		]), PackedColorArray([Color("ffc46b")]))
		draw_circle(bp + Vector2(8, -7), 1.2, Color("3a3a44"))


## Summer's bike, leaning near the treehouse — tap for a bell ding.
class Bike extends Node2D:
	func try_tap(wp: Vector2) -> bool:
		if (wp - global_position - Vector2(0, -26)).length() < 62.0:
			Sound.bell()
			Fx.sparkles(get_parent(), global_position + Vector2(18, -52), 4, Color("ffe6b3"))
			return true
		return false

	func _draw() -> void:
		var frame := Color("d97f7a")
		var wheel := Color("5c5a66")
		draw_arc(Vector2(-26, -14), 14.0, 0, TAU, 20, wheel, 4.0, true)
		draw_arc(Vector2(26, -14), 14.0, 0, TAU, 20, wheel, 4.0, true)
		draw_line(Vector2(-26, -14), Vector2(-6, -38), frame, 4.0)
		draw_line(Vector2(-6, -38), Vector2(20, -38), frame, 4.0)
		draw_line(Vector2(20, -38), Vector2(26, -14), frame, 4.0)
		draw_line(Vector2(-6, -38), Vector2(0, -14), frame, 4.0)
		draw_line(Vector2(0, -14), Vector2(-26, -14), frame, 4.0)
		draw_line(Vector2(22, -38), Vector2(18, -50), frame, 3.5)
		draw_line(Vector2(12, -50), Vector2(24, -50), frame, 3.5)   # handlebars
		draw_line(Vector2(-8, -38), Vector2(-12, -46), frame, 3.5)
		draw_line(Vector2(-16, -46), Vector2(-8, -46), Color("8a6a44"), 4.0)  # saddle
		draw_circle(Vector2(24, -48), 3.0, Color("ffd98a"))  # the bell
		# stabilisers — she's nearly six!
		draw_arc(Vector2(32, -10), 7.0, 0, TAU, 14, wheel, 3.0, true)


## Picnic blanket — so many picnic Adventure Days.
class PicnicBlanket extends Node2D:
	func try_tap(wp: Vector2) -> bool:
		if (wp - global_position - Vector2(0, -14)).length() < 80.0:
			Sound.card_sound()
			Fx.hearts(get_parent(), global_position + Vector2(0, -34), 2)
			return true
		return false

	func _draw() -> void:
		# blanket in soft perspective
		draw_polygon(PackedVector2Array([
			Vector2(-70, 0), Vector2(70, 0), Vector2(52, -30), Vector2(-52, -30),
		]), PackedColorArray([Color("f2c9c9")]))
		for i in 3:
			var yy := -7.0 - i * 8.0
			var inset := 4.0 + i * 4.0
			draw_line(Vector2(-70 + inset * 4.5, yy), Vector2(70 - inset * 4.5, yy), Color("e8b8b8"), 3.0)
		for i in 4:
			var xx := -42.0 + i * 28.0
			draw_line(Vector2(xx, 0), Vector2(xx * 0.75, -30), Color("e8b8b8"), 3.0)
		# basket
		DrawKit.rounded_rect(self, Rect2(-16, -44, 32, 22), 6.0, Color("c9915c"))
		draw_arc(Vector2(0, -44), 11.0, PI, TAU, 10, Color("8a6a44"), 3.5, true)
		# apple and cup
		draw_circle(Vector2(30, -8), 6.0, Color("e07a70"))
		draw_line(Vector2(30, -14), Vector2(32, -18), Color("7fb87a"), 2.0)
		DrawKit.rounded_rect(self, Rect2(-40, -16, 12, 12), 3.0, Color("a9c9e8"))


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
		queue_redraw()

	func _draw() -> void:
		var fx := float(facing)
		var body := Color("f3f0e8") if kind == "indy" else Color("43404a")
		var patch := Color("a5764f")
		var bob := -absf(sin(t * 10.0)) * 2.5 if moving else sin(t * 2.2) * 1.0
		var swing := sin(t * 10.0) * 8.0 if moving else 0.0

		# long thin legs with little paws
		for leg in [[-22.0, swing], [-16.0, -swing], [16.0, -swing], [22.0, swing]]:
			var lx: float = leg[0] * fx
			var ls: float = leg[1] * fx * 0.35
			draw_line(Vector2(lx, -30 + bob), Vector2(lx + ls, 0), body, 4.5)
			draw_circle(Vector2(lx + ls, -1), 2.8, body)
		# slender body: deep chest, tucked waist, arched back
		DrawKit.ellipse(self, Vector2(14 * fx, -36 + bob), 16.0, 14.0, body)
		DrawKit.ellipse(self, Vector2(-16 * fx, -35 + bob), 13.0, 11.0, body)
		draw_polygon(PackedVector2Array([
			Vector2(-16 * fx, -46 + bob), Vector2(14 * fx, -50 + bob),
			Vector2(14 * fx, -26 + bob), Vector2(-16 * fx, -28 + bob),
		]), PackedColorArray([body]))
		# long neck and narrow head
		draw_line(Vector2(20 * fx, -44 + bob), Vector2(30 * fx, -62 + bob), body, 8.0)
		DrawKit.ellipse(self, Vector2(32 * fx, -64 + bob), 8.5, 6.5, body)
		draw_line(Vector2(37 * fx, -62 + bob), Vector2(47 * fx, -59 + bob), body, 5.0)
		draw_circle(Vector2(48 * fx, -59 + bob), 2.2, Color("2e2a28"))
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


## The hole left after a dig — fades away slowly on its own.
class Hole extends Node2D:
	func _draw() -> void:
		DrawKit.ellipse(self, Vector2.ZERO, 26.0, 10.0, Color("6e5138"))
		DrawKit.ellipse(self, Vector2(0, -1.5), 20.0, 7.0, Color("543d2a"))
		draw_circle(Vector2(-30, -4), 6.0, Color("a67c58"))
		draw_circle(Vector2(32, -3), 7.0, Color("a67c58"))
		draw_circle(Vector2(38, -8), 4.0, Color("b98d68"))


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
