# Sharing with friends: Meta's test channel (plan)

**Status:** Planned (2026-10-28), not started. The lead chose this over
sideloading from GitHub. This sheet says what each side does; when it's
done, it becomes ADR-026 and `design/RELEASING.md` takes the steps.

## The goal

Friends install the game from the Store app on their own Quest and get
each new release as an update. They don't need developer mode, SideQuest
or a cable. Meta's invite-only release channels (ALPHA, BETA) do that:
up to 200 people per channel by default, invited by email or by a link,
without store review. Every upload still has to pass Meta's packaging
checks.

## Today

- `release.py` builds a **debug** APK (`--export-debug`) signed with the
  Mac's Android debug key. GitHub has it, and the repo is public.
- A debug build shows the TUNING pages and writes the swing log and PERF
  lines (`Settings.dev`, `Perf.on` follow `OS.is_debug_build()`).
- Meta takes only release builds (`android:debuggable` false), signed
  with a release key.

## What you do (once)

Accounts and passwords are yours. I can't make them, and they don't go
in the repo or the chat.

1. **A Meta developer account and organization:** sign in at
   developers.meta.com/horizon with your Meta account and create an
   organization. It's free. Meta may ask to verify the account (a phone
   number or a payment method) before you can upload.
2. **The app:** in the Developer Dashboard, create a new app for Meta
   Quest (Horizon Store). Name it "Pickleball '94 VR"; the name must be
   unique on the platform. If the dashboard asks for a privacy policy or
   a Data Use Checkup before uploads, the honest answers are:
   - the game collects nothing;
   - nothing leaves the headset except the coach page, which stays on
     your Wi-Fi.
3. **The upload token:** Dashboard > Account > Account settings > "Get
   Oculus platform utility token" > Generate. Store it in the Mac's
   keychain (I'll give you the one-line `security` command). Treat it as
   a password.
4. **The release key's password:** when I run the key script, you type
   a password of your choice. Write it down somewhere safe.
   - Keep a backup of the key file too: on another drive, or in your
     password manager as an attachment.
   - **If the key or its password is lost, the app can never be updated
     on the Store**; friends would have to uninstall and you'd start a
     new app.
5. **Decide the age group** (Meta asks on every upload):
   - TEENS_AND_ADULTS (13+) is the simple choice.
   - MIXED_AGES (kids too, e.g. your son with his own account) brings
     Meta's extra rules for under-13s.
   - My suggestion: TEENS_AND_ADULTS. Your kid plays on your headset and
     pranks from your phone either way.
6. **Invite friends:** Dashboard > your app > Distribution > Release
   Channels > ALPHA.
   - Use "Email Invite Users" with the email on each friend's Meta
     account, or copy the channel's invite URL and text it to them.
   - Meta's invite emails are known to go missing, so the link is the
     safer way.

## What I do

1. **The release key** (`game/tools/make_keystore.sh`):
   - `keytool` makes `~/.config/pickleball-vr/release.keystore`,
     outside the repo.
   - The password goes into the macOS keychain (item
     `pickleball-vr-release-key`), never into a file.
   - The script refuses to overwrite an existing key.
2. **Release builds:**
   - `release.py` exports with `--export-release`.
   - It hands Godot the key through its environment variables
     (`GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `_USER`, `_PASSWORD`), read
     from the keychain at build time.
   - The APK on GitHub becomes this release build too, so friends who
     sideload get the same clean game.
3. **The manifest, to pass Meta's checks.** Already right:
   - minSdk 32 and targetSdk 34 (Meta requires 34 for new apps);
   - arm64 only;
   - `installLocation="auto"`;
   - the VR category;
   - Quest 2, 3 and Pro support.

   Changes:
   - set `excludeFromRecents` to `true` (it's `false` now);
   - confirm the release APK has no `debuggable` and lists
     `com.oculus.supportedDevices`.

   A new `game/tools/check_apk.sh` reads the built APK's manifest
   (`aapt2 dump`) and fails the release if any of these are wrong.
4. **Uploading** (`release.py X.Y.Z --push --channel alpha`):
   - Meta's `ovr-platform-util` (macOS build, fetched by a script like
     `fetch_openxr_vendors.sh`, git-ignored) runs `upload-quest-build`
     with:
     - the app ID;
     - the token from the keychain;
     - the APK;
     - `--channel alpha`;
     - `--age-group` as decided;
     - the CHANGELOG entry as `--notes`.
   - Then "cut a release" is one command: tests, tag, GitHub release and
     the friends' update.
   - The app ID goes in `game/tools/release.cfg`; it's not a secret.
5. **Your own builds:**
   - `quest_build.sh` stays a debug build with TUNING and the swing log.
   - It's signed with the release key too, so it installs over the
     Store's copy and back without losing your saves (Android refuses an
     update signed with a different key).
6. **Docs and tests:**
   - ADR-026 (the decision);
   - `design/RELEASING.md` (the new steps);
   - the signing section of ADR-011;
   - `test_release.py` covers the new flags and the manifest check, on a
     throwaway copy as now.

## What friends do

1. Open your invite link on their phone (signed in to Meta) or accept the
   email, and join the ALPHA channel.
2. On the Quest: Store > Library (or search the name) > Install. It can
   take a few minutes to show up after joining.
3. Updates come by themselves after each release.
4. For COACH and PRANKS, their phone must be on the same Wi-Fi as their
   headset, as for you.

## Known risks

- **Invite emails** sometimes never arrive, or the game doesn't appear
  for a while. The invite link and a headset restart usually fix it.
- **The first upload may fail Meta's checks** for something not listed
  here. The validator says what; it gets fixed and uploaded again.
- **Signing your debug builds with the release key:** once the Store's
  copy is on your headset, your own sideloads must be signed with that
  key, or Android refuses to install over it.
