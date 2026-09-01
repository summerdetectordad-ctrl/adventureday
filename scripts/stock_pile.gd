class_name StockPile
extends Node2D
## The heap of building bits at the foot of the home tree. Everything she
## collects out in the meadow flies here and lands on the pile, so the stock
## is a thing you can SEE rather than a number in a menu — she does not have to
## remember she has seven planks, she can look at seven planks.
##
## Tapping it counts the pile out loud, which is the counting practice.

signal counted

const SLOTS := [
	{"kind": "stick",  "x": -46.0},
	{"kind": "plank",  "x": 6.0},
	{"kind": "rope",   "x": 58.0},
	{"kind": "timber", "x": 106.0},
	{"kind": "paint",  "x": 148.0},
]

var _bounce := 0.0
var _bounce_kind := ""


func tap_score(wp: Vector2) -> float:
	return clampf(1.0 - (wp - global_position - Vector2(50, -26.0)).length() / 110.0, 0.0, 1.0)


func try_tap(wp: Vector2) -> bool:
	return (wp - global_position - Vector2(50, -26.0)).length() < 110.0


func _process(delta: float) -> void:
	if _bounce > 0.0:
		_bounce = maxf(0.0, _bounce - delta * 2.6)
		queue_redraw()


## A material just landed — give that stack a little bounce.
func landed(kind: String) -> void:
	_bounce_kind = kind
	_bounce = 1.0
	queue_redraw()


## Count the pile out, one number puff per stack. Optional, and skippable by
## simply not tapping.
func count_out() -> void:
	var delay := 0.0
	for slot in SLOTS:
		var n: int = int(GameState.materials.get(slot["kind"], 0))
		if n <= 0:
			continue
		var at := position + Vector2(slot["x"], -_height(n) - 18.0)
		var parent := get_parent()
		get_tree().create_timer(delay).timeout.connect(func() -> void:
			if is_instance_valid(parent):
				Fx.float_number(parent, at, n)
				Sound.pop())
		delay += 0.34
	counted.emit()


func _height(n: int) -> float:
	return minf(72.0, n * 7.0)


func _draw() -> void:
	DrawKit.soft_shadow(self, Vector2(52, 4), 96.0, 0.13)
	for slot in SLOTS:
		var kind: String = slot["kind"]
		var n: int = int(GameState.materials.get(kind, 0))
		if n <= 0:
			continue
		var bx: float = slot["x"]
		var lift := 0.0
		if _bounce > 0.0 and kind == _bounce_kind:
			lift = sin(_bounce * PI) * 5.0
		_draw_stack(kind, bx, n, lift)


func _draw_stack(kind: String, bx: float, n: int, lift: float) -> void:
	var shown := mini(n, 10)
	match kind:
		"stick":
			for i in shown:
				var y := -2.0 - i * 6.0 - lift
				var wob := sin(i * 2.3) * 5.0
				draw_line(Vector2(bx - 20 + wob, y), Vector2(bx + 18 + wob, y - 4),
					Color("55381f"), 5.5)
				draw_line(Vector2(bx - 20 + wob, y), Vector2(bx + 18 + wob, y - 4),
					Color("8a6242"), 3.2)
		"plank":
			for i in shown:
				var y := -6.0 - i * 7.0 - lift
				draw_rect(Rect2(bx - 22, y, 44, 6), Color("c9a06c"))
				draw_rect(Rect2(bx - 22, y, 44, 2), Color("d9b485"))
				draw_line(Vector2(bx - 22, y + 6), Vector2(bx + 22, y + 6), Color("a97e54"), 1.2)
		"rope":
			for i in shown:
				var y := -10.0 - i * 9.0 - lift
				draw_arc(Vector2(bx, y), 13.0, 0, TAU, 18, Color("9a8055"), 5.0, true)
				draw_arc(Vector2(bx, y), 13.0, PI * 0.9, PI * 1.6, 8, Color("b39a6d"), 2.2, true)
		"timber":
			for i in shown:
				var y := -8.0 - i * 10.0 - lift
				draw_rect(Rect2(bx - 18, y, 36, 9), Color("a87c4e"))
				draw_rect(Rect2(bx - 18, y, 36, 3), Color("bb8f5e"))
				draw_rect(Rect2(bx - 18, y + 9, 36, 1.5), Color("87613a"))
		"paint":
			for i in mini(shown, 5):
				var y := -14.0 - i * 15.0 - lift
				var cols := [Color("e8918c"), Color("6fb3d2"), Color("8fc48a"), Color("ffd98a"), Color("c4b8e8")]
				DrawKit.rounded_rect(self, Rect2(bx - 11, y, 22, 15), 2.0, Color("b8b0a0"))
				draw_rect(Rect2(bx - 9, y + 2, 18, 5), cols[i % cols.size()])
				draw_arc(Vector2(bx, y), 9.0, PI, TAU, 8, Color("8a95a0"), 2.0, true)
	if n > 10:
		# too many to draw — say so with a number instead
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(bx - 8, -_height(n) - 20.0), str(n),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("6b4f38"))
