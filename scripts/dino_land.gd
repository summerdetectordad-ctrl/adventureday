extends Zone
## Dino Land, east of the meadow. Summer is dinosaur-obsessed, so this is the
## payoff for the museum she has been filling with bones and eggs all along.
##
## Nothing here is frightening: four kinds of dinosaur amble about the valley,
## all of them gentle, and they lower their heads
## to be patted, the volcano only ever puffs, and the dig wall gives up a find
## every time — it just takes a few brushes. No fail state, as everywhere else.

const WORLD_W := 2900.0
const HOME_SIGN_X := 90.0


func _ready() -> void:
	zone_name = "dino"
	setup_ground(WORLD_W, "dino")

	var volcano := Volcano.new()
	volcano.position = Vector2(1060.0, GROUND_Y)
	add_child(volcano)

	for spec in [[520.0, 0], [980.0, 1], [1560.0, 2]]:
		var trail := Footprints.new()
		trail.position = Vector2(spec[0], GROUND_Y)
		trail.seed_v = int(spec[1])
		add_child(trail)

	# the cave in the valley wall, and whoever is grumbling inside it
	var cave := CaveMouth.new()
	cave.position = Vector2(2180.0, GROUND_Y)
	add_child(cave)
	interactables.append(cave)
	# nothing else claims a tap over the mouth — she needs to be able to get in
	people_keep_clear.append(Rect2(2180.0 - 120.0, GROUND_Y - 240.0, 240.0, 250.0))

	# a sign to the right of it, pointing back at the entrance
	var warn := CaveSign.new()
	warn.position = Vector2(2520.0, GROUND_Y)
	add_child(warn)
	interactables.append(warn)

	var home := Grove.Signpost.new()
	home.dir = -1.0
	home.destination = "home"
	home.position = Vector2(HOME_SIGN_X, GROUND_Y)
	add_child(home)
	interactables.append(home)

	# onward, to the cove at the far end of the valley
	var onward := Grove.Signpost.new()
	onward.dir = 1.0
	onward.destination = "cove"
	onward.position = Vector2(WORLD_W - 90.0, GROUND_Y)
	add_child(onward)
	interactables.append(onward)

	# the dig wall: brush the rock away layer by layer and a fossil appears
	for wx in [700.0, 1240.0, 1820.0]:
		var wall := DigWall.new()
		wall.position = Vector2(wx, GROUND_Y)
		add_child(wall)
		interactables.append(wall)

	var bone_game := Grove.GameSpot.new()
	bone_game.game = "bones"
	# above the middle dig wall, in the gap the roaming dinosaurs do not reach
	bone_game.position = Vector2(1262.0, GROUND_Y - 215.0)
	add_child(bone_game)
	interactables.append(bone_game)

	# Gentle grazers spread down the valley, and NOT across the cave mouth
	# (2040..2320) —
	# they wander 220 either way, and a longneck parked in the entrance meant
	# she could not get in at all.
	for spec in [[420.0, "compy"], [470.0, "compy"], [520.0, "compy"],
			[900.0, "longneck"], [1380.0, "trike"], [1660.0, "stego"],
			[2740.0, "longneck"]]:
		var dino := Dino.new()
		dino.species = spec[1]
		dino.position = Vector2(spec[0], GROUND_Y)
		add_child(dino)
		interactables.append(dino)

	# the fossil hunters, out on the dig with her
	spawn_folk("dino", [640.0, 1500.0])

	var bike := Nature.Bike.new()
	bike.position = Vector2(380.0, GROUND_Y)
	add_child(bike)
	interactables.append(bike)

	setup_player(arrival_x({"home": 200.0, "cove": WORLD_W - 220.0,
		"cave": 2180.0 - 210.0, "bike": 700.0}, 240.0))


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if ui_layer != null or busy:
		return
	var wp := get_global_mouse_position()
	# her backpack, the drink and snack bubbles, and tapping Summer herself
	if handle_tap(event.position, wp):
		return

	var best: Node2D = null
	var best_score := 0.05
	for n in interactables:
		if not is_instance_valid(n):
			continue
		var s: float = n.tap_score(wp)
		if s > best_score:
			best_score = s
			best = n
	if best != null:
		if absf(best.global_position.x - player.position.x) > 150.0:
			player.target_x = best.global_position.x - 70.0 * signf(
				best.global_position.x - player.position.x)
			await walk_until_near(best.global_position.x, 160.0)
		_interact(best, wp)
		return

	var now := Time.get_ticks_msec() / 1000.0
	if now - last_tap_t < 0.4 and wp.distance_to(last_tap_pos) < 170.0:
		player.try_jump(wp)
		last_tap_t = -10.0
		return
	last_tap_t = now
	last_tap_pos = wp
	player.target_x = wp.x



func _interact(node: Node2D, wp: Vector2) -> void:
	player.face_toward(node.global_position.x)
	if node is Grove.Signpost:
		node.point()
		_travel(str(node.destination))
	elif node is DigWall:
		_brush(node, wp)
	elif node is Grove.GameSpot:
		open_game(BoneGame.new())
	elif node is CaveMouth:
		travel_to("res://scenes/dino_cave.tscn", "dino")
	elif node is CaveSign:
		# the sign points at the cave; tapping it just reads it aloud, so to
		# speak — she still has to walk over and go in herself
		node.try_tap(Vector2.ZERO)
		DialogueCard.show_chat(hud, "what does that say?",
			"a t-rex lives in that cave!", "tell",
			"he is grumpy, but he is not dangerous. he just gets splinters.")
	elif node is Nature.Bike:
		open_bike_map(node)
	elif node is Folk.Person:
		talk_to(node)
	elif node is Dino:
		_pat(node)


## Brush the rock away. Every wall gives up its fossil — it just takes a few
## goes, and the shape appears a little more each time.
func _brush(wall: DigWall, wp: Vector2) -> void:
	if wall.revealed:
		# already found — a friendly pat and a look at what it was
		Fx.hearts(self, wall.position + Vector2(0, -120.0), 2)
		Sound.pop()
		return
	busy = true
	player.reach(wp)
	player.start_dig()
	Sound.dig_sound()
	await get_tree().create_timer(0.55).timeout
	if not is_inside_tree():
		busy = false
		return
	wall.brush()
	Fx.dirt(self, wall.position + Vector2(0, -100.0), 6)
	if wall.revealed:
		await get_tree().create_timer(0.4).timeout
		if not is_inside_tree():
			busy = false
			return
		GameState.add_to_satchel(wall.find_kind)
		hud.bounce_satchel()
		Fx.sparkles(self, wall.position + Vector2(0, -110.0), 12, Color("ffe6b3"))
		Sound.chime_find()
		AffirmationCard.show_card(hud, Affirm.next())
	busy = false


## Say hello to a dinosaur. It stops, turns to her and dips its head down to
## be patted, which is the whole point.
## Saying hello to a dinosaur. Each species speaks for itself, and each has
## its own photographs — a triceratops picture is really a triceratops.
func _pat(dino: Dino) -> void:
	dino.greet(player.position.x)
	meet_animal(dino.species, dino)
	Fx.hearts(self, dino.position + Vector2(-40.0, -170.0), 3)


func _travel(where: String) -> void:
	if where == "cove":
		travel_to("res://scenes/pirate_cove.tscn", "dino")
	else:
		travel_to("res://scenes/main.tscn", "dino")


## A wall of soft rock with something buried in it. Three brushes and the
## fossil is free — it can never come up empty.
class DigWall extends Node2D:
	const BRUSHES := 3

	var brushed := 0
	var revealed := false
	var find_kind := "dino_bone"

	func _ready() -> void:
		find_kind = ["dino_bone", "dino_egg", "ammonite", "trilobite"][randi() % 4]

	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position - Vector2(0, -96.0)).length() / 120.0, 0.0, 1.0)

	func try_tap(_wp: Vector2) -> bool:
		return true

	func brush() -> void:
		brushed = mini(BRUSHES, brushed + 1)
		revealed = brushed >= BRUSHES
		queue_redraw()

	func _draw() -> void:
		var rock := Color("b09a82")
		DrawKit.soft_shadow(self, Vector2(0, 2), 92.0, 0.16)
		# the rock face
		draw_polygon(PackedVector2Array([
			Vector2(-96, 4), Vector2(-84, -140), Vector2(-30, -186),
			Vector2(46, -178), Vector2(94, -120), Vector2(100, 4),
		]), PackedColorArray([rock]))
		draw_polygon(PackedVector2Array([
			Vector2(-96, 4), Vector2(-84, -140), Vector2(-30, -186), Vector2(-24, -150),
			Vector2(-56, -110), Vector2(-62, 4),
		]), PackedColorArray([rock.darkened(0.12)]))
		for i in 4:
			draw_line(Vector2(-70 + i * 40, -30 - i * 18), Vector2(-40 + i * 40, -50 - i * 16),
				rock.darkened(0.2), 2.5)

		# the fossil, appearing as the rock is brushed away
		var p := Vector2(6, -96)
		var reveal := brushed / float(BRUSHES)
		if reveal > 0.0:
			# the dug-out hollow
			DrawKit.ellipse(self, p, 34.0 * reveal + 12.0, 26.0 * reveal + 10.0,
				rock.darkened(0.28))
			DrawKit.ellipse(self, p + Vector2(-2, -2), 30.0 * reveal + 8.0,
				22.0 * reveal + 7.0, Color("8f7a63"))
		if reveal >= 0.34:
			draw_set_transform(p, 0.0, Vector2.ONE * (0.18 + reveal * 0.22))
			DrawKit.draw_find(self, find_kind, 90.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if revealed:
			DrawKit.star(self, p + Vector2(34, -30), 7.0, Color("ffd98a"))
		else:
			# a little brush resting against the rock, inviting another go
			draw_line(Vector2(70, 2), Vector2(58, -40), Color("a97e54"), 5.0)
			DrawKit.rounded_rect(self, Rect2(52, -54, 12, 16), 3.0, Color("e8c88a"))


## A dinosaur. Four kinds wander the valley, all of them gentle: they amble
## back and forth, and when she says hello they come to her and lower their
## heads to be patted. Nothing here ever charges, roars at her, or runs away
## frightened.
class Dino extends Node2D:
	var species := "longneck"      ## longneck | trike | stego | compy
	var home_x := 0.0
	var roam := 220.0              ## how far either side of home it wanders
	var speed := 26.0
	var body := Color("7fa86a")

	var _t := 0.0
	var _dir := 1.0
	var _lower := 0.0
	var _greeting := false
	var _pause := 0.0

	func _ready() -> void:
		_t = randf() * 8.0
		home_x = position.x
		_dir = 1.0 if randf() < 0.5 else -1.0
		_pause = randf() * 4.0
		match species:
			"longneck":
				body = [Color("7fa86a"), Color("8a9fb8")][randi() % 2]
				speed = 24.0
			"trike":
				body = Color("b08a5e")
				speed = 30.0
				roam = 180.0
			"stego":
				body = Color("8f9a72")
				speed = 22.0
				roam = 200.0
			"compy":
				body = Color("c9a05e")
				speed = 78.0
				roam = 150.0

	func head_height() -> float:
		match species:
			"longneck": return lerpf(-268.0, -150.0, _lower)
			"trike": return -104.0
			"stego": return -96.0
		return -46.0

	func tap_score(wp: Vector2) -> float:
		var aim := Vector2(-20.0, head_height() * 0.6)
		return clampf(1.0 - (wp - global_position - aim).length() / 170.0, 0.0, 1.0)

	func try_tap(_wp: Vector2) -> bool:
		return true

	## Come and say hello: stop, turn to her, and dip the head down to be patted.
	func greet(toward_x: float) -> void:
		_greeting = true
		_dir = 1.0 if toward_x > position.x else -1.0
		var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(self, "_lower", 1.0, 0.9)
		tw.tween_interval(2.0)
		tw.tween_property(self, "_lower", 0.0, 1.1)
		tw.tween_callback(func() -> void: _greeting = false)

	func _process(delta: float) -> void:
		_t += delta
		if not _greeting:
			if _pause > 0.0:
				_pause -= delta
			else:
				position.x += _dir * speed * delta
				if absf(position.x - home_x) > roam:
					_dir = -_dir
					_pause = randf_range(1.5, 5.0)
		queue_redraw()

	func _draw() -> void:
		# the art faces LEFT when fx is 1, so fx is the opposite of the way it
		# is walking — otherwise they all amble along tail-first
		var fx := -_dir
		var step := sin(_t * (5.0 if species == "compy" else 2.2))
		var walking := _pause <= 0.0 and not _greeting
		DrawKit.soft_shadow(self, Vector2(0, 3), 96.0 if species == "longneck" else 62.0, 0.17)
		match species:
			"longneck": _draw_longneck(fx, step, walking)
			"trike": _draw_trike(fx, step, walking)
			"stego": _draw_stego(fx, step, walking)
			_: _draw_compy(fx, step, walking)

	func _legs(fx: float, step: float, walking: bool, xs: Array, top: float,
			w: float, shade := 0.16) -> void:
		for i in xs.size():
			var lx: float = float(xs[i]) * fx
			var sw := (step if i % 2 == 0 else -step) * (6.0 if walking else 0.0)
			draw_line(Vector2(lx, top), Vector2(lx + sw, -8), body.darkened(shade), w)
			DrawKit.ellipse(self, Vector2(lx + sw, -5), w * 0.66, w * 0.38, body.darkened(shade + 0.1))

	func _draw_longneck(fx: float, step: float, walking: bool) -> void:
		_legs(fx, step, walking, [-54, -18, 18, 54], -78.0, 21.0)
		DrawKit.ellipse(self, Vector2(0, -108), 84.0, 54.0, body)
		DrawKit.ellipse(self, Vector2(2, -92), 70.0, 32.0, body.lightened(0.12))
		DrawKit.ellipse(self, Vector2(-14 * fx, -128), 54.0, 26.0, body.lightened(0.06))
		DrawKit.ellipse(self, Vector2(-44 * fx, -122), 30.0, 26.0, body)
		var tail := PackedVector2Array()
		for i in 9:
			var u := i / 8.0
			tail.append(Vector2((70.0 + u * 110.0) * fx,
				-110.0 + u * 46.0 + sin(_t * 1.1 + u * 3.0) * 7.0))
		draw_polyline(tail, body.darkened(0.08), 15.0)
		var hy := head_height()
		var hx := lerpf(-104.0, -128.0, _lower) * fx
		var neck := PackedVector2Array()
		for i in 11:
			var u := i / 10.0
			neck.append(Vector2(
				lerpf(-46.0 * fx, hx, u) - sin(u * PI) * 14.0 * (1.0 - _lower) * fx,
				lerpf(-126.0, hy, u) + sin(_t * 0.8) * 6.0 * u * (1.0 - _lower)))
		draw_polyline(neck, body, 20.0)
		draw_polyline(neck, body.lightened(0.07), 9.0)
		_head(Vector2(hx, hy + sin(_t * 0.8) * 6.0 * (1.0 - _lower)), fx, 26.0, 17.0)

	func _draw_trike(fx: float, step: float, walking: bool) -> void:
		_legs(fx, step, walking, [-38, -14, 14, 38], -60.0, 19.0)
		DrawKit.ellipse(self, Vector2(0, -84), 70.0, 42.0, body)
		DrawKit.ellipse(self, Vector2(4, -70), 56.0, 26.0, body.lightened(0.12))
		var tail := PackedVector2Array()
		for i in 7:
			var u := i / 6.0
			tail.append(Vector2((58.0 + u * 62.0) * fx, -82.0 + u * 44.0))
		draw_polyline(tail, body.darkened(0.06), 14.0)
		var hp := Vector2(-92.0 * fx, -92.0 + _lower * 30.0)
		# the frill sits BEHIND the head, clear of the body
		var fr := hp + Vector2(24 * fx, -4)
		DrawKit.ellipse(self, fr, 26.0, 33.0, body.darkened(0.14))
		DrawKit.ellipse(self, fr, 20.0, 26.0, body.lightened(0.08))
		for i in 5:
			var a := -1.1 + i * 0.55
			draw_circle(fr + Vector2(cos(a) * 23.0 * fx, sin(a) * 29.0), 3.6,
				body.darkened(0.26))
		_head(hp, fx, 23.0, 15.0)
		for h in [[-8.0, -18.0, 16.0], [4.0, -22.0, 13.0], [-18.0, -4.0, 9.0]]:
			draw_polygon(PackedVector2Array([
				hp + Vector2(h[0] * fx, h[1]), hp + Vector2((h[0] - 5) * fx, h[1] + 7),
				hp + Vector2((h[0] - 4) * fx - h[2] * fx, h[1] - h[2] * 0.5),
			]), PackedColorArray([Color("efe6d0")]))

	func _draw_stego(fx: float, step: float, walking: bool) -> void:
		_legs(fx, step, walking, [-40, -14, 14, 40], -58.0, 18.0)
		DrawKit.ellipse(self, Vector2(0, -80), 74.0, 38.0, body)
		DrawKit.ellipse(self, Vector2(4, -68), 58.0, 22.0, body.lightened(0.12))
		for i in 6:
			var u := i / 5.0
			var px := lerpf(-52.0, 48.0, u) * fx
			var ph := 26.0 - absf(u - 0.5) * 22.0
			draw_polygon(PackedVector2Array([
				Vector2(px - 12 * fx, -110), Vector2(px + 12 * fx, -110),
				Vector2(px + (2.0 if i % 2 == 0 else -2.0) * fx, -110 - ph),
			]), PackedColorArray([Color("d98f6a") if i % 2 == 0 else Color("c47f5c")]))
		var tail := PackedVector2Array()
		for i in 7:
			var u := i / 6.0
			tail.append(Vector2((62.0 + u * 70.0) * fx, -84.0 + u * 30.0 + sin(_t * 1.4) * 5.0 * u))
		draw_polyline(tail, body.darkened(0.06), 13.0)
		for i in 2:
			draw_line(Vector2((122.0 + i * 6.0) * fx, -58.0 + sin(_t * 1.4) * 5.0),
				Vector2((140.0 + i * 10.0) * fx, -74.0 + i * 16.0 + sin(_t * 1.4) * 5.0),
				Color("efe6d0"), 5.0)
		_head(Vector2(-74.0 * fx, -84.0 + _lower * 30.0), fx, 20.0, 13.0)

	func _draw_compy(fx: float, step: float, walking: bool) -> void:
		var hop := absf(step) * (4.0 if walking else 0.0)
		_legs(fx, step, walking, [-8, 8], -26.0, 7.0, 0.2)
		DrawKit.ellipse(self, Vector2(0, -32 - hop), 24.0, 15.0, body)
		DrawKit.ellipse(self, Vector2(2, -28 - hop), 18.0, 9.0, body.lightened(0.14))
		var tail := PackedVector2Array()
		for i in 6:
			var u := i / 5.0
			tail.append(Vector2((20.0 + u * 40.0) * fx, -34.0 - hop + u * 14.0))
		draw_polyline(tail, body.darkened(0.08), 6.0)
		draw_line(Vector2(-14 * fx, -38 - hop), Vector2(-24 * fx, -50 - hop), body, 7.0)
		_head(Vector2(-28.0 * fx, -54.0 - hop + _lower * 22.0), fx, 12.0, 8.0)

	## A head with a friendly eye and, when the head is down, a little smile.
	func _head(p: Vector2, fx: float, w: float, h: float) -> void:
		DrawKit.ellipse(self, p, w, h, body)
		DrawKit.ellipse(self, p + Vector2(-w * 0.5 * fx, h * 0.14), w * 0.46, h * 0.52,
			body.lightened(0.06))
		draw_circle(p + Vector2(-w * 0.22 * fx, -h * 0.34), w * 0.16, Color.WHITE)
		draw_circle(p + Vector2(-w * 0.26 * fx, -h * 0.34), w * 0.085, Color("3a3a44"))
		draw_circle(p + Vector2(-w * 0.84 * fx, h * 0.06), w * 0.07, body.darkened(0.35))
		if _lower > 0.4:
			draw_arc(p + Vector2(-w * 0.45 * fx, h * 0.24), w * 0.23, 0.1, PI - 0.1, 8,
				body.darkened(0.3), 1.8, true)


## A volcano on the far horizon. It puffs, gently, forever. It never erupts.
class Volcano extends Node2D:
	var _t := 0.0
	var _puffs: Array = []

	func _ready() -> void:
		z_index = -1
		for i in 5:
			_puffs.append({"y": randf() * 120.0, "x": randf_range(-14.0, 14.0),
				"r": randf_range(14.0, 26.0)})

	func _process(delta: float) -> void:
		_t += delta
		for p in _puffs:
			p["y"] += delta * 12.0
			if p["y"] > 150.0:
				p["y"] = 0.0
				p["x"] = randf_range(-14.0, 14.0)
		queue_redraw()

	func _draw() -> void:
		var rock := Color("9c8b7a")
		draw_polygon(PackedVector2Array([
			Vector2(-300, 0), Vector2(-90, -300), Vector2(-40, -318),
			Vector2(50, -300), Vector2(310, 0),
		]), PackedColorArray([rock]))
		draw_polygon(PackedVector2Array([
			Vector2(-300, 0), Vector2(-90, -300), Vector2(-40, -318), Vector2(-60, -250),
			Vector2(-170, -80),
		]), PackedColorArray([rock.darkened(0.12)]))
		draw_polygon(PackedVector2Array([
			Vector2(-90, -300), Vector2(-40, -318), Vector2(50, -300), Vector2(-20, -286),
		]), PackedColorArray([rock.darkened(0.25)]))
		# soft puffs drifting up, never anything more
		for p in _puffs:
			var y: float = p["y"]
			var a := clampf(1.0 - y / 150.0, 0.0, 1.0) * 0.5
			draw_circle(Vector2(-20.0 + p["x"], -318.0 - y), p["r"] + y * 0.12,
				Color(0.94, 0.92, 0.9, a))


## A trail of big three-toed footprints pressed into the ground.
class Footprints extends Node2D:
	var seed_v := 0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_v + 31
		for i in 5:
			var p := Vector2(i * 74.0, -6.0 - (i % 2) * 12.0 + rng.randf_range(-4.0, 4.0))
			DrawKit.ellipse(self, p, 20.0, 11.0, Color(0.42, 0.34, 0.26, 0.17))
			for k in 3:
				var a := -0.7 + k * 0.7
				draw_circle(p + Vector2(cos(a) * 20.0, sin(a) * 9.0 - 5.0), 6.0,
					Color(0.42, 0.34, 0.26, 0.17))


## The mouth of the cave in the valley wall. Dark inside, with a low grumble
## coming out of it now and then — she can hear that somebody is in there long
## before she is brave enough to go and look.
class CaveMouth extends Node2D:
	var _t := 0.0

	func _ready() -> void:
		_t = randf() * 5.0
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position - Vector2(0, -120.0)).length() / 170.0,
			0.0, 1.0)

	func try_tap(_wp: Vector2) -> bool:
		return true

	func _draw() -> void:
		var rock := Color("9c8a72")
		# the rock face it is cut into
		DrawKit.blob(self, Vector2(0, -150), 250.0, 190.0, rock, 5)
		DrawKit.blob(self, Vector2(-150, -90), 130.0, 110.0, rock.darkened(0.06), 9)
		DrawKit.blob(self, Vector2(160, -100), 140.0, 120.0, rock.lightened(0.05), 13)
		# the opening
		draw_colored_polygon(PackedVector2Array([
			Vector2(-96, 0), Vector2(-92, -170), Vector2(-40, -232),
			Vector2(44, -232), Vector2(94, -168), Vector2(98, 0),
		]), Color("3e352f"))
		DrawKit.ellipse(self, Vector2(0, -70), 78.0, 96.0, Color("2c2521"))
		# a couple of teeth of rock in the opening
		for spec in [[-60.0, 42.0], [52.0, 34.0]]:
			draw_colored_polygon(PackedVector2Array([
				Vector2(float(spec[0]) - 14.0, -232), Vector2(float(spec[0]) + 14.0, -232),
				Vector2(float(spec[0]), -232.0 + float(spec[1])),
			]), rock.lightened(0.08))
		# somebody in there is not having a good day
		var puff := fmod(_t * 0.4, 1.0)
		draw_circle(Vector2(-10.0 - puff * 70.0, -96.0 - puff * 34.0),
			8.0 + puff * 16.0, Color(1, 1, 1, 0.13 * (1.0 - puff)))
		# bones by the entrance, and a few footprints leading in
		DrawKit.rounded_rect(self, Rect2(112, -16, 54, 11), 5.0, Color("efe6d0"))
		draw_circle(Vector2(112, -16), 8.0, Color("efe6d0"))
		draw_circle(Vector2(166, -5), 8.0, Color("efe6d0"))
		for i in 3:
			DrawKit.ellipse(self, Vector2(130.0 + i * 46.0, 14.0), 15.0, 8.0,
				Color(0.35, 0.30, 0.24, 0.22))


## The sign beside the cave mouth, pointing back at it.
##
## He is entirely friendly once she has pulled the splinter out, so this is a
## bit of theatre rather than a real warning — but a dark hole in a rock face
## deserves a sign, and "danger" is exactly the sort of word a five-year-old
## wants to be able to read. At the picture level it is a t-rex face and an
## arrow, which says the same thing without a word on it.
class CaveSign extends Node2D:
	var _t := 0.0

	func _ready() -> void:
		_t = randf() * 4.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position - Vector2(0, -110.0)).length() / 90.0,
			0.0, 1.0)

	func try_tap(_wp: Vector2) -> bool:
		Sound.knock()
		return true

	func _draw() -> void:
		var post := Color("8a6a52")
		var board := Color("d9b485")
		var ink := Color("6b4f38")
		var sway := sin(_t * 1.1) * 0.9
		DrawKit.soft_shadow(self, Vector2(4, 2), 34.0, 0.14)
		draw_line(Vector2(0, 0), Vector2(0, -108), post.darkened(0.25), 11.0)
		draw_line(Vector2(-2, 0), Vector2(-2, -108), post, 6.0)

		draw_set_transform(Vector2(0, -156), deg_to_rad(sway), Vector2.ONE)
		# the board, with a nailed-on look
		DrawKit.rounded_rect(self, Rect2(-86, -56, 172, 112), 10.0, Color("a97e54"))
		DrawKit.rounded_rect(self, Rect2(-80, -50, 160, 100), 8.0, board)
		for sx in [-68.0, 68.0]:
			for sy in [-40.0, 40.0]:
				draw_circle(Vector2(sx, sy), 3.0, Color("8a6a52"))

		# the words go along the top, wrapped, so they stay on the board
		var font := ThemeDB.fallback_font
		var lines: Array = [[], ["t-rex!"], ["danger!", "a t-rex lives here"]][
			clampi(GameState.reading_level, 0, 2)]
		var ty := -26.0
		for i in lines.size():
			var t := str(lines[i])
			var fs: int = 24 if lines.size() == 1 else (20 if i == 0 else 14)
			var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string(font, Vector2(-w * 0.5, ty), t,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("b8483f"))
			ty += 20.0

		# a t-rex head and an arrow, side by side underneath — between them they
		# say the whole thing with no reading at all
		var hc := Vector2(-38, 24)
		DrawKit.ellipse(self, hc, 24.0, 16.0, Color("6f9a5e"))
		DrawKit.rounded_rect(self, Rect2(hc.x - 23, hc.y + 5, 40, 9), 4.0, Color("5e8850"))
		for i in 4:
			draw_colored_polygon(PackedVector2Array([
				Vector2(hc.x - 17 + i * 10, hc.y + 5), Vector2(hc.x - 12 + i * 10, hc.y + 5),
				Vector2(hc.x - 14.5 + i * 10, hc.y + 13),
			]), Color("efe6d0"))
		draw_circle(hc + Vector2(9, -5), 4.6, Color("fff8ec"))
		draw_circle(hc + Vector2(10, -5), 2.6, Color("3f3a33"))
		draw_line(hc + Vector2(2, -13), hc + Vector2(14, -8), Color("4e6f42"), 2.4)

		# pointing back to the cave, which is on her left
		draw_line(Vector2(56, 26), Vector2(20, 26), Color("6b4f38"), 6.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(10, 26), Vector2(24, 18), Vector2(24, 34),
		]), Color("6b4f38"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
