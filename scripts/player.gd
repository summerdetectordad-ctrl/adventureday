class_name Player
extends Node2D
## Summer — blonde hair, backpack on her back. Origin is at her feet.
## Tap to walk; double-tap to jump toward the tap (straight up if the tap is
## above her head). She lands on blocks, swims across the pond, and grabs
## vines mid-jump — double-tap again to let go. The metal detector lives in
## her backpack until she takes it out.
## Arrow keys / A-D walk, Up/W jumps — desktop testing only.

const GRAVITY := 1500.0
const MAX_FALL := 720.0
const JUMP_VY := -640.0
const JUMP_VX := 250.0
const HAND_UP_Y := -78.0    # where her raised hands are, relative to her feet

var target_x := 0.0
var speed := 230.0
var facing := 1
var walking := false
var t := 0.0

## The meadow (main.gd). It provides floor_y_at, clamp_walk, in_water,
## water_surface_y and vine_near. Null = flat ground (harmless for dev).
var world: Node2D = null
var held_tool := ""         # "", "detector", "net" or "camera" — what is in her hand

var vel_y := 0.0
var jump_vx := 0.0
var on_ground := true
var swimming := false
var climbing := false
var vine: Node2D = null     # Nature.Vine while clinging
var climb_d := 0.0          # distance down the vine, hands on the rope
var climb_target := 0.0
var regrab_t := 0.0         # can't re-grab a vine for a moment after letting go
var reach_t := 0.0          # arm stretched toward reach_local (berries, the bell)
var reach_local := Vector2(26, -46)   # where the reach is aimed, player-local
var talk_t := 0.0           # chatting to an animal, little wave
var swipe_t := 0.0          # the net sweeping a big happy arc
var camera_t := 0.0         # camera held up to take a photo
var drink_t := 0.0          # bottle up, proper gulps
var drink_dur := 1.5
var dig_t := 0.0            # kneeling and scooping with the trowel
var dig_dur := 1.1
var build_t := 0.0            # hammering on the treehouse
var sit_t := 0.0              # sitting down on the grass for a snack
var sit_dur := 0.0
var sit_food: Array = []      # the sandwich she actually made, in her hands
var riding := false           # on the ladder, lift, slide or zip line
var ride_path: PackedVector2Array = PackedVector2Array()
var ride_u := 0.0
var ride_secs := 1.0
var ride_pose := "ladder"     # ladder | lift | slide | zip
var build_dur := 1.6
var blink_t := 0.0          # >0 while the eyes are shut
var blink_in := 2.5         # seconds until the next blink
var base_y := 0.0


func _ready() -> void:
	target_x = position.x
	base_y = position.y


func _process(delta: float) -> void:
	if climbing or swimming or walking or not on_ground:
		t += delta
	else:
		t += delta * 0.35
	regrab_t = maxf(0.0, regrab_t - delta)
	reach_t = maxf(0.0, reach_t - delta)
	talk_t = maxf(0.0, talk_t - delta)
	swipe_t = maxf(0.0, swipe_t - delta)
	camera_t = maxf(0.0, camera_t - delta)
	drink_t = maxf(0.0, drink_t - delta)
	dig_t = maxf(0.0, dig_t - delta)
	build_t = maxf(0.0, build_t - delta)
	sit_t = maxf(0.0, sit_t - delta)
	# a natural blink every few seconds
	if blink_t > 0.0:
		blink_t = maxf(0.0, blink_t - delta)
	else:
		blink_in -= delta
		if blink_in <= 0.0:
			blink_t = 0.13
			blink_in = randf_range(2.2, 5.0)

	# Riding the ladder, the bucket lift, the slide or the zip line: she simply
	# follows the path. Gravity and walking are suspended until she is off.
	if riding:
		ride_u = minf(1.0, ride_u + delta / maxf(0.1, ride_secs))
		global_position = _ride_point(ride_u)
		walking = false
		if ride_u >= 1.0:
			riding = false
			on_ground = false
			vel_y = 0.0
			jump_vx = 0.0
			target_x = position.x
			Sound.land_sound()
		queue_redraw()
		return

	if climbing:
		climb_d = move_toward(climb_d, climb_target, 90.0 * delta)
		global_position = vine.point_at(climb_d) - Vector2(0.0, HAND_UP_Y)
		queue_redraw()
		return

	var key_dir := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		key_dir -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		key_dir += 1.0
	if key_dir != 0.0:
		target_x = position.x + key_dir * speed * 0.5

	var dx := target_x - position.x
	walking = on_ground and not swimming and absf(dx) > 4.0
	if not on_ground:
		if jump_vx != 0.0:
			facing = 1 if jump_vx > 0.0 else -1
		var nx := position.x + jump_vx * delta
		position.x = world.clamp_walk(position.x, nx, position.y) if world else nx
	elif absf(dx) > 4.0:
		facing = 1 if dx > 0.0 else -1
		var sp := speed * (0.55 if swimming else 1.0)
		var nx := move_toward(position.x, target_x, sp * delta)
		position.x = world.clamp_walk(position.x, nx, position.y) if world else nx

	_vertical(delta)
	queue_redraw()


func _vertical(delta: float) -> void:
	var in_water: bool = world != null and world.in_water(position.x)

	if swimming:
		on_ground = true
		vel_y = 0.0
		if not in_water:
			# reached the pond's edge — wade out
			var fy := _floor_y()
			position.y = move_toward(position.y, fy, 160.0 * delta)
			if absf(position.y - fy) < 1.0:
				swimming = false
		else:
			position.y = move_toward(position.y, world.water_surface_y(), 140.0 * delta)
		return

	if on_ground:
		if in_water:
			_enter_water()
			return
		var fy := _floor_y()
		if position.y < fy - 1.0:
			# walked off an edge — drift down gently
			on_ground = false
			vel_y = 0.0
			jump_vx = float(facing) * speed * 0.8 if walking else 0.0
		else:
			position.y = fy
		return

	# airborne
	vel_y = minf(vel_y + GRAVITY * delta, MAX_FALL)
	position.y += vel_y * delta

	if in_water:
		if vel_y > 0.0 and position.y >= world.water_surface_y():
			_enter_water()
		return

	var fy := _floor_y()
	if vel_y > 0.0 and position.y >= fy:
		position.y = fy
		vel_y = 0.0
		jump_vx = 0.0
		on_ground = true
		target_x = position.x
		Sound.land_sound()
	elif world != null and vel_y > -80.0 and regrab_t <= 0.0:
		# near the top of the jump, hands reaching — anything to grab?
		var v: Node2D = world.vine_near(global_position + Vector2(0, HAND_UP_Y))
		if v != null:
			_grab(v)


func _floor_y() -> float:
	return world.floor_y_at(position.x, position.y) if world != null else base_y


func _enter_water() -> void:
	swimming = true
	on_ground = true
	vel_y = 0.0
	jump_vx = 0.0
	walking = false
	Sound.splash()
	if world != null:
		Fx.sparkles(world, position + Vector2(0, -30.0), 6, Color("a9d7e8"))


## Double-tap: jump toward the tap — or, from a vine, launch off toward it.
func try_jump(tap: Vector2) -> void:
	if climbing:
		_launch(tap)
		return
	if not on_ground:
		return
	swimming = false
	on_ground = false
	walking = false
	vel_y = JUMP_VY
	var dxx := tap.x - position.x
	if absf(dxx) < 60.0:
		jump_vx = 0.0
	else:
		facing = 1 if dxx > 0.0 else -1
		jump_vx = JUMP_VX * float(facing)
	target_x = position.x
	Sound.jump_sound()


func _grab(v: Node2D) -> void:
	climbing = true
	vine = v
	walking = false
	on_ground = false
	vel_y = 0.0
	jump_vx = 0.0
	var hand := global_position + Vector2(0, HAND_UP_Y)
	climb_d = clampf(hand.y - v.global_position.y, v.min_d(), v.max_d())
	climb_target = climb_d
	Sound.grab_sound()


## Single tap while clinging: taps beside her pump the swing, taps above
## shimmy up, taps below shimmy down.
func climb_toward(tap: Vector2) -> void:
	if not climbing:
		return
	var d := tap - (position + Vector2(0, -50.0))
	if absf(d.x) > absf(d.y) and absf(d.x) > 40.0:
		vine.pump(signf(d.x))
		facing = 1 if d.x > 0.0 else -1
		Sound.swish()
	elif d.y < -30.0:
		climb_target = maxf(vine.min_d(), climb_target - 62.0)
		Sound.pop()
	elif d.y > 30.0:
		climb_target = minf(vine.max_d(), climb_target + 62.0)
		Sound.pop()


## Double-tap while clinging: fling off the vine toward the tap, carrying the
## swing's momentum. A tap straight below just drops her off gently.
func _launch(tap: Vector2) -> void:
	var v: Node2D = vine
	var d := climb_d
	climbing = false
	vine = null
	regrab_t = 0.6
	on_ground = false
	walking = false
	target_x = position.x
	var swing_vx := clampf(-v.ang_vel * d, -260.0, 260.0)
	var dxx := tap.x - position.x
	if absf(dxx) < 60.0:
		if tap.y > position.y - 40.0:
			vel_y = 60.0
			jump_vx = swing_vx * 0.4
			Sound.pop()
			return
		vel_y = JUMP_VY * 0.85
		jump_vx = swing_vx
	else:
		facing = 1 if dxx > 0.0 else -1
		vel_y = JUMP_VY
		jump_vx = JUMP_VX * 1.35 * float(facing) + swing_vx * 0.6
	Sound.jump_sound()


func let_go() -> void:
	if not climbing:
		return
	climbing = false
	vine = null
	regrab_t = 0.6
	on_ground = false
	vel_y = 60.0
	jump_vx = 0.0
	target_x = position.x
	Sound.pop()


func face_toward(x: float) -> void:
	if absf(x - position.x) > 2.0:
		facing = 1 if x > position.x else -1


## Stretch an arm out toward a world point (a berry, the bell) with a little
## crouch — reads clearly as "grabbing that". Kept short so the arm stays a
## natural length; main.gd walks her close before this fires.
func reach(toward: Vector2 = Vector2.INF) -> void:
	reach_t = 0.7
	if toward != Vector2.INF:
		var d := toward - (global_position + Vector2(0, -50.0))
		facing = 1 if d.x >= 0.0 else -1
		reach_local = d.limit_length(30.0)
		if reach_local.length() < 10.0:
			reach_local = Vector2(20.0 * facing, -6.0)
	else:
		reach_local = Vector2(20.0 * facing, 4.0)
	queue_redraw()


## A proper drink: bottle up to her mouth, head back, real gulps.
func drink() -> void:
	drink_t = drink_dur
	queue_redraw()


## Ride a path: the rope ladder up, the bucket lift up, the slide down, the
## zip line across. She follows `path` over `seconds`, then drops the last
## little bit onto whatever is under her. Nothing here can go wrong — the ride
## always finishes, and she always lands on her feet.
func ride(path: PackedVector2Array, seconds: float, pose := "ladder") -> void:
	if path.size() < 2:
		return
	ride_path = path
	ride_secs = maxf(0.2, seconds)
	ride_pose = pose
	ride_u = 0.0
	riding = true
	climbing = false
	vine = null
	swimming = false
	walking = false
	vel_y = 0.0
	jump_vx = 0.0
	global_position = path[0]
	target_x = position.x
	queue_redraw()


## Where along the ride path she is, 0..1.
func _ride_point(u: float) -> Vector2:
	var n := ride_path.size()
	if n == 0:
		return global_position
	var f := clampf(u, 0.0, 1.0) * (n - 1)
	var i := clampi(int(f), 0, n - 2)
	return ride_path[i].lerp(ride_path[i + 1], f - i)


## Sit down on the grass and eat the thing she actually made — the sandwich
## she stacked, or a slice of her pie, drawn in her hands as she bites it.
func sit_and_eat(food: Array, seconds := 4.4) -> void:
	sit_food = food.duplicate()
	sit_dur = seconds
	sit_t = seconds
	target_x = position.x
	queue_redraw()


## How far through the snack she is, 0..1.
func eat_progress() -> float:
	if sit_dur <= 0.0:
		return 1.0
	return clampf(1.0 - sit_t / sit_dur, 0.0, 1.0)


## Kneel down and scoop with the trowel.
func start_dig() -> void:
	dig_t = dig_dur
	queue_redraw()


## Hammer at the treehouse.
func build(toward_x: float) -> void:
	face_toward(toward_x)
	build_t = build_dur
	queue_redraw()


func talk() -> void:
	talk_t = 2.6
	queue_redraw()


## Sweep the butterfly net in a big arc.
func swipe() -> void:
	swipe_t = 0.45
	queue_redraw()


## Both hands up, camera out — say cheese!
func hold_camera() -> void:
	camera_t = 1.5
	queue_redraw()


## --- drawing -----------------------------------------------------------------
## Summer is drawn as a proper little figure: two-segment arms and legs with
## elbows and knees, soft dark outlines for definition, a blink, and real
## poses for everything she does (drinking, digging, hammering, reaching).

const SKIN := Color("f2c9a5")
const HAIR := Color("f0cd7e")
const SHIRT := Color("cfc192")
const SHORTS := Color("8a9166")
const BOOT := Color("8a6f5c")
const PACK := Color("8fb7d9")
const HAT := Color("d9c9a0")
const INK := Color("4a3a30")


## A limb segment with a soft outline underneath.
## Two-bone limb: root -> joint -> tip, joint bulging toward `bend_dir`.
func _limb2(root: Vector2, tip: Vector2, bend_dir: Vector2, rest_len: float,
		col: Color, w: float) -> Vector2:
	var slack := maxf(0.0, rest_len - root.distance_to(tip))
	var joint := (root + tip) * 0.5 + bend_dir.normalized() * (2.0 + slack * 0.55)
	draw_line(root, joint, col.darkened(0.35), w + 2.6)
	draw_line(joint, tip, col.darkened(0.35), w + 2.4)
	draw_line(root, joint, col, w)
	draw_line(joint, tip, col, w * 0.92)
	return joint


func _hand(p: Vector2, col := SKIN) -> void:
	draw_circle(p, 4.2, col.darkened(0.35))
	draw_circle(p, 3.1, col)


## One leg: hip -> knee -> ankle, with a boot at the foot.
func _leg(hip: Vector2, foot: Vector2, fx: float, tone: float) -> void:
	var col := SKIN.darkened(tone)
	_limb2(hip, foot + Vector2(0, -7.0), Vector2(fx, 0.2), 26.0, col, 5.0)
	# sock cuff
	draw_line(foot + Vector2(-3.2, -8.5), foot + Vector2(3.2, -8.5), Color("fff8ec"), 3.0)
	# boot with sole and a lit toe
	var bcol := BOOT.darkened(tone)
	DrawKit.rounded_rect(self, Rect2(foot + Vector2(-5.5, -7.5), Vector2(12.5, 7.5)), 3.0, bcol.darkened(0.3))
	DrawKit.rounded_rect(self, Rect2(foot + Vector2(-4.5, -6.8), Vector2(10.8, 6.0)), 2.5, bcol)
	draw_rect(Rect2(foot + Vector2(-4.5, -1.6), Vector2(10.8, 1.6)), Color("5e4433"))
	draw_line(foot + Vector2(-3.0, -5.5), foot + Vector2(4.5, -5.5), bcol.lightened(0.15), 1.3)


func _draw() -> void:
	var fx := float(facing)
	if swimming:
		_draw_swimming(fx)
		return

	# --- pose selection -------------------------------------------------------
	# a ride borrows the poses that already exist: hanging for the ladder and
	# zip line, seated for the slide and the bucket
	var hanging := climbing or (riding and (ride_pose == "ladder" or ride_pose == "zip"))
	var walk_ph := t * 9.0
	var bob := 0.0
	if hanging:
		bob = 0.0
	elif riding:
		bob = 0.0
	elif not on_ground:
		bob = 0.0
	elif walking:
		bob = -absf(sin(walk_ph)) * 3.0
	else:
		bob = sin(t * 2.0) * 1.2
	var digging := dig_t > 0.0 and on_ground
	var building := build_t > 0.0 and on_ground and not digging
	var on_bike := riding and ride_pose == "bike"
	var sitting := (sit_t > 0.0 and on_ground and not digging and not building) \
		or (riding and (ride_pose == "slide" or ride_pose == "lift")) or on_bike
	var drinking := drink_t > 0.0 and on_ground and not digging and not building \
		and not sitting
	if reach_t > 0.0 and on_ground:
		bob += 3.5
	if digging:
		bob += 11.0    # a proper kneel
	if sitting:
		# right down on the grass — except on the bike, where she sits UP on
		# the saddle with the frame under her
		bob += -4.0 if on_bike else 20.0

	# soft shadow under her feet while she's on the ground
	if on_ground and not hanging and not riding:
		DrawKit.soft_shadow(self, Vector2(0, 1), 17.0, 0.13)

	# --- backpack (behind everything) ----------------------------------------
	DrawKit.rounded_rect(self, Rect2(-16.0 * fx - 10.0, -59.0 + bob, 20.0, 30.0), 8.0, PACK.darkened(0.35))
	DrawKit.rounded_rect(self, Rect2(-16.0 * fx - 9.0, -58.0 + bob, 18.0, 28.0), 7.0, PACK)
	DrawKit.rounded_rect(self, Rect2(-16.0 * fx - 9.0, -58.0 + bob, 18.0, 10.0), 5.0, PACK.darkened(0.1))
	DrawKit.rounded_rect(self, Rect2(-16.0 * fx - 6.5, -44.0 + bob, 13.0, 10.0), 4.0, PACK.darkened(0.06))
	draw_line(Vector2(-16.0 * fx - 6.0, -47.0 + bob), Vector2(-16.0 * fx + 6.0, -47.0 + bob),
		PACK.lightened(0.15), 1.5)
	if held_tool != "detector" or not on_ground:
		draw_line(Vector2(-16.0 * fx, -58.0 + bob), Vector2(-21.0 * fx, -73.0 + bob), Color("8d99ae"), 4.0)
		DrawKit.ellipse(self, Vector2(-22.0 * fx, -76.0 + bob), 6.0, 3.0, Color("6f7f96"))

	# --- skeleton anchors -----------------------------------------------------
	var hip_b := Vector2(-3.0 * fx, -32.0 + bob)
	var hip_f := Vector2(3.5 * fx, -32.0 + bob)
	var sho_b := Vector2(-6.0 * fx, -51.0 + bob)
	var sho_f := Vector2(6.0 * fx, -51.0 + bob)

	# --- feet per pose --------------------------------------------------------
	var foot_b: Vector2
	var foot_f: Vector2
	if hanging:
		foot_b = Vector2(-4.5 * fx, -8.0 - sin(t * 4.0) * 3.0)
		foot_f = Vector2(4.5 * fx, -8.0 + sin(t * 4.0) * 3.0)
	elif not on_ground:
		foot_b = Vector2(-9.0 * fx, -6.0)
		foot_f = Vector2(10.0 * fx, -13.0)
	elif sitting:
		# legs stretched out in front, the way children sit to eat
		foot_b = Vector2(25.0 * fx, 2.0)
		foot_f = Vector2(31.0 * fx, 0.0)
	elif digging:
		foot_b = Vector2(-10.0 * fx, 0.0)
		foot_f = Vector2(13.0 * fx, 0.0)
	elif walking:
		var s1 := sin(walk_ph)
		foot_f = Vector2((5.5 + s1 * 10.0) * fx, -maxf(0.0, cos(walk_ph)) * 6.0)
		foot_b = Vector2((-5.5 - s1 * 10.0) * fx, -maxf(0.0, -cos(walk_ph)) * 6.0)
	else:
		foot_b = Vector2(-5.5 * fx, 0.0)
		foot_f = Vector2(5.5 * fx, 0.0)

	# --- back arm target ------------------------------------------------------
	var hand_b: Vector2
	if camera_t > 0.0 and on_ground:
		hand_b = Vector2(1.0 * fx, -62.0 + bob)
	elif hanging:
		hand_b = Vector2(-3.0, -76.0)
	elif not on_ground:
		hand_b = Vector2(-14.0 * fx, -60.0)
	elif sitting:
		hand_b = Vector2(-8.0 * fx, -22.0 + bob)
	elif digging:
		hand_b = Vector2(6.0 * fx, -16.0 + bob * 0.2)
	elif drinking:
		hand_b = Vector2(-9.0 * fx, -30.0 + bob)
	elif walking:
		hand_b = Vector2((-7.0 - sin(walk_ph) * 6.0) * fx, -30.0 + bob)
	else:
		hand_b = Vector2(-8.5 * fx, -29.0 + bob + sin(t * 2.0) * 0.8)

	# --- draw: back arm, legs, torso, front arm, head, props ------------------
	_limb2(sho_b, hand_b, Vector2(-fx * 0.4, 1.0), 24.0, SKIN.darkened(0.08), 4.2)
	_hand(hand_b, SKIN.darkened(0.08))

	_leg(hip_b, foot_b, fx, 0.08)
	_leg(hip_f, foot_f, fx, 0.0)

	# shirt with collar, side shade and buttons
	var shirt_pts := PackedVector2Array([
		Vector2(-8 * fx, -56 + bob), Vector2(8 * fx, -56 + bob),
		Vector2(11 * fx, -34 + bob), Vector2(-11 * fx, -34 + bob),
	])
	draw_polygon(shirt_pts, PackedColorArray([SHIRT]))
	draw_polygon(PackedVector2Array([
		Vector2(-8 * fx, -56 + bob), Vector2(-4 * fx, -56 + bob),
		Vector2(-6 * fx, -34 + bob), Vector2(-11 * fx, -34 + bob),
	]), PackedColorArray([SHIRT.darkened(0.09)]))
	var outline_pts := shirt_pts.duplicate()
	outline_pts.append(shirt_pts[0])
	draw_polyline(outline_pts, SHIRT.darkened(0.35), 1.6, true)
	draw_rect(Rect2(5 * fx - 3, -51 + bob, 6, 5), SHIRT.darkened(0.12))
	draw_line(Vector2(5 * fx - 3, -51 + bob), Vector2(5 * fx + 3, -51 + bob), SHIRT.darkened(0.25), 1.2)
	draw_circle(Vector2(0, -50 + bob), 1.1, SHIRT.darkened(0.3))
	draw_circle(Vector2(0, -44 + bob), 1.1, SHIRT.darkened(0.3))
	# rolled sleeve cuffs at the shoulders
	DrawKit.ellipse(self, sho_b + Vector2(0, 2), 4.5, 5.5, SHIRT.darkened(0.12))
	DrawKit.ellipse(self, sho_f + Vector2(0, 2), 4.5, 5.5, SHIRT)
	# cargo shorts with belt, buckle and pocket stitching
	DrawKit.rounded_rect(self, Rect2(-12.7, -38.7 + bob, 25.4, 11.4), 3.5, SHORTS.darkened(0.35))
	DrawKit.rounded_rect(self, Rect2(-12, -38 + bob, 24, 10), 3.0, SHORTS)
	draw_rect(Rect2(-13, -30 + bob, 10, 7), SHORTS)
	draw_rect(Rect2(3, -30 + bob, 10, 7), SHORTS.darkened(0.06))
	draw_line(Vector2(-11, -25 + bob), Vector2(-5, -25 + bob), SHORTS.darkened(0.22), 1.2)
	draw_line(Vector2(5, -25 + bob), Vector2(11, -25 + bob), SHORTS.darkened(0.22), 1.2)
	draw_rect(Rect2(-11, -38 + bob, 22, 3), Color("8a6a44"))
	draw_rect(Rect2(-1.5, -38 + bob, 3, 3), Color("d9b45c"))
	# coral neckerchief with a knot
	draw_polygon(PackedVector2Array([
		Vector2(-6 * fx, -56 + bob), Vector2(7 * fx, -56 + bob), Vector2(1 * fx, -45 + bob),
	]), PackedColorArray([Color("e8918c")]))
	draw_polygon(PackedVector2Array([
		Vector2(-2 * fx, -56 + bob), Vector2(4 * fx, -56 + bob), Vector2(1 * fx, -50 + bob),
	]), PackedColorArray([Color("d97f7a")]))
	draw_circle(Vector2(1 * fx, -55 + bob), 1.6, Color("c96b64"))
	# backpack strap
	draw_line(Vector2(-8 * fx, -54 + bob), Vector2(3 * fx, -40 + bob), PACK.darkened(0.15), 4.0)

	# --- front arm target -----------------------------------------------------
	var hand_f: Vector2
	if camera_t > 0.0 and on_ground:
		hand_f = Vector2(10.0 * fx, -62.0 + bob)
	elif hanging:
		hand_f = Vector2(3.0, -76.0)
	elif not on_ground:
		hand_f = Vector2(15.0 * fx, -64.0)
	elif sitting:
		# the sandwich comes up to her mouth for each bite, then back down
		var bite := absf(sin(eat_progress() * PI * 3.0))
		hand_f = Vector2(lerpf(13.0, 7.0, bite) * fx, lerpf(-34.0, -60.0, bite) + bob)
	elif digging:
		hand_f = Vector2(15.0 * fx, -18.0)
	elif building:
		var swing_a := -1.5 + absf(sin((build_dur - build_t) * 7.5)) * 1.05
		hand_f = sho_f + Vector2(cos(swing_a) * 17.0 * fx, sin(swing_a) * 17.0)
	elif drinking:
		hand_f = Vector2(6.5 * fx, -60.0 + bob)
	elif swipe_t > 0.0 and held_tool == "net":
		hand_f = Vector2(15.0 * fx, -40.0 + bob)
	elif reach_t > 0.0:
		hand_f = Vector2(6 * fx, -50 + bob) + (reach_local - Vector2(0, -4.0))
	elif talk_t > 0.0:
		hand_f = Vector2((14.0 + sin(t * 8.0) * 3.5) * fx, -64 + bob)
	elif held_tool != "" and on_ground:
		hand_f = Vector2(15.0 * fx, -37.0 + bob)
	elif walking:
		hand_f = Vector2((7.0 + sin(walk_ph) * 6.0) * fx, -30.0 + bob)
	else:
		hand_f = Vector2(8.5 * fx, -29.0 + bob - sin(t * 2.0) * 0.8)

	_limb2(sho_f, hand_f, Vector2(fx * 0.15, 1.0), 24.0, SKIN, 4.4)
	_hand(hand_f)

	_draw_head(fx, bob, drinking)

	# --- props ----------------------------------------------------------------
	if camera_t > 0.0 and on_ground:
		DrawKit.rounded_rect(self, Rect2(Vector2(2 * fx - 11, -71 + bob), Vector2(22, 15)), 4.5, Color("55636f"))
		DrawKit.rounded_rect(self, Rect2(Vector2(2 * fx - 10, -70 + bob), Vector2(20, 13)), 4.0, Color("7a8b9c"))
		draw_circle(Vector2(2 * fx, -63.5 + bob), 4.5, Color("9fb0c4"))
		draw_circle(Vector2(2 * fx, -63.5 + bob), 2.5, Color("5c6b7a"))
		draw_circle(Vector2(2 * fx + 1.2, -64.5 + bob), 1.0, Color.WHITE)
		draw_circle(Vector2(2 * fx + 7, -67 + bob), 1.4, Color("ffd98a"))
		return

	if sitting:
		# The sandwich she actually built, shrinking bite by bite. Nothing is
		# ever wrong here — a tower of nine fillings is a fine sandwich.
		var eaten := eat_progress()
		var left := maxi(0, int(ceil(sit_food.size() * (1.0 - eaten))))
		var hp := hand_f + Vector2(3.0 * fx, -2.0)
		for i in left:
			var ly := hp.y - i * 4.2
			var col := _food_colour(str(sit_food[i]))
			DrawKit.rounded_rect(self, Rect2(hp.x - 8, ly - 4.0, 16, 4.4), 1.6, col)
		if left == 0 and eaten < 0.999:
			DrawKit.heart(self, hp + Vector2(0, -10), 4.0, Color("f2a0b5"))
		return

	if drinking:
		# the bottle tilts up as she drinks; little bubbles at each gulp
		var p := 1.0 - drink_t / drink_dur
		var tilt := lerpf(0.25, 1.2, clampf(p * 1.7, 0.0, 1.0)) * fx
		var mouth := Vector2(7.0 * fx, -62.5 + bob)
		draw_set_transform(mouth, tilt, Vector2.ONE)
		DrawKit.rounded_rect(self, Rect2(-4.0, -16.0, 8.0, 15.0), 2.5, Color("6e8fb0"))
		DrawKit.rounded_rect(self, Rect2(-3.2, -15.2, 6.4, 13.4), 2.2, Color("a9c9e8"))
		draw_rect(Rect2(-2.0, -18.5, 4.0, 3.5), Color("7a8b9c"))
		DrawKit.ellipse(self, Vector2(-0.8, -9.0), 1.6, 3.5, Color("cfe9f4"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if fmod(p * 2.5, 1.0) < 0.35 and p > 0.25:
			draw_circle(mouth + Vector2(4.0 * fx, -6.0), 1.5, Color(1, 1, 1, 0.6))
			draw_circle(mouth + Vector2(6.5 * fx, -10.0), 1.0, Color(1, 1, 1, 0.45))
		return

	if digging:
		# trowel scooping in her front hand
		var p := 1.0 - dig_t / dig_dur
		var scoop := sin(p * PI * 3.0) * 0.5
		var ta := (0.65 + scoop) * fx
		draw_set_transform(hand_f, ta, Vector2(fx, 1.0))
		draw_line(Vector2.ZERO, Vector2(9.0, 4.0), Color("8a6a44"), 3.5)
		draw_polygon(PackedVector2Array([
			Vector2(9.0, 1.0), Vector2(18.0, 4.5), Vector2(9.0, 8.0),
		]), PackedColorArray([Color("8d99ae")]))
		draw_polygon(PackedVector2Array([
			Vector2(10.0, 2.5), Vector2(16.0, 4.5), Vector2(10.0, 6.5),
		]), PackedColorArray([Color("aab6c4")]))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return

	if building:
		# a little wooden mallet swinging from her front hand
		var dir := (hand_f - sho_f).normalized()
		var head_p := hand_f + dir * 13.0
		draw_line(hand_f, head_p, Color("8a6a44"), 3.5)
		draw_set_transform(head_p, dir.angle(), Vector2.ONE)
		DrawKit.rounded_rect(self, Rect2(-4.0, -6.5, 8.0, 13.0), 2.5, Color("77573d"))
		DrawKit.rounded_rect(self, Rect2(-3.2, -5.7, 6.4, 11.4), 2.2, Color("a97e54"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return

	# her tool, when it's out and she's on foot (and not busy waving/reaching)
	if on_ground and talk_t <= 0.0 and (reach_t <= 0.0 or swipe_t > 0.0):
		if held_tool == "detector":
			var sweep := sin(t * 3.0) * (10.0 if walking else 4.0)
			var disc := Vector2((44 + sweep) * fx, -5)
			draw_line(hand_f, disc + Vector2(0, -8), Color("55636f"), 6.0)
			draw_line(hand_f, disc + Vector2(0, -8), Color("8d99ae"), 4.0)
			DrawKit.ellipse(self, disc, 14.0, 6.0, Color("55636f"))
			DrawKit.ellipse(self, disc, 13.0, 5.5, Color("6f7f96"))
			DrawKit.ellipse(self, disc + Vector2(0, -1.5), 9.0, 3.5, Color("9fb0c4"))
			draw_circle(hand_f + (disc + Vector2(0, -8) - hand_f) * 0.4, 2.2, Color("d9b45c"))
		elif held_tool == "camera":
			# the camera, held ready at her side — she raises it to her eye in
			# hold_camera(), which the camera_t pose above handles
			var cam := hand_f + Vector2(6.0 * fx, -4.0)
			DrawKit.rounded_rect(self, Rect2(cam.x - 11.0, cam.y - 7.0, 22.0, 14.0),
				3.5, Color("55636f"))
			DrawKit.rounded_rect(self, Rect2(cam.x - 4.0, cam.y - 10.0, 9.0, 4.0),
				1.6, Color("55636f"))
			draw_circle(cam, 5.0, Color("9fb0c4"))
			draw_circle(cam, 3.2, Color("3f4a55"))
			draw_circle(cam + Vector2(-1.2, -1.2), 1.1, Color(1, 1, 1, 0.8))
			draw_circle(cam + Vector2(8.0, -4.0), 1.4, Color("ffd98a"))
			# the strap round her neck
			draw_line(Vector2(-4.0 * fx, -60.0), cam + Vector2(-8.0, -2.0),
				Color("6e5039"), 2.0)
		elif held_tool == "net":
			var a := -1.15 + sin(t * 2.0) * 0.06
			if swipe_t > 0.0:
				a = lerpf(-2.3, -0.25, 1.0 - swipe_t / 0.45)
			var tip := hand_f + Vector2(cos(a) * 40.0 * fx, sin(a) * 40.0)
			var hoop := hand_f + Vector2(cos(a) * 54.0 * fx, sin(a) * 54.0)
			draw_line(hand_f, tip, Color("6e5039"), 5.5)
			draw_line(hand_f, tip, Color("a97e54"), 3.5)
			draw_arc(hoop, 13.0, 0, TAU, 16, Color("6e8fb0"), 3.5, true)
			for i in 3:
				var my := -6.0 + i * 6.0
				draw_arc(hoop + Vector2(0, my), maxf(3.0, 13.0 - absf(my)), PI * 0.15, PI * 0.85, 8,
					Color("a9c9e8"), 1.5, true)


func _draw_swimming(fx: float) -> void:
	var bob := sin(t * 2.6) * 2.0
	# ripple ring around her
	DrawKit.ellipse(self, Vector2(0, -38), 36.0 + sin(t * 3.0) * 3.0, 7.0, Color("cfe9f4"))
	# shoulders just above the water
	DrawKit.ellipse(self, Vector2(0, -46 + bob * 0.5), 14.0, 10.0, SHIRT.darkened(0.35))
	DrawKit.ellipse(self, Vector2(0, -46 + bob * 0.5), 13.0, 9.0, SHIRT)
	# paddling arms with elbows
	var a := t * 5.5
	var hand_a := Vector2(fx * (14.0 + cos(a) * 6.0), -40 + sin(a) * 5.0)
	var hand_b := Vector2(fx * -(12.0 + sin(a) * 5.0), -41 + cos(a) * 5.0)
	_limb2(Vector2(4.0 * fx, -48 + bob * 0.5), hand_a, Vector2(fx * 0.3, 1.0), 20.0, SKIN, 4.2)
	_limb2(Vector2(-4.0 * fx, -48 + bob * 0.5), hand_b, Vector2(-fx * 0.3, 1.0), 20.0, SKIN.darkened(0.06), 4.0)
	_hand(hand_a)
	# little kick splashes behind
	for i in 2:
		var sx := -fx * (24.0 + i * 9.0)
		draw_circle(Vector2(sx, -34 + sin(t * 7.0 + i) * 3.0), 3.0 - i, Color(1, 1, 1, 0.5))
	_draw_head(fx, 16.0 + bob, false)


func _draw_head(fx: float, bob: float, drinking: bool) -> void:
	var head_c := Vector2(0, -68 + bob)
	if drinking:
		head_c += Vector2(-1.5 * fx, -1.5)   # head tips back for the drink
	# outlined head
	draw_circle(head_c, 14.2, SKIN.darkened(0.32))
	draw_circle(head_c, 13.0, SKIN)
	# soft shading on the back of her head, away from the sun
	if fx > 0.0:
		draw_arc(head_c, 11.0, PI * 0.6, PI * 1.4, 8, SKIN.darkened(0.07), 3.5, true)
	else:
		draw_arc(head_c, 11.0, -PI * 0.4, PI * 0.4, 8, SKIN.darkened(0.07), 3.5, true)
	# little ear on the near side
	draw_circle(head_c + Vector2(-10.5 * fx, 2.0), 3.0, SKIN.darkened(0.32))
	draw_circle(head_c + Vector2(-10.5 * fx, 2.0), 2.2, SKIN)
	draw_arc(head_c + Vector2(-10.5 * fx, 2.0), 1.1, 0, PI, 6, SKIN.darkened(0.18), 1.0, true)
	# hair: cap, fringe strands, ponytail with bobble
	draw_circle(head_c + Vector2(-3 * fx, -7), 10.0, HAIR)
	draw_arc(head_c, 12.0, PI + 0.25, TAU - 0.45, 12, HAIR, 6.0, true)
	draw_arc(head_c + Vector2(-1 * fx, -2), 12.5, PI + 0.5, PI + 1.3, 6, HAIR.darkened(0.1), 1.5, true)
	draw_arc(head_c + Vector2(1 * fx, -2), 12.5, TAU - 1.2, TAU - 0.5, 6, HAIR.lightened(0.12), 1.5, true)
	for st in 3:
		var sx := (2.0 + st * 3.0) * fx
		draw_line(head_c + Vector2(sx, -11.5), head_c + Vector2(sx + 1.0 * fx, -8.0),
			HAIR.darkened(0.12), 1.3)
	# ponytail: outlined, swishing gently as she moves
	var sway := sin(t * (9.0 if walking else 2.0)) * (2.5 if walking else 1.0)
	var tail_r := head_c + Vector2(-12 * fx, 7)
	draw_circle(tail_r + Vector2(0, -13), 6.3, HAIR.darkened(0.3))
	draw_circle(tail_r + Vector2(0, -13), 5.5, HAIR)
	DrawKit.ellipse(self, tail_r + Vector2(-2 * fx + sway * 0.4, -5), 4.2, 7.5, HAIR.darkened(0.3))
	DrawKit.ellipse(self, tail_r + Vector2(-2 * fx + sway * 0.4, -5), 3.5, 6.5, HAIR.darkened(0.04))
	DrawKit.ellipse(self, tail_r + Vector2(-3.5 * fx + sway, 3), 2.8, 4.5, HAIR.darkened(0.08))
	draw_circle(head_c + Vector2(-11 * fx, 2), 2.2, Color("e8918c"))
	# safari hat: outlined crown and brim, band with a pin
	DrawKit.ellipse(self, head_c + Vector2(-1 * fx, -9.5), 18.2, 5.8, HAT.darkened(0.35))
	draw_circle(head_c + Vector2(-1 * fx, -14), 10.4, HAT.darkened(0.35))
	draw_circle(head_c + Vector2(-1 * fx, -14), 9.5, HAT)
	draw_arc(head_c + Vector2(-1 * fx, -15), 7.5, PI + 0.4, TAU - 0.4, 8, HAT.lightened(0.1), 3.0, true)
	DrawKit.ellipse(self, head_c + Vector2(-1 * fx, -9), 17.5, 5.0, HAT.darkened(0.12))
	DrawKit.ellipse(self, head_c + Vector2(-1 * fx, -10), 17.0, 5.0, HAT)
	DrawKit.ellipse(self, head_c + Vector2(-1 * fx, -11.5), 17.0, 4.0, HAT.lightened(0.08))
	draw_line(head_c + Vector2(-10 * fx, -12), head_c + Vector2(8 * fx, -12), Color("a97e54"), 3.0)
	draw_circle(head_c + Vector2(5 * fx, -12), 1.4, Color("d9b45c"))
	# face: brows, blinking eyes with glints, nose, mouth, blush
	var eye_a := head_c + Vector2(4 * fx, 0)
	var eye_b := head_c + Vector2(9 * fx, 0)
	draw_arc(eye_a + Vector2(0, -3.5), 2.4, PI + 0.5, TAU - 0.5, 6, HAIR.darkened(0.25), 1.2, true)
	draw_arc(eye_b + Vector2(0, -3.5), 2.4, PI + 0.5, TAU - 0.5, 6, HAIR.darkened(0.25), 1.2, true)
	if blink_t > 0.0:
		draw_line(eye_a + Vector2(-1.8, 0.3), eye_a + Vector2(1.8, 0.3), INK, 1.4)
		draw_line(eye_b + Vector2(-1.8, 0.3), eye_b + Vector2(1.8, 0.3), INK, 1.4)
	else:
		draw_circle(eye_a, 2.0, INK)
		draw_circle(eye_b, 2.0, INK)
		draw_circle(eye_a + Vector2(-0.6, -0.6), 0.7, Color.WHITE)
		draw_circle(eye_b + Vector2(-0.6, -0.6), 0.7, Color.WHITE)
	draw_circle(head_c + Vector2(6.5 * fx, 3.2), 1.1, SKIN.darkened(0.15))   # nose
	if drinking:
		DrawKit.ellipse(self, head_c + Vector2(6.5 * fx, 5.8), 2.0, 2.6, Color("9c6b5a"))
	else:
		draw_arc(head_c + Vector2(6.5 * fx, 4), 3.0, 0.3, PI - 0.3, 8, Color("b56a5f"), 1.8, true)
	draw_circle(head_c + Vector2(-3.5 * fx, 3.5), 2.2, Color(0.95, 0.6, 0.6, 0.3))


## The colour of one sandwich or pie layer, for the little stack she holds
## while she eats. Matches the ingredient colours in the picnic game.
func _food_colour(kind: String) -> Color:
	match kind:
		"bread": return Color("e8c88a")
		"butter": return Color("ffe9a8")
		"jam": return Color("b56a9f")
		"cheese": return Color("ffd98a")
		"tomato": return Color("e07a70")
		"lettuce": return Color("a8d5a2")
		"ham": return Color("f2b8b0")
		"cucumber": return Color("8cc188")
		"pastry": return Color("e8c88a")
		"apple": return Color("e05c50")
		"berry": return Color("8a5fa8")
	return Color("e8c88a")
