# Adventure Day

Calm 2D game for Summer. She explores a meadow with a backpack full of
adventures: the metal detector (a soft tone rises near buried finds — dig up
fossils, dino bones, Roman coins and pirate treasure for the treehouse
museum), a butterfly net, a camera that takes real photographs of what she points it
at (frogs, robins, butterflies, owls, the meadow — and Indy and Star
themselves), a whistle that calls
Indy and Star running in as a surprise, a water bottle, a sketch pad that
opens a full drawing suite anywhere, a map of the meadow, and a picnic that
opens a sandwich-tower building game. She jumps over crates, rocks and logs,
swims across the pond, swings on vines and launches off them onto lookout
perches, and has polite little chats with the frogs, birds, butterflies and
dogs. Affirmations appear on soft cards: at start-up, when a find is
shelved, and when the sunshine poster is tapped.

Godot 4 (GDScript, standard build — not .NET). Sideloaded Android APK.
No ads, no purchases, no accounts, no analytics, no internet permission,
no fail state, no reading required.

Project docs: [AGENTS.md](AGENTS.md) (canonical reference),
[IDEAS.md](IDEAS.md) (backlog).

## Controls

- Touch: tap to walk; double-tap to jump that way (above her head = straight
  up). Tap Summer to open her backpack of items: metal detector, butterfly
  net, camera, whistle (calls/sends the dogs), sketch pad, map, water
  bottle, picnic. Big shovel button to dig (detector must be out). Walk into
  the pond to swim. Jump near a hanging vine to grab it — tap above/below to
  climb, tap beside her to swing, double-tap to launch off toward the tap
  (onto the lookout perches!). Tap far-away things and she walks over first:
  berries get picked, animals get a friendly chat with a camera button to
  photograph them. Tap the treehouse door for the museum; drag finds from
  the basket onto any shelf spot; tap a shelved find to see its word.
- Keyboard (dev): arrows or A/D to walk; Up/W to jump; Down/S to climb down;
  Space/E to dig or enter (or let go of a vine).
- Mute: top-right button; persists.

## Run it

Already set up on this laptop: Godot 4.3 lives in `C:\Godot\`, and the
**Adventure Day** shortcut on the desktop launches the game straight into the
meadow — no editor, just double-click. To open the editor instead, run
`C:\Godot\Godot_v4.3-stable_win64.exe` on its own.

On a fresh machine:

1. Godot 4.x **standard** build from godotengine.org (zip, single exe —
   extract to `C:\Godot\`).
2. Project Manager → Import → this folder's `project.godot` → Edit.
3. F5.

Save file: `user://adventure_day_save.json`
(Windows: `%APPDATA%\Godot\app_userdata\Adventure Day\`). Delete to reset.

## Android export

One-time: JDK 17; Android SDK (via Android Studio or cmdline-tools);
Editor → Manage Export Templates → Download (~1 GB); Editor Settings →
Export → Android → set JDK + SDK paths; Project → Export → Add → Android →
Keystore: Debug (Godot can generate one — fine for sideloading). Leave every
permission unchecked, including Internet. `export_presets.cfg` is gitignored
(contains keystore secrets) — recreate per machine.

Tablet: enable Developer Options, allow unknown sources, copy APK over, tap
it. With USB debugging on, Godot's toolbar Android icon does one-click deploy.

## Building the treehouse

The treehouse is the main progression. Materials found in the meadow fly home
and land on a **visible pile** under the tree — collecting never builds
anything by itself. Tapping the **plan table** opens the build board, which
shows the treehouse as it stands with a glowing circle on every spot she could
build next. Tap a circle and the part appears as a translucent ghost exactly
where it would go, with what it needs shown as dots she can count. Tap
**build it!** and Summer walks over, hammers, and the pieces fly up from the
pile one at a time.

Five tracks: **house** (platform → cabin → upstairs → tower → mansion roof),
**climbing** (rope ladder → stairs → spiral → bucket lift → slide),
**outside** (decks, balcony, rope bridges to a second and third tree, crow's
nest, zip line, ground workshop), **inside** (shelves, den, kitchen, art room,
telescope) and **pretty** (bunting, a name sign, flowers, a hammock, a lantern
and a dozen more). Nothing is ever mutually exclusive and nothing is ever
refused — an unaffordable plan just gives a friendly wobble.

Parts can be **upgraded in place** to better materials: sticks → planks →
good timber → painted in a colour she picks.

## The other places

Signposts at each end of the meadow lead somewhere new, and each has a
signpost home:

- **The market** (west) — stalls that swap fruit for timber, paint, planks,
  rope and pie tins. Fruit is the only currency; the treasures on her museum
  shelves are never spendable.
- **Dino Land** (east) — rock walls to brush fossils out of, gentle long-necks
  that lower their heads to be patted, and a volcano that only ever puffs.

## Eating

The picnic's **Eat** button takes her out to the blanket, where she sits down
on the grass and eats the sandwich she actually built, bite by bite. Once the
kitchen is up, the treehouse can bake **fruit pies** — any combination of fruit
is a good pie.

## Arranging the museum

Drag a find from the basket up onto any shelf spot to put it on display, and
drag it back **down into the basket** to take it off again. There is no bin —
nothing is ever thrown away, it just moves between the basket and the shelf.
The basket holds any number of finds, nine at a time, with arrows to turn the
pages. Every storey she builds opens another shelf room.

## Getting up the tree

Tap the glowing ring at the foot of the tree and she climbs the rope ladder up
onto the platform. From up there she can walk out along the decks, cross the
rope bridges to the second and third trees, and come back down the ladder — or,
once they are built, ride the bucket lift, whizz down the slide, or take the
zip line off the crow's nest.
