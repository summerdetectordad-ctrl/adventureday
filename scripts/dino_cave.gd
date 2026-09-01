extends Zone
## The cave in Dino Land, and the T-rex who lives in it.
##
## He is enormous and he growls, and he is only ever grumpy because he keeps
## getting SPLINTERS. Nothing here can hurt her, he never chases, and the very
## worst that happens is he is a bit short with her until she works out what is
## wrong.
##
## The first visit is a little mystery: he will not say what the matter is, so
## she has to look, and then she spots it. After that he simply tells her he
## has done it again — chasing something tasty, sitting on a log — and the
## splinter moves around: a foot, a hand, and sometimes his bottom, which is
## the funniest thing in the world when you are five.
##
## A new splinter turns up ten minutes after the last one came out, so there is
## always a reason to come back, and never a reason to hurry.

const WORLD_W := 1500.0
const OUT_X := 130.0
const TREX_X := 900.0
## How long before he manages to get another one.
const SPLINTER_AGAIN := 600.0

## Where it is this time. His bottom is in here on purpose.
const SPOTS := ["foot", "hand", "bum"]

const SPOT_WORD := {
	"foot": "foot",
	"hand": "little hand",
	"bum": "bottom",
}

## How he explains it, after the first time. He is never embarrassed, and it is
## never her fault.
const EXCUSES := [
	"oh no. i think i have a splinter again. i was chasing something tasty.",
	"ouch! another splinter. i sat down on an old log.",
	"not again! i was scratching my back on a tree.",
	"oof. i got another one chasing a very quick little compy.",
	"hello again. i have done it AGAIN. i was rolling in the sticks.",
]

var trex: Trex = null
var _busy_talking := false


func _ready() -> void:
	zone_name = "cave"
	world_w = WORLD_W

	var bg := CaveBG.new()
	bg.width = WORLD_W
	bg.z_index = -3
	add_child(bg)

	# the way out, back into the daylight
	var out := Grove.Signpost.new()
	out.dir = -1.0
	out.destination = "dino"
	out.position = Vector2(OUT_X, GROUND_Y)
	add_child(out)
	interactables.append(out)

	trex = Trex.new()
	trex.position = Vector2(TREX_X, GROUND_Y)
	add_child(trex)
	interactables.append(trex)
	trex.refresh()

	var bike := Nature.Bike.new()
	bike.position = Vector2(300.0, GROUND_Y)
	add_child(bike)
	interactables.append(bike)

	setup_player(arrival_x({"dino": OUT_X + 90.0, "bike": 420.0}, 250.0))


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if ui_layer != null or busy or _busy_talking:
		return
	var wp := get_global_mouse_position()
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
		if absf(best.global_position.x - player.position.x) > 200.0:
			player.target_x = best.global_position.x - 150.0 * signf(
				best.global_position.x - player.position.x)
			await walk_until_near(best.global_position.x, 210.0)
		_interact(best)
		return
	player.target_x = wp.x



func _interact(node: Node2D) -> void:
	player.face_toward(node.global_position.x)
	if node is Grove.Signpost:
		node.point()
		travel_to("res://scenes/dino_land.tscn", "cave")
	elif node is Nature.Bike:
		open_bike_map(node)
	elif node is Trex:
		_see_to_the_trex()


# --- the T-rex ---------------------------------------------------------------

## Is there a splinter in him right now?
func _has_splinter() -> bool:
	var since := Time.get_unix_time_from_system() - GameState.trex_helped_t
	return GameState.trex_helped_t <= 0.0 or since > SPLINTER_AGAIN


## Show one exchange and wait for it to be read.
func _say(l1: String, l2: String, seconds := 3.4) -> void:
	var card := DialogueCard.show_chat(hud, l1, l2)
	await get_tree().create_timer(seconds).timeout
	if is_instance_valid(card):
		card.dismiss()
	await get_tree().create_timer(0.35).timeout


## The whole visit. First time it is a mystery she has to solve; after that he
## tells her straight away and she just gets on with it.
func _see_to_the_trex() -> void:
	if _busy_talking:
		return
	_busy_talking = true
	player.talk()
	trex.look_at_her(player.position.x)

	if not _has_splinter():
		# nothing wrong today — he is simply pleased to see her
		await _say("hello! how is your foot today?",
			"all better, thank you. no splinters at all!", 3.6)
		Fx.hearts(self, trex.position + Vector2(-90.0, -230.0), 3)
		_busy_talking = false
		return

	# pick where it is. The first one is always a foot — easier to find, and it
	# makes the funny ones funnier later.
	if GameState.trex_spot == "" or not GameState.trex_met:
		GameState.trex_spot = "foot"
	trex.splinter_spot = GameState.trex_spot
	trex.show_splinter = true
	trex.refresh()

	if not GameState.trex_met:
		await _first_time()
	else:
		await _again()

	if not is_inside_tree():
		return
	await _pull_it_out()
	_busy_talking = false


## The first meeting: he will not say what is wrong, so she looks for herself.
func _first_time() -> void:
	trex.grumpy = true
	trex.refresh()
	await _say("hello! are you a t-rex?", "rrrr. go away. i am busy being grumpy.", 3.8)
	if not is_inside_tree():
		return
	await _say("you do not look busy. you look sad.",
		"hmph. maybe i am a bit sad.", 3.4)
	if not is_inside_tree():
		return
	await _say("does something hurt?", "...my foot. but i do not know why.", 3.4)
	if not is_inside_tree():
		return
	# she has a proper look — this is the diagnosis, and she does it herself
	player.face_toward(trex.position.x)
	player.reach(trex.position + Vector2(-120.0, -60.0))
	Fx.sparkles(self, trex.position + Vector2(-140.0, -40.0), 5, Color("ffe6b3"))
	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree():
		return
	await _say("may i look? i am good at looking.", "...alright. be careful.", 3.2)
	if not is_inside_tree():
		return
	await _say("i can see it! there is a splinter in your foot.",
		"a SPLINTER? is that all it is?", 3.6)


## Every visit after that. He knows exactly what he has done.
func _again() -> void:
	trex.grumpy = true
	trex.refresh()
	var spot := str(SPOT_WORD.get(GameState.trex_spot, "foot"))
	await _say("hello! oh dear. what is it this time?",
		EXCUSES[randi() % EXCUSES.size()], 4.0)
	if not is_inside_tree():
		return
	if GameState.trex_spot == "bum":
		# the funniest possible place to get a splinter
		await _say("where is it?", "it is in my BOTTOM. do not laugh.", 3.4)
		if not is_inside_tree():
			return
		await _say("i am not laughing. (i am a bit.)",
			"hmph! alright, it IS quite funny.", 3.4)
	else:
		await _say("where is it?", "in my %s. right there. ouch." % spot, 3.4)


## Out it comes. The same ending every time, because it is the good bit.
func _pull_it_out() -> void:
	var at := trex.splinter_pos()
	player.face_toward(trex.position.x)
	player.reach(trex.global_position + at)
	Sound.grab_sound()
	await get_tree().create_timer(0.9).timeout
	if not is_inside_tree():
		return
	trex.show_splinter = false
	trex.grumpy = false
	trex.refresh()
	Fx.sparkles(self, trex.global_position + at, 8, Color("ffe6b3"))
	Sound.chime_find()
	trex.bounce()

	GameState.trex_helped_t = Time.get_unix_time_from_system()
	# next time it will be somewhere else — and it might be his bottom
	GameState.trex_spot = SPOTS[randi() % SPOTS.size()]

	if not GameState.trex_met:
		GameState.trex_met = true
		GameState.save_game()
		await _say("there! all done.",
			"it is GONE! you are brilliant. i promise never to gobble you.", 4.4)
		if not is_inside_tree():
			return
		# a proper thank you the first time
		GameState.add_to_satchel("dino_bone")
		if hud != null:
			hud.bounce_satchel()
		await _say("thank you!", "take this. it is my best bone. we are friends now.", 3.8)
	else:
		GameState.save_game()
		var thanks := [
			"that is SO much better. thank you!",
			"aaah. you are the best splinter puller there is.",
			"gone! you are very good at this.",
		]
		await _say("there you go.", thanks[randi() % thanks.size()], 3.6)
		GameState.add_fruit(2)
		GameState.add_material(["stick", "plank", "rope"][randi() % 3], 1)
		if hud != null:
			hud.bump_fruit()
			hud.bump_materials()
	Fx.hearts(self, trex.position + Vector2(-90.0, -240.0), 5)
	GameState.save_game()


## The cave itself: rock walls, a bright mouth back to the daylight, hanging
## stalactites and a few glowing crystals so it is never gloomy.
class CaveBG extends Node2D:
	var width := 1500.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var rock := Color("574a42")
		var deep := Color("3e352f")
		var floor_c := Color("6b5c4e")
		# the dark behind everything
		draw_rect(Rect2(0, -900, width, 900 + 400), deep)
		# lumpy back wall
		for i in int(width / 120.0) + 1:
			var bx := i * 120.0
			DrawKit.blob(self, Vector2(bx, GROUND_Y - 520.0), 110.0, 190.0,
				rock.darkened(0.12), i * 7 + 3)
		for i in int(width / 90.0) + 1:
			var bx2 := i * 90.0 + 45.0
			DrawKit.blob(self, Vector2(bx2, GROUND_Y - 300.0), 82.0, 150.0, rock, i * 5 + 11)
		# the floor
		draw_rect(Rect2(0, GROUND_Y, width, 400), floor_c)
		draw_rect(Rect2(0, GROUND_Y, width, 10), floor_c.lightened(0.14))
		for i in int(width / 70.0):
			draw_circle(Vector2(i * 70.0 + 30.0, GROUND_Y + 40.0 + sin(i * 2.1) * 20.0),
				3.5, floor_c.darkened(0.16))

		# stalactites from the roof, and stalagmites from the floor
		for i in int(width / 76.0):
			var sx := i * 76.0 + 20.0
			var h := 52.0 + sin(i * 3.7) * 34.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(sx - 17.0, GROUND_Y - 470.0), Vector2(sx + 17.0, GROUND_Y - 470.0),
				Vector2(sx, GROUND_Y - 470.0 + h),
			]), rock.lightened(0.06))
			if i % 3 == 0:
				var gh := 30.0 + sin(i * 1.9) * 16.0
				draw_colored_polygon(PackedVector2Array([
					Vector2(sx - 13.0, GROUND_Y + 2.0), Vector2(sx + 13.0, GROUND_Y + 2.0),
					Vector2(sx, GROUND_Y - gh),
				]), rock.lightened(0.1))

		# the mouth of the cave: daylight, so the way out is never in doubt
		var mouth := Vector2(70.0, GROUND_Y)
		draw_colored_polygon(PackedVector2Array([
			mouth + Vector2(-90, 0), mouth + Vector2(-90, -230), mouth + Vector2(-30, -290),
			mouth + Vector2(60, -290), mouth + Vector2(96, -220), mouth + Vector2(96, 0),
		]), Color("cfe6f2"))
		DrawKit.ellipse(self, mouth + Vector2(6, -120), 74.0, 118.0, Color("e8f4fa"))
		draw_rect(Rect2(mouth.x - 88, mouth.y - 40, 182, 40), Color("d8ddc4"))

		# Glowing crystals, gently breathing. They GROW OUT OF something — a
		# clump on the floor or a ledge on the wall — because a crystal floating
		# in mid-air just reads as a mistake.
		for spec in [[520.0, 0.0, 5, 1.0], [640.0, -196.0, 9, 0.75],
				[1120.0, 0.0, 4, 1.15], [1370.0, -168.0, 7, 0.7], [830.0, 0.0, 2, 0.6]]:
			var cx: float = spec[0]
			var cy: float = spec[1]
			var sc: float = spec[3]
			var glow := 0.55 + 0.45 * sin(_t * 1.1 + float(spec[2]))
			var c := Vector2(cx, GROUND_Y + cy)
			if cy < 0.0:
				# a little rock shelf for the wall ones to sit on
				DrawKit.ellipse(self, c + Vector2(0, 6.0 * sc), 34.0 * sc, 9.0 * sc,
					rock.lightened(0.12))
			draw_circle(c + Vector2(0, -14.0 * sc), 40.0 * sc,
				Color(0.62, 0.86, 0.95, 0.09 * glow))
			for k in 3:
				var kh := (26.0 - absf(1.0 - k) * 8.0) * sc
				var kx := c + Vector2((-13.0 + k * 13.0) * sc, 0.0)
				draw_colored_polygon(PackedVector2Array([
					kx + Vector2(-6.0 * sc, 2.0), kx + Vector2(6.0 * sc, 2.0),
					kx + Vector2(0, -kh),
				]), Color(0.66, 0.9, 0.98, 0.55 + 0.25 * glow))
				draw_colored_polygon(PackedVector2Array([
					kx + Vector2(-6.0 * sc, 2.0), kx + Vector2(0, 2.0),
					kx + Vector2(0, -kh),
				]), Color(0.78, 0.95, 1.0, 0.45 + 0.2 * glow))


## The T-rex. Enormous, sitting down, and entirely harmless. He is drawn
## GRUMPY or PLEASED, and with or without a splinter in whichever bit of him
## is currently the problem.
class Trex extends Node2D:
	var grumpy := false
	var show_splinter := false
	var splinter_spot := "foot"
	var _t := 0.0
	var _look := 0.0
	var _bounce := 0.0

	func _ready() -> void:
		_t = randf() * 4.0

	func refresh() -> void:
		queue_redraw()

	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position - Vector2(-60, -180)).length() / 240.0,
			0.0, 1.0)

	func try_tap(_wp: Vector2) -> bool:
		return true

	func look_at_her(x: float) -> void:
		_look = 2.5
		if x < global_position.x:
			_look = 2.5

	func bounce() -> void:
		_bounce = 1.0

	func _process(delta: float) -> void:
		_t += delta
		if _look > 0.0:
			_look = maxf(0.0, _look - delta)
		if _bounce > 0.0:
			_bounce = maxf(0.0, _bounce - delta * 1.6)
		queue_redraw()

	## Where the splinter is, in his local space — so she reaches for the right
	## bit of him, and the sparkles land there too.
	func splinter_pos() -> Vector2:
		match splinter_spot:
			"hand": return Vector2(-92, -196)
			"bum": return Vector2(120, -132)
			_: return Vector2(-118, -18)

	func _draw() -> void:
		var body := Color("6f9a5e") if not grumpy else Color("6a8f5b")
		var belly := Color("bcd6a0")
		var dark := body.darkened(0.22)
		var breathe := sin(_t * 1.2) * 3.0
		var hop := sin(_bounce * PI) * 14.0
		draw_set_transform(Vector2(0, -hop), 0.0, Vector2.ONE)

		DrawKit.soft_shadow(self, Vector2(10, 2), 150.0, 0.20)

		# tail, curled round behind him
		var tail := PackedVector2Array()
		for i in 13:
			var v := i / 12.0
			tail.append(Vector2(80.0 + 214.0 * v, -160.0 + 138.0 * v * v + 26.0 * v))
		for i in 13:
			var v := 1.0 - i / 12.0
			tail.append(Vector2(80.0 + 214.0 * v,
				-160.0 + 138.0 * v * v + 26.0 * v + (54.0 * (1.0 - v) + 4.0)))
		draw_colored_polygon(tail, dark)

		# the big sitting legs
		for spec in [[36.0, 0.0], [-46.0, 6.0]]:
			var lx: float = spec[0]
			DrawKit.ellipse(self, Vector2(lx, -66), 56.0, 62.0, dark)
			DrawKit.ellipse(self, Vector2(lx - 6.0, -70), 48.0, 54.0, body)
		# the near foot, toes forward — this is the usual splinter
		DrawKit.rounded_rect(self, Rect2(-160, -34, 120, 34), 15.0, dark)
		DrawKit.rounded_rect(self, Rect2(-156, -38, 112, 32), 14.0, body)
		for i in 3:
			draw_circle(Vector2(-146.0 + i * 34.0, -8.0), 9.0, Color("efe6d0"))

		# body, sitting up
		DrawKit.ellipse(self, Vector2(0, -180 + breathe), 96.0, 118.0, dark)
		DrawKit.ellipse(self, Vector2(-4, -182 + breathe), 88.0, 110.0, body)
		DrawKit.ellipse(self, Vector2(-36, -168 + breathe), 46.0, 76.0, belly)

		# little arms — famously little
		var arm_y := -196.0 + breathe
		draw_line(Vector2(-62, arm_y), Vector2(-92, arm_y + 6.0), dark, 15.0)
		draw_line(Vector2(-62, arm_y), Vector2(-92, arm_y + 6.0), body, 11.0)
		for i in 2:
			draw_line(Vector2(-92, arm_y + 6.0), Vector2(-108, arm_y + 1.0 + i * 9.0),
				Color("efe6d0"), 3.5)

		# head
		var head := Vector2(-52, -300 + breathe + (-6.0 if _look > 0.0 else 0.0))
		DrawKit.ellipse(self, head, 78.0, 54.0, dark)
		DrawKit.ellipse(self, head + Vector2(-2, -2), 72.0, 48.0, body)
		# jaw
		DrawKit.rounded_rect(self, Rect2(head.x - 74, head.y + 16, 128, 26), 11.0, dark)
		DrawKit.rounded_rect(self, Rect2(head.x - 72, head.y + 14, 124, 22), 10.0,
			body.lightened(0.05))
		# teeth, blunt and cheerful rather than sharp
		for i in 6:
			var tx := head.x - 62.0 + i * 20.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(tx - 5, head.y + 16), Vector2(tx + 5, head.y + 16),
				Vector2(tx, head.y + 27),
			]), Color("efe6d0"))
		# eye: a cross brow when grumpy, a happy arc when not
		var eye := head + Vector2(22, -10)
		draw_circle(eye, 11.0, Color("fff8ec"))
		draw_circle(eye + Vector2(2.0 if _look > 0.0 else 0.0, 0), 6.0, Color("3f3a33"))
		draw_circle(eye + Vector2(-1.5, -2.0), 2.2, Color.WHITE)
		if grumpy:
			draw_line(eye + Vector2(-13, -14), eye + Vector2(10, -7), dark.darkened(0.3), 5.0)
		else:
			draw_arc(eye + Vector2(0, -13), 11.0, PI + 0.3, TAU - 0.3, 10,
				dark.darkened(0.3), 4.0, true)
		draw_circle(head + Vector2(-58, -8), 4.0, dark.darkened(0.3))    # nostril
		# a grumpy puff of breath, or a happy little heart
		if grumpy:
			for i in 2:
				var pu := fmod(_t * 0.7 + i * 0.5, 1.0)
				draw_circle(head + Vector2(-70.0 - pu * 40.0, -6.0 - pu * 18.0),
					4.0 + pu * 7.0, Color(1, 1, 1, 0.20 * (1.0 - pu)))

		# the splinter, wherever it is today, with a sore red glow round it
		if show_splinter:
			var sp := splinter_pos()
			draw_circle(sp, 22.0 + sin(_t * 4.0) * 2.0, Color(0.9, 0.35, 0.3, 0.22))
			draw_circle(sp, 13.0, Color(0.92, 0.45, 0.4, 0.32))
			draw_line(sp + Vector2(-3, 8), sp + Vector2(5, -14), Color("8a6a44"), 5.0)
			draw_line(sp + Vector2(-2, 6), sp + Vector2(4, -12), Color("c9a06c"), 2.6)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
