class_name Player
extends Node2D
## Summer, drawn in code, holding her metal detector. Origin is at her feet.
## Tap anywhere to walk there; arrow keys / A-D work on desktop for testing.

var target_x := 0.0
var speed := 230.0
var facing := 1
var walking := false
var t := 0.0


func _ready() -> void:
	target_x = position.x


func _process(delta: float) -> void:
	var key_dir := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		key_dir -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		key_dir += 1.0
	if key_dir != 0.0:
		target_x = position.x + key_dir * speed * 0.5

	var dx := target_x - position.x
	walking = absf(dx) > 4.0
	if walking:
		facing = 1 if dx > 0.0 else -1
		position.x = move_toward(position.x, target_x, speed * delta)
		t += delta
	else:
		t += delta * 0.35
	queue_redraw()


func _draw() -> void:
	var fx := float(facing)
	var bob := 0.0
	var leg := 0.0
	if walking:
		bob = -absf(sin(t * 9.0)) * 3.5
		leg = sin(t * 9.0) * 7.0
	else:
		bob = sin(t * 2.0) * 1.2

	var skin := Color("f2c9a5")
	var hair := Color("6e4a32")
	var dress := Color("e8918c")
	var boot := Color("8a6f5c")
	var ink := Color("4a3a30")

	# legs and boots
	draw_rect(Rect2(-10 - leg * 0.4 * fx, -26, 7, 20), skin.darkened(0.06))
	draw_rect(Rect2(-12 - leg * 0.4 * fx, -9, 11, 9), boot)
	draw_rect(Rect2(3 + leg * 0.4 * fx, -26, 7, 20), skin)
	draw_rect(Rect2(1 + leg * 0.4 * fx, -9, 11, 9), boot)

	# dress
	draw_polygon(PackedVector2Array([
		Vector2(-8 * fx, -56 + bob), Vector2(8 * fx, -56 + bob),
		Vector2(16 * fx, -24 + bob), Vector2(-16 * fx, -24 + bob),
	]), PackedColorArray([dress]))

	# arm holding the detector
	draw_line(Vector2(6 * fx, -50 + bob), Vector2(18 * fx, -38 + bob), skin, 5.0)

	# head, hair, face
	draw_circle(Vector2(0, -68 + bob), 13.0, skin)
	draw_circle(Vector2(-3 * fx, -75 + bob), 10.0, hair)
	draw_arc(Vector2(0, -68 + bob), 12.0, PI + 0.25, TAU - 0.45, 12, hair, 6.0, true)
	draw_circle(Vector2(-12 * fx, -61 + bob), 5.5, hair)  # ponytail
	draw_circle(Vector2(4 * fx, -68 + bob), 1.8, ink)
	draw_circle(Vector2(9 * fx, -68 + bob), 1.8, ink)
	draw_arc(Vector2(6.5 * fx, -64 + bob), 3.0, 0.3, PI - 0.3, 8, Color("b56a5f"), 1.8, true)
	draw_circle(Vector2(1 * fx, -63 + bob), 2.2, Color(0.95, 0.6, 0.6, 0.35))  # cheek

	# metal detector, gently sweeping
	var sweep := sin(t * 3.0) * (10.0 if walking else 4.0)
	var hand := Vector2(18 * fx, -38 + bob)
	var disc := Vector2((46 + sweep) * fx, -5)
	draw_line(hand, disc + Vector2(0, -8), Color("8d99ae"), 4.5)
	DrawKit.ellipse(self, disc, 13.0, 5.5, Color("6f7f96"))
	DrawKit.ellipse(self, disc + Vector2(0, -1.5), 9.0, 3.5, Color("9fb0c4"))
