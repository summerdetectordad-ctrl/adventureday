extends Zone
## The market, west of the home grove. A row of stalls under striped awnings,
## each with a banner saying what it sells, and a trader pottering about behind
## the counter.
##
## Barter, not money — museum finds are never spent. Every stall BUYS and
## SELLS: she can swap fruit for what she needs, or hand materials back for
## fruit when she is short. Selling gives one fruit less than buying costs,
## which is how every market that ever existed works, and it means trading in
## circles slowly costs her — but fruit regrows, so she can never get stuck.
##
## Stalls never run out and nothing is ever unavailable, so there is no way to
## come away disappointed.

const WORLD_W := 1720.0
const HOME_SIGN_X := 100.0

## Every stall: what it trades, the fruit it asks, and how it looks. `sell` is
## worked out from `fruit`, never stored, so the two can never drift apart.
const STALLS := [
	{"x": 400.0, "gives": "timber", "n": 1, "fruit": 3, "awning": "c96b64", "word": "wood"},
	{"x": 640.0, "gives": "paint", "n": 1, "fruit": 4, "awning": "6fb3d2", "word": "paint"},
	{"x": 880.0, "gives": "plank", "n": 2, "fruit": 2, "awning": "8fc48a", "word": "planks"},
	{"x": 1120.0, "gives": "rope", "n": 2, "fruit": 2, "awning": "c4a0d8", "word": "rope"},
	{"x": 1340.0, "gives": "seed", "n": 2, "fruit": 1, "awning": "8fc48a", "word": "seeds"},
	{"x": 1560.0, "gives": "pastry", "n": 1, "fruit": 2, "awning": "e8b06a", "word": "pie tin"},
]

var trading := false


## What a stall pays for goods handed back: one fruit less than it charges,
## and never less than nothing.
static func sell_price(buy_fruit: int) -> int:
	return maxi(0, buy_fruit - 1)


func _ready() -> void:
	zone_name = "market"
	setup_ground(WORLD_W)

	for tree_x in [220.0, 1670.0]:
		var tree := Nature.MeadowTree.new()
		tree.position = Vector2(tree_x, GROUND_Y)
		add_child(tree)

	# the way home
	var home := Grove.Signpost.new()
	home.dir = 1.0
	home.destination = "home"
	home.position = Vector2(HOME_SIGN_X, GROUND_Y)
	add_child(home)
	interactables.append(home)

	var stall_game := Grove.GameSpot.new()
	stall_game.game = "stall"
	stall_game.position = Vector2(762.0, GROUND_Y - 300.0)
	add_child(stall_game)
	interactables.append(stall_game)

	for spec in STALLS:
		var stall := Stall.new()
		stall.spec = spec
		stall.position = Vector2(spec["x"], GROUND_Y)
		stall.z_index = 2
		add_child(stall)
		interactables.append(stall)

	# the traders, walking their patch BEHIND the counters
	# In the GAPS between stalls, not on them. Stalls sit at 400/640/880/1120/
	# 1340/1560 and are 168 wide, so a trader wandering freely spent half the
	# time hidden behind one. Small patches keep them where she can see them.
	spawn_folk("market", [520.0, 1000.0, 1450.0], 1, 34.0, 26.0)

	# her bike, so the whole land is two taps from anywhere
	var bike := Nature.Bike.new()
	bike.position = Vector2(300.0, GROUND_Y)
	add_child(bike)
	interactables.append(bike)

	setup_player(arrival_x({"home": HOME_SIGN_X + 90.0, "bike": 640.0}, 220.0))


# --- world queries the player relies on -------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if ui_layer != null or trading:
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
		if best is Stall:
			# remember which half of the counter she reached for
			(best as Stall).aim = wp
		if absf(best.global_position.x - player.position.x) > 140.0:
			player.target_x = best.global_position.x - 60.0 * signf(
				best.global_position.x - player.position.x)
			await _walk_until_near(best.global_position.x, 150.0)
		_interact(best)
		return

	var now := Time.get_ticks_msec() / 1000.0
	if now - last_tap_t < 0.4 and wp.distance_to(last_tap_pos) < 170.0:
		player.try_jump(wp)
		last_tap_t = -10.0
		return
	last_tap_t = now
	last_tap_pos = wp
	player.target_x = wp.x


func _walk_until_near(x: float, dist: float) -> void:
	var waited := 0.0
	while absf(player.position.x - x) > dist and waited < 4.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
		if not is_inside_tree():
			return


func _interact(node: Node2D) -> void:
	player.face_toward(node.global_position.x)
	if node is Grove.Signpost:
		node.point()
		go_home()
	elif node is Grove.GameSpot:
		open_game(StallGame.new())
	elif node is Nature.Bike:
		open_bike_map(node)
	elif node is Folk.Person:
		talk_to(node)
	elif node is Stall:
		_trade(node)


## Trade at a stall. Which way depends on which button she reached for: BUY
## swaps fruit for goods, SELL hands goods back for fruit (one less than the
## buy price). If she has not got what a trade needs, the stall gives a
## friendly wobble and shows what is missing — never a refusal, never a
## dead end, and nothing from the museum is ever spendable.
func _trade(stall: Stall) -> void:
	if trading:
		return
	var spec: Dictionary = stall.spec
	var kind := str(spec["gives"])
	var n: int = int(spec["n"])
	var buy: int = int(spec["fruit"])
	var sell := sell_price(buy)
	var selling := stall.aimed_at_sell()

	if selling:
		# handing goods back over the counter
		if int(GameState.materials.get(kind, 0)) < n:
			stall.wiggle()
			Sound.pop()
			stall.flash_need("goods")
			return
		trading = true
		GameState.add_material(kind, -n)
		GameState.add_fruit(sell)
	else:
		if GameState.fruit < buy:
			stall.wiggle()
			Sound.pop()
			stall.flash_need("fruit")
			Fx.float_number(self, stall.position + Vector2(0, -190.0), buy)
			return
		trading = true
		GameState.add_fruit(-buy)
		GameState.add_material(kind, n)

	player.reach(stall.global_position + Vector2(0, -130.0))
	Sound.grab_sound()
	hud.bump_fruit()
	hud.bump_materials()
	Fx.sparkles(self, stall.position + Vector2(0, -150.0), 8, Color("ffe6b3"))
	Sound.chime_find()
	stall.celebrate()
	GameState.save_game()
	await get_tree().create_timer(0.5).timeout
	trading = false


## One market stall: a banner saying what it sells, a striped awning, the goods
## on the counter, and two buttons — BUY on the left, SELL on the right. Both
## show their price in apples, so the numbers can be counted rather than read.
class Stall extends Node2D:
	var spec: Dictionary = {}
	## Where on the stall she last reached. The two buttons sit either side of
	## the counter, so this decides whether she is buying or selling.
	var aim := Vector2.ZERO
	var _t := 0.0
	var _pop := 0.0
	var _need := ""
	var _need_t := 0.0

	const BUY_AT := Vector2(-36, -34)
	const SELL_AT := Vector2(36, -34)
	const BTN := Vector2(64, 44)

	func _ready() -> void:
		_t = randf() * 5.0

	func tap_score(wp: Vector2) -> float:
		return clampf(1.0 - (wp - global_position - Vector2(0, -96.0)).length() / 150.0, 0.0, 1.0)

	func try_tap(_wp: Vector2) -> bool:
		return true

	## True when the tap landed on the SELL half. The buy button is the default,
	## so a vague tap anywhere on the stall buys — which is what she means
	## nearly every time.
	func aimed_at_sell() -> bool:
		var local := aim - global_position
		return Rect2(SELL_AT - BTN * 0.5, BTN).grow(14.0).has_point(local)

	func _process(delta: float) -> void:
		_t += delta
		if _pop > 0.0:
			_pop = maxf(0.0, _pop - delta * 2.0)
		if _need_t > 0.0:
			_need_t = maxf(0.0, _need_t - delta * 0.7)
		queue_redraw()

	func wiggle() -> void:
		var tw := create_tween()
		for i in 2:
			tw.tween_property(self, "rotation", 0.05, 0.07)
			tw.tween_property(self, "rotation", -0.05, 0.07)
		tw.tween_property(self, "rotation", 0.0, 0.06)

	## Show what the trade was short of, rather than just refusing.
	func flash_need(what: String) -> void:
		_need = what
		_need_t = 1.0

	func celebrate() -> void:
		_pop = 1.0

	func _draw() -> void:
		var wood := Color("a97e54")
		var awning := Color(str(spec.get("awning", "c96b64")))
		DrawKit.soft_shadow(self, Vector2(0, 2), 78.0, 0.15)
		# posts
		for sx in [-70.0, 70.0]:
			draw_line(Vector2(sx, 0), Vector2(sx, -168), wood.darkened(0.22), 8.0)
			draw_line(Vector2(sx - 2.5, 0), Vector2(sx - 2.5, -168), wood.darkened(0.34), 2.5)
		# counter
		DrawKit.rounded_rect(self, Rect2(-78, -74, 156, 16), 4.0, wood)
		draw_rect(Rect2(-78, -74, 156, 5), wood.lightened(0.12))
		# the cloth hanging down the front of the counter, which is what the buy
		# and sell buttons are pinned to
		DrawKit.rounded_rect(self, Rect2(-72, -62, 144, 56), 6.0, awning.lightened(0.34))
		for i in 6:
			draw_line(Vector2(-64.0 + i * 25.0, -58), Vector2(-64.0 + i * 25.0, -8),
				Color(1, 1, 1, 0.28), 5.0)
		draw_rect(Rect2(-72, -62, 144, 7), awning)
		DrawKit.rounded_rect(self, Rect2(-64, -58, 128, 10), 3.0, wood.darkened(0.18))
		# striped awning with a scalloped edge
		draw_rect(Rect2(-84, -186, 168, 26), Color("f4ead6"))
		for i in 7:
			draw_rect(Rect2(-84 + i * 24, -186, 12, 26), awning)
		for i in 8:
			draw_circle(Vector2(-78 + i * 21.5, -160), 10.5, Color("f4ead6") if i % 2 == 0 else awning)
		draw_line(Vector2(-84, -186), Vector2(84, -186), wood.darkened(0.2), 5.0)

		_draw_banner(awning)
		# the goods on the counter
		var bounce := sin(_pop * PI) * 5.0
		_draw_goods(Vector2(0, -80 - bounce))
		_draw_buttons()

	## The banner over the awning, saying what this stall sells. Hung on two
	## little cords so it reads as cloth, not a label stuck on the screen.
	func _draw_banner(awning: Color) -> void:
		var word := str(spec.get("word", ""))
		var font := ThemeDB.fallback_font
		var w := maxf(120.0, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x + 44.0)
		var sway := sin(_t * 1.3) * 1.5
		var r := Rect2(-w * 0.5, -246 + sway, w, 44)
		for sx in [-1.0, 1.0]:
			draw_line(Vector2(sx * w * 0.42, r.end.y), Vector2(sx * 62.0, -190.0),
				Color("8a7355"), 2.0)
		DrawKit.rounded_rect(self, Rect2(r.position + Vector2(0, 4), r.size), 10.0,
			Color(0, 0, 0, 0.10))
		DrawKit.rounded_rect(self, r, 10.0, Color("fff8ec"))
		DrawKit.rounded_rect_outline(self, r, 10.0, awning, 3.0)
		var tw := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		draw_string(font, Vector2(-tw * 0.5, r.position.y + 32.0), word,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("6b4f38"))

	## BUY and SELL, side by side under the counter, each with its price in
	## apples. Green means she can do it right now; pale means not yet.
	func _draw_buttons() -> void:
		var font := ThemeDB.fallback_font
		var kind := str(spec.get("gives", "timber"))
		var n: int = int(spec.get("n", 1))
		var buy: int = int(spec.get("fruit", 3))
		var sell := int(maxi(0, buy - 1))
		var can_buy := GameState.fruit >= buy
		var can_sell := int(GameState.materials.get(kind, 0)) >= n

		for side in 2:
			var at: Vector2 = BUY_AT if side == 0 else SELL_AT
			var live: bool = can_buy if side == 0 else can_sell
			var label := ("buy %d" % n if n > 1 else "buy") if side == 0 else "sell"
			var price: int = buy if side == 0 else sell
			var glow := 0.0
			if _need_t > 0.0 and ((side == 0 and _need == "fruit") or (side == 1 and _need == "goods")):
				glow = _need_t
			var r := Rect2(at - BTN * 0.5, BTN)
			DrawKit.rounded_rect(self, Rect2(r.position + Vector2(0, 3), r.size), 12.0,
				Color(0, 0, 0, 0.12))
			var face := Color("a8d5a2") if live else Color("e6dcc6")
			if glow > 0.0:
				face = face.lerp(Color("f0b8a8"), glow)
			DrawKit.rounded_rect(self, r, 12.0, face)
			var lw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
			draw_string(font, Vector2(at.x - lw * 0.5, at.y - 4.0), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
				Color("36552f") if live else Color("9c8f78"))
			# the price, as that many apples — countable, no reading needed
			for i in mini(price, 4):
				var ax := at.x - (mini(price, 4) - 1) * 6.5 + i * 13.0
				draw_circle(Vector2(ax, at.y + 12.0), 5.2,
					Color("e05c50") if live else Color("cdc3ac"))
			if price == 0:
				draw_string(font, Vector2(at.x - 5.0, at.y + 18.0), "0",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("9c8f78"))
			if price > 4:
				draw_string(font, Vector2(at.x + 26.0, at.y + 18.0), "+",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("9c8f78"))

	func _draw_goods(p: Vector2) -> void:
		match str(spec.get("gives", "timber")):
			"timber":
				for i in 3:
					draw_rect(Rect2(p.x - 22, p.y - i * 11.0, 44, 10), Color("a87c4e"))
					draw_rect(Rect2(p.x - 22, p.y - i * 11.0, 44, 3), Color("bb8f5e"))
			"paint":
				var cols := [Color("e8918c"), Color("6fb3d2"), Color("8fc48a")]
				for i in 3:
					var px := p.x - 22.0 + i * 22.0
					DrawKit.rounded_rect(self, Rect2(px - 10, p.y - 20, 20, 20), 2.0, Color("b8b0a0"))
					draw_rect(Rect2(px - 8, p.y - 18, 16, 6), cols[i])
					draw_arc(Vector2(px, p.y - 20), 9.0, PI, TAU, 8, Color("8a95a0"), 2.0, true)
			"plank":
				for i in 3:
					draw_rect(Rect2(p.x - 24, p.y - i * 9.0, 48, 8), Color("c9a06c"))
					draw_rect(Rect2(p.x - 24, p.y - i * 9.0, 48, 2.5), Color("d9b485"))
			"rope":
				for i in 2:
					draw_arc(Vector2(p.x, p.y - 10 - i * 17.0), 14.0, 0, TAU, 20, Color("9a8055"), 6.0, true)
					draw_arc(Vector2(p.x, p.y - 10 - i * 17.0), 14.0, PI * 0.9, PI * 1.6, 8,
						Color("b39a6d"), 2.4, true)
			"seed":
				# paper packets with a flower on the front
				for i in 3:
					var sx := p.x - 20.0 + i * 20.0
					DrawKit.rounded_rect(self, Rect2(sx - 9, p.y - 26, 18, 26), 2.0, Color("efe3c8"))
					draw_rect(Rect2(sx - 9, p.y - 26, 18, 5), Color("d8c9a4"))
					draw_circle(Vector2(sx, p.y - 13), 4.5,
						[Color("e8918c"), Color("ffd98a"), Color("c4b8e8")][i])
					draw_circle(Vector2(sx, p.y - 13), 1.8, Color("fff8ec"))
			_:
				# a pie tin and a roll of pastry
				DrawKit.ellipse(self, Vector2(p.x, p.y - 6), 24.0, 9.0, Color("b8b0a0"))
				DrawKit.ellipse(self, Vector2(p.x, p.y - 9), 19.0, 6.5, Color("cdc6b6"))
				DrawKit.rounded_rect(self, Rect2(p.x - 14, p.y - 30, 28, 14), 5.0, Color("e8c88a"))

