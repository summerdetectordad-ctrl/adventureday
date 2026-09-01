#!/usr/bin/env bash
# Build Adventure Day for Android.
#
#   ./build_android.sh apk   -> build/AdventureDay.apk  (sideload onto a phone)
#   ./build_android.sh aab   -> build/AdventureDay.aab  (upload to Play)
#
# The signing key is deliberately NOT in this repo. It lives in
# C:\AdventureDayKeys — back that folder up, because losing it means never
# being able to update the app on Play again.
set -e

GODOT="/c/Godot47/Godot_v4.7.2-stable_win64_console.exe"
KEYS="/c/AdventureDayKeys"
export JAVA_HOME="/c/Jdk/jdk-17.0.20.1+1"
export ANDROID_HOME="C:\AndroidSdk"
export ANDROID_SDK_ROOT="C:\AndroidSdk"

# the password is read from the keystore's own README rather than stored here
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="C:/AdventureDayKeys/upload.keystore"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="adventureday"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$(grep '^Password :' "$KEYS/KEYSTORE-README.txt" | awk '{print $3}')"

if [ -z "$GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD" ]; then
	echo "Could not read the keystore password from $KEYS/KEYSTORE-README.txt" >&2
	exit 1
fi

mkdir -p build
"$GODOT" --headless --path "$(pwd -W 2>/dev/null || pwd)" --import >/dev/null 2>&1 || true

case "${1:-apk}" in
	aab)
		# The gradle staging folder keeps a copy of the exported project. If a
		# previous build left one there, the next export recurses into it and
		# fails on hundreds of missing paths. Always start it empty.
		rm -rf android/build/assetPackInstallTime/src/main/assets/*
		echo "Building AAB (Gradle) — a few minutes..."
		"$GODOT" --headless --path "$(pwd -W 2>/dev/null || pwd)" \
			--export-release "Android AAB" "$(pwd -W 2>/dev/null || pwd)\build\AdventureDay.aab"
		ls -lh build/AdventureDay.aab
		;;
	*)
		echo "Building APK..."
		"$GODOT" --headless --path "$(pwd -W 2>/dev/null || pwd)" \
			--export-release "Android" "$(pwd -W 2>/dev/null || pwd)\build\AdventureDay.apk"
		ls -lh build/AdventureDay.apk
		;;
esac
