class_name Grove
## The home grove: the first stretch of the world, almost entirely about the
## treehouse. Bridges between the three trees, the signposts that lead away to
## the market and the adventure lands, and the fruit trees she shakes.
##
## Nothing in here can hurt or block her — bridges are one-way floors and
## signposts only ever point.


## A rope bridge between two trees. Sways as she crosses, which is the best
## feeling in the game. Acts as a one-way platform, like the lookout perches.
class RopeBridge extends Node2D:
	var from_x := 0.0
	var to_x := 300.0
	var deck_y := 0.0        ## world y of the walking surface
	var walker: Node2D = null  ## the player, so the deck dips under her feet

	var _t := 0.0
	var _dip := 0.0

	func _ready() -> void:
		z_index = 3

	## The stand-on surface, in global space.
	func rect() -> Rect2:
		return Rect2(Vector2(minf(from_x, to_x), deck_y), Vector2(absf(to_x - from_x), 10))

	func _process(delta: float) -> void:
		_t += delta
		var want := 0.0
		if walker != null and is_instance_valid(walker):
			var wx: float = walker.position.x
			if wx > minf(from_x, to_x) and wx < maxf(from_x, to_x) \
					and absf(walker.position.y - deck_y) < 40.0:
				want = 1.0
		_dip = lerpf(_dip, want, delta * 5.0)
		if _dip > 0.01 or want > 0.0:
			queue_redraw()

	## How far the deck hangs below the straight line at u (0..1).
	func _sag(u: float) -> float:
		var base := sin(u * PI) * 16.0
		var under := 0.0
		if walker != null and is_instance_valid(walker) and _dip > 0.01:
			var span := absf(to_x - from_x)
			var wu: float = clampf((walker.position.x - minf(from_x, to_x)) / maxf(span, 1.0), 0.0, 1.0)
			under = exp(-pow((u - wu) * 4.0, 2.0)) * 16.0 * _dip
		return base + under + sin(_t * 1.3 + u * 5.0) * 1.6

	func _draw() -> void:
		var span := to_x - from_x
		var rope := Color("9a8055")
		var plank := Color("c9a06c")
		var steps := maxi(8, int(absf(span) / 26.0))
		# the two handrails and the deck
		var deck := PackedVector2Array()
		var rail_a := PackedVector2Array()
		for i in steps + 1:
			var u := i / float(steps)
			var x := lerpf(0.0, span, u)
			var y := _sag(u)
			deck.append(Vector2(x, y))
			rail_a.append(Vector2(x, y - 54.0 + sin(u * PI) * 5.0))
		draw_polyline(rail_a, rope, 3.0)
		for i in steps + 1:
			if i % 2 == 0:
				draw_line(deck[i], rail_a[i], rope, 2.0)
		for i in steps:
			var a: Vector2 = deck[i]
			var b: Vector2 = deck[i + 1]
			var mid := (a + b) * 0.5
			var ang := (b - a).angle()
			draw_set_transform(mid, ang, Vector2.ONE)
			draw_rect(Rect2(-13, -5, 26, 9), plank.darkened(0.14))
			draw_rect(Rect2(-13, -5, 26, 3), plank.lightened(0.06))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_polyline(deck, rope.darkened(0.2), 2.0)


## A signpost pointing off to somewhere else. Tapping it wobbles and points,
## then travels — no reading needed, the picture on the board says where.
class Signpost extends Node2D:
	var dir := 1.0            ## -1 points left, +1 points right
	var destination := "market"   ## market | dino
	var _t := 0.0

	func _ready() -> void:
		_t = randf() * 6.0

	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position - Vector2(0, -74.0)).length() / 84.0, 0.0, 1.0)

	func try_tap(wp: Vector2) -> bool:
		return (wp - global_position - Vector2(0, -74.0)).length() < 84.0

	func _process(delta: float) -> void:
		_t += delta

	## A friendly wobble and a nudge in the direction it points.
	func point() -> void:
		var tw := create_tween()
		tw.tween_property(self, "rotation", 0.10 * dir, 0.10)
		tw.tween_property(self, "rotation", -0.06 * dir, 0.10)
		tw.tween_property(self, "rotation", 0.0, 0.12)

	func _draw() -> void:
		var wood := Color("a97e54")
		DrawKit.soft_shadow(self, Vector2(0, 2), 26.0, 0.14)
		draw_line(Vector2(0, 0), Vector2(0, -104), wood.darkened(0.2), 9.0)
		draw_line(Vector2(-3, 0), Vector2(-3, -104), wood.darkened(0.34), 3.0)
		# the arm, pointing the way
		var x0 := 0.0 if dir > 0.0 else -72.0
		var board := Rect2(x0, -96, 72, 34)
		DrawKit.rounded_rect(self, board, 4.0, wood)
		draw_rect(Rect2(board.position.x, board.position.y, board.size.x, 5), wood.lightened(0.12))
		# a pointed end
		var tipx := board.end.x + 16.0 if dir > 0.0 else board.position.x - 16.0
		draw_polygon(PackedVector2Array([
			Vector2(board.end.x if dir > 0.0 else board.position.x, board.position.y),
			Vector2(tipx, board.position.y + 17),
			Vector2(board.end.x if dir > 0.0 else board.position.x, board.end.y),
		]), PackedColorArray([wood]))
		_draw_symbol(board.get_center())
		# a tuft at the foot
		DrawKit.tuft(self, Vector2(10, 2), 11.0, Color("7fb87a"), 63)

	## The picture that says where this goes.
	func _draw_symbol(c: Vector2) -> void:
		match destination:
			"home":
				# her own treehouse, so the way back is never in doubt
				draw_rect(Rect2(c.x - 3, c.y + 2, 6, 12), Color("8a6a52"))
				DrawKit.rounded_rect(self, Rect2(c.x - 13, c.y - 8, 26, 12), 2.0, Color("c9a06c"))
				draw_polygon(PackedVector2Array([
					Vector2(c.x - 17, c.y - 8), Vector2(c.x + 17, c.y - 8), Vector2(c.x, c.y - 19),
				]), PackedColorArray([Color("a9743f")]))
				draw_circle(Vector2(c.x, c.y - 2), 3.0, Color("ffe9b8"))
			"cove":
				# a little sail against the water
				draw_rect(Rect2(c.x - 20, c.y + 6, 40, 5), Color("6fb3d2"))
				draw_polygon(PackedVector2Array([
					Vector2(c.x - 14, c.y + 6), Vector2(c.x + 16, c.y + 6), Vector2(c.x + 8, c.y + 12),
					Vector2(c.x - 8, c.y + 12),
				]), PackedColorArray([Color("a97e54")]))
				draw_line(Vector2(c.x, c.y + 6), Vector2(c.x, c.y - 14), Color("8a6a52"), 2.5)
				draw_polygon(PackedVector2Array([
					Vector2(c.x + 1, c.y - 14), Vector2(c.x + 15, c.y + 2), Vector2(c.x + 1, c.y + 2),
				]), PackedColorArray([Color("f2e6c8")]))
			"market":
				# a striped awning
				draw_rect(Rect2(c.x - 18, c.y - 2, 36, 10), Color("f4ead6"))
				for i in 4:
					draw_rect(Rect2(c.x - 18 + i * 9, c.y - 2, 4.5, 10), Color("e8918c"))
				draw_line(Vector2(c.x - 16, c.y + 8), Vector2(c.x - 16, c.y + 13), Color("8a6a52"), 2.0)
				draw_line(Vector2(c.x + 16, c.y + 8), Vector2(c.x + 16, c.y + 13), Color("8a6a52"), 2.0)
			_:
				# a little long-neck against the sky
				draw_circle(Vector2(c.x + 8, c.y - 6), 4.0, Color("6f9a5d"))
				draw_line(Vector2(c.x + 8, c.y - 5), Vector2(c.x + 2, c.y + 3), Color("6f9a5d"), 4.0)
				DrawKit.ellipse(self, Vector2(c.x - 6, c.y + 5), 12.0, 6.0, Color("6f9a5d"))
				draw_line(Vector2(c.x - 15, c.y + 4), Vector2(c.x - 21, c.y - 1), Color("6f9a5d"), 3.5)
				for lx in [-10.0, -2.0]:
					draw_line(Vector2(c.x + lx, c.y + 9), Vector2(c.x + lx, c.y + 14), Color("6f9a5d"), 3.0)


## A fruit tree she can shake. Fruit drops, bounces and can be picked up —
## which turns fruit from a pickup into an action.
class FruitTree extends Node2D:
	const MAX_FRUIT := 6

	var fruit_left := MAX_FRUIT
	var seed_v := 7
	var _shake := 0.0
	var _regrow := 0.0
	var _positions: Array = []

	func _ready() -> void:
		_seed_positions()

	func _seed_positions() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_v
		_positions.clear()
		for i in MAX_FRUIT:
			_positions.append(Vector2(rng.randf_range(-58.0, 58.0), rng.randf_range(-232.0, -168.0)))

	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position - Vector2(0, -150.0)).length() / 96.0, 0.0, 1.0)

	func try_tap(wp: Vector2) -> bool:
		return (wp - global_position - Vector2(0, -150.0)).length() < 96.0

	func _process(delta: float) -> void:
		if _shake > 0.0:
			_shake = maxf(0.0, _shake - delta * 2.2)
			queue_redraw()
		if fruit_left < MAX_FRUIT:
			_regrow += delta
			if _regrow > 26.0:
				_regrow = 0.0
				fruit_left += 1
				queue_redraw()

	## Shake the tree. Returns how many fruit fell — never zero for long, since
	## the tree always grows more.
	func shake() -> int:
		_shake = 1.0
		var n := mini(fruit_left, 2)
		fruit_left -= n
		queue_redraw()
		return n

	func _draw() -> void:
		var sway := sin(_shake * PI * 5.0) * _shake * 0.05
		draw_set_transform(Vector2.ZERO, sway, Vector2.ONE)
		DrawKit.soft_shadow(self, Vector2(0, 2), 62.0, 0.14)
		DrawKit.trunk(self, Vector2(0, 2), 172.0, 15.0, 9.0, Color("806048"), seed_v)
		DrawKit.canopy(self, Vector2(0, -212), 86.0, 72.0, Color("8fc48a"), seed_v)
		DrawKit.blob(self, Vector2(-56, -186), 34.0, 28.0, Color("7fb87a"), seed_v + 3)
		DrawKit.blob(self, Vector2(58, -196), 32.0, 26.0, Color("9ccf8f"), seed_v + 5)
		for i in fruit_left:
			var p: Vector2 = _positions[i]
			draw_circle(p + Vector2(0, 1.5), 8.0, Color("b8483f"))
			draw_circle(p, 7.5, Color("e05c50"))
			draw_circle(p + Vector2(-2.5, -2.5), 2.6, Color("f2a09a"))
			draw_line(p + Vector2(0, -7), p + Vector2(1, -12), Color("6f5a3f"), 1.6)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A fruit that has just fallen, waiting to be picked up.
class FallenFruit extends Node2D:
	var _t := 0.0

	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position - Vector2(0, -8.0)).length() / 54.0, 0.0, 1.0)

	func try_tap(wp: Vector2) -> bool:
		return (wp - global_position - Vector2(0, -8.0)).length() < 54.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var bob := sin(_t * 2.4) * 1.2
		DrawKit.soft_shadow(self, Vector2(0, 1), 11.0, 0.14)
		draw_circle(Vector2(0, -8 + bob), 9.0, Color("b8483f"))
		draw_circle(Vector2(0, -9 + bob), 8.0, Color("e05c50"))
		draw_circle(Vector2(-3, -12 + bob), 3.0, Color("f2a09a"))
		draw_line(Vector2(0, -17 + bob), Vector2(1.5, -23 + bob), Color("6f5a3f"), 1.8)
		DrawKit.ellipse(self, Vector2(5, -22 + bob), 4.0, 2.0, Color("8cc188"))


## The garden patch below the trees. Seeds bought at the market go in here and
## grow while she plays; once grown it can be picked for fruit. Nothing ever
## dies, wilts or needs watering on a schedule — it only ever moves forwards,
## so coming back after a week is only ever good news.
class GardenPatch extends Node2D:
	const ROWS := 5
	## Seconds of play for a patch to grow from freshly sown to ready.
	const GROW_SECONDS := 240.0

	var _t := 0.0

	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position - Vector2(0, -30.0)).length() / 96.0, 0.0, 1.0)

	func try_tap(_wp: Vector2) -> bool:
		return true

	func _process(delta: float) -> void:
		_t += delta
		if GameState.garden_seeds > 0 and GameState.garden_growth < 1.0:
			GameState.garden_growth = minf(1.0, GameState.garden_growth + delta / GROW_SECONDS)
			queue_redraw()

	func ready_to_pick() -> bool:
		return GameState.garden_seeds > 0 and GameState.garden_growth >= 1.0

	## Sow one seed. More seeds mean a fuller patch, never a faster one.
	func sow() -> bool:
		if int(GameState.materials.get("seed", 0)) <= 0 or GameState.garden_seeds >= ROWS:
			return false
		GameState.materials["seed"] = int(GameState.materials["seed"]) - 1
		GameState.garden_seeds += 1
		if GameState.garden_seeds == 1:
			GameState.garden_growth = 0.0
		GameState.save_game()
		queue_redraw()
		return true

	## Pick the patch: three fruit per row that grew. The soil is left ready to
	## sow again.
	func pick() -> int:
		if not ready_to_pick():
			return 0
		var n: int = GameState.garden_seeds * 3
		GameState.garden_seeds = 0
		GameState.garden_growth = 0.0
		GameState.add_fruit(n)
		queue_redraw()
		return n

	func _draw() -> void:
		var soil := Color("8a6a4c")
		var grown: int = GameState.garden_seeds
		var g: float = GameState.garden_growth
		DrawKit.rounded_rect(self, Rect2(-72, -14, 144, 20), 5.0, soil)
		DrawKit.rounded_rect(self, Rect2(-72, -16, 144, 8), 4.0, soil.lightened(0.1))
		for i in ROWS:
			var px := -56.0 + i * 28.0
			if i >= grown:
				# an empty drill, waiting for a seed
				DrawKit.ellipse(self, Vector2(px, -12), 7.0, 3.0, soil.darkened(0.2))
				continue
			var h := 6.0 + g * 30.0
			draw_line(Vector2(px, -12), Vector2(px, -12 - h), Color("6f9a5d"), 3.0)
			if g > 0.35:
				DrawKit.ellipse(self, Vector2(px - 5, -12 - h * 0.7), 6.0, 3.5, Color("83b86f"))
				DrawKit.ellipse(self, Vector2(px + 5, -12 - h * 0.5), 6.0, 3.5, Color("8fc48a"))
			if g >= 1.0:
				# ripe, and gently bobbing to say so
				var bob := sin(_t * 2.0 + i) * 1.5
				draw_circle(Vector2(px, -16 - h + bob), 7.0, Color("b8483f"))
				draw_circle(Vector2(px, -17 - h + bob), 6.0, Color("e05c50"))
				draw_circle(Vector2(px - 2, -19 - h + bob), 2.2, Color("f2a09a"))
		if ready_to_pick():
			DrawKit.star(self, Vector2(0, -62 + sin(_t * 2.4) * 3.0), 8.0, Color("ffd98a"))


## A footprint pressed into the grass behind her, fading away. Tiny, but it
## makes the world feel touched rather than walked past.
class Footstep extends Node2D:
	var life := 2.6
	var _age := 0.0
	var fx := 1.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_age += delta
		if _age >= life:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := clampf(1.0 - _age / life, 0.0, 1.0) * 0.22
		DrawKit.ellipse(self, Vector2.ZERO, 5.0, 2.6, Color(0.36, 0.3, 0.22, a))
		DrawKit.ellipse(self, Vector2(2.5 * fx, -2.0), 3.0, 1.8, Color(0.36, 0.3, 0.22, a))


## A firefly, drifting. They only come out once she has been playing a while —
## a quiet reward for a long session, never anything she has to catch.
class Firefly extends Node2D:
	var _t := 0.0
	var _home := Vector2.ZERO
	var _drift := Vector2.ZERO

	func _ready() -> void:
		_t = randf() * 10.0
		_home = position
		z_index = 6

	func _process(delta: float) -> void:
		_t += delta
		_drift = Vector2(sin(_t * 0.6) * 40.0, sin(_t * 0.43 + 1.3) * 26.0)
		position = _home + _drift
		queue_redraw()

	func _draw() -> void:
		var glow := 0.35 + 0.4 * (0.5 + 0.5 * sin(_t * 2.4))
		draw_circle(Vector2.ZERO, 9.0, Color(1.0, 0.93, 0.6, glow * 0.22))
		draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.95, 0.68, glow * 0.5))
		draw_circle(Vector2.ZERO, 2.0, Color(1.0, 1.0, 0.86, glow))


## A cat that turns up on the treehouse roof now and then and washes itself.
## No stakes, no interaction needed — just a nice surprise.
class RoofCat extends Node2D:
	var _t := 0.0

	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position).length() / 60.0, 0.0, 1.0)

	func try_tap(_wp: Vector2) -> bool:
		return true

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var fur := Color("6f6259")
		var breathe := sin(_t * 1.4) * 1.2
		DrawKit.ellipse(self, Vector2(0, 2 + breathe), 22.0, 11.0, fur)
		draw_circle(Vector2(-17, -6 + breathe), 10.0, fur)
		for sx in [-23.0, -11.0]:
			draw_polygon(PackedVector2Array([
				Vector2(sx, -12 + breathe), Vector2(sx + 6, -22 + breathe),
				Vector2(sx + 9, -11 + breathe),
			]), PackedColorArray([fur]))
		draw_circle(Vector2(-21, -7 + breathe), 1.8, Color("d8e08a"))
		draw_circle(Vector2(-13, -7 + breathe), 1.8, Color("d8e08a"))
		# a tail curled round, flicking slowly
		var tail := PackedVector2Array()
		for i in 8:
			var u := i / 7.0
			tail.append(Vector2(16.0 + u * 18.0, 2.0 + breathe - sin(u * PI * 0.9 + _t * 0.8) * 14.0 * u))
		draw_polyline(tail, fur, 5.0)


## Flat stones across the pond, so she can hop instead of swim if she likes.
class SteppingStones extends Node2D:
	var count := 5
	var span := 300.0

	func _ready() -> void:
		z_index = 1

	## One continuous walking surface across the whole line of stones — she
	## steps from stone to stone without ever falling down a gap.
	func walk_rect() -> Rect2:
		return Rect2(Vector2(global_position.x - span * 0.5 - 20.0, global_position.y - 6.0),
			Vector2(span + 40.0, 10.0))

	## Is this x over the stones?
	func covers(x: float) -> bool:
		var r := walk_rect()
		return x >= r.position.x and x <= r.end.x

	func _draw() -> void:
		for i in count:
			var x := -span * 0.5 + span * (i / float(count - 1))
			var bob := sin(float(i) * 1.7) * 2.0
			DrawKit.ellipse(self, Vector2(x, 4 + bob), 30.0, 11.0, Color(0.35, 0.4, 0.42, 0.28))
			DrawKit.ellipse(self, Vector2(x, bob), 27.0, 10.0, Color("9aa1a0"))
			DrawKit.ellipse(self, Vector2(x - 3, -2 + bob), 19.0, 6.0, Color("b3b8b4"))


## The telescope on the tower. Tapping it shows her what is out there — the
## adventure lands, long before she has walked to them.
class Telescope extends Node2D:
	var _t := 0.0

	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position).length() / 80.0, 0.0, 1.0)

	func try_tap(_wp: Vector2) -> bool:
		return true

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var glint := 0.4 + 0.3 * sin(_t * 1.6)
		draw_set_transform(Vector2.ZERO, -0.42, Vector2.ONE)
		DrawKit.rounded_rect(self, Rect2(-4, -6, 30, 12), 4.0, Color("55636f"))
		DrawKit.rounded_rect(self, Rect2(20, -8, 11, 16), 4.0, Color("7a8b9c"))
		draw_circle(Vector2(31, 0), 4.5, Color("aed9ef"))
		draw_circle(Vector2(31, 0), 2.2, Color(1, 1, 1, glint))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_line(Vector2(-2, 4), Vector2(-6, 22), Color("55636f"), 3.0)
		draw_line(Vector2(2, 4), Vector2(6, 22), Color("55636f"), 3.0)


## What she sees down the telescope: a soft, distant view of somewhere she has
## not been yet. Tap to put it away.
class FarView extends CanvasLayer:
	signal closed

	var place := "dino"

	func _ready() -> void:
		layer = 44
		var body := Body.new()
		body.place = place
		body.dismissed.connect(func() -> void:
			closed.emit()
			queue_free())
		add_child(body)

	class Body extends Control:
		signal dismissed
		var place := "dino"
		var _t := 0.0
		var _shown := 0.0

		func _ready() -> void:
			set_anchors_preset(Control.PRESET_FULL_RECT)
			mouse_filter = Control.MOUSE_FILTER_STOP
			size = get_viewport().get_visible_rect().size
			_shown = Time.get_ticks_msec() / 1000.0
			modulate.a = 0.0
			var tw := create_tween()
			tw.tween_property(self, "modulate:a", 1.0, 0.3)
			get_tree().create_timer(7.0).timeout.connect(_dismiss)

		func _process(delta: float) -> void:
			_t += delta
			queue_redraw()

		func _gui_input(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed:
				accept_event()
				if Time.get_ticks_msec() / 1000.0 - _shown > 0.4:
					_dismiss()

		func _dismiss() -> void:
			if not is_inside_tree():
				return
			var tw := create_tween()
			tw.tween_property(self, "modulate:a", 0.0, 0.25)
			tw.tween_callback(func() -> void: dismissed.emit())

		func _draw() -> void:
			var vs := size
			draw_rect(Rect2(Vector2.ZERO, vs), Color(0.06, 0.05, 0.04, 0.9))
			var c := vs * 0.5
			var r := minf(vs.x, vs.y) * 0.38
			# the round view through the eyepiece
			var view := PackedVector2Array()
			for i in 48:
				var a := i / 48.0 * TAU
				view.append(c + Vector2(cos(a), sin(a)) * r)
			draw_polygon(view, PackedColorArray([Color("cfe6f2")]))
			# far hills, drifting slowly
			var drift := sin(_t * 0.2) * 12.0
			_hills(c, r, drift)
			# and the thing worth walking to
			var s := r / 760.0
			if place == "dino":
				_longneck(c + Vector2(drift * 0.6 + r * 0.2, r * 0.16), s)
			else:
				_stalls(c + Vector2(drift * 0.6, r * 0.2), s)
			# the eyepiece ring and a soft vignette
			draw_arc(c, r, 0, TAU, 60, Color("2a2520"), 18.0, true)
			draw_arc(c, r + 12.0, 0, TAU, 60, Color("55636f"), 8.0, true)
			for i in 3:
				draw_arc(c, r - 8.0 - i * 5.0, 0, TAU, 48,
					Color(0.1, 0.09, 0.07, 0.10 - i * 0.03), 10.0, true)

		## Hills, clipped to the round eyepiece: the top of each band is the
		## skyline, the bottom follows the circle itself so nothing spills out.
		func _hills(c: Vector2, r: float, drift: float) -> void:
			var steps := 40
			for k in 2:
				var base := c.y + r * (0.1 + k * 0.16)
				var top: Array = []
				var bottom: Array = []
				for i in steps + 1:
					var u := i / float(steps)
					var x := c.x - r + u * r * 2.0
					var dx := clampf(x - c.x, -r, r)
					var half := sqrt(maxf(0.0, r * r - dx * dx))
					var lo := c.y + half            # the circle's lower edge here
					var hi := c.y - half
					var y := base - sin(u * PI * (1.6 + k)) * r * (0.16 - k * 0.05) \
						+ drift * (0.4 - k * 0.2)
					top.append(Vector2(x, clampf(y, hi, lo)))
					bottom.append(Vector2(x, lo))
				var band := PackedVector2Array()
				for p in top:
					band.append(p)
				for i in range(bottom.size() - 1, -1, -1):
					band.append(bottom[i])
				draw_polygon(band, PackedColorArray([
					Color("a8c9a2") if k == 0 else Color("8fb98a")]))

		## A long-neck grazing on the far horizon, drawn small. `s` scales the
		## whole thing to the size of the eyepiece.
		func _longneck(p: Vector2, s: float) -> void:
			var body := Color("7fa86a")
			for i in 4:
				draw_line(p + Vector2((-46.0 + i * 30.0) * s, 24.0 * s),
					p + Vector2((-46.0 + i * 30.0) * s, 86.0 * s),
					body.darkened(0.14), 14.0 * s)
			DrawKit.ellipse(self, p, 90.0 * s, 44.0 * s, body)
			var neck := PackedVector2Array()
			for i in 9:
				var u := i / 8.0
				neck.append(p + Vector2(lerpf(-50.0, -128.0, u) * s,
					lerpf(-24.0, -152.0, u) * s))
			draw_polyline(neck, body, 17.0 * s)
			DrawKit.ellipse(self, p + Vector2(-132.0 * s, -156.0 * s), 23.0 * s, 14.0 * s, body)
			draw_circle(p + Vector2(-138.0 * s, -160.0 * s), 3.0 * s, Color("3a3a44"))
			# a swishing tail
			var tail := PackedVector2Array()
			for i in 7:
				var u := i / 6.0
				tail.append(p + Vector2((80.0 + u * 110.0) * s, (-6.0 + u * 34.0) * s))
			draw_polyline(tail, body.darkened(0.06), 13.0 * s)

		func _stalls(p: Vector2, s: float) -> void:
			for i in 3:
				var sx := p.x + (i - 1) * 120.0 * s
				draw_rect(Rect2(sx - 40.0 * s, p.y - 44.0 * s, 80.0 * s, 44.0 * s),
					Color("a97e54"))
				draw_rect(Rect2(sx - 46.0 * s, p.y - 60.0 * s, 92.0 * s, 16.0 * s),
					Color("f4ead6"))
				for k in 4:
					draw_rect(Rect2(sx - 46.0 * s + k * 24.0 * s, p.y - 60.0 * s,
						11.0 * s, 16.0 * s),
						[Color("c96b64"), Color("6fb3d2"), Color("8fc48a")][i])


## A place she can get on or off something: the rope ladder, the bucket lift,
## the slide, the zip line. Drawn as a soft ring so it reads as "you can use
## this" without cluttering the tree.
class RideSpot extends Node2D:
	var kind := "ladder"      ## ladder | lift | slide | zip
	var _t := 0.0

	func _ready() -> void:
		_t = randf() * 5.0
		z_index = 4

	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position).length() / 72.0, 0.0, 1.0)

	func try_tap(_wp: Vector2) -> bool:
		return true

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var pulse := 0.5 + 0.5 * sin(_t * 2.0)
		var col := Color("ffd98a")
		match kind:
			"lift": col = Color("a9c9e8")
			"slide": col = Color("6fb3d2")
			"zip": col = Color("c4b8e8")
		draw_circle(Vector2.ZERO, 24.0, Color(1, 1, 1, 0.14 + 0.08 * pulse))
		draw_arc(Vector2.ZERO, 20.0, 0, TAU, 26, Color(col, 0.5 + 0.3 * pulse), 3.5, true)
		# Chevrons pointing the way she will travel. UP means the point of the
		# arrow is ABOVE its two ends; down is the mirror of that.
		var up := kind == "ladder" or kind == "lift"
		var drift := sin(_t * 2.4) * 2.0 * (-1.0 if up else 1.0)
		for i in 2:
			var y := -5.0 + i * 10.0 + drift
			var tip := -5.0 if up else 5.0
			draw_polyline(PackedVector2Array([
				Vector2(-9, y - tip), Vector2(0, y + tip), Vector2(9, y - tip),
			]), Color(col, 0.9), 3.5)


## A shallow puddle. She splashes through it — the single best reason to walk
## somewhere twice. Nothing about it can go wrong; it is only ever a splash.
class Puddle extends Node2D:
	var w := 70.0
	var _t := 0.0
	var _ripple := 0.0
	var _inside := false

	func _ready() -> void:
		_t = randf() * 4.0
		z_index = -1

	## True the first frame she steps in — the world uses that to splash.
	func stepped_in(x: float, feet_y: float, ground_y: float) -> bool:
		var over := absf(x - global_position.x) < w * 0.5 and absf(feet_y - ground_y) < 12.0
		var entered := over and not _inside
		_inside = over
		if entered:
			_ripple = 1.0
		return entered

	func _process(delta: float) -> void:
		_t += delta
		if _ripple > 0.0:
			_ripple = maxf(0.0, _ripple - delta * 1.6)
		queue_redraw()

	func _draw() -> void:
		var shimmer := 0.5 + 0.5 * sin(_t * 1.1)
		DrawKit.ellipse(self, Vector2(0, 0), w * 0.5, w * 0.17, Color(0.55, 0.7, 0.76, 0.5))
		DrawKit.ellipse(self, Vector2(-2, -1.5), w * 0.4, w * 0.11,
			Color(0.78, 0.89, 0.93, 0.35 + shimmer * 0.12))
		if _ripple > 0.0:
			for i in 2:
				var r := (1.0 - _ripple) * w * (0.45 + i * 0.25)
				DrawKit.ellipse(self, Vector2.ZERO, r, r * 0.34,
					Color(1, 1, 1, _ripple * (0.3 - i * 0.12)))


## "There is a game here." One marker, one meaning, used at every game in
## every world — the plank bridge at the cove, the bone table in Dino Land, a
## stall counter at the market, the garden row, a spare museum shelf. If she
## learns it once she can find them all.
class GameSpot extends Node2D:
	var game := "pattern"     ## plank | bones | stall | pattern | memory
	var label := ""
	var _t := 0.0

	func _ready() -> void:
		_t = randf() * 5.0
		z_index = 5

	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position).length() / 92.0, 0.0, 1.0)

	func try_tap(_wp: Vector2) -> bool:
		return true

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var pulse := 0.5 + 0.5 * sin(_t * 1.8)
		var bob := sin(_t * 1.4) * 4.0
		var c := Vector2(0, bob)
		# a soft halo and a ring of little stars — deliberately different from
		# the ride markers, which are chevrons
		draw_circle(c, 34.0, Color(1, 1, 1, 0.16 + 0.10 * pulse))
		draw_arc(c, 29.0, 0, TAU, 30, Color(1.0, 0.85, 0.54, 0.45 + 0.35 * pulse), 3.5, true)
		for i in 3:
			var a := _t * 0.7 + TAU * i / 3.0
			DrawKit.star(self, c + Vector2(cos(a), sin(a) * 0.5) * 29.0, 5.0,
				Color(1.0, 0.92, 0.7, 0.55 + 0.4 * pulse))
		DrawKit.star(self, c, 15.0, Color("ffd98a"))
		DrawKit.star(self, c, 8.0, Color("fff3d0"))
