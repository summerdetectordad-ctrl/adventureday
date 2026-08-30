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
- Shelf items can be rearranged but NEVER removed/lost. Satchel items are never lost.
- Zero binary assets. All art via `_draw()` (DrawKit), all audio procedural (sound.gd). Only non-text file is icon.svg.
- Education elements are optional garnish only; playability overrides everything.

## Architecture

Autoloads (order matters; declared in project.godot):
1. `GameState` (scripts/game_state.gd) — satchel/shelf/muted persistence; JSON at `user://adventure_day_save.json`. Format: `{"satchel": ["kind"...], "shelf": {"slotIndex": "kind"}, "muted": bool}`. Session-only (unsaved): `start_card_shown`, `spawn_at_door`, `berries_picked`.
2. `Sound` (scripts/sound.gd) — single AudioStreamGenerator mixer @22050 Hz. Detector tone: sine 180→720 Hz, amp 0.015→0.14 driven by `detector_active` + `detector_strength` (0..1) set each frame by main.gd. One-shot notes via `play_note(f0, f1, dur, amp, delay)`; effect wrappers: chime_find, chime_shelf, card_sound, pop, dig_sound, ribbit, chirp, woof, bell. Mute = bus 0 mute.
3. `Affirm` (scripts/affirmations.gd) — the 10 affirmations `{text, icon}`; `next()` is a shuffle-bag (no repeats until all shown). Icons must exist in `DrawKit.draw_icon`.

Scenes (both are one-node .tscn shells; everything built in `_ready()`):
- `scenes/main.tscn` → scripts/main.gd — the meadow.
- `scenes/museum.tscn` → scripts/museum.gd — treehouse interior.
- Transition: tap treehouse door / HUD door button → museum; museum door → meadow (`GameState.spawn_at_door = true`).

Shared classes (global class_name, one per file):
- `DrawKit` (drawkit.gd) — static draw helpers: rounded_rect(+outline/points), ellipse, star, heart; `draw_icon(kind)` for affirmation icons (heart/star/sun/flower/rainbow/bird/leaf/butterfly/cloud); `draw_find(kind)` for finds.
- `Fx` (fx.gd) — sparkles, hearts, float_number (all self-freeing tweens).
- `FindIcon` (find_icon.gd) — Node2D wrapper around DrawKit.draw_find; used for dug items, tray, shelf.
- `IconButton` (icon_button.gd) — round icon-only touch button (kinds: mute, satchel, dig, door).
- `Hud` (hud.gd) — CanvasLayer; mode "world" (satchel+mute+contextual dig/door) or "museum" (mute only). Signals: dig_pressed, door_pressed.
- `AffirmationCard` (affirmation_card.gd) — `AffirmationCard.show_card(hud_layer, Affirm.next())`; slides up, tap or 8 s to dismiss.
- `Player` (player.gd) — Summer; tap-to-walk `target_x`, keyboard (arrows/AD) for dev; facing via `fx` multiplier in _draw, NOT node scale.
- `Nature` (nature.gd) — inner classes: SkyBackdrop (Control on CanvasLayer -1; explicit size from viewport — anchors alone failed), WorldBG, MeadowTree, Treehouse (door_rect()), BerryBush, Pond, Frog, BirdTree, Bike, PicnicBlanket, Dog, Hole, HintSparkle. NOTE: do not name inner classes after native Godot classes (Sky/Tree caused parse errors).

Interactable pattern: node exposes `try_tap(world_pos) -> bool`; main.gd checks its `interactables` list before treating a tap as walk-to.

## World layout (main.gd)

WORLD_W 4200, GROUND_Y 600, viewport 1280x800 (canvas_items/expand). Camera child of player, offset (0,-200), limits 0..4200 x 0..800.
Positions: treehouse/door x=250, bike 430, bushes 1150/2200/3450, birdtree 1750, pond 2750, picnic 3720, deco trees 950/3100/3950. Buried finds: 6 concurrent, x 650..4050, min 260 apart, ≥220 from player on spawn; dig when within 80; tone range 520; hint sparkle fades in within 240. Dig → chime → satchel → respawn elsewhere (never runs out).

Find kinds + weights (GameState.FIND_TYPES, fossils/dino weighted highest): ammonite 4, dino_bone 4, dino_egg 3, trilobite 3, shark_tooth 3, roman_coin 2, pirate_coin 2, gem 1, old_key 1.

## Museum layout (museum.gd)

28 slots: 7 cols x 280..1000 step 120, 4 rows y 175/295/415/535 (shelf plank drawn at slot y+30). Tray (satchel contents) centred at y 716. Drag: press picks nearest item ≤48 px; release drops to nearest free slot ≤80 px, else returns. Tray→shelf placement: save + chime_shelf + sparkles + affirmation card. Shelf→shelf move: save + pop. Press+release moving <14 px = tap → WordTag (WORDS map, lowercase Year 1 words) instead of move. Poster tap (≤95 px of POSTER_CENTER (120,300)) → affirmation card. DOOR_RECT (1090,430,152,190) → exit.

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
```

Visual check: add temporary autoload script that waits, `get_viewport().get_texture().get_image().save_png(...)`, switches scene, captures again, quits (windowed, not headless). Remove the autoload + file afterwards; delete `%APPDATA%\Godot\app_userdata\Adventure Day\adventure_day_save.json` if the probe faked state. "ObjectDB instances leaked" on forced quit is benign.

## Code conventions

- Tabs, typed GDScript where cheap, `:=` inference.
- Dictionaries accessed with `["key"]` (not dot). Vector2 stored in a Dictionary must be copied out, mutated, written back.
- Facing flip via `fx := float(facing)` multiplier on x coordinates inside _draw.
- Self-freeing effects: tween chain ends in `tween_callback(queue_free)`.
- Colors as `Color("hex")`; palette: sky c3e2f2/eef7fb, grass 8fc48a/a8d5a2, dirt b9906b/a67c58, wood 8a6a52/c9a06c/a97e54, cream fff8ec, gold ffd98a, coral e8918c, slate 7a8b9c.
- No input map; keys polled directly (KEY_LEFT/RIGHT/A/D, SPACE/E context action).

## Android export (not yet configured on this machine)

JDK 17 + Android SDK + export templates (Editor → Manage Export Templates). Debug keystore ok for sideloading. `export_presets.cfg` is gitignored (holds keystore secrets) — recreate per machine, leave ALL permissions unchecked. Gradle build unnecessary for plain APK.

## Doc map

- AGENTS.md (this file) — canonical reference for AI agents; keep current when architecture/rules change.
- IDEAS.md — unbuilt inspiration backlog; append, don't build without being asked.
- README.md — human quickstart (setup/run/export).
- CLAUDE.md — pointer here.
