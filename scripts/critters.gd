class_name Critters
## What the animals say, and what they can teach her. The companion to `Folk`:
## people have names and stories, animals have voices and facts.
##
## Talking to an animal used to end in a camera button and nothing else. Now
## the camera is a thing she carries in her hand, so an empty-handed chat is
## for LEARNING — she asks, and the animal tells her something true about
## itself. The photograph is a separate, deliberate act.
##
## READING: like Folk, every fact is a pair — [short, long] — picked by
## `GameState.reading_level`, so the setting changes how much she reads and
## never whether she can talk to an animal.

const ANIMALS := {
	"frog": {
		"hello": ["hello frog!", "hello frog, how are you today?"],
		"reply": "ribbit! i am good, thank you",
		"tells": [
			["i drink through my skin.", "i do not need to sip. i drink water right through my skin."],
			["i was a tadpole first.", "i started as an egg, then a tadpole with a tail, and then i grew legs."],
			["my long legs help me jump.", "my back legs are folded up like springs. that is how i jump so far."],
		],
	},
	"bird": {
		"hello": ["hello birds!", "hello birds, how is your nest?"],
		"reply": "tweet tweet! it is snug, thank you",
		"tells": [
			["my bones are hollow.", "my bones have air inside them. that makes me light enough to fly."],
			["we sing to say this is our tree.", "we sing in the morning to tell the other birds that this tree is ours."],
			["we build the nest with moss and mud.", "we weave moss, twigs and mud into a cup, then line it with soft feathers."],
		],
	},
	"butterfly": {
		"hello": ["hello butterfly!", "hello butterfly, you are so pretty"],
		"reply": "flutter flutter! thank you",
		"tells": [
			["i taste with my feet.", "i taste with my feet. i stand on a leaf to find out if it is a good one."],
			["i was a caterpillar.", "i was a caterpillar first. i made a case and came out with wings."],
			["my wings are tiny scales.", "my wings are covered in tiny scales, like the smallest roof tiles."],
		],
	},
	"owl": {
		"hello": ["hello owl!", "hello owl, are you sleepy today?"],
		"reply": "hoo hoo... a little bit",
		"tells": [
			["my feathers make me quiet.", "the edges of my feathers are soft and fluffy, so i fly without a sound."],
			["i can turn my head right round.", "i cannot move my eyes, so i turn my whole head instead — nearly all the way round."],
			["i can hear a mouse in the grass.", "one of my ears is higher than the other. that is how i find a mouse in the dark."],
		],
	},
	"indy": {
		"hello": ["hello indy!", "hello indy, good dog!"],
		"reply": "woof woof!",
		"tells": [
			["i smell much better than you.", "my nose is thousands of times better than yours. i can smell where you have been."],
			["my wet nose helps me smell.", "my nose stays wet on purpose. it helps me catch the smells in the air."],
			["i wag when i am happy.", "when i wag to the right i am happy. dogs really do that."],
		],
	},
	"star": {
		"hello": ["hello star!", "hello star, who is a good girl?"],
		"reply": "woof! me me me!",
		"tells": [
			["i hear sounds you cannot.", "my ears pick up sounds far too high for you to hear."],
			["i sweat through my paws.", "i cannot sweat like you. i pant, and i sweat a little through my paws."],
			["i dream when i twitch.", "when my paws twitch while i sleep, i am dreaming — probably about running."],
		],
	},
	"parrot": {
		"hello": ["hello parrot!", "hello parrot, can you say my name?"],
		"reply": "summer! summer! squawk!",
		"tells": [
			["i copy sounds i like.", "i copy the sounds i hear the most. that is how i learned your name."],
			["i hold my food in one foot.", "i can hold my food up in one foot, like you hold a sandwich."],
			["my beak is strong enough to crack a nut.", "my beak can crack a nut that you would need a tool for."],
		],
	},

	# --- Dino Land. She is meeting them, so they get to speak too. ----------
	"longneck": {
		"hello": ["hello longneck!", "hello longneck, how do you reach so high?"],
		"reply": "hello, small one!",
		"tells": [
			["i eat leaves all day.", "i eat leaves all day long. a body this big takes a lot of filling."],
			["my neck reaches the top leaves.", "my neck lets me eat the leaves at the very top, where nobody else can reach."],
			["i swallow stones to help my tummy.", "i swallow small stones. they sit in my tummy and help grind up the leaves."],
		],
	},
	"trike": {
		"hello": ["hello trike!", "hello trike, your horns are splendid"],
		"reply": "thank you! i am rather proud of them",
		"tells": [
			["i have three horns.", "i have three horns — two long ones over my eyes and a short one on my nose."],
			["my frill makes me look big.", "the big frill round my head makes me look bigger than i really am."],
			["i eat low plants.", "my beak is made for snipping tough low plants, not for chasing anybody."],
		],
	},
	"stego": {
		"hello": ["hello stego!", "hello stego, what are your plates for?"],
		"reply": "nobody is quite sure, you know!",
		"tells": [
			["my plates might keep me cool.", "the plates along my back may have helped me cool down, like a row of fans."],
			["my tail has four spikes.", "my tail has four long spikes on the end. i swing it if something bothers me."],
			["my head is quite small.", "my head is small for a body this size — about as big as a lunch box."],
		],
	},
	"compy": {
		"hello": ["hello little one!", "hello little one, you are quick!"],
		"reply": "chirp! yes i am!",
		"tells": [
			["i am about as big as a chicken.", "i am only about as big as a chicken, so i keep out of the way."],
			["being small means being fast.", "small means light, and light means fast. that is how i stay safe."],
			["birds are my cousins.", "birds came from dinosaurs like me. that makes a robin a sort of cousin."],
		],
	},
	"trex": {
		"hello": ["hello!", "hello, how are you feeling today?"],
		"reply": "rrrr... better now, thank you",
		"tells": [
			["my teeth are as long as your hand.", "my teeth are as long as your hand, and i grew new ones when they wore out."],
			["my nose was very good.", "i could smell things a very long way off — better than i could see them."],
			["my arms are little but strong.", "my arms look silly and small, but they were strong enough to lift you."],
		],
	},
}


static func has(who: String) -> bool:
	return ANIMALS.has(who)


## What she says to open, worded for how much she is reading.
static func greeting(who: String) -> String:
	var lines: Array = ANIMALS.get(who, ANIMALS["frog"])["hello"]
	return str(lines[1] if GameState.reading_level >= 2 else lines[0])


static func reply(who: String) -> String:
	return str(ANIMALS.get(who, ANIMALS["frog"])["reply"])


## Something true about itself, at her reading level.
static func something_to_tell(who: String) -> String:
	var tells: Array = ANIMALS.get(who, ANIMALS["frog"])["tells"]
	var pair: Array = tells[randi() % tells.size()]
	return str(pair[1] if GameState.reading_level >= 2 else pair[0])
