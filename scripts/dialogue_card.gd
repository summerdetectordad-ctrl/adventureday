class_name DialogueCard
extends Control
## A soft two-line chat between Summer and an animal — lowercase, phonics
## friendly, always polite. Never required reading: it dismisses itself.
## A camera button lets her ask (nicely) to take a photo; main.gd listens
## for photo_moment and does the actual snap.

signal photo_moment
## A person, asked to tell her something. Animals get the camera; people get
## this — they know things, and being told something is better than a snapshot.
signal tell_moment

## Kept slim so it fits in the strip of dirt below the ground line — on a
## long phone screen that strip is not very tall.
const CARD_HEIGHT := 164.0
const SHOW_SECONDS := 9.0

var line1 := ""
var line2 := ""
## "camera" for an animal, "tell" for a person.
var action := "camera"
## What they say when she asks. Set for people before the card is shown.
var told := ""
var _label1: Label
var _label2: Label
var _camera_btn: IconButton
var _dismissing := false
var _snapping := false


static func show_chat(layer: Node, l1: String, l2: String, act := "camera",
		tell_line := "") -> DialogueCard:
	for child in layer.get_children():
		if child is DialogueCard or child is AffirmationCard:
			child.queue_free()
	var card: DialogueCard = DialogueCard.new()
	card.line1 = l1
	card.line2 = l2
	card.action = act
	card.told = tell_line
	layer.add_child(card)
	return card


func _ready() -> void:
	var vs := get_viewport().get_visible_rect().size
	# The dirt below the ground line is all the room there is, and on a long
	# phone screen that is not much. Shrink to fit rather than sit over the
	# meadow — the words matter less than being able to see what she is doing.
	var dirt: float = vs.y - DrawKit.ground_screen_y(self)
	var h: float = clampf(dirt - 8.0, 104.0, CARD_HEIGHT)
	size = Vector2(minf(820.0, vs.x - 80.0), h)
	pivot_offset = size / 2.0
	position = Vector2((vs.x - size.x) / 2.0, vs.y + 20.0)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var fs: int = 26 if size.y > 140.0 else 22
	_label1 = _make_label(line1, 22.0, Color("6b5a4a"), fs)
	_label2 = _make_label("", size.y / 2.0 + 4.0, Color("5c7a54"), fs)

	var bs: float = clampf(size.y - 40.0, 64.0, 92.0)
	_camera_btn = IconButton.new("camera" if action == "camera" else "tell", bs)
	_camera_btn.position = Vector2(size.x - bs - 20.0, size.y / 2.0 - bs / 2.0)
	_camera_btn.pressed.connect(_on_camera if action == "camera" else _on_tell)
	add_child(_camera_btn)

	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "position:y", _resting_y(), 0.5)
	Sound.card_sound()

	# the animal replies after a friendly pause
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		if not _dismissing and not _snapping and is_instance_valid(_label2):
			_label2.text = line2)

	get_tree().create_timer(SHOW_SECONDS).timeout.connect(func() -> void:
		if not _snapping:
			dismiss())


func _make_label(text: String, y: float, col: Color, fs := 26) -> Label:
	var label := Label.new()
	label.text = text
	label.position = Vector2(48, y)
	label.size = Vector2(size.x - 190, size.y / 2.0 - 14.0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", fs)
	label.add_theme_color_override("font_color", col)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _on_camera() -> void:
	if _snapping or _dismissing:
		return
	_snapping = true
	_camera_btn.visible = false
	_label1.text = "please may i take a photo?"
	_label2.text = ""
	await get_tree().create_timer(1.2).timeout
	if _dismissing:
		return
	_label2.text = "yes please do!"
	await get_tree().create_timer(0.9).timeout
	if _dismissing:
		return
	photo_moment.emit()
	await get_tree().create_timer(1.1).timeout
	dismiss()


func dismiss() -> void:
	if _dismissing:
		return
	_dismissing = true
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "position:y", get_viewport().get_visible_rect().size.y + 30.0, 0.35)
	tw.tween_callback(queue_free)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		accept_event()
		if not _snapping:
			dismiss()


func _draw() -> void:
	DrawKit.rounded_rect(self, Rect2(Vector2(0, 4), size), 28.0, Color(0, 0, 0, 0.07))
	DrawKit.rounded_rect(self, Rect2(Vector2.ZERO, size), 28.0, Color("fff8ec"))
	DrawKit.rounded_rect_outline(self, Rect2(Vector2.ZERO, size), 28.0, Color("f0d9a8"), 3.0)
	# little speech tails: Summer's up top, the animal's below
	DrawKit.heart(self, Vector2(28, 42), 8.0, Color("f2a0b5"))
	DrawKit.star(self, Vector2(28, size.y / 2.0 + 34.0), 8.0, Color("a8d5a2"))


## She asks them to tell her something, and they do. The card stays up longer
## than usual afterwards — this is the bit worth reading.
func _on_tell() -> void:
	if _snapping or _dismissing:
		return
	_snapping = true
	_camera_btn.visible = false
	_label1.text = "tell me something!"
	_label2.text = ""
	await get_tree().create_timer(1.0).timeout
	if _dismissing:
		return
	_label2.text = told
	tell_moment.emit()
	await get_tree().create_timer(7.5).timeout
	dismiss()


## Sit in the dirt below the ground line, so a chat never covers the meadow.
## If the dirt is too shallow for the card — a very wide, short screen — it
## goes as low as it can instead.
func _resting_y() -> float:
	var vs := get_viewport().get_visible_rect().size
	return clampf(DrawKit.ground_screen_y(self) + 4.0, 0.0, vs.y - size.y - 6.0)
