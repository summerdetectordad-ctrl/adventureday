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

var satchel: Array = []      # find kinds being carried, oldest first
var shelf: Dictionary = {}   # slot index (int) -> find kind
var muted := false

# Session-only flags (not saved).
var start_card_shown := false
var spawn_at_door := false
var berries_picked := 0   # gentle counting practice, wraps at 20


func _ready() -> void:
	randomize()
	load_game()


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


func move_on_shelf(from_slot: int, to_slot: int) -> void:
	if not shelf.has(from_slot):
		return
	var kind: String = shelf[from_slot]
	shelf.erase(from_slot)
	shelf[to_slot] = kind
	save_game()


func toggle_mute() -> void:
	muted = not muted
	Sound.set_muted(muted)
	save_game()


func save_game() -> void:
	var shelf_out := {}
	for slot in shelf:
		shelf_out[str(slot)] = shelf[slot]
	var data := {"satchel": satchel, "shelf": shelf_out, "muted": muted}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func load_game() -> void:
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
	shelf = {}
	var shelf_in: Dictionary = data.get("shelf", {})
	for key in shelf_in:
		shelf[int(key)] = shelf_in[key]


func _notification(what: int) -> void:
	# Save whenever the app is backgrounded or closed (tablet home button, etc.)
	if what == NOTIFICATION_APPLICATION_PAUSED \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT \
			or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
