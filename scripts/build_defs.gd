class_name BuildDefs
## Every part Summer can build, in one place. The build board reads this to
## lay out its spots; Treehouse reads it to decide what to draw; the
## museum reads it to decide which rooms exist. Adding a part means adding one
## entry here and one draw case in nature.gd — nothing else.
##
## Nothing here is ever mutually exclusive: `needs` only encodes what is
## physically impossible (a second storey without a first), never a choice.

const TRACKS := ["structure", "access", "extension", "comfort", "decoration"]

const TRACK_LABEL := {
	"structure": "house",
	"access": "climbing",
	"extension": "outside",
	"comfort": "inside",
	"decoration": "pretty",
}

## Built from the very first session — the bare platform she starts with.
const START_BUILT := ["platform", "ladder_rope", "shelves"]

## Which tree (or the ground) each spot belongs to. The board pans between
## them; the world draws them at different x positions.
##   home | two | three | ground
##
## `spot` is in the owning node's local coordinates — the same space
## Treehouse draws in, so a ghost preview can be drawn straight there.
const PARTS := {
	# --- structure: the spine ------------------------------------------------
	"platform": {
		"track": "structure", "word": "platform", "site": "home",
		"cost": {}, "needs": [], "spot": Vector2(0, -262), "tierable": true,
	},
	"cabin": {
		"track": "structure", "word": "cabin", "site": "home",
		"cost": {"plank": 4, "stick": 3}, "needs": ["platform"],
		"spot": Vector2(0, -306), "tierable": true, "unlocks": "museum",
	},
	"storey2": {
		"track": "structure", "word": "upstairs", "site": "home",
		"cost": {"plank": 6, "rope": 3}, "needs": ["cabin"],
		"spot": Vector2(0, -380), "tierable": true,
	},
	"tower": {
		"track": "structure", "word": "tower", "site": "home",
		"cost": {"timber": 4, "plank": 4}, "needs": ["storey2"],
		"spot": Vector2(0, -454), "tierable": true,
	},
	"mansion_roof": {
		"track": "structure", "word": "rooftop", "site": "home",
		"cost": {"timber": 6, "paint": 2}, "needs": ["tower"],
		"spot": Vector2(0, -516), "tierable": false,
	},

	# --- access: how she gets up --------------------------------------------
	"ladder_rope": {
		"track": "access", "word": "ladder", "site": "home",
		"cost": {}, "needs": [], "spot": Vector2(0, -150), "tierable": false,
	},
	"stairs_wood": {
		"track": "access", "word": "stairs", "site": "home",
		"cost": {"plank": 4}, "needs": ["platform"],
		"spot": Vector2(-52, -150), "tierable": true,
	},
	"stairs_spiral": {
		"track": "access", "word": "spiral", "site": "home",
		"cost": {"timber": 5}, "needs": ["stairs_wood"],
		"spot": Vector2(52, -150), "tierable": false,
	},
	"lift_bucket": {
		"track": "access", "word": "lift", "site": "home",
		"cost": {"rope": 4, "plank": 2}, "needs": ["cabin"],
		"spot": Vector2(-104, -200), "tierable": false,
	},
	"slide": {
		"track": "access", "word": "slide", "site": "home",
		"cost": {"timber": 3, "paint": 1}, "needs": ["deck_front"],
		"spot": Vector2(150, -140), "tierable": false,
	},

	# --- extension: outward --------------------------------------------------
	"deck_front": {
		"track": "extension", "word": "deck", "site": "home",
		"cost": {"plank": 3}, "needs": ["cabin"],
		"spot": Vector2(96, -262), "tierable": true,
	},
	"deck_side": {
		"track": "extension", "word": "side deck", "site": "home",
		"cost": {"plank": 3}, "needs": ["cabin"],
		"spot": Vector2(-100, -262), "tierable": true,
	},
	"balcony": {
		"track": "extension", "word": "balcony", "site": "home",
		"cost": {"plank": 5, "rope": 2}, "needs": ["deck_front", "deck_side"],
		"spot": Vector2(0, -240), "tierable": true,
	},
	"workshop": {
		"track": "extension", "word": "workshop", "site": "ground",
		"cost": {"timber": 4, "plank": 6}, "needs": ["cabin"],
		"spot": Vector2(-266, -60), "tierable": true, "unlocks": "workshop",
	},
	"bridge2": {
		"track": "extension", "word": "bridge", "site": "home",
		"cost": {"rope": 5, "plank": 4}, "needs": ["storey2"],
		"spot": Vector2(160, -300), "tierable": false,
	},
	"tree2_platform": {
		"track": "extension", "word": "platform", "site": "two",
		"cost": {"plank": 4, "stick": 3}, "needs": ["bridge2"],
		"spot": Vector2(0, -262), "tierable": true,
	},
	"tree2_cabin": {
		"track": "extension", "word": "cabin", "site": "two",
		"cost": {"plank": 5, "rope": 2}, "needs": ["tree2_platform"],
		"spot": Vector2(0, -310), "tierable": true,
	},
	"crows_nest": {
		"track": "extension", "word": "crows nest", "site": "two",
		"cost": {"timber": 3, "rope": 2}, "needs": ["tree2_cabin"],
		"spot": Vector2(0, -430), "tierable": false,
	},
	"zipline": {
		"track": "extension", "word": "zip line", "site": "two",
		"cost": {"rope": 6}, "needs": ["crows_nest"],
		"spot": Vector2(84, -400), "tierable": false,
	},
	"bridge3": {
		"track": "extension", "word": "long bridge", "site": "two",
		"cost": {"rope": 6, "plank": 5}, "needs": ["tree2_cabin"],
		"spot": Vector2(150, -300), "tierable": false,
	},
	"tree3_platform": {
		"track": "extension", "word": "platform", "site": "three",
		"cost": {"plank": 5, "timber": 2}, "needs": ["bridge3"],
		"spot": Vector2(0, -262), "tierable": true,
	},
	"tree3_tower": {
		"track": "extension", "word": "big tower", "site": "three",
		"cost": {"timber": 6, "plank": 4}, "needs": ["tree3_platform"],
		"spot": Vector2(0, -350), "tierable": true,
	},

	# --- comfort: interiors with a purpose -----------------------------------
	"shelves": {
		"track": "comfort", "word": "shelves", "site": "home",
		"cost": {}, "needs": [], "spot": Vector2(-40, -300), "tierable": false,
		"unlocks": "museum",
	},
	"den": {
		"track": "comfort", "word": "den", "site": "home",
		"cost": {"rope": 2, "plank": 2}, "needs": ["cabin"],
		"spot": Vector2(40, -300), "tierable": false, "unlocks": "den",
	},
	"kitchen": {
		"track": "comfort", "word": "kitchen", "site": "home",
		"cost": {"plank": 4, "timber": 2}, "needs": ["storey2"],
		"spot": Vector2(-40, -376), "tierable": false, "unlocks": "kitchen",
	},
	"art_room": {
		"track": "comfort", "word": "art room", "site": "home",
		"cost": {"plank": 3, "paint": 1}, "needs": ["tower"],
		"spot": Vector2(-40, -450), "tierable": false, "unlocks": "art_room",
	},
	"telescope": {
		"track": "comfort", "word": "telescope", "site": "home",
		"cost": {"timber": 2, "rope": 1}, "needs": ["tower"],
		"spot": Vector2(46, -470), "tierable": false,
	},

	# --- decoration: cheap, frequent, joyful ---------------------------------
	"name_sign": {
		"track": "decoration", "word": "my name", "site": "home",
		"cost": {"plank": 1}, "needs": ["cabin"], "spot": Vector2(0, -240),
	},
	"painted_door": {
		"track": "decoration", "word": "painted door", "site": "home",
		"cost": {"paint": 1}, "needs": [], "spot": Vector2(0, -46),
	},
	"bunting": {
		"track": "decoration", "word": "bunting", "site": "home",
		"cost": {"rope": 1}, "needs": ["cabin"], "spot": Vector2(-60, -330),
	},
	"flower_box": {
		"track": "decoration", "word": "flowers", "site": "home",
		"cost": {"plank": 1}, "needs": ["cabin"], "spot": Vector2(-46, -288),
	},
	"wind_chime": {
		"track": "decoration", "word": "chimes", "site": "home",
		"cost": {"stick": 1, "rope": 1}, "needs": ["cabin"], "spot": Vector2(62, -300),
	},
	"lantern": {
		"track": "decoration", "word": "lantern", "site": "home",
		"cost": {"stick": 1}, "needs": [], "spot": Vector2(-46, -96),
	},
	"weather_vane": {
		"track": "decoration", "word": "weather vane", "site": "home",
		"cost": {"stick": 1, "plank": 1}, "needs": ["cabin"], "spot": Vector2(-52, -350),
	},
	"letterbox": {
		"track": "decoration", "word": "letterbox", "site": "ground",
		"cost": {"plank": 1}, "needs": [], "spot": Vector2(96, -40),
	},
	"welcome_mat": {
		"track": "decoration", "word": "welcome", "site": "ground",
		"cost": {"rope": 1}, "needs": [], "spot": Vector2(0, 6),
	},
	"bird_box": {
		"track": "decoration", "word": "bird box", "site": "home",
		"cost": {"plank": 1, "stick": 1}, "needs": [], "spot": Vector2(-96, -330),
	},
	"hammock": {
		"track": "decoration", "word": "hammock", "site": "home",
		"cost": {"rope": 2}, "needs": ["deck_front"], "spot": Vector2(120, -286),
	},
	"tyre_swing": {
		"track": "decoration", "word": "swing", "site": "home",
		"cost": {"rope": 1, "stick": 1}, "needs": [], "spot": Vector2(112, -120),
	},
	"pet_bowls": {
		"track": "decoration", "word": "dog bowls", "site": "ground",
		"cost": {"plank": 1}, "needs": [], "spot": Vector2(-92, -8),
	},
	"plant_pots": {
		"track": "decoration", "word": "plant pots", "site": "ground",
		"cost": {"stick": 1}, "needs": [], "spot": Vector2(52, -10),
	},
	"flag": {
		"track": "decoration", "word": "flag", "site": "home",
		"cost": {"stick": 1, "rope": 1}, "needs": ["cabin"], "spot": Vector2(66, -360),
	},
	"chalkboard": {
		"track": "decoration", "word": "chalkboard", "site": "ground",
		"cost": {"plank": 1}, "needs": [], "spot": Vector2(-130, -60),
	},

	# --- tree two: the lookout tree -----------------------------------------
	# Tree two used to offer nothing but the five "outside" pieces, so panning
	# to it showed four empty tracks. It is now a whole little house of its own.
	"tree2_roof": {
		"track": "structure", "word": "roof", "site": "two",
		"cost": {"plank": 3, "stick": 2}, "needs": ["tree2_cabin"],
		"spot": Vector2(0, -348), "tierable": true,
	},
	"tree2_loft": {
		"track": "structure", "word": "loft", "site": "two",
		"cost": {"plank": 5, "rope": 2}, "needs": ["tree2_roof"],
		"spot": Vector2(0, -392), "tierable": true,
	},
	"tree2_net": {
		"track": "access", "word": "climbing net", "site": "two",
		"cost": {"rope": 4}, "needs": ["tree2_platform"],
		"spot": Vector2(-64, -150), "tierable": false,
	},
	"tree2_swing": {
		"track": "access", "word": "swing", "site": "two",
		"cost": {"rope": 2, "plank": 1}, "needs": ["tree2_platform"],
		"spot": Vector2(96, -180), "tierable": false,
	},
	"tree2_pole": {
		"track": "access", "word": "fire pole", "site": "two",
		"cost": {"timber": 2}, "needs": ["tree2_cabin"],
		"spot": Vector2(58, -150), "tierable": false,
	},
	"tree2_deck": {
		"track": "extension", "word": "deck", "site": "two",
		"cost": {"plank": 4}, "needs": ["tree2_platform"],
		"spot": Vector2(-88, -258), "tierable": true,
	},
	"tree2_bunk": {
		"track": "comfort", "word": "bunk beds", "site": "two",
		"cost": {"plank": 3, "rope": 1}, "needs": ["tree2_cabin"],
		"spot": Vector2(-30, -300), "tierable": false,
	},
	"tree2_hammock": {
		"track": "comfort", "word": "hammock", "site": "two",
		"cost": {"rope": 3}, "needs": ["tree2_platform"],
		"spot": Vector2(0, -226), "tierable": false,
	},
	"tree2_spyglass": {
		"track": "comfort", "word": "spyglass", "site": "two",
		"cost": {"timber": 1, "rope": 1}, "needs": ["crows_nest"],
		"spot": Vector2(34, -452), "tierable": false,
	},
	"tree2_flag": {
		"track": "decoration", "word": "flag", "site": "two",
		"cost": {"rope": 1}, "needs": ["tree2_cabin"], "spot": Vector2(-46, -376),
	},
	"tree2_lanterns": {
		"track": "decoration", "word": "lanterns", "site": "two",
		"cost": {"stick": 1}, "needs": ["tree2_platform"], "spot": Vector2(0, -272),
	},
	"tree2_bunting": {
		"track": "decoration", "word": "bunting", "site": "two",
		"cost": {"rope": 1}, "needs": ["tree2_cabin"], "spot": Vector2(-56, -330),
	},
	"tree2_windsock": {
		"track": "decoration", "word": "windsock", "site": "two",
		"cost": {"rope": 1, "paint": 1}, "needs": ["tree2_platform"],
		"spot": Vector2(74, -290),
	},

	# --- tree three: the tall one -------------------------------------------
	"tree3_top": {
		"track": "structure", "word": "top room", "site": "three",
		"cost": {"timber": 5, "plank": 4}, "needs": ["tree3_tower"],
		"spot": Vector2(0, -430), "tierable": true,
	},
	"tree3_spire": {
		"track": "structure", "word": "spire", "site": "three",
		"cost": {"timber": 4, "paint": 1}, "needs": ["tree3_top"],
		"spot": Vector2(0, -500), "tierable": false,
	},
	"tree3_stairs": {
		"track": "access", "word": "spiral stairs", "site": "three",
		"cost": {"timber": 4}, "needs": ["tree3_platform"],
		"spot": Vector2(0, -150), "tierable": true,
	},
	"tree3_rope": {
		"track": "access", "word": "knot rope", "site": "three",
		"cost": {"rope": 3}, "needs": ["tree3_platform"],
		"spot": Vector2(-70, -170), "tierable": false,
	},
	"tree3_zip": {
		"track": "access", "word": "zip home", "site": "three",
		"cost": {"rope": 6}, "needs": ["tree3_tower"],
		"spot": Vector2(-96, -380), "tierable": false,
	},
	"tree3_deck": {
		"track": "extension", "word": "deck", "site": "three",
		"cost": {"plank": 5}, "needs": ["tree3_platform"],
		"spot": Vector2(92, -258), "tierable": true,
	},
	"tree3_netbridge": {
		"track": "extension", "word": "rope walk", "site": "three",
		"cost": {"rope": 5, "plank": 2}, "needs": ["tree3_tower"],
		"spot": Vector2(-100, -300), "tierable": false,
	},
	"tree3_telescope": {
		"track": "comfort", "word": "big telescope", "site": "three",
		"cost": {"timber": 3, "rope": 1}, "needs": ["tree3_tower"],
		"spot": Vector2(40, -450), "tierable": false,
	},
	"tree3_beds": {
		"track": "comfort", "word": "camp beds", "site": "three",
		"cost": {"plank": 3, "rope": 2}, "needs": ["tree3_tower"],
		"spot": Vector2(-32, -300), "tierable": false,
	},
	"tree3_lookout": {
		"track": "comfort", "word": "map table", "site": "three",
		"cost": {"plank": 2, "paint": 1}, "needs": ["tree3_top"],
		"spot": Vector2(-34, -390), "tierable": false,
	},
	"tree3_flag": {
		"track": "decoration", "word": "flag", "site": "three",
		"cost": {"rope": 1}, "needs": ["tree3_tower"], "spot": Vector2(-44, -444),
	},
	"tree3_lights": {
		"track": "decoration", "word": "lights", "site": "three",
		"cost": {"rope": 1, "paint": 1}, "needs": ["tree3_platform"],
		"spot": Vector2(0, -272),
	},
	"tree3_vane": {
		"track": "decoration", "word": "weather vane", "site": "three",
		"cost": {"stick": 1, "plank": 1}, "needs": ["tree3_top"],
		"spot": Vector2(46, -466),
	},
}

## What it costs to raise a part to the next material tier. Tier 1 is sticks
## and twine, 2 is planks (where most parts start), 3 is good timber from the
## market, 4 is painted in a colour she picks.
const TIER_COST := {
	3: {"timber": 2},
	4: {"paint": 1},
}

const TIER_NAME := ["", "sticks", "planks", "timber", "painted"]
const MAX_TIER := 4

## Materials, in the order they read across the top bar.
const MATERIALS := ["stick", "plank", "rope", "timber", "paint", "seed"]


static func cost_of(id: String) -> Dictionary:
	return PARTS.get(id, {}).get("cost", {})


static func needs_of(id: String) -> Array:
	return PARTS.get(id, {}).get("needs", [])


static func site_of(id: String) -> String:
	return PARTS.get(id, {}).get("site", "home")


static func spot_of(id: String) -> Vector2:
	return PARTS.get(id, {}).get("spot", Vector2.ZERO)


static func word_of(id: String) -> String:
	return PARTS.get(id, {}).get("word", id)


static func track_of(id: String) -> String:
	return PARTS.get(id, {}).get("track", "decoration")


static func is_tierable(id: String) -> bool:
	return bool(PARTS.get(id, {}).get("tierable", false))


## Every part on a track, in declaration order.
static func ids_on_track(track: String) -> Array:
	var out: Array = []
	for id in PARTS:
		if PARTS[id]["track"] == track:
			out.append(id)
	return out
