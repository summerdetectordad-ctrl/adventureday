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
./build_android.sh apk    # build/AdventureDay.apk  — sideload onto a phone
./build_android.sh aab    # build/AdventureDay.aab  — upload to Play
```

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

## Before each Play upload

Bump both in `export_presets.cfg`, in **both** presets:

```
version/code=2       # must increase every single upload
version/name="1.1"   # what people see
```

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

## Gotcha

The Gradle staging folder (`android/build/assetPackInstallTime/src/main/assets`)
keeps a copy of the exported project. If a previous build left one there, the
next export recurses into it and dies on hundreds of missing paths.
`build_android.sh` clears it before every AAB build. If you ever build by hand
from the editor and hit that, delete `android/` and re-install the build
template.
