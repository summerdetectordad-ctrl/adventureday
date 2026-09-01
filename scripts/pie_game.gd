class_name PieGame
extends CanvasLayer
## Baking, in the treehouse kitchen. Fruit she has picked goes into a pastry
## case, she crimps the edges, and it bakes with a warm glow. Then she eats it,
## or shares it.
##
## No recipe is wrong. A pie of nine strawberries is a fine pie. The oven never
## burns anything and the timer only ever counts toward something nice.

signal closed
signal eat_now(stack: Array)

const FILLINGS := ["apple", "berry", "cherry", "plum", "pear", "rhubarb"]
const BAKE_SECONDS := 3.4

var table: Table


func _ready() -> void:
	layer = 40
	table = Table.new()
	table.game = self
	add_child(table)

	var pack_btn := IconButton.new("pack", 96.0)
	pack_btn.pressed.connect(func() -> void: closed.emit())
	table.add_child(pack_btn)
	table.pack_btn = pack_btn

	var bake_btn := IconButton.new("eat", 120.0)
	bake_btn.pressed.connect(_bake)
	table.add_child(bake_btn)
	table.bake_btn = bake_btn
	table.layout_buttons()


## Crimp the edges, then into the oven. Watchable, short, and it always works.
func _bake() -> void:
	if table.stage != "filling":
		if table.stage == "done":
			_serve()
		return
	if GameState.pie_stack.is_empty():
		table.wobble()
		return
	table.stage = "crimping"
	Sound.pop()
	await get_tree().create_timer(0.7).timeout
	if not is_instance_valid(table):
		return
	table.stage = "baking"
	table.bake_t = 0.0
	Sound.card_sound()
	await get_tree().create_timer(BAKE_SECONDS).timeout
	if not is_instance_valid(table):
		return
	table.stage = "done"
	Fx.sparkles(table, table.tin_pos() + Vector2(0, -40), 10, Color("ffe6b3"))
	Sound.chime_find()


func _serve() -> void:
	var stack: Array = GameState.pie_stack.duplicate()
	stack.push_front("pastry")
	GameState.pie_stack.clear()
	GameState.save_game()
	eat_now.emit(stack)
	closed.emit()


class Table extends Control:
	var game: PieGame = null
	var pack_btn: IconButton
	var bake_btn: IconButton
	var stage := "filling"    # filling | crimping | baking | done
	var bake_t := 0.0
	var t := 0.0
	var _wobble := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		get_viewport().size_changed.connect(layout_buttons)

	func layout_buttons() -> void:
		var vs := get_viewport().get_visible_rect().size
		size = vs
		if pack_btn:
			pack_btn.position = Vector2(vs.x - 120, 24)
		if bake_btn:
			bake_btn.position = Vector2(vs.x - 160, vs.y * 0.60)

	func _process(delta: float) -> void:
		t += delta
		if stage == "baking":
			bake_t += delta
		if _wobble > 0.0:
			_wobble = maxf(0.0, _wobble - delta * 3.0)
		queue_redraw()

	func wobble() -> void:
		_wobble = 1.0

	func tin_pos() -> Vector2:
		return Vector2(size.x * 0.40, size.y * 0.585)

	func _btn_pos(i: int) -> Vector2:
		var step := minf(140.0, (size.x - 200.0) / FILLINGS.size())
		var start := size.x / 2.0 - step * (FILLINGS.size() - 1) / 2.0
		return Vector2(start + i * step, size.y - 110.0)

	func _gui_input(event: InputEvent) -> void:
		if not (event is InputEventMouseButton and event.pressed \
				and event.button_index == MOUSE_BUTTON_LEFT):
			return
		accept_event()
		if stage != "filling":
			return
		var p: Vector2 = event.position
		for i in FILLINGS.size():
			if p.distance_to(_btn_pos(i)) < 58.0:
				if GameState.fruit <= 0:
					wobble()
					Sound.pop()
					return
				GameState.add_fruit(-1)
				GameState.pie_stack.append(FILLINGS[i])
				Sound.pop()
				queue_redraw()
				return

	func _draw() -> void:
		var vs := size
		# the kitchen: warm wood, a window, a worktop
		draw_rect(Rect2(Vector2.ZERO, vs), Color("e8d9bd"))
		draw_rect(Rect2(0, vs.y * 0.62, vs.x, vs.y * 0.38), Color("c9a06c"))
		draw_rect(Rect2(0, vs.y * 0.62, vs.x, 14), Color("d9b485"))
		# window with the meadow outside
		var win := Rect2(vs.x * 0.68, vs.y * 0.14, vs.x * 0.24, vs.y * 0.3)
		DrawKit.rounded_rect(self, win, 10.0, Color("8a6a44"))
		draw_rect(Rect2(win.position + Vector2(8, 8), win.size - Vector2(16, 16)), Color("c3e2f2"))
		draw_rect(Rect2(win.position.x + 8, win.end.y - 8 - win.size.y * 0.3,
			win.size.x - 16, win.size.y * 0.3), Color("a8d5a2"))
		draw_line(win.get_center() - Vector2(0, win.size.y * 0.5 - 8),
			win.get_center() + Vector2(0, win.size.y * 0.5 - 8), Color("8a6a44"), 5.0)

		var tp := tin_pos()
		var wob := sin(_wobble * PI * 4.0) * 8.0 * _wobble
		_draw_pie(tp + Vector2(wob, 0))
		_draw_stage_hint(vs, tp)

		# the fruit she can put in, and how much fruit she has left
		for i in FILLINGS.size():
			var bp := _btn_pos(i)
			draw_circle(bp + Vector2(0, 4), 54.0, Color(0, 0, 0, 0.07))
			draw_circle(bp, 54.0, Color(1, 1, 1, 0.93))
			_fruit_icon(FILLINGS[i], bp, 1.0)
		var font := ThemeDB.fallback_font
		draw_circle(Vector2(70, 60), 18.0, Color("e05c50"))
		draw_string(font, Vector2(96, 70), str(GameState.fruit),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("6b4f38"))

	func _draw_pie(tp: Vector2) -> void:
		var pastry := Color("e8c88a")
		# the tin
		DrawKit.ellipse(self, tp + Vector2(0, 14), 132.0, 34.0, Color("9aa0a6"))
		DrawKit.ellipse(self, tp + Vector2(0, 8), 126.0, 30.0, Color("b8bcc2"))
		# the pastry case
		DrawKit.ellipse(self, tp, 120.0, 30.0, pastry)
		DrawKit.ellipse(self, tp + Vector2(0, -4), 104.0, 24.0, pastry.darkened(0.1))

		# the fruit inside, heaped up
		var stack: Array = GameState.pie_stack
		for i in stack.size():
			var a := i * 2.399
			var r := 12.0 + sqrt(float(i)) * 15.0
			var p := tp + Vector2(cos(a) * r, sin(a) * r * 0.26 - 6.0 - i * 0.6)
			_fruit_icon(str(stack[i]), p, 0.42)

		if stage == "filling":
			return
		# a lid, crimped at the edge
		var bake := clampf(bake_t / PieGame.BAKE_SECONDS, 0.0, 1.0)
		var lid := pastry.lerp(Color("d9a45c"), bake)
		DrawKit.ellipse(self, tp + Vector2(0, -8), 112.0, 28.0, lid)
		for i in 22:
			var a := i / 22.0 * TAU
			draw_circle(tp + Vector2(cos(a) * 112.0, sin(a) * 28.0 - 8.0), 6.0, lid.darkened(0.08))
		# steam curls, and a warm glow while it bakes
		if stage == "baking":
			draw_circle(tp + Vector2(0, -8), 150.0, Color(1.0, 0.78, 0.42, 0.10 + 0.05 * sin(t * 5.0)))
			for i in 3:
				var sx := tp.x - 40.0 + i * 40.0
				var pts := PackedVector2Array()
				for k in 8:
					var u := k / 7.0
					pts.append(Vector2(sx + sin(u * 5.0 + t * 2.2 + i) * 9.0,
						tp.y - 40.0 - u * 70.0))
				draw_polyline(pts, Color(1, 1, 1, 0.4 * (1.0 - bake * 0.3)), 3.0)
		if stage == "done":
			DrawKit.star(self, tp + Vector2(-90, -50), 9.0, Color("ffd98a"))
			DrawKit.star(self, tp + Vector2(96, -34), 7.0, Color("ffe6b3"))

	func _draw_stage_hint(vs: Vector2, tp: Vector2) -> void:
		var font := ThemeDB.fallback_font
		var msg := ""
		match stage:
			"filling": msg = "put fruit in"
			"crimping": msg = "crimping the edges"
			"baking": msg = "baking..."
			"done": msg = "ready! tap to eat"
		var w := font.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		draw_string(font, Vector2(tp.x - w / 2.0, vs.y * 0.20), msg,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("8a6a52"))

	func _fruit_icon(kind: String, p: Vector2, s: float) -> void:
		var col := Color("e05c50")
		match kind:
			"berry": col = Color("8a5fa8")
			"cherry": col = Color("c8384a")
			"plum": col = Color("7a5490")
			"pear": col = Color("bcd06a")
			"rhubarb": col = Color("d95f7a")
		draw_circle(p + Vector2(0, 2 * s), 26.0 * s, col.darkened(0.2))
		draw_circle(p, 24.0 * s, col)
		draw_circle(p + Vector2(-8 * s, -8 * s), 7.0 * s, col.lightened(0.3))
		draw_line(p + Vector2(0, -22 * s), p + Vector2(3 * s, -34 * s), Color("6f5a3f"), 3.0 * s)
		DrawKit.ellipse(self, p + Vector2(10 * s, -32 * s), 9.0 * s, 4.5 * s, Color("8cc188"))
