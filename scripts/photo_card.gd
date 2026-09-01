class_name PhotoCard
extends CanvasLayer
## A big polaroid pop-up so Summer can really look at a photo she's taken
## (or one from the museum shelf). Tap anywhere to tuck it away, or it
## drifts off by itself. Blocks taps underneath while it's up.

signal closed

var kind := "photo_meadow_0"
var word := ""


static func show_photo(parent: Node, kind_v: String, word_v := "") -> PhotoCard:
	var pc := PhotoCard.new()
	pc.kind = kind_v
	pc.word = word_v
	parent.add_child(pc)
	Sound.card_sound()
	return pc


func _ready() -> void:
	layer = 45
	var body := CardBody.new()
	body.kind = kind
	body.word = word
	body.dismissed.connect(func() -> void:
		closed.emit()
		queue_free())
	add_child(body)


class CardBody extends Control:
	signal dismissed

	var kind := ""
	var word := ""
	var _closing := false
	var _shown_at := 0.0

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		_shown_at = Time.get_ticks_msec() / 1000.0
		modulate.a = 0.0
		scale = Vector2(0.6, 0.6)
		var vs := get_viewport().get_visible_rect().size
		size = vs
		pivot_offset = vs / 2.0
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 1.0, 0.22)
		tw.parallel().tween_property(self, "scale", Vector2.ONE, 0.38) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		# The polaroid is its own Node2D so the tilt lives in the node transform.
		# DrawKit sets a draw transform of its own for some subjects, and that
		# REPLACES rather than stacks — drawing the card here would lose the tilt
		# and fling the picture off-frame.
		var polaroid := Polaroid.new()
		polaroid.kind = kind
		polaroid.word = word
		polaroid.position = vs / 2.0
		polaroid.rotation = -0.045
		add_child(polaroid)
		var timer := get_tree().create_timer(6.0)
		timer.timeout.connect(_dismiss)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			accept_event()
			if Time.get_ticks_msec() / 1000.0 - _shown_at > 0.4:
				_dismiss()

	func _dismiss() -> void:
		if _closing or not is_inside_tree():
			return
		_closing = true
		var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(self, "scale", Vector2(0.15, 0.15), 0.3)
		tw.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
		tw.tween_callback(func() -> void: dismissed.emit())

	func _draw() -> void:
		var vs := size
		# soft dim behind, so the photo is the whole moment
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.2, 0.16, 0.1, 0.25))
		var center := vs / 2.0
		# a couple of gentle stars around it
		DrawKit.star(self, center + Vector2(-200, -150), 10.0, Color("ffd98a"))
		DrawKit.star(self, center + Vector2(210, 120), 7.0, Color("ffe6b3"))


	## The picture itself, tilted like it's just been set down.
	class Polaroid extends Node2D:
		var kind := ""
		var word := ""

		func _draw() -> void:
			DrawKit.rounded_rect(self, Rect2(-160, -180, 320, 380), 12.0, Color(0, 0, 0, 0.16))
			DrawKit.draw_find(self, kind, 190.0)
			# the word under the picture, lowercase — optional flavour, like the tags
			if word == "":
				return
			var font := ThemeDB.fallback_font
			var fs := 42
			var w := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string(font, Vector2(-w / 2.0, 152.0), word,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("8a7355"))
