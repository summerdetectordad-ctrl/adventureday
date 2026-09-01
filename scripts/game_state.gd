extends Node
## Autoload: all persistent state. Saves to a local JSON file on every change —
## the game is always safe to put down. Nothing here ever removes a shelf item.

const SAVE_PATH := "user://adventure_day_save.json"

## Find types and their spawn weights. Fossils and dinosaurs are weighted
## heaviest — they're the current obsession.
const FIND_TYPES := {
	"ammonite": 4,
	"dino_bone": 4,
	"dino_egg": 3,
	"trilobite": 3,
	"shark_tooth": 3,
	"roman_coin": 2,
	"pirate_coin": 2,
	"gem": 1,
	"old_key": 1,
}

## The word for each find, lowercase and Year 1 friendly. Lives here because
## both the museum shelf and the basket view show it.
const FIND_WORDS := {
	"ammonite": "ammonite",
	"trilobite": "trilobite",
	"dino_bone": "bone",
	"dino_egg": "egg",
	"shark_tooth": "tooth",
	"roman_coin": "coin",
	"pirate_coin": "coin",
	"gem": "gem",
	"old_key": "key",
	"drawing": "art",
	"photo": "snap",
}

## Old saves stored one integer, 1..5. Each level implied a set of parts; this
## maps them forward so nobody loses a treehouse they already built.
const LEVEL_MIGRATION := {
	2: ["cabin", "deck_front"],
	3: ["storey2", "deck_side", "flower_box"],
	4: ["tower", "telescope", "flag"],
	5: ["mansion_roof", "bunting", "lantern", "bird_box"],
}

var satchel: Array = []      # find kinds being carried, oldest first
var shelf: Dictionary = {}   # slot index (int) -> find kind
var muted := false
var materials: Dictionary = {"stick": 0, "plank": 0, "rope": 0, "timber": 0, "paint": 0, "seed": 0}
var fruit := 0               # berries picked, the market's currency

## The treehouse, as a set of parts rather than a level. See BuildDefs.
var built: Array = []                # part ids, in the order she built them
var tiers: Dictionary = {}           # part id -> 1..4 material tier
var paint_colours: Dictionary = {}   # part id -> colour hex she chose

## Meters. Both count seconds since the last drink/snack. They never punish —
## an empty meter only ever puts a friendly bubble over her head.
var thirst_accum := 0.0
var hunger_accum := 0.0

## The garden patch below the trees. Seeds from the market go in here and grow
## while she plays; a grown patch can be picked for fruit. Nothing ever dies or
## needs watering on a schedule — it only ever moves forwards.
var garden_seeds := 0
var garden_growth := 0.0   # 0..1

## Pieces of the pirate map she has dug up, 0..4. At 4 the chest appears.
var map_pieces := 0

## How much reading the mini-games use. Parent-set, three steps, and it only
## ever changes how the GAMES are worded — never what she can reach or do.
##   0 = pictures  (Reception)   no words at all
##   1 = words     (Year 1)      simple words and numbers to 10
##   2 = sentences (Year 2)      longer words, digraphs, numbers to 20
## No age gate and no sign-up: an age gate implies a wrong answer, in a game
## whose whole premise is that there is not one.
var reading_level := 1

## Which tree the plan board was last left on, so building a run of parts on
## tree two does not throw her back to the home tree after every single one.
var last_build_site := "home"

## Worked out at startup from the physical screen — see _fit_to_screen.
var ui_scale := 1.0
var screen_inches := 0.0

## The people she has already said hello to, by id. A first meeting gets the
## introduction; after that they just chat.
var met_folk: Array = []

## The T-rex in the cave. `trex_met` is whether she has solved the mystery the
## first time; `trex_helped_t` is when the last splinter came out (a new one
## turns up ten minutes later); `trex_spot` is where the next one will be.
var trex_met := false
var trex_helped_t := 0.0
var trex_spot := ""

# Session-only flags (not saved).
var start_card_shown := false
var spawn_at_door := false
## Which world she has just walked in from — "market", "dino", "cove", "home",
## or "bike" when she rode. Each world reads it to put her at the right end
## instead of dumping her back at its default start position.
var arrive_from := ""
var berries_picked := 0   # gentle counting practice, wraps at 20
var held_tool := ""       # "", "detector" or "net" — what's out of the backpack
var dogs_here := false    # Indy and Star only arrive when the whistle calls them
var sketch_strokes: Array = []   # the sketch pad's page: stroke/fill/clear ops
var sketch_redo: Array = []      # undone ops waiting for redo
var sandwich_stack: Array = []   # the picnic sandwich in progress
var pie_stack: Array = []        # the fruit pie in progress


func _ready() -> void:
	randomize()
	load_game()
	_fit_to_screen()


## The game was laid out for a tablet. On a phone the same drawing lands on a
## much smaller piece of glass, so the buttons come out under the ~9 mm that a
## finger actually needs and everything reads as tiny. Scaling the whole canvas
## up fixes it in one place: she sees a little less of the world at once, and
## every control grows to match. Tablets are left alone.
func _fit_to_screen() -> void:
	var dpi := DisplayServer.screen_get_dpi()
	var px := DisplayServer.screen_get_size()
	if dpi <= 0 or px.x <= 0 or px.y <= 0:
		return
	var inches := sqrt(float(px.x * px.x + px.y * px.y)) / float(dpi)
	var f := 1.0
	if inches < 6.0:
		f = 1.5
	elif inches < 7.6:
		f = 1.32
	elif inches < 9.5:
		f = 1.14
	screen_inches = inches
	ui_scale = f
	if f != 1.0 and get_window() != null:
		get_window().content_scale_factor = f


func random_find_type() -> String:
	var total := 0
	for w in FIND_TYPES.values():
		total += w
	var r := randi() % total
	for kind in FIND_TYPES:
		r -= FIND_TYPES[kind]
		if r < 0:
			return kind
	return "ammonite"


func add_to_satchel(kind: String) -> void:
	satchel.append(kind)
	save_game()


func take_from_satchel(index: int) -> void:
	if index >= 0 and index < satchel.size():
		satchel.remove_at(index)
		save_game()


func place_on_shelf(slot: int, kind: String) -> void:
	shelf[slot] = kind
	save_game()


## Take a find off the shelf and put it back in the basket. NOTHING IS LOST —
## it moves from one place she owns to another, and can go straight back up.
## This is how she curates the museum when the shelves fill up.
func take_off_shelf(slot: int) -> void:
	if not shelf.has(slot):
		return
	var kind: String = shelf[slot]
	shelf.erase(slot)
	satchel.append(kind)
	save_game()


func move_on_shelf(from_slot: int, to_slot: int) -> void:
	if not shelf.has(from_slot):
		return
	var kind: String = shelf[from_slot]
	shelf.erase(from_slot)
	shelf[to_slot] = kind
	save_game()


func add_material(kind: String, n := 1) -> void:
	materials[kind] = int(materials.get(kind, 0)) + n
	save_game()


func add_fruit(n := 1) -> void:
	fruit = maxi(0, fruit + n)
	save_game()


func can_afford(cost: Dictionary) -> bool:
	for k in cost:
		if int(materials.get(k, 0)) < int(cost[k]):
			return false
	return true


func spend(cost: Dictionary) -> void:
	for k in cost:
		materials[k] = maxi(0, int(materials.get(k, 0)) - int(cost[k]))


## --- the treehouse ---------------------------------------------------------

func has_built(id: String) -> bool:
	return built.has(id)


## True when every part this one physically sits on already exists. Nothing is
## ever locked by choice — only by what it would have to stand on.
func can_start(id: String) -> bool:
	if built.has(id):
		return false
	for need in BuildDefs.needs_of(id):
		if not built.has(need):
			return false
	return true


## Everything she could start right now, whether or not she can pay for it —
## the board shows unaffordable ones too, because seeing what's coming is
## half the fun.
func available_builds() -> Array:
	var out: Array = []
	for id in BuildDefs.PARTS:
		if can_start(id):
			out.append(id)
	return out


## Build a part. Only ever called when can_afford — building cannot fail.
func build_part(id: String) -> void:
	if built.has(id):
		return
	spend(BuildDefs.cost_of(id))
	built.append(id)
	if BuildDefs.is_tierable(id) and not tiers.has(id):
		tiers[id] = 2
	save_game()


func tier_of(id: String) -> int:
	return int(tiers.get(id, 2 if BuildDefs.is_tierable(id) else 1))


func can_upgrade(id: String) -> bool:
	return built.has(id) and BuildDefs.is_tierable(id) and tier_of(id) < BuildDefs.MAX_TIER


func upgrade_cost(id: String) -> Dictionary:
	if not can_upgrade(id):
		return {}
	return BuildDefs.TIER_COST.get(tier_of(id) + 1, {})


func upgrade_part(id: String, colour := "") -> void:
	if not can_upgrade(id):
		return
	spend(upgrade_cost(id))
	tiers[id] = tier_of(id) + 1
	if colour != "":
		paint_colours[id] = colour
	save_game()


## Has she unlocked a named room? Rooms come from parts that declare "unlocks".
func has_room(room: String) -> bool:
	for id in built:
		if BuildDefs.PARTS.get(id, {}).get("unlocks", "") == room:
			return true
	return false


func toggle_mute() -> void:
	muted = not muted
	Sound.set_muted(muted)
	save_game()


## --- save / load -----------------------------------------------------------

func save_game() -> void:
	var shelf_out := {}
	for slot in shelf:
		shelf_out[str(slot)] = shelf[slot]
	var data := {
		"satchel": satchel, "shelf": shelf_out, "muted": muted,
		"materials": materials, "fruit": fruit,
		"built": built, "tiers": tiers, "paint": paint_colours,
		"thirst": thirst_accum, "hunger": hunger_accum,
		"garden_seeds": garden_seeds, "garden_growth": garden_growth,
		"map_pieces": map_pieces, "reading_level": reading_level,
		"last_build_site": last_build_site, "met": met_folk,
		"trex_met": trex_met, "trex_helped_t": trex_helped_t, "trex_spot": trex_spot,
		"save_version": 2,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func load_game() -> void:
	_ensure_start_built()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	satchel = data.get("satchel", [])
	muted = bool(data.get("muted", false))
	fruit = maxi(0, int(data.get("fruit", 0)))
	thirst_accum = maxf(0.0, float(data.get("thirst", 0.0)))
	hunger_accum = maxf(0.0, float(data.get("hunger", 0.0)))
	garden_seeds = maxi(0, int(data.get("garden_seeds", 0)))
	garden_growth = clampf(float(data.get("garden_growth", 0.0)), 0.0, 1.0)
	map_pieces = clampi(int(data.get("map_pieces", 0)), 0, 4)
	reading_level = clampi(int(data.get("reading_level", 1)), 0, 2)
	last_build_site = str(data.get("last_build_site", "home"))
	met_folk = data.get("met", [])
	trex_met = bool(data.get("trex_met", false))
	trex_helped_t = float(data.get("trex_helped_t", 0.0))
	trex_spot = str(data.get("trex_spot", ""))

	var mats: Dictionary = data.get("materials", {})
	for k in BuildDefs.MATERIALS:
		materials[k] = maxi(0, int(mats.get(k, 0)))

	shelf = {}
	var shelf_in: Dictionary = data.get("shelf", {})
	for key in shelf_in:
		shelf[int(key)] = shelf_in[key]

	if data.has("built"):
		# Version 2 save: parts as they were stored.
		built = []
		for id in data.get("built", []):
			if BuildDefs.PARTS.has(id) and not built.has(id):
				built.append(id)
		tiers = {}
		var tin: Dictionary = data.get("tiers", {})
		for id in tin:
			if BuildDefs.PARTS.has(id):
				tiers[id] = clampi(int(tin[id]), 1, BuildDefs.MAX_TIER)
		paint_colours = {}
		var pin: Dictionary = data.get("paint", {})
		for id in pin:
			paint_colours[id] = str(pin[id])
	else:
		# Version 1 save: one integer. Grant everything that level implied, so
		# nobody opens the game to find their treehouse taken away.
		_migrate_from_level(clampi(int(data.get("treehouse_level", 1)), 1, 5))

	_ensure_start_built()


func _ensure_start_built() -> void:
	for id in BuildDefs.START_BUILT:
		if not built.has(id):
			built.append(id)
		if BuildDefs.is_tierable(id) and not tiers.has(id):
			tiers[id] = 2


func _migrate_from_level(level: int) -> void:
	built = []
	_ensure_start_built()
	for lvl in range(2, level + 1):
		for id in LEVEL_MIGRATION.get(lvl, []):
			if not built.has(id):
				built.append(id)
				if BuildDefs.is_tierable(id):
					tiers[id] = 2
	save_game()


func _notification(what: int) -> void:
	# Save whenever the app is backgrounded or closed (tablet home button, etc.)
	if what == NOTIFICATION_APPLICATION_PAUSED \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT \
			or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


## Put a find back where it came from. The ONLY way anything leaves her
## collection, and it is deliberately not called "throw away": the meadow keeps
## making more, so what goes back is never really gone, and she needs some way
## to make room once the basket is full. Two taps behind a named button, so it
## can never happen by accident.
func put_back(index: int) -> void:
	if index < 0 or index >= satchel.size():
		return
	satchel.remove_at(index)
	save_game()
