# Releasing

Started with **0.1.0** on 2026-10-27 (ADR-011).

## The number

[Semantic versioning](https://semver.org), `MAJOR.MINOR.PATCH`:

- **MINOR** for a release with new features.
- **PATCH** for fixes only.
- **MAJOR** stays 0 until the game is called finished (1.0.0).

The version lives in `game/project.godot` (`config/version`) and the Quest
export preset (`version/name`, plus `version/code`, which Android needs to
rise with every release: `MAJOR*10000 + MINOR*100 + PATCH`). Change it
only with the tool, which keeps them in step:

```sh
python3 game/tools/version.py              # the current version
python3 game/tools/version.py set 0.2.0
```

## Cutting a release

1. **Write the CHANGELOG entry** at the top of `CHANGELOG.md`, for
   players: `## [X.Y.Z] - YYYY-MM-DD`, one paragraph, then `### Added` /
   `### Changed` / `### Fixed`. Without one, `release.py` stops and prints
   a template from the roadmap.
2. **Add the release line** under `## Releases` in `design/ROADMAP.md`.
3. **Dry run**, from an up-to-date `main`:

   ```sh
   python3 game/tools/release.py X.Y.Z --dry-run
   ```

   It prints the plan and everything that would stop it. It stops if:
   - you're not on `main`;
   - there are uncommitted changes other than `CHANGELOG.md` and the
     roadmap;
   - the tag already exists, here or on GitHub;
   - `main` is behind GitHub;
   - `gh` isn't logged in;
   - the OpenXR plugin is missing;
   - there's no CHANGELOG entry.
4. **Release:**

   ```sh
   python3 game/tools/release.py X.Y.Z --push
   ```

   It works in this order:
   1. Branches `feature/cld-release-X.Y.Z`.
   2. Sets the version and runs every test (a failure stops it with
      nothing committed).
   3. Commits "Release X.Y.Z" (the version files, the CHANGELOG and the
      roadmap) and tags `vX.Y.Z`, annotated with the entry's first
      paragraph.
   4. Builds `build/pickleball-vr-X.Y.Z.apk`, and the Mac and Windows
      games (the `macOS` and `Windows` presets) zipped as
      `build/Pickleball94VR-X.Y.Z-macos.zip` and `-windows.zip`. The
      Windows zip holds the .exe and the OpenXR library it loads.
   5. Fast-forwards `main`, pushes `main` and the tag.
   6. Creates the GitHub release with the APK and both zips attached, and
      the CHANGELOG entry and how to install each as its notes.

   Without `--push`, everything stays local, and it prints the commands
   to publish.
5. **Install it on the headset** to check the published build:
   `adb install -r build/pickleball-vr-X.Y.Z.apk`.

`python3 game/tools/test_release.py` tests the version and CHANGELOG tools
on throwaway copies.

## CI

GitHub Actions (`.github/workflows/ci.yml`) runs every Godot test and the
release tools' self-test on each push and pull request. It uses Linux
with the pinned, hash-checked Godot 4.7.2
(`.github/actions/setup-godot`), and takes about half a minute. Check that
`main` is green before cutting a release. CI has no OpenXR plugin, so the
tests must not need it.

## The computer builds

The Mac and Windows games are flat mode (ADR-001): for a coach watching
(ADR-028, 029) or a friend to dink with (ADR-027), with no Godot to
install. Neither is signed by a developer account, so each asks once:
right-click > Open on a Mac, More info > Run anyway on Windows. The Mac
app is ad-hoc signed with the microphone entitlement and its reason, for
HOLD TO TALK. The Windows build is untested on Windows itself: the lead's
first try is its check. On a PC with a headset on Link or Air Link, OpenXR
may start the game in VR.

## Why the APK is built on the Mac

A Quest build needs Java 17, the Android SDK, Godot's Android build
template and the OpenXR Vendors plugin (`design/QUEST_SETUP.md`). They're
set up on the lead's Mac, not on GitHub's runners, so `release.py` builds
locally and uploads the APK itself. Building in CI on a tag (as the port
kit does) is possible later: the same steps as `design/QUEST_SETUP.md`
in a workflow, with `fetch_openxr_vendors.sh` for the plugin and the
keystore as a secret. The tests already run there (see CI above).

## Sharing with friends

Planned: Meta's ALPHA release channel, so friends install from the Store
and get updates. The plan, and what each side does, is in
`design/TEST_CHANNEL.md`.

## Signing

Releases are **debug-signed**, with the Mac's Android debug keystore
(`~/Library/Application Support/Godot/keystores/debug.keystore`). That's
fine for sideloading (Developer Mode, `adb install`, SideQuest). Meta's
store needs a release keystore. Making one is the lead's call, because its
password is a secret to keep safe, and losing it means you can never
update the app. Its setup goes in ADR-011 when the time comes.
