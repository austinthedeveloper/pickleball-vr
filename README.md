# Pickleball '94 VR

[![CI](https://github.com/austinthedeveloper/pickleball-vr/actions/workflows/ci.yml/badge.svg)](https://github.com/austinthedeveloper/pickleball-vr/actions/workflows/ci.yml)

First-person pickleball in VR, the next artifact of *Pickleball '94* after
the Godot remaster (`../pickleball-port-kit`). You hold the paddle; the
rules, the CPUs' personalities and the park come from the port kit.

Godot **4.7** with OpenXR (ADR-001). Built for **Meta Quest**, standalone.
On a Mac, or anywhere without a headset, it plays in **flat mode** on the
monitor.

## Run

```sh
godot --path game                 # the lobby and MATCH SETUP (flat mode without a headset)
godot --path game -- play         # straight into a match
godot --path game -- demo         # DEMO: the bot against the CPU
godot --path game -- doubles      # doubles, with a CPU partner (ADR-004)
game/tools/test.sh                # all tests, headless (must pass)
```

## Screenshots

`game/tools/shots.sh` renders the standard views (lobby, matches, the
ball machine, the dink partner, a lesson, every venue) into `shots/` at
the repo root. Git ignores the folder; it's for looking.

## Controls

| | Quest | Flat mode |
|---|---|---|
| Swing | swing the paddle (right controller) | automatic when the ball's in reach |
| Aim | the paddle's angle and speed | the mouse (a ring on the far court) |
| Move | walk; left stick | WASD / arrows |
| Turn | right stick (45 deg snaps) | |
| Serve | the ball is in your left hand: pull its trigger to let go, then hit it | Space |
| Soft shot | swing gently | hold Shift |
| Pause | the menu button (or B/Y) | Esc |
| Menus | point the free hand's laser, pull a trigger; or the sticks | point and click the mouse; or the arrows and Enter |

The **shot assist** (ADR-003) pulls a miss toward a good shot, 65% by
default.

## Practice

- **PADDLE** (on MAIN): your paddle hand and angle, and profiles for
  paddle accessories: ANGLE, TWIST and REACH per profile (ADR-015).
- **PRACTICE PARTNER:** a CPU at their kitchen line.
  - DINKS: it keeps a dinking rally going, every ball back to you. You
    can set the DIFFICULTY (how low it skims the net) and turn on floor
    TARGETS (ADR-010).
  - HANDS: it volleys every ball hard back at you, out of the air;
    DIFFICULTY is the pace (ADR-014).
- **BALL MACHINE:** drives, dinks, lobs or a mix. You set the SPEED, the
  TARGET, where the machine stands (MACHINE AT), the RATE, RETURN TO and
  TARGETS. At your kitchen line, drives come at you through the air
  (ADR-007).
- **HOW TO PLAY:** seven lessons, each a drill with one goal.

## Venues

PARK, LAKESIDE, SUNSET, GYM and SPACE (ADR-008), each with the port kit's
court colours and ambience. HOME plays at the opponent's home court.

## Rules

As in the remaster: rally scoring to 5. Serve diagonally, past the
kitchen. The serve and the return each bounce once (the two-bounce rule).
No volleys from your own kitchen. Lines are in. Faults are called the
remaster's way: NET!, OUT!, FAULT! (the wrong box), KITCHEN!, VOLLEY!.

## Layout

```
game/sim/     the pure sim: k (constants), fx (int maths), ball, aim,
              intercept, sim (rules, serve, CPUs), bot, types
game/sim/     ... drill (the ball machine and lessons)
game/meta/    settings, opponents (the ladder), lessons, venues
game/view/    world (the venues), match_view, xr_rig, flat_rig, avatar,
              paddle_mesh, scoreboard, menu_3d, machine, crowd, announcer
game/data/    opponents.json (imported), lessons.json
game/scenes/  main (XR or flat)
game/tests/   headless suites, golden traces
game/tools/   test.sh, screenshot.gd, rally_stats.gd
design/       ROADMAP, KNOWN_ISSUES, QUEST_SETUP, FROM_THE_PORT_KIT
decisions/    ADRs
```

## Releases

Download the APK from the
[GitHub releases](https://github.com/austinthedeveloper/pickleball-vr/releases)
and sideload it (`adb install -r pickleball-vr-X.Y.Z.apk`, with the Quest
in developer mode), then open Library > Unknown Sources. `CHANGELOG.md`
says what's in each; `design/RELEASING.md` says how one is cut.

## On the Quest

See `design/QUEST_SETUP.md` (a JDK, the Android SDK, developer mode, a USB
cable).
