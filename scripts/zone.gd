class_name Zone
extends Node2D
## Shared behaviour for the places away from home — the market, Dino Land and
## Pirate Cove. They were built as thin scenes and it showed: Summer arrived
## without her backpack, could not have a drink, could not whistle for the dogs
## or take a photo. Everything she carries should come with her.
##
## The meadow (main.gd) is the richer implementation and stays separate — it
## also has digging, vines, blocks and the whole building loop. `_use_item`
## exists in both places; KEEP THEM IN STEP.
##
## A zone extends this, calls `setup_ground()` then places its own scenery,
## then calls `setup_player()`. Its `_unhandled_input` must give `handle_tap()`
## first refusal so the backpack and the bubbles work.

## Everything except the detector and the net: there is nothing buried to
## sweep for and no butterflies to catch away from the meadow, and a tool that
## does nothing is worse than one that is not offered.
const AWAY_ITEMS := ["camera", "whistle", "sketchpad", "map", "bottle", "picnic"]

const GROUND_Y := 600.0

var world_w := 2000.0
var zone_name := "meadow"      ## what a photo taken here is a photo OF
## Which items this world offers. The meadow gives her everything; away from
## home the detector and net are left out.
var pack_items: Array = AWAY_ITEMS
var player: Player
var hud: Hud
var interactables: Array = []
var dogs: Array = []
## The map reads these off whatever world it is given. Away from the meadow
## there is nothing to climb or clamber on, but they must exist or the map
## errors the moment she opens it.
var platforms: Array = []
var vines: Array = []
var blocks: Array = []
var ui_layer: CanvasLayer = null
var busy := false

var pack: Backpack = null
var pack_open_t := 0.0
var thirst_bubble: Nature.ThirstBubble = null
var hunger_bubble: Nature.HungerBubble = null
var last_tap_t := -10.0
var last_tap_pos := Vector2.ZERO


## Sky and ground. Call first.
func setup_ground(w: float, palette := "meadow") -> void:
	world_w = w
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -1
	add_child(sky_layer)
	sky_layer.add_child(Nature.SkyBackdrop.new())

	var bg := Nature.WorldBG.new()
	bg.world_w = w
	bg.ground_y = GROUND_Y
	bg.palette = palette
	add_child(bg)


## Summer, her camera, the colour grade and the HUD. Call last, after the
## scenery, so she stands in front of it.
func setup_player(at_x: float) -> void:
	player = Player.new()
	player.position = Vector2(at_x, GROUND_Y)
	player.world = self
	player.held_tool = GameState.held_tool
	add_child(player)

	if GameState.dogs_here:
		spawn_dogs(false)
	for d in dogs:
		d.follow = player

	var cam := Camera2D.new()
	cam.position = Vector2(0, -200)
	cam.limit_left = 0
	cam.limit_right = int(world_w)
	cam.limit_top = 0
	cam.limit_bottom = 800
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 4.0
	player.add_child(cam)
	cam.make_current()

	add_child(Paint.grade_layer())
	hud = Hud.new("world")
	hud.satchel_pressed.connect(open_satchel)
	hud.pack_pressed.connect(toggle_pack)
	hud.shutter_pressed.connect(snap_here)
	add_child(hud)
	# she may have walked in still holding it
	hud.set_camera_out(player.held_tool == "camera")


# --- world queries the player relies on (flat ground by default) -------------

func in_water(_x: float) -> bool:
	return false


func water_surface_y() -> float:
	return GROUND_Y + 26.0


func floor_y_at(_x: float, _feet_y: float) -> float:
	return GROUND_Y


func clamp_walk(_from_x: float, to_x: float, _feet_y: float) -> float:
	return clampf(to_x, 40.0, world_w - 40.0)


func vine_near(_hand: Vector2) -> Node2D:
	return null


# --- the things she carries --------------------------------------------------

func _process(delta: float) -> void:
	if player == null:
		return
	# the meters keep running wherever she is
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

	if pack != null:
		pack.position = player.position
		pack.held_tool = player.held_tool
		if not player.on_ground \
				or Time.get_ticks_msec() / 1000.0 - pack_open_t > 8.0:
			close_pack()


## First refusal on a tap: the backpack ring, the bubbles, and tapping Summer
## herself. Returns true when the tap has been dealt with.
func handle_tap(screen_pos: Vector2, wp: Vector2) -> bool:
	if hud != null and hud.top_bar_tap(screen_pos):
		return true
	if pack != null:
		var item := pack.item_at(wp)
		close_pack()
		if item != "":
			last_tap_t = -10.0
			use_item(item)
			return true
		if wp.distance_to(player.position + Vector2(0, -45.0)) < 70.0:
			last_tap_t = -10.0
			return true
		return false
	if thirst_bubble != null and thirst_bubble.try_tap(wp):
		last_tap_t = -10.0
		sip()
		return true
	if hunger_bubble != null and hunger_bubble.try_tap(wp):
		last_tap_t = -10.0
		open_picnic()
		return true
	# Summer herself is not a target — the backpack has its own button, so a tap
	# near her is just a tap on the ground and she walks there.
	return false


## Look in the basket, wherever she is.
func open_satchel() -> void:
	if ui_layer != null:
		return
	close_pack()
	open_ui(SatchelView.new())


func toggle_pack() -> void:
	if pack != null:
		close_pack()
		return
	if not player.on_ground or player.riding:
		return
	pack = Backpack.new()
	pack.items = pack_items
	pack.held_tool = player.held_tool
	pack.position = player.position
	pack.z_index = 30
	add_child(pack)
	pack_open_t = Time.get_ticks_msec() / 1000.0
	Sound.pop()


func close_pack() -> void:
	if pack != null:
		pack.queue_free()
		pack = null


func use_item(id: String) -> void:
	match id:
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


func open_ui(ui: CanvasLayer) -> void:
	ui_layer = ui
	close_pack()
	ui.closed.connect(func() -> void:
		ui_layer = null
		ui.queue_free()
		player.set_process(true)
		Sound.pop())
	add_child(ui)
	player.set_process(false)
	Sound.card_sound()


## A real drink: bottle up, head back, two gulps.
func sip() -> void:
	player.target_x = player.position.x
	player.drink()
	Sound.gulp()
	get_tree().create_timer(0.55).timeout.connect(Sound.gulp)
	get_tree().create_timer(1.1).timeout.connect(func() -> void:
		if is_inside_tree() and player != null:
			Fx.sparkles(self, player.position + Vector2(8.0 * player.facing, -78.0), 4,
				Color("a9d7e8")))
	GameState.thirst_accum = 0.0
	GameState.save_game()
	if thirst_bubble != null:
		thirst_bubble.queue_free()
		thirst_bubble = null


## The picnic, wherever she is. Its Eat button hands the sandwich back so she
## sits down on the spot and eats it.
func open_picnic() -> void:
	var game := SandwichGame.new()
	game.eat_now.connect(sit_and_eat)
	open_ui(game)


func sit_and_eat(stack: Array) -> void:
	if stack.is_empty():
		return
	var seconds := 4.4
	player.face_toward(player.position.x + 40.0)
	player.sit_and_eat(stack, seconds)
	for i in 3:
		get_tree().create_timer(0.9 + i * 1.1).timeout.connect(func() -> void:
			if is_inside_tree():
				Sound.munch())
	await get_tree().create_timer(seconds).timeout
	if not is_inside_tree():
		return
	GameState.hunger_accum = 0.0
	GameState.save_game()
	if hunger_bubble != null:
		hunger_bubble.queue_free()
		hunger_bubble = null
	Fx.hearts(self, player.position + Vector2(0, -80.0), 4)
	Sound.chime_find()
	AffirmationCard.show_card(hud, Affirm.next())


## The whistle brings Indy and Star running, wherever she is.
func whistle() -> void:
	Sound.whistle()
	if not GameState.dogs_here:
		GameState.dogs_here = true
		await get_tree().create_timer(0.9).timeout
		if not is_inside_tree():
			return
		spawn_dogs(true)
		Sound.woof()
	else:
		GameState.dogs_here = false
		for d in dogs:
			interactables.erase(d)
			var tw := create_tween()
			tw.tween_property(d, "position:x", -200.0, 2.2)
			tw.tween_callback(d.queue_free)
		dogs.clear()
		Sound.woof()


func spawn_dogs(surprise: bool) -> void:
	var base_x := player.position.x if player else 240.0
	for spec in [["indy", 115.0, 1.0], ["star", 195.0, 1.15]]:
		var d := Nature.Dog.new()
		d.kind = spec[0]
		d.trail = spec[1]
		d.scale = Vector2(spec[2], spec[2])
		d.position = Vector2(base_x - (900.0 if surprise else float(spec[1])), GROUND_Y)
		d.follow = player
		add_child(d)
		interactables.append(d)
		dogs.append(d)


## Snap a photo of where she is. The picture pops up big, then goes in the
## satchel like every other find.
func take_photo(subject: String, at: Vector2) -> void:
	player.face_toward(at.x)
	player.hold_camera()
	Sound.shutter()
	var kind := "photo_%s_%d" % [subject, randi() % 10]
	Fx.sparkles(self, at, 6, Color("ffe6b3"))
	await get_tree().create_timer(0.55).timeout
	if not is_inside_tree():
		return
	var card := PhotoCard.new()
	card.kind = kind
	card.word = subject
	card.closed.connect(func() -> void:
		GameState.add_to_satchel(kind)
		hud.bounce_satchel()
		on_collected()
		Sound.pop())
	open_ui(card)


## Open one of the mini-games. It gets its own screen with a big exit button,
## and whatever she earns comes straight back here.
func open_game(game: MiniGame) -> void:
	game.rewarded.connect(take_reward)
	open_ui(game)


## A game handing something back: a material, fruit, or a find for the museum.
## Games always give something — never nothing.
func take_reward(kind: String, n: int) -> void:
	if kind.begins_with("find:"):
		for i in n:
			GameState.add_to_satchel(kind.substr(5))
		if hud != null:
			hud.bounce_satchel()
	elif kind == "fruit":
		GameState.add_fruit(n)
		if hud != null:
			hud.bump_fruit()
	else:
		GameState.add_material(kind, n)
		if hud != null:
			hud.bump_materials()


## Something new has joined the collection. The meadow uses this to celebrate
## milestones; nowhere else needs to do anything.
func on_collected() -> void:
	pass


## Off home, saving first.
func go_home() -> void:
	travel_to("res://scenes/main.tscn", zone_name)


## Everybody who lives in this world, placed along the ground and left to
## potter about. `z` puts them behind the scenery where that reads better —
## the market traders belong behind their own stalls.
func spawn_folk(where: String, spots: Array, z := 0, depth := 0.0) -> void:
	var ids := Folk.who_lives_in(where)
	for i in mini(ids.size(), spots.size()):
		var p := Folk.Person.new()
		p.id = ids[i]
		p.home_x = float(spots[i])
		p.roam = 110.0
		# `depth` stands them further back: higher up the screen and a little
		# smaller, which is how a trader gets to be behind their counter and
		# still be visible over it
		p.position = Vector2(p.home_x, GROUND_Y - depth)
		if depth > 0.0:
			p.scale = Vector2(0.9, 0.9)
		p.z_index = z
		add_child(p)
		interactables.append(p)


## Say hello to somebody. They stop and face her, and the card offers a TALK
## button rather than a camera — people would rather tell her something than
## be photographed.
func talk_to(person: Folk.Person) -> void:
	person.attend(player.position.x)
	player.face_toward(person.global_position.x)
	player.talk()
	DialogueCard.show_chat(hud, Folk.greeting(person.id), Folk.reply(person.id),
		"tell", Folk.something_to_tell(person.id))


## Take the camera out, or put it away again. Out, it stays in her hand: she
## walks around with it, everything worth photographing becomes tappable, and
## a shutter button appears for a picture of wherever she is. It used to fire
## a photo the instant she touched it in the backpack, which meant she could
## only ever photograph her own feet.
func toggle_camera() -> void:
	if player.held_tool == "camera":
		player.held_tool = ""
	else:
		player.held_tool = "camera"
	GameState.held_tool = player.held_tool
	if hud != null:
		hud.set_camera_out(player.held_tool == "camera")
	Sound.pop()


## Is the camera in her hand right now?
func camera_out() -> bool:
	return player != null and player.held_tool == "camera"


## Meeting an animal. Without the camera she asks it something and learns
## something back — the same as talking to a person. With the camera out she
## politely asks to take its picture instead, and the card's button does it.
func meet_animal(who: String, target: Node2D, subject := "") -> void:
	player.face_toward(target.global_position.x)
	player.talk()
	var subj := subject if subject != "" else who
	if camera_out():
		var card := DialogueCard.show_chat(hud, Critters.greeting(who),
			Critters.reply(who), "camera")
		card.photo_moment.connect(func() -> void:
			if is_instance_valid(target):
				take_photo(subj, target.global_position + Vector2(0, -40.0)))
		return
	DialogueCard.show_chat(hud, Critters.greeting(who), Critters.reply(who),
		"tell", Critters.something_to_tell(who))


## A picture of wherever she is standing — the view, not a creature. This is
## what the shutter button on the HUD does while the camera is out.
func snap_here() -> void:
	if ui_layer != null or busy:
		return
	take_photo(zone_name, player.position + Vector2(60.0 * player.facing, -70.0))


## Off to another world on foot, remembering which way she went so the place
## she arrives at is the edge she walked in through.
func travel_to(scene: String, leaving_as: String) -> void:
	GameState.held_tool = player.held_tool
	GameState.arrive_from = leaving_as
	GameState.save_game()
	Sound.card_sound()
	await get_tree().create_timer(0.45).timeout
	if is_inside_tree():
		get_tree().change_scene_to_file(scene)


## Where to stand on arrival. `doors` maps the world she came from to the x
## she should appear at; anything unlisted falls back to `default`.
func arrival_x(doors: Dictionary, default: float) -> float:
	var from := GameState.arrive_from
	GameState.arrive_from = ""
	return float(doors.get(from, default))


## Tapping the bike: pick a world, then ride there. Every world has one, so
## the whole land is a couple of taps away from anywhere.
func open_bike_map(bike: Node2D) -> void:
	if busy or ui_layer != null:
		return
	var map := BikeMap.new()
	# the meadow is "meadow" as a photo subject but "home" as a destination —
	# translate, or the map never says "you are here" at home
	map.here = "home" if zone_name == "meadow" else zone_name
	map.chosen.connect(func(dest: String) -> void:
		map.closed.emit()
		ride_bike(bike, dest))
	open_ui(map)


## She gets on and pedals off. The bike follows her along the ground, dust
## puffs behind, and when she reaches the edge of the world the next one
## begins. Committed the moment she chooses, so it cannot be interrupted into
## a broken state.
func ride_bike(bike: Node2D, destination: String) -> void:
	if busy:
		return
	busy = true
	close_pack()
	var scene: String = str(BIKE_SCENES.get(destination, ""))
	if scene == "":
		busy = false
		return

	# ride toward whichever edge that world lies in
	var west := destination == "market" \
		or (zone_name == "cove" and destination != "cove") \
		or (zone_name == "dino" and (destination == "home" or destination == "market"))
	var to_x := clampf(player.position.x + (-1400.0 if west else 1400.0), 60.0, world_w - 60.0)
	var seconds := 2.2

	if bike != null and is_instance_valid(bike):
		bike.z_index = 3
	player.face_toward(to_x)
	player.ride(PackedVector2Array([
		Vector2(player.position.x, GROUND_Y), Vector2(to_x, GROUND_Y),
	]), seconds, "bike")
	Sound.bell()

	# the bike stays under her, and she kicks up dust as she goes
	var puff := 0.0
	var elapsed := 0.0
	while elapsed < seconds:
		await get_tree().process_frame
		if not is_inside_tree():
			return
		var d := get_process_delta_time()
		elapsed += d
		if bike != null and is_instance_valid(bike):
			bike.position = Vector2(player.position.x, GROUND_Y)
			bike.scale = Vector2(1.0 if not west else -1.0, 1.0)
		puff -= d
		if puff <= 0.0:
			puff = 0.12
			Fx.dirt(self, player.position + Vector2(0, -4.0), 2)

	GameState.arrive_from = "bike"
	travel_to(scene, "bike")


## Where the bike goes. One list, so a new world is one line here and one
## entry in BikeMap.PLACES.
const BIKE_SCENES := {
	"home": "res://scenes/main.tscn",
	"market": "res://scenes/market.tscn",
	"dino": "res://scenes/dino_land.tscn",
	"cove": "res://scenes/pirate_cove.tscn",
	"cave": "res://scenes/dino_cave.tscn",
}
