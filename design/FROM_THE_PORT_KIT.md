# What came over from the port kit

The port kit (`../pickleball-port-kit`) spent 111 tasks learning how to
build *Pickleball '94* well. Here's what this repo keeps, and what it left
behind.

## Kept as rules

- **A pure, exact sim** (port ADR-052/059 → ADR-002): ints, no Nodes, no
  clock, so tests, golden traces, replays and netcode all work.
- **Presentation never writes to the sim** (port ADR-102):
  `test_view.test_view_never_writes_to_the_sim` replays the view's input
  log into a bare sim and compares.
- **Commands for match changes** (port ADR-102): `MatchView.command` →
  `Sim.step(human, commands)`.
- **The CPU schedule is the shipped schedule**: tests drive `step()`.
- **Golden traces**, regenerated only on purpose, with the reason in the
  commit.
- **Typed GDScript** with the same traps: `:=` can't infer from an
  Array element, and `pass` and `call` are names you can't reuse.
- **ADRs, a roadmap, known issues**, and branches with the
  `feature/cld-` prefix.

## Kept as content

- **The rules and their calls:** rally scoring to 5, the two-bounce rule,
  no kitchen volleys (port ADR-055), NET!, OUT!, FAULT!, KITCHEN!,
  VOLLEY!, 2 BOUNCES.
- **The two-tone court and kitchen** (port ADR-022/027).
- **The sounds** (hit, drive, bounce, net, whistle, applause, the park's
  ambience) from `game/assets/audio/`.
- **To come:** the eight ladder teams and their quips (port ADR-023/048),
  the venues (port ADR-024/046/088), STORY, ROAD TRIP and the hats.

## Left behind, on purpose

- **SNES frame-exactness and conformance traces.** The paddle in your hand
  can't be a button (ADR-002/003).
- **The bitmap fonts and 960x540 pixel art.** VR text has to be
  resolution-free. Label3D for now; a VR-legible take on the house style
  comes with the menus (phase 4).
- **The updater** (port ADR-057). The Quest store or sideloading updates
  the app.

## Learned the hard way, again

- `xr/openxr/startup_alert=false`, or a Mac with no runtime blocks on a
  modal "OpenXR failed to start" alert, which hangs headless tests.
- A test runner that builds scenes must run on the first frame, not in
  `_initialize`, or `_ready` never fires.
