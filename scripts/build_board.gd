class_name BuildBoard
extends CanvasLayer
## The plan board. Shows the treehouse exactly as it stands, with a glowing
## badge on every spot she could build next. Tap a badge and the part appears
## as a translucent ghost right where it would go, with what it needs listed as
## the material's own picture, the numeral and the word.
##
## Unaffordable spots are shown too, and are still tappable — seeing what is
## coming is half the fun. Tapping one wiggles the cost rather than refusing;
## nothing here is ever a failure.
##
## Draw order matters here: background panel, then the tree, then the ghost of
## the chosen part, then the badges and readouts on top of everything.

signal closed
signal build_chosen(id: String)
signal upgrade_chosen(id: String, colour: String)

const PAINTS := ["e8918c", "6fb3d2", "8fc48a", "ffd98a", "c4b8e8", "f2b8cf"]

var start_site := "home"

var _body: Body = null


func _ready() -> void:
	layer = 42
	_body = Body.new()
	_body.site = start_site
	_body.board = self
	add_child(_body)


func close() -> void:
	if _body != null:
		_body.dismiss()


## Background, state and input. Draws only the dim and the cream panel.
class Body extends Control:
	var board: BuildBoard = null
	var site := "home"
	var track := "structure"
	var selected := ""
	var t := 0.0
	var wiggle := 0.0
	var tree_origin := Vector2.ZERO
	var tree_scale := 1.0
	var badges: Array = []      # {pos, id, mode}  mode: "build" | "upgrade"
	var tabs: Array = []        # {rect, track}
	var sites: Array = []       # {rect, site}
	var paint_dots: Array = []  # {rect, hex}
	var action_rect := Rect2()
	var close_rect := Rect2()

	var _closing := false
	var _tree: Treehouse = null
	var _ghost: Treehouse = null
	var _overlay: Overlay = null

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		size = get_viewport().get_visible_rect().size
		_overlay = Overlay.new()
		_overlay.body = self
		_overlay.z_index = 4
		add_child(_overlay)
		_build_tree_view()
		modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 1.0, 0.18)

	func _build_tree_view() -> void:
		for n in [_tree, _ghost]:
			if n != null:
				n.queue_free()
		_tree = Treehouse.new()
		_tree.site = site
		_tree.z_index = 1
		add_child(_tree)
		# a second tree drawing on top that renders ONLY the selected part,
		# translucent — so she sees the actual thing, in its actual place
		_ghost = Treehouse.new()
		_ghost.site = site
		_ghost.ghost_only = true
		_ghost.z_index = 2
		_ghost.modulate = Color(1, 1, 1, 0.55)
		add_child(_ghost)
		_layout_tree()

	func set_preview(id: String) -> void:
		if _tree != null:
			_tree.preview_id = id
			_tree.refresh()
		if _ghost != null:
			_ghost.preview_id = id
			_ghost.refresh()

	func _layout_tree() -> void:
		var vs := size
		var area := Rect2(24, 74, vs.x * 0.58, vs.y - 190.0)
		tree_scale = minf(area.size.y / 620.0, area.size.x / 460.0)
		tree_origin = Vector2(area.position.x + area.size.x * 0.5,
			area.position.y + area.size.y - 18.0)
		for n in [_tree, _ghost]:
			if n != null:
				n.position = tree_origin
				n.scale = Vector2(tree_scale, tree_scale)

	func _process(delta: float) -> void:
		t += delta
		if wiggle > 0.0:
			wiggle = maxf(0.0, wiggle - delta * 4.0)
		_layout_tree()
		queue_redraw()

	## Where a part's spot lands on screen.
	func screen_of(id: String) -> Vector2:
		return tree_origin + BuildDefs.spot_of(id) * tree_scale

	## Everything on this track that belongs to the tree currently shown.
	func entries() -> Array:
		var out: Array = []
		for id in BuildDefs.ids_on_track(track):
			var s := BuildDefs.site_of(id)
			if not ((s == site) or (site == "home" and s == "ground")):
				continue
			if GameState.can_start(id):
				out.append({"id": id, "mode": "build"})
			elif GameState.can_upgrade(id):
				out.append({"id": id, "mode": "upgrade"})
		return out

	## Which trees she can see the board for — the far ones only once their
	## bridge exists, so the board never offers a tree she cannot reach.
	func visible_sites() -> Array:
		return board.visible_sites_now()

	# --- input ---------------------------------------------------------------

	func _gui_input(event: InputEvent) -> void:
		if not (event is InputEventMouseButton and event.pressed):
			return
		accept_event()
		var p: Vector2 = event.position

		if close_rect.has_point(p):
			dismiss()
			return
		for tab in tabs:
			if tab["rect"].has_point(p):
				track = tab["track"]
				selected = ""
				set_preview("")
				Sound.pop()
				return
		for s in sites:
			if s["rect"].has_point(p):
				site = s["site"]
				selected = ""
				# remembered, so the next visit opens on the same tree
				GameState.last_build_site = site
				GameState.save_game()
				_build_tree_view()
				Sound.pop()
				return
		for dot in paint_dots:
			if dot["rect"].has_point(p):
				_do_action(str(dot["hex"]))
				return
		if selected != "" and action_rect.has_point(p):
			_do_action("")
			return
		for b in badges:
			if (p - b["pos"]).length() < 46.0:
				selected = b["id"]
				set_preview(b["id"] if b["mode"] == "build" else "")
				Sound.pop()
				return
		# tapping the empty surround closes, like every other panel
		dismiss()

	func _do_action(colour: String) -> void:
		if selected == "":
			return
		var mode := "build" if GameState.can_start(selected) else "upgrade"
		var cost := BuildDefs.cost_of(selected) if mode == "build" \
			else GameState.upgrade_cost(selected)
		if not GameState.can_afford(cost):
			# never a refusal — the cost just gives a friendly shake
			wiggle = 1.0
			Sound.pop()
			return
		# the painted tier wants a colour; the swatches appear first
		if mode == "upgrade" and GameState.tier_of(selected) + 1 == BuildDefs.MAX_TIER \
				and colour == "":
			return
		var id := selected
		GameState.last_build_site = site
		GameState.save_game()
		if mode == "build":
			board.build_chosen.emit(id)
		else:
			board.upgrade_chosen.emit(id, colour)
		dismiss()

	func dismiss() -> void:
		if _closing:
			return
		_closing = true
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.16)
		tw.tween_callback(func() -> void:
			if board != null:
				board.closed.emit())

	func _draw() -> void:
		var vs := size
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.16, 0.13, 0.09, 0.55))
		DrawKit.rounded_rect(self, Rect2(12, 12, vs.x - 24, vs.y - 24), 18.0, Color("fff8ec"))


## Everything that has to sit above the tree: badges, the readout panel, the
## track tabs and the tree switcher.
class Overlay extends Control:
	var body: Body = null

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if body == null:
			return
		size = body.size
		var vs := body.size
		_draw_title(vs)
		_draw_badges()
		_draw_panel(vs)
		_draw_tabs(vs)
		_draw_sites(vs)

	func _draw_title(vs: Vector2) -> void:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(38, 56), "what shall we build?",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("7a5f42"))
		body.close_rect = Rect2(vs.x - 84, 26, 56, 56)
		var c := body.close_rect.get_center()
		draw_circle(c, 26.0, Color("efe3cf"))
		draw_line(c + Vector2(-9, -9), c + Vector2(9, 9), Color("8a7355"), 4.0)
		draw_line(c + Vector2(9, -9), c + Vector2(-9, 9), Color("8a7355"), 4.0)

	func _draw_badges() -> void:
		body.badges.clear()
		for entry in body.entries():
			var id: String = entry["id"]
			var mode: String = entry["mode"]
			var p := body.screen_of(id)
			body.badges.append({"pos": p, "id": id, "mode": mode})
			var cost := BuildDefs.cost_of(id) if mode == "build" \
				else GameState.upgrade_cost(id)
			var afford := GameState.can_afford(cost)
			var pulse := 0.5 + 0.5 * sin(body.t * 3.0 + p.x * 0.01)
			var ring := Color("8fc48a") if afford else Color("c9bda6")
			if id == body.selected:
				ring = Color("ffd98a")
			draw_circle(p, 34.0, Color(1, 1, 1, 0.92))
			draw_arc(p, 30.0, 0, TAU, 30, ring, 4.0 + (2.0 * pulse if afford else 0.0), true)
			if mode == "build":
				draw_line(p + Vector2(-12, 0), p + Vector2(12, 0), ring.darkened(0.15), 5.0)
				draw_line(p + Vector2(0, -12), p + Vector2(0, 12), ring.darkened(0.15), 5.0)
			else:
				# an up-arrow: this one is already built, but could be nicer
				draw_polygon(PackedVector2Array([
					p + Vector2(0, -13), p + Vector2(12, 2), p + Vector2(-12, 2),
				]), PackedColorArray([ring.darkened(0.15)]))
				draw_rect(Rect2(p.x - 5, p.y + 2, 10, 9), ring.darkened(0.15))

	func _draw_panel(vs: Vector2) -> void:
		var px := vs.x * 0.62
		var panel := Rect2(px, 84, vs.x - px - 34.0, vs.y - 200.0)
		DrawKit.rounded_rect(self, panel, 14.0, Color("f4ead6"))
		var font := ThemeDB.fallback_font
		body.paint_dots.clear()
		body.action_rect = Rect2()

		if body.selected == "":
			draw_string(font, Vector2(panel.position.x + 24, panel.position.y + 54),
				"tap a circle", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("a2917a"))
			draw_string(font, Vector2(panel.position.x + 24, panel.position.y + 86),
				"to see what it makes", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("a2917a"))
			_draw_stock(panel, font)
			return

		var mode := "build" if GameState.can_start(body.selected) else "upgrade"
		var cost := BuildDefs.cost_of(body.selected) if mode == "build" \
			else GameState.upgrade_cost(body.selected)
		var afford := GameState.can_afford(cost)

		draw_string(font, Vector2(panel.position.x + 24, panel.position.y + 50),
			BuildDefs.word_of(body.selected), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("6b4f38"))
		if mode == "upgrade":
			var nt: int = GameState.tier_of(body.selected) + 1
			draw_string(font, Vector2(panel.position.x + 24, panel.position.y + 82),
				"in " + BuildDefs.TIER_NAME[nt], HORIZONTAL_ALIGNMENT_LEFT, -1, 22,
				Color("a2917a"))

		# WHAT IT NEEDS. Coloured dots told her how many but never which — the
		# colour alone does not say "rope". So each line is the material's own
		# picture, the numeral, and the word, laid out exactly like the counters
		# along the top of the screen, which she already reads fluently.
		#
		# Underneath, how many she actually has, but only when it is short —
		# saying "you have 4" when she has plenty is just noise.
		var wob := sin(body.wiggle * PI * 4.0) * 6.0 * body.wiggle
		var y := panel.position.y + 132.0
		for k in cost:
			var n: int = int(cost[k])
			var have: int = int(GameState.materials.get(k, 0))
			var enough := have >= n
			var ink := Color("6b4f38") if enough else Color("c07a6a")
			var x := panel.position.x + 34.0 + wob

			draw_set_transform(Vector2(x + 20.0, y), 0.0, Vector2.ONE)
			DrawKit.draw_material(self, k, 21.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

			draw_string(font, Vector2(x + 54.0, y + 13.0), "%d" % n,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 38, ink)
			draw_string(font, Vector2(x + 92.0, y + 11.0),
				str(TopBar.NAMES.get(k, k)), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, ink)
			if not enough:
				draw_string(font, Vector2(x + 54.0, y + 38.0),
					"you have %d" % have, HORIZONTAL_ALIGNMENT_LEFT, -1, 19,
					Color("b5a68e"))
				y += 20.0
			y += 50.0

		# the paint swatches, when this upgrade is the painted one
		if mode == "upgrade" and GameState.tier_of(body.selected) + 1 == BuildDefs.MAX_TIER \
				and afford:
			draw_string(font, Vector2(panel.position.x + 24, y + 22), "pick a colour",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("8a7355"))
			for i in PAINTS.size():
				var r := Rect2(panel.position.x + 26 + (i % 3) * 62,
					y + 40 + floori(i / 3.0) * 62, 52, 52)
				body.paint_dots.append({"rect": r, "hex": PAINTS[i]})
				draw_circle(r.get_center(), 24.0, Color(PAINTS[i]))
				draw_arc(r.get_center(), 24.0, 0, TAU, 24, Color(1, 1, 1, 0.7), 3.0, true)
			return

		body.action_rect = Rect2(panel.position.x + 24, panel.end.y - 96,
			panel.size.x - 48, 72)
		var btn := Color("8fc48a") if afford else Color("ddd2bd")
		DrawKit.rounded_rect(self, body.action_rect, 16.0, btn)
		var label := "build it!" if afford else "keep looking"
		var lw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
		draw_string(font, body.action_rect.get_center() + Vector2(-lw / 2.0, 10), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 30,
			Color("3f5c3a") if afford else Color("9c9079"))

	## Her stock, so the board answers "what have I got?" without leaving it.
	func _draw_stock(panel: Rect2, font: Font) -> void:
		var y := panel.position.y + 150.0
		for k in BuildDefs.MATERIALS:
			var n: int = int(GameState.materials.get(k, 0))
			draw_set_transform(Vector2(panel.position.x + 42, y), 0.0, Vector2.ONE)
			DrawKit.draw_material(self, k, 15.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_string(font, Vector2(panel.position.x + 72, y + 9), "%d" % n,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("6b4f38"))
			draw_string(font, Vector2(panel.position.x + 104, y + 8),
				str(TopBar.NAMES.get(k, k)), HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
				Color("a2917a"))
			y += 42.0

	func _draw_tabs(vs: Vector2) -> void:
		body.tabs.clear()
		var n := BuildDefs.TRACKS.size()
		var tw := (vs.x - 80.0) / n
		var font := ThemeDB.fallback_font
		for i in n:
			var tr: String = BuildDefs.TRACKS[i]
			var r := Rect2(40 + i * tw, vs.y - 104, tw - 12, 72)
			body.tabs.append({"rect": r, "track": tr})
			var on := tr == body.track
			DrawKit.rounded_rect(self, r, 14.0, Color("e8dcc4") if on else Color("f4ead6"))
			if on:
				draw_rect(Rect2(r.position.x + 12, r.end.y - 8, r.size.x - 24, 5), Color("a97e54"))
			var label: String = BuildDefs.TRACK_LABEL[tr]
			var lw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
			draw_string(font, r.get_center() + Vector2(-lw / 2.0, 8), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 22,
				Color("6b4f38") if on else Color("a2917a"))

	func _draw_sites(vs: Vector2) -> void:
		body.sites.clear()
		var vis := body.visible_sites()
		if vis.size() < 2:
			return
		for i in vis.size():
			var s: String = vis[i]
			var r := Rect2(38 + i * 74, vs.y - 178, 64, 60)
			body.sites.append({"rect": r, "site": s})
			var on := s == body.site
			DrawKit.rounded_rect(self, r, 12.0, Color("e8dcc4") if on else Color("f4ead6"))
			# a tiny tree per site, so no reading is needed
			var c := r.get_center()
			draw_rect(Rect2(c.x - 3, c.y + 2, 6, 16), Color("8a6a52"))
			draw_circle(c + Vector2(0, -6), 15.0 - i * 2.0, Color("94c489") if on else Color("bcd9b4"))
			if i > 0:
				draw_line(c + Vector2(-24, 6), c + Vector2(-14, 6), Color("9a8055"), 2.5)



## Which trees the board can show right now. Exposed so the world can check a
## remembered site is still reachable before opening on it.
func visible_sites_now() -> Array:
	var out := ["home"]
	if GameState.has_built("bridge2"):
		out.append("two")
	if GameState.has_built("bridge3"):
		out.append("three")
	return out
