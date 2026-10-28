# ADR-024: The coaching suite

**Status:** Accepted (2026-10-28)

## Context

After the first coach companion (ADR-023), the lead asked for every idea
from the brainstorm: "I love every single idea ... knock it out in the
order you'd like". `design/COACHING.md` tracks each one (C-1 to C-20).

## Decision

**Where things live.**
- `scenes/coach_desk.gd` (CoachDesk) takes a coach's messages and keeps
  the coaching state: the session being saved, a challenge, a workout,
  the court marks. It acts only through what main and the view already
  do. Main keeps the views and menus, and delegates to it.
- `meta/sessions.gd` saves sessions.
- The view measures the shots and shows the cues, challenges and marks.

**Shots measure more (C-3 to C-6, C-17).** At your hit the view records:
- the side (forehand when the ball is on your paddle side of your head);
- how far behind the kitchen line you were;
- where on the face it struck, in the paddle's own frame;
- your paddle's height when the other side last struck;
- the ball's path in, sampled every 3 ticks.

Then it records how high the ball crossed the net, and its path out.
All of this is display side, like the swing log.

**Coach actions that change a drill are sim commands (C-8, C-9).**
- `CMD_PIN_TARGET` puts the target where the coach tapped and keeps it
  there through hits, misses and side switches, until it's let go.
- `CMD_FEED_TO` sends the partner's next dink to the tapped spot.

Both go through `MatchView.command` → `Sim.step`, so a run stays
deterministic and replays exactly.

**Display-only actions stay in the view.**
- Cues (C-7) appear over the net for 3.5 s with a soft ding.
- A challenge (C-12) sits above that, with its progress.
- Zones and lines (C-14) glow cyan on the floor. They're drawn after
  the net's tinted mesh so it doesn't dim them. The desk re-applies
  them to every new view.

**Sessions and players (C-10, C-18).**
- Every practice shot is saved to `user://sessions/`, one JSON file per
  session. A file is written every 5 shots and at every timed run's end.
- The newest 60 sessions are kept. Replay paths are dropped from the
  file.
- A file name has the time, the player and a count, so two sessions in
  one second don't collide (a test caught that).
- Records are kept per player. The save's `records` key becomes
  `records.by_player`; old runs go to PLAYER 1 and load as they were.
  Missing keys fill, so there's no save version bump.

**Sliders (C-11)** show the drill's TUNING values at its level and
change them for this session only. **Workouts (C-13)** are saved in
Settings. Every step is timed, and the next drill starts 5 s after time
is up.

**The page does the analysis.** Insights (C-15), the breakdown, the
sweet-spot map, replays (C-17), history trends and the report (C-16)
are all computed in the coach's browser from the shots. The headset
only stores and sends.

## Consequences

- Several phones can watch and coach at once (C-19). They all see the
  same marks, target and challenge from the state.
- Remote coaching (C-20) needs a relay server and stays Later.
- The page is one file of about 50 KB with no libraries. It was tried
  end to end against the flat-mode game in a browser.

## Amendment (2026-10-28): the coach's ball machine (C-21)

"The coach on his screen starts the ball machine. They can then place
the machine anywhere on the screen, then place where they want the ball
to bounce. They can also control ball speed, spin, and height."

- START THE MACHINE starts BALL MACHINE with the coach's machine feeding
  it.
- On the page's court, Machine places the machine anywhere on their side,
  and Bounce places the spot on your side where its balls bounce.
- Sliders set the speed (3 to 20 m/s over the ground), the spin (100%
  backspin to 100% topspin), the height over the net (5 cm to 3 m) and a
  ball every 1.25 to 8 s.
- All of it is one sim command, `CMD_MACHINE`. `Drill.coach_machine`
  keeps each value in reach, and `_coach_feed` aims with
  `Aim.shot(..., clear)`, the same solver the drills use. A change
  reaches the machine at its next ball. RESTART leaves the machine where
  it was put. The machine's model stands at its x as well as its z.
- The settings are saved, so the next session starts where the coach
  left off.

`test_coach` checks the bounce lands within 30 cm of the coach's spot
across speeds, spins, heights and positions, and that it crosses the net
at least as high as asked.

## Amendment (2026-10-28): the coach tablet in the headset (C-22)

"What if the coach companion app also had a representation in the game?
So when you pause, you'll see the companion off to the side."

The phone's page can't run in the headset: there's no web view on the
Quest in Godot. So the tablet is native:
- **What it is.** A 2D panel of Godot Controls in a SubViewport, on a
  quad. It stands about 50° to your left of PAUSED, turned to you. It
  appears only in practice drills: not matches, not lessons.
- **Pointing.** The laser or the mouse hits the quad, and the hit
  becomes the panel's own mouse events, so its buttons are real buttons.
  A new panel ignores the click that opened it, as menus do.
- **What it shows.** The run (score or streak, time, good %, net
  clearance), the court with this session's shots, the target, the feed
  and the coach's machine, what the numbers say, and forehand against
  backhand.
- **What it does.** Court taps place the target, the next feed, the
  machine or its bounce. Steppers set the machine's speed, spin, height
  and interval, and START THE MACHINE starts it.
- **Same paths as the phone.** Everything goes through
  `CoachDesk.handle`, so the commands are the phone's: sim commands stay
  sim commands.
- **No phone needed.** It works with COACH MODE off; the desk always
  keeps the session's shots (`live`). Its insights are a GDScript
  version of the page's (`CoachDesk.insights`).

## Amendment (2026-10-28): the tablet follows the drill

In a partner drill the tablet "was still showing the ball machine and the
config values for it". Now each drill shows its own controls:
- **A partner drill:** taps for TARGET and FEED, and PACE AND SIZE
  steppers. These are the drill's own live sliders (C-11), the same
  list the phone gets.
- **The ball machine:** taps for TARGET, MACHINE and BOUNCE, and the
  machine's speed, spin, height and interval with START.
