class_name Folk
## The people Summer meets: kids in the meadow, traders at the market,
## adventurers in Dino Land, pirates at the cove. One roster, one figure, one
## way of talking to them — so a new world only has to say who lives there.
##
## Everyone is friendly, nobody ever wants anything from her, and no
## conversation can go wrong. Tapping a person opens the same card the animals
## use, but where an animal gets a camera button a person gets a TALK button:
## ask, and they tell her something true and worth knowing.
##
## READING: every line is lowercase and phonics-friendly. Each fact is written
## twice — a short version for the picture/word levels, a longer one for the
## sentence level — so the reading setting changes how much she reads, never
## whether she can talk to someone.

## role: "kid" | "trader" | "adventurer" | "pirate" — what they wear.
## Every `tells` entry is [short, long]: the same fact, said two ways.
const PEOPLE := {
	# --- the meadow: children from the village ------------------------------
	"pip": {
		"name": "pip", "role": "kid", "hat": "cap", "top": "e8918c",
		"hello": "i am pip. i live by the big oak.",
		"tells": [
			["a bee has five eyes.", "a bee has five eyes — two big ones and three small ones on top."],
			["snails carry their homes.", "a snail carries its home on its back, so it is never lost."],
			["frogs drink with their skin.", "a frog does not need to sip. it drinks water through its skin."],
		],
	},
	"nell": {
		"name": "nell", "role": "kid", "hat": "bunches", "top": "8fc48a",
		"hello": "i am nell. i am good at climbing.",
		"tells": [
			["oak trees grow from acorns.", "every big oak tree started as one little acorn on the ground."],
			["owls can turn their heads far.", "an owl can turn its head almost all the way round to look behind it."],
			["moss shows you the damp side.", "moss likes the damp side of a tree, so it can help you tell which way is which."],
		],
	},
	"gus": {
		"name": "gus", "role": "kid", "hat": "beanie", "top": "6fb3d2",
		"hello": "i am gus. i like to dig for things.",
		"tells": [
			["old things sink down slowly.", "the ground gets thicker each year, so old things end up deep down."],
			["flint can make a spark.", "flint is a hard stone. hit it right and it makes a spark."],
			["worms help the soil.", "worms make little tunnels, and that lets air and rain get down to the roots."],
		],
	},

	# --- the market: the people who keep the stalls -------------------------
	"rosa": {
		"name": "rosa", "role": "trader", "hat": "scarf", "top": "c96b64",
		"hello": "i am rosa. i sell good wood.",
		"tells": [
			["wood floats because it is light.", "wood floats because it is lighter than the water it sits in."],
			["you can count a tree's rings.", "cut wood shows rings. count them and you know how old the tree was."],
			["oak is the strongest here.", "oak is slow to grow and very strong, so it makes the best beams."],
		],
	},
	"sam": {
		"name": "sam", "role": "trader", "hat": "cap", "top": "6fb3d2",
		"hello": "i am sam. i mix all the paint.",
		"tells": [
			["red and blue make purple.", "mix red paint with blue paint and you get purple every time."],
			["old paint came from rocks.", "long ago people ground up soft rocks to make their paint."],
			["yellow and blue make green.", "mix yellow with blue and you get green — try it on your sketch pad."],
		],
	},
	"tess": {
		"name": "tess", "role": "trader", "hat": "bun", "top": "8fc48a",
		"hello": "i am tess. i have seeds for you.",
		"tells": [
			["seeds sleep until it rains.", "a seed waits in the ground and only wakes up when it gets warm and wet."],
			["dandelions fly on the wind.", "a dandelion seed has its own little parachute to catch the wind."],
			["bees help the seeds happen.", "bees carry pollen from flower to flower, and that is how seeds get made."],
		],
	},

	# --- dino land: the fossil hunters --------------------------------------
	"finn": {
		"name": "finn", "role": "adventurer", "hat": "sunhat", "top": "cfc192",
		"hello": "i am finn. i hunt for old bones.",
		"tells": [
			["bones can turn to stone.", "if a bone sits in the ground long enough, it slowly turns into stone."],
			["some dinosaurs ate only plants.", "the ones with long necks ate leaves. their teeth were flat, not sharp."],
			["we brush, we never bash.", "we clean a fossil with a soft brush. a hammer would snap it."],
		],
	},
	"ivy": {
		"name": "ivy", "role": "adventurer", "hat": "cap", "top": "e8b06a",
		"hello": "i am ivy. i draw all the finds.",
		"tells": [
			["birds came from dinosaurs.", "birds are the only dinosaurs left. look at a robin's feet and you can see it."],
			["a big one could be as long as six cars.", "the longest dinosaurs were as long as six cars parked in a row."],
			["footprints tell us how they walked.", "a track of footprints tells us if a dinosaur walked or ran, and how big it was."],
		],
	},

	# --- the cove: the pirates ----------------------------------------------
	"ben": {
		"name": "ben", "role": "pirate", "hat": "bandana", "top": "c96b64",
		"hello": "i am ben. i keep the ship tidy.",
		"tells": [
			["ships need the wind behind them.", "a sail catches the wind, and the wind is what pushes the ship along."],
			["knots keep the sails up.", "a good knot holds fast in a storm but still comes undone when you want it to."],
			["the sea goes up and down each day.", "the sea comes in and goes out twice a day. that is the tide."],
		],
	},
	"peg": {
		"name": "peg", "role": "pirate", "hat": "tricorn", "top": "6fb3d2",
		"hello": "i am peg. i read all the maps.",
		"tells": [
			["x marks the spot.", "on an old map, a cross shows where something is buried. dig there."],
			["stars can show you the way.", "sailors found their way at night by looking up at the stars."],
			["a shell can sound like the sea.", "hold a big shell to your ear and you can hear a sound just like the sea."],
		],
	},
	"hal": {
		"name": "hal", "role": "pirate", "hat": "bandana", "top": "8fc48a",
		"hello": "i am hal. i look out from the top.",
		"tells": [
			["gulls mean land is near.", "if you see gulls from a ship, then land is not far away."],
			["a lighthouse keeps ships safe.", "a lighthouse shines all night so ships know where the rocks are."],
			["crabs walk sideways.", "a crab's legs bend out to the sides, so sideways is the easy way to go."],
		],
	},
}


## Everyone who belongs in one world.
static func who_lives_in(where: String) -> Array:
	match where:
		"meadow": return ["pip", "nell", "gus"]
		"market": return ["rosa", "sam", "tess"]
		"dino": return ["finn", "ivy"]
		"cove": return ["ben", "peg", "hal"]
	return []


## What she says to open, worded for how much she is reading.
static func greeting(id: String) -> String:
	var name := str(PEOPLE[id]["name"])
	if GameState.reading_level >= 2:
		return "hello %s, how are you today?" % name
	return "hello %s!" % name


## Their reply — the introduction the first time, a plain hello after that.
static func reply(id: String) -> String:
	if GameState.met_folk.has(id):
		return "hello again!"
	GameState.met_folk.append(id)
	GameState.save_game()
	return str(PEOPLE[id]["hello"])


## Something worth knowing, at her reading level.
static func something_to_tell(id: String) -> String:
	var tells: Array = PEOPLE[id]["tells"]
	var pair: Array = tells[randi() % tells.size()]
	return str(pair[1] if GameState.reading_level >= 2 else pair[0])


## One person, walking their little patch of the world. Tapping opens a chat.
## They amble between `home_x ± roam` and stop to face Summer while she talks.
class Person extends Node2D:
	var id := "pip"
	var home_x := 0.0
	var roam := 120.0
	var speed := 30.0
	var t := 0.0
	var _dir := 1.0
	var _pause := 0.0
	var _talking := false
	var _wave := 0.0

	func _ready() -> void:
		t = randf() * 6.0
		_dir = 1.0 if randf() < 0.5 else -1.0
		_pause = randf() * 2.0

	func spec() -> Dictionary:
		return Folk.PEOPLE.get(id, Folk.PEOPLE["pip"])

	func tap_score(wp: Vector2) -> float:
		# A person NEVER claims a tap that landed on something she jumps. They
		# wander, so sooner or later one stands on a crate, and then aiming at
		# the crate starts a conversation instead. The log or crate wins there,
		# always — she can talk to them a step to either side.
		var z := get_parent()
		if z != null and "blocks" in z:
			for b in z.blocks:
				if is_instance_valid(b) \
						and absf(wp.x - b.position.x) < b.w * 0.5 + 10.0 \
						and wp.y > b.position.y - b.h - 30.0:
					return 0.0
		# 72, not 92: they are small figures, and a generous hitbox was grabby
		return clampf(1.0 - (wp - global_position - Vector2(0, -46)).length() / 72.0, 0.0, 1.0)

	func try_tap(_wp: Vector2) -> bool:
		return true

	## Stand still and face her while they are talking.
	func attend(toward_x: float) -> void:
		_talking = true
		_dir = signf(toward_x - global_position.x)
		if _dir == 0.0:
			_dir = 1.0
		_wave = 1.0
		get_tree().create_timer(6.0).timeout.connect(func() -> void:
			if is_instance_valid(self):
				_talking = false)

	func _process(delta: float) -> void:
		t += delta
		if _wave > 0.0:
			_wave = maxf(0.0, _wave - delta * 0.7)
		if not _talking:
			if _pause > 0.0:
				_pause -= delta
			else:
				position.x += _dir * speed * delta
				if position.x < home_x - roam:
					position.x = home_x - roam
					_dir = 1.0
					_pause = randf_range(0.6, 2.4)
				elif position.x > home_x + roam:
					position.x = home_x + roam
					_dir = -1.0
					_pause = randf_range(0.6, 2.4)
		queue_redraw()

	func walking() -> bool:
		return not _talking and _pause <= 0.0

	func _draw() -> void:
		var s: Dictionary = spec()
		var fx := _dir
		var step := sin(t * 7.0) if walking() else 0.0
		var bob := absf(step) * 2.0
		var top := Color(str(s.get("top", "e8918c")))
		var skin := Color("f2c9a5")
		var trouser := Color("7a8b6a")

		DrawKit.soft_shadow(self, Vector2(0, 2), 26.0, 0.16)
		# legs
		for spec_l in [[-1.0, 0.06], [1.0, -0.06]]:
			var side: float = spec_l[0]
			var sw: float = step * 9.0 * side
			draw_line(Vector2(side * 6.0, -34 + bob), Vector2(side * 6.0 + sw, -2),
				trouser, 7.0)
			draw_line(Vector2(side * 6.0 + sw, -2), Vector2(side * 6.0 + sw + fx * 4.0, -1),
				Color("6b5a4a"), 6.0)
		# body
		DrawKit.rounded_rect(self, Rect2(-13, -62 + bob, 26, 30), 9.0, top.darkened(0.25))
		DrawKit.rounded_rect(self, Rect2(-11.5, -61 + bob, 23, 28), 8.0, top)
		if str(s.get("role", "kid")) == "pirate":
			# a striped pirate top
			for i in 3:
				draw_rect(Rect2(-11.5, -56 + bob + i * 8.0, 23, 4.0), Color("fff8ec"))
		elif str(s.get("role", "kid")) == "trader":
			# an apron
			DrawKit.rounded_rect(self, Rect2(-9, -50 + bob, 18, 18), 4.0, Color("efe3c8"))
		elif str(s.get("role", "kid")) == "adventurer":
			# a strap across, and a pack on the back
			DrawKit.rounded_rect(self, Rect2(-15 * fx - 5, -58 + bob, 10, 22), 4.0,
				Color("8fb7d9"))
			draw_line(Vector2(-6 * fx, -58 + bob), Vector2(6 * fx, -40 + bob),
				Color("a97e54"), 4.0)
		# arms — the near one waves for a moment when she comes to talk
		var swing := step * 8.0
		draw_line(Vector2(-8 * fx, -56 + bob), Vector2(-11 * fx - swing, -40 + bob),
			skin.darkened(0.1), 6.0)
		if _wave > 0.3:
			var w := sin(t * 12.0) * 0.5
			draw_line(Vector2(8 * fx, -56 + bob),
				Vector2(16 * fx, -66 + bob + w * 5.0), skin, 6.0)
			draw_circle(Vector2(17 * fx, -68 + bob + w * 5.0), 4.0, skin)
		else:
			draw_line(Vector2(8 * fx, -56 + bob), Vector2(11 * fx + swing, -40 + bob),
				skin, 6.0)
			draw_circle(Vector2(11 * fx + swing, -39 + bob), 3.6, skin)
		# head
		var hc := Vector2(fx * 1.5, -74 + bob)
		draw_circle(hc, 13.0, skin.darkened(0.3))
		draw_circle(hc, 11.8, skin)
		_hat(hc, fx, str(s.get("hat", "cap")), top)
		# face: two dots and a smile, always
		draw_circle(hc + Vector2(fx * 3.0, -1.0), 1.9, Color("5a4a3a"))
		draw_circle(hc + Vector2(fx * 8.0, -1.0), 1.9, Color("5a4a3a"))
		draw_arc(hc + Vector2(fx * 5.5, 3.0), 3.2, 0.35, PI - 0.35, 8,
			Color("b56a5f"), 1.8, true)
		draw_circle(hc + Vector2(-fx * 2.0, 3.5), 2.2, Color(0.95, 0.6, 0.6, 0.28))

	func _hat(hc: Vector2, fx: float, kind: String, top: Color) -> void:
		match kind:
			"cap":
				draw_circle(hc + Vector2(0, -6), 11.0, top.darkened(0.35))
				DrawKit.ellipse(self, hc + Vector2(fx * 9.0, -5.0), 8.0, 3.0,
					top.darkened(0.45))
			"beanie":
				draw_circle(hc + Vector2(0, -6), 11.2, Color("c4a0d8"))
				draw_rect(Rect2(hc.x - 11.5, hc.y - 6.0, 23, 5.0), Color("b28cc8"))
				draw_circle(hc + Vector2(0, -17), 4.0, Color("efe3f5"))
			"bunches":
				draw_circle(hc + Vector2(0, -6), 11.0, Color("f0cd7e"))
				for side in [-1.0, 1.0]:
					draw_circle(hc + Vector2(side * 13.0, -2.0), 6.2, Color("f0cd7e"))
					draw_circle(hc + Vector2(side * 13.0, -8.0), 2.6, Color("e8918c"))
			"bun":
				draw_circle(hc + Vector2(0, -6), 11.0, Color("8a6a52"))
				draw_circle(hc + Vector2(-fx * 10.0, -11.0), 6.0, Color("8a6a52"))
			"scarf":
				draw_circle(hc + Vector2(0, -6), 11.2, Color("d98ca8"))
				draw_arc(hc, 11.5, PI + 0.2, TAU - 0.2, 12, Color("c97a96"), 4.0, true)
				draw_line(hc + Vector2(-fx * 10.0, -2.0), hc + Vector2(-fx * 16.0, 8.0),
					Color("d98ca8"), 4.0)
			"sunhat":
				DrawKit.ellipse(self, hc + Vector2(0, -6.0), 19.0, 5.5, Color("d9c9a0").darkened(0.3))
				DrawKit.ellipse(self, hc + Vector2(0, -7.0), 18.0, 5.0, Color("d9c9a0"))
				draw_circle(hc + Vector2(0, -12.0), 8.5, Color("d9c9a0"))
				draw_line(hc + Vector2(-8, -11), hc + Vector2(8, -11), Color("a97e54"), 2.5)
			"bandana":
				draw_circle(hc + Vector2(0, -6), 11.0, Color("c9524a"))
				draw_rect(Rect2(hc.x - 11.5, hc.y - 8.0, 23, 6.0), Color("b8483f"))
				for i in 3:
					draw_circle(hc + Vector2(-8.0 + i * 8.0, -5.0), 1.6, Color("fff0f0"))
				draw_line(hc + Vector2(-fx * 10.0, -4.0), hc + Vector2(-fx * 18.0, 4.0),
					Color("c9524a"), 4.0)
			"tricorn":
				draw_circle(hc + Vector2(0, -8), 9.5, Color("4a4038"))
				DrawKit.ellipse(self, hc + Vector2(0, -8.0), 20.0, 6.0, Color("4a4038"))
				draw_polygon(PackedVector2Array([
					hc + Vector2(-20, -8), hc + Vector2(0, -20), hc + Vector2(20, -8),
				]), PackedColorArray([Color("3d352e")]))
				draw_circle(hc + Vector2(fx * 7.0, -14.0), 3.2, Color("e8c168"))
			_:
				draw_circle(hc + Vector2(0, -6), 11.0, Color("8a6a52"))
