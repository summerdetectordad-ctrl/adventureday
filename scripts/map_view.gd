class_name MapView
extends CanvasLayer
## The meadow map from Summer's backpack: the whole world as one friendly
## strip, with a gently pulsing "you are here" dot that moves live. Icons
## only — no reading needed to understand it.

signal closed

var world_node: Node2D   # main.gd — for the live player position


func _ready() -> void:
	layer = 40
	var sheet := Sheet.new()
	sheet.world_node = world_node
	add_child(sheet)

	var pack_btn := IconButton.new("pack", 96.0)
	pack_btn.pressed.connect(func() -> void: closed.emit())
	sheet.add_child(pack_btn)
	sheet.pack_btn = pack_btn
	sheet.layout_buttons()


class Sheet extends Control:
	var world_node: Node2D
	var pack_btn: IconButton
	var t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		get_viewport().size_changed.connect(layout_buttons)

	func layout_buttons() -> void:
		var vs := get_viewport().get_visible_rect().size
		size = vs
		if pack_btn:
			pack_btn.position = Vector2(vs.x - 120, 24)

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			accept_event()

	## World x -> map position along the strip.
	func _mx(x: float) -> float:
		var world_w: float = world_node.WORLD_W if world_node else 4200.0
		return lerpf(110.0, size.x - 110.0, clampf(x / world_w, 0.0, 1.0))

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("eef7fb"))
		# parchment
		var card := Rect2(Vector2(40, 120), size - Vector2(80, 280))
		DrawKit.rounded_rect(self, Rect2(card.position + Vector2(0, 6), card.size), 26.0, Color(0, 0, 0, 0.07))
		DrawKit.rounded_rect(self, card, 26.0, Color("fff2d9"))
		DrawKit.rounded_rect_outline(self, card, 26.0, Color("e0cba0"), 4.0)
		# a compass sun in the corner
		var comp := card.position + Vector2(74, 68)
		for i in 8:
			var a := TAU * i / 8.0
			draw_line(comp + Vector2.from_angle(a) * 16.0, comp + Vector2.from_angle(a) * 28.0, Color("ffd98a"), 4.0)
		draw_circle(comp, 13.0, Color("ffd98a"))
		draw_circle(comp, 9.0, Color("ffe6b3"))

		var gy := card.position.y + card.size.y * 0.62   # the ground line
		# grass strip and dotted path
		draw_rect(Rect2(card.position.x + 40, gy, card.size.x - 80, 14), Color("a8d5a2"))
		for i in 40:
			var px := lerpf(card.position.x + 60, card.end.x - 60, i / 39.0)
			draw_circle(Vector2(px, gy - 6), 2.0, Color("d9c9a8"))

		# treehouse
		var th := Vector2(_mx(250.0), gy)
		draw_rect(Rect2(th + Vector2(-5, -46), Vector2(10, 46)), Color("8a6a52"))
		draw_circle(th + Vector2(0, -58), 24.0, Color("9ccf8f"))
		DrawKit.rounded_rect(self, Rect2(th + Vector2(-14, -70), Vector2(28, 20)), 4.0, Color("c9a06c"))
		# trees
		for tx in [950.0, 1750.0, 3100.0, 3950.0]:
			var tp := Vector2(_mx(tx), gy)
			draw_rect(Rect2(tp + Vector2(-3, -24), Vector2(6, 24)), Color("8a6a52"))
			draw_circle(tp + Vector2(0, -32), 14.0, Color("9ccf8f"))
		# berry bushes
		for bx in [1150.0, 2200.0, 3450.0]:
			var bp := Vector2(_mx(bx), gy)
			draw_circle(bp + Vector2(0, -8), 11.0, Color("8cc188"))
			draw_circle(bp + Vector2(-3, -10), 2.2, Color("6d4788"))
			draw_circle(bp + Vector2(4, -6), 2.2, Color("6d4788"))
		# pond
		DrawKit.ellipse(self, Vector2(_mx(2750.0), gy + 4), 34.0, 10.0, Color("a9d7e8"))
		# picnic
		var pp := Vector2(_mx(3720.0), gy)
		draw_polygon(PackedVector2Array([
			pp + Vector2(-14, 0), pp + Vector2(14, 0), pp + Vector2(9, -8), pp + Vector2(-9, -8),
		]), PackedColorArray([Color("f2c9c9")]))
		# lookout perches and vines
		if world_node:
			for plat in world_node.platforms:
				var lp := Vector2(_mx(plat.position.x), gy)
				draw_line(lp + Vector2(-9, -18), lp + Vector2(9, -18), Color("a97e54"), 4.0)
				draw_line(lp + Vector2(-6, -18), lp + Vector2(-6, 0), Color("a97e54"), 2.5)
				draw_line(lp + Vector2(6, -18), lp + Vector2(6, 0), Color("a97e54"), 2.5)
			for v in world_node.vines:
				var vp := Vector2(_mx(v.position.x), gy)
				draw_line(vp + Vector2(0, -34), vp + Vector2(0, -16), Color("6f9a5d"), 3.0)
				draw_circle(vp + Vector2(0, -16), 3.0, Color("8cc188"))
			# blocks
			for blk in world_node.blocks:
				var kp := Vector2(_mx(blk.position.x), gy)
				draw_rect(Rect2(kp + Vector2(-6, -10), Vector2(12, 10)), Color("c9a06c"))

		# Summer — you are here!
		if world_node and world_node.player:
			var sp := Vector2(_mx(world_node.player.position.x), gy - 4)
			var pulse := 8.0 + sin(t * 4.0) * 2.0
			draw_circle(sp, pulse + 5.0, Color(0.91, 0.57, 0.55, 0.25))
			draw_circle(sp, pulse, Color("e8918c"))
			draw_circle(sp + Vector2(0, -3), 4.0, Color("f0cd7e"))
			DrawKit.star(self, sp + Vector2(0, -24 - sin(t * 4.0) * 2.0), 7.0, Color("ffd98a"))
			# the dogs, if they've come to play
			if GameState.dogs_here:
				draw_circle(sp + Vector2(-16, 2), 4.0, Color("f3f0e8"))
				draw_circle(sp + Vector2(-24, 2), 4.0, Color("43404a"))
