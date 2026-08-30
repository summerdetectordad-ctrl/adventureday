# Adventure Day

Calm 2D game for Summer. She explores a meadow with a metal detector — a soft
tone rises near buried finds — digs up fossils, dino bones, Roman coins and
pirate treasure, and arranges them on the shelf in her treehouse museum.
Indy and Star (the lurchers) trot along behind her. Affirmations appear on
soft cards: at start-up, when a find is shelved, and when the sunshine poster
is tapped.

Godot 4 (GDScript, standard build — not .NET). Sideloaded Android APK.
No ads, no purchases, no accounts, no analytics, no internet permission,
no fail state, no reading required.

Project docs: [AGENTS.md](AGENTS.md) (canonical reference),
[IDEAS.md](IDEAS.md) (backlog).

## Controls

- Touch: tap to walk; big shovel button to dig; tap the treehouse door for
  the museum; drag finds from the basket onto any shelf spot; tap a shelved
  find to see its word; tap dogs/frogs/berries/nest/bike/poster for surprises.
- Keyboard (dev): arrows or A/D to walk; Space/E to dig or enter.
- Mute: top-right button; persists.

## Run it

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
