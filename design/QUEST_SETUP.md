# Quest setup

What a Quest build needs on the Mac (no Windows needed: ADR-001). Steps
1 to 3 are yours: they need your password, a license click, or the headset.

1. **Java 17 and the Android tools** (Homebrew):

   ```sh
   brew install --cask temurin@17
   brew install --cask android-commandlinetools android-platform-tools
   sdkmanager --licenses
   sdkmanager "platform-tools" "build-tools;35.0.0" "platforms;android-35"
   ```

2. **Developer mode.** In the Meta Horizon app on your phone: Devices >
   your Quest > Headset settings > Developer mode, on. It asks you to make
   a (free) developer organization the first time.
3. **Plug in.** Use a USB-C data cable from the Quest to the Mac. In the
   headset, allow USB debugging (tick "always allow"). `adb devices`
   should then list it.

Then the rest (VR-06):

4. **Godot's Android settings:** Editor Settings > Export > Android: the
   Java SDK path (`/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home`)
   and the Android SDK path (Homebrew's
   `/opt/homebrew/share/android-commandlinetools`).
5. **The Godot OpenXR Vendors plugin** (GodotVR's official release on
   GitHub, the version made for Godot 4.7) goes in `game/addons/`. It
   carries Meta's OpenXR loader.
6. **The export preset:** Android, XR Mode OpenXR, the Meta plugin on,
   arm64 only, Gradle build, min SDK 32. Then
   `godot --path game --export-debug "Quest" build/pickleball-vr.apk` and
   `adb install -r build/pickleball-vr.apk`.

The Android export templates for 4.7.2 are already installed on this Mac.
