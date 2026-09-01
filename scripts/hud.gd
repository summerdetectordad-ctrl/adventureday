class_name Hud
extends CanvasLayer
## On-screen buttons — icons only, big targets. The world HUD shows the
## satchel, mute, the counters and a contextual dig button; the museum HUD just
## mute. The museum door is tapped in the world itself, not from here.

signal dig_pressed
## The basket (what she is carrying) and the backpack (what she can use) are
## two different things, and now have a button each.
signal satchel_pressed
signal pack_pressed
## Snap a picture of wherever she is standing. Only shown while the camera is
## actually in her hand — the rest of the time there is nothing to press.
signal shutter_pressed

var mode := "world"
var mute_btn: IconButton
var satchel_btn: IconButton
var pack_btn: IconButton
var dig_btn: IconButton
var top_bar: TopBar = null
var reading_btn: IconButton = null
var shutter_btn: IconButton = null


func _init(m := "world") -> void:
	mode = m


func _ready() -> void:
	mute_btn = IconButton.new("mute", 84.0)
	mute_btn.pressed.connect(_on_mute)
	add_child(mute_btn)
	if mode == "world":
		satchel_btn = IconButton.new("satchel", 96.0)
		satchel_btn.pressed.connect(func() -> void: satchel_pressed.emit())
		add_child(satchel_btn)
		# the backpack lives under the basket. Tapping SUMMER no longer opens it —
		# that got in the way of simply walking about.
		pack_btn = IconButton.new("backpack", 88.0)
		pack_btn.pressed.connect(func() -> void: pack_pressed.emit())
		add_child(pack_btn)
		dig_btn = IconButton.new("dig", 130.0)
		dig_btn.visible = false
		dig_btn.pressed.connect(func() -> void: dig_pressed.emit())
		add_child(dig_btn)
		# how much reading the mini-games use. Parent-set, three steps, and it
		# only ever changes the WORDING of a game, never what she can do.
		shutter_btn = IconButton.new("shutter", 108.0)
		shutter_btn.pressed.connect(func() -> void: shutter_pressed.emit())
		shutter_btn.visible = false
		add_child(shutter_btn)
		reading_btn = IconButton.new("reading", 64.0)
		reading_btn.pressed.connect(_cycle_reading)
		add_child(reading_btn)
		# the counters across the top: fruit, materials, thirst, hunger
		top_bar = TopBar.new()
		add_child(top_bar)
		move_child(top_bar, 0)
	_layout()
	get_viewport().size_changed.connect(_layout)


func _layout() -> void:
	var vs := get_viewport().get_visible_rect().size
	mute_btn.position = Vector2(vs.x - 108, 24)
	if mode == "world":
		satchel_btn.position = Vector2(24, 24)
		pack_btn.position = Vector2(28, 132)
		# bottom-right, well clear of the counters — this is a parent-set control,
		# not something she needs while playing
		reading_btn.position = Vector2(vs.x - 96, vs.y - 96)
		if shutter_btn != null:
			shutter_btn.position = Vector2(vs.x - 148, vs.y - 226)
		dig_btn.position = Vector2(vs.x / 2.0 - 65, vs.y - 170)


## Cycle pictures → words → sentences. Nothing can break: it only changes how
## wordy the mini-games are.
func _cycle_reading() -> void:
	GameState.reading_level = (GameState.reading_level + 1) % 3
	GameState.save_game()
	reading_btn.queue_redraw()
	Sound.pop()


func _on_mute() -> void:
	GameState.toggle_mute()
	mute_btn.queue_redraw()


func set_dig_visible(v: bool) -> void:
	if dig_btn:
		dig_btn.visible = v


func bump_fruit() -> void:
	if top_bar:
		top_bar.bump_fruit()


func bump_materials() -> void:
	if top_bar:
		top_bar.bump_materials()


## Did this tap land on the materials pill? Lets main.gd give the top bar a
## chance at a tap before the world gets it.
func top_bar_tap(screen_pos: Vector2) -> bool:
	return top_bar != null and top_bar.tap_at(screen_pos)


func bounce_satchel() -> void:
	if satchel_btn == null:
		return
	satchel_btn.queue_redraw()
	satchel_btn.scale = Vector2(1.3, 1.3)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(satchel_btn, "scale", Vector2.ONE, 0.45)


## Show or hide the shutter button. Called whenever what she is holding
## changes, so the button is on screen exactly when the camera is.
func set_camera_out(out: bool) -> void:
	if shutter_btn != null:
		shutter_btn.visible = out
