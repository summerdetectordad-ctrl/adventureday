# AGENTS.md — Adventure Day

Machine-oriented project reference. Read this before changing anything.

## What this is

Calm 2D metal-detecting/collecting game for Summer (turns 6 in Oct 2026; UK Year 1, finished Reception well — reads simple lowercase words, recognises numbers to ~20). Godot 4.x, GDScript, standard build (NOT .NET). Ships as sideloaded Android APK, landscape tablet. Desktop keyboard supported for dev only.

Based on real weekly "Adventure Days" (photo folders at `C:\Users\PeterWard\Desktop\Adventure Days - Complete` — inspiration only, alignment to the book is secondary to playability).

## Invariants — never violate

- No ads, IAP, accounts, analytics, networking. Android export must NOT request the Internet permission.
- No fail state: nothing chases, nothing runs out, no timers, no lives, no score pressure.
- No reading REQUIRED to play. Text exists only as optional flavour (affirmation cards, word tags) that auto-dismisses and gates nothing.
- Soft palette, no flashing, no sudden/loud audio. All audio soft sine-based. Mute button must always work and persist.
- Big touch targets (≥ ~80 px), forgiving hit radii.
- Safe to quit at any instant: save on every state change + on APPLICATION_PAUSED/FOCUS_OUT/WM_CLOSE (game_state.gd).
- NOTHING COLLECTED IS EVER DESTROYED. There is no bin. A find moves freely between the basket and the shelf (drag up to display, drag back DOWN into the basket to take it off) — both are hers. The basket holds any number, TRAY_PER_PAGE at a time with page arrows. Shelf rooms grow as she builds (storey2, tower, tree2_cabin, tree3_tower → up to 5 rooms, 140 spots).
- Art is code-drawn (DrawKit) plus procedural shaders (paint.gd — shader code strings + a runtime-generated NoiseTexture2D), audio procedural (sound.gd). Binary assets are PERMITTED if they genuinely help (user relaxed the old zero-binary rule, 2026-08-30) — but never ship anything with unclear licensing. Non-text files so far: icon.svg, and `photos/` — the real photographs the camera produces (see `Photos` below and photos/CREDITS.md). Everything else stays code-drawn.
- Education elements are optional garnish only; playability overrides everything. `GameState.reading_level` (0 pictures / 1 words / 2 sentences, parent-set from the HUD button beside mute) only ever changes how WORDY a mini-game is — never what she can reach, do or finish. No age gate and no sign-up: an age gate implies a wrong answer. Target band is Reception to Year 2 (ages 4-7).

## Architecture

Autoloads (order matters; declared in project.godot):
1. `GameState` (scripts/game_state.gd) — all persistence; JSON at `user://adventure_day_save.json`, SAVE VERSION 2. Format: `{"satchel": ["kind"...], "shelf": {"slotIndex": "kind"}, "muted": bool, "materials": {"stick"/"plank"/"rope"/"timber"/"paint"/"seed": n}, "fruit": n, "built": ["partId"...], "tiers": {"partId": 1..4}, "paint": {"partId": "hex"}, "thirst": s, "hunger": s, "garden_seeds": n, "garden_growth": 0..1, "map_pieces": 0..4, "last_build_site": "home"/"two"/"three", "met": ["folkId"...], "save_version": 2}`. Shelf slot indices are GLOBAL across museum rooms (room * 28 + local). MIGRATION: a v1 save has `treehouse_level` 1..5 instead of `built` — `_migrate_from_level` grants everything that level implied so nobody loses a treehouse they already built; keep that path working. Building: `can_start(id)` (prerequisites only), `available_builds()`, `build_part(id)`, `tier_of/can_upgrade/upgrade_cost/upgrade_part(id, colour)`, `has_room(name)` (rooms come from parts declaring "unlocks"). `add_material(kind, n)`, `add_fruit(n)`, `can_afford(cost)`, `spend(cost)`. Session-only (unsaved): `start_card_shown`, `spawn_at_door`, `spawn_from`, `berries_picked`, `held_tool`, `dogs_here`, `sketch_strokes`, `sandwich_stack`, `pie_stack`.
2. `Sound` (scripts/sound.gd) — single AudioStreamGenerator mixer @22050 Hz. Detector tone: sine 180→720 Hz, amp 0.015→0.14 driven by `detector_active` + `detector_strength` (0..1) set each frame by main.gd. One-shot notes via `play_note(f0, f1, dur, amp, delay)`; effect wrappers: chime_find, chime_shelf, card_sound, pop, dig_sound, ribbit, chirp, woof, bell, hoot, knock, gulp, whistle, shutter, splash, munch. Mute = bus 0 mute.
3. `Affirm` (scripts/affirmations.gd) — the 10 affirmations `{text, icon}`; `next()` is a shuffle-bag (no repeats until all shown). Icons must exist in `DrawKit.draw_icon`.

Scenes (both are one-node .tscn shells; everything built in `_ready()`):
- `scenes/main.tscn` → scripts/main.gd — the meadow.
- `scenes/museum.tscn` → scripts/museum.gd — treehouse interior (shelves; plus the kitchen nook once built).
- `scenes/market.tscn` → scripts/market.gd — the market, WEST of the grove. Six stalls, each with a cloth BANNER naming what it sells and two buttons on the counter skirt: BUY (fruit → goods) and SELL (goods → fruit). `sell_price(buy)` is always one fruit less than the buy price and is derived, never stored, so the two cannot drift apart. Which one she gets depends on where the tap landed (`Stall.aim` + `aimed_at_sell()`); BUY is the default, so a vague tap anywhere on the stall buys, which is what she means nearly every time. Prices are drawn as that many apples — countable, no reading. Museum finds are NEVER spendable, nothing runs out, and a trade she cannot afford wobbles and shows what was missing rather than refusing. Three traders potter about behind the counters (see `Folk`).
- `scenes/pirate_cove.tscn` → scripts/pirate_cove.gd — Pirate Cove, on EAST again from Dino Land. Four sand patches each hold one piece of the treasure map (the fourth always completes it); a whole map reveals the chest. Rock pools to peer into, a parrot that copies her, a wreck to clamber on. Three `PirateShip`s ride the swell out in the bay (z_index -1, in front of the Sea at -2), pure scenery. Three pirates ashore (see `Folk`).
- `scenes/dino_cave.tscn` → scripts/dino_cave.gd — THE CAVE, entered from `DinoLand.CaveMouth` at x=1900. A T-rex lives in it who is only ever grumpy because he keeps getting SPLINTERS. First visit is a mystery she solves herself (he will not say what is wrong → she asks → she looks → she spots it → she pulls it out → he promises never to gobble her, and gives her his best bone). After that he says what he has done (`EXCUSES`) and the splinter rotates through `SPOTS` — foot, hand, and his bottom, which is in there on purpose. `GameState.trex_helped_t` + `SPLINTER_AGAIN` (600 s) means a new one turns up ten minutes later; `trex_met` gates the first-time story; `trex_spot` is where the next one will be. He never chases, and nothing in the cave can hurt her.
- TRAVEL AND ARRIVAL: `Zone.travel_to(scene, leaving_as)` records `GameState.arrive_from`, and each world places her with `Zone.arrival_x({from: x, ...}, default)`, which consumes it. That is what makes a return trip land at the gate she left through instead of the world's default start — coming home from the market she appears at the west signpost, from Dino Land at the east one, and out of the cave at the cave mouth. Add a world → add its entry to every neighbour's `arrival_x` map.
- THE BIKE: there is one in every world (`Nature.Bike`). Tapping it opens `BikeMap` — every world as a picture, the current one marked "you are here" rather than hidden — and choosing one runs `Zone.ride_bike()`: she rides off on the `"bike"` ride pose with the bike following her and dust behind, then the scene changes with `arrive_from = "bike"`. GOTCHA: the meadow's `zone_name` is "meadow" but its bike-map id is "home"; `open_bike_map` translates, or the map never says "you are here" at home. A new world needs one line in `BikeMap.PLACES`, one in `Zone.BIKE_SCENES`, and a `_thumb` case.
- `scenes/dino_land.tscn` → scripts/dino_land.gd — Dino Land, EAST. Brush-away fossil walls (3 brushes, always yields); FOUR kinds of `Dino` (longneck, trike, stego, compy) that amble between `home_x ± roam` and `greet()` her by stopping and dipping their heads; a volcano that only ever puffs; footprint trails. GOTCHA: the dinosaur art faces LEFT at fx=1, so `_draw` uses `fx = -_dir` or they walk tail-first.
- Transitions: tap the treehouse DOOR ITSELF → museum (there is no HUD door button; it used to float in the dirt); museum door → meadow (`GameState.spawn_at_door = true`). Signposts change scene: west → market, east → dino land; each zone has a "home" signpost back. Everything is saved before travelling.

Shared classes (global class_name, one per file):
- `DrawKit` (drawkit.gd) — static draw helpers: rounded_rect(+outline/points), ellipse, star, heart; painterly kit: `vgrad` (vertical-gradient rect), `blob`/`blob_points` (seeded organic ellipse — pass a stable seed or animated redraws flicker), `soft_shadow` (layered ground contact shadow), `canopy` (shaded foliage mass), `trunk` (tapered bark trunk), `tuft` (grass blades); `draw_icon(kind)` for affirmation icons (heart/star/sun/flower/rainbow/bird/leaf/butterfly/cloud); `draw_find(kind)` for finds. LIGHT CONVENTION: sun is upper-right — highlights up/right, shade down/left, shadows lean slightly left.
- `DrawKit.summer_head(c, at, r, munch)` — Summer's face alone at any size (hat, fringe, ponytail, blinking eyes), for the places where a face says it better than a symbol: the picnic's eat button is her taking a bite. Her whole figure still lives in player.gd; this is only the head. `DrawKit.vegan_badge(c, at, r)` — the green leaf-and-tick mark. The leaf is drawn TWICE, a fatter green pass first, to cut a gap through the tick behind it; without that the two shapes merge into one blob below about 20 px.
- `Paint` (paint.gd) — the shader layer that lifts flat polygons toward realism: SKY_SHADER (gradient + sun glow + drifting fbm clouds; on a ColorRect inside Nature.SkyBackdrop), `grain(rect, ...)` (per-pixel mottle ColorRect overlaid on big flat fills — dirt/turf in WorldBG._ready, museum walls/floor), `grade_layer()` (full-screen colour grade CanvasLayer — S-curve, saturation, warm-lights/cool-shades, vignette — added just BEFORE the Hud in both scenes; same layer index 1, tree order keeps it under the UI). GOTCHA: the mobile renderer runs shaders at half precision — sin()-hash noise shatters into visible facets; ALL shader noise must sample `noise_tex` (runtime NoiseTexture2D bound automatically by `_material`). Overlay ColorRects must keep MOUSE_FILTER_IGNORE or they eat taps.
- `BuildDefs` (build_defs.gd) — THE source of truth for the treehouse. `PARTS` maps id -> {track, word, site, cost, needs, spot, tierable, unlocks}; five TRACKS (structure/access/extension/comfort/decoration); `site` is which tree it belongs to (home/two/three/ground); `spot` is a Vector2 in Treehouse-local coords, used for the board's badge, the ghost preview AND the fly-to target when building. `needs` encodes ONLY physical impossibility (no storey without the one below) — never a choice, so nothing is ever mutually exclusive. START_BUILT = platform/ladder_rope/shelves. TIER_COST: tier 3 = timber 2, tier 4 = paint 1. Adding a part = one entry here + one case in Treehouse._draw_part.
- `Treehouse` (treehouse.gd) — a tree she builds in, drawn from `GameState.built` rather than a level number, so any combination looks right. Three exist in the grove (`site` = home/two/three; home also draws the "ground" parts round its base). Storey bands: CABIN_TOP -340, STOREY2_TOP -420, TOWER_TOP -488, roof caps whatever is tallest (`_top()`) — kept compact so the finished mansion still fits on screen. `preview_id` suppresses a part; `ghost_only` draws ONLY that part (the board stacks a translucent copy over the real tree). Moving parts (flag, vane, bunting, chime, zipline) live in the `Motion` child so the big static tree does not redraw every frame; they hang off `_top()` so they follow the house up.
- `StockPile` (stock_pile.gd) — the visible heap of materials at the foot of the home tree. Everything gathered flies here; the stacks grow with the count. Tap = `count_out()`, which pops a numeral over each stack (the counting practice, entirely optional).
- `PlanTable` (plan_table.gd) — the workbench that opens the board. The pinned plan shows the cheapest available build (affordable first), so the table is a reading-free goal. `wiggle()` for "not quite enough yet" — never a refusal.
- `BuildBoard` (build_board.gd, CanvasLayer 42) — the plan board. `Body` holds state/input/background, a `Treehouse` at z1, a ghost `Treehouse` at z2, and an `Overlay` at z4 for badges/panel/tabs. DRAW ORDER MATTERS: badges must sit above the ghost. Badges land at `tree_origin + spot * tree_scale`. Unaffordable spots are still shown and still tappable (they wiggle). Emits `build_chosen` / `upgrade_chosen(id, colour)`.
- `TopBar` (top_bar.gd, inside Hud) — fruit, all six materials (stick, plank, rope, timber, paint, seed) each with its name underneath so she can read what she is carrying, thirst and hunger. `NAMES` maps the internal key to the word she sees (timber → "wood"). `tap_at()` swallows taps on the counters so a look at the read-out never walks her to the top of the screen — every world gets this through `Zone.handle_tap`. METERS NEVER PUNISH: an empty one only glows and floats a bubble. THIRST_SECONDS 300, HUNGER_SECONDS 600.
- `Grove` (grove.gd) — inner classes for the home grove: RopeBridge (one-way floor via `rect()`, sags under her feet), Signpost (`destination` home/market/dino, picture not words), FruitTree (`shake()` drops fruit, regrows), FallenFruit, GardenPatch, Footstep, Firefly, RoofCat, SteppingStones (one continuous `walk_rect()` so she never falls down a gap), Telescope + FarView (the round eyepiece view of the next land; hills are clipped to the circle).
- `Critters` (critters.gd) — what the animals say and what they can TEACH. The companion to `Folk`: same `[short, long]` fact pairs picked by `GameState.reading_level`. Covers frog/bird/butterfly/owl/indy/star/parrot and every Dino Land species plus the cave T-rex. `Zone.meet_animal(who, target, subject)` is the single entry point: empty-handed it opens a chat with a TELL button and she learns something; with the camera in her hand it opens the same card with a CAMERA button, she asks politely, and the photo is of THAT creature.
- THE CAMERA IS A THING SHE CARRIES. `use_item("camera")` calls `Zone.toggle_camera()`, which puts it in her hand (`player.held_tool = "camera"`, drawn at her side with the strap round her neck) — it does NOT fire a photo. It used to snap the instant she touched it in the backpack, which meant she could only ever photograph her own feet. While it is out: every creature is tappable for a portrait, and `Hud.shutter_pressed` → `Zone.snap_here()` takes a picture of the place. Picking up the detector or net puts it away (`hud.set_camera_out(false)`), and so does tapping it again. One hand, one thing in it.
- `Folk` (folk.gd) — THE PEOPLE. One roster (`PEOPLE`: name, role, hat, top, hello, `tells`), one figure (`Folk.Person`, a walker with `home_x`/`roam` that stops and faces her while talking), one way of meeting them. A world gets its people with `Zone.spawn_folk(where, spots, z, depth)` and routes taps with `elif node is Folk.Person: talk_to(node)` — that is the whole job. `who_lives_in()` maps meadow → three village kids, market → three traders, dino → two fossil hunters, cove → three pirates. `depth` stands them further back (higher and smaller) so a market trader can be BEHIND their counter and still visible over it; the stalls take `z_index = 2` and the traders 1.
  - Talking uses the same `DialogueCard` as the animals, but where an animal gets a camera button a person gets a TALK button (`action = "tell"`): ask, and they tell her something true. Every fact in `tells` is a PAIR — `[short, long]` — and `something_to_tell()` picks by `GameState.reading_level`, so the setting changes how much she reads and never whether she can talk to someone. `GameState.met_folk` remembers who she has met, so a first meeting introduces them and later ones just say hello.
  - Adding a person means one entry in `PEOPLE` and one id in `who_lives_in`. Roles ("kid"/"trader"/"adventurer"/"pirate") pick the clothes; `hat` picks from `_hat`.
- `Zone` (zone.gd) — THE SHELL every world extends, the meadow included. One place for: the backpack and its button, the basket button, drinking, the whistle (the dogs follow her anywhere), the camera, the sketch pad, the map, the picnic, the thirst/hunger meters and bubbles, the camera rig, the colour grade and the HUD. A world calls `setup_ground(w, palette)`, places its own scenery, then `setup_player(x)`, and its `_unhandled_input` MUST give `handle_tap(screen_pos, wp)` first refusal or the backpack, the counters and the bubbles all go dead. Build a new world by extending Zone and writing only what is special about it. `pack_items` picks what the backpack offers: the meadow sets `Backpack.ITEMS` (everything), everywhere else takes `AWAY_ITEMS`, which leaves out the detector and net — nothing to sweep for or catch out there, and a dead tool is worse than an absent one. Zone also carries empty `platforms`/`vines`/`blocks` because MapView reads them off whatever world it is handed. Override `on_collected()` to react to a new find (the meadow celebrates milestones).
  - main.gd `extends Zone` too. It used to duplicate thirteen of these functions and every fix had to be made twice — which is exactly how the ladder arrow, the top-bar taps and the backpack drifted apart. It now overrides only the four that are genuinely different at home: `use_item` (adds the detector and the net), `whistle` (the dogs have a kennel to run to), `sit_and_eat` (she walks to the picnic blanket) and `take_reward` (refreshes the stock pile). Subclasses must NOT redeclare parent members or consts, and an overridden `_process` must call `super(delta)`.
- BUILD SITES: `BuildDefs.PARTS` entries carry a `site` — home / two / three / ground. Tree two and tree three used to have five and two parts, both on the "outside" track, so panning to them showed four empty tabs; they now carry a full set across all five tracks (18 and 15 parts) and are proper houses of their own. Every track has something on every tree — if you add a site, keep that true. `GameState.last_build_site` remembers which tree she was working on: the board opens there (falling back home if its bridge is not built yet), every site switch and every build records it, and `main._reopen_board()` brings the board straight back after the build animation so a run of parts on one tree is one flow.
- RIDES: `Player.ride(path, seconds, pose)` follows a path with gravity and walking suspended, then drops her onto whatever is below. Poses reuse what already exists — `hanging` (ladder, zip) borrows the vine-cling look, `sitting` (slide, lift) borrows the snack pose. main.gd `_refresh_rides()` places `Grove.RideSpot` markers and fills `tree_decks` (the platform + decks become one-way floors), so the treehouse is somewhere to BE, not scenery. The ladder is always there, so the platform is always reachable.
- `Nature.WorldBG.palette` — "meadow" / "dino" / "cove" swaps the whole ground colour set plus how much grass and flower cover there is (`flora`), so each zone reads differently without a second copy of the drawing.
- `MiniGame` (mini_game.gd, CanvasLayer 41) — base for the five discoverable games. Subclasses override `build()` (NOT `_ready`) so the exit button always exists; it is re-parented last so a game can never cover its own way out. `say(pictures, words, sentence)` picks the wording from `GameState.reading_level`; `missed()` drops a level after two wrong in a row and `hit()` never raises it straight after a miss; `give(kind, n)` emits `rewarded` — "fruit", a material name, or "find:<kind>" for the museum. EVERY game rewards something; none is timed or scored.
- The five: `PlankGame` (cove, phonics), `BoneGame` (dino, shape/spatial), `StallGame` (market, number bonds), `PatternGame` (garden, repeating patterns), `MemoryGame` (museum, memory — its deck is built from HER OWN finds, so it changes as the collection grows). Each is opened from a `Grove.GameSpot` — the one star-ring marker used at every game everywhere, deliberately different from the chevron ride markers.
- `PieGame` (pie_game.gd, CanvasLayer 40) — baking in the kitchen. Fruit -> pastry -> crimp -> bake -> eat. No recipe is wrong. Emits `eat_now(stack)` like the picnic does.
- `Photos` (photos.gd) — the real photographs behind `photo_<subject>_<v>` finds. `get_photo(subject, v)` → Texture2D or null (`COUNTS` says how many files each subject has; v wraps, so a saved find always shows the same picture in the popup AND on the museum shelf); `crop_for(tex, pic)` centre-crops to the polaroid window without squashing. Files are `photos/<subject>_<n>.jpg`, 600x600, mipmaps ON (they get drawn tiny on shelves). Subjects with photos: frog, bird, butterfly, owl, meadow (Pexels License), indy, star (Summer's own dogs, cropped from `IndyStar/`). Any subject without a photo falls back to DrawKit's drawn version — adding a subject means dropping files in and bumping COUNTS, nothing else. Dino Land subjects (longneck, trike, stego, compy, trex, dino) are life-size park models, sculptures and museum skeletons rather than photographs of animals — dinosaurs being extinct — under the same Pexels licence; the red-lit scary ones were deliberately left out.
- `Fx` (fx.gd) — sparkles, hearts, float_number (all self-freeing tweens).
- `FindIcon` (find_icon.gd) — Node2D wrapper around DrawKit.draw_find; used for dug items, tray, shelf.
- `IconButton` (icon_button.gd) — round icon-only touch button (kinds: mute, satchel, dig, door).
- `Hud` (hud.gd) — CanvasLayer; mode "world" (satchel+mute+contextual dig/door) or "museum" (mute only). Signals: dig_pressed, door_pressed.
- `AffirmationCard` (affirmation_card.gd) — `AffirmationCard.show_card(hud_layer, Affirm.next())`; slides up, tap or 8 s to dismiss.
- `Player` (player.gd) — Summer (blonde ponytail under a safari hat, khaki explorer shirt, olive cargo shorts, coral neckerchief, blue backpack); tap-to-walk `target_x`, keyboard (arrows/AD walk, Up/W jump, Down/S climb down, Space/E dig-or-enter/let-go) for dev; facing via `fx` multiplier in _draw, NOT node scale. DRAWING: full little-figure rig — two-segment arms/legs via `_limb2(root, tip, bend_dir, rest_len, ...)` (elbows/knees bulge with slack), soft dark outlines (part colour darkened ~0.35 drawn wider underneath), walk cycle with opposite arm swing, natural blink (`blink_t`/`blink_in`), ponytail sway. Physics states: on_ground / airborne (GRAVITY 1500, JUMP_VY -640, JUMP_VX 250, MAX_FALL 720) / swimming / climbing. `world` (main.gd, null-safe) supplies floor_y_at(x, feet_y), clamp_walk(from, to, feet_y), in_water(x), water_surface_y(), vine_near(hand). `held_tool` ""/"detector"/"net" drawn in hand on ground; stowed detector handle pokes from pack. `regrab_t` 0.6 s cooldown stops instant vine re-grab after let-go/launch. Pose timers (priority dig > build > drink; each gates the others): `reach_t`+`reach_local` (arm toward target, limited to 30 px so arms stay natural — main walks her to ARM_STOP 56 first), `talk_t` (wave), `swipe_t` (net arc), `camera_t` (camera to face), `drink_t` (bottle tilts to open mouth, gulp bubbles), `dig_t` (kneel + trowel scoops), `build_t` (mallet swings). Public: try_jump(tap), climb_toward(tap), let_go(), face_toward(x), reach(toward), talk(), swipe(), hold_camera(), drink(), start_dig(), build(toward_x).
- `Nature` (nature.gd) — inner classes: SkyBackdrop (Control on CanvasLayer -1; explicit size from viewport — anchors alone failed; also draws the two distant hill bands with parallax by reading `get_viewport().canvas_transform` each frame — hills are screen-space, NOT in WorldBG), WorldBG (1:1 near meadow rise + hedgerow shrubs, gradient dirt cutaway, wobbly-edge turf strip, tufts, flowers), MeadowTree, Treehouse (door_rect(); draws build stages from GameState.treehouse_level — 2 porch, 3 annex room, 4 rooftop lookout, 5 rope ladder/birdhouse/fairy lights; main calls queue_redraw() after building), BuildSign (COSTS table + static next_cost(); shows needed materials as icons, collected ones full-colour, missing ones ghosted; wiggle() = friendly not-yet shake; at DOOR_X-108), MaterialPickup (kind stick/plank/rope, ground collectible), Owl (perched at (3152, GROUND_Y-170) by the x=3100 tree; blinks, hoots + flaps on tap), BerryBush, Pond (frog_at(wp)), Frog, BirdTree (flutter_t — parent bird hops/flaps when greeted), Bike, PicnicBlanket, Block (crate/rock/log; rect(); not interactable — main handles collision), Platform (one-way lookout perch, rect(), stilts drawn to GROUND_Y), Vine (point_at(d), near(hand), min_d/max_d, pump(dir), ang_vel for launches), Butterfly (wants_tap/try_tap dodge, get_caught(net_pos, parent) catch-and-release + away_t respawn), ThirstBubble, Dog, Hole, HintSparkle. Interactables expose `tap_score(wp) -> float` (0..1 — how central the tap is; 0 = miss; used by main's weighted picking) alongside `try_tap(wp)` (act). Scores: berries r60 (bush leaves half-weight r95), frogs r55 (open water flat 0.3), nest r75, bike r62, blanket r80, dog r60, butterfly r70. NOTE: do not name inner classes after native Godot classes (Sky/Tree caused parse errors).
- `Backpack` (backpack.gd) — 4x2 bubble grid above Summer; ITEMS = detector, net, camera, whistle, sketchpad, map, bottle, picnic; item_at(wp); equipped tool ringed gold.
- `PhotoCard` (photo_card.gd, CanvasLayer 45) — BIG viewable polaroid popup: shown after every photo taken (then the photo stows to the satchel on dismiss) and when tapping a photo_* item in the museum. `PhotoCard.show_photo(parent, kind, word)`; `closed` signal; tap or 6 s dismisses; full-rect Control blocks taps underneath. In the meadow it goes through main's `_open_ui` (pauses the player, sets ui_layer).
- `DialogueCard` (dialogue_card.gd) — two-line polite chat card (Summer line then animal reply after 1.5 s); camera IconButton → asks "please may i take a photo?" then emits `photo_moment` (main snaps). show_chat(layer, l1, l2). Auto-dismisses.
- `DrawingSuite` (drawing_suite.gd, CanvasLayer 40) — full-screen sketch pad; GameState.sketch_strokes holds OPS: {type:"stroke",col,w,pts[]} | {type:"fill",col} | {type:"clear"} (missing type = stroke). Draw starts from the last "clear". Undo/redo move ops to/from GameState.sketch_redo (new ops clear redo). Right-hand tool column: pack, save, undo, redo, fill (current colour), clear (fresh page — undoable, nothing lost). Paper-colour swatch = eraser; page persists all session. Save → PNG in user://drawings/ + "drawing" satchel item. `closed` signal.
- `MapView` (map_view.gd, CanvasLayer 40) — world strip with landmarks + live pulsing you-are-here dot; needs `world_node` set before add_child. `closed` signal.
- `SandwichGame` (sandwich_game.gd, CanvasLayer 40) — the picnic. A wooden board along the bottom holds all 8 fillings, each drawn by `Table._food(kind, pos, w, h)` and captioned from `NAMES`. Tap one to stack it on the plate; tap the tower to take the top layer back off (there is no other undo, and a five-year-old will mistap). Stack lives in `GameState.sandwich_stack`; the eat button hands it to `Zone.sit_and_eat`, which walks her to the blanket and feeds her layer by layer. `closed` signal.
  - EVERYTHING IN IT IS VEGAN. `PLANT_MADE` (butter, cheese, ham) are the plant versions and wear `DrawKit.vegan_badge` — the leaf-and-tick mark she will see on real packets — so it is visible at a glance that nothing came from an animal. If you add a filling, decide which side of that line it falls on. The kind ids are also keys in `Player._food_colour`, so renaming one silently greys out the food she holds while eating.
  - `_food` draws BOTH the stacked layer and the picture on its button, so what she taps is exactly what she gets. It is sized from `w`/`h` alone — no magic numbers — which is what lets one routine serve a 150 px layer and a 70 px icon.
  - GOTCHA: skinny layers use draw_rect — rounded_rect polygons < ~8 px tall fail triangulation.

Interactable pattern: node exposes `try_tap(world_pos) -> bool`; main.gd checks its `interactables` list before treating a tap as walk-to.

- MAKING ROOM: the basket and the shelves both fill up, and until recently there was no visible way to empty either. Two routes now, both named in words: in `SatchelView`, tapping a find picks it up and offers KEEP IT or PUT IT BACK (`GameState.put_back`) — the only thing in the game that removes something she owns, deliberately two taps behind a labelled button, and never called throwing away because the meadow keeps making more. In the museum, tapping a shelved find shows its word tag with an "into my basket" button (`WordTag.slot` + `take_down`, calling `_take_off_shelf`). The drag-into-the-tray gesture still works and always did — nothing on screen ever said so, which is why nobody found it. GOTCHA: `_press` must give `word_tag.tap_at()` first refusal or the shelf behind swallows the tap.
## World layout (main.gd)

WORLD_W 4200, GROUND_Y 600, viewport 1280x800 (canvas_items/expand). Camera child of player, offset (0,-200), limits 0..4200 x 0..800.
THE HOME GROVE (x 0..1500) is almost entirely about the treehouse — no digging, no material spawns, nothing to distract. Signpost west 60 (market), home tree/door 420 (its workshop draws at local -320..-212, i.e. world 100..208), plan table 690, stock pile 830, bike 1150, SECOND tree 1020, THIRD tree 1300, garden 1430. GROVE_END_X 1500 = where the meadow proper begins.
MEADOW: bushes 1620/2200/3450, birdtree 1900, pond 2750, picnic 3720, fruit trees 1700/2600/3560, owl 3152, deco trees 3100/3950, signpost east 4150 (dino land). Blocks (jump over / stand on): log 1560 (116x54), crate 2050 (120x72), rock 2450 (132x58), crate 3270 (120x72). Platforms (one-way perches, plank top at position): (2250,450), (3000,445). Stepping stones across the pond are ONE continuous walk surface (Grove.SteppingStones.walk_rect) and `in_water` returns false while she is on them.
BRIDGES: Grove.RopeBridge between the trees once built, added to `platforms` (one-way). `_refresh_bridges()` rebuilds them; a bridge appears as soon as it is built, even though the far tree is still bare — walking to an empty tree is the invitation to build it.
GATHERABLES and what they are FOR — every one must feed something. Blackberry bushes and fruit trees both give `fruit` (the market currency) and ease hunger a little; the bushes also pop a running count 1..20 for counting practice. Buried finds and dig walls give museum finds. MaterialPickups give building bits. The butterfly net is deliberately catch-and-release — she holds it a moment and lets it go, and that is the whole reward.
Materials: 4 concurrent MaterialPickups (weights stick 3/plank 3/rope 2), x GROVE_END_X..4060, min 240 apart, clear of pond/blocks; collect = reach + fly-to-STOCK-PILE + GameState.add_material; another spawns 12–25 s later. BUILDING IS DEFERRED — collecting never builds. Materials fly home to the StockPile; tapping the PlanTable opens the BuildBoard; choosing a spot emits build_chosen, and `_do_build(id)` COMMITS TO THE SAVE FIRST (so quitting mid-animation loses nothing), then walks her over, swings the mallet, and flies 3–6 pieces from the pile to the spot with a knock each (~2 s total), then sparkles + chime + affirmation + an auto "photo_treehouse_N" into the satchel. Unaffordable = plan_table.wiggle(), never a refusal. `_do_upgrade(id, colour)` does the same for a material tier. storey2 unlocks the museum's second room, tower a third; kitchen unlocks the PieGame in the museum.

Movement: single tap walks; double tap (≤0.4 s, ≤170 px apart) jumps toward the tap — straight up if the tap is within 60 px of her x. Mid-jump hands near a vine → cling (blocked for regrab_t 0.6 s after release). While clinging: taps above/below shimmy 62 px; taps beside pump the swing (Vine.pump, amp ≤0.5 rad, decays); double tap LAUNCHES toward the tap (JUMP_VX*1.35 + swing tip velocity; straight below = gentle drop). Pond x 2750±165 → swims (feet settle at GROUND_Y+26, ~55% walk speed); no digging/detecting while swimming/climbing/airborne/on perches/UI open. Block sides stop walking (clamp_walk, 14 px skin); block/platform tops are floors when feet are above top+12; platforms never block sideways.

Walk-to interactions: tapping any interactable > REACH (120 px x-distance) away stores pending_interact and walks her to ARM_STOP (56 px) short of the tap — she stops at arm's length, never on top of the thing, then reaches; interact fires only once she has STOPPED (not player.walking; keep pending while target still far — walking is stale-false on the tap frame). On arrival main._interact routes it — berries/bike get reach(wp)+try_tap (arm stretches toward the tap + crouch, 0.7 s), blanket opens SandwichGame, animals (dogs, nest birds, pond frogs via frog_at, butterflies) get try_tap + _chat (CHATS table: lowercase polite phonics lines) on a DialogueCard whose camera button photographs the animal. Butterfly + net held = player.swipe() (net sweeps an arc, 0.45 s) + get_caught instead of chat.

Tap priority (in _unhandled_input): pack ring items → thirst bubble → weighted picking (Summer's pack hitbox scored as 1 - d/70 vs every interactable's tap_score; HIGHEST score wins, ties go to Summer — so a central hit on a berry beats the fringe of her hitbox and vice versa) → treehouse door → double-tap jump → walk.

Photos: _take_photo(subject, at) — Summer holds the camera up (player.hold_camera(), pose drawn over her face), shutter, then a BIG PhotoCard popup of "photo_<subject>_<v>" (v = randi()%10) via _open_ui; dismissing it stows the photo into the satchel. Subjects: frog, bird, owl, indy, star, butterfly (via chat camera) and meadow (backpack camera). DrawKit.draw_photo renders the ten variants per subject (sky v%4, decoration v%5, flip v>=5, offset v%3); draw_find routes any "photo_*" kind to it. Museum word tag for photo_* = the subject name. No screenshot files are written.

Backpack: tap Summer (≤70 px of feet+(0,-45)) → Backpack grid; auto-closes after 8 s, on jump/swim, or on any other tap. HintSparkle twinkles on the pack while held_tool == "". Items: detector/net toggle held_tool (mutually exclusive; gates tone+sparkles+dig / butterfly catching); camera = meadow photo (see Photos above); whistle toggles the dogs — NOT present by default, arrive running from off-screen left after 0.9 s (surprise!), whistled away they follow a DogHome node off-screen then free (GameState.dogs_here survives museum trips); bottle = a real drink (player.drink() — bottle to her mouth, two gulps, resets thirst; ThirstBubble nudges after 300 s, never a consequence); sketchpad/map/picnic open CanvasLayer suites — main sets ui_layer, player.set_process(false), blocks world input until `closed`.

Satchel/shelf kinds now include "drawing" and "photo_<subject>_<v>" (plus legacy "photo"). They're satchel items like any find — never spawned buried (not in FIND_TYPES).

Find kinds + weights (GameState.FIND_TYPES, fossils/dino weighted highest): ammonite 4, dino_bone 4, dino_egg 3, trilobite 3, shark_tooth 3, roman_coin 2, pirate_coin 2, gem 1, old_key 1.

## Museum layout (museum.gd)

UP TO FIVE rooms — one per storey built (storey2, tower, tree2_cabin, tree3_tower); round RoomArrows at (1248,380)/(34,380) step between them. Basket pages with its own arrows at (150,716)/(1130,716), TRAY_PER_PAGE 9, dots under the basket. 28 slots PER ROOM: 7 cols x 280..1000 step 120, 4 rows y 175/295/415/535 (shelf plank at slot y+30); global slot = room*28 + local — GameState.shelf keys are global, `slot_pos` takes LOCAL. `_populate_shelf()` rebuilds icons per room. Tapping a photo_* item opens a PhotoCard (big view) instead of a word tag. Basket (satchel contents) centred at y 716, one page at a time. Drag: press picks nearest VISIBLE item ≤48 px; release drops to nearest free slot ≤80 px. Releasing BELOW y = TRAY_Y-90 takes a shelf find off display and back into the basket (bg.basket_glow lights while carrying one down). Nothing is ever destroyed. Tray→shelf placement: save + chime_shelf + sparkles + affirmation card. Shelf→shelf move: save + pop. Press+release moving <14 px = tap → WordTag (WORDS map, lowercase Year 1 words) instead of move. Poster tap (≤95 px of POSTER_CENTER (120,300)) → affirmation card. DOOR_RECT (1090,430,152,190) → exit.

## Affirmation triggers

1. Once per app session, 1.4 s after meadow loads. 2. Every tray→shelf placement. 3. Sunshine poster tap. All via `AffirmationCard.show_card`.

## Personalisation facts

- Summer: nearly 6, dinosaur/fossil obsessed, loves art and drawing (see IDEAS.md).
- Dogs (both lurchers, in-game companions following player, tappable → woof+bounce+hearts): Indy — white, brown patch over one eye, brown ear opposite side, trail 115; Star — black, slightly bigger (scale 1.15), white star chest marking, trail 195.
- Affirmations list is verbatim from the user; edit only in affirmations.gd.

## Validation (do this after changes)

Godot editor not installed system-wide; a copy was used from scratchpad during development. Any Godot 4.3+ standard build works:

```
godot --headless --path <project> --import        # parse/compile errors
godot --headless --path <project> --quit-after 300           # runtime smoke, meadow
godot --headless --path <project> res://scenes/museum.tscn --quit-after 200
godot --headless --path <project> res://scenes/market.tscn --quit-after 200
godot --headless --path <project> res://scenes/dino_land.tscn --quit-after 200
godot --headless --path <project> res://scenes/pirate_cove.tscn --quit-after 200
godot --headless --path <project> res://scenes/dino_cave.tscn --quit-after 200
```

Visual check: add temporary autoload script that waits, `get_viewport().get_texture().get_image().save_png(...)`, switches scene, captures again, quits (windowed, not headless). Remove the autoload + file afterwards; delete `%APPDATA%\Godot\app_userdata\Adventure Day\adventure_day_save.json` if the probe faked state. "ObjectDB instances leaked" on forced quit is benign.

Behaviour check (headless, no screen): same trick, but assert instead of screenshot — a temporary autoload that waits ~1.2 s for the scene, then drives the real API (`hud.pack_pressed.emit()`, `m._do_build("cabin")`, `m._spawn_buried()`), prints one `T<n> ...` line per check and a final `RESULT: PASS/FAIL`, then `get_tree().quit()`. Add it to project.godot as an autoload, run, then restore project.godot and delete the probe. GOTCHA: `get_tree().current_scene` is untyped, so `var n := m.buried.size()` will not compile inside a probe — write `var n: int = ...`.

## Code conventions

- Tabs, typed GDScript where cheap, `:=` inference.
- Dictionaries accessed with `["key"]` (not dot). Vector2 stored in a Dictionary must be copied out, mutated, written back.
- Facing flip via `fx := float(facing)` multiplier on x coordinates inside _draw.
- GOTCHA: IconButton icons draw relative to `ctr` (the button centre), NOT the node origin — an icon drawn at Vector2.ZERO lands in the top-left corner of the button.
- GOTCHA: `modulate` is a NODE property, so setting it part-way through a `_draw` fades the whole node, not the next few calls. To fade one thing, pass an alpha into its colours.
- GOTCHA: a marker that points at a built thing must be positioned FROM that thing, not from a constant. The climb marker comes from `main._climb_path()` (the midpoint of whatever way up she has built) so it cannot drift off the ladder, or sit where a ladder used to be after she builds the stairs.
- GOTCHA: `draw_set_transform()` REPLACES the canvas item's draw transform — it does not stack. A _draw() that sets one and then calls a DrawKit helper which sets its own (draw_photo's bird/butterfly branches, draw_icon callers) loses the outer one, and everything drawn afterwards lands in the wrong place. Put position/rotation on a child Node2D instead of nesting draw transforms (see PhotoCard.Polaroid).
- GOTCHA: an inner class (`Dino`, `Stall`, `Trex`, `Folk.Person`) is NOT parse-checked when you access its members from outside — `dino.kind` on a class whose property is `species` compiles fine and then fails at runtime. Anything touching an inner class's properties has to be exercised by a behaviour probe, not just an `--import`.
- GOTCHA: inside a Control's `_gui_input`, read `event.position` — never `get_local_mouse_position()`. A touch on Android does not move a mouse cursor, so the live position can be stale or (0,0) and every button on the panel misses. This bit the picnic, the sketch pad and the pie game at once.
- GOTCHA: never place things by rejection sampling with a give-up count. `_spawn_buried`/`_spawn_material` used to throw darts at the ground and stop after 60 misses, so she quietly started with five finds instead of six — and it got worse as the treehouse filled the strip with blocks. `main._open_spot(lo, hi, taken, want_gap, block_pad, player_gap)` walks the strip instead: the pond and the blocks are a hard no, spacing and her own position are preferences, and it returns the roomiest legal spot. -1 means genuinely nowhere.
- Self-freeing effects: tween chain ends in `tween_callback(queue_free)`.
- Colors as `Color("hex")`; palette: sky c3e2f2/eef7fb, grass 8fc48a/a8d5a2, dirt b9906b/a67c58, wood 8a6a52/c9a06c/a97e54, cream fff8ec, gold ffd98a, coral e8918c, slate 7a8b9c.
- No input map; keys polled directly (KEY_LEFT/RIGHT/A/D walk, UP/W jump, DOWN/S climb down, SPACE/E context action).

## Android export (not yet configured on this machine)

JDK 17 + Android SDK + export templates (Editor → Manage Export Templates). Debug keystore ok for sideloading. `export_presets.cfg` is gitignored (holds keystore secrets) — recreate per machine, leave ALL permissions unchecked. Gradle build unnecessary for plain APK.

## Doc map

- AGENTS.md (this file) — canonical reference for AI agents; keep current when architecture/rules change.
- IDEAS.md — unbuilt inspiration backlog; append, don't build without being asked.
- PLAN.md — the considered design for the next arc: deferred treehouse building (plan table + stock pile + build board), the home grove, zones/signposts (market, dino/pirate land), top-bar counters, food loop. UNBUILT; read before touching treehouse/building/HUD so new work matches the intended shape.
- README.md — human quickstart (setup/run/export).
- CLAUDE.md — pointer here.

## Android / Play release

Engine is **Godot 4.7.2** (`C:\Godot47\`). It was 4.3, which targets API 34 —
below Google Play's API 36 floor (from 31 Aug 2026). The upgrade was validated
scene by scene; nothing in the game needed changing for it.

`./build_android.sh apk|aab` is the only supported way to build. Toolchain
paths, the keystore location, the version-bump ritual and the one real gotcha
(the Gradle staging folder keeping a stale copy of the project) are in
`store/RELEASE.md`. Play Console form answers are in `store/CRIB.md`.

`project.godot` needs `textures/vram_compression/import_etc2_astc=true` or the
Android export refuses to run.

The app ships with **no Android permissions at all** — no INTERNET included.
Keep it that way: it is what makes the Families Policy and the data safety
declaration trivial. Adding any networking would change the whole compliance
picture.

## Phones vs tablets

The game is laid out for 1280x800 with `canvas_items` + `expand`, which keeps
the logical height at 800 and lets the width grow. On a 21:9 phone that gives a
1742-wide logical viewport — 36% more world than the design assumes — so
everything reads as small and the buttons fall under the ~9 mm a finger needs.

`GameState._fit_to_screen()` measures the physical screen (DPI + pixel size)
and sets `content_scale_factor` accordingly: under 6" → 1.5, under 7.6" → 1.32,
under 9.5" → 1.14, tablets and desktops → 1.0. A 6.8" phone lands at 1.32,
which brings the logical viewport back to about 1320x606 — very close to the
1280 the art was drawn for. If a device guesses wrong, that one function is the
only place to change.

CARDS SIT IN THE DIRT. `DrawKit.ground_screen_y()` works out where the ground
line falls on screen (the camera is effectively locked vertically, but the
visible height moves with the screen shape and the UI scale). DialogueCard and
AffirmationCard place themselves below it and SHRINK to fit the strip that is
available — on a long phone that strip is only ~100 px. A card that covers the
meadow is worse than a card with slightly smaller text.

## Where files go

- `build/` — APKs, AABs and the Windows build. Gitignored. `build_android.sh apk` also drops a
  copy in `Desktop\Adventure Day\` so it is easy to pass to a phone.
- `Desktop\Adventure Day\` — the APK, a launcher for the PC, and a README.
  Nothing else belongs on the desktop.
- `C:\AdventureDayKeys\` — the signing key. Outside the repo, on purpose.
- `%APPDATA%\Godot\app_userdata\Adventure Day\` — Godot's own folder. It holds
  `adventure_day_save.json`, which is HER SAVED GAME on this machine. Do not
  delete it.

DEBUG RENDERS: probe scripts save screenshots to `user://`, which is that same
app_userdata folder. Clean them up when the probe is done — otherwise they pile
up next to the save file. Delete the PNGs, never the JSON.

## The Windows icon

`store/AdventureDay.ico` is a six-size icon (16/32/48/64/128/256) built by
`tools/make_icon.sh` from `store/play_icon_512.png`, and embedded at export
time via rcedit (`C:\BuildTools\rcedit-x64.exe`, path set in the editor
settings). With a single size in the file the export warns and Windows picks a
badly scaled icon for the taskbar.

`tools/check_icon.sh` parses an .ico back and confirms every directory entry
points at a real PNG inside the file — worth running if the icon is ever
regenerated. GOTCHA: bash's printf reads `\x` escapes greedily and produced a
subtly wrong file; the script uses octal `\NNN` instead.

## Taps: who gets them

Three separate playtest complaints turned out to be the same class of bug —
two things wanting the same tap. Worth checking with a probe rather than
waiting for the next report.

- CARDS DO NOT TAKE TAPS. `DialogueCard` and `AffirmationCard` are
  `MOUSE_FILTER_IGNORE`, so a tap aimed at a berry or a log behind them reaches
  the world. Their buttons are children and still get their own events. They
  auto-dismiss; there is no tap-to-dismiss any more, and there does not need to
  be, because they no longer block anything.
- A DOUBLE TAP ALWAYS MEANS JUMP. `main._unhandled_input` checks `is_double`
  BEFORE scanning interactables. The second tap of a jump often lands on a
  butterfly or a game marker, and she would end up in a conversation instead of
  in the air. The first tap of the pair already did whatever it was doing.
- PEOPLE YIELD TO BLOCKS. `Folk.Person.tap_score` returns 0 for any point over
  one of the zone's `blocks`. They wander, so sooner or later one stands on a
  crate; the crate wins there and she can talk to them a step to either side.

A probe that samples the world and reports where two interactables both score
highly — and where any interactable's zone covers a block — found all of these
at once. Rebuild it if the layout changes much.

GOTCHA: `drop_copy` fails if the game is open — Windows locks the exe. It used
to fail silently and leave the previous version sitting on the desktop while
the build output said everything worked; a stale build got tested for ten
minutes before anyone noticed. It now stops with a clear message. Close the
game before rebuilding.

CARDS CLOSE WHEN SHE MOVES ON. `Zone.handle_tap` calls `dismiss_cards()` on
every tap that reaches the world, so walking away or reaching for something
else puts the speech bubble away. Taps on the card's own talk button never
reach the world, so pressing that is safe.

## The market crowd

Two kinds of person, and they are laid out deliberately:

- SIX TRADERS, one per stall, stood at the back of their own pitch. `roam = 0`
  so they never leave it (a `Person` with no roam also stops animating a walk),
  `depth 62` so head and shoulders clear the counter, offset +36 px so they
  stand BESIDE their goods rather than behind a stack of planks that hides
  everything but their hat. Drawn at z 1, behind the stalls at z 2.
- THREE CUSTOMERS browsing in front, at z 4 with the player. They patrol the
  open ground either end of the row and the gap in the middle, because a
  customer parked in front of a counter is one the stall out-scores.

Z-ORDER: background < traders (1) < stalls (2) < customers and Summer (4).
Summer used to be at the default 0 and vanished behind every stall she walked
past.

THE TALK BUTTON WAITS FOR THE REPLY. `DialogueCard` hides it until line two
has actually appeared, then pops it in. Offering it while somebody is still
mid-sentence invites a tap that cuts the reply off and the conversation stops
making sense. Applies to the camera button on animals too.

PEOPLE GET OUT OF THE WAY. `Zone.mind_her_space()` runs in every world: while
she is stood still at something that is not a person, the ONE person closest to
walking across her `give_way()`s and ambles off the other way instead. Only
one, and only the one actually heading toward her — a whole market turning on
its heel at the same moment looks absurd, and the point is that it should not
be noticeable. This is the real fix for people blocking a counter; the tap
damping below is the safety net for when one is already there.

`Zone.people_keep_clear` is a list of world rectangles where a person's tap
score is DAMPENED to 0.3 — the market fills it with each stall's button band.
Dampened, not zeroed: their body genuinely is in front of the button, so a tap
there should reach the stall, but a tap on their head is above the band and
still reaches them. The stall's own tap radius came down from 150 to 105 for
the same reason — at 150 it won the tap on a customer's own head.
