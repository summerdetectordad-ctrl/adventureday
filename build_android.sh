#!/usr/bin/env bash
# Build and version Adventure Day for Android.
#
#   ./build_android.sh version              show the current version
#   ./build_android.sh bump [patch|minor|major]   raise the version
#   ./build_android.sh apk                  build/AdventureDay.apk  (sideload)
#   ./build_android.sh aab                  build/AdventureDay.aab  (upload to Play)
#   ./build_android.sh win                  build/windows/AdventureDay.exe (play on PC)
#   ./build_android.sh all                  the Windows build and the APK
#   ./build_android.sh release [patch|minor|major]
#                                           bump, build the AAB, tag the commit
#
# ABOUT VERSIONS
#   version/code is an integer. Google Play remembers every code you have ever
#   uploaded and will reject anything that is not HIGHER than the last one.
#   Android also refuses to install an "update" whose code went down. So the
#   code only ever goes up, it is never reused, and if a build fails after a
#   bump you do NOT put it back — you bump again.
#
#   version/name is the string people see. It follows major.minor.patch.
#
#   Both appear TWICE in export_presets.cfg, once per preset, and must match.
#   That is exactly the sort of thing that gets missed by hand, which is why
#   this script edits both.
#
# THE SIGNING KEY is deliberately not in this repo. It lives in
# C:\AdventureDayKeys — back that folder up, because losing it means never
# being able to update the app on Play again.
set -e

GODOT="/c/Godot47/Godot_v4.7.2-stable_win64_console.exe"
KEYS="/c/AdventureDayKeys"
PRESETS="export_presets.cfg"
HERE="$(pwd -W 2>/dev/null || pwd)"

export JAVA_HOME="/c/Jdk/jdk-17.0.20.1+1"
export ANDROID_HOME="C:\\AndroidSdk"
export ANDROID_SDK_ROOT="C:\\AndroidSdk"


# --- version handling --------------------------------------------------------

current_code() { grep -m1 '^version/code=' "$PRESETS" | cut -d= -f2; }
current_name() { grep -m1 '^version/name=' "$PRESETS" | cut -d'"' -f2; }

show_version() {
	echo "  versionCode : $(current_code)"
	echo "  versionName : $(current_name)"
	local n
	n=$(grep -c '^version/code=' "$PRESETS")
	if [ "$n" -ne 2 ]; then
		echo "  WARNING: expected version/code in 2 presets, found $n" >&2
	fi
	if [ "$(grep '^version/code=' "$PRESETS" | sort -u | wc -l)" -ne 1 ] \
		|| [ "$(grep '^version/name=' "$PRESETS" | sort -u | wc -l)" -ne 1 ]; then
		echo "  WARNING: the two presets disagree — fix before releasing" >&2
	fi
}

bump_version() {
	local part="${1:-patch}"
	local code name major minor patch
	code=$(current_code)
	name=$(current_name)
	major=$(echo "$name" | cut -d. -f1)
	minor=$(echo "$name" | cut -d. -f2)
	patch=$(echo "$name" | cut -d. -f3)
	[ -z "$minor" ] && minor=0
	[ -z "$patch" ] && patch=0

	case "$part" in
		major) major=$((major + 1)); minor=0; patch=0 ;;
		minor) minor=$((minor + 1)); patch=0 ;;
		patch) patch=$((patch + 1)) ;;
		*) echo "bump takes patch, minor or major (got '$part')" >&2; exit 1 ;;
	esac

	local newcode="$((code + 1))"
	local newname="$major.$minor.$patch"

	# both presets, always together
	sed -i "s|^version/code=.*|version/code=$newcode|g" "$PRESETS"
	sed -i "s|^version/name=.*|version/name=\"$newname\"|g" "$PRESETS"

	echo "  $name (code $code)  ->  $newname (code $newcode)"
}


# --- building ----------------------------------------------------------------

# The Gradle staging folders keep a copy of the exported project. Left there,
# the NEXT export — of either kind — picks those files up as project resources
# and produces an archive with DUPLICATE ENTRIES, which then fails to sign. The
# APK it leaves behind looks fine on disk and does not verify. It cost one
# silently corrupt build to find, so both are cleared before every build.
clean_staging() {
	rm -rf android/build/assetPackInstallTime/src/main/assets/* 2>/dev/null || true
	rm -rf android/build/src/instrumented/assets/* 2>/dev/null || true
}

## Put a finished build where it is easy to find and pass to a phone.
##
## If the game is OPEN, Windows locks the file and the copy fails — and the
## folder is then left holding the previous version while the build output says
## everything succeeded. That happened, and a stale build was tested for a good
## ten minutes before anyone noticed. So this says so, loudly.
drop_copy() {
	local src="$1"
	local name="$2"
	local drop="$USERPROFILE/OneDrive/Desktop/Adventure Day"
	[ -d "$drop" ] || return 0
	if cp "$src" "$drop/$name" 2>/dev/null; then
		echo "  copied to Desktop/Adventure Day/$name"
		return 0
	fi
	echo "" >&2
	echo "COULD NOT UPDATE Desktop/Adventure Day/$name — the file is in use." >&2
	echo "The game is probably still open. Close it and run this again, or the" >&2
	echo "copy on the desktop will stay on the PREVIOUS version." >&2
	echo "The new build is fine, it is at $src" >&2
	exit 1
}

signing_env() {
	export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="C:/AdventureDayKeys/upload.keystore"
	export GODOT_ANDROID_KEYSTORE_RELEASE_USER="adventureday"
	export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$(grep '^Password :' "$KEYS/KEYSTORE-README.txt" | awk '{print $3}')"
	if [ -z "$GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD" ]; then
		echo "Could not read the keystore password from $KEYS/KEYSTORE-README.txt" >&2
		exit 1
	fi
}

## Every build is checked before it is handed over. A signature that does not
## verify is exactly the failure this catches.
verify_apk() {
	local apk="$1"
	if ! "C:/AndroidSdk/build-tools/36.0.0/apksigner.bat" verify "$apk" >/dev/null 2>&1; then
		echo "" >&2
		echo "BUILD IS BAD: $apk does not verify. Do not install or upload it." >&2
		"C:/AndroidSdk/build-tools/36.0.0/apksigner.bat" verify "$apk" 2>&1 | head -3 >&2
		exit 1
	fi
	echo "  signature verified"
}

build_apk() {
	signing_env
	clean_staging
	mkdir -p build
	echo "Building APK  v$(current_name) (code $(current_code))..."
	"$GODOT" --headless --path "$HERE" --import >/dev/null 2>&1 || true
	"$GODOT" --headless --path "$HERE" \
		--export-release "Android" "$HERE\\build\\AdventureDay.apk"
	verify_apk build/AdventureDay.apk
	ls -lh build/AdventureDay.apk
	drop_copy build/AdventureDay.apk AdventureDay.apk
}

## The PC build. Running the project through the editor binary works, but it
## puts "(DEBUG)" in the title bar and is not the game — this is a real,
## standalone executable with everything packed inside it.
build_win() {
	mkdir -p build/windows
	echo "Building Windows  v$(current_name)..."
	"$GODOT" --headless --path "$HERE" --import >/dev/null 2>&1 || true
	"$GODOT" --headless --path "$HERE" \
		--export-release "Windows Desktop" "$HERE\\build\\windows\\AdventureDay.exe"
	ls -lh build/windows/AdventureDay.exe
	drop_copy build/windows/AdventureDay.exe AdventureDay.exe
}

build_aab() {
	signing_env
	clean_staging
	mkdir -p build
	echo "Building AAB  v$(current_name) (code $(current_code)) — a few minutes..."
	"$GODOT" --headless --path "$HERE" --import >/dev/null 2>&1 || true
	"$GODOT" --headless --path "$HERE" \
		--export-release "Android AAB" "$HERE\\build\\AdventureDay.aab"
	ls -lh build/AdventureDay.aab
}


# --- a whole release ---------------------------------------------------------

do_release() {
	local part="${1:-patch}"

	if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
		echo "Working tree is not clean. Commit first, so the tag points at" >&2
		echo "exactly what you shipped." >&2
		git status --short >&2
		exit 1
	fi

	bump_version "$part"
	local name code
	name=$(current_name)
	code=$(current_code)

	build_aab

	git add "$PRESETS"
	git commit -q -m "Release v$name (versionCode $code)"
	git tag -a "v$name" -m "Adventure Day v$name (versionCode $code)"
	echo ""
	echo "Tagged v$name. Push it with:"
	echo "  git push && git push --tags"
	echo ""
	echo "Then upload build/AdventureDay.aab to the Play Console."
}


case "${1:-apk}" in
	version) show_version ;;
	bump)    bump_version "${2:-patch}" ;;
	aab)     build_aab ;;
	win)     build_win ;;
	all)     build_win; build_apk ;;
	release) do_release "${2:-patch}" ;;
	apk|*)   build_apk ;;
esac
