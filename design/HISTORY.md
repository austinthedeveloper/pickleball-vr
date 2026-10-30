# VR history: what to try, as each task landed

The notes that went with each task on `design/ROADMAP.md` when its branch
landed: what to try in the headset, and what you said after playing it.
They moved here in the 2026-10-28 cleanup so the roadmap stays short. The
index on the roadmap keeps every task's status.

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

## Phase 7: sharing and online

**VR-74..77, played (2026-10-29): the Quest against the Mac through the
relay, moving and turning the paddle: "it all worked".** Dinking online
with a friend (ADR-027).
Both of you install the same version (0.6.0 or later; the headset says
YOUR FRIEND HAS ... if not).
1. One picks MAIN > PLAY A FRIEND > HOST: OPEN A ROOM. The page shows
   YOUR ROOM: and four letters. The first room after a quiet spell takes
   up to 25 seconds (the relay waking up).
2. The other picks PLAY A FRIEND, sets ROOM LETTER 1 to 4 to those
   letters (the stick left and right, or click the < and >), and JOIN.
3. The match starts on both: FRIENDLY DINK. You stand at your kitchen
   lines (the guest at the far end); whoever has the ball drops it and
   dinks; the board counts the rally and keeps the BEST. Whoever misses
   starts the next one.

Without a second headset: the Mac's flat mode (`godot --path game`)
plays a friend too. The mouse aims, dinks are soft and Shift drives.
Things to look for:
- Does your friend's ball arrive smoothly, or jump?
- Does their body and paddle look like them?
- Does anything ever freeze?

The menu button shows BACK TO THE GAME and LEAVE; the match doesn't stop
behind it.

**VR-79, ready to test: COACH VIEW (ADR-028).**
1. On the Quest: COACH > COACH MODE ON, COACH FROM ANYWHERE ON. Note the
   room (ANYWHERE   ROOM XXXX). Start a drill, PRACTICE PARTNER for one.
2. On the Mac (`godot --path game`): MAIN > WATCH A PLAYER, set the four
   letters, WATCH ROOM.
3. You on court, about a quarter of a second behind. Keys 1 to 4 change
   the camera: BEHIND, SIDE, ACROSS, ABOVE. Esc for the menu.
4. Change drills on the Quest: the Mac follows.
5. **The coach's panel (VR-80),** on the right of the Mac's screen (Tab
   hides it): pick the drill and level, START, PAUSE, a cue, and click the
   court for the target or the partner's next ball. The Quest should do
   it at once. The phone page still works alongside.
6. **Instant replay (VR-81):** after a shot, R on the Mac (or REPLAY on
   the panel): THE LAST SHOT, held on the contact at 1/2. S changes the
   speed, Space pauses, Left and Right step a frame, 1 to 4 the camera,
   Backspace back to live. Does the paddle face at contact look like the
   one you hit with?

Look for: your swing as the coach sees it (does the body read as you?),
and any hitch when a drill starts.
