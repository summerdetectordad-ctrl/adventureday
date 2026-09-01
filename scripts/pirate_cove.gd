extends Zone
## Pirate Cove, beyond Dino Land. Sand to dig, rock pools to peer into, a
## friendly parrot that copies her whistle, and a wrecked boat with a treasure
## map hidden around it in four pieces.
##
## The map is the spine: every dig in the sand turns up a piece until she has
## all four, and then the X appears and the chest is there. It cannot fail and
## it cannot run out — the fourth piece is guaranteed by the fourth dig.

const WORLD_W := 2400.0
const HOME_SIGN_X := 90.0
const CHEST_X := 1880.0

var chest: Chest = null


func _ready() -> void:
	zone_name = "cove"
	setup_ground(WORLD_W, "cove")

	var sea := Sea.new()
	sea.position = Vector2(0, GROUND_Y)
	sea.width = WORLD_W
	add_child(sea)

	# ships out on the water: one close in, two further off
	for spec in [[700.0, 1.0, 3], [1560.0, 0.62, 8], [2180.0, 0.44, 5]]:
		var ship := PirateShip.new()
		ship.scale = Vector2(float(spec[1]), float(spec[1]))
		ship.seed_v = int(spec[2])
		ship.position = Vector2(float(spec[0]), GROUND_Y - 104.0 - (1.0 - float(spec[1])) * 26.0)
		ship.z_index = -1
		add_child(ship)

	var home := Grove.Signpost.new()
	home.dir = -1.0
	home.destination = "home"
	home.position = Vector2(HOME_SIGN_X, GROUND_Y)
	add_child(home)
	interactables.append(home)

	var wreck := Wreck.new()
	wreck.position = Vector2(1180.0, GROUND_Y)
	add_child(wreck)
	interactables.append(wreck)

	for px in [520.0, 900.0, 1520.0]:
		var pool := RockPool.new()
		pool.position = Vector2(px, GROUND_Y + 4.0)
		add_child(pool)
		interactables.append(pool)

	var plank_game := Grove.GameSpot.new()
	plank_game.game = "plank"
	plank_game.position = Vector2(1010.0, GROUND_Y - 150.0)
	add_child(plank_game)
	interactables.append(plank_game)

	var parrot := Parrot.new()
	parrot.position = Vector2(1240.0, GROUND_Y - 236.0)
	add_child(parrot)
	interactables.append(parrot)

	# four patches of sand to dig, one map piece each
	for sx in [420.0, 780.0, 1420.0, 1700.0]:
		var spot := SandSpot.new()
		spot.position = Vector2(sx, GROUND_Y)
		add_child(spot)
		interactables.append(spot)

	chest = Chest.new()
	chest.position = Vector2(CHEST_X, GROUND_Y)
	add_child(chest)
	interactables.append(chest)

	# the crew, ashore for the day
	spawn_folk("cove", [560.0, 1080.0, 1620.0])

	var bike := Nature.Bike.new()
	bike.position = Vector2(320.0, GROUND_Y)
	add_child(bike)
	interactables.append(bike)

	setup_player(arrival_x({"dino": HOME_SIGN_X + 90.0, "bike": 700.0}, 220.0))


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
		go_home()
	elif node is SandSpot:
		_dig_sand(node, wp)
	elif node is RockPool:
		_peer(node)
	elif node is Grove.GameSpot:
		open_game(PlankGame.new())
	elif node is Nature.Bike:
		open_bike_map(node)
	elif node is Folk.Person:
		talk_to(node)
	elif node is Parrot:
		_talk_to_parrot(node)
	elif node is Chest:
		_open_chest(node)
	elif node is Wreck:
		Sound.knock()
		Fx.dirt(self, wp, 3)


## Dig the sand. Every patch has a piece of the map — the fourth one always
## finishes it, so the treasure can never be out of reach.
func _dig_sand(spot: SandSpot, wp: Vector2) -> void:
	if spot.dug:
		Fx.sparkles(self, spot.position + Vector2(0, -30.0), 3, Color("ffe6b3"))
		Sound.pop()
		return
	busy = true
	player.reach(wp)
	player.start_dig()
	Sound.dig_sound()
	await get_tree().create_timer(0.9).timeout
	if not is_inside_tree():
		busy = false
		return
	spot.dug = true
	spot.queue_redraw()
	Fx.dirt(self, spot.position + Vector2(0, -20.0), 8)
	GameState.map_pieces = mini(4, GameState.map_pieces + 1)
	GameState.save_game()
	Fx.sparkles(self, spot.position + Vector2(0, -40.0), 10, Color("ffe6b3"))
	Sound.chime_find()
	MapPieceCard.show_piece(hud, GameState.map_pieces)
	if GameState.map_pieces >= 4 and chest != null:
		chest.revealed = true
		chest.queue_redraw()
	busy = false


func _peer(pool: RockPool) -> void:
	player.reach(pool.global_position + Vector2(0, -10.0))
	var found := pool.look()
	Sound.pop()
	if found != "":
		GameState.add_to_satchel(found)
		hud.bounce_satchel()
		Fx.sparkles(self, pool.position + Vector2(0, -30.0), 8, Color("a9d7e8"))
		Sound.chime_find()
	else:
		Fx.hearts(self, pool.position + Vector2(0, -40.0), 1)


func _talk_to_parrot(parrot: Parrot) -> void:
	parrot.squawk()
	Sound.chirp()
	meet_animal("parrot", parrot)


## The chest only appears once the map is whole. Opening it is the payoff.
func _open_chest(c: Chest) -> void:
	if not c.revealed:
		# still buried — a friendly nudge toward the sand
		Fx.hearts(self, c.position + Vector2(0, -50.0), 1)
		Sound.pop()
		return
	if c.opened:
		Fx.sparkles(self, c.position + Vector2(0, -50.0), 5, Color("ffd98a"))
		Sound.pop()
		return
	busy = true
	c.opened = true
	c.queue_redraw()
	Sound.chime_shelf()
	Fx.sparkles(self, c.position + Vector2(0, -60.0), 16, Color("ffd98a"))
	for kind in ["pirate_coin", "gem", "old_key"]:
		GameState.add_to_satchel(kind)
	hud.bounce_satchel()
	await get_tree().create_timer(0.8).timeout
	if not is_inside_tree():
		busy = false
		return
	AffirmationCard.show_card(hud, Affirm.next())
	busy = false


## The sea along the back, rolling in and out. Purely scenery — she never has
## to go in it.
class Sea extends Node2D:
	var width := 2400.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -2

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var far := Color("7fb5c9")
		var near := Color("a9d3e2")
		draw_rect(Rect2(0, -150, width, 92), far)
		for band in 3:
			var pts := PackedVector2Array()
			var y := -102.0 + band * 18.0
			var x := 0.0
			while x <= width:
				pts.append(Vector2(x, y + sin(x * 0.012 + _t * (0.7 + band * 0.2)) * 4.0))
				x += 40.0
			draw_polyline(pts, near.lightened(0.1 - band * 0.03), 3.0)
		# the wet edge where the sea meets the sand
		var edge := PackedVector2Array()
		var ex := 0.0
		while ex <= width:
			edge.append(Vector2(ex, -58.0 + sin(ex * 0.008 + _t * 0.5) * 5.0))
			ex += 40.0
		edge.append(Vector2(width, -40.0))
		edge.append(Vector2(0, -40.0))
		draw_polygon(edge, PackedColorArray([Color(0.78, 0.86, 0.86, 0.55)]))


## A patch of soft sand with a piece of the map under it.
class SandSpot extends Node2D:
	var dug := false
	var _t := 0.0

	func _ready() -> void:
		_t = randf() * 4.0

	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position - Vector2(0, -14.0)).length() / 84.0, 0.0, 1.0)

	func try_tap(_wp: Vector2) -> bool:
		return true

	func _process(delta: float) -> void:
		_t += delta
		if not dug:
			queue_redraw()

	func _draw() -> void:
		var sand := Color("d8c9a4")
		if dug:
			DrawKit.ellipse(self, Vector2(0, -6), 40.0, 13.0, sand.darkened(0.22))
			DrawKit.ellipse(self, Vector2(-2, -9), 32.0, 9.0, sand.darkened(0.34))
			return
		DrawKit.ellipse(self, Vector2(0, -6), 44.0, 15.0, sand.lightened(0.08))
		DrawKit.ellipse(self, Vector2(-3, -9), 34.0, 10.0, sand.lightened(0.16))
		# a corner of paper just showing, glinting now and then
		var glint := 0.3 + 0.3 * sin(_t * 1.6)
		draw_polygon(PackedVector2Array([
			Vector2(6, -14), Vector2(20, -12), Vector2(14, -22),
		]), PackedColorArray([Color("f2e6c8")]))
		DrawKit.star(self, Vector2(16, -26), 5.0, Color(1.0, 0.87, 0.6, glint))


## A rock pool. Peer in and there might be a shell, a tooth or just a crab
## waving hello — never nothing worth looking at.
class RockPool extends Node2D:
	var looked := 0
	var _t := 0.0
	var _crab := 0.0

	func _ready() -> void:
		_t = randf() * 5.0

	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position - Vector2(0, -16.0)).length() / 88.0, 0.0, 1.0)

	func try_tap(_wp: Vector2) -> bool:
		return true

	## Look in. The first two looks give a find; after that a crab says hello.
	func look() -> String:
		looked += 1
		_crab = 1.0
		queue_redraw()
		if looked <= 2:
			return ["shark_tooth", "ammonite"][looked - 1]
		return ""

	func _process(delta: float) -> void:
		_t += delta
		if _crab > 0.0:
			_crab = maxf(0.0, _crab - delta * 0.5)
		queue_redraw()

	func _draw() -> void:
		var rock := Color("b8a88f")
		DrawKit.ellipse(self, Vector2(0, -4), 62.0, 20.0, rock.darkened(0.1))
		DrawKit.ellipse(self, Vector2(0, -8), 50.0, 15.0, Color("6fb3d2"))
		DrawKit.ellipse(self, Vector2(-6, -11), 34.0, 9.0,
			Color(0.72, 0.88, 0.93, 0.6 + 0.15 * sin(_t * 1.3)))
		# weed and a limpet or two
		for i in 3:
			var wx := -30.0 + i * 26.0
			draw_line(Vector2(wx, -6), Vector2(wx + sin(_t * 1.1 + i) * 4.0, -20), Color("6f9a5d"), 3.0)
		draw_circle(Vector2(22, -6), 5.0, Color("cbb89a"))
		# the crab, out for a wave after she has looked
		if _crab > 0.05:
			var cx := 14.0 + sin(_t * 3.0) * 4.0
			DrawKit.ellipse(self, Vector2(cx, -16), 9.0, 6.0, Color("d9705e"))
			for sx in [-1.0, 1.0]:
				draw_line(Vector2(cx + sx * 7, -16), Vector2(cx + sx * 14, -22), Color("d9705e"), 2.5)
			draw_circle(Vector2(cx - 3, -20), 1.8, Color("3a3a44"))
			draw_circle(Vector2(cx + 3, -20), 1.8, Color("3a3a44"))


## The wrecked boat, half in the sand. Something to climb on and look at.
class Wreck extends Node2D:
	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position - Vector2(0, -80.0)).length() / 130.0, 0.0, 1.0)

	func try_tap(_wp: Vector2) -> bool:
		return true

	func _draw() -> void:
		var wood := Color("8a6a52")
		DrawKit.soft_shadow(self, Vector2(0, 2), 130.0, 0.16)
		# the hull, tipped over
		draw_set_transform(Vector2.ZERO, -0.16, Vector2.ONE)
		draw_polygon(PackedVector2Array([
			Vector2(-140, 0), Vector2(140, 0), Vector2(104, -66), Vector2(-104, -66),
		]), PackedColorArray([wood]))
		for i in 4:
			draw_line(Vector2(-132 + i * 6, -6 - i * 14), Vector2(132 - i * 6, -6 - i * 14),
				wood.darkened(0.14), 3.0)
		draw_polygon(PackedVector2Array([
			Vector2(-140, 0), Vector2(-104, -66), Vector2(-86, -66), Vector2(-118, 0),
		]), PackedColorArray([wood.darkened(0.16)]))
		# a broken mast with a scrap of sail
		draw_line(Vector2(20, -60), Vector2(48, -240), wood.darkened(0.08), 11.0)
		draw_polygon(PackedVector2Array([
			Vector2(44, -226), Vector2(120, -190), Vector2(38, -150),
		]), PackedColorArray([Color("f2e6c8")]))
		draw_polygon(PackedVector2Array([
			Vector2(44, -226), Vector2(86, -206), Vector2(42, -186),
		]), PackedColorArray([Color("e4d5b2")]))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# a rope coil and a barrel in the sand
		draw_arc(Vector2(-150, -10), 16.0, 0, TAU, 20, Color("9a8055"), 6.0, true)
		DrawKit.rounded_rect(self, Rect2(150, -46, 44, 46), 8.0, Color("a97e54"))
		draw_rect(Rect2(150, -34, 44, 5), Color("7a5c40"))
		draw_rect(Rect2(150, -18, 44, 5), Color("7a5c40"))


## A parrot on the mast. It copies whatever she says, which is the entire joke
## and works every time.
class Parrot extends Node2D:
	var _t := 0.0
	var _squawk := 0.0

	func _ready() -> void:
		_t = randf() * 6.0

	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position).length() / 86.0, 0.0, 1.0)

	func try_tap(_wp: Vector2) -> bool:
		return true

	func squawk() -> void:
		_squawk = 1.0

	func _process(delta: float) -> void:
		_t += delta
		if _squawk > 0.0:
			_squawk = maxf(0.0, _squawk - delta * 1.2)
		queue_redraw()

	func _draw() -> void:
		var bob := sin(_t * 1.6) * 2.0 + sin(_squawk * PI * 6.0) * _squawk * 3.0
		# tail, body, wing, head
		draw_polygon(PackedVector2Array([
			Vector2(-6, 6 + bob), Vector2(-34, 26 + bob), Vector2(-10, 16 + bob),
		]), PackedColorArray([Color("4a8fd0")]))
		DrawKit.ellipse(self, Vector2(0, bob), 16.0, 22.0, Color("d94f4f"))
		DrawKit.ellipse(self, Vector2(-4, 2 + bob), 10.0, 15.0, Color("e87070"))
		draw_polygon(PackedVector2Array([
			Vector2(2, -6 + bob), Vector2(16, 10 + bob), Vector2(2, 14 + bob),
		]), PackedColorArray([Color("4aa85a")]))
		draw_circle(Vector2(2, -20 + bob), 13.0, Color("d94f4f"))
		# beak, eye, and a jaunty crest
		draw_polygon(PackedVector2Array([
			Vector2(12, -24 + bob), Vector2(26, -18 + bob), Vector2(12, -12 + bob),
		]), PackedColorArray([Color("f0c04a")]))
		draw_circle(Vector2(6, -24 + bob), 3.4, Color.WHITE)
		draw_circle(Vector2(7, -24 + bob), 1.8, Color("3a3a44"))
		for i in 3:
			draw_line(Vector2(-2 - i * 3, -30 + bob), Vector2(-8 - i * 4, -42 + bob),
				[Color("f0c04a"), Color("4aa85a"), Color("4a8fd0")][i], 2.5)
		# feet on the spar
		for fx2 in [-4.0, 5.0]:
			draw_line(Vector2(fx2, 20 + bob), Vector2(fx2, 27 + bob), Color("c2a05a"), 2.5)


## The treasure chest at the X. Buried until the map is whole.
class Chest extends Node2D:
	var revealed := false
	var opened := false
	var _t := 0.0

	func _ready() -> void:
		revealed = GameState.map_pieces >= 4
		_t = randf() * 4.0

	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position - Vector2(0, -30.0)).length() / 96.0, 0.0, 1.0)

	func try_tap(_wp: Vector2) -> bool:
		return true

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if not revealed:
			# just a patch of sand with two crossed sticks — the X is a secret
			DrawKit.ellipse(self, Vector2(0, -4), 40.0, 13.0, Color("cbb89a"))
			draw_line(Vector2(-14, -12), Vector2(14, 0), Color("a9906a"), 4.0)
			draw_line(Vector2(14, -12), Vector2(-14, 0), Color("a9906a"), 4.0)
			return
		var lid := -14.0 if opened else 0.0
		DrawKit.soft_shadow(self, Vector2(0, 2), 54.0, 0.16)
		DrawKit.rounded_rect(self, Rect2(-46, -46, 92, 46), 5.0, Color("8a6a52"))
		draw_rect(Rect2(-46, -30, 92, 7), Color("c2a05a"))
		draw_rect(Rect2(-8, -46, 16, 46), Color("c2a05a"))
		# the lid, up if she has opened it
		draw_set_transform(Vector2(0, -46), lid * 0.03, Vector2.ONE)
		draw_polygon(PackedVector2Array([
			Vector2(-46, 0), Vector2(46, 0), Vector2(38, -22 + lid), Vector2(-38, -22 + lid),
		]), PackedColorArray([Color("9a7a5e")]))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if opened:
			# gold spilling out, twinkling
			for i in 7:
				var gx := -30.0 + i * 10.0
				draw_circle(Vector2(gx, -50 + sin(_t + i) * 2.0), 6.0, Color("d9a940"))
				draw_circle(Vector2(gx - 2, -52 + sin(_t + i) * 2.0), 2.4, Color("f0c96a"))
			DrawKit.star(self, Vector2(0, -76 + sin(_t * 2.0) * 3.0), 9.0, Color("ffd98a"))
		else:
			DrawKit.star(self, Vector2(0, -70 + sin(_t * 2.2) * 3.0), 8.0, Color("ffd98a"))


## The map, shown a piece at a time as she digs them up. Four pieces and it is
## whole, and the X is right there.
class MapPieceCard extends CanvasLayer:
	var pieces := 1

	static func show_piece(parent: Node, n: int) -> MapPieceCard:
		var c := MapPieceCard.new()
		c.pieces = n
		parent.add_child(c)
		Sound.card_sound()
		return c

	func _ready() -> void:
		layer = 46
		var body := Body.new()
		body.pieces = pieces
		body.dismissed.connect(queue_free)
		add_child(body)

	class Body extends Control:
		signal dismissed
		var pieces := 1
		var _shown := 0.0

		func _ready() -> void:
			set_anchors_preset(Control.PRESET_FULL_RECT)
			mouse_filter = Control.MOUSE_FILTER_STOP
			size = get_viewport().get_visible_rect().size
			_shown = Time.get_ticks_msec() / 1000.0
			modulate.a = 0.0
			scale = Vector2(0.7, 0.7)
			pivot_offset = size / 2.0
			var tw := create_tween()
			tw.tween_property(self, "modulate:a", 1.0, 0.2)
			tw.parallel().tween_property(self, "scale", Vector2.ONE, 0.36) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			get_tree().create_timer(5.0).timeout.connect(_dismiss)

		func _gui_input(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed:
				accept_event()
				if Time.get_ticks_msec() / 1000.0 - _shown > 0.4:
					_dismiss()

		func _dismiss() -> void:
			if not is_inside_tree():
				return
			var tw := create_tween()
			tw.tween_property(self, "modulate:a", 0.0, 0.22)
			tw.tween_callback(func() -> void: dismissed.emit())

		func _draw() -> void:
			var vs := size
			draw_rect(Rect2(Vector2.ZERO, vs), Color(0.2, 0.16, 0.1, 0.35))
			var c := vs * 0.5
			var w := 380.0
			var h := 280.0
			# the paper, torn at the edges
			DrawKit.rounded_rect(self, Rect2(c.x - w / 2 + 6, c.y - h / 2 + 8, w, h), 6.0,
				Color(0, 0, 0, 0.14))
			DrawKit.rounded_rect(self, Rect2(c.x - w / 2, c.y - h / 2, w, h), 6.0, Color("f2e6c8"))
			# each quarter she has found so far
			for i in 4:
				if i >= pieces:
					continue
				var qx := c.x - w / 2 + (i % 2) * w / 2
				var qy := c.y - h / 2 + floori(i / 2.0) * h / 2
				draw_rect(Rect2(qx + 6, qy + 6, w / 2 - 12, h / 2 - 12), Color("e8d9b4"))
			# the coastline, and the X once it is whole
			draw_polyline(PackedVector2Array([
				c + Vector2(-140, 40), c + Vector2(-70, 10), c + Vector2(-10, 40),
				c + Vector2(60, 0), c + Vector2(140, 30),
			]), Color("9a7a55"), 3.0)
			for i in 3:
				draw_arc(c + Vector2(-100 + i * 30, -60), 10.0 + i * 3.0, PI, TAU, 10,
					Color("b39a6d"), 2.0, true)
			if pieces >= 4:
				draw_line(c + Vector2(78, -16), c + Vector2(112, 18), Color("c8384a"), 6.0)
				draw_line(c + Vector2(112, -16), c + Vector2(78, 18), Color("c8384a"), 6.0)
				DrawKit.star(self, c + Vector2(95, -44), 10.0, Color("ffd98a"))
			# how many pieces, as dots she can count
			for i in 4:
				draw_circle(c + Vector2(-33 + i * 22, h / 2 - 22), 8.0,
					Color("c8384a") if i < pieces else Color("d9cfba"))


## A ship out in the bay: hull, masts, square sails and a flag, riding the
## swell. Pure scenery — she cannot sail it, and nothing about it can go wrong.
## Drawn behind everything on the beach and in front of the sea.
class PirateShip extends Node2D:
	var seed_v := 3
	var _t := 0.0

	func _ready() -> void:
		_t = seed_v * 1.7

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var hull := Color("6b4f38")
		var deck := Color("a97e54")
		var sail := Color("f4ead6")
		var trim := Color("c96b64")
		# riding the swell: the whole ship lifts and tips a little
		var lift := sin(_t * 0.8) * 4.0
		var tip := sin(_t * 0.62 + 1.1) * 0.026
		draw_set_transform(Vector2(0, lift), tip, Vector2.ONE)

		# masts, rigging, and the bowsprit poking out over the water
		for mx in [-34.0, 26.0]:
			draw_line(Vector2(mx, -20), Vector2(mx, -196), deck.darkened(0.32), 4.5)
		draw_line(Vector2(86, -34), Vector2(122, -50), deck.darkened(0.32), 3.5)
		draw_line(Vector2(-34, -196), Vector2(-88, -34), Color("8a7355"), 1.4)
		draw_line(Vector2(26, -196), Vector2(122, -50), Color("8a7355"), 1.4)
		draw_line(Vector2(26, -196), Vector2(-34, -150), Color("8a7355"), 1.4)

		# square sails: narrow, bellied, with clear sky between them
		for spec in [[-34.0, -182.0, 30.0, 52.0], [-34.0, -118.0, 26.0, 42.0],
				[26.0, -176.0, 27.0, 48.0], [26.0, -118.0, 23.0, 38.0]]:
			var mx: float = spec[0]
			var top: float = spec[1]
			var hw: float = spec[2]
			var h: float = spec[3]
			var belly := 7.0 + sin(_t * 1.1 + mx) * 2.0
			var pts := PackedVector2Array()
			for i in 9:
				var v := i / 8.0
				pts.append(Vector2(mx - hw + 2.0 * hw * v, top + sin(v * PI) * 2.0))
			for i in 9:
				var v := 1.0 - i / 8.0
				pts.append(Vector2(mx - hw + 2.0 * hw * v,
					top + h + sin(v * PI) * belly))
			draw_colored_polygon(pts, sail)
			draw_rect(Rect2(mx - hw * 0.94, top + h * 0.5, hw * 1.88, h * 0.13), trim)
			draw_line(Vector2(mx - hw - 3.0, top), Vector2(mx + hw + 3.0, top),
				deck.darkened(0.35), 3.0)

		# the flag at the masthead
		var flap := sin(_t * 3.2) * 4.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(-34, -196), Vector2(-4, -190 + flap), Vector2(-34, -182),
		]), trim)
		DrawKit.star(self, Vector2(-24, -190 + flap * 0.4), 4.0, Color("fff8ec"))

		# the hull: long, curved, deeper amidships, with a rising stern
		var body := PackedVector2Array()
		for i in 17:
			var v := i / 16.0
			body.append(Vector2(-96.0 + 190.0 * v, -34.0 + sin(v * PI) * 7.0))
		for i in 17:
			var v := 1.0 - i / 16.0
			body.append(Vector2(-78.0 + 158.0 * v, 16.0 - sin(v * PI) * 11.0))
		draw_colored_polygon(body, hull)
		# the stern castle at the back, and the deck rail along the top
		DrawKit.rounded_rect(self, Rect2(-104, -56, 34, 26), 5.0, hull.lightened(0.06))
		draw_rect(Rect2(-96, -34, 190, 8), deck)
		draw_rect(Rect2(-96, -30, 190, 3), hull.darkened(0.2))
		# portholes along the side
		for i in 6:
			draw_circle(Vector2(-70.0 + i * 28.0, -18.0), 4.4, Color("d9c9a0"))
			draw_circle(Vector2(-70.0 + i * 28.0, -18.0), 2.6, Color("8a7355"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		# its reflection, wobbling on the water
		for i in 4:
			var w := 52.0 - i * 10.0
			draw_line(Vector2(-w + sin(_t * 1.4 + i) * 5.0, 22.0 + i * 7.0),
				Vector2(w + sin(_t * 1.4 + i) * 5.0, 22.0 + i * 7.0),
				Color(1, 1, 1, 0.20 - i * 0.04), 3.0)
