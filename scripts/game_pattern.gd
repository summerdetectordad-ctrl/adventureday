class_name PatternGame
extends MiniGame
## Pattern Patch — the garden. A row of flowers in a repeating pattern with one
## gap in it. She picks the flower that belongs, then plants a row of her own.
##
## Repeating patterns are core Reception and Year 1 maths, and the real
## foundation for algebra. A wrong pick wobbles and the row stays exactly as it
## was; the pattern is never taken away and re-rolled to punish a miss.

const COLOURS := ["e8918c", "ffd98a", "a9c9e8", "c4b8e8", "8fc48a", "f2b8cf"]
const ROUNDS := 4

var _round := 0
var _row: Array = []       # colour indices; -1 is the gap
var _gap := 0
var _answer := 0
var _choices: Array = []
var _wobble := -1
var _wob_t := 0.0
var _solved := false
var _body: Body = null


func build() -> void:
	_body = Body.new()
	_body.game = self
	add_child(_body)
	_new_row()


func _new_row() -> void:
	_solved = false
	_wobble = -1
	var palette := range(COLOURS.size())
	palette.shuffle()
	# the repeating unit: AB, then ABC or AAB, then longer
	var unit: Array = []
	match level:
		0: unit = [palette[0], palette[1]]
		1: unit = [palette[0], palette[1], palette[2]] if randf() < 0.5 \
			else [palette[0], palette[0], palette[1]]
		_: unit = [palette[0], palette[1], palette[1], palette[2]]
	var length: int = [6, 7, 8][level]
	_row = []
	for i in length:
		_row.append(unit[i % unit.size()])
	# At the easier levels the gap is at the END — "what comes next" is the
	# classic form and the clearest. Only the hardest level hides it mid-row,
	# where the wording changes to "fill the gap" to match.
	if level < 2:
		_gap = length - 1
	else:
		_gap = 2 + randi() % (length - 3)
	_answer = _row[_gap]
	_row[_gap] = -1
	# the choices
	var opts := [_answer]
	var n_opts: int = [2, 3, 3][level]
	while opts.size() < n_opts:
		var o: int = palette[randi() % palette.size()]
		if not opts.has(o):
			opts.append(o)
	opts.shuffle()
	_choices = opts
	if _body != null:
		_body.queue_redraw()


func _pick(i: int) -> void:
	if _solved:
		return
	if int(_choices[i]) == _answer:
		_row[_gap] = _answer
		_solved = true
		_round += 1
		hit()
		give("seed", 1)
		give("fruit", 2)
		if _body != null:
			_body.queue_redraw()
		await get_tree().create_timer(1.3).timeout
		if not is_inside_tree():
			return
		if _round >= ROUNDS:
			closed.emit()
		else:
			_new_row()
	else:
		_wobble = i
		_wob_t = 1.0
		missed()
		if _body != null:
			_body.queue_redraw()


class Body extends Control:
	var game: PatternGame = null
	var t := 0.0
	var _picks: Array = []

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
		for i in _picks.size():
			if (_picks[i] as Rect2).has_point(event.position):
				game._pick(i)
				return

	func _draw() -> void:
		var vs := size
		size = get_viewport().get_visible_rect().size
		MiniGame.backdrop(self, vs, Color("cfe4c6"))
		# the soil bed the row is planted in
		DrawKit.rounded_rect(self, Rect2(50, vs.y * 0.44, vs.x - 100, 96), 16.0, Color("8a6a4c"))
		DrawKit.rounded_rect(self, Rect2(50, vs.y * 0.44, vs.x - 100, 22), 12.0, Color("9c7a58"))

		game.say(self, "", "which one comes next?", "which flower fills the gap?",
			Vector2(vs.x * 0.5, 116))

		# the row
		var n := game._row.size()
		var span := minf(vs.x - 160.0, n * 116.0)
		for i in n:
			var x := vs.x * 0.5 - span * 0.5 + span * (float(i) + 0.5) / n
			var y := vs.y * 0.44 + 6.0
			var idx: int = int(game._row[i])
			if idx < 0:
				# the gap, gently pulsing so it is obvious where to look
				var pulse := 0.4 + 0.25 * sin(t * 2.4)
				draw_circle(Vector2(x, y - 46), 34.0, Color(1, 1, 1, pulse))
				draw_arc(Vector2(x, y - 46), 34.0, 0, TAU, 26, Color("8a6a4c"), 3.0, true)
				DrawKit.ellipse(self, Vector2(x, y + 14), 14.0, 6.0, Color("6f5540"))
			else:
				_flower(Vector2(x, y), idx, 1.0)

		# the flowers to choose from
		_picks.clear()
		for i in game._choices.size():
			var cx := vs.x * 0.5 + (float(i) - (game._choices.size() - 1) * 0.5) * 170.0
			var wob := 0.0
			if game._wobble == i and game._wob_t > 0.0:
				wob = sin(game._wob_t * PI * 5.0) * 10.0 * game._wob_t
			var c := Vector2(cx + wob, vs.y * 0.76)
			_picks.append(Rect2(c.x - 62, c.y - 62, 124, 124))
			draw_circle(c + Vector2(0, 5), 56.0, Color(0, 0, 0, 0.08))
			draw_circle(c, 56.0, Color(1, 1, 1, 0.92))
			_flower(c + Vector2(0, 28), int(game._choices[i]), 1.05)

		MiniGame.progress(self, game._round, PatternGame.ROUNDS, Vector2(vs.x * 0.5, vs.y - 40))

	## One flower, growing out of the soil.
	func _flower(base: Vector2, idx: int, s: float) -> void:
		var col := Color(PatternGame.COLOURS[idx % PatternGame.COLOURS.size()])
		var sway := sin(t * 1.1 + base.x * 0.01) * 2.0
		var head := base + Vector2(sway, -46.0 * s)
		draw_line(base, head, Color("6f9a5d"), 5.0 * s)
		DrawKit.ellipse(self, base + Vector2(-9 * s, -18 * s), 9.0 * s, 4.5 * s, Color("83b86f"))
		DrawKit.ellipse(self, base + Vector2(9 * s, -26 * s), 8.0 * s, 4.0 * s, Color("8fc48a"))
		for p in 6:
			var a := TAU * p / 6.0
			DrawKit.ellipse(self, head + Vector2.from_angle(a) * 15.0 * s,
				11.0 * s, 8.0 * s, col)
		draw_circle(head, 11.0 * s, col.lightened(0.18))
		draw_circle(head, 7.0 * s, Color("ffd98a"))
		draw_circle(head + Vector2(-2 * s, -2 * s), 3.0 * s, Color("ffe6b3"))
