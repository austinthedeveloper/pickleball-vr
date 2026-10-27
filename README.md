# Pickleball '94 VR

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

## On the Quest

See `design/QUEST_SETUP.md` (a JDK, the Android SDK, developer mode, a USB
cable).
