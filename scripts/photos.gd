class_name Photos
## The real photographs Summer's camera takes. Wildlife and meadow shots come
## from Pexels (Pexels License — free to use and redistribute, no attribution
## required); Indy and Star are her own dogs. See photos/CREDITS.md.
##
## Everything else in the game is still code-drawn (DrawKit) — these are only
## the pictures inside the polaroid. If a subject has no photo, or a file is
## missing, DrawKit.draw_photo quietly falls back to the drawn version.

const DIR := "res://photos/"

## Photos on disk per subject, as "<subject>_<0..n-1>.jpg". Keep in step with
## the files — a count higher than the files present just yields null.
const COUNTS := {
	"frog": 6,
	"bird": 6,
	"butterfly": 6,
	"owl": 6,
	"meadow": 6,
	"indy": 2,
	"star": 2,
	# Dino Land. Extinct animals cannot be photographed, so these are the next
	# best thing: life-size models, park sculptures and museum skeletons. Same
	# Pexels licence as the wildlife shots.
	"longneck": 6,
	"trike": 5,
	"stego": 3,
	"compy": 3,
	"trex": 6,
	"dino": 5,
}

static var _cache := {}


## The photo for a "photo_<subject>_<v>" find, or null if there isn't one.
## v is the variation baked into the kind when the snap was taken, so a given
## find always shows the same picture — in the popup and on the museum shelf.
static func get_photo(subject: String, v: int) -> Texture2D:
	var n: int = COUNTS.get(subject, 0)
	if n <= 0:
		return null
	var path := "%s%s_%d.jpg" % [DIR, subject, posmod(v, n)]
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]


## The slice of a photo to show inside `pic`, cropped from the centre so it
## fills the frame without squashing.
static func crop_for(tex: Texture2D, pic: Rect2) -> Rect2:
	var ts := Vector2(tex.get_size())
	var want := pic.size.x / pic.size.y
	if ts.x / ts.y > want:
		var w := ts.y * want          # too wide — trim the sides
		return Rect2((ts.x - w) * 0.5, 0.0, w, ts.y)
	var h := ts.x / want              # too tall — trim top and bottom
	return Rect2(0.0, (ts.y - h) * 0.5, ts.x, h)
