class_name BikeMap
extends CanvasLayer
## Where shall we go? Tapping the bike opens this: every world she knows, as a
## picture she can recognise before she can read the name under it. Pick one
## and she gets on and rides there.
##
## The world she is already in is shown too, marked so she can see it — a place
## she cannot pick is never simply missing, because a gap is confusing.
## Nothing here can go wrong: the only way out other than choosing is the exit
## button or a tap on the surround.

signal closed
signal chosen(destination: String)

## Every world the bike goes to, in the order they sit in the land: the market
## is west of home, Dino Land east, and the cove beyond that.
const PLACES := [
	{"id": "market", "word": "market"},
	{"id": "home", "word": "home"},
	{"id": "dino", "word": "dino land"},
	{"id": "cove", "word": "the cove"},
	{"id": "cave", "word": "the cave"},
]

## Which world this map was opened in, so it can be marked "you are here".
var here := "home"

var _exit: IconButton = null
var _body: Body = null


func _ready() -> void:
	layer = 44
	_body = Body.new()
	_body.map = self
	add_child(_body)
	_exit = IconButton.new("pack", 96.0)
	_exit.pressed.connect(func() -> void: closed.emit())
	add_child(_exit)
	_layout()
	get_viewport().size_changed.connect(_layout)


func _layout() -> void:
	if _exit != null:
		_exit.position = Vector2(get_viewport().get_visible_rect().size.x - 120, 24)


class Body extends Control:
	var map: BikeMap = null
	var t := 0.0
	var _cards: Array = []      # {rect, id}

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		size = get_viewport().get_visible_rect().size

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if not (event is InputEventMouseButton and event.pressed):
			return
		accept_event()
		var p: Vector2 = event.position
		for c in _cards:
			if (c["rect"] as Rect2).has_point(p):
				if str(c["id"]) == map.here:
					Sound.pop()          # already there — say so, do nothing
					return
				Sound.bell()
				map.chosen.emit(str(c["id"]))
				return
		map.closed.emit()

	func _draw() -> void:
		var vs := size
		size = get_viewport().get_visible_rect().size
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.2, 0.16, 0.1, 0.5))
		DrawKit.rounded_rect(self, Rect2(30, 30, vs.x - 60, vs.y - 60), 22.0, Color("fff8ec"))

		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(64, 96), "where shall we go?",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("6b4f38"))

		# the road they all sit on, so the map reads as one journey
		var road_y := vs.y * 0.52
		draw_line(Vector2(90, road_y + 96.0), Vector2(vs.x - 90, road_y + 96.0),
			Color("d9c3a8"), 8.0)
		for i in int((vs.x - 200) / 44.0):
			draw_line(Vector2(110.0 + i * 44.0, road_y + 96.0),
				Vector2(132.0 + i * 44.0, road_y + 96.0), Color("fff8ec"), 4.0)

		_cards.clear()
		var n := BikeMap.PLACES.size()
		var cw := minf(250.0, (vs.x - 180.0) / n)
		var ch := cw * 0.80
		for i in n:
			var place: Dictionary = BikeMap.PLACES[i]
			var id := str(place["id"])
			var cx := vs.x * 0.5 + (float(i) - (n - 1) * 0.5) * (cw + 18.0)
			var r := Rect2(cx - cw * 0.5, road_y - ch * 0.5, cw, ch)
			_cards.append({"rect": r, "id": id})
			var mine := id == map.here
			var lift := 0.0 if mine else sin(t * 2.0 + i * 0.7) * 3.0

			var card := Rect2(r.position + Vector2(0, lift), r.size)
			DrawKit.rounded_rect(self, Rect2(card.position + Vector2(0, 6), card.size),
				16.0, Color(0, 0, 0, 0.10))
			DrawKit.rounded_rect(self, card, 16.0,
				Color("efe6d2") if mine else Color("fffdf5"))
			DrawKit.rounded_rect_outline(self, card, 16.0,
				Color("cdbfa4") if mine else Color("f0d9a8"), 3.0)
			_thumb(id, Vector2(card.get_center().x, card.position.y + ch * 0.42),
				cw * 0.40, mine)

			var word := str(place["word"])
			var ww := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
			draw_string(font, Vector2(card.get_center().x - ww * 0.5, card.end.y - 18.0),
				word, HORIZONTAL_ALIGNMENT_LEFT, -1, 26,
				Color("a2917a") if mine else Color("6b4f38"))
			# a little marker on the road under each place
			draw_circle(Vector2(cx, road_y + 96.0), 9.0,
				Color("e8918c") if mine else Color("8fc48a"))
			if mine:
				# where she is standing right now
				var tag := "you are here"
				var tw := font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
				draw_string(font, Vector2(cx - tw * 0.5, road_y + 138.0), tag,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("a2917a"))

	## A little picture of each world — recognisable before it is readable.
	func _thumb(id: String, c: Vector2, s: float, dim: bool) -> void:
		var a := 0.45 if dim else 1.0
		match id:
			"home":
				draw_rect(Rect2(c.x - s, c.y - s * 0.2, s * 2.0, s * 0.7),
					Color(Color("a8d5a2"), a))
				draw_rect(Rect2(c.x - s * 0.12, c.y - s * 0.6, s * 0.24, s * 0.8),
					Color(Color("8a6a52"), a))
				DrawKit.blob(self, Vector2(c.x, c.y - s * 0.72), s * 0.62, s * 0.48,
					Color(Color("7fb87a"), a), 3)
				DrawKit.rounded_rect(self, Rect2(c.x - s * 0.34, c.y - s * 0.62,
					s * 0.68, s * 0.44), s * 0.1, Color(Color("8fb7d9"), a))
			"market":
				draw_rect(Rect2(c.x - s, c.y - s * 0.2, s * 2.0, s * 0.7),
					Color(Color("a8d5a2"), a))
				for sx in [-0.7, 0.7]:
					draw_rect(Rect2(c.x + s * sx - s * 0.04, c.y - s * 0.5,
						s * 0.08, s * 0.7), Color(Color("a97e54"), a))
				draw_rect(Rect2(c.x - s * 0.8, c.y - s * 0.62, s * 1.6, s * 0.2),
					Color(Color("f4ead6"), a))
				for i in 4:
					draw_rect(Rect2(c.x - s * 0.8 + i * s * 0.4, c.y - s * 0.62,
						s * 0.2, s * 0.2), Color(Color("c96b64"), a))
				DrawKit.rounded_rect(self, Rect2(c.x - s * 0.6, c.y - s * 0.34,
					s * 1.2, s * 0.12), 3.0, Color(Color("a97e54"), a))
			"dino":
				draw_rect(Rect2(c.x - s, c.y - s * 0.2, s * 2.0, s * 0.7),
					Color(Color("cdbb8e"), a))
				# a volcano behind, and a long neck in front
				draw_colored_polygon(PackedVector2Array([
					Vector2(c.x + s * 0.2, c.y - s * 0.18),
					Vector2(c.x + s * 0.75, c.y - s * 0.9),
					Vector2(c.x + s * 1.0, c.y - s * 0.18),
				]), Color(Color("9c8a72"), a))
				DrawKit.ellipse(self, Vector2(c.x - s * 0.3, c.y - s * 0.3),
					s * 0.42, s * 0.22, Color(Color("7fa86e"), a))
				draw_line(Vector2(c.x - s * 0.55, c.y - s * 0.4),
					Vector2(c.x - s * 0.75, c.y - s * 0.92), Color(Color("7fa86e"), a),
					s * 0.14)
				draw_circle(Vector2(c.x - s * 0.78, c.y - s * 0.96), s * 0.1,
					Color(Color("7fa86e"), a))
			"cave":
				draw_rect(Rect2(c.x - s, c.y - s * 0.2, s * 2.0, s * 0.7),
					Color(Color("cdbb8e"), a))
				DrawKit.blob(self, Vector2(c.x, c.y - s * 0.5), s * 0.95, s * 0.7,
					Color(Color("9c8a72"), a), 5)
				# the dark mouth, with two little eyes glinting inside it
				draw_colored_polygon(PackedVector2Array([
					Vector2(c.x - s * 0.42, c.y - s * 0.18),
					Vector2(c.x - s * 0.34, c.y - s * 0.76),
					Vector2(c.x + s * 0.34, c.y - s * 0.76),
					Vector2(c.x + s * 0.42, c.y - s * 0.18),
				]), Color(Color("3e352f"), a))
				draw_circle(Vector2(c.x - s * 0.12, c.y - s * 0.46), s * 0.08,
					Color(Color("ffd98a"), a))
				draw_circle(Vector2(c.x + s * 0.16, c.y - s * 0.46), s * 0.08,
					Color(Color("ffd98a"), a))
			"cove":
				draw_rect(Rect2(c.x - s, c.y - s * 0.5, s * 2.0, s * 0.42),
					Color(Color("7fb5c9"), a))
				draw_rect(Rect2(c.x - s, c.y - s * 0.1, s * 2.0, s * 0.6),
					Color(Color("e8d9b8"), a))
				# a little ship on the water
				draw_colored_polygon(PackedVector2Array([
					Vector2(c.x - s * 0.42, c.y - s * 0.22),
					Vector2(c.x + s * 0.42, c.y - s * 0.22),
					Vector2(c.x + s * 0.28, c.y - s * 0.08),
					Vector2(c.x - s * 0.28, c.y - s * 0.08),
				]), Color(Color("6b4f38"), a))
				draw_line(Vector2(c.x, c.y - s * 0.24), Vector2(c.x, c.y - s * 0.7),
					Color(Color("8a7355"), a), s * 0.06)
				draw_colored_polygon(PackedVector2Array([
					Vector2(c.x, c.y - s * 0.68), Vector2(c.x + s * 0.32, c.y - s * 0.42),
					Vector2(c.x, c.y - s * 0.28),
				]), Color(Color("f4ead6"), a))
