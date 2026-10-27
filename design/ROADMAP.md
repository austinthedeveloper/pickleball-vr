# VR roadmap

The milestone sheet for the VR game. Branches chain, each cut from the
previous one's tip, with the `feature/cld-` prefix. Nothing goes to `main`
except the bootstrap commit: you review and merge. When a branch's work
is in, its row's status flips in the same commit.

**Status:** **Done** means automated checks cover it fully or you've played
and approved it. **Ready to test** means it works and is verified, but it
needs a human in the headset (the row says what to try). **Planned / In
progress / Blocked** mean what they say.

**Every branch, before it's marked:** `game/tools/test.sh` passes; the
golden traces are unchanged unless the branch means to change play (the
commit says why, and an ADR covers it); there are screenshots of anything
visual; `design/KNOWN_ISSUES.md` and the ADRs are up to date.

## Phases

1. **Singles.** One human against one CPU, first person, flat mode and Quest.
2. **Doubles.** A CPU partner, four on court, doubles serving.
3. **Feel.** Spin, paddle tuning, the port kit's CPU personalities and
   ladder, sound and crowd.
4. **In-headset menus.** MATCH SETUP, options and the save, all inside VR.
5. **Modes.** Ball machine and HOW TO PLAY, tournament, venues, career,
   records.
6. **Online.** The port kit's rollback (port ADR-102/103) on the 120 Hz sim.

## Index

| Task | What | Branch | Status |
|---|---|---|---|
| VR-01 | The 3D sim: ball, net, bounce, aim, rules (ADR-002) | `feature/cld-vr-singles` | Done |
| VR-02 | Paddle contact and the shot assist (ADR-003) | `feature/cld-vr-singles` | Ready to test |
| VR-03 | The CPU and the bot | `feature/cld-vr-singles` | Ready to test |
| VR-04 | The park, the match view, flat mode | `feature/cld-vr-singles` | Ready to test |
| VR-05 | The XR rig: paddle hand, serve hand, sticks, haptics | `feature/cld-vr-singles` | Ready to test (on the Quest 3) |
| VR-06 | Quest build: export preset, `quest_build.sh`, OpenXR Vendors 5.1.0 | `feature/cld-vr-quest-device` | Ready to test (builds and installs on the Quest 3) |
| VR-07 | Doubles (ADR-004) | `feature/cld-vr-doubles` | Ready to test |
| VR-08 | The ladder's eight teams as CPUs (ADR-005) | `feature/cld-vr-setup` | Ready to test |
| VR-09 | The lobby and MATCH SETUP in the world (ADR-005) | `feature/cld-vr-setup` | Ready to test |
| VR-10 | Spin and the sweet spot (ADR-006) | `feature/cld-vr-feel` | Ready to test |
| VR-11 | Hit sounds, haptics, PADDLE ANGLE (ADR-006) | `feature/cld-vr-feel` | Ready to test |
| VR-12 | The crowd and the announcer (ADR-006) | `feature/cld-vr-feel` | Ready to test |
| VR-13 | The ball machine (ADR-007) | `feature/cld-vr-practice` | Ready to test |
| VR-14 | HOW TO PLAY: seven lessons (ADR-007) | `feature/cld-vr-practice` | Ready to test |
| VR-15 | Menu pages and pause (ADR-007) | `feature/cld-vr-practice` | Ready to test |
| VR-16 | Venues: PARK, LAKESIDE, SUNSET, GYM, SPACE (ADR-008) | `feature/cld-vr-practice` | Ready to test |
| VR-17 | More venues: DINOSAUR, UNDERSEA, TIME of day | | Planned |
| VR-18 | Quest performance: CPU spikes fixed, PERF timing (ADR-009) | `feature/cld-vr-quest-device` | Done (measured on the Quest 3) |
| VR-19 | Ball machine 2: volley feeds, SPEED, MACHINE AT, real dinks (ADR-007) | `feature/cld-vr-machine-2` | Ready to test |

## Phase 1: singles

**VR-02, ready to test (flat mode now; the headset after VR-06).** In
flat mode: `godot --path game`, Space to serve, move with WASD, aim with
the mouse, Shift for a soft shot. Do the shots go where the ring is? Is
rally pace right?

**VR-03, ready to test.** `godot --path game -- demo`: does the CPU move
and choose shots like a rec player? Rally stats:
`godot --headless --path game -s res://tools/rally_stats.gd -- 6 1`
(about 10 to 15 shots a rally, points split).

**VR-05 / VR-06, blocked on you.** See `design/QUEST_SETUP.md`. Once the
JDK and SDK are in and the Quest is in developer mode, the remaining work
is the export preset, the vendors plugin and the first on-device check:
pose names, the paddle's angle in the hand, frame rate.

## Phase 2: doubles

**VR-07, ready to test.** `godot --path game -- doubles` (or
`-- doubles demo`). Watch for the rotation: after your side wins a point
you switch courts. Does the CPU partner leave your balls to you? Rally
stats: `rally_stats.gd -- 4 1 doubles` (about 12 shots a rally).

## Phase 3/4 (started): the ladder and MATCH SETUP

**VR-08 / VR-09, ready to test.** `godot --path game` opens the lobby.
Point with the mouse and click (or use the arrows and Enter): pick
DOUBLES, VS CHAMPS, then PLAY. The team's intro is called at the start.
At the end, REMATCH or MATCH SETUP. On the Quest, point with your
free-hand laser and pull a trigger. Do the teams feel different?
HENDERSON should be easy and the CHAMPS hard.

## Phase 3: feel

**VR-10, ready to test.** Watch the demo (`-- demo`): CPU drives dip and
kick forward off the bounce, and dinks float and check up. In the headset,
brush up the back of the ball for topspin and slice under it for
backspin. A hit off the rim should come off slower.

**VR-11, ready to test (headset).** Hit sounds change with the shot.
Haptics should be crisp from the sweet spot and dull off the rim. Try
PADDLE ANGLE at 0, 15, 30 and 45 and see which matches how you hold a
real paddle.

**VR-12, ready to test.** Listen to a match: the start, a fault call,
then the score before the serve ("four two", "three all"), match point,
the result. The crowd stands for long rallies. Check the volumes.

## Phase 5: modes

**VR-13, ready to test.** MAIN > BALL MACHINE: pick a shot, a target and a
zone, then START. Try DINK to the KITCHEN with RETURN TO KITCHEN. Does the
streak feel fair? Is the machine's pace right?

**VR-14, ready to test.** MAIN > HOW TO PLAY: play the seven lessons in
order. Do the instructions read well over the court, and is each goal
reachable for a beginner in the headset? (The bot passes all seven.)

**VR-15, ready to test.** Esc (or the menu button) pauses anything. Check
that the click that opens a page never presses a row on it.

**VR-19, ready to test.** BALL MACHINE: DRIVE, SPEED FAST, MACHINE AT
KITCHEN, RATE RAPID, and stand at your kitchen line: balls should come at
you waist-high and fast. Then DINK with RETURN TO KITCHEN: the machine
moves to their kitchen, and soft returns should count.

**VR-16, ready to test.** MATCH SETUP > VENUE: try each one, and HOME
against different teams (the GOTH CLUB play in SPACE). In the headset,
does the SUNSET's low sun get in your eyes too much?

## For you

1. **The first session in the headset** (VR-05): wake the controllers, open
   Library > Unknown Sources > Pickleball '94 VR, and check the paddle in
   your hand, the stick, the serve, the laser in the menus and the
   vibration.
2. **A GitHub repository** for this project, if you want one (it's local
   only for now). Pick its name and visibility, and I'll add the remote
   and CI.
3. **The paddle's angle in the hand.** The grip pose holds the paddle
   along the controller. VR games often tilt it 30 to 45 degrees. Decide
   on the device.
