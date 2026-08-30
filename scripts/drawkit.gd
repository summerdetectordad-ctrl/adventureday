class_name DrawKit
## Shared code-drawn art helpers. Everything in the game is drawn with these —
## no external asset files. Swap real illustrations in later by replacing the
## _draw() bodies that call into here; game logic never touches this file.

const OUTLINE := Color("00000014")


static func rounded_rect_points(rect: Rect2, radius: float) -> PackedVector2Array:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var pts := PackedVector2Array()
	var corners := [
		[Vector2(rect.position.x + r, rect.position.y + r), PI],
		[Vector2(rect.end.x - r, rect.position.y + r), PI * 1.5],
		[Vector2(rect.end.x - r, rect.end.y - r), 0.0],
		[Vector2(rect.position.x + r, rect.end.y - r), PI * 0.5],
	]
	for corner in corners:
		var center: Vector2 = corner[0]
		var start: float = corner[1]
		for i in 9:
			var a: float = start + (PI * 0.5) * i / 8.0
			pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts


static func rounded_rect(c: CanvasItem, rect: Rect2, radius: float, col: Color) -> void:
	c.draw_polygon(rounded_rect_points(rect, radius), PackedColorArray([col]))


static func rounded_rect_outline(c: CanvasItem, rect: Rect2, radius: float, col: Color, width: float) -> void:
	var pts := rounded_rect_points(rect, radius)
	pts.append(pts[0])
	c.draw_polyline(pts, col, width, true)


static func ellipse(c: CanvasItem, center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	c.draw_polygon(pts, PackedColorArray([col]))


static func star(c: CanvasItem, pos: Vector2, s: float, col: Color, points: int = 5) -> void:
	var pts := PackedVector2Array()
	for i in points * 2:
		var r := s if i % 2 == 0 else s * 0.45
		var a := -PI / 2 + PI * i / points
		pts.append(pos + Vector2(cos(a), sin(a)) * r)
	c.draw_polygon(pts, PackedColorArray([col]))


static func heart(c: CanvasItem, pos: Vector2, s: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 26:
		var a := TAU * i / 26.0
		var x := 16.0 * pow(sin(a), 3.0)
		var y := -(13.0 * cos(a) - 5.0 * cos(2 * a) - 2.0 * cos(3 * a) - cos(4 * a))
		pts.append(pos + Vector2(x, y) * (s / 16.0))
	c.draw_polygon(pts, PackedColorArray([col]))


# --- Affirmation icons -------------------------------------------------------

static func draw_icon(c: CanvasItem, kind: String, s: float) -> void:
	match kind:
		"heart":
			heart(c, Vector2.ZERO, s * 0.9, Color("f2a0b5"))
			heart(c, Vector2(-s * 0.12, -s * 0.1), s * 0.35, Color("f9c8d4"))
		"star":
			star(c, Vector2.ZERO, s, Color("ffd98a"))
			star(c, Vector2(s * 0.55, -s * 0.6), s * 0.35, Color("ffe6b3"))
		"sun":
			for i in 8:
				var a := TAU * i / 8.0
				c.draw_line(Vector2.from_angle(a) * s * 0.62, Vector2.from_angle(a) * s, Color("ffd98a"), s * 0.14)
			c.draw_circle(Vector2.ZERO, s * 0.5, Color("ffd98a"))
			c.draw_circle(Vector2.ZERO, s * 0.38, Color("ffe6b3"))
		"flower":
			c.draw_line(Vector2(0, s * 0.2), Vector2(0, s), Color("8fc48a"), s * 0.12)
			for i in 6:
				var a := TAU * i / 6.0
				c.draw_circle(Vector2.from_angle(a) * s * 0.42, s * 0.3, Color("f2b8cf"))
			c.draw_circle(Vector2.ZERO, s * 0.26, Color("ffd98a"))
		"rainbow":
			var cols := [Color("f2a0a0"), Color("ffd98a"), Color("a8d5a2"), Color("a9c9e8")]
			for i in cols.size():
				c.draw_arc(Vector2(0, s * 0.4), s * (1.0 - i * 0.17), PI, TAU, 24, cols[i], s * 0.15, true)
		"bird":
			ellipse(c, Vector2(-s * 0.05, s * 0.12), s * 0.55, s * 0.42, Color("8fb7d9"))
			c.draw_circle(Vector2(s * 0.38, -s * 0.25), s * 0.3, Color("8fb7d9"))
			c.draw_polygon(PackedVector2Array([
				Vector2(s * 0.62, -s * 0.3), Vector2(s * 0.92, -s * 0.22), Vector2(s * 0.62, -s * 0.14),
			]), PackedColorArray([Color("ffc46b")]))
			ellipse(c, Vector2(-s * 0.15, s * 0.05), s * 0.3, s * 0.2, Color("b3d0e8"))
			c.draw_circle(Vector2(s * 0.42, -s * 0.32), s * 0.06, Color("3a3a44"))
			c.draw_polygon(PackedVector2Array([
				Vector2(-s * 0.5, s * 0.1), Vector2(-s * 0.95, -s * 0.1), Vector2(-s * 0.85, s * 0.3),
			]), PackedColorArray([Color("7aa6cc")]))
		"leaf":
			var pts := PackedVector2Array()
			for i in 13:
				var u := i / 12.0
				pts.append(Vector2(lerpf(-s, s, u), -sin(PI * u) * s * 0.5))
			for i in 13:
				var u := 1.0 - i / 12.0
				pts.append(Vector2(lerpf(-s, s, u), sin(PI * u) * s * 0.5))
			c.draw_polygon(pts, PackedColorArray([Color("a8d5a2")]))
			c.draw_line(Vector2(-s * 0.9, 0), Vector2(s * 0.75, 0), Color("8fc48a"), s * 0.08)
		"butterfly":
			c.draw_circle(Vector2(-s * 0.42, -s * 0.28), s * 0.4, Color("c4a8e0"))
			c.draw_circle(Vector2(s * 0.42, -s * 0.28), s * 0.4, Color("c4a8e0"))
			c.draw_circle(Vector2(-s * 0.34, s * 0.3), s * 0.28, Color("f2b8cf"))
			c.draw_circle(Vector2(s * 0.34, s * 0.3), s * 0.28, Color("f2b8cf"))
			ellipse(c, Vector2.ZERO, s * 0.12, s * 0.5, Color("6e5a48"))
			c.draw_line(Vector2(-s * 0.05, -s * 0.45), Vector2(-s * 0.25, -s * 0.75), Color("6e5a48"), s * 0.05)
			c.draw_line(Vector2(s * 0.05, -s * 0.45), Vector2(s * 0.25, -s * 0.75), Color("6e5a48"), s * 0.05)
		"cloud":
			var col := Color("cfdde8")
			c.draw_circle(Vector2(0, -s * 0.15), s * 0.5, col)
			c.draw_circle(Vector2(-s * 0.5, s * 0.08), s * 0.35, col)
			c.draw_circle(Vector2(s * 0.5, s * 0.08), s * 0.35, col)
			rounded_rect(c, Rect2(-s * 0.65, -s * 0.05, s * 1.3, s * 0.48), s * 0.2, col)
		_:
			star(c, Vector2.ZERO, s, Color("ffd98a"))


# --- Museum finds ------------------------------------------------------------

static func draw_find(c: CanvasItem, kind: String, s: float) -> void:
	match kind:
		"ammonite":
			c.draw_circle(Vector2.ZERO, s, Color("c9a06c"))
			c.draw_circle(Vector2.ZERO, s * 0.94, Color("d9b485"))
			var pts := PackedVector2Array()
			for i in 80:
				var a := i * 0.24
				var r := s * 0.06 + s * 0.82 * (i / 79.0)
				pts.append(Vector2(cos(a), sin(a)) * r)
			c.draw_polyline(pts, Color("8a6a44"), maxf(2.0, s * 0.09), true)
		"trilobite":
			ellipse(c, Vector2.ZERO, s * 0.62, s * 0.9, Color("9c8b74"))
			ellipse(c, Vector2(0, -s * 0.5), s * 0.58, s * 0.38, Color("8a7a64"))
			for i in 5:
				var y := -s * 0.1 + i * s * 0.22
				var w := s * 0.6 * (1.0 - i * 0.13)
				c.draw_line(Vector2(-w, y), Vector2(w, y), Color("8a7a64"), maxf(2.0, s * 0.07))
			c.draw_circle(Vector2(-s * 0.24, -s * 0.52), s * 0.08, Color("5c5044"))
			c.draw_circle(Vector2(s * 0.24, -s * 0.52), s * 0.08, Color("5c5044"))
		"dino_bone":
			var col := Color("efe6d0")
			var w := s * 1.5
			var h := s * 0.34
			c.draw_rect(Rect2(-w / 2, -h / 2, w, h), col)
			for sx in [-1.0, 1.0]:
				c.draw_circle(Vector2(sx * w / 2, -h * 0.5), h * 0.72, col)
				c.draw_circle(Vector2(sx * w / 2, h * 0.5), h * 0.72, col)
			c.draw_line(Vector2(-w * 0.25, 0), Vector2(w * 0.25, 0), Color("ddd2b8"), maxf(2.0, s * 0.06))
		"dino_egg":
			ellipse(c, Vector2.ZERO, s * 0.62, s * 0.82, Color("e8e2cf"))
			ellipse(c, Vector2(-s * 0.12, -s * 0.12), s * 0.44, s * 0.6, Color("f2eddc"))
			for off in [Vector2(-0.25, 0.3), Vector2(0.25, -0.05), Vector2(-0.05, -0.45), Vector2(0.3, 0.45), Vector2(-0.38, -0.15)]:
				c.draw_circle(off * s, s * 0.07, Color("b8ac8c"))
		"shark_tooth":
			c.draw_polygon(PackedVector2Array([
				Vector2(-s * 0.6, -s * 0.35), Vector2(s * 0.6, -s * 0.35),
				Vector2(s * 0.12, s * 0.8), Vector2(-s * 0.12, s * 0.8),
			]), PackedColorArray([Color("e8e2d5")]))
			rounded_rect(c, Rect2(-s * 0.68, -s * 0.62, s * 1.36, s * 0.34), s * 0.14, Color("c2baa9"))
			c.draw_line(Vector2(0, -s * 0.25), Vector2(0, s * 0.55), Color("d4ccbc"), maxf(2.0, s * 0.07))
		"roman_coin":
			c.draw_circle(Vector2.ZERO, s * 0.85, Color("c39c44"))
			c.draw_circle(Vector2.ZERO, s * 0.72, Color("d9b45c"))
			c.draw_circle(Vector2(-s * 0.05, -s * 0.02), s * 0.3, Color("c39c44"))
			c.draw_polygon(PackedVector2Array([
				Vector2(s * 0.18, -s * 0.12), Vector2(s * 0.3, -s * 0.02), Vector2(s * 0.18, s * 0.06),
			]), PackedColorArray([Color("c39c44")]))
			c.draw_rect(Rect2(-s * 0.2, s * 0.24, s * 0.32, s * 0.14), Color("c39c44"))
			c.draw_arc(Vector2.ZERO, s * 0.6, PI * 0.7, PI * 1.3, 10, Color("b08a38"), maxf(2.0, s * 0.06))
		"pirate_coin":
			c.draw_circle(Vector2.ZERO, s * 0.85, Color("d9a940"))
			c.draw_circle(Vector2.ZERO, s * 0.7, Color("f0c96a"))
			star(c, Vector2.ZERO, s * 0.4, Color("d9a940"))
			c.draw_circle(Vector2(-s * 0.3, -s * 0.35), s * 0.1, Color("fae3a8"))
		"gem":
			c.draw_polygon(PackedVector2Array([
				Vector2(0, -s * 0.8), Vector2(s * 0.7, -s * 0.15), Vector2(0, s * 0.8), Vector2(-s * 0.7, -s * 0.15),
			]), PackedColorArray([Color("e0a0c8")]))
			c.draw_polygon(PackedVector2Array([
				Vector2(0, -s * 0.8), Vector2(s * 0.3, -s * 0.15), Vector2(0, s * 0.3), Vector2(-s * 0.3, -s * 0.15),
			]), PackedColorArray([Color("f0c4dd")]))
			star(c, Vector2(s * 0.3, -s * 0.45), s * 0.16, Color.WHITE)
		"old_key":
			var col := Color("c9a25c")
			c.draw_arc(Vector2(-s * 0.45, 0), s * 0.32, 0, TAU, 20, col, maxf(3.0, s * 0.16), true)
			c.draw_rect(Rect2(-s * 0.12, -s * 0.07, s * 0.95, s * 0.14), col)
			c.draw_rect(Rect2(s * 0.6, 0, s * 0.12, s * 0.28), col)
			c.draw_rect(Rect2(s * 0.38, 0, s * 0.12, s * 0.22), col)
		_:
			c.draw_circle(Vector2.ZERO, s * 0.7, Color("c9a06c"))
