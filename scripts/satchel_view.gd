class_name SatchelView
extends CanvasLayer
## What is in the basket. Tapping the basket in the corner opens this: every
## find she is carrying, laid out where she can look at them, a page at a time.
##
## The basket is where finds WAIT until she takes them up to the museum
## shelves. Tapping one picks it up and shows its word, with two big choices:
## KEEP it, or PUT IT BACK in the meadow. Putting one back is the only way
## anything ever leaves her collection, it takes two deliberate taps, and it is
## never called throwing away — the meadow keeps making more. Without it the
## basket fills up and she is stuck.

signal closed

const PER_PAGE := 12
const COLS := 6

var page := 0
var _exit: IconButton = null
var _body: Body = null


func _ready() -> void:
	layer = 43
	_body = Body.new()
	_body.view = self
	add_child(_body)
	_exit = IconButton.new("pack", 96.0)
	_exit.pressed.connect(func() -> void: closed.emit())
	add_child(_exit)
	_layout()
	get_viewport().size_changed.connect(_layout)


func _layout() -> void:
	if _exit != null:
		_exit.position = Vector2(get_viewport().get_visible_rect().size.x - 120, 24)


func pages() -> int:
	return maxi(1, ceili(float(GameState.satchel.size()) / PER_PAGE))


class Body extends Control:
	var view: SatchelView = null
	var t := 0.0
	var _rects: Array = []      # {rect, kind, index}
	var _arrows: Array = []     # {rect, step}
	## The find she has picked up, if any: its basket index, its word, and the
	## two buttons that go with it.
	var _chosen := -1
	var _keep_rect := Rect2()
	var _back_rect := Rect2()
	var _put_t := 0.0           ## the little "off it goes" flourish

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		size = get_viewport().get_visible_rect().size

	func _process(delta: float) -> void:
		t += delta
		if _put_t > 0.0:
			_put_t = maxf(0.0, _put_t - delta * 1.6)
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if not (event is InputEventMouseButton and event.pressed):
			return
		accept_event()
		var p: Vector2 = event.position

		# the two big choices come first — they sit over everything else
		if _chosen >= 0:
			if _keep_rect.has_point(p):
				_chosen = -1
				Sound.pop()
				return
			if _back_rect.has_point(p):
				GameState.put_back(_chosen)
				_chosen = -1
				_put_t = 1.0
				# a page that has just emptied should not strand her
				view.page = clampi(view.page, 0, view.pages() - 1)
				Sound.pop()
				return
			# anywhere else just puts it down again
			_chosen = -1
			Sound.pop()
			return

		for a in _arrows:
			if (a["rect"] as Rect2).has_point(p):
				view.page = clampi(view.page + int(a["step"]), 0, view.pages() - 1)
				Sound.pop()
				return
		for r in _rects:
			if (r["rect"] as Rect2).has_point(p):
				var kind := str(r["kind"])
				if kind.begins_with("photo_"):
					PhotoCard.show_photo(view, kind, kind.split("_")[1])
				else:
					_chosen = int(r["index"])
					Sound.pop()
				return
		# a tap on the empty surround puts the basket away
		view.closed.emit()

	func _draw() -> void:
		var vs := size
		size = get_viewport().get_visible_rect().size
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.2, 0.16, 0.1, 0.45))
		DrawKit.rounded_rect(self, Rect2(30, 30, vs.x - 60, vs.y - 60), 22.0, Color("fff8ec"))

		var font := ThemeDB.fallback_font
		var n := GameState.satchel.size()
		draw_string(font, Vector2(64, 92), "in my basket",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color("7a5f42"))
		# how many, as a numeral beside a little basket
		_basket(Vector2(vs.x - 210, 76), 1.0)
		draw_string(font, Vector2(vs.x - 176, 90), str(n),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color("6b4f38"))
		# how to make room, once she can read and the basket is filling up
		if n >= 10 and GameState.reading_level > 0 and _chosen < 0:
			draw_string(font, Vector2(64, 130), "tap a find to keep it or put it back",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("a2917a"))

		_rects.clear()
		_arrows.clear()
		if n == 0:
			# empty is a fine thing to be — say so kindly
			draw_string(font, Vector2(vs.x * 0.5 - 190, vs.y * 0.5), "nothing in here yet",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("a2917a"))
			DrawKit.heart(self, Vector2(vs.x * 0.5, vs.y * 0.5 + 70), 22.0, Color("f2a0b5"))
			return

		var first := view.page * SatchelView.PER_PAGE
		var last := mini(n, first + SatchelView.PER_PAGE)
		var cols := SatchelView.COLS
		var cw := minf(150.0, (vs.x - 220.0) / cols)
		var rows := int(ceil(float(last - first) / cols))
		var ch := minf(150.0, (vs.y - 300.0) / maxi(rows, 1))
		var ox := vs.x * 0.5 - (cols - 1) * cw * 0.5
		var oy := vs.y * 0.52 - (rows - 1) * ch * 0.5

		for i in range(first, last):
			var k := i - first
			var c := Vector2(ox + (k % cols) * cw, oy + floori(float(k) / cols) * ch)
			var r := Rect2(c.x - cw * 0.42, c.y - ch * 0.42, cw * 0.84, ch * 0.84)
			var kind := str(GameState.satchel[i])
			_rects.append({"rect": r, "kind": kind, "index": i})
			# a shelf plank under each row, like the museum
			if k % cols == 0:
				draw_rect(Rect2(ox - cw * 0.55, c.y + ch * 0.43, cols * cw, 8.0),
					Color("d9b485"))
			DrawKit.rounded_rect(self, r, 10.0, Color("f4ead6"))
			draw_set_transform(c, 0.0, Vector2.ONE)
			DrawKit.draw_find(self, kind, minf(r.size.x, r.size.y) * 0.30)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		# pages, if there is more than one basketful
		if view.pages() > 1:
			for spec in [[-1, 74.0], [1, vs.x - 74.0]]:
				var step := int(spec[0])
				var at := Vector2(float(spec[1]), vs.y * 0.52)
				var can := (step < 0 and view.page > 0) \
					or (step > 0 and view.page < view.pages() - 1)
				if not can:
					continue
				var ar := Rect2(at.x - 42, at.y - 42, 84, 84)
				_arrows.append({"rect": ar, "step": step})
				draw_circle(at, 34.0, Color("efe3cf"))
				# the point of the arrow goes in the direction it TAKES her
				draw_polygon(PackedVector2Array([
					at + Vector2(-9 * step, -15), at + Vector2(-9 * step, 15),
					at + Vector2(11 * step, 0),
				]), PackedColorArray([Color("8a7355")]))
			for i in view.pages():
				draw_circle(Vector2(vs.x * 0.5 - (view.pages() - 1) * 13.0 + i * 26.0,
					vs.y - 84.0), 8.0,
					Color("8a7355") if i == view.page else Color(0.72, 0.66, 0.56, 0.4))

		# a leaf or two drifting off, right after something went back
		if _put_t > 0.0:
			for i in 5:
				var a := i * 1.3 + t
				var fly := (1.0 - _put_t)
				DrawKit.ellipse(self, Vector2(vs.x * 0.5 + cos(a) * 90.0 * fly,
					vs.y * 0.52 - fly * 150.0 + sin(a) * 20.0), 9.0, 5.0,
					Color(0.55, 0.75, 0.5, _put_t * 0.8))

		if _chosen >= 0:
			_draw_choice(vs)

	## She has picked a find up: its name, and the two things she can do with
	## it. Big, worded, and impossible to trigger by accident.
	func _draw_choice(vs: Vector2) -> void:
		if _chosen >= GameState.satchel.size():
			_chosen = -1
			return
		var kind := str(GameState.satchel[_chosen])
		var font := ThemeDB.fallback_font
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.2, 0.16, 0.1, 0.5))
		var cr := Rect2(vs.x * 0.5 - 300.0, vs.y * 0.5 - 200.0, 600.0, 400.0)
		DrawKit.rounded_rect(self, cr, 26.0, Color("fff8ec"))
		DrawKit.rounded_rect_outline(self, cr, 26.0, Color("f0d9a8"), 3.0)

		draw_set_transform(Vector2(vs.x * 0.5, cr.position.y + 108.0), 0.0, Vector2.ONE)
		DrawKit.draw_find(self, kind, 46.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		var word := str(GameState.FIND_WORDS.get(kind, ""))
		if word != "":
			var ww := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 36).x
			draw_string(font, Vector2(vs.x * 0.5 - ww * 0.5, cr.position.y + 200.0), word,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color("6b4f38"))

		var by := cr.end.y - 108.0
		_keep_rect = Rect2(vs.x * 0.5 - 268.0, by, 250.0, 84.0)
		_back_rect = Rect2(vs.x * 0.5 + 18.0, by, 250.0, 84.0)
		# keep it — the safe one, and the one that looks like the obvious answer
		DrawKit.rounded_rect(self, _keep_rect, 18.0, Color("a8d5a2"))
		DrawKit.heart(self, Vector2(_keep_rect.position.x + 42.0, by + 42.0), 15.0,
			Color("fff8ec"))
		draw_string(font, Vector2(_keep_rect.position.x + 76.0, by + 54.0), "keep it",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("36552f"))
		# put it back — plainly labelled, never called throwing away
		DrawKit.rounded_rect(self, _back_rect, 18.0, Color("e8d4b8"))
		_leaf(Vector2(_back_rect.position.x + 42.0, by + 42.0), 16.0)
		draw_string(font, Vector2(_back_rect.position.x + 70.0, by + 54.0), "put it back",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("7a5f42"))

	func _leaf(c: Vector2, s: float) -> void:
		var pts := PackedVector2Array()
		for i in 12:
			var v := i / 11.0
			pts.append(c + Vector2(-s + 2.0 * s * v, -sin(v * PI) * s * 0.62))
		for i in 12:
			var v := 1.0 - i / 11.0
			pts.append(c + Vector2(-s + 2.0 * s * v, sin(v * PI) * s * 0.62))
		draw_colored_polygon(pts, Color("7fb87a"))
		draw_line(c + Vector2(-s, 0), c + Vector2(s, 0), Color("5d8f58"), 2.0)

	func _basket(c: Vector2, s: float) -> void:
		DrawKit.rounded_rect(self, Rect2(c.x - 22 * s, c.y - 12 * s, 44 * s, 26 * s),
			7.0 * s, Color("d9b98c"))
		DrawKit.rounded_rect(self, Rect2(c.x - 24 * s, c.y - 16 * s, 48 * s, 8 * s),
			4.0 * s, Color("e3c79c"))
		for i in 3:
			draw_line(c + Vector2((-14 + i * 14) * s, -10 * s),
				c + Vector2((-11 + i * 14) * s, 12 * s), Color("bb9764"), 2.0 * s)
