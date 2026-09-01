class_name PlankGame
extends MiniGame
## Walk the Plank — Pirate Cove. Planks float between the beach and the wreck,
## each with a letter on it. She taps them in order to build the word and walks
## across to the ship.
##
## She is crossing TO the ship, never being made to walk off the end: a wrong
## plank wobbles, the parrot says the word again, and she stays exactly where
## she is. Phonics — blending and letter order — is the biggest Year 1 skill.

## Words with a picture we can actually draw, for the picture round.
const PICTURE_WORDS := [
	{"word": "sun", "icon": "sun"}, {"word": "star", "icon": "star"},
	{"word": "bird", "icon": "bird"}, {"word": "leaf", "icon": "leaf"},
	{"word": "heart", "icon": "heart"}, {"word": "flower", "icon": "flower"},
	{"word": "cloud", "icon": "cloud"},
]
const CVC := ["cat", "dog", "sun", "hat", "pig", "bus", "cup", "net", "log", "hen"]
const LONGER := ["ship", "fish", "shell", "chest", "sand", "moon", "star", "crab"]

const ROUNDS := 3

var _round := 0
var _word := ""
var _icon := ""
var _planks: Array = []      # {ch, done}
var _next := 0               # which letter she is looking for
var _wobble := -1
var _wob_t := 0.0
var _rlevel := 1        ## the level this ROUND is being played at, fixed at its
                        ## start — easing off mid-word would change the rules
var _body: Body = null


func build() -> void:
	_body = Body.new()
	_body.game = self
	add_child(_body)
	_new_round()


func _new_round() -> void:
	_next = 0
	_wobble = -1
	_rlevel = level
	if _rlevel == 0:
		var pick: Dictionary = PICTURE_WORDS[randi() % PICTURE_WORDS.size()]
		_word = pick["word"]
		_icon = pick["icon"]
		# three planks: the right first letter and two others
		var letters := [_word[0]]
		while letters.size() < 3:
			var c := char(97 + randi() % 26)
			if not letters.has(c):
				letters.append(c)
		letters.shuffle()
		_planks = []
		for c in letters:
			_planks.append({"ch": c, "done": false})
	else:
		_icon = ""
		_word = (CVC if _rlevel == 1 else LONGER)[randi() % (CVC if _rlevel == 1 else LONGER).size()]
		var chars: Array = []
		for i in _word.length():
			chars.append(_word[i])
		chars.shuffle()
		_planks = []
		for c in chars:
			_planks.append({"ch": c, "done": false})
	if _body != null:
		_body.queue_redraw()


## Which letter she needs next.
func _wanted() -> String:
	if _rlevel == 0:
		return _word[0]
	return _word[_next]


func _tap_plank(i: int) -> void:
	if i < 0 or i >= _planks.size() or _planks[i]["done"]:
		return
	if str(_planks[i]["ch"]) == _wanted():
		_planks[i]["done"] = true
		_next += 1
		hit()
		Sound.knock()
		var finished := (_rlevel == 0) or _next >= _word.length()
		if finished:
			_round += 1
			give("find:pirate_coin", 1)
			give("fruit", 2)
			if _round >= ROUNDS:
				_finish()
			else:
				await get_tree().create_timer(1.1).timeout
				if is_inside_tree():
					_new_round()
	else:
		# the plank wobbles and the parrot says it again; nothing is lost
		_wobble = i
		_wob_t = 1.0
		missed()
		Sound.chirp()
	if _body != null:
		_body.queue_redraw()


func _finish() -> void:
	await get_tree().create_timer(1.2).timeout
	if is_inside_tree():
		closed.emit()


class Body extends Control:
	var game: PlankGame = null
	var t := 0.0
	var _rects: Array = []

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		size = get_viewport().get_visible_rect().size

	func _process(delta: float) -> void:
		t += delta
		if game != null and game._wob_t > 0.0:
			game._wob_t = maxf(0.0, game._wob_t - delta * 2.5)
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if not (event is InputEventMouseButton and event.pressed):
			return
		accept_event()
		var p: Vector2 = event.position
		for i in _rects.size():
			if (_rects[i] as Rect2).has_point(p):
				game._tap_plank(i)
				return

	func plank_pos(i: int, n: int) -> Vector2:
		var vs := size
		var span := minf(vs.x - 360.0, n * 190.0)
		var x := vs.x * 0.5 - span * 0.5 + span * (float(i) + 0.5) / n
		return Vector2(x, vs.y * 0.62 + sin(t * 1.2 + i) * 5.0)

	func _draw() -> void:
		var vs := size
		size = get_viewport().get_visible_rect().size
		MiniGame.backdrop(self, vs, Color("bfe0ee"))
		# sea below the planks
		draw_rect(Rect2(0, vs.y * 0.5, vs.x, vs.y * 0.5), Color("7fb5c9"))
		for band in 4:
			var pts := PackedVector2Array()
			var y := vs.y * 0.56 + band * 40.0
			var x := 0.0
			while x <= vs.x:
				pts.append(Vector2(x, y + sin(x * 0.014 + t * (0.6 + band * 0.2)) * 5.0))
				x += 40.0
			draw_polyline(pts, Color(1, 1, 1, 0.22), 3.0)
		# the beach she starts from and the ship she is heading for
		draw_rect(Rect2(0, vs.y * 0.5, 150, vs.y * 0.5), Color("e0d2ac"))
		_ship(Vector2(vs.x - 130, vs.y * 0.5))

		var font := ThemeDB.fallback_font
		# what to do, and what she is building
		if game._rlevel == 0:
			game.say(self, "", "which sound does it start with?",
				"tap the plank with the first sound", Vector2(vs.x * 0.5, 100))
			draw_set_transform(Vector2(vs.x * 0.5, 190), 0.0, Vector2(1.6, 1.6))
			DrawKit.draw_icon(self, game._icon, 46.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			game.say(self, "", "build the word", "tap the letters in order",
				Vector2(vs.x * 0.5, 100))
			# The word she is building. Letters she has not placed yet are shown
			# faintly, so she can always SEE the word she is making — without
			# that there is no way to know which plank comes next.
			var cell := 56.0
			var start := vs.x * 0.5 - (game._word.length() - 1) * cell * 0.5
			for i in game._word.length():
				var c := Vector2(start + i * cell, 190)
				var got := i < game._next
				DrawKit.rounded_rect(self, Rect2(c.x - 24, c.y - 30, 48, 60), 8.0,
					Color("fff8ec") if got else Color(1, 1, 1, 0.5))
				var ch := game._word[i]
				var w := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
				draw_string(font, c + Vector2(-w / 2.0, 14), ch,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 40,
					MiniGame.INK if got else Color(0.55, 0.47, 0.38, 0.45))
				# a soft ring round the letter she is looking for next
				if i == game._next:
					draw_arc(c, 34.0, 0, TAU, 26,
						Color(1.0, 0.85, 0.54, 0.5 + 0.35 * sin(t * 3.0)), 3.5, true)

		# the planks
		_rects.clear()
		for i in game._planks.size():
			var pp := plank_pos(i, game._planks.size())
			var wob := 0.0
			if game._wobble == i and game._wob_t > 0.0:
				wob = sin(game._wob_t * PI * 5.0) * 10.0 * game._wob_t
			var r := Rect2(pp.x - 74 + wob, pp.y - 34, 148, 68)
			_rects.append(r)
			var done: bool = game._planks[i]["done"]
			DrawKit.rounded_rect(self, Rect2(r.position + Vector2(0, 5), r.size), 8.0,
				Color(0, 0, 0, 0.12))
			DrawKit.rounded_rect(self, r, 8.0,
				Color("8fc48a") if done else Color("c9a06c"))
			draw_rect(Rect2(r.position.x + 6, r.position.y + 6, r.size.x - 12, 5),
				Color(1, 1, 1, 0.25))
			var ch: String = str(game._planks[i]["ch"])
			var cw := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 42).x
			draw_string(font, r.get_center() + Vector2(-cw / 2.0, 15), ch,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 42,
				Color("3f5c3a") if done else Color("5e4433"))

		# Summer stepping across as she gets them right
		var walked := float(game._next) / maxf(1.0, float(game._planks.size()))
		var sp := Vector2(lerpf(90.0, vs.x - 190.0, walked), vs.y * 0.62 - 60.0)
		_summer(sp)
		MiniGame.progress(self, game._round, PlankGame.ROUNDS, Vector2(vs.x * 0.5, vs.y - 54))

	## A little Summer, just enough to read as her.
	func _summer(p: Vector2) -> void:
		var bob := sin(t * 2.4) * 2.0
		DrawKit.ellipse(self, p + Vector2(0, 34), 18.0, 6.0, Color(0, 0, 0, 0.12))
		draw_rect(Rect2(p.x - 9, p.y - 4 + bob, 18, 26), Color("9bb07a"))
		DrawKit.rounded_rect(self, Rect2(p.x - 11, p.y - 22 + bob, 22, 22), 6.0, Color("cfe0a8"))
		draw_circle(p + Vector2(0, -32 + bob), 13.0, Color("f2d3a8"))
		DrawKit.ellipse(self, p + Vector2(0, -42 + bob), 19.0, 6.0, Color("d9b45c"))
		draw_circle(p + Vector2(-4, -34 + bob), 1.8, Color("3a3a44"))
		draw_circle(p + Vector2(4, -34 + bob), 1.8, Color("3a3a44"))
		draw_arc(p + Vector2(0, -30 + bob), 5.0, 0.3, PI - 0.3, 8, Color("c0705f"), 1.6, true)

	func _ship(p: Vector2) -> void:
		draw_polygon(PackedVector2Array([
			p + Vector2(-90, -10), p + Vector2(90, -10),
			p + Vector2(64, -76), p + Vector2(-64, -76),
		]), PackedColorArray([Color("8a6a52")]))
		draw_line(p + Vector2(0, -76), p + Vector2(0, -230), Color("8a6a52"), 10.0)
		draw_polygon(PackedVector2Array([
			p + Vector2(4, -224), p + Vector2(84, -168), p + Vector2(4, -120),
		]), PackedColorArray([Color("f2e6c8")]))
		draw_polygon(PackedVector2Array([
			p + Vector2(-4, -216), p + Vector2(-70, -170), p + Vector2(-4, -130),
		]), PackedColorArray([Color("e4d5b2")]))
		# the parrot, who says the word again when she needs it
		var flap := sin(t * 3.0) * 2.0
		draw_circle(p + Vector2(-30, -92 + flap), 11.0, Color("d94f4f"))
		draw_circle(p + Vector2(-30, -104 + flap), 8.0, Color("d94f4f"))
		draw_polygon(PackedVector2Array([
			p + Vector2(-23, -106 + flap), p + Vector2(-13, -102 + flap),
			p + Vector2(-23, -99 + flap),
		]), PackedColorArray([Color("f0c04a")]))
		draw_circle(p + Vector2(-27, -106 + flap), 2.0, Color.WHITE)
