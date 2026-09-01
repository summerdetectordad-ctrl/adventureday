class_name Backpack
extends Node2D
## The fan of item bubbles that opens above Summer when her backpack is
## tapped. Two rows of big friendly icons; tapping one uses that item.
## Icons only — no reading needed.

const ITEMS := ["detector", "net", "camera", "whistle", "sketchpad", "map", "bottle", "picnic"]
const COLS := 4
const SPACING := 104.0
const ROW_Y := [-172.0, -276.0]

## Which items this pack shows. Away from the meadow the detector and net are
## left out — there is nothing to sweep for or catch, and a tool that does
## nothing is worse than one that is not offered.
var items: Array = ITEMS
var held_tool := ""    # the equipped tool gets a soft golden ring
var t := 0.0


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


## Which item bubble (if any) is under this world position?
func item_at(wp: Vector2) -> String:
	for i in items.size():
		if (wp - (global_position + _pos(i))).length() < 50.0:
			return str(items[i])
	return ""


func _pos(i: int) -> Vector2:
	var cols := mini(COLS, maxi(1, items.size()))
	var row := floori(float(i) / cols)
	var col := i % cols
	# centre each row by how many are actually ON it, so a short last row
	# does not sit off to the left
	var on_row := mini(cols, items.size() - row * cols)
	return Vector2((col - (on_row - 1) * 0.5) * SPACING, ROW_Y[mini(row, ROW_Y.size() - 1)])


func _draw() -> void:
	for i in items.size():
		var p := _pos(i)
		var r := 44.0 + sin(t * 3.0 + i * 0.7) * 1.5
		draw_circle(p + Vector2(0, 4), r, Color(0, 0, 0, 0.07))
		draw_circle(p, r, Color(1, 1, 1, 0.93))
		if items[i] == held_tool:
			draw_arc(p, r - 4.0, 0, TAU, 32, Color("ffd98a"), 5.0, true)
		draw_set_transform(p, 0.0, Vector2.ONE)
		_icon(str(items[i]))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _icon(id: String) -> void:
	match id:
		"detector":
			draw_line(Vector2(-14, -20), Vector2(10, 10), Color("8d99ae"), 5.0)
			draw_line(Vector2(-14, -20), Vector2(-21, -25), Color("8d99ae"), 4.0)
			DrawKit.ellipse(self, Vector2(14, 15), 14.0, 6.0, Color("6f7f96"))
			DrawKit.ellipse(self, Vector2(14, 13.5), 10.0, 4.0, Color("9fb0c4"))
		"net":
			draw_line(Vector2(-8, 26), Vector2(2, -4), Color("a97e54"), 4.5)
			draw_arc(Vector2(6, -12), 14.0, 0, TAU, 16, Color("8fb7d9"), 3.5, true)
			for i in 3:
				var my := -6.0 + i * 6.0
				draw_arc(Vector2(6, -12 + my), maxf(3.0, 14.0 - absf(my)), PI * 0.15, PI * 0.85, 8,
					Color("a9c9e8"), 1.8, true)
		"camera":
			DrawKit.rounded_rect(self, Rect2(-20, -12, 40, 28), 7.0, Color("7a8b9c"))
			DrawKit.rounded_rect(self, Rect2(-7, -18, 17, 8), 3.0, Color("7a8b9c"))
			draw_circle(Vector2(0, 2), 10.0, Color("9fb0c4"))
			draw_circle(Vector2(0, 2), 6.0, Color("5c6b7a"))
			draw_circle(Vector2(-2.5, 0), 2.0, Color(1, 1, 1, 0.8))
			draw_circle(Vector2(14, -7), 2.4, Color("ffd98a"))
		"whistle":
			DrawKit.rounded_rect(self, Rect2(-18, -8, 30, 16), 7.0, Color("e8918c"))
			draw_circle(Vector2(8, 10), 9.0, Color("e8918c"))
			draw_circle(Vector2(-14, -12), 5.0, Color("d9b45c"))
			draw_circle(Vector2(-14, -12), 2.4, Color("fff8ec"))
			for i in 2:
				draw_arc(Vector2(20, -6), 6.0 + i * 6.0, -0.7, 0.7, 8, Color("a9c9e8"), 2.0, true)
		"sketchpad":
			DrawKit.rounded_rect(self, Rect2(-18, -22, 36, 44), 5.0, Color("fffdf5"))
			DrawKit.rounded_rect_outline(self, Rect2(-18, -22, 36, 44), 5.0, Color("d9c9a8"), 2.5)
			draw_circle(Vector2(8, -10), 6.0, Color("ffd98a"))
			draw_line(Vector2(-12, 12), Vector2(-2, 0), Color("8fc48a"), 3.0)
			draw_line(Vector2(-2, 0), Vector2(8, 12), Color("8fc48a"), 3.0)
			DrawKit.heart(self, Vector2(-9, -10), 5.0, Color("f2a0b5"))
			# a little crayon resting on it
			draw_line(Vector2(4, 22), Vector2(18, 8), Color("e8918c"), 5.0)
			draw_polygon(PackedVector2Array([
				Vector2(18, 8), Vector2(23, 6), Vector2(20, 3),
			]), PackedColorArray([Color("e8918c")]))
		"map":
			for i in 3:
				var mx := -21.0 + i * 14.0
				var lift := 4.0 if i == 1 else 0.0
				draw_polygon(PackedVector2Array([
					Vector2(mx, -16 - lift), Vector2(mx + 14, -16 + lift - 4),
					Vector2(mx + 14, 18 + lift - 4), Vector2(mx, 18 - lift),
				]), PackedColorArray([Color("fff2d9") if i % 2 == 0 else Color("f7e7c4")]))
			for i in 4:
				draw_circle(Vector2(-16.0 + i * 9.0, 2.0 - i * 3.0), 1.6, Color("b08a38"))
			draw_line(Vector2(14, -8), Vector2(20, -2), Color("e8918c"), 3.0)
			draw_line(Vector2(20, -8), Vector2(14, -2), Color("e8918c"), 3.0)
		"bottle":
			DrawKit.rounded_rect(self, Rect2(-11, -12, 22, 34), 8.0, Color("a9d7e8"))
			draw_rect(Rect2(-11, 2, 22, 16), Color("8ac0d6"))
			DrawKit.rounded_rect(self, Rect2(-7, -24, 14, 12), 4.0, Color("7a8b9c"))
			draw_circle(Vector2(-4, -4), 2.5, Color(1, 1, 1, 0.7))
		"picnic":
			DrawKit.rounded_rect(self, Rect2(-20, -14, 40, 9), 4.0, Color("e8c88a"))
			draw_rect(Rect2(-18, -5, 36, 4), Color("f2b8cf"))
			draw_rect(Rect2(-18, -1, 36, 4), Color("ffd98a"))
			draw_rect(Rect2(-18, 3, 36, 4), Color("a8d5a2"))
			DrawKit.rounded_rect(self, Rect2(-20, 7, 40, 9), 4.0, Color("e8c88a"))
		_:
			DrawKit.star(self, Vector2.ZERO, 18.0, Color("ffd98a"))
