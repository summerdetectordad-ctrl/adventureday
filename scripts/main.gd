extends Zone
## The meadow. Summer walks, jumps (double-tap), swims across the pond,
## clambers over blocks, swings and launches from vines, and carries a whole
## backpack of things: the metal detector, a butterfly net, a camera, a
## whistle that calls the dogs, a water bottle, a sketch pad, a map and a
## picnic. Tapping something far away walks her over to it first; animals
## get a polite little chat (and can have their photo taken).
## No fail state: nothing chases, nothing runs out, nothing is timed.

const WORLD_W := 4200.0
const DOOR_X := 420.0
## The home grove. The first stretch of the world is almost entirely about the
## treehouse — this is where a session starts and ends.
const TREE2_X := 1020.0
const TREE3_X := 1300.0
const SIGN_WEST_X := 92.0
const SIGN_EAST_X := 4150.0
const FRUIT_TREE_X := [1700.0, 2600.0, 3560.0]
const GROVE_END_X := 1500.0   # the meadow proper begins here
const BURIED_COUNT := 6
const DIG_RANGE := 80.0
const TONE_RANGE := 520.0
const POND_X := 2750.0
const WATER_HALF_W := 165.0
const DOUBLE_TAP_TIME := 0.4
const DOUBLE_TAP_DIST := 170.0
const REACH := 120.0          # close enough to use/collect/chat
const ARM_STOP := 56.0        # walking to something, she stops this far short
const MATERIAL_COUNT := 4     # building bits lying around at any one time
const MATERIAL_KINDS := {"stick": 3, "plank": 3, "rope": 2}


var buried: Array = []      # {x, kind, sparkle}
var digging := false
var pending_enter := false
var pending_interact := {}  # {node, wp} — walking over to something tapped
var material_nodes: Array = []   # Nature.MaterialPickup lying about
var plan_table: PlanTable
var stock_pile: StockPile
var trees: Dictionary = {}       # site -> Treehouse ("home" / "two" / "three")
var bridges: Array = []          # Grove.RopeBridge, rebuilt when one is built
var fruit_trees: Array = []      # Grove.FruitTree
var stones: Grove.SteppingStones = null
var garden: Grove.GardenPatch = null
var puddles: Array = []          # Grove.Puddle — splashable, no rain needed
var rung_t := 0.0
var was_on_ground := true
var roof_cat: Grove.RoofCat = null
var telescope: Grove.Telescope = null
var ride_spots: Array = []       # Grove.RideSpot — ladder, lift, slide, zip
var tree_decks: Array = []       # Rect2 walkable surfaces up in the trees
var session_t := 0.0
var step_t := 0.0
var cat_t := 60.0
var fireflies_out := false
var last_milestone := 0
var building := false


## Where the dogs trot home to when the whistle sends them off.
class DogHome extends Node2D:
	var facing := -1


func _ready() -> void:
	zone_name = "meadow"
	# at home she carries everything, detector and net included
	pack_items = Backpack.ITEMS
	setup_ground(WORLD_W)

	for tree_x in [3100.0, 3950.0]:
		var tree := Nature.MeadowTree.new()
		tree.position = Vector2(tree_x, GROUND_Y)
		tree.tint = randf_range(0.0, 0.08)
		add_child(tree)

	# --- the home grove: three trees she builds across ----------------------
	# The second and third stand visibly empty from the very first session.
	# She can see them long before she can reach them, and that is the point.
	for spec in [["home", DOOR_X], ["two", TREE2_X], ["three", TREE3_X]]:
		var tree := Treehouse.new()
		tree.site = spec[0]
		tree.position = Vector2(spec[1], GROUND_Y)
		add_child(tree)
		trees[spec[0]] = tree
	set_meta("treehouse", trees["home"])

	# the bridges only exist once she has built them
	_refresh_bridges()
	_refresh_telescope()
	_refresh_rides()

	# signposts: the market one way, the adventure lands the other
	var west := Grove.Signpost.new()
	west.dir = -1.0
	west.destination = "market"
	west.position = Vector2(SIGN_WEST_X, GROUND_Y)
	add_child(west)
	interactables.append(west)

	var east := Grove.Signpost.new()
	east.dir = 1.0
	east.destination = "dino"
	east.position = Vector2(SIGN_EAST_X, GROUND_Y)
	add_child(east)
	interactables.append(east)

	# fruit trees to shake, the market's currency growing on branches
	for i in FRUIT_TREE_X.size():
		var ft := Grove.FruitTree.new()
		ft.seed_v = 11 + i * 7
		ft.position = Vector2(FRUIT_TREE_X[i], GROUND_Y)
		add_child(ft)
		interactables.append(ft)
		fruit_trees.append(ft)

	garden = Grove.GardenPatch.new()
	garden.position = Vector2(1430.0, GROUND_Y)
	add_child(garden)
	interactables.append(garden)

	# Pattern Patch, planted at the end of the garden row
	var patch_game := Grove.GameSpot.new()
	patch_game.game = "pattern"
	patch_game.position = Vector2(1548.0, GROUND_Y - 96.0)
	add_child(patch_game)
	interactables.append(patch_game)

	# the plan table: where materials become building. Tapping it opens the
	# board; the plan pinned to it shows what she could make next.
	plan_table = PlanTable.new()
	plan_table.position = Vector2(660.0, GROUND_Y)
	add_child(plan_table)
	interactables.append(plan_table)

	# the stock pile: everything she has gathered, in a heap she can see
	stock_pile = StockPile.new()
	stock_pile.position = Vector2(780.0, GROUND_Y)
	add_child(stock_pile)
	interactables.append(stock_pile)

	# the village children, out playing in the meadow
	spawn_folk("meadow", [1780.0, 2320.0, 3340.0])

	# a wise little owl on the middle meadow tree
	var owl := Nature.Owl.new()
	owl.position = Vector2(3152.0, GROUND_Y - 170.0)
	add_child(owl)
	interactables.append(owl)

	var bike := Nature.Bike.new()
	bike.position = Vector2(1150.0, GROUND_Y)
	add_child(bike)
	interactables.append(bike)

	for bush_x in [1620.0, 2200.0, 3450.0]:
		var bush := Nature.BerryBush.new()
		bush.position = Vector2(bush_x, GROUND_Y)
		add_child(bush)
		interactables.append(bush)

	var pond := Nature.Pond.new()
	pond.position = Vector2(POND_X, GROUND_Y + 8.0)
	add_child(pond)
	interactables.append(pond)

	# flat stones across the pond — she can hop over instead of swimming
	stones = Grove.SteppingStones.new()
	stones.position = Vector2(POND_X, GROUND_Y + 2.0)
	stones.span = WATER_HALF_W * 1.9
	add_child(stones)

	# puddles near the pond and along the damp end of the meadow
	for px in [2380.0, 2560.0, 3020.0, 3180.0]:
		var pud := Grove.Puddle.new()
		pud.w = randf_range(58.0, 92.0)
		pud.position = Vector2(px, GROUND_Y + 2.0)
		add_child(pud)
		puddles.append(pud)

	var bird_tree := Nature.BirdTree.new()
	bird_tree.position = Vector2(1900.0, GROUND_Y)
	add_child(bird_tree)
	interactables.append(bird_tree)

	var picnic := Nature.PicnicBlanket.new()
	picnic.position = Vector2(3720.0, GROUND_Y)
	add_child(picnic)
	interactables.append(picnic)

	# blocks to jump over and stand on
	for spec in [
		["log", 1560.0, 116.0, 54.0],
		["crate", 2050.0, 120.0, 72.0],
		["rock", 2450.0, 132.0, 58.0],
		["crate", 3270.0, 120.0, 72.0],
	]:
		var blk := Nature.Block.new()
		blk.kind = spec[0]
		blk.position = Vector2(spec[1], GROUND_Y)
		blk.w = spec[2]
		blk.h = spec[3]
		add_child(blk)
		blocks.append(blk)

	# lookout perches — reachable by vine launch or a hop from a block
	for px in [Vector2(2250.0, 450.0), Vector2(3000.0, 445.0)]:
		var plat := Nature.Platform.new()
		plat.position = px
		add_child(plat)
		platforms.append(plat)

	# vines hanging from the canopies, grabbable mid-jump
	for spec in [[Vector2(1120.0, 356.0), 128.0], [Vector2(1480.0, 300.0), 150.0],
			[Vector2(3135.0, 356.0), 128.0]]:
		var v := Nature.Vine.new()
		v.position = spec[0]
		v.length = spec[1]
		add_child(v)
		vines.append(v)

	# butterflies dancing over the flowers
	for bx in [1180.0, 1620.0, 2350.0, 2920.0, 3600.0]:
		var fl := Nature.Butterfly.new()
		fl.position = Vector2(bx, GROUND_Y - 130.0 - randf_range(0.0, 40.0))
		add_child(fl)
		interactables.append(fl)

	# Back at the right gate: coming home from the market she appears by the
	# west sign she left through, and from Dino Land by the east one — not
	# dumped back at the treehouse every time.
	var start_x := arrival_x({
		"market": SIGN_WEST_X + 76.0,
		"dino": SIGN_EAST_X - 76.0,
		"cove": SIGN_EAST_X - 76.0,
		"bike": DOOR_X + 150.0,
	}, 340.0)
	if GameState.spawn_at_door:
		start_x = DOOR_X + 90.0
	GameState.spawn_at_door = false
	setup_player(start_x)

	# the dig button is the one control only the meadow has
	hud.dig_pressed.connect(_try_dig)

	for i in BURIED_COUNT:
		_spawn_buried()
	for i in MATERIAL_COUNT:
		_spawn_material()

	if not GameState.start_card_shown:
		GameState.start_card_shown = true
		await get_tree().create_timer(1.4).timeout
		AffirmationCard.show_card(hud, Affirm.next())


func _exit_tree() -> void:
	Sound.detector_active = false


## --- world queries the player relies on -----------------------------------

## Over the pond — unless she is up on the stepping stones, which keep her dry.
func in_water(x: float) -> bool:
	if absf(x - POND_X) >= WATER_HALF_W:
		return false
	if stones != null and player != null and not player.swimming \
			and player.position.y <= GROUND_Y + 6.0 and stones.covers(x):
		return false
	return true


func water_surface_y() -> float:
	return GROUND_Y + 26.0


## Floor under feet at x: the ground, a block top, or a lookout perch —
## whichever is highest that her feet are above.
func floor_y_at(x: float, feet_y: float) -> float:
	var fy := GROUND_Y
	for blk in blocks:
		var r: Rect2 = blk.rect()
		if x >= r.position.x - 6.0 and x <= r.end.x + 6.0 \
				and feet_y <= r.position.y + 12.0:
			fy = minf(fy, r.position.y)
	for plat in platforms:
		var r: Rect2 = plat.rect()
		if x >= r.position.x and x <= r.end.x and feet_y <= r.position.y + 12.0:
			fy = minf(fy, r.position.y)
	for r in tree_decks:
		if x >= r.position.x and x <= r.end.x and feet_y <= r.position.y + 12.0:
			fy = minf(fy, r.position.y)
	if stones != null:
		var sr := stones.walk_rect()
		if x >= sr.position.x and x <= sr.end.x and feet_y <= sr.position.y + 12.0:
			fy = minf(fy, sr.position.y)
	return fy


## Stop a walk (or airborne drift) at block sides and the world edges.
## Perches are one-way — they never block her.
func clamp_walk(from_x: float, to_x: float, feet_y: float) -> float:
	to_x = clampf(to_x, 40.0, WORLD_W - 40.0)
	for blk in blocks:
		var r: Rect2 = blk.rect()
		if feet_y > r.position.y + 12.0:
			if from_x <= r.position.x and to_x > r.position.x - 14.0:
				to_x = r.position.x - 14.0
			elif from_x >= r.end.x and to_x < r.end.x + 14.0:
				to_x = r.end.x + 14.0
	return to_x


func vine_near(hand: Vector2) -> Node2D:
	for v in vines:
		if v.near(hand):
			return v
	return null


## ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	# the meters, the bubbles and the backpack are the shell's job
	super(delta)
	var detecting: bool = player.held_tool == "detector" and player.on_ground \
		and player.position.y >= GROUND_Y - 1.0 \
		and not player.swimming and not player.climbing and not digging \
		and ui_layer == null
	var nd := 1.0e9
	for b in buried:
		var d: float = absf(b["x"] - player.position.x)
		b["sparkle"].modulate.a = (clampf(1.0 - d / 240.0, 0.0, 1.0) * 0.9) if detecting else 0.0
		nd = minf(nd, d)
	Sound.detector_active = detecting
	Sound.detector_strength = clampf(1.0 - nd / TONE_RANGE, 0.0, 1.0)

	if pack != null:
		pack.position = player.position
		pack.held_tool = player.held_tool
		if not player.on_ground or player.swimming \
				or Time.get_ticks_msec() / 1000.0 - pack_open_t > 8.0:
			close_pack()

	# Gentle nudges when she's been adventuring a long while. These NEVER
	# punish — the only thing an empty meter does is float a friendly bubble.
	GameState.thirst_accum += delta
	GameState.hunger_accum += delta
	if GameState.thirst_accum > TopBar.THIRST_SECONDS and thirst_bubble == null \
			and ui_layer == null:
		thirst_bubble = Nature.ThirstBubble.new()
		thirst_bubble.z_index = 25
		add_child(thirst_bubble)
	if thirst_bubble != null:
		thirst_bubble.position = player.position + Vector2(52.0 * player.facing, -122.0)
	if GameState.hunger_accum > TopBar.HUNGER_SECONDS and hunger_bubble == null \
			and ui_layer == null:
		hunger_bubble = Nature.HungerBubble.new()
		hunger_bubble.z_index = 25
		add_child(hunger_bubble)
	if hunger_bubble != null:
		hunger_bubble.position = player.position + Vector2(-52.0 * player.facing, -122.0)

	_ambience(delta)

	hud.set_dig_visible(nd < DIG_RANGE and detecting)

	# arriving at something she tapped from far away: she stops at arm's
	# length first, THEN reaches — never standing on top of it
	if not pending_interact.is_empty() and player.on_ground and not player.swimming \
			and not player.walking:
		var wpp: Vector2 = pending_interact["wp"]
		if absf(player.position.x - wpp.x) < REACH + 20.0:
			var todo: Dictionary = pending_interact
			pending_interact = {}
			_interact(todo["node"], todo["wp"])
		elif absf(player.position.x - player.target_x) < 6.0:
			pending_interact = {}   # truly stopped short of it — let it go
		# otherwise she just hasn't set off yet — keep waiting

	if pending_enter and not player.walking and player.on_ground \
			and absf(player.position.x - DOOR_X) < 60.0:
		pending_enter = false
		_enter_museum()


func _unhandled_input(event: InputEvent) -> void:
	if digging or ui_layer != null:
		return
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		var wp := get_global_mouse_position()
		var now := Time.get_ticks_msec() / 1000.0
		var is_double := now - last_tap_t < DOUBLE_TAP_TIME \
			and wp.distance_to(last_tap_pos) < DOUBLE_TAP_DIST

		# hanging on a vine: side taps pump the swing, up/down taps shimmy,
		# a double-tap launches her off toward the tap
		if player.climbing:
			if is_double:
				last_tap_t = -10.0
				player.try_jump(wp)
			else:
				last_tap_t = now
				last_tap_pos = wp
				player.climb_toward(wp)
			return

		# the counters, the backpack ring and the drink/snack bubbles — all
		# handled once, in the shell, for every world
		if handle_tap(event.position, wp):
			return

		# Weighted hitboxes: every candidate scores by how CENTRAL the tap is
		# (1.0 dead-on, fading to 0 at the hitbox edge). Where hitboxes overlap,
		# the thing she was actually aiming for wins.
		#
		# Summer herself is NOT a target any more. Tapping her used to open the
		# backpack, which meant every tap near her opened a menu instead of
		# letting her walk. The backpack has its own button now.
		var best_node: Node2D = null
		var best_score := 0.0
		for node in interactables:
			var sc: float = node.tap_score(wp)
			if sc > best_score:
				best_score = sc
				best_node = node
		if best_score > 0.0:
			last_tap_t = -10.0
			pending_enter = false
			if absf(wp.x - player.position.x) < REACH:
				pending_interact = {}
				_interact(best_node, wp)
			else:
				# walk over, but stop at arm's length so she isn't standing
				# on top of it (and blocking the things around it)
				pending_interact = {"node": best_node, "wp": wp}
				var stop_x := wp.x - ARM_STOP * signf(wp.x - player.position.x)
				player.target_x = clampf(stop_x, 60.0, WORLD_W - 60.0)
			return

		var treehouse: Treehouse = get_meta("treehouse")
		if treehouse.door_rect().has_point(wp):
			pending_enter = true
			pending_interact = {}
			player.target_x = DOOR_X + 40.0
			return

		if is_double:
			last_tap_t = -10.0
			pending_interact = {}
			player.try_jump(wp)
			return
		last_tap_t = now
		last_tap_pos = wp
		pending_enter = false
		pending_interact = {}
		player.target_x = clampf(wp.x, 60.0, WORLD_W - 60.0)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_E:
			if player.climbing:
				player.let_go()
			elif absf(player.position.x - DOOR_X) < 170.0:
				_enter_museum()
			else:
				_try_dig()
		elif event.keycode == KEY_UP or event.keycode == KEY_W:
			if player.climbing:
				player.climb_toward(player.position + Vector2(0, -200.0))
			else:
				player.try_jump(player.position + Vector2(0, -220.0))
		elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
			if player.climbing:
				player.climb_toward(player.position + Vector2(0, 50.0))


func use_item(id: String) -> void:
	match id:
		"detector", "net":
			player.held_tool = "" if player.held_tool == id else id
			GameState.held_tool = player.held_tool
			# only one thing in her hands at a time, so the shutter goes with it
			hud.set_camera_out(false)
			if player.held_tool == id:
				Sound.grab_sound()
			else:
				Sound.pop()
			Fx.sparkles(self, player.position + Vector2(0, -60.0), 5, Color("ffe6b3"))
		"camera":
			toggle_camera()
		"whistle":
			whistle()
		"bottle":
			sip()
		"sketchpad":
			open_ui(DrawingSuite.new())
		"map":
			var mv := MapView.new()
			mv.world_node = self
			open_ui(mv)
		"picnic":
			open_picnic()


func whistle() -> void:
	Sound.whistle()
	if not GameState.dogs_here:
		# the best surprise: here come Indy and Star!
		GameState.dogs_here = true
		await get_tree().create_timer(0.9).timeout
		if not is_inside_tree():
			return
		spawn_dogs(true)
		Sound.woof()
	else:
		GameState.dogs_here = false
		var home := DogHome.new()
		home.position = Vector2(-600.0, GROUND_Y)
		add_child(home)
		var leaving := dogs.duplicate()
		dogs.clear()
		for d in leaving:
			interactables.erase(d)
			d.follow = home
		Sound.woof()
		get_tree().create_timer(5.0).timeout.connect(func() -> void:
			for d in leaving:
				if is_instance_valid(d):
					d.queue_free()
			if is_instance_valid(home):
				home.queue_free())


func _interact(node: Node2D, wp: Vector2) -> void:
	player.face_toward(node.global_position.x)
	if node is Nature.Bike:
		open_bike_map(node)
	elif node is Folk.Person:
		talk_to(node)
	elif node is Nature.Dog:
		node.try_tap(wp)
		_chat("indy" if node.kind == "indy" else "star", node)
	elif node is Nature.BirdTree:
		node.try_tap(wp)
		_chat("bird", node)
	elif node is Nature.Pond:
		var f: Nature.Frog = node.frog_at(wp)
		if f != null:
			f.hop()
			_chat("frog", f)
		else:
			node.try_tap(wp)
	elif node is Nature.Butterfly:
		if player.held_tool == "net":
			Sound.swish()
			player.swipe()
			node.get_caught(player.position + Vector2(38.0 * player.facing, -88.0), self)
		else:
			node.try_tap(wp)
			_chat("butterfly", node)
	elif node is Nature.Owl:
		node.try_tap(wp)
		_chat("owl", node)
	elif node is Nature.MaterialPickup:
		_collect_material(node, wp)
	elif node is PlanTable:
		_open_build_board()
	elif node is StockPile:
		player.reach(wp)
		node.count_out()
	elif node is Grove.Signpost:
		node.point()
		_travel_to(node.destination)
	elif node is Grove.FruitTree:
		_shake_fruit_tree(node)
	elif node is Grove.FallenFruit:
		player.reach(wp)
		_pick_fruit(node)
	elif node is Grove.GameSpot:
		open_game(PatternGame.new())
	elif node is Grove.GardenPatch:
		_tend_garden(node)
	elif node is Grove.RideSpot:
		_start_ride(node)
	elif node is Grove.Telescope:
		var view := Grove.FarView.new()
		view.place = "dino"
		open_ui(view)
	elif node is Grove.RoofCat:
		Sound.pop()
		Fx.hearts(self, node.global_position + Vector2(0, -30.0), 2)
	elif node is Nature.PicnicBlanket:
		node.try_tap(wp)
		open_picnic()
	else:
		# berries, the bike bell — a clear reach-and-grab toward the tap
		player.reach(wp)
		var got: bool = node.try_tap(wp)
		if got and node is Nature.BerryBush:
			# the fruit counter pops, so she sees where the berry went
			hud.bump_fruit()


## Meeting one of the meadow animals. The shell decides whether that means
## learning something or taking its picture — it depends on whether the camera
## is in her hand.
func _chat(who: String, target: Node2D) -> void:
	meet_animal(who, target)


## --- building the treehouse --------------------------------------------------

## Somewhere along the ground to put the next thing. Both spawners used to
## throw darts at the strip and give up after 60 misses, which quietly left
## her with five finds instead of six — and got worse as the treehouse filled
## the ground with blocks. This walks the strip instead: the pond and the
## blocks are hard no, everything else is a preference, and it hands back the
## roomiest spot it can find. Only genuinely nowhere returns -1.
func _open_spot(lo: float, hi: float, taken: Array, want_gap: float,
		block_pad: float, player_gap: float) -> float:
	var best: Array = []
	var best_score := -1.0
	var x := lo
	while x <= hi:
		var legal := absf(x - POND_X) > WATER_HALF_W + block_pad - 20.0
		if legal:
			for blk in blocks:
				if absf(x - blk.position.x) < blk.w * 0.5 + block_pad:
					legal = false
					break
		if legal:
			# elbow room from its neighbours, and from wherever she is standing
			var score := want_gap
			for t in taken:
				score = minf(score, absf(float(t) - x))
			if player_gap > 0.0 and player != null:
				score = minf(score, minf(player_gap, absf(player.position.x - x)))
			if score > best_score + 0.5:
				best_score = score
				best = [x]
			elif score > best_score - 0.5:
				best.append(x)
		x += 24.0
	if best.is_empty():
		return -1.0
	return float(best[randi() % best.size()])


func _spawn_material() -> void:
	var taken: Array = []
	for m in material_nodes:
		taken.append(m.position.x)
	var x := _open_spot(GROVE_END_X, WORLD_W - 140.0, taken, 240.0, 70.0, 0.0)
	if x < 0.0:
		return
	var kind := _random_material_kind()
	var pickup := Nature.MaterialPickup.new()
	pickup.kind = kind
	pickup.position = Vector2(x, GROUND_Y)
	add_child(pickup)
	material_nodes.append(pickup)
	interactables.append(pickup)


func _random_material_kind() -> String:
	var total := 0
	for w in MATERIAL_KINDS.values():
		total += w
	var r := randi() % total
	for kind in MATERIAL_KINDS:
		r -= MATERIAL_KINDS[kind]
		if r < 0:
			return kind
	return "stick"


func _collect_material(node: Nature.MaterialPickup, wp: Vector2) -> void:
	player.reach(wp)
	Sound.grab_sound()
	GameState.add_material(node.kind)
	stock_pile.queue_redraw()
	Fx.sparkles(self, node.global_position + Vector2(0, -14.0), 5, Color("d9b485"))
	interactables.erase(node)
	material_nodes.erase(node)
	# the found bit flies home and lands on the pile
	node.z_index = 20
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_interval(0.25)
	var kind: String = node.kind
	tw.tween_property(node, "position", stock_pile.position + Vector2(50.0, -40.0), 0.55)
	tw.parallel().tween_property(node, "scale", Vector2(0.3, 0.3), 0.55)
	tw.tween_callback(func() -> void:
		node.queue_free()
		Sound.pop()
		# it lands on the pile, and the pile visibly grows
		stock_pile.landed(kind)
		plan_table.refresh()
		hud.bump_materials())
	# another bit turns up somewhere else after a little while
	get_tree().create_timer(randf_range(12.0, 25.0)).timeout.connect(func() -> void:
		if is_inside_tree() and material_nodes.size() < MATERIAL_COUNT:
			_spawn_material())


## Open the plan board. Nothing is spent here — she picks, and only then does
## Summer walk over and build it.
func _open_build_board() -> void:
	if building or ui_layer != null:
		return
	# back to whichever tree she was working on — building three things on tree
	# two should not throw her home between each one
	var board := BuildBoard.new()
	board.start_site = GameState.last_build_site
	if not board.visible_sites_now().has(board.start_site):
		board.start_site = "home"
	board.build_chosen.connect(_do_build)
	board.upgrade_chosen.connect(_do_upgrade)
	open_ui(board)


## Build one part: she walks over, hammers, and the pieces fly up from the
## stock pile and snap into place one at a time. Never instant — watching it
## happen is the reward.
func _do_build(id: String) -> void:
	if building:
		return
	var cost := BuildDefs.cost_of(id)
	if not GameState.can_afford(cost):
		plan_table.wiggle()
		return
	building = true
	# committed the moment she chooses, so quitting mid-animation loses nothing
	GameState.build_part(id)
	if id == "painted_door" and not GameState.paint_colours.has(id):
		# a cheerful colour, chosen for her — she can repaint it any time
		GameState.paint_colours[id] = BuildBoard.PAINTS[randi() % BuildBoard.PAINTS.size()]

	var site := BuildDefs.site_of(id)
	var tree: Treehouse = trees.get("home" if site == "ground" else site, null)
	if tree == null:
		building = false
		return
	var target: Vector2 = tree.position + BuildDefs.spot_of(id)

	player.target_x = player.position.x
	player.face_toward(target.x)
	player.build(target.x)
	stock_pile.queue_redraw()

	# pieces fly from the pile to the spot, a knock each as they land
	var pieces := 0
	for k in cost:
		pieces += int(cost[k])
	pieces = clampi(pieces, 3, 6)
	for i in pieces:
		var delay := 0.22 + i * 0.24
		get_tree().create_timer(delay).timeout.connect(func() -> void:
			if not is_inside_tree():
				return
			_fly_piece(stock_pile.position + Vector2(50, -40), target)
			Sound.knock())

	await get_tree().create_timer(0.3 + pieces * 0.24 + 0.5).timeout
	if not is_inside_tree():
		building = false
		return

	tree.refresh()
	plan_table.refresh()
	stock_pile.queue_redraw()
	Fx.sparkles(self, target, 12, Color("ffe6b3"))
	Fx.dirt(self, target + Vector2(0, 14), 5)
	Sound.chime_shelf()
	_after_build(id)
	building = false
	# straight back to the same tree, so a run of parts on tree two is one
	# flow rather than a re-pan after every single piece
	_reopen_board()


## Back to the plan board on whichever tree she was building, once the
## hammering is over. Skipped if she has wandered into something else in the
## meantime — an open picnic or a photo card always wins.
func _reopen_board() -> void:
	await get_tree().create_timer(0.7).timeout
	if not is_inside_tree() or building or ui_layer != null:
		return
	_open_build_board()


## Raise a part to a better material — same shape, better wood, or her colour.
func _do_upgrade(id: String, colour: String) -> void:
	if building:
		return
	if not GameState.can_afford(GameState.upgrade_cost(id)):
		plan_table.wiggle()
		return
	building = true
	var site := BuildDefs.site_of(id)
	var tree: Treehouse = trees.get("home" if site == "ground" else site, null)
	var target: Vector2 = (tree.position if tree else player.position) + BuildDefs.spot_of(id)
	player.target_x = player.position.x
	player.face_toward(target.x)
	player.build(target.x)
	for d in [0.25, 0.55]:
		get_tree().create_timer(d).timeout.connect(Sound.knock)
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		building = false
		return
	GameState.upgrade_part(id, colour)
	if tree != null:
		tree.refresh()
	plan_table.refresh()
	stock_pile.queue_redraw()
	Fx.sparkles(self, target, 10, Color("ffe6b3"))
	Sound.chime_shelf()
	building = false
	_reopen_board()


## The small living details: footprints behind her, fireflies once she has been
## playing a long while, and a cat that turns up on the roof now and then.
## None of it asks anything of her — it just makes the meadow feel lived in.
func _ambience(delta: float) -> void:
	session_t += delta

	# rungs lighting up under her as she climbs the ladder
	if player.riding and player.ride_pose == "ladder":
		rung_t -= delta
		if rung_t <= 0.0:
			rung_t = 0.22
			Fx.sparkles(self, player.position + Vector2(0, -6.0), 2, Color("ffe6b3"))
	else:
		rung_t = 0.0

	# splashing through puddles
	for pud in puddles:
		if pud.stepped_in(player.position.x, player.position.y, GROUND_Y) \
				and not player.swimming:
			Sound.splash()
			Fx.sparkles(self, player.position + Vector2(0, -10.0), 5, Color("a9d7e8"))

	# the welcome mat squeaks when she lands on it
	var landed := player.on_ground and not was_on_ground
	was_on_ground = player.on_ground
	if landed and GameState.has_built("welcome_mat") \
			and absf(player.position.x - DOOR_X) < 34.0 \
			and absf(player.position.y - GROUND_Y) < 8.0:
		Sound.bell()
		Fx.hearts(self, player.position + Vector2(0, -50.0), 1)

	# footprints in the dirt, fading
	if player.on_ground and not player.swimming and player.walking:
		step_t -= delta
		if step_t <= 0.0:
			step_t = 0.34
			var f := Grove.Footstep.new()
			f.position = player.position + Vector2(-6.0 * player.facing, -2.0)
			f.fx = float(player.facing)
			add_child(f)

	# fireflies come out after a long session — a quiet reward for staying
	if not fireflies_out and session_t > 420.0:
		fireflies_out = true
		for i in 9:
			var fly := Grove.Firefly.new()
			fly.position = Vector2(randf_range(GROVE_END_X, WORLD_W - 200.0),
				GROUND_Y - randf_range(60.0, 240.0))
			add_child(fly)

	# the cat visits the roof once the cabin is up
	cat_t -= delta
	if cat_t <= 0.0:
		cat_t = randf_range(70.0, 150.0)
		if roof_cat == null and GameState.has_built("cabin"):
			roof_cat = Grove.RoofCat.new()
			var top: float = trees["home"]._top()
			roof_cat.position = Vector2(DOOR_X - 46.0, GROUND_Y + top - 62.0)
			add_child(roof_cat)
			interactables.append(roof_cat)
			get_tree().create_timer(randf_range(30.0, 60.0)).timeout.connect(func() -> void:
				if is_instance_valid(roof_cat):
					interactables.erase(roof_cat)
					roof_cat.queue_free()
				roof_cat = null)


## The meadow celebrates every tenth find. Called by the shell whenever
## something new joins the collection.
func on_collected() -> void:
	_check_milestone()


## A gentle celebration at every tenth find on the shelf. Never exclusive,
## never missable — it just happens, and then she carries on.
func _check_milestone() -> void:
	var n := GameState.shelf.size() + GameState.satchel.size()
	if n > 0 and n % 10 == 0 and n != last_milestone:
		last_milestone = n
		for i in 22:
			var p := player.position + Vector2(randf_range(-160.0, 160.0), -randf_range(40.0, 220.0))
			Fx.sparkles(self, p, 2, [Color("ffd98a"), Color("f2b8cf"), Color("a9c9e8"),
				Color("c4b8e8"), Color("8fc48a")][i % 5])
		Sound.chime_shelf()
		AffirmationCard.show_card(hud, Affirm.next())


## A game handing something back. Games always give something — never nothing.
func take_reward(kind: String, n: int) -> void:
	if kind.begins_with("find:"):
		for i in n:
			GameState.add_to_satchel(kind.substr(5))
		hud.bounce_satchel()
		_check_milestone()
	elif kind == "fruit":
		GameState.add_fruit(n)
		hud.bump_fruit()
	else:
		GameState.add_material(kind, n)
		hud.bump_materials()
		stock_pile.queue_redraw()
		plan_table.refresh()


## She walks to the picnic blanket, sits down on the grass and eats what she
## made — three bites, crumbs, and a wiggle in between. If the dogs are out,
## one of them gets the last bite.
func sit_and_eat(stack: Array) -> void:
	if stack.is_empty():
		return
	var blanket_x := 3720.0
	for n in interactables:
		if n is Nature.PicnicBlanket:
			blanket_x = n.position.x
			break
	# only walk over if she is somewhere near it — otherwise she sits where she is
	if absf(player.position.x - blanket_x) < 900.0:
		player.target_x = blanket_x - 60.0
		var waited := 0.0
		while absf(player.position.x - (blanket_x - 60.0)) > 24.0 and waited < 4.0:
			await get_tree().process_frame
			waited += get_process_delta_time()
			if not is_inside_tree():
				return
	player.face_toward(player.position.x + 40.0)
	var seconds := 4.4
	player.sit_and_eat(stack, seconds)

	var bites := 3
	for i in bites:
		get_tree().create_timer(0.9 + i * 1.1).timeout.connect(func() -> void:
			if not is_inside_tree():
				return
			Sound.munch()
			Fx.dirt(self, player.position + Vector2(18.0 * player.facing, -46.0), 3))

	await get_tree().create_timer(seconds).timeout
	if not is_inside_tree():
		return
	# a full tummy, and the meter refills
	GameState.hunger_accum = 0.0
	GameState.save_game()
	if hunger_bubble != null:
		hunger_bubble.queue_free()
		hunger_bubble = null
	Fx.hearts(self, player.position + Vector2(0, -80.0), 4)
	Sound.chime_find()
	# the dogs always want the last bite
	for d in dogs:
		if absf(d.position.x - player.position.x) < 260.0:
			Sound.woof()
			Fx.hearts(self, d.position + Vector2(0, -60.0), 2)
			break
	AffirmationCard.show_card(hud, Affirm.next())


## Off through a signpost to somewhere else. Everything is saved first, so
## travelling is always safe.
func _travel_to(destination: String) -> void:
	if building or ui_layer != null:
		return
	match destination:
		"market":
			travel_to("res://scenes/market.tscn", "home")
		"dino":
			travel_to("res://scenes/dino_land.tscn", "home")
		"cove":
			travel_to("res://scenes/pirate_cove.tscn", "home")


## Put the rope bridges in place for whatever she has built. Each one is a
## one-way floor, like the lookout perches — it can never block her.
func _refresh_bridges() -> void:
	for b in bridges:
		platforms.erase(b)
		b.queue_free()
	bridges.clear()
	# The bridge appears as soon as she builds it, even though the far tree is
	# still bare — walking over to an empty tree is the invitation to build it.
	var specs := []
	if GameState.has_built("bridge2"):
		specs.append([DOOR_X + 88.0, TREE2_X - 60.0])
	if GameState.has_built("bridge3"):
		specs.append([TREE2_X + 60.0, TREE3_X - 64.0])
	for s in specs:
		var br := Grove.RopeBridge.new()
		br.from_x = s[0]
		br.to_x = s[1]
		br.deck_y = GROUND_Y - 262.0
		br.walker = player
		br.position = Vector2(s[0], GROUND_Y - 262.0)
		add_child(br)
		bridges.append(br)
		platforms.append(br)


## The decks she can actually stand on, and the ways up and down. Rebuilt
## whenever she builds something, so the treehouse becomes a place to BE as
## soon as it exists rather than scenery to look at.
func _refresh_rides() -> void:
	for s in ride_spots:
		interactables.erase(s)
		s.queue_free()
	ride_spots.clear()
	tree_decks.clear()

	var deck_y := GROUND_Y - 262.0
	# the home platform, plus its decks once they are built
	tree_decks.append(Rect2(DOOR_X - 88.0, deck_y, 176.0, 10.0))
	if GameState.has_built("deck_front"):
		tree_decks.append(Rect2(DOOR_X + 58.0, deck_y, 66.0, 10.0))
	if GameState.has_built("deck_side"):
		tree_decks.append(Rect2(DOOR_X - 124.0, deck_y, 66.0, 10.0))
	if GameState.has_built("tree2_platform"):
		tree_decks.append(Rect2(TREE2_X - 74.0, deck_y, 148.0, 10.0))
	if GameState.has_built("tree3_platform"):
		tree_decks.append(Rect2(TREE3_X - 78.0, deck_y, 156.0, 10.0))

	# There is always a way up, so the platform is always reachable. The marker
	# sits at the MIDDLE OF WHATEVER SHE CLIMBS — the rope ladder, the stairs
	# or the spiral — so it can never drift off the thing it belongs to. It is
	# well above the museum door: the door and the climb are different things.
	var climb := _climb_path()
	_add_ride("ladder", climb[climb.size() / 2])
	if GameState.has_built("lift_bucket"):
		_add_ride("lift", Vector2(DOOR_X - 104.0, GROUND_Y - 172.0))
	if GameState.has_built("slide"):
		_add_ride("slide", Vector2(DOOR_X + 128.0, deck_y - 30.0))
	if GameState.has_built("zipline") and GameState.has_built("crows_nest"):
		_add_ride("zip", Vector2(TREE2_X + 30.0, GROUND_Y - 420.0))


func _add_ride(kind: String, at: Vector2) -> void:
	var spot := Grove.RideSpot.new()
	spot.kind = kind
	spot.position = at
	add_child(spot)
	ride_spots.append(spot)
	interactables.append(spot)


## The route up the home tree, following whichever way up she has actually
## built. Treehouse._draw_access picks one of these three to draw; this must
## stay in step with it or the marker ends up floating beside thin air.
func _climb_path() -> PackedVector2Array:
	var deck_y := GROUND_Y - 262.0
	if GameState.has_built("stairs_wood") and not GameState.has_built("stairs_spiral"):
		# the wooden flight climbs diagonally from the left
		var p := PackedVector2Array()
		for i in 6:
			var u := i / 5.0
			p.append(Vector2(DOOR_X + lerpf(-96.0, -14.0, u),
				GROUND_Y + lerpf(-6.0, -252.0, u)))
		p.append(Vector2(DOOR_X - 14.0, deck_y))
		return p
	# the rope ladder and the spiral both run straight up the trunk
	return PackedVector2Array([Vector2(DOOR_X, GROUND_Y), Vector2(DOOR_X, deck_y)])


## Get on. The ladder and the lift carry her up (or back down if she is already
## up); the slide and the zip line only ever go down, which is the fun bit.
func _start_ride(spot: Grove.RideSpot) -> void:
	if player.riding or building:
		return
	var deck_y := GROUND_Y - 262.0
	var up := player.position.y > deck_y + 40.0
	var path := PackedVector2Array()
	var secs := 1.6
	var pose := spot.kind

	match spot.kind:
		"ladder":
			path = _climb_path()
			secs = 1.8
			if not up:
				# coming back down the same way, in reverse
				var back := PackedVector2Array()
				for i in range(path.size() - 1, -1, -1):
					back.append(path[i])
				path = back
				secs = 1.2
		"lift":
			var x := DOOR_X - 104.0
			path = PackedVector2Array([Vector2(x, GROUND_Y), Vector2(x, deck_y)])
			secs = 2.2
			if not up:
				path = PackedVector2Array([Vector2(x, deck_y), Vector2(x, GROUND_Y)])
		"slide":
			if up:
				# she needs to be up top to go down it — walk her to the ladder
				_start_ride_from(_spot_of_kind("ladder"))
				return
			for i in 13:
				var u := i / 12.0
				path.append(Vector2(lerpf(DOOR_X + 122.0, DOOR_X + 214.0, u),
					lerpf(deck_y + 8.0, GROUND_Y, u * u * 0.82 + u * 0.18)))
			secs = 1.5
		"zip":
			if up:
				return
			for i in 11:
				var u := i / 10.0
				path.append(Vector2(lerpf(TREE2_X + 30.0, TREE2_X + 300.0, u),
					lerpf(GROUND_Y - 420.0, GROUND_Y - 150.0, u)))
			secs = 1.9

	if path.size() < 2:
		return
	# walk her to the start first, so she never teleports
	player.target_x = path[0].x
	var waited := 0.0
	while absf(player.position.x - path[0].x) > 26.0 and waited < 2.5:
		await get_tree().process_frame
		waited += get_process_delta_time()
		if not is_inside_tree():
			return
	Sound.swish()
	player.ride(path, secs, pose)


func _spot_of_kind(kind: String) -> Grove.RideSpot:
	for s in ride_spots:
		if s.kind == kind:
			return s
	return null


func _start_ride_from(spot: Grove.RideSpot) -> void:
	if spot != null:
		_start_ride(spot)


## The telescope only exists once she has built it, up on the tower.
func _refresh_telescope() -> void:
	if telescope != null:
		interactables.erase(telescope)
		telescope.queue_free()
		telescope = null
	if not GameState.has_built("telescope"):
		return
	telescope = Grove.Telescope.new()
	telescope.position = Vector2(DOOR_X, GROUND_Y) + BuildDefs.spot_of("telescope")
	add_child(telescope)
	interactables.append(telescope)


## Sow a seed, or pick a grown patch. Tapping it always does the most useful
## thing, so there is nothing to get wrong.
func _tend_garden(patch: Grove.GardenPatch) -> void:
	player.reach(patch.global_position + Vector2(0, -20.0))
	if patch.ready_to_pick():
		var n := patch.pick()
		hud.bump_fruit()
		Fx.float_number(self, patch.position + Vector2(0, -80.0), n)
		Fx.sparkles(self, patch.position + Vector2(0, -50.0), 10, Color("ffe6b3"))
		Sound.chime_find()
		AffirmationCard.show_card(hud, Affirm.next())
		return
	if patch.sow():
		hud.bump_materials()
		Fx.dirt(self, patch.position + Vector2(0, -10.0), 5)
		Sound.dig_sound()
		return
	# no seeds yet, or the patch is full — a friendly nothing
	Fx.hearts(self, patch.position + Vector2(0, -50.0), 1)
	Sound.pop()


## Shake a fruit tree — fruit drops and bounces on the grass.
func _shake_fruit_tree(tree: Grove.FruitTree) -> void:
	player.reach(tree.global_position + Vector2(0, -120.0))
	var n := tree.shake()
	Sound.swish()
	if n <= 0:
		return
	for i in n:
		var f := Grove.FallenFruit.new()
		f.position = tree.position + Vector2(randf_range(-40.0, 40.0), -180.0)
		add_child(f)
		interactables.append(f)
		var land := Vector2(f.position.x + randf_range(-30.0, 30.0), GROUND_Y - 4.0)
		var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(f, "position", land, 0.42)
		tw.tween_property(f, "position", land + Vector2(6, -16), 0.14)
		tw.tween_property(f, "position", land, 0.12)
		tw.tween_callback(Sound.pop)


## Pick a fallen fruit up. Fruit is the market's currency, and it regrows —
## so trading can never cost her anything she cannot get back.
func _pick_fruit(node: Node2D) -> void:
	interactables.erase(node)
	node.z_index = 20
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(node, "position", player.position + Vector2(0, -70.0), 0.35)
	tw.parallel().tween_property(node, "scale", Vector2(0.3, 0.3), 0.35)
	tw.tween_callback(func() -> void:
		node.queue_free()
		GameState.add_fruit(1)
		GameState.hunger_accum = maxf(0.0, GameState.hunger_accum - 40.0)
		hud.bump_fruit()
		Sound.pop())


## A single plank sailing up to the tree.
func _fly_piece(from: Vector2, to: Vector2) -> void:
	var piece := Nature.MaterialPickup.new()
	piece.kind = ["plank", "stick", "rope"][randi() % 3]
	piece.position = from
	piece.z_index = 22
	piece.scale = Vector2(0.7, 0.7)
	add_child(piece)
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(piece, "position", to + Vector2(randf_range(-14, 14), randf_range(-10, 6)), 0.42)
	tw.parallel().tween_property(piece, "rotation", randf_range(-2.0, 2.0), 0.42)
	tw.parallel().tween_property(piece, "scale", Vector2(0.25, 0.25), 0.42)
	tw.tween_callback(piece.queue_free)


## The little ceremony after a build lands: a photo for the museum wall, and
## an affirmation. New rooms get announced too.
func _after_build(id: String) -> void:
	AffirmationCard.show_card(hud, Affirm.next())
	# a snapshot of the treehouse as it now stands, straight into the satchel
	var kind := "photo_treehouse_%d" % (GameState.built.size() % 10)
	GameState.add_to_satchel(kind)
	hud.bounce_satchel()
	if id == "bridge2" or id == "bridge3":
		_refresh_bridges()
	if id == "telescope":
		_refresh_telescope()
	_refresh_rides()


## --- digging ----------------------------------------------------------------

func _nearest_buried() -> Dictionary:
	var best := {}
	var nd := 1.0e9
	for b in buried:
		var d: float = absf(b["x"] - player.position.x)
		if d < nd:
			nd = d
			best = b
	return best


func _spawn_buried() -> void:
	# Nothing buried under the pond or under a block, spread out from the other
	# finds, and not right under her feet — but there is always something in
	# the ground to look for.
	var taken: Array = []
	for b in buried:
		taken.append(b["x"])
	var x := _open_spot(GROVE_END_X, WORLD_W - 150.0, taken, 260.0, 90.0, 220.0)
	if x < 0.0:
		return
	var sparkle := Nature.HintSparkle.new()
	sparkle.position = Vector2(x, GROUND_Y - 12.0)
	sparkle.modulate.a = 0.0
	add_child(sparkle)
	buried.append({"x": x, "kind": GameState.random_find_type(), "sparkle": sparkle})


func _try_dig() -> void:
	if digging or player.held_tool != "detector" or not player.on_ground \
			or player.swimming or player.climbing or ui_layer != null:
		return
	var b := _nearest_buried()
	if b.is_empty() or absf(b["x"] - player.position.x) > DIG_RANGE:
		return
	digging = true
	player.target_x = player.position.x
	player.face_toward(b["x"])
	player.start_dig()
	Sound.dig_sound()

	var spot := Vector2(b["x"], GROUND_Y + 4.0)
	# proper scoops: little bursts of earth as the trowel works
	Fx.dirt(self, spot)
	for d in [0.35, 0.7]:
		get_tree().create_timer(d).timeout.connect(func() -> void:
			if is_inside_tree():
				Fx.dirt(self, spot, 5))
	var hole := Nature.Hole.new()
	hole.position = spot
	hole.scale = Vector2(0.2, 0.2)
	add_child(hole)
	create_tween().tween_property(hole, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var item := FindIcon.new(b["kind"], 30.0)
	item.position = spot + Vector2(0, 8)
	item.scale = Vector2(0.1, 0.1)
	item.z_index = 10
	add_child(item)

	await get_tree().create_timer(0.4).timeout
	var rise := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	rise.tween_property(item, "position", spot + Vector2(0, -95.0), 0.6)
	rise.parallel().tween_property(item, "scale", Vector2(1.3, 1.3), 0.6)
	await rise.finished

	Sound.chime_find()
	Fx.sparkles(self, item.position)
	await get_tree().create_timer(0.75).timeout

	var stow := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	stow.tween_property(item, "position", player.position + Vector2(0, -70.0), 0.4)
	stow.parallel().tween_property(item, "scale", Vector2(0.2, 0.2), 0.4)
	await stow.finished
	item.queue_free()

	GameState.add_to_satchel(b["kind"])
	hud.bounce_satchel()
	Sound.pop()

	var fade := create_tween()
	fade.tween_property(hole, "modulate:a", 0.0, 4.0)
	fade.tween_callback(hole.queue_free)

	b["sparkle"].queue_free()
	buried.erase(b)
	_spawn_buried()
	digging = false


func _enter_museum() -> void:
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/museum.tscn")
