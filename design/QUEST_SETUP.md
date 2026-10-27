# Quest setup

What a Quest build needs on the Mac (no Windows: ADR-001). Done once on
the lead's M1 Pro with a Quest 3, 2026-10-27.

## Yours (a password, a license click or the headset)

1. **Java 17 and the Android tools** (Homebrew):

   ```sh
   brew install --cask temurin@17
   brew install --cask android-commandlinetools android-platform-tools
   sdkmanager --licenses
   sdkmanager "platforms;android-35" "build-tools;35.0.0"
   ```

2. **Developer mode.** In the Meta Horizon phone app: Devices > your
   Quest > Headset settings > Developer mode. The first time, it asks you
   to make a (free) developer organization.
3. **Plug in** with a USB-C *data* cable and allow USB debugging in the
   headset ("always allow"). `adb devices` then lists it as `device`.

## The rest (scripted or one-off)

4. **Android pieces Godot checks for:**
   - The SDK's own platform-tools:
     `sdkmanager --sdk_root=/opt/homebrew/share/android-commandlinetools "platform-tools"`.
     Homebrew's adb lives elsewhere, and Godot looks inside the SDK.
   - The standard debug keystore, at
     `~/Library/Application Support/Godot/keystores/debug.keystore`:
     `keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12`.
   - In Godot's editor settings: Export > Android > Java SDK Path =
     `/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home`, and
     Android SDK Path = `/opt/homebrew/share/android-commandlinetools`.
5. **The OpenXR Vendors plugin** (Meta's loader): run
   `game/tools/fetch_openxr_vendors.sh`. It's pinned to 5.1.0-stable and
   checked against its SHA-256. Git ignores the ~80 MB addon, so run it in
   each new checkout.
6. **Build, install, launch:** `game/tools/quest_build.sh`. The first run
   installs Godot's Android build template into `game/android/` (also
   ignored by git), and Gradle downloads its dependencies once.
   `--check` lists anything missing.

The export preset ("Quest" in `game/export_presets.cfg`) has XR Mode
OpenXR, the Meta plugin on, Quest 2 / 3 / Pro, arm64 only, a Gradle
build, and min SDK 32.
