class_name IconButton
extends Control
## Big, forgiving, code-drawn touch button. Icons only — no text.

signal pressed

var kind := "mute"
var btn_size := 90.0


func _init(k: String, s := 90.0) -> void:
	kind = k
	btn_size = s
	custom_minimum_size = Vector2(s, s)
	size = Vector2(s, s)
	pivot_offset = Vector2(s / 2.0, s / 2.0)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		scale = Vector2(0.85, 0.85)
		var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "scale", Vector2.ONE, 0.3)
		pressed.emit()


func _draw() -> void:
	var c := btn_size / 2.0
	var ctr := Vector2(c, c)
	draw_circle(ctr + Vector2(0, 3), c, Color(0, 0, 0, 0.08))
	draw_circle(ctr, c, Color(1, 1, 1, 0.88))
	var ink := Color("7a8b9c")
	match kind:
		"mute":
			draw_rect(Rect2(ctr + Vector2(-22, -9), Vector2(10, 18)), ink)
			draw_polygon(PackedVector2Array([
				ctr + Vector2(-12, -9), ctr + Vector2(0, -19),
				ctr + Vector2(0, 19), ctr + Vector2(-12, 9),
			]), PackedColorArray([ink]))
			if GameState.muted:
				draw_line(ctr + Vector2(-26, 20), ctr + Vector2(22, -22), Color("e8918c"), 6.0)
			else:
				draw_arc(ctr + Vector2(4, 0), 11.0, -0.9, 0.9, 10, ink, 4.0, true)
				draw_arc(ctr + Vector2(4, 0), 18.0, -0.9, 0.9, 10, ink, 4.0, true)
		"satchel":
			# basket with treasures peeking out
			draw_circle(ctr + Vector2(-8, -8), 7.0, Color("d9b485"))   # ammonite
			draw_arc(ctr + Vector2(-8, -8), 4.0, 0, TAU * 0.75, 10, Color("8a6a44"), 2.0, true)
			draw_circle(ctr + Vector2(9, -9), 6.5, Color("f0c96a"))    # gold coin
			draw_polygon(PackedVector2Array([
				ctr + Vector2(-24, -6), ctr + Vector2(24, -6),
				ctr + Vector2(18, 22), ctr + Vector2(-18, 22),
			]), PackedColorArray([Color("c9915c")]))
			for i in 3:
				var wy := 1.0 + i * 8.0
				draw_line(ctr + Vector2(-22 + i * 1.5, wy), ctr + Vector2(22 - i * 1.5, wy),
					Color("b57f4d"), 3.0)
			draw_arc(ctr + Vector2(0, -4), 20.0, PI + 0.35, TAU - 0.35, 14, Color("8a6a44"), 4.5, true)
			var count := GameState.satchel.size()
			if count > 0:
				draw_circle(ctr + Vector2(26, -26), 16.0, Color("e8918c"))
				draw_string(ThemeDB.fallback_font, ctr + Vector2(11, -18), str(count),
					HORIZONTAL_ALIGNMENT_CENTER, 30, 24, Color.WHITE)
		"dig":
			var handle := Color("a97e54")
			draw_line(ctr + Vector2(-18, -26), ctr + Vector2(4, 0), handle, 8.0)
			draw_line(ctr + Vector2(-26, -18), ctr + Vector2(-10, -34), handle, 8.0)
			var blade := Color("9aa7b5")
			draw_circle(ctr + Vector2(12, 10), 15.0, blade)
			draw_polygon(PackedVector2Array([
				ctr + Vector2(-2, 12), ctr + Vector2(26, 12), ctr + Vector2(12, 32),
			]), PackedColorArray([blade]))
		"door":
			DrawKit.rounded_rect(self, Rect2(ctr + Vector2(-14, -26), Vector2(34, 48)), 10.0, Color("8a6647"))
			draw_circle(ctr + Vector2(12, 0), 3.0, Color("d9b45c"))
			var green := Color("8fc48a")
			draw_line(ctr + Vector2(-34, 0), ctr + Vector2(-16, 0), green, 6.0)
			draw_polygon(PackedVector2Array([
				ctr + Vector2(-16, -9), ctr + Vector2(-5, 0), ctr + Vector2(-16, 9),
			]), PackedColorArray([green]))
		_:
			DrawKit.star(self, ctr, 20.0, Color("ffd98a"))
