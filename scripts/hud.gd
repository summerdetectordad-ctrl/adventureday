class_name Hud
extends CanvasLayer
## On-screen buttons — icons only, big targets. The world HUD shows the
## satchel, mute, and contextual dig/door buttons; the museum HUD just mute.

signal dig_pressed
signal door_pressed

var mode := "world"
var mute_btn: IconButton
var satchel_btn: IconButton
var dig_btn: IconButton
var door_btn: IconButton


func _init(m := "world") -> void:
	mode = m


func _ready() -> void:
	mute_btn = IconButton.new("mute", 84.0)
	mute_btn.pressed.connect(_on_mute)
	add_child(mute_btn)
	if mode == "world":
		satchel_btn = IconButton.new("satchel", 96.0)
		add_child(satchel_btn)
		dig_btn = IconButton.new("dig", 130.0)
		dig_btn.visible = false
		dig_btn.pressed.connect(func() -> void: dig_pressed.emit())
		add_child(dig_btn)
		door_btn = IconButton.new("door", 104.0)
		door_btn.visible = false
		door_btn.pressed.connect(func() -> void: door_pressed.emit())
		add_child(door_btn)
	_layout()
	get_viewport().size_changed.connect(_layout)


func _layout() -> void:
	var vs := get_viewport().get_visible_rect().size
	mute_btn.position = Vector2(vs.x - 108, 24)
	if mode == "world":
		satchel_btn.position = Vector2(24, 24)
		dig_btn.position = Vector2(vs.x / 2.0 - 65, vs.y - 170)
		door_btn.position = Vector2(vs.x / 2.0 + 100, vs.y - 156)


func _on_mute() -> void:
	GameState.toggle_mute()
	mute_btn.queue_redraw()


func set_dig_visible(v: bool) -> void:
	if dig_btn:
		dig_btn.visible = v


func set_door_visible(v: bool) -> void:
	if door_btn:
		door_btn.visible = v


func bounce_satchel() -> void:
	if satchel_btn == null:
		return
	satchel_btn.queue_redraw()
	satchel_btn.scale = Vector2(1.3, 1.3)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(satchel_btn, "scale", Vector2.ONE, 0.45)
