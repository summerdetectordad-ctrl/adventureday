extends Node2D
## The meadow. Summer walks, the detector hums and rises near buried finds,
## she digs, and carries treasures home to the treehouse museum.
## No fail state: nothing chases, nothing runs out, nothing is timed.

const WORLD_W := 4200.0
const GROUND_Y := 600.0
const DOOR_X := 250.0
const BURIED_COUNT := 6
const DIG_RANGE := 80.0
const TONE_RANGE := 520.0

var player: Player
var hud: Hud
var buried: Array = []      # {x, kind, sparkle}
var digging := false
var pending_enter := false
var interactables: Array = []


func _ready() -> void:
	# sky behind everything, fixed to the screen
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -1
	add_child(sky_layer)
	sky_layer.add_child(Nature.SkyBackdrop.new())

	var bg := Nature.WorldBG.new()
	bg.world_w = WORLD_W
	bg.ground_y = GROUND_Y
	add_child(bg)

	for tree_x in [950.0, 3100.0, 3950.0]:
		var tree := Nature.MeadowTree.new()
		tree.position = Vector2(tree_x, GROUND_Y)
		tree.tint = randf_range(0.0, 0.08)
		add_child(tree)

	var treehouse := Nature.Treehouse.new()
	treehouse.position = Vector2(DOOR_X, GROUND_Y)
	add_child(treehouse)
	set_meta("treehouse", treehouse)

	var bike := Nature.Bike.new()
	bike.position = Vector2(430.0, GROUND_Y)
	add_child(bike)
	interactables.append(bike)

	for bush_x in [1150.0, 2200.0, 3450.0]:
		var bush := Nature.BerryBush.new()
		bush.position = Vector2(bush_x, GROUND_Y)
		add_child(bush)
		interactables.append(bush)

	var pond := Nature.Pond.new()
	pond.position = Vector2(2750.0, GROUND_Y + 8.0)
	add_child(pond)
	interactables.append(pond)

	var bird_tree := Nature.BirdTree.new()
	bird_tree.position = Vector2(1750.0, GROUND_Y)
	add_child(bird_tree)
	interactables.append(bird_tree)

	var picnic := Nature.PicnicBlanket.new()
	picnic.position = Vector2(3720.0, GROUND_Y)
	add_child(picnic)
	interactables.append(picnic)

	player = Player.new()
	player.position = Vector2(DOOR_X + 90.0 if GameState.spawn_at_door else 340.0, GROUND_Y)
	GameState.spawn_at_door = false

	# Indy and Star trot along behind (added before Summer so she draws in front)
	var indy := Nature.Dog.new()
	indy.kind = "indy"
	indy.trail = 115.0
	indy.position = player.position + Vector2(-115, 0)
	add_child(indy)
	interactables.append(indy)

	var star := Nature.Dog.new()
	star.kind = "star"
	star.trail = 195.0
	star.scale = Vector2(1.15, 1.15)   # Star is a bit bigger than Indy
	star.position = player.position + Vector2(-195, 0)
	add_child(star)
	interactables.append(star)

	add_child(player)
	indy.follow = player
	star.follow = player

	var cam := Camera2D.new()
	cam.position = Vector2(0, -200)
	cam.limit_left = 0
	cam.limit_right = int(WORLD_W)
	cam.limit_top = 0
	cam.limit_bottom = 800
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 4.0
	player.add_child(cam)
	cam.make_current()

	hud = Hud.new("world")
	hud.dig_pressed.connect(_try_dig)
	hud.door_pressed.connect(_enter_museum)
	add_child(hud)

	for i in BURIED_COUNT:
		_spawn_buried()

	Sound.detector_active = true

	if not GameState.start_card_shown:
		GameState.start_card_shown = true
		await get_tree().create_timer(1.4).timeout
		AffirmationCard.show_card(hud, Affirm.next())


func _exit_tree() -> void:
	Sound.detector_active = false


func _process(_delta: float) -> void:
	var nd := 1.0e9
	for b in buried:
		var d: float = absf(b["x"] - player.position.x)
		b["sparkle"].modulate.a = clampf(1.0 - d / 240.0, 0.0, 1.0) * 0.9
		nd = minf(nd, d)
	Sound.detector_active = not digging
	Sound.detector_strength = clampf(1.0 - nd / TONE_RANGE, 0.0, 1.0)

	var near_door := absf(player.position.x - DOOR_X) < 170.0
	hud.set_dig_visible(nd < DIG_RANGE and not digging)
	hud.set_door_visible(near_door and not digging)

	if pending_enter and not player.walking and absf(player.position.x - DOOR_X) < 60.0:
		pending_enter = false
		_enter_museum()


func _unhandled_input(event: InputEvent) -> void:
	if digging:
		return
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		var wp := get_global_mouse_position()
		for node in interactables:
			if node.try_tap(wp):
				return
		var treehouse: Nature.Treehouse = get_meta("treehouse")
		if treehouse.door_rect().has_point(wp):
			pending_enter = true
			player.target_x = DOOR_X + 40.0
			return
		pending_enter = false
		player.target_x = clampf(wp.x, 60.0, WORLD_W - 60.0)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_E:
			if absf(player.position.x - DOOR_X) < 170.0:
				_enter_museum()
			else:
				_try_dig()


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
	for attempt in 60:
		var x := randf_range(650.0, WORLD_W - 150.0)
		var ok := absf(x - player.position.x) > 220.0 if player else true
		for b in buried:
			if absf(b["x"] - x) < 260.0:
				ok = false
				break
		if ok:
			var sparkle := Nature.HintSparkle.new()
			sparkle.position = Vector2(x, GROUND_Y - 12.0)
			sparkle.modulate.a = 0.0
			add_child(sparkle)
			buried.append({"x": x, "kind": GameState.random_find_type(), "sparkle": sparkle})
			return


func _try_dig() -> void:
	if digging:
		return
	var b := _nearest_buried()
	if b.is_empty() or absf(b["x"] - player.position.x) > DIG_RANGE:
		return
	digging = true
	player.target_x = player.position.x
	Sound.dig_sound()

	var spot := Vector2(b["x"], GROUND_Y + 4.0)
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
