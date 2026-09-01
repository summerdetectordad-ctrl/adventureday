class_name MiniGame
extends CanvasLayer
## Base for the mini-games dotted around the world. Each one opens on its own
## screen with a big exit button in the corner, exactly like the sketch pad, so
## there is never any doubt about how to get out.
##
## THE RULES, for every game:
##   - No timer, no score to lose, no way to be wrong twice in a row. A wrong
##     answer wobbles and asks again; it never takes anything away.
##   - It gets a step EASIER if she is finding it hard, and never harder
##     straight after a miss.
##   - It always finishes with something she can use — materials, fruit or a
##     find for the museum. Never nothing.
##   - Reading level comes from GameState.reading_level and only changes the
##     WORDING, never whether she can finish.

signal closed
## Something to take away: "stick"/"plank"/"rope"/"timber"/"paint"/"seed",
## "fruit", or "find:<kind>" for a museum piece.
signal rewarded(kind: String, n: int)

const PAPER := Color("fff8ec")
const INK := Color("6b4f38")
const SOFT := Color("a2917a")

var level := 1            ## copy of the reading level; may drift down in play
var misses := 0           ## wrong taps this session, for easing off
var _exit: IconButton = null


func _ready() -> void:
	layer = 41
	level = clampi(GameState.reading_level, 0, 2)
	_exit = IconButton.new("pack", 96.0)
	_exit.pressed.connect(func() -> void: closed.emit())
	add_child(_exit)
	_layout_exit()
	get_viewport().size_changed.connect(_layout_exit)
	build()
	# the way out is drawn LAST so a game can never cover its own exit button
	move_child(_exit, get_child_count() - 1)


## Games override this instead of _ready, so the exit button always exists.
func build() -> void:
	pass


func _layout_exit() -> void:
	if _exit == null:
		return
	var vs := get_viewport().get_visible_rect().size
	_exit.position = Vector2(vs.x - 120, 24)


## A wrong answer. Never punished — after two in a row the game quietly drops
## a step so the next one is easier.
func missed() -> void:
	misses += 1
	if misses >= 2 and level > 0:
		level -= 1
		misses = 0
	Sound.pop()


## A right answer. Never raises the level straight after a miss.
func hit() -> void:
	misses = 0
	Sound.chime_find()


func give(kind: String, n := 1) -> void:
	rewarded.emit(kind, n)


## The instruction line at the top of a game, worded for her reading level.
## At level 0 there are no words at all — the pictures do the talking.
func say(control: CanvasItem, pictures: String, words: String, sentence: String,
		at: Vector2) -> void:
	var text: String = [pictures, words, sentence][level]
	if text == "":
		return
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
	control.draw_string(font, at + Vector2(-w / 2.0, 0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 30, INK)


## The soft paper backdrop every game shares, so they feel like one family.
static func backdrop(control: CanvasItem, vs: Vector2, tint: Color) -> void:
	control.draw_rect(Rect2(Vector2.ZERO, vs), tint)
	DrawKit.rounded_rect(control, Rect2(16, 16, vs.x - 32, vs.y - 32), 20.0,
		Color(1, 1, 1, 0.28))


## A row of dots showing how many rounds are done — countable, no reading.
static func progress(control: CanvasItem, done: int, total: int, at: Vector2) -> void:
	for i in total:
		control.draw_circle(at + Vector2(i * 26.0 - (total - 1) * 13.0, 0), 9.0,
			Color("8fc48a") if i < done else Color(1, 1, 1, 0.55))
