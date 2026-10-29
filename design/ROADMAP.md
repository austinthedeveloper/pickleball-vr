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

## Releases

- **v0.3.0** (2026-10-28): the coaching update. The coach companion and
  its tablet in the headset, the coach's ball machine, rigged bodies,
  dartboard targets, passthrough, timed runs, TUNING, paddle profiles.
- **v0.2.0** (2026-10-27): the practice update. DINK PARTNER, the ball
  machine's volley feeds, the new look, the paddle tuned on logged
  strokes, FOCUS.
- **v0.1.0** (2026-10-27): the first release. Singles and doubles against
  the ladder, DINK PARTNER, the BALL MACHINE, HOW TO PLAY, five venues.

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
| VR-19 | Ball machine 2: volley feeds, SPEED, MACHINE AT, real dinks (ADR-007) | `feature/cld-vr-machine-2` | Done (played) |
| VR-20 | DINK PARTNER: a cooperative dinking CPU (ADR-010) | `feature/cld-vr-dink-partner` | Done (played) |
| VR-21 | Floor targets, partner and machine (ADR-010) | `feature/cld-vr-dink-partner` | Done (played) |
| VR-22 | Releases: version.py, release.py, CHANGELOG (ADR-011) | `main` | Done |
| VR-23 | CI: tests on every push and pull request (ADR-011) | `feature/cld-vr-ci` | Done (green on GitHub) |
| VR-24 | Style: the person, the machine, the paddle, the ball (ADR-012) | `feature/cld-vr-style` | Done (played; 72 fps, 9.5 ms GPU) |
| VR-25 | Paddle tuned on logged swings: grip, restitution, swing curve (ADR-003) | `feature/cld-vr-partner-2` | Done (played: "so much better, feeling really good") |
| VR-26 | FOCUS: long rallies dim the world (ADR-013) | `feature/cld-vr-focus` | Ready to test |
| VR-27 | The dink zone: a foot past the kitchen line (ADR-010) | `feature/cld-vr-focus` | Ready to test |
| VR-28 | HANDS: the partner volleys hard at you (ADR-014) | `feature/cld-vr-hands` | Done (played: "feel good") |
| VR-29 | FOCUS deeper and sooner: 5 in a row, nearly black by 13 (ADR-013) | `feature/cld-vr-focus-2` | Done (played: "feel good") |
| VR-30 | Blocks keep a fast ball's pace (ADR-003) | `feature/cld-vr-blocks` | Ready to test |
| VR-31 | HANDS: a soft feed, then faster (ADR-014) | `feature/cld-vr-blocks` | Ready to test |
| VR-32 | The dink zone 2.5 ft past the kitchen line (ADR-010) | `feature/cld-vr-blocks` | Ready to test |
| VR-33 | A bigger, unhurried swing lands shorter (swing curve, ADR-003) | `feature/cld-vr-blocks` | Ready to test |
| VR-34 | HANDS: more power after the feed (ADR-014) | `feature/cld-vr-blocks` | Ready to test |
| VR-35 | PADDLE page: profiles for paddle accessories (ADR-015) | `feature/cld-vr-paddle-profiles` | Ready to test |
| VR-36 | Kitchen drills: proposals (design/KITCHEN_DRILLS.md) | `feature/cld-vr-paddle-profiles` | Done (the lead picked RESETS) |
| VR-37 | RESETS: block speed-ups into the kitchen (ADR-016) | `feature/cld-vr-resets` | Played: "the right idea" |
| VR-38 | Partner feeds have a lead-in: hold, drop, strike (ADR-016) | `feature/cld-vr-resets` | Ready to test |
| VR-39 | Menus: click < to step back, > to step on | `feature/cld-vr-resets` | Ready to test |
| VR-40 | CALL THE SPOT, LINE AND CROSS, VOLLEY DINKS, ATTACK OR DINK (ADR-017) | `feature/cld-vr-drills` | Ready to test |
| VR-41 | The swing log by mode, and swings_report.py (ADR-017) | `feature/cld-vr-drills` | Ready to test |
| VR-42 | Rigged bodies for the partner and CPU players (ADR-018) | `feature/cld-vr-body` | Played: "looks ridiculous, the shirt looks painted on" |
| VR-43 | Cloth shells: a real shirt and shorts (ADR-018) | `feature/cld-vr-body` | Played: "looks better" |
| VR-44 | Dartboard targets: rings and points (ADR-019) | `feature/cld-vr-dartboard` | Played: "look good" |
| VR-45 | Practice: leaning over the kitchen line isn't a fault (ADR-019) | `feature/cld-vr-dartboard` | Ready to test |
| VR-46 | TUNING pages (debug builds) and tune.sh sync (ADR-020) | `feature/cld-vr-tuning` | Ready to test |
| VR-47 | Paddle profiles: TURN, a full TWIST, ANGLE +-90 (ADR-015) | `feature/cld-vr-tuning` | Played: "good" |
| VR-48 | DINKS: the target follows you across (ADR-019) | `feature/cld-vr-tuning` | Ready to test |
| VR-49 | Passthrough: the court in your room (ADR-021) | `feature/cld-vr-timed` | Played: "worked perfect" |
| VR-50 | Timed runs (MODE) and RECORDS (ADR-022) | `feature/cld-vr-timed` | Ready to test |
| VR-51 | Stronger hit vibration (tunable); a ding on target hits | `feature/cld-vr-timed` | Ready to test |
| VR-52 | Floor targets move after a miss too (ADR-019) | `feature/cld-vr-timed` | Ready to test |
| VR-53 | Coach companion: a web page from the headset (ADR-023) | `feature/cld-vr-coach` | Played: "worked so well" |
| VR-54 | Coach START NEW mid-run; stronger vibration; blocks keep 72% (ADR-003, 023) | `feature/cld-vr-coach` | Ready to test |
| VR-55 | The coaching suite: C-3..C-18 (ADR-024, design/COACHING.md) | `feature/cld-vr-coaching` | Ready to test |
| VR-56 | The coach's ball machine: place, bounce, speed, spin, height (C-21, ADR-024) | `feature/cld-vr-coach-machine` | Ready to test |
| VR-57 | The coach tablet beside PAUSED (C-22, ADR-024) | `feature/cld-vr-tablet` | Ready to test |
| VR-58 | REACH -30..+20 cm, 1 cm steps (ADR-015) | `feature/cld-vr-reach` | Ready to test |
| VR-59 | Full swings hit full: the swing curve's top (ADR-003) | `feature/cld-vr-drives` | Ready to test |
| VR-60 | The tablet shows the drill's own controls (ADR-024) | `feature/cld-vr-drives` | Ready to test |
| VR-61 | Drift: tracking in the swing log, PADDLE > CHECK (ADR-015) | `feature/cld-vr-drives` | Ready to test |
| VR-62 | Tablet: a clean court per drill; taps show and say what they did (ADR-024) | `feature/cld-vr-tablet-2` | Ready to test |
| VR-63 | PRANKS: soundboard, silly balls and paddles, weather, antics, voice, selfie; MERCY (ADR-025, C-23) | `feature/cld-vr-pranks` | Ready to test |

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

**VR-55, ready to test.** The coaching suite (design/COACHING.md tracks
each idea). On the phone: tap modes on the court (Target, Feed, Zone,
Line), cues, a challenge, the sliders, a workout, then tap a shot to
replay it and LOAD the history.

**VR-53, ready to test.** MAIN > COACH > COACH MODE ON, then on a phone
on the same Wi-Fi open the address it shows and enter the code. Run a
drill from the phone; watch the shots land on its court.

**VR-49 / VR-50, ready to test.** MAIN > PASSTHROUGH ON: is it only the
court in your room, and does the floor line up? PRACTICE PARTNER > MODE
1 MIN: play a few runs, then check RECORDS.

**VR-46, ready to test.** PAUSED > TUNING (debug builds): step the
drills' numbers while you play. Say "sync the tuning" and
`game/tools/tune.sh sync` makes them the defaults.

**VR-43 to VR-45, ready to test.** The partner wears a real shirt and
shorts (ADR-018). Targets are dartboards that score 1, 2 or 3 points,
and leaning over the kitchen line is fine in practice (ADR-019). Play
CALL THE SPOT and VOLLEY DINKS again; the log now says how far each
ball missed by.

**VR-40 / VR-41, ready to test.** PRACTICE PARTNER > DRILL: try CALL
THE SPOT, LINE AND CROSS, VOLLEY DINKS and ATTACK OR DINK, a few
minutes each, in one session. Then `game/tools/swings.sh > s.log` and
`python3 game/tools/swings_report.py s.log` gives a report per mode.

**VR-38 / VR-39, ready to test.** Every partner feed now starts with the
ball held up in their hand, then dropped and struck: about 0.85 s to see
it coming. Is that enough warning without making RESETS slow? In any
menu, click the < of a setting to step it back.

**VR-37, played: "the right idea".** MAIN > PRACTICE PARTNER > DRILL RESETS. You
start mid-court. Block each drive soft into their kitchen, under the red
line over the net. Are the drives the speed and height of a real
speed-up? Is the line fair on each level?

**VR-35, ready to test.** MAIN > PADDLE. With an accessory on, pick
PROFILE 1 and step ANGLE, TWIST and REACH until the paddle you see sits
where the real one is. Does anything else need setting (the face further
to one side, say)?

**VR-33 / VR-34, ready to test.** DINKS: a bigger but unhurried swing
should land in the zone, not on its edge. Do drives from the baseline
still feel right (average swings are up to 10% softer)? HANDS: the ball
after the feed is firmer, and full pace is 8% faster.

**VR-30 / VR-31 / VR-32, played: the soft start is good.** HANDS: each rally opens with
a soft feed at you, then the next three balls build to full pace. Block
one (paddle out, no swing): it should carry back over the net. DINKS:
the gold zone now reaches 2.5 ft past their kitchen line.

**VR-29, played and approved.** FOCUS, stronger: at 5 in a row the world
starts to darken, deeper every 2, nearly black by 13. Too much, or about
right?

**VR-28, played and approved.** MAIN > PRACTICE PARTNER > DRILL HANDS. Stand
at your kitchen line and volley: the partner comes up to theirs and
volleys every ball back at you, hard, about waist to chest high. Try
EASY, MEDIUM and HARD (7, 10 and 13 m/s). Is HARD fast enough, or too
fast? Does the count (HANDS IN A ROW) feel fair?

**VR-26 / VR-27, ready to test.** DINK PARTNER: string 8 dinks together
and the world starts to darken, deeper every couple of dinks, back when
the streak breaks. A dink landing just past their kitchen line now counts.

**VR-24, played and approved** (72 fps, GPU 9.2-9.8 ms of 13.9). DINK PARTNER: watch the partner split-step,
shuffle, and swing through your ball. BALL MACHINE: the head turns to
each feed, a ball rolls into it first, and the light blinks just before.
Does it all feel smooth at 72 fps?

**VR-20 / VR-21, played and approved, fixes included:** the count
is dinks in a row and resets outside their kitchen, the announcer matches
it, PARTNER can be CROSS COURT, menus don't move you, and holding the
Meta button recenters you down the court.

**VR-20 / VR-21, first notes.** MAIN > DINK PARTNER > START. Stand
at your kitchen line and dink. Does the partner feel like a patient
practice partner? Do its dinks land where you'd want them? Try EASY,
MEDIUM and HARD, and aim for the gold circle (TARGETS). On the BALL
MACHINE, turn TARGETS on with RETURN TO DEEP.

**VR-19, played and good.** BALL MACHINE: DRIVE, SPEED FAST, MACHINE AT
KITCHEN, RATE RAPID, and stand at your kitchen line: balls should come at
you waist-high and fast. Then DINK with RETURN TO KITCHEN: the machine
moves to their kitchen, and soft returns should count.

**VR-16, ready to test.** MATCH SETUP > VENUE: try each one, and HOME
against different teams (the GOTH CLUB play in SPACE). In the headset,
does the SUNSET's low sun get in your eyes too much?

## For you

- **Kitchen drills:** all but THIRD SHOT DROPS are built (VR-37, VR-40).

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
