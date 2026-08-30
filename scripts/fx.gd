class_name Fx
## Tiny celebration effects — gentle sparkles and floating hearts.
## Nothing flashes; everything drifts and fades softly.


class SparkleStar extends Node2D:
	var col := Color("ffd98a")
	var s := 7.0

	func _draw() -> void:
		DrawKit.star(self, Vector2.ZERO, s, col)


class FloatHeart extends Node2D:
	var col := Color("f2a0b5")
	var s := 9.0

	func _draw() -> void:
		DrawKit.heart(self, Vector2.ZERO, s, col)


static func sparkles(parent: Node, pos: Vector2, n := 8, col := Color("ffd98a")) -> void:
	for i in n:
		var st := SparkleStar.new()
		st.col = col
		st.s = randf_range(4.0, 9.0)
		st.position = pos
		st.z_index = 20
		parent.add_child(st)
		var dir := Vector2.from_angle(randf() * TAU) * randf_range(24.0, 70.0)
		var tw := st.create_tween()
		tw.tween_property(st, "position", pos + dir, 0.7) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(st, "modulate:a", 0.0, 0.7)
		tw.tween_callback(st.queue_free)


class NumPuff extends Node2D:
	var n := 1

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var txt := str(n)
		var fs := 40
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_circle(Vector2.ZERO, 27.0, Color(1, 1, 1, 0.75))
		draw_string(font, Vector2(-w / 2.0, fs * 0.35), txt,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("7a5a8f"))


## A soft counting number that drifts up and fades — Year 1 number practice,
## never required for anything.
static func float_number(parent: Node, pos: Vector2, n: int) -> void:
	var np := NumPuff.new()
	np.n = n
	np.position = pos
	np.z_index = 20
	parent.add_child(np)
	var tw := np.create_tween()
	tw.tween_property(np, "position:y", pos.y - 70.0, 1.1) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(np, "modulate:a", 0.0, 1.1)
	tw.tween_callback(np.queue_free)


static func hearts(parent: Node, pos: Vector2, n := 3) -> void:
	for i in n:
		var h := FloatHeart.new()
		h.s = randf_range(7.0, 11.0)
		h.position = pos + Vector2(randf_range(-18.0, 18.0), randf_range(-8.0, 8.0))
		h.z_index = 20
		parent.add_child(h)
		var tw := h.create_tween()
		tw.tween_property(h, "position:y", h.position.y - randf_range(50.0, 90.0), 1.2) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(h, "modulate:a", 0.0, 1.2)
		tw.tween_callback(h.queue_free)
