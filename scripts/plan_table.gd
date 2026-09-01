class_name PlanTable
extends Node2D
## The workbench beside the home tree with a plan pinned to it. Tapping it
## opens the build board. This is the whole point of the deferred building
## loop: materials found anywhere in the world only become BUILDING here.
##
## The plan on the table shows the next thing she could make, so the table
## itself is a goal she can read without any words.

var _t := 0.0
var next_id := ""    ## what the pinned plan is showing


func _ready() -> void:
	refresh()


func tap_score(wp: Vector2) -> float:
	return clampf(1.0 - (wp - global_position - Vector2(0, -48.0)).length() / 78.0, 0.0, 1.0)


func try_tap(wp: Vector2) -> bool:
	return (wp - global_position - Vector2(0, -48.0)).length() < 78.0


## Pin the cheapest thing she could build next — affordable first, so the
## table is usually showing something she can actually have.
func refresh() -> void:
	var best := ""
	var best_score := -1.0
	for id in GameState.available_builds():
		var cost := BuildDefs.cost_of(id)
		var total := 0
		for k in cost:
			total += int(cost[k])
		var score := 100.0 - total
		if GameState.can_afford(cost):
			score += 200.0
		if BuildDefs.track_of(id) == "structure":
			score += 40.0
		if score > best_score:
			best_score = score
			best = id
	next_id = best
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if next_id != "" and GameState.can_afford(BuildDefs.cost_of(next_id)):
		queue_redraw()


## A friendly little shake — "not quite enough bits yet", never a failure.
func wiggle() -> void:
	var tw := create_tween()
	for i in 3:
		tw.tween_property(self, "rotation", 0.07, 0.07)
		tw.tween_property(self, "rotation", -0.07, 0.07)
	tw.tween_property(self, "rotation", 0.0, 0.06)


func _draw() -> void:
	var wood := Color("a97e54")
	DrawKit.soft_shadow(self, Vector2(0, 2), 48.0, 0.14)
	# trestle legs
	for sx in [-1.0, 1.0]:
		draw_line(Vector2(sx * 26, -30), Vector2(sx * 34, 0), wood.darkened(0.3), 6.0)
		draw_line(Vector2(sx * 26, -30), Vector2(sx * 14, 0), wood.darkened(0.24), 6.0)
	draw_line(Vector2(-30, -14), Vector2(30, -14), wood.darkened(0.34), 4.0)
	# table top, tilted a touch toward us
	DrawKit.rounded_rect(self, Rect2(-42, -40, 84, 12), 3.0, wood)
	draw_rect(Rect2(-42, -40, 84, 4), wood.lightened(0.12))

	# the plan, pinned and curling at one corner
	var paper := Color("fdf6e3")
	draw_polygon(PackedVector2Array([
		Vector2(-34, -40), Vector2(34, -42), Vector2(30, -84), Vector2(-32, -82),
	]), PackedColorArray([paper]))
	draw_polyline(PackedVector2Array([
		Vector2(-34, -40), Vector2(34, -42), Vector2(30, -84), Vector2(-32, -82), Vector2(-34, -40),
	]), Color("cfc4a8"), 1.5)
	draw_circle(Vector2(0, -80), 2.6, Color("c85f56"))

	if next_id == "":
		# nothing left to build — the plan becomes a happy little drawing
		DrawKit.heart(self, Vector2(0, -62), 11.0, Color("f2a0b5"))
		return

	# a tiny picture of the thing, and what it needs, in dots
	_draw_plan_icon(next_id, Vector2(0, -66))
	var cost := BuildDefs.cost_of(next_id)
	var affordable := GameState.can_afford(cost)
	# the material itself and how many, rather than a row of coloured specks
	# that never said which material they were
	var dx := -30.0
	for k in cost:
		var n: int = int(cost[k])
		draw_set_transform(Vector2(dx, -48), 0.0, Vector2.ONE)
		DrawKit.draw_material(self, k, 7.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_string(ThemeDB.fallback_font, Vector2(dx + 9.0, -43.0), "%d" % n,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
			Color("6b4f38") if affordable else Color("bdb4a2"))
		dx += 26.0
	if affordable:
		var glow := 0.35 + 0.25 * sin(_t * 3.0)
		draw_arc(Vector2(0, -62), 30.0, 0, TAU, 26, Color(1.0, 0.85, 0.54, glow), 3.0, true)


func _draw_plan_icon(id: String, p: Vector2) -> void:
	var line := Color("7a6a52")
	match BuildDefs.track_of(id):
		"structure":
			draw_rect(Rect2(p.x - 13, p.y - 6, 26, 16), Color(0, 0, 0, 0))
			draw_polyline(PackedVector2Array([
				p + Vector2(-13, 10), p + Vector2(-13, -6), p + Vector2(13, -6), p + Vector2(13, 10),
			]), line, 2.0)
			draw_polyline(PackedVector2Array([
				p + Vector2(-17, -6), p + Vector2(0, -18), p + Vector2(17, -6),
			]), line, 2.0)
		"access":
			draw_line(p + Vector2(-8, -16), p + Vector2(-8, 12), line, 2.0)
			draw_line(p + Vector2(8, -16), p + Vector2(8, 12), line, 2.0)
			for i in 4:
				var ly := -12.0 + i * 8.0
				draw_line(p + Vector2(-8, ly), p + Vector2(8, ly), line, 1.8)
		"extension":
			draw_line(p + Vector2(-16, 4), p + Vector2(16, 4), line, 2.2)
			for i in 4:
				draw_line(p + Vector2(-12 + i * 8, 4), p + Vector2(-12 + i * 8, -8), line, 1.8)
			draw_line(p + Vector2(-16, -8), p + Vector2(16, -8), line, 1.8)
		"comfort":
			draw_polyline(PackedVector2Array([
				p + Vector2(-14, 10), p + Vector2(-14, -8), p + Vector2(14, -8), p + Vector2(14, 10),
			]), line, 2.0)
			draw_line(p + Vector2(-14, 2), p + Vector2(14, 2), line, 1.8)
			draw_line(p + Vector2(-14, -4), p + Vector2(14, -4), line, 1.8)
		_:
			DrawKit.star(self, p, 12.0, Color("d9b45c"))

