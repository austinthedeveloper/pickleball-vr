#!/bin/sh
# Builds the Quest APK and installs it on a plugged-in headset
# (design/QUEST_SETUP.md). With --check, only reports what's missing.
#   game/tools/quest_build.sh [--check]
cd "$(dirname "$0")/.." || exit 2
missing=0
need() { echo "  missing: $1"; missing=1; }
echo "Quest build prerequisites:"
/usr/libexec/java_home -v 17 >/dev/null 2>&1 || need "Java 17 (brew install --cask temurin@17)"
command -v adb >/dev/null 2>&1 || need "adb (brew install --cask android-platform-tools)"
sdk="${ANDROID_HOME:-/opt/homebrew/share/android-commandlinetools}"
[ -d "$sdk/platforms" ] || need "Android SDK platforms in $sdk (sdkmanager \"platforms;android-35\" \"build-tools;35.0.0\")"
[ -d addons/godotopenxrvendors ] || need "the Godot OpenXR Vendors plugin in game/addons/ (QUEST_SETUP step 5)"
[ -d android/build ] || need "Godot's Android build template (Project > Install Android Build Template, or --install-android-build-template)"
if command -v adb >/dev/null 2>&1; then
  adb devices | grep -q "device$" || need "a Quest on USB with debugging allowed (adb devices lists none)"
fi
if [ $missing -ne 0 ]; then
  echo "Not ready."; exit 1
fi
echo "  all there."
[ "$1" = "--check" ] && exit 0
mkdir -p ../build
godot --headless --path . --export-debug "Quest" ../build/pickleball-vr.apk || exit 1
adb install -r ../build/pickleball-vr.apk && adb shell monkey -p com.tinychair.pickleball94vr 1
