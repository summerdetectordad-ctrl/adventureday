# Building and releasing Adventure Day

## Toolchain (already installed on this machine)

| Thing | Where | Why |
|---|---|---|
| Godot 4.7.2 | `C:\Godot47\` | 4.3 targeted API 34; Play needs 36 |
| JDK 17 (Temurin) | `C:\Jdk\jdk-17.0.20.1+1` | Gradle needs it |
| Android SDK | `C:\AndroidSdk` | platform 36, build-tools 36.0.0 |
| Export templates | `%APPDATA%\Godot\export_templates\4.7.2.stable` | |
| **Upload keystore** | `C:\AdventureDayKeys` | **BACK THIS UP** |

## Building

```bash
./build_android.sh version         # what is it now
./build_android.sh bump patch      # 1.0.0 -> 1.0.1, code 1 -> 2
./build_android.sh apk             # build/AdventureDay.apk — sideload
./build_android.sh aab             # build/AdventureDay.aab — upload to Play
./build_android.sh release patch   # bump, build the AAB, commit, tag
```

Every APK build verifies its own signature before handing it over, and both
Gradle staging folders are cleared first — see the gotcha at the bottom.

The signing password is read at build time from
`C:\AdventureDayKeys\KEYSTORE-README.txt` and passed to Godot as an
environment variable. It is deliberately not stored in `export_presets.cfg`,
and neither that file nor the keystore is in git.

## Sideloading for the birthday

1. Copy `AdventureDay.apk` to the phone or tablet (USB, or email it to yourself)
2. On the device, open it and allow "install unknown apps" for whatever app you
   opened it from
3. Install

No Play account needed. This works today and is not dependent on anything
Google does.

## Versions

`./build_android.sh bump` handles this — do not edit the numbers by hand.

- `version/code` is an integer. Play remembers every code ever uploaded and
  rejects anything not HIGHER than the last. Android refuses an "update" whose
  code went down. So it only goes up, is never reused, and if a build fails
  after a bump you bump again rather than putting it back.
- `version/name` is the string people see, `major.minor.patch`.
- Both appear TWICE in `export_presets.cfg`, once per preset, and must match.
  `./build_android.sh version` warns if they have drifted apart.

## Verified in the current build

| Check | Result |
|---|---|
| targetSdkVersion | **36** (Android 16) — meets the Aug 2026 floor |
| compileSdkVersion | 36 |
| Architectures | arm64-v8a, x86_64 (APK); + armeabi-v7a (AAB) |
| Android permissions requested | **none at all** |
| Internet permission | **absent** — the app cannot go online |
| Signature | v1+v2+v3, `CN=Adventure Day, ..., C=GB` |
| APK size | 79 MB |
| AAB size | 103 MB (Play splits this per device) |

The complete absence of permissions is what makes the data safety form a
two-click job — see `CRIB.md`.

## Gotcha: the Gradle staging folders

`android/build/assetPackInstallTime/src/main/assets` and
`android/build/src/instrumented/assets` keep a copy of the exported project.
Left there, the NEXT export of either kind picks those files up as project
resources and produces an archive with DUPLICATE ENTRIES.

The resulting APK looks perfectly normal on disk and fails to verify. It is a
silent corruption — nothing in the build output says the file is unusable.

`build_android.sh` now clears both folders before every build AND verifies the
signature of every APK it produces, refusing to hand over one that does not
check out. If you build by hand from the editor and hit this, delete
`android/` and re-install the build template.
