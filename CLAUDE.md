# CLAUDE.md

Pickleball '94 VR: first-person pickleball for Meta Quest (Godot 4.7,
OpenXR), built from what the port kit (`../pickleball-port-kit`) learned.
Branch per change with the `feature/cld-` prefix. Never commit to `main`
(the human reviews and merges).

## Commands

```sh
game/tools/test.sh                                   # all tests, headless (must pass)
godot --path game                                    # play (flat mode without a headset)
godot --path game -- demo                            # DEMO: bot vs CPU
godot --headless --path game -s res://tests/golden.gd   # regenerate golden traces (play changes only)
godot --path game --resolution 1280x720 -s res://tools/screenshot.gd -- <lobby|demo|play|machine|lesson|partner> <frames> <out.png> [doubles | lesson] [drill=CALL_THE_SPOT...] [venue=NAME] [tick=N]
python3 game/tools/version.py [set X.Y.Z]            # the version, everywhere (design/RELEASING.md)
python3 game/tools/release.py X.Y.Z --dry-run         # cut a release: checks, bump, tests, tag, APK (--push: GitHub release)
python3 game/tools/test_release.py                    # the release tools' self-test
game/tools/shots.sh [filter]                          # the standard screenshots into shots/ (git-ignored, for looking)
godot --headless --path game -s res://tools/rally_stats.gd -- <matches> <difficulty> [doubles]
python3 game/tools/import_opponents.py                # the ladder, from the port kit
game/tools/fetch_openxr_vendors.sh                    # Meta's OpenXR loader into game/addons (pinned, git-ignored)
game/tools/quest_build.sh [--check]                   # build + install + launch on the Quest (design/QUEST_SETUP.md)
game/tools/swings.sh > s.log                          # the headset's swing log (debug builds)
python3 game/tools/swings_report.py s.log [--since HH:MM]   # that log summed up per mode (ADR-017)
```

Releases are semver with tags `vX.Y.Z`, `CHANGELOG.md` and an APK on the
GitHub release (`design/RELEASING.md`, ADR-011). GitHub Actions runs
`test.sh` and the release self-test on every push and pull request
(`.github/workflows/ci.yml`), without the OpenXR plugin (keep the tests
plugin-free). Godot's version and SHA-512s are pinned in
`.github/actions/setup-godot/action.yml`, the same pin as the port kit's.

`design/ROADMAP.md` is the milestone sheet: keep it current with each
branch. `design/KNOWN_ISSUES.md` lists the defects, and
`decisions/README.md` the ADRs (next: ADR-019). `design/QUEST_SETUP.md`
covers the headset build.

**The canon bible** is `../pickleball/docs/PICKLEBALL_94_BIBLE.md`. The VR
game is one of its artifacts and may not contradict it. Port kit
decisions are cited as "port ADR-n", the SNES repo's as "SNES ADR-n".

## Rules of the code (game/)

- **The sim is pure and exact** (ADR-002). `game/sim/` uses ints only
  (micrometres, 120 Hz ticks, Q14 unit vectors), no Nodes, no clock, and
  no randomness except the seeded generator in its state. Square roots go
  through `Fx.isqrt`. GDScript `/` truncates and `>>` floors.
- **A human's input is a `SimTypes.HumanInput`** (ADR-003): head on the
  ground, paddle face centre and normal, free hand, toss. Nothing else
  crosses into the sim. The XR rig interpolates poses to ticks; flat mode
  and DEMO get theirs from `Bot`.
- **Presentation never writes to the sim**
  (`test_view_never_writes_to_the_sim`). A change to a running match is a
  command: `MatchView.command` → `Sim.step(human, commands)`.
- **Tests play through `step()`** with the bot, as the game does.
- **Every OpenXR name lives in `view/xr_rig.gd`.**
- **Menus are `Menu3D`s** (rows by id, move/change/press or point and
  click). Tests select rows by id, never by counting.
- **Settings live in `Settings`** (`meta/settings.gd`), and tests use
  their own file (the runner sets `Settings.default_path`).
- **Lessons are data** (`data/lessons.json`), and `test_drill` makes sure
  the bot can pass every one.
- **The ladder is data:** `data/opponents.json` comes from
  `tools/import_opponents.py`. Don't edit it by hand.
- **Typed GDScript.** `:=` can't infer from Array elements: annotate
  (`var x: int = arr[i]`). `pass` and `call` are reserved.
- **Mind the Quest's CPU** (ADR-009): GDScript there is several times
  slower than on the Mac. Anything that predicts flight (`Aim`,
  `Intercept`) must stay cheap. Debug builds log `PERF` lines
  (`adb logcat -s godot`) to check.
- **Behaviour changes need an ADR**, and golden traces change only on
  purpose, with the reason in the commit.

## Before calling it done

1. `game/tools/test.sh` passes.
2. Look at a screenshot of anything visual (`tools/screenshot.gd`).
3. Update `design/KNOWN_ISSUES.md`, the ADRs and the roadmap.
