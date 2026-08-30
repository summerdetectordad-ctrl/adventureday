extends Node
## Autoload: Summer's affirmations. They appear on soft cards — one when the
## game opens, one each time a find is placed on the museum shelf, and any time
## the sunshine poster in the treehouse is tapped. Cards are meant to be read
## aloud together; the game never requires reading them (they dismiss on a tap
## anywhere, or fade away on their own).
##
## To add or change affirmations, just edit this list. "icon" must be one of
## the kinds in DrawKit.draw_icon.

const LIST := [
	{"text": "I am loved wherever I am.", "icon": "heart"},
	{"text": "My brain grows every time I practise.", "icon": "flower"},
	{"text": "Mistakes are how I learn.", "icon": "rainbow"},
	{"text": "My feelings are okay, and I can handle them.", "icon": "heart"},
	{"text": "I try things even when I feel a bit scared — that's brave.", "icon": "star"},
	{"text": "I am kind to people and animals.", "icon": "bird"},
	{"text": "I have a go first, then I ask for help.", "icon": "leaf"},
	{"text": "There is only one me, and that's brilliant.", "icon": "sun"},
	{"text": "I notice the good things around me.", "icon": "butterfly"},
	{"text": "A big deep breath helps me feel calm.", "icon": "cloud"},
]

var _bag: Array = []


## Shuffle-bag: every affirmation appears once before any repeats.
func next() -> Dictionary:
	if _bag.is_empty():
		_bag = LIST.duplicate()
		_bag.shuffle()
	return _bag.pop_back()
