extends Node2D
## Inside the treehouse: Summer's own museum. Finds wait in the basket at the
## bottom; she drags them onto any free shelf spot, rearranges them whenever she
## likes, and drags them back DOWN into the basket to take them off display.
##
## NOTHING IS EVER DESTROYED. There is no bin. A find only ever moves between
## the basket and the shelf — both of which are hers — so she can curate the
## museum freely and can never lose a treasure by mistake. The basket holds any
## number, a page at a time.

const SLOT_XS := [280.0, 400.0, 520.0, 640.0, 760.0, 880.0, 1000.0]
const SHELF_YS := [175.0, 295.0, 415.0, 535.0]
const TRAY_Y := 716.0
## How many finds the basket shows at once. More than this and it pages —
## big targets matter more than seeing everything at once.
const TRAY_PER_PAGE := 9
const PICK_RADIUS := 48.0
const DROP_RADIUS := 80.0

const POSTER_CENTER := Vector2(120, 300)
const DOOR_RECT := Rect2(1090, 430, 152, 190)

## Tap (not drag) a find and its name pops up on a little tag. The words live
## in GameState.FIND_WORDS so the basket view shows the same ones.
const WORDS := GameState.FIND_WORDS

var hud: Hud
var room := 0                      # 0 = main room; 1 = the annex (built at level 3)
var shelf_nodes: Dictionary = {}   # GLOBAL slot (int) -> FindIcon, current room only
var tray_nodes: Array = []         # FindIcon, index-matched to GameState.satchel
var dragging: FindIcon = null
var drag_from_slot := -1           # -1 means "from the tray" (global slot otherwise)
var tray_page := 0
var tray_arrow_l: RoomArrow = null
var tray_arrow_r: RoomArrow = null
var kitchen: KitchenNook = null
var game_spot: Grove.GameSpot = null
var ui_layer: CanvasLayer = null
var drag_home := Vector2.ZERO
var press_pos := Vector2.ZERO
var word_tag: WordTag = null
var bg: MuseumBG
var arrow_l: RoomArrow
var arrow_r: RoomArrow


## Every room she builds opens another shelf room — 28 spots each, so a fully
## built treehouse holds 140 finds on display. Anything beyond that lives in the
## basket, which never fills up.
func rooms_unlocked() -> int:
	var n := 1
	for id in ["storey2", "tower", "tree2_cabin", "tree3_tower"]:
		if GameState.has_built(id):
			n += 1
	return n


func _ready() -> void:
	Sound.detector_active = false
	bg = MuseumBG.new()
	bg.slot_xs = SLOT_XS
	bg.shelf_ys = SHELF_YS
	bg.door_rect = DOOR_RECT
	bg.poster_center = POSTER_CENTER
	add_child(bg)

	arrow_r = RoomArrow.new()
	arrow_r.dir = 1
	arrow_r.position = Vector2(1248, 380)
	add_child(arrow_r)
	arrow_l = RoomArrow.new()
	arrow_l.dir = -1
	arrow_l.position = Vector2(34, 380)
	add_child(arrow_l)
	_update_arrows()
	# wood grain on the walls (vertical streaks) and floor (horizontal)
	bg.add_child(Paint.grain(Rect2(0, 0, 1280, 645), 42.0, 0.07,
		Color("6e5039"), Color("fff3d8"), Vector2(0.12, 1.0)))
	bg.add_child(Paint.grain(Rect2(0, 645, 1280, 160), 42.0, 0.1,
		Color("5e4433"), Color("e8c89a"), Vector2(1.0, 0.14)))

	_populate_shelf()

	# arrows for turning the basket's pages, once there is more than one
	tray_arrow_l = RoomArrow.new()
	tray_arrow_l.dir = -1
	tray_arrow_l.position = Vector2(150, TRAY_Y)
	add_child(tray_arrow_l)
	tray_arrow_r = RoomArrow.new()
	tray_arrow_r.dir = 1
	tray_arrow_r.position = Vector2(1130, TRAY_Y)
	add_child(tray_arrow_r)

	for kind in GameState.satchel:
		var icon := FindIcon.new(kind, 28.0)
		add_child(icon)
		tray_nodes.append(icon)
	_layout_tray()

	# Memory Museum, on a spare shelf: the cards are her own finds
	game_spot = Grove.GameSpot.new()
	game_spot.game = "memory"
	game_spot.position = Vector2(168, 596)
	add_child(game_spot)

	# the kitchen, once she has built it — a little stove she can bake at
	if GameState.has_room("kitchen"):
		kitchen = KitchenNook.new()
		kitchen.position = Vector2(1120, 610)
		add_child(kitchen)

	add_child(Paint.grade_layer())
	hud = Hud.new("museum")
	add_child(hud)


## Memory Museum: face-down cards made from her own collection.
func _open_memory() -> void:
	if ui_layer != null:
		return
	var game := MemoryGame.new()
	game.rewarded.connect(_take_reward)
	ui_layer = game
	game.closed.connect(func() -> void:
		ui_layer = null
		game.queue_free()
		Sound.pop())
	add_child(game)
	Sound.card_sound()


## A game handing something back — materials for the treehouse, mostly.
func _take_reward(kind: String, n: int) -> void:
	if kind.begins_with("find:"):
		for i in n:
			GameState.add_to_satchel(kind.substr(5))
	elif kind == "fruit":
		GameState.add_fruit(n)
	else:
		GameState.add_material(kind, n)


## Baking in the treehouse kitchen. Fruit she picked, into a pie.
func _open_kitchen() -> void:
	if ui_layer != null:
		return
	var game := PieGame.new()
	game.eat_now.connect(_eat_pie)
	ui_layer = game
	game.closed.connect(func() -> void:
		ui_layer = null
		game.queue_free()
		Sound.pop())
	add_child(game)
	Sound.card_sound()


## She sits down right here in the kitchen and eats a slice.
func _eat_pie(stack: Array) -> void:
	Fx.hearts(self, kitchen.position + Vector2(0, -120.0), 4)
	for i in 3:
		get_tree().create_timer(0.3 + i * 0.5).timeout.connect(Sound.munch)
	GameState.hunger_accum = 0.0
	GameState.save_game()
	await get_tree().create_timer(1.9).timeout
	if not is_inside_tree():
		return
	Sound.chime_find()
	AffirmationCard.show_card(hud, Affirm.next())
	if kitchen != null:
		kitchen.cool_a_pie()


## A stove, a shelf of jars and a windowsill where the pie cools.
class KitchenNook extends Node2D:
	var pies_cooling := 0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if pies_cooling > 0:
			queue_redraw()

	func cool_a_pie() -> void:
		pies_cooling = mini(3, pies_cooling + 1)
		queue_redraw()

	func _draw() -> void:
		var wood := Color("a97e54")
		DrawKit.soft_shadow(self, Vector2(0, 2), 70.0, 0.15)
		# the stove
		DrawKit.rounded_rect(self, Rect2(-64, -110, 128, 110), 8.0, Color("8a8f96"))
		DrawKit.rounded_rect(self, Rect2(-56, -102, 112, 46), 6.0, Color("5c6470"))
		draw_circle(Vector2(0, -79), 17.0, Color("d97f4a"))
		draw_circle(Vector2(0, -79), 11.0, Color("f2a86a"))
		for i in 3:
			draw_circle(Vector2(-34 + i * 34, -34), 7.0, Color("c9ced4"))
		draw_rect(Rect2(-56, -18, 112, 8), Color("6f7680"))
		# a shelf of jars above
		draw_rect(Rect2(-70, -168, 140, 9), wood)
		for i in 4:
			var jx := -50.0 + i * 33.0
			DrawKit.rounded_rect(self, Rect2(jx - 11, -196, 22, 28), 4.0,
				[Color("b56a9f"), Color("e05c50"), Color("8a5fa8"), Color("d9a45c")][i])
			draw_rect(Rect2(jx - 12, -198, 24, 5), Color("cdc6b6"))
		# pies cooling on the sill
		for i in pies_cooling:
			var px := -40.0 + i * 40.0
			DrawKit.ellipse(self, Vector2(px, -122), 18.0, 6.0, Color("b8bcc2"))
			DrawKit.ellipse(self, Vector2(px, -126), 16.0, 5.5, Color("d9a45c"))
			var wisp := sin(_t * 2.0 + i) * 3.0
			draw_line(Vector2(px + wisp, -134), Vector2(px - wisp, -150), Color(1, 1, 1, 0.28), 2.5)


## Slots per room. Global slot index = room * slot_count() + local slot.
func slot_count() -> int:
	return SLOT_XS.size() * SHELF_YS.size()


## Position for a LOCAL (within-room) slot index.
func slot_pos(local: int) -> Vector2:
	var row := floori(float(local) / SLOT_XS.size())
	var col := local % SLOT_XS.size()
	return Vector2(SLOT_XS[col], SHELF_YS[row])


## (Re)build the shelf icons for the room we're standing in.
func _populate_shelf() -> void:
	for slot in shelf_nodes:
		shelf_nodes[slot].queue_free()
	shelf_nodes.clear()
	var base := room * slot_count()
	for slot in GameState.shelf:
		if slot >= base and slot < base + slot_count():
			var icon := FindIcon.new(GameState.shelf[slot], 30.0)
			icon.position = slot_pos(slot - base)
			add_child(icon)
			shelf_nodes[slot] = icon


func _update_arrows() -> void:
	arrow_r.visible = room < rooms_unlocked() - 1
	arrow_l.visible = room > 0


func _switch_room(to: int) -> void:
	to = clampi(to, 0, rooms_unlocked() - 1)
	if to == room:
		return
	room = to
	bg.room = room
	bg.queue_redraw()
	if is_instance_valid(word_tag):
		word_tag.queue_free()
	_populate_shelf()
	_update_arrows()
	Sound.pop()


## Which page of the basket a given find sits on.
func _page_of(index: int) -> int:
	return floori(float(index) / TRAY_PER_PAGE)


func _page_count() -> int:
	return maxi(1, ceili(float(tray_nodes.size()) / TRAY_PER_PAGE))


func _goto_page(p: int) -> void:
	tray_page = clampi(p, 0, _page_count() - 1)


## The basket holds everything, however much that is, by showing a page at a
## time with big arrows. Nothing is ever hidden away for good — it is all still
## hers, just on another page.
func _layout_tray() -> void:
	_goto_page(tray_page)
	var count := tray_nodes.size()
	var first := tray_page * TRAY_PER_PAGE
	var last := mini(count, first + TRAY_PER_PAGE)
	var shown := last - first
	var step := 96.0
	var start := 640.0 - step * (shown - 1) / 2.0
	for i in count:
		var node: FindIcon = tray_nodes[i]
		if node == dragging:
			continue
		var on_page := i >= first and i < last
		node.visible = on_page
		if not on_page:
			continue
		var target := Vector2(start + step * (i - first), TRAY_Y)
		var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(node, "position", target, 0.3)
	if tray_arrow_l != null:
		tray_arrow_l.visible = tray_page > 0
		tray_arrow_r.visible = tray_page < _page_count() - 1
	if bg != null:
		bg.tray_page = tray_page
		bg.tray_pages = _page_count()
		bg.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press(get_global_mouse_position())
		else:
			_release(get_global_mouse_position())
	elif event is InputEventMouseMotion and dragging:
		dragging.position = get_global_mouse_position()


func _press(wp: Vector2) -> void:
	if ui_layer != null:
		return
	# the word tag sits above everything, and its take-down button gets first
	# refusal or the shelf behind it swallows the tap
	if is_instance_valid(word_tag) and word_tag.tap_at(wp - word_tag.position):
		return
	if arrow_r.visible and wp.distance_to(arrow_r.position) < 52.0:
		_switch_room(room + 1)
		return
	if arrow_l.visible and wp.distance_to(arrow_l.position) < 52.0:
		_switch_room(room - 1)
		return
	if tray_arrow_r.visible and wp.distance_to(tray_arrow_r.position) < 52.0:
		_goto_page(tray_page + 1)
		_layout_tray()
		Sound.pop()
		return
	if tray_arrow_l.visible and wp.distance_to(tray_arrow_l.position) < 52.0:
		_goto_page(tray_page - 1)
		_layout_tray()
		Sound.pop()
		return
	if DOOR_RECT.has_point(wp):
		_exit_to_world()
		return
	if wp.distance_to(POSTER_CENTER) < 95.0:
		AffirmationCard.show_card(hud, Affirm.next())
		Fx.sparkles(self, POSTER_CENTER, 5)
		return
	if kitchen != null and wp.distance_to(kitchen.position) < 110.0:
		_open_kitchen()
		return
	if game_spot != null and wp.distance_to(game_spot.position) < 92.0:
		_open_memory()
		return

	var best: FindIcon = null
	var best_d := PICK_RADIUS
	for node in tray_nodes:
		if not node.visible:
			continue           # on another page of the basket
		var d: float = wp.distance_to(node.position)
		if d < best_d:
			best_d = d
			best = node
	for slot in shelf_nodes:
		var d: float = wp.distance_to(shelf_nodes[slot].position)
		if d < best_d:
			best_d = d
			best = shelf_nodes[slot]
	if best == null:
		return

	dragging = best
	press_pos = wp
	drag_home = best.position
	drag_from_slot = -1
	for slot in shelf_nodes:
		if shelf_nodes[slot] == best:
			drag_from_slot = slot
			break
	dragging.z_index = 10
	bg.basket_glow = drag_from_slot >= 0
	bg.queue_redraw()
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(dragging, "scale", Vector2(1.25, 1.25), 0.2)


func _release(wp: Vector2) -> void:
	if dragging == null:
		return
	var node := dragging
	dragging = null
	node.z_index = 1
	bg.basket_glow = false
	bg.queue_redraw()

	# a tap (no real movement) shows the find's name instead of moving it
	if wp.distance_to(press_pos) < 14.0:
		_settle(node, drag_home)
		_show_word(node, drag_from_slot)
		return

	var base := room * slot_count()
	var target_slot := -1          # global slot index
	var best_d := DROP_RADIUS
	for local in slot_count():
		var slot := base + local
		if shelf_nodes.has(slot) and shelf_nodes[slot] != node:
			continue
		var d: float = wp.distance_to(slot_pos(local))
		if d < best_d:
			best_d = d
			target_slot = slot

	# Dropped down in the basket? Take it off the shelf and put it back. This is
	# how she picks and chooses what is on display — nothing is ever destroyed,
	# it just goes back in the basket and can come straight out again.
	if drag_from_slot >= 0 and wp.y > TRAY_Y - 90.0:
		shelf_nodes.erase(drag_from_slot)
		GameState.take_off_shelf(drag_from_slot)
		tray_nodes.append(node)
		_goto_page(_page_of(tray_nodes.size() - 1))
		_layout_tray()
		Sound.pop()
		Fx.sparkles(self, Vector2(node.position.x, TRAY_Y), 4, Color("d9b485"))
		return

	if target_slot >= 0:
		if drag_from_slot == -1:
			# from the tray: a new treasure joins the museum
			var idx := tray_nodes.find(node)
			if idx >= 0:
				tray_nodes.remove_at(idx)
				GameState.take_from_satchel(idx)
			GameState.place_on_shelf(target_slot, node.kind)
			shelf_nodes[target_slot] = node
			_settle(node, slot_pos(target_slot - base))
			_layout_tray()
			Sound.chime_shelf()
			Fx.sparkles(self, slot_pos(target_slot - base))
			AffirmationCard.show_card(hud, Affirm.next())
		else:
			# rearranging the shelf
			if target_slot != drag_from_slot:
				shelf_nodes.erase(drag_from_slot)
				shelf_nodes[target_slot] = node
				GameState.move_on_shelf(drag_from_slot, target_slot)
				Sound.pop()
			_settle(node, slot_pos(target_slot - base))
	else:
		# no spot found — drift gently back to where it came from
		_settle(node, drag_home)


func _settle(node: FindIcon, pos: Vector2) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "position", pos, 0.35)
	tw.parallel().tween_property(node, "scale", Vector2.ONE, 0.35)


func _show_word(node: FindIcon, slot := -1) -> void:
	# photos open BIG so she can really look at them
	if node.kind.begins_with("photo_"):
		PhotoCard.show_photo(self, node.kind, node.kind.split("_")[1])
		return
	if is_instance_valid(word_tag):
		word_tag.queue_free()
	word_tag = WordTag.new()
	word_tag.word = WORDS.get(node.kind, "")
	word_tag.slot = slot
	word_tag.take_down = _take_off_shelf
	word_tag.position = node.position + Vector2(0, -46)
	word_tag.z_index = 15
	add_child(word_tag)
	Sound.pop()


func _exit_to_world() -> void:
	GameState.spawn_at_door = true
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


## Round arrow that walks between the museum's rooms (the annex opens once
## the treehouse reaches level 3).
class RoomArrow extends Node2D:
	var dir := 1    # 1 = right, -1 = left
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var nudge := sin(t * 2.5) * 2.0 * dir
		draw_circle(Vector2(nudge, 0), 30.0, Color(0, 0, 0, 0.08))
		draw_circle(Vector2(nudge, -2), 28.0, Color("fff8ec"))
		draw_arc(Vector2(nudge, -2), 28.0, 0, TAU, 24, Color("f0d9a8"), 3.0, true)
		var d := float(dir)
		draw_polyline(PackedVector2Array([
			Vector2(nudge - d * 6.0, -14.0), Vector2(nudge + d * 8.0, -2.0),
			Vector2(nudge - d * 6.0, 10.0),
		]), Color("8fc48a"), 6.0, true)


## Small tag showing a find's name in lowercase — appears on a tap, fades out.
class WordTag extends Node2D:
	var word := ""
	## Set for a find that is ON a shelf: the tag then also offers a button to
	## take it down again. The drag-into-the-basket gesture always worked, but
	## nothing on screen ever said so, so nobody found it.
	var slot := -1
	var take_down: Callable = Callable()
	var _btn := Rect2()

	func _ready() -> void:
		modulate.a = 0.0
		scale = Vector2(0.6, 0.6)
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 1.0, 0.2)
		tw.parallel().tween_property(self, "scale", Vector2.ONE, 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(4.0 if slot >= 0 else 2.4)
		tw.tween_property(self, "modulate:a", 0.0, 0.4)
		tw.tween_callback(queue_free)

	## Returns true when the tap was the take-down button, so the museum knows
	## not to treat it as a tap on the shelf behind.
	func tap_at(local: Vector2) -> bool:
		if slot < 0 or not _btn.has_point(local):
			return false
		if take_down.is_valid():
			take_down.call(slot)
		queue_free()
		return true

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var fs := 30
		var w := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var rect := Rect2(-w / 2.0 - 18.0, -50.0, w + 36.0, 46.0)
		DrawKit.rounded_rect(self, rect, 15.0, Color("fff8ec"))
		DrawKit.rounded_rect_outline(self, rect, 15.0, Color("f0d9a8"), 3.0)
		draw_polygon(PackedVector2Array([
			Vector2(-8, -5), Vector2(8, -5), Vector2(0, 7),
		]), PackedColorArray([Color("fff8ec")]))
		draw_string(font, Vector2(-w / 2.0, -17.0), word,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("6b5a4a"))
		if slot < 0:
			_btn = Rect2()
			return
		# the way back down off the shelf, said in words and drawn as a basket
		var label := "into my basket"
		var lw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		_btn = Rect2(-(lw + 62.0) * 0.5, -104.0, lw + 62.0, 44.0)
		DrawKit.rounded_rect(self, _btn, 14.0, Color("e8d4b8"))
		DrawKit.rounded_rect_outline(self, _btn, 14.0, Color("cdb492"), 2.0)
		var bc := Vector2(_btn.position.x + 26.0, _btn.position.y + 22.0)
		DrawKit.rounded_rect(self, Rect2(bc.x - 11, bc.y - 5, 22, 13), 4.0, Color("c9915c"))
		draw_arc(bc + Vector2(0, -4), 10.0, PI + 0.35, TAU - 0.35, 10, Color("8a6a44"), 2.5, true)
		draw_string(font, Vector2(_btn.position.x + 46.0, _btn.position.y + 30.0), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("7a5f42"))


## Everything static inside the treehouse, drawn in code.
class MuseumBG extends Node2D:
	var slot_xs: Array = []
	var shelf_ys: Array = []
	var door_rect := Rect2()
	var poster_center := Vector2.ZERO
	var room := 0
	var tray_page := 0
	var tray_pages := 1
	var basket_glow := false   ## lit while she is holding a find off the shelf

	func _draw() -> void:
		# plank walls with a warm light falling from the window
		DrawKit.vgrad(self, Rect2(0, 0, 1280, 645), Color("f0e2c8"), Color("dfcba8"))
		for i in 9:
			draw_line(Vector2(i * 160.0, 0), Vector2(i * 160.0, 645), Color(0.78, 0.68, 0.53, 0.55), 3.0)
			draw_line(Vector2(i * 160.0 + 3, 0), Vector2(i * 160.0 + 3, 645), Color(1, 1, 1, 0.25), 1.5)
		# wood grain flecks
		for i in 30:
			var gx := fmod(i * 173.0, 1260.0) + 10.0
			var gy := fmod(i * 97.0, 600.0) + 20.0
			DrawKit.ellipse(self, Vector2(gx, gy), 6.0, 2.0, Color(0.75, 0.64, 0.48, 0.25))
		# soft pool of window light on the wall
		draw_circle(Vector2(640, 240), 240.0, Color(1.0, 0.95, 0.8, 0.1))
		draw_circle(Vector2(640, 200), 150.0, Color(1.0, 0.95, 0.8, 0.08))
		# floorboards with seams and grain
		DrawKit.vgrad(self, Rect2(0, 645, 1280, 160), Color("cfa678"), Color("b08659"))
		draw_rect(Rect2(0, 645, 1280, 6), Color(0.5, 0.36, 0.22, 0.4))   # wall shadow line
		for i in 5:
			draw_line(Vector2(0, 645 + i * 32.0), Vector2(1280, 645 + i * 32.0), Color("a87f52"), 2.0)
			draw_line(Vector2(0, 647 + i * 32.0), Vector2(1280, 647 + i * 32.0), Color(1, 1, 1, 0.14), 1.2)
		for i in 9:
			var bx := fmod(i * 293.0, 1240.0) + 20.0
			var by := 660.0 + (i % 5) * 30.0
			draw_line(Vector2(bx, by), Vector2(bx + 46.0, by), Color(0.55, 0.4, 0.25, 0.3), 1.5)

		# round window with a peek of the meadow sky
		var win := Vector2(640, 82)
		draw_circle(win, 66.0, Color(0.4, 0.3, 0.2, 0.25))   # recess shadow
		draw_circle(win, 62.0, Color("8a6a44"))
		draw_circle(win, 56.0, Color("a5825a"))
		draw_circle(win, 53.0, Color("aed9ef"))
		DrawKit.vgrad(self, Rect2(win.x - 53, win.y, 106, 50), Color("c8e6f4"), Color("e8f3e2"))
		draw_circle(win + Vector2(22, -17), 13.0, Color("ffdf98"))
		draw_circle(win + Vector2(22, -17), 9.0, Color("ffedc4"))
		draw_circle(win + Vector2(-16, 11), 11.0, Color(1, 1, 1, 0.9))
		draw_circle(win + Vector2(-27, 14), 8.0, Color(1, 1, 1, 0.9))
		draw_circle(win + Vector2(-6, 14), 8.5, Color(1, 1, 1, 0.9))
		draw_line(win + Vector2(-53, 0), win + Vector2(53, 0), Color("8a6a44"), 4.5)
		draw_line(win + Vector2(0, -53), win + Vector2(0, 53), Color("8a6a44"), 4.5)
		draw_arc(win, 48.0, PI * 1.15, PI * 1.5, 10, Color(1, 1, 1, 0.5), 3.0, true)

		# shelves: shadow on the wall beneath, lit front edge, wood grain
		for y in shelf_ys:
			var left: float = slot_xs[0] - 55.0
			var right: float = slot_xs[slot_xs.size() - 1] + 55.0
			DrawKit.vgrad(self, Rect2(left + 6, y + 46.0, right - left - 12, 14.0),
				Color(0.42, 0.3, 0.18, 0.22), Color(0.42, 0.3, 0.18, 0.0))
			DrawKit.rounded_rect(self, Rect2(left, y + 30.0, right - left, 16.0), 7.0, Color("a97e54"))
			DrawKit.rounded_rect(self, Rect2(left, y + 30.0, right - left, 6.0), 3.0, Color("c9a06c"))
			draw_line(Vector2(left + 12, y + 41.0), Vector2(right - 12, y + 41.0), Color("8a6242"), 1.5)
			for bracket_x in [left + 32.0, right - 32.0]:
				var sway := 12.0 if bracket_x < 640.0 else -12.0
				draw_polygon(PackedVector2Array([
					Vector2(bracket_x - sway, y + 46), Vector2(bracket_x + sway, y + 46),
					Vector2(bracket_x + sway, y + 72),
				]), PackedColorArray([Color("97704a")]))
				draw_line(Vector2(bracket_x - sway, y + 46), Vector2(bracket_x + sway, y + 72),
					Color("7d5c3c"), 2.0)

		# sunshine poster — tap it for an affirmation
		var pc := poster_center
		DrawKit.rounded_rect(self, Rect2(pc + Vector2(-72, -84), Vector2(144, 168)), 16.0, Color("fff8ec"))
		DrawKit.rounded_rect_outline(self, Rect2(pc + Vector2(-72, -84), Vector2(144, 168)), 16.0, Color("f0d9a8"), 4.0)
		draw_line(pc + Vector2(-40, -84), pc + Vector2(0, -120), Color("b39b6e"), 3.0)
		draw_line(pc + Vector2(40, -84), pc + Vector2(0, -120), Color("b39b6e"), 3.0)
		for i in 8:
			var a := TAU * i / 8.0
			draw_line(pc + Vector2.from_angle(a) * 26.0, pc + Vector2.from_angle(a) * 40.0, Color("ffd98a"), 6.0)
		draw_circle(pc, 22.0, Color("ffd98a"))
		draw_circle(pc, 16.0, Color("ffe6b3"))
		DrawKit.heart(self, pc + Vector2(-34, 52), 9.0, Color("f2a0b5"))
		DrawKit.star(self, pc + Vector2(34, 52), 9.0, Color("ffd98a"))
		DrawKit.star(self, pc + Vector2(0, 60), 6.0, Color("ffe6b3"))

		if room == 0:
			# T-Rex picture — the Oxford Natural History Museum adventure
			var tp := Vector2(1160, 250)
			DrawKit.rounded_rect(self, Rect2(tp + Vector2(-64, -74), Vector2(128, 148)), 14.0, Color("d9e8d4"))
			DrawKit.rounded_rect_outline(self, Rect2(tp + Vector2(-64, -74), Vector2(128, 148)), 14.0, Color("a97e54"), 5.0)
			var dino := Color("7fa86f")
			DrawKit.ellipse(self, tp + Vector2(4, 14), 34.0, 20.0, dino)                 # body
			draw_line(tp + Vector2(-24, 20), tp + Vector2(-48, 40), dino, 10.0)          # tail
			DrawKit.rounded_rect(self, Rect2(tp + Vector2(16, -38), Vector2(26, 30)), 9.0, dino)  # head
			draw_line(tp + Vector2(20, -8), tp + Vector2(22, 6), dino, 9.0)              # neck
			draw_circle(tp + Vector2(30, -30), 2.6, Color("3a3a44"))
			draw_line(tp + Vector2(2, 32), tp + Vector2(2, 48), dino, 8.0)               # legs
			draw_line(tp + Vector2(18, 32), tp + Vector2(18, 48), dino, 8.0)
			draw_line(tp + Vector2(10, -2), tp + Vector2(16, 2), dino, 4.0)              # tiny arm
		else:
			# the annex: a rainbow-over-the-meadow picture instead
			var tp := Vector2(1160, 250)
			DrawKit.rounded_rect(self, Rect2(tp + Vector2(-64, -74), Vector2(128, 148)), 14.0, Color("dce8f2"))
			DrawKit.rounded_rect_outline(self, Rect2(tp + Vector2(-64, -74), Vector2(128, 148)), 14.0, Color("a97e54"), 5.0)
			var arcs := [Color("f2a0a0"), Color("ffd98a"), Color("a8d5a2"), Color("a9c9e8")]
			for i in arcs.size():
				draw_arc(tp + Vector2(0, 30), 52.0 - i * 9.0, PI, TAU, 20, arcs[i], 8.0, true)
			DrawKit.ellipse(self, tp + Vector2(-30, 40), 36.0, 14.0, Color("a8d5a2"))
			DrawKit.ellipse(self, tp + Vector2(34, 44), 30.0, 12.0, Color("bcd9b4"))
			draw_circle(tp + Vector2(-38, -44), 12.0, Color("ffd98a"))
			draw_circle(tp + Vector2(-38, -44), 8.0, Color("ffe6b3"))

		# rug with a border, under the basket
		DrawKit.ellipse(self, Vector2(640, 780), 300.0, 42.0, Color("d9a3a3"))
		DrawKit.ellipse(self, Vector2(640, 780), 280.0, 37.0, Color("e8b8b8"))
		DrawKit.ellipse(self, Vector2(640, 780), 220.0, 28.0, Color("f2cece"))
		var rug_ring := PackedVector2Array()
		for i in 41:
			var ra := TAU * i / 40.0
			rug_ring.append(Vector2(640, 780) + Vector2(cos(ra) * 250.0, sin(ra) * 32.0))
		draw_polyline(rug_ring, Color("c98f8f"), 2.0, true)

		# woven basket for new finds, with shadow and crossed weave
		DrawKit.ellipse(self, Vector2(640, 762), 490.0, 22.0, Color(0.4, 0.28, 0.18, 0.18))
		DrawKit.rounded_rect(self, Rect2(160, 668, 960, 96), 26.0, Color("d9b98c"))
		DrawKit.rounded_rect(self, Rect2(172, 678, 936, 76), 20.0, Color("cba874"))
		for i in 11:
			draw_line(Vector2(200 + i * 80.0, 678), Vector2(212 + i * 80.0, 754), Color("bb9764"), 3.0)
			draw_line(Vector2(252 + i * 80.0, 678), Vector2(240 + i * 80.0, 754), Color(0.68, 0.53, 0.34, 0.6), 2.5)
		for wy in 2:
			draw_line(Vector2(180, 700 + wy * 26.0), Vector2(1100, 700 + wy * 26.0), Color(0.65, 0.5, 0.32, 0.4), 2.0)
		DrawKit.rounded_rect(self, Rect2(160, 664, 960, 12), 6.0, Color("e3c79c"))   # rim
		# lit up while she is carrying something down off the shelf, so it is
		# obvious the basket is somewhere she can put it
		if basket_glow:
			DrawKit.rounded_rect(self, Rect2(154, 658, 972, 112), 28.0, Color(1.0, 0.85, 0.54, 0.28))
			for i in 3:
				draw_arc(Vector2(640, 716), 300.0 + i * 90.0, PI * 1.05, PI * 1.95, 32,
					Color(1.0, 0.85, 0.54, 0.18 - i * 0.05), 6.0, true)
		# a dot per basket page, so she can see there is more in there
		if tray_pages > 1:
			for i in tray_pages:
				var dx := 640.0 - (tray_pages - 1) * 11.0 + i * 22.0
				draw_circle(Vector2(dx, 786), 6.0,
					Color("8a6647") if i == tray_page else Color(0.54, 0.4, 0.28, 0.35))

		# door back out to the meadow — panelled, framed, lit from the room
		DrawKit.rounded_rect(self, door_rect.grow(6), 24.0, Color("6e5039"))
		DrawKit.rounded_rect(self, door_rect, 22.0, Color("8a6647"))
		DrawKit.rounded_rect(self, door_rect.grow(-8), 16.0, Color("9c7654"))
		var pw := door_rect.size.x - 40.0
		DrawKit.rounded_rect(self, Rect2(door_rect.position + Vector2(20, 22), Vector2(pw, 62)), 8.0, Color("8f6a4a"))
		DrawKit.rounded_rect(self, Rect2(door_rect.position + Vector2(20, 100), Vector2(pw, 68)), 8.0, Color("8f6a4a"))
		DrawKit.rounded_rect_outline(self, Rect2(door_rect.position + Vector2(20, 22), Vector2(pw, 62)), 8.0, Color("7d5c3c"), 2.0)
		DrawKit.rounded_rect_outline(self, Rect2(door_rect.position + Vector2(20, 100), Vector2(pw, 68)), 8.0, Color("7d5c3c"), 2.0)
		draw_circle(door_rect.position + Vector2(28, door_rect.size.y / 2.0), 5.0, Color("d9b45c"))
		draw_circle(door_rect.position + Vector2(27, door_rect.size.y / 2.0 - 1.0), 2.0, Color("f0d9a0"))
		var ac := door_rect.position + Vector2(door_rect.size.x / 2.0, -34.0)
		var green := Color("8fc48a")
		draw_line(ac + Vector2(-20, 0), ac + Vector2(8, 0), green, 7.0)
		draw_polygon(PackedVector2Array([
			ac + Vector2(8, -11), ac + Vector2(22, 0), ac + Vector2(8, 11),
		]), PackedColorArray([green]))


## Take one find down off a shelf and put it back in her basket. The same
## thing the drag-into-the-basket gesture does, reachable by a plain button on
## the word tag — because a gesture nobody can see is not a way out.
func _take_off_shelf(slot: int) -> void:
	if not shelf_nodes.has(slot):
		return
	var node: FindIcon = shelf_nodes[slot]
	shelf_nodes.erase(slot)
	GameState.take_off_shelf(slot)
	tray_nodes.append(node)
	_goto_page(_page_of(tray_nodes.size() - 1))
	_layout_tray()
	Sound.pop()
	Fx.sparkles(self, Vector2(node.position.x, TRAY_Y), 4, Color("d9b485"))
