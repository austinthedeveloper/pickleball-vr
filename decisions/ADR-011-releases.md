# ADR-011: Releases: semver, a changelog, the APK on GitHub

**Status:** Accepted (2026-10-27)

## Context

The game plays well on the lead's Quest 3, which they called fun. They
asked to start making releases, with the process documented. The port
kit releases with a tag that CI builds (port `design/VERSIONING.md`). A
Quest APK, though, needs an Android toolchain and a GDExtension plugin
that only the lead's Mac has.

## Decision

- **Semver** from 0.1.0, written by `game/tools/version.py` into the
  project and the Quest preset. Android's `version/code` is
  `MAJOR*10000 + MINOR*100 + PATCH`, so it always rises.
- **`CHANGELOG.md`** at the repo root, written by hand for players (Keep a
  Changelog). Each release's entry becomes the tag message and the GitHub
  release notes.
- **`game/tools/release.py X.Y.Z [--dry-run] [--push]`** checks everything
  first and changes nothing if any check fails. Then:
  1. a release branch;
  2. the version bump;
  3. the full test suite;
  4. the release commit and the annotated tag;
  5. the APK, built locally (debug-signed);
  6. with `--push`: `main` and the tag pushed, and the GitHub release
     created with the APK attached.

  `design/RELEASING.md` has the steps.
- **Debug-signed** until there's a store release, which needs a release
  keystore whose password is the lead's to keep.

## Consequences

- Every release is reproducible from its tag, with the plugin pinned by
  `fetch_openxr_vendors.sh`.
- **CI tests** (added the same day): GitHub Actions runs `test.sh` and
  `test_release.py` on every push and pull request. It runs on Linux
  with the port kit's pinned Godot 4.7.2, and without the plugin. The
  first run passed all 81 tests in 31 s, with the golden traces identical
  to the Mac's, which shows the sim is deterministic across platforms.
- No CI builds yet: the APK is still built on the Mac.
