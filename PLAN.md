# PLAN.md — the build-out plan

**STATUS: BUILT.** All five phases are implemented, compiling and smoke-tested
across all four scenes. See §17 for what shipped, the decisions taken along the
way, and the handful of things deliberately left for later.

This file stays as the design reference for the treehouse arc. IDEAS.md remains
the loose backlog.

Everything below passes the invariants in AGENTS.md — no fail state, no
required reading, calm, offline, nothing collected is ever lost.

---

## 1. What the game becomes

Today the world is one 4,200 px meadow. The treehouse sits at x=250, the
museum is inside it, and building is a single tap on a sign that instantly
bumps `treehouse_level` 1 to 5. Materials collected are spent the moment you
can afford the next rung. There is no choice in it.

The plan turns the treehouse from a background prop into **the main
progression of the game**, and splits the world into places you travel
between.

```
  MARKET  <--signpost--  HOME GROVE  -->  THE MEADOW  --signpost-->  ADVENTURE LANDS
  (trade)                (build)          (gather)                   (dino / pirate)
```

**The core loop:**

1. **Gather** in the meadow — sticks, planks, rope, fruit, buried finds.
2. **Carry home** — materials land on a visible stock pile under the tree.
3. **Choose** at the plan table — what gets built next, and out of what.
4. **Watch it built** — Summer hammers it together, piece by piece.
5. **New space unlocks new play** — a kitchen to bake in, a deck to sit on,
   a bridge to a second tree, a lookout to see the next land from.

She starts with a bare platform in a tree. She can end up with a mansion
spanning two trees, joined by rope bridges, with a garden below and a
telescope on the roof.

---

## 2. Guard rails

These are the constraints every mechanic below is designed around. They are
easy to break by accident, so they are written out.

| Guard rail | What it means for building |
|---|---|
| **No fail state** | Materials are infinite and respawn forever. You can never be short of anything permanently, never lose a build, never take a wrong turn. |
| **Hunger and thirst never punish** | They are *invitations*, not penalties. An empty meter makes a friendly bubble appear, nothing more. No slower walking, no stopped play, no sad face. |
| **No required reading** | Every build choice is a picture plus a count. Words appear as optional garnish, the way the museum word tags already do. |
| **Nothing collected is ever lost** | Museum finds are **never** currency. Trading uses fruit, which regrows. |
| **Safe to quit at any instant** | A build is committed the moment it is chosen, not when the animation finishes. |
| **No dead ends** | The build tree has an order, but nothing is ever mutually exclusive. Everything is eventually buildable. |
| **No punishing timers** | Nothing decays while she is away. Coming back after a week is exactly as good as coming back tomorrow. |
| **Big targets** | Build spots are at least 80 px, comfortably tappable by a five-year-old thumb. |

---

## 3. The building system

### 3.1 Why deferred building is the right call

Instant building is the weakest part of the current design: the material and
the reward are the same moment, so neither lands. Splitting them gives three
things a young child reads clearly — **anticipation** (I can see the pile
growing), **agency** (I chose this), and **ceremony** (I watched it happen).

This is the loop that makes *Animal Crossing*, *Stardew Valley* and
*Spiritfarer* work: you commission a thing at a station, and it becomes real
as an event you witness.

### 3.2 The stock pile

At the foot of the home tree, a **visible pile of materials**. Not a number
in a menu — an actual heap of sticks, a stack of planks, a coil of rope, that
physically grows as she collects.

- Each material collected in the meadow flies home and lands on the pile
  (the existing fly-to-sign animation, retargeted).
- The pile's drawn size steps up at thresholds, so progress is visible from
  across the screen.
- Tapping the pile makes Summer count it — numerals pop above each stack.
  This is the counting practice, and it is optional.

**Why it matters:** it makes the abstract concrete. She does not have to
remember she has seven planks; she can see seven planks.

### 3.3 The plan table

A small workbench beside the tree with a plan pinned to it, replacing the
current BuildSign. Tapping it opens the **build board**.

This is the "return to the treehouse" the whole system hinges on. Materials
found anywhere in the world only become *building* here.

### 3.4 The build board

A full-screen panel (same furniture as the backpack ring and drawing suite —
`CanvasLayer`, tap outside to close) showing a picture of the treehouse as it
stands right now, with **glowing build spots** on and around it.

- Every spot is a plus badge on the part of the tree it would occupy — a spot
  on the trunk for the ladder, one to the left for the deck, one above for the
  next storey.
- Tapping a spot shows what it would be: a **ghost preview** drawn in place,
  translucent, plus its cost as icons and a numeral.
- Affordable spots pulse gently. Unaffordable ones are still tappable and
  still show their preview — they just wiggle instead of building, exactly as
  the sign does today. **Seeing what is coming is half the fun.**
- A row of tabs switches track: Structure / Access / Extension / Comfort /
  Decoration.

### 3.5 The build animation

Never instant. On confirm:

1. Board closes, camera eases to the tree.
2. Summer walks over, `player.build()` — the existing mallet swing.
3. Pieces fly in from the stock pile and snap into place, one at a time, with
   a knock per piece (the existing four-knock sequence, extended).
4. Sawdust puff, a soft chime, the new part settles with a `TRANS_BACK` bounce.
5. Affirmation card.
6. A **photo of the treehouse is taken automatically** and added to the
   satchel — so the museum ends up with a before-and-after wall of every
   stage. Photos already work, so this is nearly free.

Target: 4 to 6 seconds. Long enough to feel earned, short enough to want again.

### 3.6 Material tiers — "better material"

Most built parts can be **upgraded in place** without changing shape. The
same deck, in a better material, is a real and very readable upgrade.

| Tier | Material | Look | Source |
|---|---|---|---|
| 1 | Sticks and twine | Rough, gappy, bark still on | Meadow, everywhere |
| 2 | Planks | Straight, sanded, even edges | Meadow, common |
| 3 | Good timber | Thick beams, joints, trim | Market (trade fruit) |
| 4 | Painted | Any colour she picks | Market (paint pots) |

Tier 4 is the sweetheart feature: **she chooses the colour**, using the
palette from the drawing suite she already loves. Her treehouse ends up the
colour she decided.

### 3.7 No wrong choices

Order is a preference, never a mistake. The only hard rule is physical: a
second storey needs a first, a bridge needs both trees to have a platform.
Everything else can be built in any order, and everything is affordable
eventually. There is no build that closes off another.

---

## 4. The build tree

Five tracks. Structure is the spine and gates the rest; the other four are
free-form.

### Structure — the spine

| # | Build | Needs | Unlocks |
|---|---|---|---|
| 1 | **Platform** (start state) | — | The tree is climbable |
| 2 | **Cabin walls and roof** | plank 4, stick 3 | Interior: the museum room |
| 3 | **Second storey** | plank 6, rope 3 | Interior: kitchen |
| 4 | **Tower room** | timber 4, plank 4 | Interior: art room |
| 5 | **Mansion roof and gables** | timber 6, paint 2 | The finished silhouette |

### Access — how she gets up

| Build | Needs | Notes |
|---|---|---|
| **Rope ladder** | rope 2, stick 3 | Start state; sways as she climbs |
| **Wooden stairs** | plank 4 | Faster climb, no sway |
| **Spiral staircase** | timber 5 | Wraps the trunk, lovely to watch |
| **Bucket lift** | rope 4, plank 2 | She rides it. Children love this. |
| **Slide to the ground** | timber 3, paint 1 | Pure joy, no utility, build it anyway |

### Extension — outward

| Build | Needs | Notes |
|---|---|---|
| **Front deck** | plank 3 | Somewhere to sit; dogs nap here |
| **Side deck** | plank 3 | |
| **Wrap-around balcony** | plank 5, rope 2 | Joins both decks |
| **Rope bridge** | rope 5, plank 4 | **To the second tree** |
| **Second tree platform** | plank 4, stick 3 | A whole new build site |
| **Crow's nest** | timber 3, rope 2 | Highest point in the game |
| **Zip line down** | rope 6 | Second tree to meadow, one-way, brilliant |

### Comfort — interior purpose

| Build | Needs | Unlocks |
|---|---|---|
| **Museum shelves** | plank 3 | (exists today) |
| **Kitchen** | plank 4, timber 2 | **Fruit pies** |
| **Art room** | plank 3, paint 1 | Her drawings framed on the walls |
| **Den and cushions** | rope 2, plank 2 | Where the dogs sleep |
| **Telescope** | timber 2, rope 1 | See the next land from the tower |

### Decoration — cheap, frequent, joyful

Each costs one or two materials. These exist so there is **always** something
affordable to build, which means the plan table is never a disappointment.

Bunting, flower boxes, wind chime, name sign, painted door, lantern, weather
vane, letterbox, welcome mat, bird box, hammock, tyre swing, pet bowls, plant
pots, a flag.

### The second tree

The single most exciting unlock. A second tree stands a short way from the
first, visibly empty from the start — **she can see it long before she can
reach it**, which is the whole trick. The rope bridge is expensive on purpose.

Once crossed, the second tree runs its own miniature build tree (platform,
cabin, crow's nest), and the two together make the mansion silhouette.

---

## 5. The home grove

The first stretch of the world becomes **almost entirely about the treehouse**.

| x | What is there |
|---|---|
| 40 | Signpost west to **the market** |
| 150–350 | Home tree, stock pile, plan table, ladder |
| 450–700 | Second tree (empty until bridged) |
| 750–950 | Garden patch, water butt, wheelbarrow |
| 1000+ | The meadow proper begins — gathering country |
| 4160 | Signpost east to **the adventure lands** |

The grove is calm and safe: no digging, few distractions, everything here is
about looking at what she has made. This is where a session starts and ends.

---

## 6. Materials and trade

**Found in the meadow** (infinite, respawning): stick, plank, rope, fruit.

**Traded at the market** (barter with fruit): timber, paint, seeds, pie tins.

Fruit is the currency, and this matters: **museum finds are never spent.**
Coins she digs up are treasures, not money. Fruit regrows, so trading can
never cost her anything she cannot get back.

Trades are shown as a picture swap, so no numbers are required to understand
it: three strawberries on the left, one plank on the right.

---

## 7. The top bar

Counters across the top, as asked. Landscape 1280x800 leaves plenty of room.

```
+--------------------------------------------------------------+
| [satchel]  fruit 12   stick 7  plank 3   [thirst]  [hunger]  [mute] |
+--------------------------------------------------------------+
```

- **Fruit** — running count, pulses when it goes up.
- **Materials** — stick / plank / rope as one grouped pill; tap it to expand
  into the full breakdown.
- **Thirst** — the existing five-minute `THIRST_SECONDS` timer, finally made
  visible instead of only appearing as a bubble.
- **Hunger** — slower, roughly ten minutes.

**The safe design for meters.** When a meter empties, exactly one thing
happens: a soft bubble appears over Summer suggesting a drink or a snack, and
the counter glows gently. Nothing else. She does not slow down, nothing is
taken away, no sad expression, no sound sting. Drinking or eating refills it
with a sparkle and a small affirmation.

The meters exist to *suggest a nice thing to do*, never to nag. If they ever
start to feel like homework, they should be turned off — and there should be
a switch to do exactly that.

---

## 8. Food

### The sandwich game gets an Eat button

A big **Eat** button in the sandwich game. Tapping it closes the minigame and
plays the payoff:

1. Summer walks to the picnic blanket.
2. She sits down — a new seated pose.
3. Three bites, crumbs, a happy wiggle between each.
4. Hunger refills, hearts float up, affirmation card.
5. If the dogs are out, one of them gets the last bite.

The sandwich she actually built is the sandwich she eats — the stack she made
is drawn in her hands.

### Fruit pies

The kitchen (Structure 3) unlocks baking, which gives fruit a second purpose
beyond trading.

1. Fruit from the top-bar counter goes into a pastry case — drag and drop, any
   combination works.
2. Tap to crimp the edges.
3. Into the oven; a short, watchable bake with a warm glow and rising curls of
   steam.
4. The pie cools on the windowsill, then can be eaten or shared.

No recipe is wrong. A pie of nine strawberries is a fine pie.

---

## 9. The market

West of the home grove, reached by tapping the signpost. A short, cheerful row
of stalls under striped awnings.

| Stall | Trades for | Why it exists |
|---|---|---|
| **Timber yard** | Good timber, beams | The tier-3 material |
| **Paint stall** | Paint pots, any colour | The tier-4 material |
| **Seed stall** | Seeds for the garden | Long-running growth to come back to |
| **Baker** | Pie tins, pastry | Feeds the kitchen |
| **Craft stall** | Bunting, lanterns, chimes | Cheap decorations |

Stallholders wave, say hello in the existing dialogue-card style, and never
run out of stock. Nothing is ever unavailable.

---

## 10. The adventure lands

East signpost. **Build Dino Land first** — AGENTS.md records that Summer is
dinosaur- and fossil-obsessed, and the museum already fills with fossils, dino
bones and dino eggs. It is the strongest possible payoff for the collection
she is already building.

**Dino Land** — bigger bones half-buried in rock, a fossil dig wall she can
brush clean layer by layer, friendly long-necks that lower their heads to be
patted, a volcano that puffs but never erupts, footprints she can follow.

**Pirate Cove** — second. Rock pools, a wreck, a rowing boat, a treasure map
that assembles from pieces, a parrot that repeats her whistle, sand to dig.

Both are separate scenes, exactly like `museum.tscn` — the pattern already
works, and it keeps each zone's memory and load time bounded.

---

## 11. Landscape and Android

**It is already landscape-locked.** `project.godot` has
`display/window/handheld/orientation=4`, which is *sensor landscape* — the
game will only ever run in landscape, but it flips between the two landscape
orientations depending on how the tablet is held.

**Recommendation: keep 4, do not change it to 0.** Value 0 pins one specific
way up, so turning the tablet round leaves the game upside down — annoying on
a device with an off-centre charging port, and children rotate tablets
constantly. Sensor landscape is the hard landscape lock you are asking for; it
just stays the right way up.

Other Android notes for when the top bar lands:

- Keep the counters clear of the top corners — tablet front cameras and
  rounded corners eat those, and gesture bars eat the bottom edge.
- `window/stretch/aspect="expand"` means real tablets are wider than 1280x800;
  anchor the top bar to the viewport, do not hard-code x positions.
- Photos added about 2.4 MB to the APK. A market and two new zones with photos
  could add 10 to 20 MB. Still small, but worth watching.

---

## 12. Technical notes

**Save migration.** `treehouse_level` (1 to 5) becomes a set of built parts.
Old saves must keep working: map level *n* to the first *n* Structure builds
and grant the decorations that were implied. Load must default every new key,
and never throw away an unrecognised one.

Proposed shape:

```json
{
  "built": ["platform", "cabin", "ladder_rope", "deck_front"],
  "tiers": { "deck_front": 2 },
  "paint": { "door": "e8918c" },
  "materials": { "stick": 7, "plank": 3, "rope": 2, "timber": 0, "paint": 0 },
  "fruit": 12,
  "hunger": 0.0,
  "thirst": 0.0
}
```

**New classes**, following the existing one-class-per-file convention:
`BuildBoard` (the panel), `StockPile`, `PlanTable`, a `Treehouse` rework that
draws from the built set rather than a level integer, `TopBar`, `MarketScene`,
`PieGame`.

**The treehouse drawing** is the biggest single job. It currently switches on
one integer; it needs to compose from a set of parts, each drawn in its tier's
material. Worth doing carefully — everything else depends on it.

**Watch the draw transform gotcha** already recorded in AGENTS.md: build
previews will be drawn nested inside a tilted board, which is exactly the
situation that broke the photo card.

---

## 13. The learning layer

Optional garnish only, per the invariants — never a gate, never a quiz.

- **Counting** — tapping the stock pile counts it out; build costs show dots
  *and* numerals.
- **Comparing** — "you have 7, you need 4" as two visible rows, not a sum.
- **Sequencing** — pie baking is first / next / last, told through pictures.
- **Trading** — the market is early addition and subtraction, made physical.
- **Colour and shape** — choosing paint, matching timber shapes to slots.
- **Words** — build names on the plan table as optional tags, in the same style
  as the museum's word tags.

Every one of these is skippable by simply not tapping it.

---

## 14. Roadmap

Ordered so that each phase is independently enjoyable — you can stop after any
of them and the game is better than before.

**Phase 1 — the building core.** Stock pile, plan table, build board, ghost
previews, build animation, the Structure and Access tracks, save migration.
*This is the phase that changes the game.*

**Phase 2 — the top bar.** Fruit and material counters, thirst made visible,
hunger, the Eat button and the sitting-and-eating animation.

**Phase 3 — the home grove.** Zone restructure, second tree, rope bridge,
Extension track, decorations.

**Phase 4 — the market.** Signpost travel, stalls, barter, timber and paint,
material tiers, the kitchen and fruit pies.

**Phase 5 — Dino Land.** A whole new zone, once the pattern is proven.

---

## 15. Thirty quick wins

Small things, mostly a few dozen lines each, that would noticeably improve the
game. Ordered roughly by impact per unit of effort.

| # | Idea | Why it is worth it |
|---|---|---|
| 1 | **Name sign on the treehouse** — her name on a carved plank | It becomes *hers*. Highest impact per line of code in this list. |
| 2 | **Auto-photo at each build stage** | Free — photos already work. Builds a before-and-after wall in the museum. |
| 3 | **Dogs nap on the deck** once it is built | Makes a built thing visibly *used*, not just present. |
| 4 | **Tap the stock pile to count it** | Counting practice that costs almost nothing. |
| 5 | **Ghost preview of the next build**, always faintly visible on the tree | Anticipation. She will aim for it. |
| 6 | **A slide from the deck to the ground** | Pure joy, no utility. Children will use it a hundred times. |
| 7 | **Bucket lift she can ride up** | Same reason. Transport is a toy. |
| 8 | **Shake fruit trees** to make fruit drop | Turns fruit from a pickup into an action. |
| 9 | **Footprints in the dirt** behind her, fading | Tiny, atmospheric, makes the world feel touched. |
| 10 | **Wind chime** on the deck, soft note on tap | Ties into the existing procedural audio. |
| 11 | **Bunting between the two trees** | Cheap decoration that reads as "someone lives here". |
| 12 | **Letterbox** with an occasional drawing inside | A reason to come home. |
| 13 | **Chalkboard by the door** showing the next build in pictures | Reading-free goal-setting. |
| 14 | **Milestone confetti** at the 10th and 20th find | Already in IDEAS.md; safe, gentle celebration. |
| 15 | **Telescope shows the next zone** as a parallax card | Sells the adventure lands before they exist. |
| 16 | **Signposts wobble and point** when tapped | Makes travel legible without words. |
| 17 | **Rope bridge sways** as she crosses | The single best-feeling thing on this list. |
| 18 | **Ladder rungs light up** as she climbs | Small, satisfying, guides the eye. |
| 19 | **Pie cooling on the windowsill** after baking | Persistence you can see from outside. |
| 20 | **Dogs beg for a bite** of pie or sandwich | Makes eating social. |
| 21 | **Flower boxes** that bloom over sessions | Slow reward for coming back. |
| 22 | **Hammock** on the deck she can lie in | A place to do nothing. Calm games need one. |
| 23 | **Bird box** on the tree; a bird moves in | Ties to the existing nest idea in IDEAS.md. |
| 24 | **Evening fireflies** after a long session | Already in IDEAS.md; cheap and lovely. |
| 25 | **Paint the door** any colour from the drawing palette | First taste of tier-4 material. |
| 26 | **Weather vane** that turns with a drifting breeze | Ambient motion is what makes a scene feel alive. |
| 27 | **A cat on the roof** that appears occasionally | Surprise without stakes. |
| 28 | **Welcome mat** she can jump on for a squeak | Silly. Children love silly. |
| 29 | **Stepping stones** across the pond | New traversal from almost no code. |
| 30 | **Puddles that splash** after rain | Sells weather with one interaction. |

---

## 16. Questions

1. **Dino Land or Pirate Cove first?** The evidence points hard at Dino Land.
2. **How big should the mansion get?** Two trees and four storeys, or should it
   keep going — a third tree, a ground-floor workshop?
3. **Hunger: in or out?** Thirst already exists and is gentle. Hunger adds a
   second meter and a second nag risk. It could stay purely a bonus (eating is
   nice) rather than a meter that empties.
4. **Should the market cost anything at all?** Free stalls are calmer;
   bartering is better practice. This plan assumes bartering with fruit.
5. **How much should be visible from the start?** This plan assumes the second
   tree is visible immediately and the bridge is expensive — the wanting is the
   point.

---

## 17. What was built

All five phases, plus the decisions taken where the plan left a gap.

### Answers taken from you

- **Dino Land first** — built. Pirate Cove is still unbuilt (§10).
- **Third tree + ground workshop** — both built, so the mansion runs across
  three trees with a workshop at the foot of the home tree.
- **Gentle meters, always on** — thirst and hunger both sit in the top bar with
  no off switch, exactly as asked.
- **Barter with fruit** — the market takes fruit and nothing else. Museum finds
  are never spendable.

### Decisions I took without asking

- **Q5, how much is visible from the start:** the second and third trees stand
  visibly empty from the first session, and the bridges are expensive. The
  wanting is the point.
- **The bridge appears the moment it is built,** before the far tree has a
  platform — walking over to a bare tree is the invitation to build on it.
- **The workshop moved to the far left** of the home tree (local -320..-212) so
  the bucket lift, stairs and plan table all have room.
- **Storeys were compressed** (cabin -340, storey2 -420, tower -488) so the
  finished mansion still fits on screen with her stood at the foot of the tree.
- **The home grove grew to x 0..1500** — the original spacing put the workshop
  through the plan table. Meadow furniture moved east to match; digging and
  material spawns now start at GROVE_END_X, so the grove stays calm.
- **`painted_door` picks a cheerful colour for her** when built, rather than
  opening a colour picker for a one-material decoration. The tier-4 upgrade on
  bigger parts is where she chooses a colour properly.
- **The pie is eaten in the kitchen**, not carried outside — she is already
  indoors, and walking her down the tree to sit on the grass felt worse.

### Phase by phase

| Phase | What shipped |
|---|---|
| **1 — building core** | `BuildDefs` (42 parts, 5 tracks), `Treehouse` rebuilt to draw from a part set, `StockPile`, `PlanTable`, `BuildBoard` with real translucent ghost previews, the fly-the-pieces build animation, save v2 + migration from `treehouse_level` |
| **2 — top bar** | `TopBar` with fruit, materials, thirst, hunger; the Eat button; the sitting-and-eating pose with the sandwich she actually made, shrinking bite by bite |
| **3 — home grove** | Three trees, rope bridges that sag under her feet, the Extension track, 16 decorations, signposts |
| **4 — market** | `market.tscn`, five stalls, fruit barter, timber and paint, material tiers 1–4, the kitchen and `PieGame` |
| **5 — Dino Land** | `dino_land.tscn`, brush-away fossil walls, long-necks that lower their heads, a volcano that only puffs, footprint trails |

### Quick wins done

1 name sign · 2 auto-photo each build · 4 tap-the-pile counting · 5 ghost
preview · 6 slide · 7 bucket lift · 8 shake fruit trees · 9 fading footprints ·
10 wind chime · 11 bunting · 12 letterbox · 13 chalkboard · 14 milestone
confetti · 15 telescope far-view · 16 signposts wobble · 17 swaying rope
bridge · 19 pie cooling on the sill · 20 dogs beg for a bite · 21 flower boxes ·
22 hammock · 23 bird box · 24 evening fireflies · 25 painted door · 26 weather
vane · 27 roof cat · 29 stepping stones

### Left for later, and why

> **All of this was subsequently built** (2026-08-31), along with the shelf
> curation fix below. Kept here as the record of what was deferred and why.


- **#3 dogs nap on the deck** — needs the dog follow-AI reworked. The dogs do
  beg for a bite when she eats (#20), which covers the same warmth for now.
- **#18 ladder rungs light up / #28 squeaky mat / #30 puddles** — pure polish,
  none of them load-bearing.
- **The slide, bucket lift and zip line are drawn but not rideable.** Riding
  them means new player movement states next to the vine code, which is the
  most delicate part of player.gd. They read as part of the house today.
- **Pirate Cove** — Dino Land came first, as agreed.
- **Seeds and the garden** — the garden patch grows with her fruit count, but
  the seed stall does not yet plant anything.
- **Dino Land uses the meadow background.** It reads as a green valley rather
  than a prehistoric one; giving `Nature.WorldBG` a palette parameter would fix
  it and is worth doing before Pirate Cove needs sand.

---

## 18. Second pass — the deferred list, and the shelf

Everything §17 left for later is now built, plus one real gap found in play.

### The shelf could fill up with no way to curate it

Reported from actual play: the shelves filled and nothing could be taken off.
The invariant says finds are never lost, which had been read as "never leaves
the shelf" — but that made the museum impossible to arrange once full.

Resolved without weakening the rule: **there is still no bin.** A find now
moves freely in *both* directions between the basket and the shelf — drag it
up to display it, drag it back down into the basket to take it off. The basket
lights up while she is carrying something down, so the gesture is discoverable.
It holds any number, nine at a time with page arrows and a dot per page.
Shelf rooms now also grow with every storey she builds, up to five rooms and
140 display spots.

### The rest of the deferred list

| Was deferred | Now |
|---|---|
| Slide, bucket lift, zip line drawn but not rideable | **Rideable.** A general `Player.ride(path, seconds, pose)` state, reusing the poses that already existed. The rope ladder and lift carry her up; the slide and zip line bring her down. |
| The treehouse was scenery you could not stand on | **The platform, decks and bridges are one-way floors.** She can climb up, walk out along a deck, cross a bridge to the second tree and slide back down. This is what makes the building pay off. |
| Dogs napping on the deck | **Built.** The dogs follow her up onto the decks and, once she has been still a few seconds, curl up and doze with little zeds. |
| Seeds and the garden | **Built.** A seed stall at the market; tap the patch to sow, it grows while she plays, and a grown patch is picked for three fruit a row. |
| Dino Land used the meadow background | **Fixed.** `WorldBG` takes a palette — meadow, dino (dry gold) and cove (sand) — including how much grass and flower cover to draw. |
| Pirate Cove | **Built.** Sand digs holding four map pieces, rock pools, a parrot that copies her, a wreck, and a chest that appears once the map is whole. Reached onward from Dino Land. |
| Quick wins 18, 28, 30 | **Built.** Rungs light under her as she climbs, the welcome mat squeaks when she lands on it, and puddles splash. |

### Still open

- **Pirate Cove has no second visit hook.** Once the chest is open the map
  stays finished; it wants something that renews, the way the meadow's finds
  do. The rock pools give two finds and then a waving crab.
- **The distant hills stay green in every zone** — they live on the sky layer,
  which the palette does not reach yet.

---

## 19. Mini-games and reasons to return — UNBUILT

Design only. Nothing in this section is built yet.

### Who is this game actually for?

**Reception to Year 2 — ages 4 to 7.** A three-year band, not a six-year one.

| Year | Age | How it lands |
|---|---|---|
| Nursery | 3–4 | Too fiddly. Drag-and-drop and the double-tap jump need more control than this. |
| **Reception** | **4–5** | Plays it as a toy: building, photos, digging. Games must be picture-only. |
| **Year 1** | **5–6** | The target. Phonics blending, number bonds to 10, repeating patterns — exactly the curriculum. |
| **Year 2** | **6–7** | Still loves the building and collecting, but needs a harder tier in the games or gets bored. |
| Year 3+ | 7+ | Too gentle. No amount of difficulty tuning fixes that. |

Summer sits in the middle of the band, which is the right place to design from.

### The sign-up question

**Don't ask for gender.** It says nothing about reading level, and it is an odd
thing to put in front of a child on the first screen.

**Don't gate on age either.** An age gate implies there is a wrong answer, in a
game whose whole premise is that there isn't one.

Instead, one parent-set control in the settings corner beside mute:

| Setting | Year | What changes |
|---|---|---|
| **Pictures** | Reception | No words anywhere in the games. Sounds and pictures only. |
| **Words** | Year 1 (default) | Simple CVC words, phonics, numbers to 10. |
| **Sentences** | Year 2 | Longer words and digraphs, numbers to 20, two-step problems. |

Local setting, no account, no data leaves the tablet. On top of that, each game
drifts one step easier if she is struggling and **never gets harder straight
after a miss** — invisible, and consistent with no fail state.

### The five games

Each opens on its own screen with a big exit button, exactly like the sketch
pad. No timers, no scores to lose, no way to get it wrong twice in a row.

**1. Walk the Plank** — *Pirate Cove*
Planks float between the beach and the wreck, each with a sound on it. The
parrot squawks a word; she taps the planks in order to build it and walks
across. A wrong plank wobbles and the parrot says the word again — she never
falls in, and the plank stays put.
*Learning:* phonics blending, the single biggest Year 1 skill.
*Reward:* gold coins for the museum, and a map piece.

**2. Bone Builder** — *Dino Land*
A faint skeleton outline on the rock wall and a pile of bones on the sand. Drag
each bone to its silhouette; it snaps home when close and drifts back if it is
not the one. Then line the finished skeletons up smallest to biggest.
*Learning:* shape and spatial matching, size ordering, real dinosaur names as
optional labels.
*Reward:* the assembled skeleton goes on a museum shelf, plus timber.

**3. Market Stall** — *the Market*
She runs a stall instead of buying from one. A customer asks for three apples
and two plums, shown as pictures and numerals; she fills the basket and the
till shows the total.
*Learning:* counting, number bonds to 10 then 20, addition.
*Reward:* fruit, and a free pick from any stall.
This one earns its place: it is the barter she already does, turned round.

**4. Pattern Patch** — *the garden, home grove*
A row of flowers in a repeating pattern with one gap. She picks the flower that
belongs. Then she plants her own pattern along the row and it stays there.
*Learning:* repeating patterns and sequencing — core Reception/Year 1 maths and
the real foundation for algebra.
*Reward:* seeds and fruit. Gives the garden a reason to exist beyond sowing.

**5. Memory Museum** — *inside the treehouse*
Cards face-down on a spare shelf, using **her own photographs and finds** as the
faces. Turn two, find a pair; the word tag shows on a match.
*Learning:* working memory, visual discrimination, vocabulary.
*Reward:* building materials — the direct feed back into the treehouse.
It grows with her collection, so it is a different game every few sessions
without anyone writing new content.

### Reasons to return

The games are the main one, but each area needs its own pull:

| Area | Why come back |
|---|---|
| **Pirate Cove** | Rock pools refill with the tide; the plank puzzle is new each visit. |
| **Dino Land** | Dig walls re-bury over time; a new skeleton to assemble. |
| **The Market** | Stock rotates, so there is always something different on the counter. |
| **The garden** | Crops finish growing; a new pattern to solve. |
| **The treehouse** | Memory Museum grows with the collection; post arrives in the letterbox. |

**No daily locks.** Nothing should ever tell a five-year-old to come back
tomorrow — things refresh on play time, not the calendar.

---

## 20. The five mini-games — BUILT

All five from §19 are in, plus the reading-level control they read from.

| Game | Where | Learning | Reward |
|---|---|---|---|
| **Walk the Plank** | Pirate Cove | phonics, letter order | a pirate coin + fruit |
| **Bone Builder** | Dino Land | shape and spatial matching | a dino bone + timber |
| **Market Stall** | the Market | counting, number bonds, addition | fruit + a material |
| **Pattern Patch** | the garden | repeating patterns, sequencing | seeds + fruit |
| **Memory Museum** | the treehouse | working memory, vocabulary | building materials |

Each opens on its own screen with a big exit button, exactly like the sketch
pad. None is timed or scored. A wrong answer wobbles and asks again, and after
two in a row the game quietly drops a level — it never gets harder straight
after a miss.

**Finding them.** One marker, a ring of little stars, used at every game in
every world — deliberately different from the chevron markers that mean "ride
this". Learn it once, find them all.

**The reading level** is a button beside mute: pictures (Reception), words
(Year 1, the default), sentences (Year 2). It only changes the WORDING of a
game. No age gate and no sign-up — and no gender question, which would tell us
nothing about reading level anyway.

### Still open

- **Memory Museum leans on her collection.** With very few finds it falls back
  to the classic fossils, so early games repeat more than later ones.
- **Walk the Plank shows the word she is building.** That makes it letter-order
  practice rather than pure blending. Pure blending needs a picture for every
  word, which needs more drawn icons than DrawKit has.
- **No game yet renews a reason to return to Pirate Cove** once the chest is
  open — the plank game is new each visit, but the cove's own thread is done.
