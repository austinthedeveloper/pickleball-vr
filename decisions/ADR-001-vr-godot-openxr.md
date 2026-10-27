# ADR-001: A VR game in Godot 4.7 with OpenXR, Quest first

**Status:** Accepted (2026-10-27)

## Context

The project lead wants a first-person VR *Pickleball '94* built from what
the port kit learned: start with singles, then doubles, then the
features. The port kit (`../pickleball-port-kit`) is a Godot 4.7 2D game.
Its 2.5D sim works in SNES ground pixels, and buttons pick the shots.

The lead's machine is an M1 Pro Mac, and the headset is a Meta Quest.
macOS has no PC-VR runtime, so a Quest build has to run on the headset
itself: an Android APK built on the Mac.

## Decision

- **A new repository**, `pickleball-vr`, next to the port kit. It has the
  same habits: docs, ADRs, a roadmap, headless tests, branches with the
  `feature/cld-` prefix.
- **Godot 4.7, same pin as the port kit.** Godot's XR support is built in,
  the lead already has it, and the port kit's lessons, tests and tools
  carry over.
- **OpenXR**, so one project runs on Quest (Android, standalone) and later
  on PC VR (SteamVR on Windows) with no changes.
- **The Compatibility renderer.** It's the light one for standalone
  headsets, and it renders the same headless and on the Mac.
- **Flat mode.** When no XR runtime starts (the Mac, CI, the tests), the
  same scene plays on a monitor with the camera at head height. You move
  with the keyboard and aim with the mouse, and a bot swings for you
  (ADR-003). Every feature is built and tested on the Mac; the headset is
  for feel.

## Consequences

- A Quest build needs a JDK 17, the Android SDK, the Godot OpenXR Vendors
  plugin (Meta's loader) and the headset in developer mode
  (`design/QUEST_SETUP.md`). None of that blocks work in flat mode.
- Controller poses and actions can only be checked on the device. They're
  isolated in `view/xr_rig.gd` so that check is one file.
