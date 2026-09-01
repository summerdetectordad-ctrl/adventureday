class_name DrawingSuite
extends CanvasLayer
## Summer's sketch pad, opened from her backpack anywhere in the meadow.
## Finger-paint with soft crayons: pastel colours down the left, three brush
## sizes, the paper-coloured swatch works as an eraser. Tools down the right:
## save a copy to the basket, undo, redo, fill the page with the chosen
## colour, and a fresh page (undo brings the old picture straight back, so
## nothing is ever really lost). The page persists between opens; the
## backpack button puts the pad away.

signal closed

var paper: Paper


func _ready() -> void:
	layer = 40
	paper = Paper.new()
	add_child(paper)

	paper.pack_btn = _btn("pack", func() -> void: closed.emit())
	paper.save_btn = _btn("save", _save)
	paper.undo_btn = _btn("undo", _undo)
	paper.redo_btn = _btn("redo", _redo)
	paper.fill_btn = _btn("fill", _fill)
	paper.clear_btn = _btn("clear", _clear)
	paper.layout_buttons()


func _btn(kind: String, action: Callable) -> IconButton:
	var b := IconButton.new(kind, 92.0)
	b.pressed.connect(action)
	paper.add_child(b)
	return b


func _undo() -> void:
	if GameState.sketch_strokes.is_empty():
		return
	GameState.sketch_redo.append(GameState.sketch_strokes.pop_back())
	Sound.pop()
	paper.queue_redraw()


func _redo() -> void:
	if GameState.sketch_redo.is_empty():
		return
	GameState.sketch_strokes.append(GameState.sketch_redo.pop_back())
	Sound.pop()
	paper.queue_redraw()


func _fill() -> void:
	GameState.sketch_strokes.append({"type": "fill", "col": Paper.COLORS[paper.sel_color]})
	GameState.sketch_redo.clear()
	Sound.swish()
	paper.queue_redraw()


func _clear() -> void:
	if GameState.sketch_strokes.is_empty():
		return
	GameState.sketch_strokes.append({"type": "clear"})
	GameState.sketch_redo.clear()
	Sound.card_sound()
	paper.queue_redraw()


func _save() -> void:
	if paper.saving:
		return
	paper.saving = true
	paper.set_buttons_visible(false)
	await RenderingServer.frame_post_draw
	var img := paper.get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("user://drawings")
	var n := DirAccess.get_files_at("user://drawings").size() + 1
	img.save_png("user://drawings/drawing_%d.png" % n)
	paper.set_buttons_visible(true)
	paper.saving = false
	GameState.add_to_satchel("drawing")
	Sound.chime_find()
	Fx.sparkles(paper, paper.size / 2.0, 10)


## The page itself plus the crayon palette. Ops (strokes, fills, clears) live
## in GameState so the picture survives trips to the museum within a session.
class Paper extends Control:
	const COLORS := ["e8918c", "f2b8cf", "ffd98a", "a8d5a2", "8fb7d9",
		"c4b8e8", "a97e54", "4a3a30", "fffdf5"]   # last one erases
	const SIZES := [7.0, 16.0, 30.0]
	const PAPER := Color("fffdf5")

	var sel_color := 0
	var sel_size := 1
	var drawing_stroke := false
	var saving := false
	var pack_btn: IconButton
	var save_btn: IconButton
	var undo_btn: IconButton
	var redo_btn: IconButton
	var fill_btn: IconButton
	var clear_btn: IconButton

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		get_viewport().size_changed.connect(layout_buttons)

	func layout_buttons() -> void:
		var vs := get_viewport().get_visible_rect().size
		size = vs
		var btns := [pack_btn, save_btn, undo_btn, redo_btn, fill_btn, clear_btn]
		for i in btns.size():
			if btns[i]:
				btns[i].position = Vector2(vs.x - 116, 20 + i * 112.0)

	func set_buttons_visible(v: bool) -> void:
		for b in [pack_btn, save_btn, undo_btn, redo_btn, fill_btn, clear_btn]:
			if b:
				b.visible = v

	func _color_pos(i: int) -> Vector2:
		return Vector2(60 + (i % 2) * 76.0, 84 + floori(float(i) / 2.0) * 76.0)

	func _size_pos(i: int) -> Vector2:
		return Vector2(98, 478 + i * 84.0)

	func _gui_input(event: InputEvent) -> void:
		if saving:
			return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				accept_event()
				var p: Vector2 = event.position
				for i in COLORS.size():
					if p.distance_to(_color_pos(i)) < 38.0:
						sel_color = i
						Sound.pop()
						queue_redraw()
						return
				for i in SIZES.size():
					if p.distance_to(_size_pos(i)) < 40.0:
						sel_size = i
						Sound.pop()
						queue_redraw()
						return
				drawing_stroke = true
				GameState.sketch_strokes.append({
					"type": "stroke",
					"col": COLORS[sel_color],
					"w": SIZES[sel_size],
					"pts": [p],
				})
				GameState.sketch_redo.clear()
				queue_redraw()
			else:
				drawing_stroke = false
		elif event is InputEventMouseMotion and drawing_stroke:
			accept_event()
			var ops := GameState.sketch_strokes
			if ops.is_empty():
				return
			var op: Dictionary = ops[ops.size() - 1]
			if op.get("type", "stroke") != "stroke":
				return
			var pts: Array = op["pts"]
			var p: Vector2 = event.position
			if pts.is_empty() or p.distance_to(pts[pts.size() - 1]) > 3.0:
				pts.append(p)
				queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), PAPER)

		# start from the most recent fresh page
		var ops := GameState.sketch_strokes
		var start := 0
		for i in ops.size():
			if ops[i].get("type", "stroke") == "clear":
				start = i + 1
		for i in range(start, ops.size()):
			var op: Dictionary = ops[i]
			match op.get("type", "stroke"):
				"fill":
					draw_rect(Rect2(Vector2.ZERO, size), Color(op["col"]))
				"stroke":
					var col := Color(op["col"])
					var w: float = op["w"]
					var pts: Array = op["pts"]
					if pts.size() == 1:
						draw_circle(pts[0], w / 2.0, col)
						continue
					draw_polyline(PackedVector2Array(pts), col, w, true)
					draw_circle(pts[0], w / 2.0 - 0.5, col)
					draw_circle(pts[pts.size() - 1], w / 2.0 - 0.5, col)

		if saving:
			return
		# faint page edge so it feels like her pad (not part of saved pictures)
		DrawKit.rounded_rect_outline(self, Rect2(Vector2(8, 8), size - Vector2(16, 16)), 18.0,
			Color("f0e4c8"), 3.0)
		# crayon palette down the left, two columns
		for i in COLORS.size():
			var p := _color_pos(i)
			draw_circle(p + Vector2(0, 3), 32.0, Color(0, 0, 0, 0.06))
			draw_circle(p, 32.0, Color(COLORS[i]))
			if i == COLORS.size() - 1:
				draw_arc(p, 31.0, 0, TAU, 24, Color("d9c9a8"), 2.5, true)  # the eraser
			if i == sel_color:
				draw_arc(p, 38.0, 0, TAU, 28, Color("8a6a44"), 4.0, true)
		# brush sizes
		for i in SIZES.size():
			var p := _size_pos(i)
			draw_circle(p, 34.0, Color(1, 1, 1, 0.9))
			draw_circle(p, SIZES[i] / 2.0 + 3.0, Color(COLORS[sel_color]) if sel_color < COLORS.size() - 1 else Color("d9c9a8"))
			if i == sel_size:
				draw_arc(p, 40.0, 0, TAU, 28, Color("8a6a44"), 4.0, true)
