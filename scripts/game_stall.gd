class_name StallGame
extends MiniGame
## Market Stall — the Market. She runs the stall instead of buying from it. A
## customer asks for some apples and some plums; she puts them in the basket,
## and then says how many that is altogether.
##
## The order is shown as pictures AND numerals, so it works before she can
## read. Nothing is timed, an over-filled basket can be emptied by tapping a
## fruit back out, and the total is picked from three answers — a wrong one
## wobbles and asks again.

const FRUITS := ["apple", "plum", "pear"]
const ROUNDS := 3

var _round := 0
var _order: Array = []       # [{fruit, want, got}]
var _stage := "filling"      # filling | total | done
var _choices: Array = []     # the three totals offered
var _wobble := -1
var _wob_t := 0.0
var _body: Body = null


func build() -> void:
	_body = Body.new()
	_body.game = self
	add_child(_body)
	_new_order()


func _new_order() -> void:
	_stage = "filling"
	_wobble = -1
	var kinds := FRUITS.duplicate()
	kinds.shuffle()
	var lines := 1 if level == 0 else 2
	var cap: int = [3, 5, 9][level]
	_order = []
	for i in lines:
		_order.append({"fruit": kinds[i], "want": 1 + randi() % cap, "got": 0})
	if _body != null:
		_body.queue_redraw()


func _total() -> int:
	var n := 0
	for line in _order:
		n += int(line["want"])
	return n


func _filled() -> bool:
	for line in _order:
		if int(line["got"]) != int(line["want"]):
			return false
	return true


## Tap a fruit on the counter to put one in the basket; tap one IN the basket
## to take it back out. Nothing is ever stuck.
func _add(fruit: String) -> void:
	for line in _order:
		if str(line["fruit"]) == fruit:
			line["got"] = int(line["got"]) + 1
			Sound.pop()
			break
	_check_filled()


func _take_back(fruit: String) -> void:
	for line in _order:
		if str(line["fruit"]) == fruit and int(line["got"]) > 0:
			line["got"] = int(line["got"]) - 1
			Sound.pop()
			break
	if _body != null:
		_body.queue_redraw()


func _check_filled() -> void:
	if not _filled():
		if _body != null:
			_body.queue_redraw()
		return
	hit()
	if level == 0:
		# Reception: filling the order IS the game
		_round_done()
		return
	# otherwise: and how many is that altogether?
	_stage = "total"
	var t := _total()
	var opts := [t]
	while opts.size() < 3:
		var o := maxi(1, t + (randi() % 5) - 2)
		if not opts.has(o):
			opts.append(o)
	opts.shuffle()
	_choices = opts
	if _body != null:
		_body.queue_redraw()


func _answer(n: int, index: int) -> void:
	if n == _total():
		hit()
		_round_done()
	else:
		_wobble = index
		_wob_t = 1.0
		missed()
	if _body != null:
		_body.queue_redraw()


func _round_done() -> void:
	_stage = "done"
	_round += 1
	give("fruit", 3)
	give(["plank", "rope", "seed"][randi() % 3], 1)
	Sound.chime_shelf()
	if _body != null:
		_body.queue_redraw()
	await get_tree().create_timer(1.4).timeout
	if not is_inside_tree():
		return
	if _round >= ROUNDS:
		closed.emit()
	else:
		_new_order()


class Body extends Control:
	var game: StallGame = null
	var t := 0.0
	var _counter: Array = []   # {rect, fruit}
	var _basket: Array = []    # {rect, fruit}
	var _answers: Array = []   # {rect, n}

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		size = get_viewport().get_visible_rect().size

	func _process(delta: float) -> void:
		t += delta
		if game._wob_t > 0.0:
			game._wob_t = maxf(0.0, game._wob_t - delta * 2.5)
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if not (event is InputEventMouseButton and event.pressed):
			return
		accept_event()
		var p: Vector2 = event.position
		if game._stage == "filling":
			for c in _counter:
				if (c["rect"] as Rect2).has_point(p):
					game._add(str(c["fruit"]))
					return
			for b in _basket:
				if (b["rect"] as Rect2).has_point(p):
					game._take_back(str(b["fruit"]))
					return
		elif game._stage == "total":
			for i in _answers.size():
				if (_answers[i]["rect"] as Rect2).has_point(p):
					game._answer(int(_answers[i]["n"]), i)
					return

	func _draw() -> void:
		var vs := size
		size = get_viewport().get_visible_rect().size
		MiniGame.backdrop(self, vs, Color("e8dcc4"))
		# the stall: striped awning across the top, counter across the middle
		draw_rect(Rect2(30, 30, vs.x - 60, 40), Color("f4ead6"))
		for i in int((vs.x - 60) / 48.0):
			draw_rect(Rect2(30 + i * 48, 30, 24, 40), Color("c96b64"))
		DrawKit.rounded_rect(self, Rect2(40, vs.y * 0.56, vs.x - 80, 26), 6.0, Color("a97e54"))

		# ONE instruction line, at the top, which changes with the stage. It used
		# to draw a second line down among the answer buttons, right on top of
		# them.
		if game._stage == "total":
			game.say(self, "", "how many altogether?",
				"how many are there altogether?", Vector2(vs.x * 0.5, 116))
		else:
			game.say(self, "", "fill the basket",
				"put the right number in the basket", Vector2(vs.x * 0.5, 116))

		_draw_order(vs)
		_draw_counter(vs)
		_draw_basket(vs)
		if game._stage == "total":
			_draw_total(vs)
		else:
			_answers.clear()
		MiniGame.progress(self, game._round, StallGame.ROUNDS, Vector2(vs.x * 0.5, vs.y - 40))

	## What the customer asked for — pictures and numerals side by side.
	func _draw_order(vs: Vector2) -> void:
		var font := ThemeDB.fallback_font
		var y := 178.0
		var n := game._order.size()
		for i in n:
			var line: Dictionary = game._order[i]
			var cx := vs.x * 0.5 + (float(i) - (n - 1) * 0.5) * 260.0
			DrawKit.rounded_rect(self, Rect2(cx - 110, y - 44, 220, 92), 14.0, Color("fff8ec"))
			var want := int(line["want"])
			var got := int(line["got"])
			_fruit(Vector2(cx - 64, y), str(line["fruit"]), 1.0)
			var txt := "%d" % want
			var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 46).x
			draw_string(font, Vector2(cx - 4 - w * 0.5, y + 16), txt,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 46, MiniGame.INK)
			# a tick once that line is right
			if got == want:
				draw_polyline(PackedVector2Array([
					Vector2(cx + 52, y), Vector2(cx + 66, y + 14), Vector2(cx + 92, y - 18),
				]), Color("8fc48a"), 7.0)
			else:
				draw_string(font, Vector2(cx + 52, y + 12), "%d" % got,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 34, MiniGame.SOFT)

	## The fruit she can pick up, on the counter. Once the basket is full they
	## fade back, so it is obvious the question has moved on to the total.
	func _draw_counter(vs: Vector2) -> void:
		_counter.clear()
		var live := game._stage == "filling"
		var n := game._order.size()
		for i in n:
			var line: Dictionary = game._order[i]
			var cx := vs.x * 0.5 + (float(i) - (n - 1) * 0.5) * 240.0
			var c := Vector2(cx, vs.y * 0.56 - 44.0)
			var r := Rect2(c.x - 54, c.y - 54, 108, 108)
			if live:
				_counter.append({"rect": r, "fruit": line["fruit"]})
			var a := 1.0 if live else 0.4
			draw_circle(c + Vector2(0, 4), 50.0, Color(0, 0, 0, 0.08 * a))
			draw_circle(c, 50.0, Color(1, 1, 1, 0.92 * a))
			_fruit(c, str(line["fruit"]), 1.5, a)

	## The basket, with what she has put in it so far.
	func _draw_basket(vs: Vector2) -> void:
		_basket.clear()
		var bx := vs.x * 0.5
		var by := vs.y * 0.80
		DrawKit.rounded_rect(self, Rect2(bx - 250, by - 46, 500, 92), 22.0, Color("d9b98c"))
		DrawKit.rounded_rect(self, Rect2(bx - 238, by - 36, 476, 72), 18.0, Color("cba874"))
		var placed := 0
		for line in game._order:
			for k in int(line["got"]):
				var px := bx - 214.0 + placed * 46.0
				var p := Vector2(px, by + sin(t * 2.0 + placed) * 2.0)
				_basket.append({"rect": Rect2(p.x - 22, p.y - 22, 44, 44),
					"fruit": line["fruit"]})
				_fruit(p, str(line["fruit"]), 0.72)
				placed += 1

	## The three totals to choose from, in the clear band between the counter
	## and the basket. The question itself lives on the instruction line up top.
	func _draw_total(vs: Vector2) -> void:
		var font := ThemeDB.fallback_font
		_answers.clear()
		for i in game._choices.size():
			var n: int = int(game._choices[i])
			var cx := vs.x * 0.5 + (float(i) - 1.0) * 150.0
			var wob := 0.0
			if game._wobble == i and game._wob_t > 0.0:
				wob = sin(game._wob_t * PI * 5.0) * 9.0 * game._wob_t
			var r := Rect2(cx - 56 + wob, vs.y * 0.60, 112, 92)
			_answers.append({"rect": r, "n": n})
			DrawKit.rounded_rect(self, Rect2(r.position + Vector2(0, 5), r.size), 16.0,
				Color(0, 0, 0, 0.1))
			DrawKit.rounded_rect(self, r, 16.0, Color("fff8ec"))
			var txt := "%d" % n
			var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 52).x
			draw_string(font, r.get_center() + Vector2(-w * 0.5, 19), txt,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 52, MiniGame.INK)

	func _fruit(p: Vector2, kind: String, s: float, a := 1.0) -> void:
		var col := Color("e05c50")
		if kind == "plum":
			col = Color("7a5490")
		elif kind == "pear":
			col = Color("bcd06a")
		draw_circle(p + Vector2(0, 2 * s), 24.0 * s, Color(col.darkened(0.2), a))
		draw_circle(p, 22.0 * s, Color(col, a))
		draw_circle(p + Vector2(-7 * s, -7 * s), 6.0 * s, Color(col.lightened(0.3), a))
		draw_line(p + Vector2(0, -20 * s), p + Vector2(3 * s, -31 * s),
			Color(Color("6f5a3f"), a), 3.0 * s)
		DrawKit.ellipse(self, p + Vector2(9 * s, -29 * s), 8.0 * s, 4.0 * s,
			Color(Color("8cc188"), a))
