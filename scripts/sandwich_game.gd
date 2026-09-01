class_name SandwichGame
extends CanvasLayer
## Picnic time! A layering game: the fillings are laid out on a wooden board,
## tap them to stack a sandwich as tall as she likes — towers welcome. Tap the
## eat button and she takes it outside and tucks in. No way to make a wrong
## sandwich, and tapping the tower takes the top layer back off, so a misplaced
## slice is never a problem. The backpack button packs the picnic away.
##
## EVERYTHING HERE IS VEGAN. The three that would normally come from an animal
## — the butter, the cheese and the ham — are the plant kind, and they wear the
## little green leaf-and-tick badge she will see on real packets in the shops.
## Nothing in this game came from an animal, and she can see that at a glance.

signal closed
## The Eat button hands the finished sandwich back to the world, which walks
## her over to the blanket, sits her down and lets her actually eat it.
signal eat_now(stack: Array)

const INGREDIENTS := ["bread", "butter", "jam", "cheese", "tomato", "lettuce", "ham", "cucumber"]

## The word under each one. Short, lowercase, the way she is taught to read
## them — and the same words the top bar uses for her materials.
const NAMES := {
	"bread": "bread",
	"butter": "butter",
	"jam": "jam",
	"cheese": "cheese",
	"tomato": "tomato",
	"lettuce": "lettuce",
	"ham": "ham",
	"cucumber": "cucumber",
}

## The ones that wear the green badge: plant butter, plant cheese, plant ham.
const PLANT_MADE := ["butter", "cheese", "ham"]

const PAPER := Color("fff8ec")
const INK := Color("6b4f38")
const SOFT := Color("a2917a")

var table: Table


func _ready() -> void:
	layer = 40
	table = Table.new()
	add_child(table)

	var pack_btn := IconButton.new("pack", 96.0)
	pack_btn.pressed.connect(func() -> void: closed.emit())
	table.add_child(pack_btn)
	table.pack_btn = pack_btn

	var eat_btn := IconButton.new("eat", 132.0)
	eat_btn.pressed.connect(_eat)
	table.add_child(eat_btn)
	table.eat_btn = eat_btn
	table.layout_buttons()


## Take the sandwich outside and eat it properly. The picnic closes, and the
## world takes over: she walks to the blanket, sits down and tucks in.
func _eat() -> void:
	if table.eating or GameState.sandwich_stack.is_empty():
		# nothing on the plate yet — nudge the board rather than doing nothing
		table.nudge_t = 1.0
		Sound.pop()
		return
	table.eating = true
	var stack: Array = GameState.sandwich_stack.duplicate()
	GameState.sandwich_stack.clear()
	Sound.pop()
	eat_now.emit(stack)
	closed.emit()


class Table extends Control:
	var pack_btn: IconButton
	var eat_btn: IconButton
	var eating := false
	var t := 0.0
	var nudge_t := 0.0        ## the board waves when she asks to eat an empty plate
	var added_t := 0.0        ## the newest layer drops in
	var picked := -1          ## which ingredient button is squashed, and for how long
	var picked_t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		get_viewport().size_changed.connect(layout_buttons)

	func layout_buttons() -> void:
		var vs := get_viewport().get_visible_rect().size
		size = vs
		if pack_btn:
			pack_btn.position = Vector2(vs.x - 120, 24)
		if eat_btn:
			eat_btn.position = _eat_centre() - Vector2(66, 66)

	func _process(delta: float) -> void:
		t += delta
		nudge_t = maxf(0.0, nudge_t - delta * 1.6)
		added_t = maxf(0.0, added_t - delta * 3.0)
		picked_t = maxf(0.0, picked_t - delta * 4.0)
		if picked_t <= 0.0:
			picked = -1
		# the eat button only looks ready when there is something to eat
		if eat_btn:
			var live := not GameState.sandwich_stack.is_empty()
			eat_btn.modulate.a = 1.0 if live else 0.4
			eat_btn.scale = Vector2.ONE * (1.0 + (0.03 * sin(t * 3.0) if live else 0.0))
		queue_redraw()

	# --- where everything sits ------------------------------------------------

	## The wooden board along the bottom that the fillings are laid out on.
	func board_top() -> float:
		return size.y - minf(190.0, size.y * 0.27)

	func plate_pos() -> Vector2:
		return Vector2(size.x * 0.5, board_top() - 76.0)

	func _eat_centre() -> Vector2:
		return Vector2(size.x - 122.0, board_top() - 178.0)

	func _btn_radius() -> float:
		return clampf((size.x - 220.0) / (SandwichGame.INGREDIENTS.size() * 2.55), 34.0, 50.0)

	func _btn_pos(i: int) -> Vector2:
		var n := SandwichGame.INGREDIENTS.size()
		var step := minf(140.0, (size.x - 150.0) / n)
		var start := size.x * 0.5 - step * (n - 1) * 0.5
		return Vector2(start + i * step, board_top() + _btn_radius() + 26.0)

	## How tall one layer is drawn — a big sandwich squashes down so the whole
	## tower always fits on the screen.
	func _layer_h() -> float:
		var room := plate_pos().y - 190.0
		return clampf(room / maxf(1.0, GameState.sandwich_stack.size()), 7.0, 21.0)

	# --- taps -----------------------------------------------------------------

	func _gui_input(event: InputEvent) -> void:
		if not (event is InputEventMouseButton and event.pressed
				and event.button_index == MOUSE_BUTTON_LEFT):
			return
		accept_event()
		if eating:
			return
		# event.position, not the live mouse — a touch on Android does not move a
		# mouse cursor, and every other panel in the game reads the event too
		var p: Vector2 = event.position
		var r := _btn_radius()
		for i in SandwichGame.INGREDIENTS.size():
			if p.distance_to(_btn_pos(i)) < r + 8.0:
				GameState.sandwich_stack.append(SandwichGame.INGREDIENTS[i])
				picked = i
				picked_t = 1.0
				added_t = 1.0
				Sound.pop()
				queue_redraw()
				return
		# tapping the sandwich itself takes the top layer back off, so a slice
		# in the wrong place is never something to be stuck with
		var stack: Array = GameState.sandwich_stack
		if not stack.is_empty():
			var pp := plate_pos()
			var tower := Rect2(pp.x - 90.0, pp.y - stack.size() * _layer_h() - 30.0,
				180.0, stack.size() * _layer_h() + 36.0)
			if tower.has_point(p):
				stack.pop_back()
				Sound.pop()
				queue_redraw()

	# --- drawing --------------------------------------------------------------

	func _draw() -> void:
		var vs := size
		size = get_viewport().get_visible_rect().size
		_scene(vs)
		_blanket(vs)
		_plate_and_tower(vs)
		_board(vs)
		_titles(vs)

	## Sky, sun, hills and a couple of trees — the same meadow she walked out of.
	func _scene(vs: Vector2) -> void:
		var horizon := vs.y * 0.30
		DrawKit.vgrad(self, Rect2(0, 0, vs.x, horizon + 4.0),
			Color("bcdcf0"), Color("e4f2fa"))
		var sun := Vector2(vs.x - 320.0, 104.0)
		draw_circle(sun, 62.0, Color(1, 0.92, 0.72, 0.30))
		draw_circle(sun, 46.0, Color("ffd98a"))
		draw_circle(sun, 34.0, Color("ffe6b3"))
		# far hills
		DrawKit.ellipse(self, Vector2(vs.x * 0.22, horizon + 40.0), vs.x * 0.34, 118.0,
			Color("a9d3a0"))
		DrawKit.ellipse(self, Vector2(vs.x * 0.78, horizon + 52.0), vs.x * 0.36, 132.0,
			Color("9ecb96"))
		draw_rect(Rect2(0, horizon, vs.x, vs.y - horizon), Color("a8d5a2"))
		# two trees on the far side of the blanket
		for spec in [[vs.x * 0.13, 0.9, 3], [vs.x * 0.88, 1.05, 7]]:
			var bx: float = spec[0]
			var s: float = spec[1]
			DrawKit.trunk(self, Vector2(bx, horizon + 66.0 * s), 150.0 * s, 19.0 * s,
				12.0 * s, Color("8a6a52"), int(spec[2]))
			DrawKit.canopy(self, Vector2(bx, horizon - 88.0 * s), 82.0 * s, 60.0 * s,
				Color("7fb87a"), int(spec[2]))
		# grass at the horizon line
		for i in int(vs.x / 46.0):
			DrawKit.tuft(self, Vector2(8.0 + i * 46.0, horizon + 12.0), 13.0,
				Color("8fc48a"), i)

	## The picnic blanket, with a soft shadow and a fringed edge.
	func _blanket(vs: Vector2) -> void:
		var br := Rect2(vs.x * 0.05, vs.y * 0.34, vs.x * 0.90, board_top() - vs.y * 0.34 + 34.0)
		DrawKit.ellipse(self, Vector2(br.get_center().x, br.end.y - 10.0),
			br.size.x * 0.50, 26.0, Color(0.35, 0.30, 0.22, 0.10))
		# fringe
		for i in int(br.size.x / 22.0):
			var fx := br.position.x + 11.0 + i * 22.0
			draw_line(Vector2(fx, br.position.y - 9.0), Vector2(fx, br.position.y + 4.0),
				Color("e0aaaa"), 3.0)
		DrawKit.rounded_rect(self, br, 26.0, Color("f2c9c9"))
		# the check, drawn as soft bands rather than hard lines
		var cols := 7
		for i in cols:
			var cw := br.size.x / cols
			if i % 2 == 1:
				draw_rect(Rect2(br.position.x + i * cw, br.position.y, cw, br.size.y),
					Color(0.90, 0.70, 0.70, 0.30))
		var rows := 4
		for j in rows:
			var rh := br.size.y / rows
			if j % 2 == 1:
				draw_rect(Rect2(br.position.x, br.position.y + j * rh, br.size.x, rh),
					Color(0.90, 0.70, 0.70, 0.30))
		DrawKit.rounded_rect_outline(self, br, 26.0, Color("e8b8b8"), 4.0)

	## The plate, the sandwich, and how many layers are on it.
	func _plate_and_tower(vs: Vector2) -> void:
		var pp := plate_pos()
		DrawKit.ellipse(self, pp + Vector2(0, 18.0), 178.0, 30.0, Color(0.35, 0.30, 0.22, 0.12))
		DrawKit.ellipse(self, pp + Vector2(0, 10.0), 172.0, 34.0, Color("fffdf5"))
		DrawKit.ellipse(self, pp + Vector2(0, 8.0), 142.0, 25.0, Color("f4efe2"))
		DrawKit.ellipse(self, pp + Vector2(0, 5.0), 120.0, 19.0, Color("fffdf5"))

		var stack: Array = GameState.sandwich_stack
		if stack.is_empty():
			_empty_plate(pp)
			return

		var lh := _layer_h()
		for i in stack.size():
			var wobble := sin(t * 1.6 + i * 0.8) * minf(3.0, i * 0.25)
			var drop := 0.0
			if i == stack.size() - 1 and added_t > 0.0:
				drop = -added_t * added_t * 46.0     # the newest slice lands softly
			_food(str(stack[i]), pp + Vector2(wobble, -4.0 - i * lh + drop), 150.0, lh)

		# how many layers, as a numeral she can count against the tower
		var font := ThemeDB.fallback_font
		var tag := Vector2(pp.x - 206.0, pp.y - 10.0)
		DrawKit.rounded_rect(self, Rect2(tag.x - 34.0, tag.y - 30.0, 68.0, 60.0), 16.0,
			Color(1, 1, 1, 0.86))
		var num := str(stack.size())
		var nw := font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
		draw_string(font, tag + Vector2(-nw * 0.5, 14.0), num,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 40, SandwichGame.INK)

	## Nothing on the plate yet. A dotted outline where the sandwich will go,
	## and — only once she can read — a word or two saying what to do.
	func _empty_plate(pp: Vector2) -> void:
		var bob := sin(t * 2.2) * 4.0
		# A ghost sandwich, stacked exactly where the real layers will go. Drawn
		# in a warm outline rather than white, or it would vanish into the plate.
		for row in [[-4.0, 16.0], [-26.0, 13.0], [-45.0, 16.0]]:
			var ry: float = row[0]
			var rh: float = row[1]
			var rr := Rect2(pp.x - 54.0, pp.y + ry - rh + bob, 108.0, rh)
			DrawKit.rounded_rect(self, rr, rh * 0.4, Color(1, 1, 1, 0.55))
			DrawKit.rounded_rect_outline(self, rr, rh * 0.4, Color("d9c3a8"), 2.5)
		_say("", "tap the food", "tap the food to build a sandwich",
			pp + Vector2(0, -92.0), 30, SandwichGame.INK)

	## The wooden board, the eight fillings, their names and their badges.
	func _board(vs: Vector2) -> void:
		var by := board_top()
		var wave := sin(t * 14.0) * 5.0 * nudge_t
		DrawKit.rounded_rect(self, Rect2(-20.0, by + wave, vs.x + 40.0, vs.y - by + 30.0),
			22.0, Color("a97e54"))
		DrawKit.rounded_rect(self, Rect2(-20.0, by + 8.0 + wave, vs.x + 40.0, vs.y - by + 22.0),
			20.0, Color("bb9764"))
		# a few plank lines, so it reads as a wooden board
		for i in 5:
			var lx := vs.x * (i + 1) / 6.0
			draw_line(Vector2(lx, by + 16.0 + wave), Vector2(lx, vs.y),
				Color(0.55, 0.42, 0.29, 0.18), 3.0)

		var font := ThemeDB.fallback_font
		var r := _btn_radius()
		for i in SandwichGame.INGREDIENTS.size():
			var kind := str(SandwichGame.INGREDIENTS[i])
			var bp := _btn_pos(i) + Vector2(0, wave)
			var squash := 1.0
			if picked == i:
				squash = 1.0 - 0.12 * picked_t
			# with nothing on the plate the fillings bob in turn, a slow wave down
			# the board — an invitation to tap that needs no words at all
			if GameState.sandwich_stack.is_empty():
				bp.y += sin(t * 2.6 - i * 0.55) * 5.0
			draw_circle(bp + Vector2(0, 5.0), r * squash, Color(0, 0, 0, 0.13))
			draw_circle(bp, r * squash, Color(1, 1, 1, 0.95))
			draw_arc(bp, r * squash - 2.0, 0, TAU, 28, Color("e6d8bd"), 2.0, true)
			_food(kind, bp + Vector2(0, r * 0.34), r * 1.42, r * 0.62)
			if SandwichGame.PLANT_MADE.has(kind):
				DrawKit.vegan_badge(self, bp + Vector2(r * 0.72, -r * 0.72), r * 0.36)
			# her word for it, right under the picture
			var word := str(SandwichGame.NAMES.get(kind, kind))
			var ww := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
			draw_string(font, bp + Vector2(-ww * 0.5, r + 30.0), word,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("fff3e0"))

	## Titles, and the note explaining the green badge.
	func _titles(vs: Vector2) -> void:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(54, 78), "my picnic",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("6b4f38"))
		# what the badge means. No words at all at the picture reading level —
		# the badge itself is the message there.
		if GameState.reading_level > 0:
			var note := "made from plants" if GameState.reading_level == 1 \
				else "the green badge means made from plants"
			DrawKit.vegan_badge(self, Vector2(70, board_top() - 34.0), 15.0)
			draw_string(font, Vector2(94, board_top() - 25.0), note,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("5d7a52"))
		# what the eat button does
		if eat_btn != null:
			var ec := _eat_centre()
			var label := "eat it!"
			var lw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
			draw_string(font, ec + Vector2(-lw * 0.5, 92.0), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 26,
				Color("6b4f38") if not GameState.sandwich_stack.is_empty()
				else Color(0.42, 0.31, 0.22, 0.4))

	## One line of instruction, worded for her reading level. Level 0 gets no
	## words at all — the pictures do the talking.
	func _say(pictures: String, words: String, sentence: String, at: Vector2,
			sz: int, col: Color) -> void:
		var text: String = [pictures, words, sentence][clampi(GameState.reading_level, 0, 2)]
		if text == "":
			return
		var font := ThemeDB.fallback_font
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
		draw_string(font, at + Vector2(-w * 0.5, 0), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)

	# --- the food itself ------------------------------------------------------

	## One filling, drawn `w` wide and `h` tall, sitting ON `pos` (pos is the
	## bottom edge). The same routine draws the layers in the sandwich and the
	## pictures on the board, so what she taps is exactly what she gets.
	func _food(kind: String, pos: Vector2, w: float, h: float) -> void:
		var half := w * 0.5
		match kind:
			"bread":
				# crust all the way round, soft crumb inside, a domed top
				DrawKit.rounded_rect(self, Rect2(pos.x - half, pos.y - h, w, h),
					h * 0.34, Color("d9a86a"))
				DrawKit.ellipse(self, Vector2(pos.x, pos.y - h + h * 0.14),
					half * 0.94, h * 0.34, Color("d9a86a"))
				DrawKit.rounded_rect(self, Rect2(pos.x - half + w * 0.035,
					pos.y - h + h * 0.22, w - w * 0.07, h * 0.62),
					h * 0.22, Color("f2ddb0"))
				for i in 3:
					draw_circle(Vector2(pos.x - half + w * (0.24 + i * 0.26),
						pos.y - h * 0.48), maxf(1.0, h * 0.08), Color("e6cb9c"))
			"butter":
				# a plant spread, with the swirl the knife left in it
				var bw := w * 0.88
				DrawKit.rounded_rect(self, Rect2(pos.x - bw * 0.5, pos.y - h * 0.72,
					bw, h * 0.72), h * 0.26, Color("f5d98e"))
				DrawKit.rounded_rect(self, Rect2(pos.x - bw * 0.5, pos.y - h * 0.72,
					bw, h * 0.5), h * 0.24, Color("ffe9a8"))
				var sw := PackedVector2Array()
				for i in 13:
					var v := i / 12.0
					sw.append(Vector2(pos.x - bw * 0.42 + bw * 0.84 * v,
						pos.y - h * 0.46 + sin(v * PI * 3.0) * h * 0.12))
				draw_polyline(sw, Color("f7e2a0"), maxf(1.0, h * 0.1), true)
			"jam":
				# glossy, and just about to drip over the edge
				var jw := w * 0.9
				DrawKit.rounded_rect(self, Rect2(pos.x - jw * 0.5, pos.y - h * 0.66,
					jw, h * 0.66), h * 0.3, Color("9c5589"))
				DrawKit.rounded_rect(self, Rect2(pos.x - jw * 0.5, pos.y - h * 0.66,
					jw, h * 0.5), h * 0.28, Color("b56a9f"))
				for i in 4:
					var jx := pos.x - jw * 0.34 + i * jw * 0.23
					draw_circle(Vector2(jx, pos.y - h * 0.62), h * 0.2, Color("c47cae"))
				for spec in [[-0.26, 0.9], [0.18, 1.15]]:
					var dx: float = pos.x + jw * float(spec[0])
					DrawKit.ellipse(self, Vector2(dx, pos.y - h * 0.1),
						h * 0.17, h * 0.3 * float(spec[1]), Color("9c5589"))
				draw_line(Vector2(pos.x - jw * 0.34, pos.y - h * 0.56),
					Vector2(pos.x - jw * 0.05, pos.y - h * 0.58),
					Color(1, 1, 1, 0.35), maxf(1.0, h * 0.1))
			"cheese":
				# a plant cheese slice, drooping a little at the corners
				var cw := w * 0.94
				draw_colored_polygon(PackedVector2Array([
					Vector2(pos.x - cw * 0.5, pos.y - h * 0.72),
					Vector2(pos.x + cw * 0.5, pos.y - h * 0.72),
					Vector2(pos.x + cw * 0.46, pos.y - h * 0.02),
					Vector2(pos.x + cw * 0.2, pos.y - h * 0.24),
					Vector2(pos.x - cw * 0.2, pos.y - h * 0.24),
					Vector2(pos.x - cw * 0.46, pos.y - h * 0.02),
				]), Color("f0c96a"))
				DrawKit.rounded_rect(self, Rect2(pos.x - cw * 0.5, pos.y - h * 0.72,
					cw, h * 0.4), h * 0.14, Color("ffd98a"))
				for spec in [[-0.22, 0.44], [0.12, 0.36], [0.32, 0.3]]:
					draw_circle(Vector2(pos.x + cw * float(spec[0]), pos.y - h * 0.46),
						h * float(spec[1]) * 0.36, Color("edbf5c"))
			"tomato":
				# proper slices: skin, flesh, a pale core and little seeds
				for i in 4:
					var tx := pos.x - w * 0.33 + i * w * 0.22
					var tc := Vector2(tx, pos.y - h * 0.42)
					var tr := h * 0.46
					draw_circle(tc, tr, Color("d1584e"))
					draw_circle(tc, tr * 0.86, Color("e07a70"))
					draw_circle(tc, tr * 0.44, Color("f2a8a0"))
					for k in 3:
						var a := k / 3.0 * TAU + 0.6
						draw_circle(tc + Vector2(cos(a), sin(a)) * tr * 0.62,
							maxf(0.8, tr * 0.11), Color("f7cfc8"))
			"lettuce":
				# a frill, not a stripe — the ruffly edge is what makes it lettuce
				var top := PackedVector2Array()
				var n := 22
				for i in n + 1:
					var v := float(i) / n
					top.append(Vector2(pos.x - w * 0.48 + w * 0.96 * v,
						pos.y - h * 0.52 + sin(v * PI * 4.0) * h * 0.2))
				var body := top.duplicate()
				body.append(Vector2(pos.x + w * 0.48, pos.y))
				body.append(Vector2(pos.x - w * 0.48, pos.y))
				draw_colored_polygon(body, Color("8cc188"))
				var inner := PackedVector2Array()
				for i in n + 1:
					var v := float(i) / n
					inner.append(Vector2(pos.x - w * 0.44 + w * 0.88 * v,
						pos.y - h * 0.36 + sin(v * PI * 4.0 + 0.5) * h * 0.15))
				inner.append(Vector2(pos.x + w * 0.44, pos.y - h * 0.04))
				inner.append(Vector2(pos.x - w * 0.44, pos.y - h * 0.04))
				draw_colored_polygon(inner, Color("a8d5a2"))
				draw_polyline(top, Color("bde0b6"), maxf(1.0, h * 0.09), true)
			"ham":
				# plant ham: a wavy-edged slice with a little marbling
				var edge := PackedVector2Array()
				var n2 := 18
				for i in n2 + 1:
					var v := float(i) / n2
					edge.append(Vector2(pos.x - w * 0.47 + w * 0.94 * v,
						pos.y - h * 0.62 + sin(v * PI * 3.0) * h * 0.1))
				var slab := edge.duplicate()
				slab.append(Vector2(pos.x + w * 0.47, pos.y - h * 0.04))
				slab.append(Vector2(pos.x - w * 0.47, pos.y - h * 0.04))
				draw_colored_polygon(slab, Color("e89a92"))
				var lift := PackedVector2Array()
				for i in n2 + 1:
					var v := float(i) / n2
					lift.append(Vector2(pos.x - w * 0.47 + w * 0.94 * v,
						pos.y - h * 0.6 + sin(v * PI * 3.0) * h * 0.1))
				lift.append(Vector2(pos.x + w * 0.47, pos.y - h * 0.3))
				lift.append(Vector2(pos.x - w * 0.47, pos.y - h * 0.3))
				draw_colored_polygon(lift, Color("f2b8b0"))
				for spec in [[-0.28, 0.34], [0.06, 0.42], [0.3, 0.3]]:
					draw_line(Vector2(pos.x + w * float(spec[0]) - w * 0.06,
							pos.y - h * float(spec[1])),
						Vector2(pos.x + w * float(spec[0]) + w * 0.06,
							pos.y - h * float(spec[1])),
						Color("f9d3ce"), maxf(1.0, h * 0.11))
			"cucumber":
				# rounds, with the dark rind and the pale seedy middle
				for i in 4:
					var cx := pos.x - w * 0.3 + i * w * 0.2
					var cc := Vector2(cx, pos.y - h * 0.42)
					var cr := h * 0.46
					draw_circle(cc, cr, Color("5f9a5c"))
					draw_circle(cc, cr * 0.84, Color("8cc188"))
					draw_circle(cc, cr * 0.56, Color("d4ecc8"))
					for k in 3:
						var a2 := k / 3.0 * TAU + 1.1
						draw_circle(cc + Vector2(cos(a2), sin(a2)) * cr * 0.26,
							maxf(0.8, cr * 0.1), Color("b8dcae"))
