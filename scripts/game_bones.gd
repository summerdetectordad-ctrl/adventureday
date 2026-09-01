class_name BoneGame
extends MiniGame
## Bone Builder — Dino Land. A faint skeleton outline on the rock wall and a
## pile of bones in the sand. Drag each bone to the silhouette it fits.
##
## A bone snaps home when it is close to the right outline and drifts gently
## back when it is not — it never disappears, and the wall never runs out of
## patience. Shape and spatial matching, plus size ordering as the levels go up.

const SHAPES := ["long", "skull", "rib", "claw", "tail", "plate"]

var _slots: Array = []      # {shape, pos, filled}
var _bones: Array = []      # {shape, pos, home, placed}
var _drag := -1
var _body: Body = null


func build() -> void:
	_body = Body.new()
	_body.game = self
	add_child(_body)
	_lay_out()


func _lay_out() -> void:
	var n: int = [3, 4, 5][level]
	var kinds := SHAPES.duplicate()
	kinds.shuffle()
	kinds = kinds.slice(0, n)
	_slots = []
	_bones = []
	for i in n:
		_slots.append({"shape": kinds[i], "filled": false})
	var jumbled := kinds.duplicate()
	jumbled.shuffle()
	for i in n:
		_bones.append({"shape": jumbled[i], "pos": Vector2.ZERO,
			"home": Vector2.ZERO, "placed": false})
	if _body != null:
		_body.reposition()
		_body.queue_redraw()


func _drop(i: int, at: Vector2) -> void:
	# which slot is it nearest?
	var best := -1
	var best_d := 92.0
	for s in _slots.size():
		if _slots[s]["filled"]:
			continue
		var d: float = at.distance_to(_body.slot_pos(s))
		if d < best_d:
			best_d = d
			best = s
	if best >= 0 and str(_slots[best]["shape"]) == str(_bones[i]["shape"]):
		_slots[best]["filled"] = true
		_bones[i]["placed"] = true
		_bones[i]["pos"] = _body.slot_pos(best)
		hit()
		Sound.knock()
		if _done():
			_finish()
	else:
		# not that one — it drifts back to the sand, nothing lost
		missed()
		var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var home: Vector2 = _bones[i]["home"]
		var bone: Dictionary = _bones[i]
		tw.tween_method(func(v: Vector2) -> void:
			bone["pos"] = v
			if _body != null:
				_body.queue_redraw(), at, home, 0.35)


func _done() -> bool:
	for s in _slots:
		if not s["filled"]:
			return false
	return true


func _finish() -> void:
	give("find:dino_bone", 1)
	give("timber", 2)
	await get_tree().create_timer(1.6).timeout
	if is_inside_tree():
		closed.emit()


class Body extends Control:
	var game: BoneGame = null
	var t := 0.0

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		size = get_viewport().get_visible_rect().size
		reposition()

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func reposition() -> void:
		size = get_viewport().get_visible_rect().size
		for i in game._bones.size():
			if not game._bones[i]["placed"]:
				game._bones[i]["home"] = bone_home(i, game._bones.size())
				game._bones[i]["pos"] = game._bones[i]["home"]

	func slot_pos(i: int) -> Vector2:
		var n := game._slots.size()
		var vs := size
		var span := minf(vs.x - 320.0, n * 180.0)
		return Vector2(vs.x * 0.5 - span * 0.5 + span * (float(i) + 0.5) / n, vs.y * 0.34)

	func bone_home(i: int, n: int) -> Vector2:
		var vs := size
		var span := minf(vs.x - 320.0, n * 180.0)
		return Vector2(vs.x * 0.5 - span * 0.5 + span * (float(i) + 0.5) / n, vs.y * 0.76)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				for i in game._bones.size():
					if game._bones[i]["placed"]:
						continue
					if (event.position - game._bones[i]["pos"]).length() < 62.0:
						game._drag = i
						break
			elif game._drag >= 0:
				var i := game._drag
				game._drag = -1
				game._drop(i, event.position)
			accept_event()
		elif event is InputEventMouseMotion and game._drag >= 0:
			game._bones[game._drag]["pos"] = event.position
			queue_redraw()
			accept_event()

	func _draw() -> void:
		var vs := size
		size = get_viewport().get_visible_rect().size
		MiniGame.backdrop(self, vs, Color("d9cfae"))
		# the rock wall the skeleton goes on
		DrawKit.rounded_rect(self, Rect2(40, vs.y * 0.14, vs.x - 80, vs.y * 0.42), 18.0,
			Color("b09a82"))
		DrawKit.rounded_rect(self, Rect2(56, vs.y * 0.16, vs.x - 112, vs.y * 0.38), 14.0,
			Color("bfa992"))
		# the sand tray the loose bones sit in
		DrawKit.rounded_rect(self, Rect2(40, vs.y * 0.64, vs.x - 80, vs.y * 0.26), 18.0,
			Color("e0d2ac"))

		game.say(self, "", "put the bones back", "match each bone to its shape",
			Vector2(vs.x * 0.5, 84))

		# the faint outlines
		for i in game._slots.size():
			var p := slot_pos(i)
			var filled: bool = game._slots[i]["filled"]
			if not filled:
				draw_circle(p, 56.0, Color(1, 1, 1, 0.16 + 0.05 * sin(t * 2.0 + i)))
				_bone(str(game._slots[i]["shape"]), p, Color(0.35, 0.28, 0.22, 0.30))

		# the bones, placed or still in the sand
		for i in game._bones.size():
			var b: Dictionary = game._bones[i]
			var p: Vector2 = b["pos"]
			var lift := 1.16 if game._drag == i else 1.0
			if not b["placed"]:
				DrawKit.ellipse(self, p + Vector2(0, 40), 34.0 * lift, 9.0, Color(0, 0, 0, 0.12))
			draw_set_transform(p, 0.0, Vector2(lift, lift))
			_bone(str(b["shape"]), Vector2.ZERO, Color("efe6d0"))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		var done := 0
		for s in game._slots:
			if s["filled"]:
				done += 1
		MiniGame.progress(self, done, game._slots.size(), Vector2(vs.x * 0.5, vs.y - 46))

	## One bone. Simple, chunky shapes that read at a glance and are clearly
	## different from each other.
	func _bone(shape: String, p: Vector2, col: Color) -> void:
		match shape:
			"long":
				draw_rect(Rect2(p.x - 42, p.y - 9, 84, 18), col)
				for sx in [-1.0, 1.0]:
					draw_circle(p + Vector2(sx * 42, -11), 13.0, col)
					draw_circle(p + Vector2(sx * 42, 11), 13.0, col)
			"skull":
				DrawKit.ellipse(self, p + Vector2(0, -4), 34.0, 27.0, col)
				DrawKit.ellipse(self, p + Vector2(-6, 20), 20.0, 14.0, col)
				draw_circle(p + Vector2(-13, -6), 7.0, col.darkened(0.45))
				draw_circle(p + Vector2(11, -6), 7.0, col.darkened(0.45))
			"rib":
				for i in 3:
					draw_arc(p + Vector2(0, -20 + i * 20), 30.0 - i * 3.0, PI * 0.15, PI * 0.85,
						14, col, 9.0, true)
				draw_line(p + Vector2(0, -34), p + Vector2(0, 30), col, 9.0)
			"claw":
				draw_polygon(PackedVector2Array([
					p + Vector2(-26, 22), p + Vector2(-8, -30), p + Vector2(12, -26),
					p + Vector2(-6, 26),
				]), PackedColorArray([col]))
				draw_polygon(PackedVector2Array([
					p + Vector2(6, 22), p + Vector2(22, -18), p + Vector2(34, -10),
					p + Vector2(20, 26),
				]), PackedColorArray([col]))
			"tail":
				for i in 4:
					var s := 20.0 - i * 3.5
					DrawKit.ellipse(self, p + Vector2(-30 + i * 21, 0), s, s * 0.8, col)
			_:
				draw_polygon(PackedVector2Array([
					p + Vector2(-32, 24), p + Vector2(32, 24), p + Vector2(0, -32),
				]), PackedColorArray([col]))
				draw_polygon(PackedVector2Array([
					p + Vector2(-16, 20), p + Vector2(16, 20), p + Vector2(0, -10),
				]), PackedColorArray([col.darkened(0.12)]))
