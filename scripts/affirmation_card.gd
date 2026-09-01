class_name AffirmationCard
extends Control
## A soft card that slides up from the bottom with one affirmation and its
## icon. Meant to be read aloud together — the game never requires reading it.
## Tap anywhere on it to dismiss, or it drifts away by itself.

const CARD_HEIGHT := 150.0
const SHOW_SECONDS := 8.0

var aff := {}
var _dismissing := false


## Show an affirmation card on the given CanvasLayer (replaces any existing one).
static func show_card(layer: Node, aff_d: Dictionary) -> void:
	for child in layer.get_children():
		if child is AffirmationCard:
			child.queue_free()
	var card: AffirmationCard = AffirmationCard.new()
	card.aff = aff_d
	layer.add_child(card)


func _ready() -> void:
	var vs := get_viewport().get_visible_rect().size
	var dirt: float = vs.y - DrawKit.ground_screen_y(self)
	size = Vector2(minf(780.0, vs.x - 80.0), clampf(dirt - 8.0, 96.0, CARD_HEIGHT))
	pivot_offset = size / 2.0
	position = Vector2((vs.x - size.x) / 2.0, vs.y + 20.0)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var label := Label.new()
	label.text = aff.get("text", "")
	label.position = Vector2(140, 0)
	label.size = Vector2(size.x - 170, size.y)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color("6b5a4a"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

	var icon := CardIcon.new()
	icon.kind = aff.get("icon", "star")
	icon.position = Vector2(78, size.y / 2.0)
	add_child(icon)

	# in the dirt below the ground line, out of the way of the meadow
	var target_y := clampf(DrawKit.ground_screen_y(self) + 4.0, 0.0, vs.y - size.y - 6.0)
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "position:y", target_y, 0.5)
	Sound.card_sound()

	var timer := Timer.new()
	timer.wait_time = SHOW_SECONDS
	timer.one_shot = true
	timer.timeout.connect(dismiss)
	add_child(timer)
	timer.start()


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
		dismiss()


func _draw() -> void:
	DrawKit.rounded_rect(self, Rect2(Vector2(0, 4), size), 28.0, Color(0, 0, 0, 0.07))
	DrawKit.rounded_rect(self, Rect2(Vector2.ZERO, size), 28.0, Color("fff8ec"))
	DrawKit.rounded_rect_outline(self, Rect2(Vector2.ZERO, size), 28.0, Color("f0d9a8"), 3.0)
	DrawKit.star(self, Vector2(size.x - 38, 30), 8.0, Color("ffd98a"))
	DrawKit.star(self, Vector2(size.x - 58, 48), 5.0, Color("ffe6b3"))


class CardIcon extends Node2D:
	var kind := "star"

	func _draw() -> void:
		DrawKit.draw_icon(self, kind, 42.0)
