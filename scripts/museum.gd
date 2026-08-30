extends Node2D
## Inside the treehouse: Summer's own museum. Finds from the satchel wait in
## the basket at the bottom; she drags them onto any free shelf spot and can
## rearrange them whenever she likes. Nothing is ever taken away — a find can
## move between shelf spots but never leaves the shelf.

const SLOT_XS := [280.0, 400.0, 520.0, 640.0, 760.0, 880.0, 1000.0]
const SHELF_YS := [175.0, 295.0, 415.0, 535.0]
const TRAY_Y := 716.0
const PICK_RADIUS := 48.0
const DROP_RADIUS := 80.0

const POSTER_CENTER := Vector2(120, 300)
const DOOR_RECT := Rect2(1090, 430, 152, 190)

## Tap (not drag) a find and its name pops up on a little tag — lowercase,
## Year 1 friendly. Never required for anything; purely a nice-to-know.
const WORDS := {
	"ammonite": "ammonite",
	"trilobite": "trilobite",
	"dino_bone": "bone",
	"dino_egg": "egg",
	"shark_tooth": "tooth",
	"roman_coin": "coin",
	"pirate_coin": "coin",
	"gem": "gem",
	"old_key": "key",
}

var hud: Hud
var shelf_nodes: Dictionary = {}   # slot (int) -> FindIcon
var tray_nodes: Array = []         # FindIcon, index-matched to GameState.satchel
var dragging: FindIcon = null
var drag_from_slot := -1           # -1 means "from the tray"
var drag_home := Vector2.ZERO
var press_pos := Vector2.ZERO
var word_tag: WordTag = null


func _ready() -> void:
	Sound.detector_active = false
	var bg := MuseumBG.new()
	bg.slot_xs = SLOT_XS
	bg.shelf_ys = SHELF_YS
	bg.door_rect = DOOR_RECT
	bg.poster_center = POSTER_CENTER
	add_child(bg)

	for slot in GameState.shelf:
		if slot < slot_count():
			var icon := FindIcon.new(GameState.shelf[slot], 30.0)
			icon.position = slot_pos(slot)
			add_child(icon)
			shelf_nodes[slot] = icon

	for kind in GameState.satchel:
		var icon := FindIcon.new(kind, 28.0)
		add_child(icon)
		tray_nodes.append(icon)
	_layout_tray()

	hud = Hud.new("museum")
	add_child(hud)


func slot_count() -> int:
	return SLOT_XS.size() * SHELF_YS.size()


func slot_pos(slot: int) -> Vector2:
	var row := floori(float(slot) / SLOT_XS.size())
	var col := slot % SLOT_XS.size()
	return Vector2(SLOT_XS[col], SHELF_YS[row])


func _layout_tray() -> void:
	var count := tray_nodes.size()
	if count == 0:
		return
	var step := minf(96.0, 880.0 / count)
	var start := 640.0 - step * (count - 1) / 2.0
	for i in count:
		var node: FindIcon = tray_nodes[i]
		if node == dragging:
			continue
		var target := Vector2(start + step * i, TRAY_Y)
		var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(node, "position", target, 0.3)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press(get_global_mouse_position())
		else:
			_release(get_global_mouse_position())
	elif event is InputEventMouseMotion and dragging:
		dragging.position = get_global_mouse_position()


func _press(wp: Vector2) -> void:
	if DOOR_RECT.has_point(wp):
		_exit_to_world()
		return
	if wp.distance_to(POSTER_CENTER) < 95.0:
		AffirmationCard.show_card(hud, Affirm.next())
		Fx.sparkles(self, POSTER_CENTER, 5)
		return

	var best: FindIcon = null
	var best_d := PICK_RADIUS
	for node in tray_nodes:
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
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(dragging, "scale", Vector2(1.25, 1.25), 0.2)


func _release(wp: Vector2) -> void:
	if dragging == null:
		return
	var node := dragging
	dragging = null
	node.z_index = 1

	# a tap (no real movement) shows the find's name instead of moving it
	if wp.distance_to(press_pos) < 14.0:
		_settle(node, drag_home)
		_show_word(node)
		return

	var target_slot := -1
	var best_d := DROP_RADIUS
	for slot in slot_count():
		if shelf_nodes.has(slot) and shelf_nodes[slot] != node:
			continue
		var d: float = wp.distance_to(slot_pos(slot))
		if d < best_d:
			best_d = d
			target_slot = slot

	if target_slot >= 0:
		if drag_from_slot == -1:
			# from the tray: a new treasure joins the museum
			var idx := tray_nodes.find(node)
			if idx >= 0:
				tray_nodes.remove_at(idx)
				GameState.take_from_satchel(idx)
			GameState.place_on_shelf(target_slot, node.kind)
			shelf_nodes[target_slot] = node
			_settle(node, slot_pos(target_slot))
			_layout_tray()
			Sound.chime_shelf()
			Fx.sparkles(self, slot_pos(target_slot))
			AffirmationCard.show_card(hud, Affirm.next())
		else:
			# rearranging the shelf
			if target_slot != drag_from_slot:
				shelf_nodes.erase(drag_from_slot)
				shelf_nodes[target_slot] = node
				GameState.move_on_shelf(drag_from_slot, target_slot)
				Sound.pop()
			_settle(node, slot_pos(target_slot))
	else:
		# no spot found — drift gently back to where it came from
		_settle(node, drag_home)


func _settle(node: FindIcon, pos: Vector2) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "position", pos, 0.35)
	tw.parallel().tween_property(node, "scale", Vector2.ONE, 0.35)


func _show_word(node: FindIcon) -> void:
	if is_instance_valid(word_tag):
		word_tag.queue_free()
	word_tag = WordTag.new()
	word_tag.word = WORDS.get(node.kind, "")
	word_tag.position = node.position + Vector2(0, -46)
	word_tag.z_index = 15
	add_child(word_tag)
	Sound.pop()


func _exit_to_world() -> void:
	GameState.spawn_at_door = true
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


## Small tag showing a find's name in lowercase — appears on a tap, fades out.
class WordTag extends Node2D:
	var word := ""

	func _ready() -> void:
		modulate.a = 0.0
		scale = Vector2(0.6, 0.6)
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 1.0, 0.2)
		tw.parallel().tween_property(self, "scale", Vector2.ONE, 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(2.4)
		tw.tween_property(self, "modulate:a", 0.0, 0.4)
		tw.tween_callback(queue_free)

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


## Everything static inside the treehouse, drawn in code.
class MuseumBG extends Node2D:
	var slot_xs: Array = []
	var shelf_ys: Array = []
	var door_rect := Rect2()
	var poster_center := Vector2.ZERO

	func _draw() -> void:
		# walls and floor
		draw_rect(Rect2(0, 0, 1280, 645), Color("ead9bd"))
		for i in 9:
			draw_line(Vector2(i * 160.0, 0), Vector2(i * 160.0, 645), Color("ddc9a8"), 3.0)
		draw_rect(Rect2(0, 645, 1280, 160), Color("c99f72"))
		for i in 5:
			draw_line(Vector2(0, 645 + i * 32.0), Vector2(1280, 645 + i * 32.0), Color("bb9265"), 2.0)

		# round window with a peek of sky
		var win := Vector2(640, 82)
		draw_circle(win, 62.0, Color("8a6a44"))
		draw_circle(win, 53.0, Color("c3e2f2"))
		draw_circle(win + Vector2(22, -17), 13.0, Color("ffd98a"))
		draw_circle(win + Vector2(-16, 11), 11.0, Color(1, 1, 1, 0.9))
		draw_circle(win + Vector2(-27, 14), 8.0, Color(1, 1, 1, 0.9))
		draw_line(win + Vector2(-53, 0), win + Vector2(53, 0), Color("8a6a44"), 4.5)
		draw_line(win + Vector2(0, -53), win + Vector2(0, 53), Color("8a6a44"), 4.5)

		# shelves
		for y in shelf_ys:
			var left: float = slot_xs[0] - 55.0
			var right: float = slot_xs[slot_xs.size() - 1] + 55.0
			DrawKit.rounded_rect(self, Rect2(left, y + 30.0, right - left, 16.0), 7.0, Color("a97e54"))
			draw_polygon(PackedVector2Array([
				Vector2(left + 20, y + 46), Vector2(left + 44, y + 46), Vector2(left + 44, y + 72),
			]), PackedColorArray([Color("97704a")]))
			draw_polygon(PackedVector2Array([
				Vector2(right - 20, y + 46), Vector2(right - 44, y + 46), Vector2(right - 44, y + 72),
			]), PackedColorArray([Color("97704a")]))

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

		# woven basket for new finds
		DrawKit.rounded_rect(self, Rect2(160, 668, 960, 96), 26.0, Color("d9b98c"))
		DrawKit.rounded_rect(self, Rect2(172, 678, 936, 76), 20.0, Color("cba874"))
		for i in 11:
			draw_line(Vector2(200 + i * 80.0, 678), Vector2(212 + i * 80.0, 754), Color("bb9764"), 3.0)

		# rug
		DrawKit.ellipse(self, Vector2(640, 790), 260.0, 34.0, Color("e8b8b8"))

		# door back out to the meadow
		DrawKit.rounded_rect(self, door_rect, 22.0, Color("8a6647"))
		DrawKit.rounded_rect(self, door_rect.grow(-8), 16.0, Color("9c7654"))
		draw_circle(door_rect.position + Vector2(28, door_rect.size.y / 2.0), 5.0, Color("d9b45c"))
		var ac := door_rect.position + Vector2(door_rect.size.x / 2.0, -34.0)
		var green := Color("8fc48a")
		draw_line(ac + Vector2(-20, 0), ac + Vector2(8, 0), green, 7.0)
		draw_polygon(PackedVector2Array([
			ac + Vector2(8, -11), ac + Vector2(22, 0), ac + Vector2(8, 11),
		]), PackedColorArray([green]))
