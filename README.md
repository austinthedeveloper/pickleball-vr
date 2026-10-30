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

- **PADDLE** (on MAIN): your paddle hand, and profiles for paddle
  accessories: ANGLE, TWIST, TURN and REACH per profile, and CHECK for
  drift (ADR-015).
- **PRACTICE PARTNER:** a CPU at their kitchen line.
  - DINKS: it keeps a dinking rally going, every ball back to you. You
    can set the DIFFICULTY (how low it skims the net) and turn on floor
    TARGETS (ADR-010).
  - HANDS: it volleys every ball hard back at you, out of the air;
    DIFFICULTY is the pace (ADR-014).
  - RESETS: from mid-court, block its drives soft into its kitchen,
    under the pop-up line (ADR-016).
  - CALL THE SPOT, LINE AND CROSS, VOLLEY DINKS and ATTACK OR DINK:
    placing drills (ADR-017).
- **BALL MACHINE:** drives, dinks, lobs or a mix. You set the SPEED, the
  TARGET, where the machine stands (MACHINE AT), the RATE, RETURN TO and
  TARGETS. At your kitchen line, drives come at you through the air
  (ADR-007).
- **MODE:** FREE PLAY, or 1, 2 or 3 MIN against the clock, with
  RECORDS per drill and player (ADR-022).
- **HOW TO PLAY:** seven lessons, each a drill with one goal.
- **PASSTHROUGH** (on MAIN): only the court, in your room (ADR-021).

## Coaching

MAIN > COACH > COACH MODE ON, then open the address it shows on a phone
on the same Wi-Fi and type the code (ADR-023).
- **COACH:** run the drills, place the target and the next feed, cues,
  challenges, workouts, the coach's ball machine, every shot's numbers,
  replays and saved sessions (ADR-024, `design/COACHING.md`).
- **PRANKS:** sounds, silly balls and paddles, weather, the partner's
  antics, a voice message and a selfie on the partner (ADR-025). Pause >
  MERCY stops them for a minute.
- **The tablet:** pause a practice drill and the same panel stands beside
  you.

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
              intercept, sim (rules, serve, CPUs), bot, types,
              drill (the ball machine, the partner's drills, lessons)
game/net/     dinking online (ADR-027): net_link, relay_link (the relay),
              loopback_link (tests), rollback, online_session; watch
              (COACH VIEW's stream, ADR-028)
game/meta/    settings, opponents (the ladder), lessons, venues, tune (TUNING),
              sessions (saved coaching sessions)
game/view/    world (the venues), match_view, xr_rig, flat_rig, avatar,
              body and cloth (the rigged person), paddle_mesh, floor_target,
              scoreboard, menu_3d, machine, crowd, announcer, focus, look,
              perf, coach (the coach page's server), coach_tablet, pranks,
              voice_rec (a watching coach's HOLD TO TALK, ADR-029)
game/scenes/  main (XR or flat), coach_desk (what a coach can ask of the game)
game/data/    opponents.json (imported), lessons.json
game/coach/   index.html: the coach page the headset serves (ADR-023)
game/assets/  audio (prank/: the synthesized prank sounds); people/rocketbox
              (Microsoft Rocketbox, MIT: the NEW partner); people
              (Quaternius' Universal Base Characters, CC0)
game/tests/   headless suites, golden traces
game/tools/   test.sh, screenshot.gd, shots.sh, rally_stats.gd, the release
              tools, quest_build.sh, swings and tune tools, make_ding.py
              and make_pranks.py (the synthesized sounds)
design/       ROADMAP and HISTORY, KNOWN_ISSUES, COACHING, KITCHEN_DRILLS,
              QUEST_SETUP, RELEASING, TEST_CHANNEL, FROM_THE_PORT_KIT
decisions/    ADRs (indexed in decisions/README.md)
```

## Releases

Download the APK from the
[GitHub releases](https://github.com/austinthedeveloper/pickleball-vr/releases)
and sideload it (`adb install -r pickleball-vr-X.Y.Z.apk`, with the Quest
in developer mode), then open Library > Unknown Sources. `CHANGELOG.md`
says what's in each; `design/RELEASING.md` says how one is cut. Installing
from Meta's Store (no developer mode) is planned: `design/TEST_CHANNEL.md`.

## On the Quest

See `design/QUEST_SETUP.md` (a JDK, the Android SDK, developer mode, a USB
cable).
