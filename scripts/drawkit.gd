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


# --- Painterly helpers -------------------------------------------------------
# Light comes from the upper right (the sun in SkyBackdrop): highlights sit
# up-and-right, shade sits down-and-left, contact shadows lean slightly left.

## Vertical gradient rectangle.
static func vgrad(c: CanvasItem, rect: Rect2, top: Color, bottom: Color) -> void:
	c.draw_polygon(PackedVector2Array([
		rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y),
	]), PackedColorArray([top, top, bottom, bottom]))


## Organic wobbly ellipse — foliage, rocks, clouds. Deterministic per seed so
## animated redraws never flicker.
static func blob_points(center: Vector2, rx: float, ry: float, seed_v: int, wobble := 0.14, points := 20) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var offs: Array = []
	for i in points:
		offs.append(1.0 + rng.randf_range(-wobble, wobble))
	var pts := PackedVector2Array()
	for i in points:
		# neighbour-averaged so the edge undulates instead of spiking
		var o: float = (offs[i] + offs[(i + 1) % points] + offs[(i + points - 1) % points]) / 3.0
		var a := TAU * i / points
		pts.append(center + Vector2(cos(a) * rx * o, sin(a) * ry * o))
	return pts


static func blob(c: CanvasItem, center: Vector2, rx: float, ry: float, col: Color, seed_v: int, wobble := 0.14) -> void:
	c.draw_polygon(blob_points(center, rx, ry, seed_v, wobble), PackedColorArray([col]))


## Soft layered contact shadow on the ground under a thing.
static func soft_shadow(c: CanvasItem, center: Vector2, rx: float, strength := 0.14) -> void:
	var ry := rx * 0.28
	for i in 3:
		var k := 1.0 - i * 0.3
		ellipse(c, center + Vector2(-rx * 0.06, 0), rx * k, ry * k,
			Color(0.25, 0.18, 0.1, strength * 0.45))


## A full shaded tree canopy: dark under-mass low-left, sunlit clusters
## up-right, a few dappled leaf glints.
static func canopy(c: CanvasItem, center: Vector2, rx: float, ry: float, base: Color, seed_v: int) -> void:
	var shade := base.darkened(0.22)
	var lit := base.lightened(0.13)
	blob(c, center + Vector2(-rx * 0.1, ry * 0.12), rx * 1.02, ry * 0.94, shade, seed_v)
	blob(c, center + Vector2(rx * 0.04, -ry * 0.02), rx * 0.94, ry * 0.86, base, seed_v + 1)
	blob(c, center + Vector2(rx * 0.3, -ry * 0.3), rx * 0.48, ry * 0.42, lit, seed_v + 2)
	blob(c, center + Vector2(-rx * 0.26, -ry * 0.22), rx * 0.4, ry * 0.36, base.lightened(0.06), seed_v + 3)
	blob(c, center + Vector2(rx * 0.02, -ry * 0.42), rx * 0.36, ry * 0.3, lit, seed_v + 4)
	# leaf texture: many small angled leaf-ellipses, sunny side lighter
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v + 9
	for i in 26:
		var a := rng.randf_range(-PI, PI)
		var rr := rng.randf_range(0.2, 0.86)
		var p := center + Vector2(cos(a) * rx * rr, sin(a) * ry * rr)
		var sunny := clampf(0.5 + (cos(a) * 0.5 - sin(a) * 0.5) * rr, 0.0, 1.0)
		var tone := shade.lerp(lit.lightened(0.1), sunny * rng.randf_range(0.7, 1.0))
		var la := rng.randf_range(-0.7, 0.7)
		var lr := rng.randf_range(3.0, 5.5)
		var pts := PackedVector2Array()
		for k in 8:
			var ka := TAU * k / 8.0
			var lp := Vector2(cos(ka) * lr, sin(ka) * lr * 0.55).rotated(la)
			pts.append(p + lp)
		c.draw_polygon(pts, PackedColorArray([tone]))
	for i in 6:
		var a := rng.randf_range(PI * 0.25, PI * 0.9)
		var rr := rng.randf_range(0.45, 0.85)
		var p := center + Vector2(-cos(a) * rx * rr, sin(a) * ry * rr)
		c.draw_circle(p, rng.randf_range(2.5, 4.0), shade.darkened(0.06))


## Tapered tree trunk with root flare, bark streaks and side shading.
## base_pos is where it meets the ground; height goes up (negative y).
static func trunk(c: CanvasItem, base_pos: Vector2, height: float, w_base: float, w_top: float, col: Color, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var lean := rng.randf_range(-0.06, 0.06)
	var top := base_pos + Vector2(lean * height, -height)
	# root flare
	c.draw_polygon(PackedVector2Array([
		base_pos + Vector2(-w_base * 1.5, 2), base_pos + Vector2(-w_base * 0.4, -w_base * 0.9),
		base_pos + Vector2(w_base * 0.4, -w_base * 0.9), base_pos + Vector2(w_base * 1.5, 2),
	]), PackedColorArray([col.darkened(0.08)]))
	# tapered body, slightly curved edges
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in 5:
		var u := i / 4.0
		var w := lerpf(w_base, w_top, u) * (1.0 + 0.06 * sin(u * PI))
		var p := base_pos.lerp(top, u)
		left.append(p + Vector2(-w, 0))
		right.append(p + Vector2(w, 0))
	var body := PackedVector2Array()
	body.append_array(left)
	for i in range(right.size() - 1, -1, -1):
		body.append(right[i])
	c.draw_polygon(body, PackedColorArray([col]))
	# shade strip on the left, light strip on the right
	for i in 4:
		var u0 := i / 4.0
		var u1 := (i + 1) / 4.0
		var w0 := lerpf(w_base, w_top, u0)
		var w1 := lerpf(w_base, w_top, u1)
		var p0 := base_pos.lerp(top, u0)
		var p1 := base_pos.lerp(top, u1)
		c.draw_polygon(PackedVector2Array([
			p0 + Vector2(-w0, 0), p0 + Vector2(-w0 * 0.45, 0),
			p1 + Vector2(-w1 * 0.45, 0), p1 + Vector2(-w1, 0),
		]), PackedColorArray([col.darkened(0.14)]))
		c.draw_polygon(PackedVector2Array([
			p0 + Vector2(w0 * 0.55, 0), p0 + Vector2(w0, 0),
			p1 + Vector2(w1, 0), p1 + Vector2(w1 * 0.55, 0),
		]), PackedColorArray([col.lightened(0.09)]))
	# bark streaks
	for i in 4:
		var u0 := rng.randf_range(0.08, 0.45)
		var u1 := u0 + rng.randf_range(0.18, 0.4)
		var off := rng.randf_range(-0.5, 0.5)
		var p0 := base_pos.lerp(top, u0) + Vector2(off * w_base, 0)
		var p1 := base_pos.lerp(top, minf(u1, 0.95)) + Vector2(off * w_top * 0.8, 0)
		c.draw_line(p0, p1, col.darkened(0.2), rng.randf_range(1.5, 2.5))


## A little clump of tapered grass blades.
static func tuft(c: CanvasItem, pos: Vector2, h: float, col: Color, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for b in 4:
		var lean := rng.randf_range(-0.5, 0.5) * h * 0.5
		var bh := h * rng.randf_range(0.6, 1.0)
		var bx := rng.randf_range(-3.5, 3.5)
		var tone := col.darkened(rng.randf_range(0.0, 0.12))
		c.draw_polygon(PackedVector2Array([
			pos + Vector2(bx - 1.7, 0), pos + Vector2(bx + 1.7, 0),
			pos + Vector2(bx + lean, -bh),
		]), PackedColorArray([tone]))


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


# --- Building materials (treehouse) ------------------------------------------

static func draw_material(c: CanvasItem, kind: String, s: float) -> void:
	match kind:
		"stick":
			c.draw_line(Vector2(-s, s * 0.5), Vector2(s, -s * 0.5), Color("6e5039"), s * 0.42)
			c.draw_line(Vector2(-s, s * 0.5), Vector2(s, -s * 0.5), Color("a97e54"), s * 0.28)
			c.draw_line(Vector2(-s * 0.1, s * 0.05), Vector2(s * 0.35, -s * 0.65), Color("a97e54"), s * 0.2)
			c.draw_circle(Vector2(s * 0.4, -s * 0.7), s * 0.16, Color("8cc188"))
		"plank":
			rounded_rect(c, Rect2(-s, -s * 0.42, s * 2.0, s * 0.84), s * 0.14, Color("6e5039"))
			rounded_rect(c, Rect2(-s * 0.92, -s * 0.34, s * 1.84, s * 0.68), s * 0.12, Color("c9a06c"))
			c.draw_line(Vector2(-s * 0.7, 0), Vector2(s * 0.7, s * 0.06), Color("a97e54"), s * 0.1)
			c.draw_circle(Vector2(-s * 0.72, -s * 0.14), s * 0.08, Color("8a6a44"))
			c.draw_circle(Vector2(s * 0.72, -s * 0.14), s * 0.08, Color("8a6a44"))
		"rope":
			c.draw_arc(Vector2.ZERO, s * 0.62, 0, TAU, 16, Color("55763f"), s * 0.42, true)
			c.draw_arc(Vector2.ZERO, s * 0.62, 0, TAU, 16, Color("6f9a5d"), s * 0.26, true)
			c.draw_arc(Vector2.ZERO, s * 0.3, 0, TAU, 12, Color("6f9a5d"), s * 0.2, true)
			c.draw_line(Vector2(-s * 0.15, -s * 0.6), Vector2(s * 0.2, -s * 0.68), Color("55763f"), s * 0.18)
			c.draw_line(Vector2(s * 0.5, s * 0.4), Vector2(s * 0.85, s * 0.62), Color("6f9a5d"), s * 0.16)
		_:
			c.draw_circle(Vector2.ZERO, s * 0.6, Color("c9a06c"))


# --- Museum finds ------------------------------------------------------------

static func draw_find(c: CanvasItem, kind: String, s: float) -> void:
	if kind.begins_with("photo_"):
		draw_photo(c, kind, s)
		return
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
		"drawing":
			# one of Summer's own drawings, in a little frame
			rounded_rect(c, Rect2(-s * 0.85, -s * 0.7, s * 1.7, s * 1.4), s * 0.16, Color("c9a06c"))
			c.draw_rect(Rect2(-s * 0.68, -s * 0.53, s * 1.36, s * 1.06), Color("fffdf5"))
			c.draw_circle(Vector2(s * 0.35, -s * 0.25), s * 0.18, Color("ffd98a"))   # sun
			c.draw_line(Vector2(-s * 0.55, s * 0.35), Vector2(-s * 0.2, -s * 0.1), Color("8fc48a"), maxf(2.0, s * 0.1))
			c.draw_line(Vector2(-s * 0.2, -s * 0.1), Vector2(s * 0.15, s * 0.35), Color("8fc48a"), maxf(2.0, s * 0.1))
			heart(c, Vector2(-s * 0.35, -s * 0.28), s * 0.16, Color("f2a0b5"))
		"photo":
			# a little instant photo
			rounded_rect(c, Rect2(-s * 0.7, -s * 0.8, s * 1.4, s * 1.6), s * 0.1, Color("fffdf5"))
			c.draw_rect(Rect2(-s * 0.56, -s * 0.66, s * 1.12, s * 1.05), Color("c3e2f2"))
			c.draw_circle(Vector2(s * 0.28, -s * 0.4), s * 0.16, Color("ffd98a"))
			ellipse(c, Vector2(-s * 0.14, s * 0.14), s * 0.3, s * 0.16, Color("a8d5a2"))
			c.draw_circle(Vector2(-s * 0.14, s * 0.0), s * 0.12, Color("83b86f"))
		_:
			c.draw_circle(Vector2.ZERO, s * 0.7, Color("c9a06c"))


## An instant photo of an animal (or the meadow). kind = "photo_<subject>_<v>"
## where v picks the variation baked in when the snap was taken. A real
## photograph goes in the frame when Photos has one for the subject; otherwise
## we draw the picture, where v 0..9 shifts sky, decoration, pose and framing so
## every snap still feels like its own little picture.
static func draw_photo(c: CanvasItem, kind: String, s: float) -> void:
	var parts := kind.split("_")
	var subject := parts[1] if parts.size() > 1 else "meadow"
	var v := int(parts[2]) if parts.size() > 2 else 0

	# polaroid frame
	rounded_rect(c, Rect2(-s * 0.78, -s * 0.9, s * 1.56, s * 1.8), s * 0.1, Color("fffdf5"))
	var pic := Rect2(-s * 0.64, -s * 0.76, s * 1.28, s * 1.18)

	var tex := Photos.get_photo(subject, v)
	if tex != null:
		c.draw_texture_rect_region(tex, pic, Photos.crop_for(tex, pic))
		return

	var skies := [Color("c3e2f2"), Color("ffe3c2"), Color("eef7fb"), Color("d9ecf7")]
	c.draw_rect(pic, skies[v % 4])
	c.draw_rect(Rect2(pic.position.x, pic.end.y - s * 0.3, pic.size.x, s * 0.3), Color("a8d5a2"))

	# a little something in the sky, different each time
	var deco_p := Vector2(-s * 0.38 if v % 2 == 0 else s * 0.38, -s * 0.5)
	match v % 5:
		0:
			c.draw_circle(deco_p, s * 0.14, Color("ffd98a"))
		1:
			c.draw_circle(deco_p, s * 0.1, Color(1, 1, 1, 0.95))
			c.draw_circle(deco_p + Vector2(s * 0.1, s * 0.03), s * 0.08, Color(1, 1, 1, 0.95))
		2:
			star(c, deco_p, s * 0.12, Color("ffd98a"))
		3:
			heart(c, deco_p, s * 0.11, Color("f2a0b5"))
		4:
			for i in 3:
				c.draw_arc(deco_p + Vector2(0, s * 0.1), s * (0.16 - i * 0.045), PI, TAU, 12,
					[Color("f2a0a0"), Color("ffd98a"), Color("a9c9e8")][i], s * 0.035, true)

	var fx := -1.0 if v >= 5 else 1.0
	var sp := Vector2((v % 3 - 1) * s * 0.12, s * 0.1)   # subject shifts around
	match subject:
		"frog":
			var green := Color("83b86f")
			ellipse(c, sp + Vector2(0, s * 0.18), s * 0.3, s * 0.2, green)
			c.draw_circle(sp + Vector2(-s * 0.13 * fx, s * 0.0), s * 0.11, green)
			c.draw_circle(sp + Vector2(s * 0.13 * fx, s * 0.0), s * 0.11, green)
			c.draw_circle(sp + Vector2(-s * 0.13 * fx, -s * 0.02), s * 0.05, Color.WHITE)
			c.draw_circle(sp + Vector2(s * 0.13 * fx, -s * 0.02), s * 0.05, Color.WHITE)
			c.draw_circle(sp + Vector2(-s * 0.13 * fx, -s * 0.02), s * 0.025, Color("3a3a44"))
			c.draw_circle(sp + Vector2(s * 0.13 * fx, -s * 0.02), s * 0.025, Color("3a3a44"))
		"bird":
			c.draw_set_transform(sp + Vector2(0, s * 0.02), 0.0, Vector2(fx * 0.42, 0.42))
			draw_icon(c, "bird", s)
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"butterfly":
			c.draw_set_transform(sp + Vector2(0, -s * 0.05), 0.0, Vector2(fx * 0.4, 0.4))
			draw_icon(c, "butterfly", s)
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"owl":
			var body := Color("9a7a5e")
			ellipse(c, sp + Vector2(0, s * 0.14), s * 0.24, s * 0.3, body)
			ellipse(c, sp + Vector2(0, s * 0.2), s * 0.15, s * 0.2, Color("e8dcc8"))
			c.draw_circle(sp + Vector2(0, -s * 0.08), s * 0.2, body)
			for side in [-1.0, 1.0]:
				c.draw_polygon(PackedVector2Array([
					sp + Vector2(side * s * 0.14, -s * 0.24), sp + Vector2(side * s * 0.22, -s * 0.34),
					sp + Vector2(side * s * 0.05, -s * 0.26),
				]), PackedColorArray([body.darkened(0.1)]))
				c.draw_circle(sp + Vector2(side * s * 0.08 * fx, -s * 0.1), s * 0.08, Color.WHITE)
				c.draw_circle(sp + Vector2(side * s * 0.08 * fx, -s * 0.1), s * 0.04, Color("4a3a30"))
			c.draw_polygon(PackedVector2Array([
				sp + Vector2(-s * 0.03, -s * 0.04), sp + Vector2(s * 0.03, -s * 0.04),
				sp + Vector2(0, s * 0.03),
			]), PackedColorArray([Color("ffc46b")]))
		"dino":
			# a long-neck against the valley
			c.draw_rect(Rect2(sp.x - s * 0.3, sp.y + s * 0.02, s * 0.6, s * 0.1), Color("b5ab74"))
			ellipse(c, sp + Vector2(0, -s * 0.06), s * 0.2, s * 0.11, Color("7fa86a"))
			for lx in [-0.12, -0.02, 0.08]:
				c.draw_line(sp + Vector2(s * lx, s * 0.02), sp + Vector2(s * lx, s * 0.1),
					Color("6f9a5d"), s * 0.045)
			c.draw_line(sp + Vector2(-s * 0.14, -s * 0.1), sp + Vector2(-s * 0.28, -s * 0.32),
				Color("7fa86a"), s * 0.05)
			ellipse(c, sp + Vector2(-s * 0.3, -s * 0.35), s * 0.06, s * 0.04, Color("7fa86a"))
			c.draw_line(sp + Vector2(s * 0.18, -s * 0.06), sp + Vector2(s * 0.34, s * 0.02),
				Color("7fa86a"), s * 0.04)
		"cove":
			# the wreck and the sea
			c.draw_rect(Rect2(pic.position.x, sp.y - s * 0.18, pic.size.x, s * 0.16),
				Color("7fb5c9"))
			c.draw_polygon(PackedVector2Array([
				sp + Vector2(-s * 0.26, s * 0.06), sp + Vector2(s * 0.26, s * 0.06),
				sp + Vector2(s * 0.18, -s * 0.08), sp + Vector2(-s * 0.18, -s * 0.08),
			]), PackedColorArray([Color("8a6a52")]))
			c.draw_line(sp + Vector2(s * 0.02, -s * 0.08), sp + Vector2(s * 0.06, -s * 0.38),
				Color("8a6a52"), s * 0.035)
			c.draw_polygon(PackedVector2Array([
				sp + Vector2(s * 0.06, -s * 0.36), sp + Vector2(s * 0.24, -s * 0.2),
				sp + Vector2(s * 0.05, -s * 0.14),
			]), PackedColorArray([Color("f2e6c8")]))
		"market":
			# a striped stall
			for i in 5:
				c.draw_rect(Rect2(sp.x - s * 0.26 + i * s * 0.105, sp.y - s * 0.24,
					s * 0.055, s * 0.1), Color("e8918c") if i % 2 == 0 else Color("f4ead6"))
			c.draw_rect(Rect2(sp.x - s * 0.26, sp.y - s * 0.24, s * 0.52, s * 0.1),
				Color(1, 1, 1, 0.0))
			c.draw_rect(Rect2(sp.x - s * 0.24, sp.y - s * 0.06, s * 0.48, s * 0.07),
				Color("a97e54"))
			for sx in [-0.22, 0.22]:
				c.draw_line(sp + Vector2(s * sx, s * 0.01), sp + Vector2(s * sx, -s * 0.24),
					Color("8a6a52"), s * 0.02)
			for i in 3:
				c.draw_circle(sp + Vector2(-s * 0.1 + i * s * 0.1, -s * 0.1), s * 0.03,
					Color("e05c50"))
		"treehouse":
			# the snapshot taken at every build stage — her house, growing
			c.draw_rect(Rect2(sp.x - s * 0.03, sp.y - s * 0.02, s * 0.06, s * 0.34), Color("8a6a52"))
			c.draw_circle(sp + Vector2(0, -s * 0.14), s * 0.26, Color("94c489"))
			rounded_rect(c, Rect2(sp.x - s * 0.16, sp.y - s * 0.24, s * 0.32, s * 0.2), s * 0.03,
				Color("c9a06c"))
			c.draw_polygon(PackedVector2Array([
				sp + Vector2(-s * 0.21, -s * 0.24), sp + Vector2(s * 0.21, -s * 0.24),
				sp + Vector2(0, -s * 0.38),
			]), PackedColorArray([Color("a9743f")]))
			c.draw_circle(sp + Vector2(0, -s * 0.15), s * 0.05, Color("ffe9b8"))
			c.draw_rect(Rect2(sp.x - s * 0.2, sp.y - s * 0.05, s * 0.4, s * 0.03), Color("a97e54"))
		"indy", "star":
			var body := Color("f3f0e8") if subject == "indy" else Color("43404a")
			ellipse(c, sp + Vector2(0, s * 0.1), s * 0.3, s * 0.16, body)
			c.draw_line(sp + Vector2(s * 0.22 * fx, s * 0.04), sp + Vector2(s * 0.32 * fx, -s * 0.14), body, s * 0.1)
			ellipse(c, sp + Vector2(s * 0.34 * fx, -s * 0.16), s * 0.12, s * 0.09, body)
			for lx in [-0.18, -0.08, 0.1, 0.2]:
				c.draw_line(sp + Vector2(s * lx * fx, s * 0.2), sp + Vector2(s * lx * fx, s * 0.34), body, s * 0.06)
			c.draw_line(sp + Vector2(-s * 0.28 * fx, s * 0.06), sp + Vector2(-s * 0.4 * fx, -s * 0.02), body, s * 0.05)
			if subject == "indy":
				c.draw_circle(sp + Vector2(s * 0.36 * fx, -s * 0.18), s * 0.05, Color("a5764f"))
			else:
				star(c, sp + Vector2(s * 0.08 * fx, s * 0.06), s * 0.07, Color("efece4"))
		_:
			# the meadow itself: hills, the treehouse, a flower
			ellipse(c, sp + Vector2(-s * 0.25, s * 0.22), s * 0.35, s * 0.18, Color("bcd9b4"))
			c.draw_rect(Rect2(sp + Vector2(s * 0.18 * fx - s * 0.03, -s * 0.1), Vector2(s * 0.06, s * 0.36)), Color("8a6a52"))
			c.draw_circle(sp + Vector2(s * 0.18 * fx, -s * 0.18), s * 0.16, Color("9ccf8f"))
			c.draw_circle(sp + Vector2(-s * 0.3, s * 0.28), s * 0.045, Color("f2b8cf"))
			c.draw_circle(sp + Vector2(-s * 0.12, s * 0.32), s * 0.045, Color("ffe6b3"))


## Summer's face on its own, at any size — the safari hat, the blonde fringe
## and ponytail, and the same eyes she has out in the world. `r` is the radius
## of her head; everything else is derived from it, so she reads correctly at
## icon size and at picture-book size. `munch` opens her mouth for a bite.
##
## She faces RIGHT. Her whole figure lives in player.gd; this is only the head,
## for the places where a face says it better than a symbol.
static func summer_head(c: CanvasItem, at: Vector2, r: float, munch := false) -> void:
	var skin := Color("f2c9a5")
	var hair := Color("f0cd7e")
	var hat := Color("d9c9a0")
	var ink := Color("5a4a3a")
	var u := r / 13.0        # everything below is in her original 13 px units

	# ponytail, behind everything
	var tail := at + Vector2(-12.0 * u, 7.0 * u)
	ellipse(c, tail + Vector2(-2.0 * u, -5.0 * u), 4.2 * u, 7.5 * u, hair.darkened(0.3))
	ellipse(c, tail + Vector2(-2.0 * u, -5.0 * u), 3.5 * u, 6.5 * u, hair.darkened(0.04))
	ellipse(c, tail + Vector2(-3.5 * u, 3.0 * u), 2.8 * u, 4.5 * u, hair.darkened(0.08))
	c.draw_circle(tail + Vector2(0, -13.0 * u), 6.3 * u, hair.darkened(0.3))
	c.draw_circle(tail + Vector2(0, -13.0 * u), 5.5 * u, hair)

	# head, with the soft shading she has in the world
	c.draw_circle(at, r * 1.09, skin.darkened(0.32))
	c.draw_circle(at, r, skin)
	c.draw_arc(at, r * 0.85, PI * 0.6, PI * 1.4, 10, skin.darkened(0.07), r * 0.27, true)
	c.draw_circle(at + Vector2(-10.5 * u, 2.0 * u), 3.0 * u, skin.darkened(0.32))
	c.draw_circle(at + Vector2(-10.5 * u, 2.0 * u), 2.2 * u, skin)

	# hair: cap and fringe
	c.draw_circle(at + Vector2(-3.0 * u, -7.0 * u), 10.0 * u, hair)
	c.draw_arc(at, 12.0 * u, PI + 0.25, TAU - 0.45, 14, hair, 6.0 * u, true)
	for st in 3:
		var sx := (2.0 + st * 3.0) * u
		c.draw_line(at + Vector2(sx, -11.5 * u), at + Vector2(sx + u, -8.0 * u),
			hair.darkened(0.12), maxf(1.0, 1.3 * u))
	c.draw_circle(at + Vector2(-11.0 * u, 2.0 * u), 2.2 * u, Color("e8918c"))

	# the safari hat
	ellipse(c, at + Vector2(-u, -9.5 * u), 18.2 * u, 5.8 * u, hat.darkened(0.35))
	c.draw_circle(at + Vector2(-u, -14.0 * u), 10.4 * u, hat.darkened(0.35))
	c.draw_circle(at + Vector2(-u, -14.0 * u), 9.5 * u, hat)
	c.draw_arc(at + Vector2(-u, -15.0 * u), 7.5 * u, PI + 0.4, TAU - 0.4, 10,
		hat.lightened(0.1), 3.0 * u, true)
	ellipse(c, at + Vector2(-u, -9.0 * u), 17.5 * u, 5.0 * u, hat.darkened(0.12))
	ellipse(c, at + Vector2(-u, -10.0 * u), 17.0 * u, 5.0 * u, hat)
	ellipse(c, at + Vector2(-u, -11.5 * u), 17.0 * u, 4.0 * u, hat.lightened(0.08))
	c.draw_line(at + Vector2(-10.0 * u, -12.0 * u), at + Vector2(8.0 * u, -12.0 * u),
		Color("a97e54"), 3.0 * u)
	c.draw_circle(at + Vector2(5.0 * u, -12.0 * u), 1.4 * u, Color("d9b45c"))

	# face
	var eye_a := at + Vector2(4.0 * u, 0)
	var eye_b := at + Vector2(9.0 * u, 0)
	for e in [eye_a, eye_b]:
		c.draw_arc(e + Vector2(0, -3.5 * u), 2.4 * u, PI + 0.5, TAU - 0.5, 8,
			hair.darkened(0.25), maxf(1.0, 1.2 * u), true)
		c.draw_circle(e, 2.0 * u, ink)
		c.draw_circle(e + Vector2(-0.6 * u, -0.6 * u), 0.7 * u, Color.WHITE)
	c.draw_circle(at + Vector2(6.5 * u, 3.2 * u), 1.1 * u, skin.darkened(0.15))
	if munch:
		# a happy open mouth, mid-bite
		ellipse(c, at + Vector2(6.5 * u, 6.0 * u), 3.2 * u, 3.6 * u, Color("9c6b5a"))
		ellipse(c, at + Vector2(6.5 * u, 7.4 * u), 2.2 * u, 1.6 * u, Color("e08a8a"))
	else:
		c.draw_arc(at + Vector2(6.5 * u, 4.0 * u), 3.0 * u, 0.3, PI - 0.3, 10,
			Color("b56a5f"), maxf(1.0, 1.8 * u), true)
	c.draw_circle(at + Vector2(-3.5 * u, 3.5 * u), 2.2 * u, Color(0.95, 0.6, 0.6, 0.3))


## The little green "this one is the plant kind" badge — a leaf and a tick, the
## mark she will see on real packets in the shops. Goes on the ingredients that
## would normally have come from an animal.
static func vegan_badge(c: CanvasItem, at: Vector2, r: float) -> void:
	var green := Color("3d9e3d")
	c.draw_circle(at, r * 1.18, Color(1, 1, 1, 0.95))   # halo, so it reads on any colour
	c.draw_circle(at, r, green)
	# the tick, low and to the left, kept slim so the leaf stays the hero
	c.draw_polyline(PackedVector2Array([
		at + Vector2(-r * 0.60, -r * 0.04),
		at + Vector2(-r * 0.26, r * 0.38),
		at + Vector2(r * 0.16, -r * 0.44),
	]), Color.WHITE, maxf(1.8, r * 0.19), true)
	# The leaf. A lens between base and tip — fat and curved on the upper side,
	# nearly straight along the spine — which is what actually reads as a leaf.
	# Drawn twice: a fatter green pass first cuts a clean gap through the tick
	# behind it, or the two shapes merge into one blob at icon size.
	var base := at + Vector2(-r * 0.06, r * 0.34)
	var tip := at + Vector2(r * 0.66, -r * 0.70)
	var dir := tip - base
	var perp := Vector2(-dir.y, dir.x).normalized()
	for pass_i in 2:
		var grow: float = r * (0.13 if pass_i == 0 else 0.0)
		var pts := PackedVector2Array()
		for i in 14:
			var v := i / 13.0
			pts.append(base + dir * v - perp * (sin(pow(v, 0.85) * PI) * r * 0.40 + grow))
		for i in 14:
			var v := 1.0 - i / 13.0
			pts.append(base + dir * v + perp * (sin(pow(v, 0.85) * PI) * r * 0.11 + grow))
		c.draw_colored_polygon(pts, green if pass_i == 0 else Color.WHITE)
	# the vein down the middle of the leaf
	c.draw_line(base + dir * 0.14, tip - dir * 0.1, green, maxf(1.2, r * 0.1))
