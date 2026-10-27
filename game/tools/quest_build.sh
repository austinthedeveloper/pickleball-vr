#!/bin/sh
# Builds the Quest APK and installs it on a plugged-in headset
# (design/QUEST_SETUP.md). With --check, only reports what's missing.
#   game/tools/quest_build.sh [--check]
cd "$(dirname "$0")/.." || exit 2
missing=0
need() { echo "  missing: $1"; missing=1; }
export JAVA_HOME="${JAVA_HOME:-$(/usr/libexec/java_home -v 17 2>/dev/null)}"
export ANDROID_HOME="${ANDROID_HOME:-/opt/homebrew/share/android-commandlinetools}"
echo "Quest build prerequisites:"
[ -n "$JAVA_HOME" ] || need "Java 17 (brew install --cask temurin@17)"
command -v adb >/dev/null 2>&1 || need "adb (brew install --cask android-platform-tools)"
[ -d "$ANDROID_HOME/platforms" ] || need "Android SDK platforms in $ANDROID_HOME (sdkmanager \"platforms;android-35\" \"build-tools;35.0.0\")"
[ -x "$ANDROID_HOME/platform-tools/adb" ] || need "the SDK's own platform-tools (sdkmanager --sdk_root=$ANDROID_HOME \"platform-tools\")"
[ -f "$HOME/Library/Application Support/Godot/keystores/debug.keystore" ] || need "Godot's debug keystore (design/QUEST_SETUP.md step 4)"
[ -d addons/godotopenxrvendors ] || need "the OpenXR Vendors plugin (game/tools/fetch_openxr_vendors.sh)"
if command -v adb >/dev/null 2>&1; then
  adb devices | grep -q "device$" || need "a Quest on USB with debugging allowed (adb devices lists none)"
fi
if [ $missing -ne 0 ]; then
  echo "Not ready."; exit 1
fi
echo "  all there."
[ "$1" = "--check" ] && exit 0
mkdir -p ../build
template=""
[ -d android/build ] || template="--install-android-build-template"
godot --headless --path . $template --export-debug "Quest" ../build/pickleball-vr.apk || exit 1
[ -f ../build/pickleball-vr.apk ] || { echo "no APK was written"; exit 1; }
adb install -r ../build/pickleball-vr.apk && adb shell monkey -p com.tinychair.pickleball94vr -c android.intent.category.LAUNCHER 1
