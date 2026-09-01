class_name TopBar
extends Control
## The counters across the top: fruit, building materials, and the thirst and
## hunger meters.
##
## THE METERS NEVER PUNISH. When one empties, exactly one thing happens — a
## friendly bubble appears over Summer suggesting a drink or a snack, and the
## counter glows gently. She does not slow down, nothing is taken away, no sad
## face, no sound sting. They exist to suggest a nice thing to do, never to nag.

const THIRST_SECONDS := 300.0
const HUNGER_SECONDS := 600.0

const PILL_H := 68.0       ## icon row on top, the word underneath
const ICON_ROW := 46.0     ## where the icon and number sit inside the pill
const GAP := 12.0

## The word under each counter, lowercase like the museum tags. Optional
## flavour — the icon and the numeral carry the meaning on their own — but it
## puts the words she is learning in front of her all session.
const NAMES := {
	"fruit": "fruit", "thirst": "drink", "hunger": "food",
	"stick": "stick", "plank": "plank", "rope": "rope",
	"timber": "wood", "paint": "paint", "seed": "seed",
}

var _t := 0.0
var _fruit_pop := 0.0
var _mat_pop := 0.0
var _pill_rects: Array = []   # {rect, id}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_WIDE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 96)


func _process(delta: float) -> void:
	_t += delta
	_fruit_pop = maxf(0.0, _fruit_pop - delta * 2.4)
	_mat_pop = maxf(0.0, _mat_pop - delta * 2.4)
	queue_redraw()


func bump_fruit() -> void:
	_fruit_pop = 1.0


func bump_materials() -> void:
	_mat_pop = 1.0


## The bar is a read-out, but a tap on it should be swallowed rather than
## sending Summer walking off toward the top of the screen.
func tap_at(p: Vector2) -> bool:
	for pr in _pill_rects:
		if pr["rect"].has_point(p):
			return true
	return false


## One counter's word, centred under it.
func _label(text: String, cx: float, top: float, font: Font) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(font, Vector2(cx - w / 2.0, top + PILL_H - 8.0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("9a8a72"))


func _draw() -> void:
	var vs := get_viewport().get_visible_rect().size
	size = Vector2(vs.x, 96)
	_pill_rects.clear()
	var font := ThemeDB.fallback_font

	# Left cluster starts clear of the satchel button, right cluster clear of
	# mute — tablet cameras and rounded corners eat the very corners.
	var meters_left := vs.x - 118.0 - 2.0 * (104.0 + GAP)
	var x := 132.0
	x = _draw_fruit(x, font)
	x = _draw_materials(x, font, meters_left - x - GAP)

	var rx := vs.x - 118.0
	rx = _draw_meter(rx, "hunger", GameState.hunger_accum, HUNGER_SECONDS, font)
	rx = _draw_meter(rx, "thirst", GameState.thirst_accum, THIRST_SECONDS, font)


func _pill(r: Rect2, id: String, glow := 0.0) -> void:
	_pill_rects.append({"rect": r, "id": id})
	DrawKit.rounded_rect(self, Rect2(r.position + Vector2(0, 2), r.size), PILL_H * 0.5,
		Color(0, 0, 0, 0.07))
	DrawKit.rounded_rect(self, r, PILL_H * 0.5, Color(1, 1, 1, 0.9))
	if glow > 0.01:
		draw_arc(r.get_center(), r.size.x * 0.5, 0, TAU, 30,
			Color(1.0, 0.85, 0.54, glow), 3.0, true)


func _draw_fruit(x: float, font: Font) -> float:
	var n := GameState.fruit
	var w := 96.0
	var r := Rect2(x, 14, w, PILL_H)
	var pop := 1.0 + sin(_fruit_pop * PI) * 0.14
	_pill(r, "fruit")
	_label(NAMES["fruit"], r.get_center().x, r.position.y, font)
	var c := r.position + Vector2(30, ICON_ROW * 0.5)
	# an apple, drawn rather than written
	draw_circle(c, 13.0 * pop, Color("b8483f"))
	draw_circle(c + Vector2(0, -1), 12.0 * pop, Color("e05c50"))
	draw_circle(c + Vector2(-4, -5), 4.0, Color("f2a09a"))
	draw_line(c + Vector2(0, -12), c + Vector2(1, -18), Color("6f5a3f"), 2.0)
	DrawKit.ellipse(self, c + Vector2(6, -17), 5.0, 2.5, Color("8cc188"))
	draw_string(font, r.position + Vector2(52, ICON_ROW * 0.5 + 10), str(n),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color("6b4f38"))
	return x + w + GAP


## EVERY material, always — she should be able to see the whole stock at a
## glance rather than having to find a hidden toggle.
func _draw_materials(x: float, font: Font, room: float) -> float:
	var kinds := BuildDefs.MATERIALS
	# share out whatever width is going, so a narrower tablet still fits
	var cell := clampf((room - 44.0) / kinds.size(), 46.0, 64.0)
	var w := 44.0 + kinds.size() * cell
	var r := Rect2(x, 14, w, PILL_H)
	_pill(r, "materials", _mat_pop * 0.5)
	var cx := r.position.x + 22.0 + cell * 0.5
	for k in kinds:
		var n: int = int(GameState.materials.get(k, 0))
		var num := str(n)
		var nw := font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, 23).x
		_draw_material_icon(Vector2(cx - nw * 0.5 - 3.0, r.position.y + ICON_ROW * 0.5), k)
		draw_string(font, Vector2(cx - nw * 0.5 + 13.0, r.position.y + ICON_ROW * 0.5 + 9), num,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 23,
			Color("6b4f38") if n > 0 else Color("b5a68e"))
		_label(str(NAMES.get(k, k)), cx, r.position.y, font)
		cx += cell
	return x + w + GAP


func _draw_material_icon(c: Vector2, kind: String) -> void:
	match kind:
		"stick":
			draw_line(c + Vector2(-11, 5), c + Vector2(10, -6), Color("55381f"), 6.0)
			draw_line(c + Vector2(-11, 5), c + Vector2(10, -6), Color("8a6242"), 3.4)
		"plank":
			draw_rect(Rect2(c.x - 12, c.y - 5, 24, 10), Color("c9a06c"))
			draw_rect(Rect2(c.x - 12, c.y - 5, 24, 3.4), Color("d9b485"))
		"rope":
			draw_arc(c, 9.0, 0, TAU, 16, Color("9a8055"), 4.4, true)
			draw_arc(c, 9.0, PI * 0.9, PI * 1.6, 8, Color("b39a6d"), 2.0, true)
		"timber":
			draw_rect(Rect2(c.x - 11, c.y - 6, 22, 12), Color("a87c4e"))
			draw_rect(Rect2(c.x - 11, c.y - 6, 22, 3.4), Color("bb8f5e"))
		"paint":
			DrawKit.rounded_rect(self, Rect2(c.x - 8, c.y - 7, 16, 14), 2.0, Color("b8b0a0"))
			draw_rect(Rect2(c.x - 6, c.y - 5, 12, 4), Color("e8918c"))
			draw_arc(c + Vector2(0, -7), 7.0, PI, TAU, 8, Color("8a95a0"), 2.0, true)
		"seed":
			# a paper packet with a flower on the front
			DrawKit.rounded_rect(self, Rect2(c.x - 8, c.y - 9, 16, 18), 2.0, Color("efe3c8"))
			draw_rect(Rect2(c.x - 8, c.y - 9, 16, 4), Color("d8c9a4"))
			draw_circle(c + Vector2(0, 1), 4.0, Color("e8918c"))
			draw_circle(c + Vector2(0, 1), 1.6, Color("ffe6b3"))


## A meter that only ever suggests. Full is a happy meter; empty just glows and
## puts a bubble over her head — never a penalty.
func _draw_meter(rx: float, kind: String, accum: float, span: float, font: Font) -> float:
	var w := 104.0
	var r := Rect2(rx - w, 14, w, PILL_H)
	var left := clampf(1.0 - accum / span, 0.0, 1.0)
	var empty := left <= 0.001
	var glow := (0.30 + 0.22 * sin(_t * 2.2)) if empty else 0.0
	_pill(r, kind, glow)
	_label(str(NAMES.get(kind, kind)), r.get_center().x, r.position.y, font)

	var c := r.position + Vector2(28, ICON_ROW * 0.5)
	if kind == "thirst":
		# a water drop
		draw_polygon(PackedVector2Array([
			c + Vector2(0, -13), c + Vector2(9, 2), c + Vector2(-9, 2),
		]), PackedColorArray([Color("6fb3d2")]))
		draw_circle(c + Vector2(0, 3), 9.0, Color("6fb3d2"))
		draw_circle(c + Vector2(-3, 1), 3.0, Color("bfe2f2"))
	else:
		# a sandwich
		draw_polygon(PackedVector2Array([
			c + Vector2(-11, -2), c + Vector2(11, -2), c + Vector2(9, -10), c + Vector2(-9, -10),
		]), PackedColorArray([Color("e8c88a")]))
		draw_rect(Rect2(c.x - 11, c.y - 2, 22, 4), Color("8fc48a"))
		draw_rect(Rect2(c.x - 11, c.y + 2, 22, 6), Color("e8c88a"))

	# the bar itself
	var bar := Rect2(r.position.x + 46, r.position.y + ICON_ROW * 0.5 - 8, 44, 16)
	DrawKit.rounded_rect(self, bar, 8.0, Color("e4dbc8"))
	if left > 0.0:
		var fill := Rect2(bar.position, Vector2(maxf(bar.size.y, bar.size.x * left), bar.size.y))
		var col := Color("6fb3d2") if kind == "thirst" else Color("e8b06a")
		DrawKit.rounded_rect(self, fill, 8.0, col)
	elif empty:
		# a soft invitation, not an alarm
		DrawKit.heart(self, bar.get_center(), 7.0, Color("f2a0b5"))
	return rx - w - GAP
