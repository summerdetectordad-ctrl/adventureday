class_name MemoryGame
extends MiniGame
## Memory Museum — inside the treehouse. Cards face-down on a spare shelf, and
## the faces are HER OWN finds and photographs. Turn two over and see if they
## match.
##
## Because the deck comes from her collection, the game is different every few
## sessions without anyone writing new content — which is exactly why it earns
## its place. Nothing is timed and a wrong pair simply turns back over.

const ROUNDS := 1

var _cards: Array = []     # {kind, up, done}
var _first := -1
var _second := -1
var _busy := false
var _cols := 4          ## fixed when the cards are dealt — the grid must never
                        ## re-lay out mid-game, or she loses track of the cards
var _body: Body = null


func build() -> void:
	_body = Body.new()
	_body.game = self
	add_child(_body)
	_deal()


## Build the deck from what she has actually collected, falling back to the
## classic finds early on when the museum is still nearly empty.
func _deal() -> void:
	var pairs: int = [3, 4, 6][level]
	_cols = [3, 4, 4][level]
	var pool: Array = []
	for kind in GameState.shelf.values():
		if not pool.has(kind):
			pool.append(kind)
	for kind in GameState.satchel:
		if not pool.has(kind):
			pool.append(kind)
	for kind in ["ammonite", "dino_bone", "trilobite", "roman_coin", "gem", "dino_egg"]:
		if not pool.has(kind):
			pool.append(kind)
	pool.shuffle()
	_cards = []
	for i in pairs:
		var kind: String = str(pool[i % pool.size()])
		for k in 2:
			_cards.append({"kind": kind, "up": false, "done": false})
	_cards.shuffle()
	if _body != null:
		_body.queue_redraw()


func _tap(i: int) -> void:
	if _busy or i < 0 or i >= _cards.size():
		return
	if _cards[i]["up"] or _cards[i]["done"]:
		return
	_cards[i]["up"] = true
	Sound.pop()
	if _first < 0:
		_first = i
	else:
		_second = i
		_busy = true
		await get_tree().create_timer(0.85).timeout
		if not is_inside_tree():
			return
		if str(_cards[_first]["kind"]) == str(_cards[_second]["kind"]):
			_cards[_first]["done"] = true
			_cards[_second]["done"] = true
			hit()
			give(["stick", "plank", "rope"][randi() % 3], 2)
			if _all_done():
				_finish()
		else:
			_cards[_first]["up"] = false
			_cards[_second]["up"] = false
			missed()
		_first = -1
		_second = -1
		_busy = false
	if _body != null:
		_body.queue_redraw()


func _all_done() -> bool:
	for c in _cards:
		if not c["done"]:
			return false
	return true


func _finish() -> void:
	give("plank", 2)
	Sound.chime_shelf()
	await get_tree().create_timer(1.6).timeout
	if is_inside_tree():
		closed.emit()


class Body extends Control:
	var game: MemoryGame = null
	var t := 0.0
	var _rects: Array = []

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
		for i in _rects.size():
			if (_rects[i] as Rect2).has_point(event.position):
				game._tap(i)
				return

	func _cols() -> int:
		return game._cols

	func _draw() -> void:
		var vs := size
		size = get_viewport().get_visible_rect().size
		MiniGame.backdrop(self, vs, Color("efe2c6"))
		# the treehouse wall, so it reads as being in her own museum
		for i in 9:
			draw_line(Vector2(i * vs.x / 8.0, 0), Vector2(i * vs.x / 8.0, vs.y),
				Color(0.78, 0.68, 0.53, 0.35), 3.0)

		game.say(self, "", "find the pairs", "turn two over and find a matching pair",
			Vector2(vs.x * 0.5, 92))

		var n := game._cards.size()
		var cols := _cols()
		var rows := int(ceil(float(n) / cols))
		var cw := minf(150.0, (vs.x - 220.0) / cols)
		var ch := minf(168.0, (vs.y - 300.0) / rows)
		var ox := vs.x * 0.5 - (cols - 1) * cw * 0.5
		var oy := vs.y * 0.52 - (rows - 1) * ch * 0.5

		_rects.clear()
		for i in n:
			var c := Vector2(ox + (i % cols) * cw, oy + floori(float(i) / cols) * ch)
			var r := Rect2(c.x - cw * 0.42, c.y - ch * 0.42, cw * 0.84, ch * 0.84)
			_rects.append(r)
			var card: Dictionary = game._cards[i]
			var up: bool = card["up"] or card["done"]
			# a shelf plank under each row
			if i % cols == 0:
				draw_rect(Rect2(ox - cw * 0.55, c.y + ch * 0.44, cols * cw, 9.0),
					Color("a97e54"))
			DrawKit.rounded_rect(self, Rect2(r.position + Vector2(0, 5), r.size), 10.0,
				Color(0, 0, 0, 0.10))
			if up:
				DrawKit.rounded_rect(self, r, 10.0, Color("fff8ec"))
				draw_set_transform(r.get_center(), 0.0, Vector2.ONE)
				DrawKit.draw_find(self, str(card["kind"]), minf(r.size.x, r.size.y) * 0.30)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				if card["done"]:
					draw_arc(r.get_center(), minf(r.size.x, r.size.y) * 0.46, 0, TAU, 26,
						Color("8fc48a"), 4.0, true)
			else:
				# the back: a little star, so every card looks inviting
				DrawKit.rounded_rect(self, r, 10.0, Color("c9a06c"))
				DrawKit.rounded_rect(self, Rect2(r.position + Vector2(7, 7),
					r.size - Vector2(14, 14)), 7.0, Color("d9b485"))
				DrawKit.star(self, r.get_center(), minf(r.size.x, r.size.y) * 0.18,
					Color(1, 1, 1, 0.55))

		var done := 0
		for c in game._cards:
			if c["done"]:
				done += 1
		MiniGame.progress(self, done / 2, game._cards.size() / 2,
			Vector2(vs.x * 0.5, vs.y - 40))
