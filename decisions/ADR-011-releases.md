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
- No CI builds yet, and no CI tests on push. Both are worth adding: the
  tests need only a pinned Godot on a runner, as in the port kit.
