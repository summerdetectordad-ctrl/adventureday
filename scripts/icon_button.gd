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
		"camera":
			DrawKit.rounded_rect(self, Rect2(ctr + Vector2(-24, -14), Vector2(48, 32)), 8.0, Color("7a8b9c"))
			DrawKit.rounded_rect(self, Rect2(ctr + Vector2(-8, -20), Vector2(20, 8)), 3.0, Color("7a8b9c"))
			draw_circle(ctr + Vector2(0, 2), 11.0, Color("9fb0c4"))
			draw_circle(ctr + Vector2(0, 2), 7.0, Color("5c6b7a"))
			draw_circle(ctr + Vector2(-3, -1), 2.2, Color(1, 1, 1, 0.8))
			draw_circle(ctr + Vector2(17, -8), 2.6, Color("ffd98a"))
		"pack":
			# back into the backpack — closes a full-screen activity
			DrawKit.rounded_rect(self, Rect2(ctr + Vector2(-18, -12), Vector2(36, 32)), 10.0, Color("8fb7d9"))
			DrawKit.rounded_rect(self, Rect2(ctr + Vector2(-18, -12), Vector2(36, 12)), 6.0, Color("7fa8cc"))
			DrawKit.rounded_rect(self, Rect2(ctr + Vector2(-7, 2), Vector2(14, 12)), 4.0, Color("a9c9e8"))
			draw_line(ctr + Vector2(0, -34), ctr + Vector2(0, -20), Color("7a8b9c"), 5.0)
			draw_polygon(PackedVector2Array([
				ctr + Vector2(-7, -20), ctr + Vector2(7, -20), ctr + Vector2(0, -10),
			]), PackedColorArray([Color("7a8b9c")]))
		"backpack":
			# Her actual rucksack — the blue one she wears. This OPENS the pack,
			# so it must not look like the "put away" icon above.
			var pk := Color("6f9ad4")
			# shoulder straps behind
			for sx in [-1.0, 1.0]:
				draw_line(ctr + Vector2(sx * 13, -18), ctr + Vector2(sx * 9, 8),
					Color("5d84b8"), 5.0)
			# grab loop
			draw_arc(ctr + Vector2(0, -22), 7.0, PI, TAU, 10, Color("5d84b8"), 4.0, true)
			# main body
			DrawKit.rounded_rect(self, Rect2(ctr + Vector2(-19, -18), Vector2(38, 40)),
				11.0, pk)
			# the flap over the top, with a buckle
			DrawKit.rounded_rect(self, Rect2(ctr + Vector2(-19, -18), Vector2(38, 17)),
				9.0, pk.darkened(0.12))
			DrawKit.rounded_rect(self, Rect2(ctr + Vector2(-6, -4), Vector2(12, 9)),
				3.0, Color("e8c168"))
			# front pocket
			DrawKit.rounded_rect(self, Rect2(ctr + Vector2(-12, 7), Vector2(24, 13)),
				5.0, pk.lightened(0.16))
			draw_line(ctr + Vector2(-12, 7), ctr + Vector2(12, 7), pk.darkened(0.18), 2.0)
		"save":
			# tuck a copy into the treasure basket
			draw_polygon(PackedVector2Array([
				ctr + Vector2(-20, 0), ctr + Vector2(20, 0),
				ctr + Vector2(15, 22), ctr + Vector2(-15, 22),
			]), PackedColorArray([Color("c9915c")]))
			draw_arc(ctr + Vector2(0, 2), 17.0, PI + 0.35, TAU - 0.35, 14, Color("8a6a44"), 4.0, true)
			draw_line(ctr + Vector2(0, -26), ctr + Vector2(0, -8), Color("8fc48a"), 5.0)
			draw_polygon(PackedVector2Array([
				ctr + Vector2(-7, -8), ctr + Vector2(7, -8), ctr + Vector2(0, 2),
			]), PackedColorArray([Color("8fc48a")]))
		"reading":
			# Pictures / words / sentences — a parent-set control, drawn as how
			# much text a game will use rather than as a number. Everything is
			# relative to `ctr`, like every other icon here.
			var lvl: int = clampi(GameState.reading_level, 0, 2)
			if lvl == 0:
				DrawKit.star(self, ctr, 12.0, Color("e8b06a"))
				draw_circle(ctr, 4.5, Color("fff3d0"))
			else:
				var rows := 2 if lvl == 1 else 3
				for i in rows:
					var w := 24.0 if i < rows - 1 else 14.0
					draw_rect(Rect2(ctr + Vector2(-12, -11 + i * 9), Vector2(w, 4.5)),
						Color("8a7355"))
			draw_arc(ctr, c - 7.0, 0, TAU, 24, Color("cfc0a4"), 2.5, true)
		"eat":
			# Summer herself, taking a bite. A face says "eat this" in a way no
			# symbol does — she can see who is doing the eating.
			var scl := btn_size / 120.0
			var sandwich := ctr + Vector2(25 * scl, 13 * scl)
			var sw := 46.0 * scl
			# the sandwich she is holding up to her mouth
			DrawKit.rounded_rect(self, Rect2(sandwich + Vector2(-sw * 0.5, -13 * scl),
				Vector2(sw, 8 * scl)), 3.5 * scl, Color("e8c88a"))
			draw_rect(Rect2(sandwich + Vector2(-sw * 0.46, -5.5 * scl),
				Vector2(sw * 0.92, 4 * scl)), Color("a8d5a2"))
			draw_rect(Rect2(sandwich + Vector2(-sw * 0.46, -1.5 * scl),
				Vector2(sw * 0.92, 3.5 * scl)), Color("e07a70"))
			DrawKit.rounded_rect(self, Rect2(sandwich + Vector2(-sw * 0.5, 2 * scl),
				Vector2(sw, 8 * scl)), 3.5 * scl, Color("e8c88a"))
			# her face, mouth open for it
			DrawKit.summer_head(self, ctr + Vector2(-16 * scl, 3 * scl), 24.0 * scl, true)
			# crumbs of pure delight
			DrawKit.star(self, ctr + Vector2(30 * scl, -28 * scl), 5.0 * scl, Color("ffd98a"))
			draw_circle(ctr + Vector2(41 * scl, -16 * scl), 2.4 * scl, Color("ffe6b3"))
		"shutter":
			# a big round shutter release, the way a camera's own button looks
			draw_circle(ctr, 30.0, Color("7a8b9c"))
			draw_circle(ctr, 24.0, Color("e8918c"))
			draw_circle(ctr, 17.0, Color("f2a8a0"))
			draw_arc(ctr, 24.0, PI * 1.05, PI * 1.65, 10, Color(1, 1, 1, 0.5), 3.0, true)
			for i in 4:
				var a := i * TAU / 4.0 + 0.4
				draw_line(ctr + Vector2.from_angle(a) * 34.0,
					ctr + Vector2.from_angle(a) * 40.0, Color("7a8b9c"), 3.0)
		"tell":
			# a speech bubble with three dots — "tell me something"
			var bub := Color("8fb7d9")
			DrawKit.rounded_rect(self, Rect2(ctr + Vector2(-25, -22), Vector2(50, 36)),
				13.0, bub)
			draw_polygon(PackedVector2Array([
				ctr + Vector2(-13, 12), ctr + Vector2(1, 12), ctr + Vector2(-15, 25),
			]), PackedColorArray([bub]))
			for i in 3:
				draw_circle(ctr + Vector2(-13.0 + i * 13.0, -4.0), 4.2, Color("fff8ec"))
		"undo":
			draw_arc(ctr + Vector2(2, 2), 18.0, PI * 0.75, PI * 2.05, 20, ink, 6.0, true)
			draw_polygon(PackedVector2Array([
				ctr + Vector2(-22, -4), ctr + Vector2(-4, -8), ctr + Vector2(-14, 8),
			]), PackedColorArray([ink]))
		"redo":
			draw_arc(ctr + Vector2(-2, 2), 18.0, PI * 0.95, PI * 2.25, 20, ink, 6.0, true)
			draw_polygon(PackedVector2Array([
				ctr + Vector2(22, -4), ctr + Vector2(4, -8), ctr + Vector2(14, 8),
			]), PackedColorArray([ink]))
		"fill":
			# paint bucket mid-pour
			DrawKit.rounded_rect(self, Rect2(ctr + Vector2(-16, -14), Vector2(26, 22)), 6.0, ink)
			draw_arc(ctr + Vector2(-3, -14), 10.0, PI, TAU, 12, ink, 4.0, true)
			draw_circle(ctr + Vector2(16, 8), 6.0, Color("8fb7d9"))
			draw_polygon(PackedVector2Array([
				ctr + Vector2(12, 0), ctr + Vector2(20, 0), ctr + Vector2(16, 12),
			]), PackedColorArray([Color("8fb7d9")]))
		"clear":
			# a fresh sparkly page
			DrawKit.rounded_rect(self, Rect2(ctr + Vector2(-16, -20), Vector2(32, 40)), 4.0, Color("fffdf5"))
			DrawKit.rounded_rect_outline(self, Rect2(ctr + Vector2(-16, -20), Vector2(32, 40)), 4.0, Color("d9c9a8"), 2.5)
			DrawKit.star(self, ctr + Vector2(0, -2), 9.0, Color("ffd98a"))
			DrawKit.star(self, ctr + Vector2(10, 10), 5.0, Color("ffe6b3"))
		_:
			DrawKit.star(self, ctr, 20.0, Color("ffd98a"))
