# ADR-023: The coach companion: a web page served by the headset

**Status:** Accepted (2026-10-28)

## Context

"Crazy idea: Companion app for coaches. They can control the drills,
see stats, shot placement, etc." The lead asked for a first version.

## Decision

**No app to install.** With COACH MODE on, the game serves its own page:
- HTTP on port 8094 serves `coach/index.html` and nothing else.
- A WebSocket on 8095 carries JSON both ways.

A coach opens `http://<headset IP>:8094` on a phone or tablet on the same
Wi-Fi. MAIN > COACH turns it on and shows the address and a four-digit
code. The code is new each launch. A socket that hasn't sent the code
gets nothing and can do nothing. The page remembers the code in the
browser for reconnecting.

**What the coach sees.**
- The state, four times a second: lobby, playing or paused; the run's
  name; score or streak, the clock, best, good %; the drill as set.
- Every one of your practice shots as it ends: the result, where it
  landed on their side, the dartboard ring and how far off it was, ball
  speed, contact height, and volley or not.

The page draws:
- **Shot placement:** a top-down view of their side with the kitchen,
  the dink zone, the target's rings and each landing, coloured on the
  board, good or miss. It can show this run or the whole session.
- **A per-mode session table:** shots, good %, mean speed and the most
  common miss.
- **The last shots.**
- **The records** for the setup set, with a bar for each recent run.

**What the coach controls.** The PRACTICE PARTNER setup (DRILL,
DIFFICULTY, MODE, TARGETS, PARTNER side, SPREAD) and START, PAUSE,
RESUME, RESTART and MENU. These go through main exactly as the
headset's own menu presses do. In the lobby, the headset shows the
PRACTICE PARTNER page with what the coach set.

**Network.** The Quest export now asks for the INTERNET permission so it
can listen. Nothing listens unless COACH MODE is on. The page uses no
libraries and no outside requests.

**The view.** `MatchView.shot_done` reports your shot when a drill
result ends it: the hit from `EVENT_HIT`, and the landing from the first
bounce on their side. It's display side only, like the swing log.

## Consequences

- Plain HTTP on the local network. The code keeps strangers on the same
  Wi-Fi out, but the traffic isn't encrypted. That's fine for drills; it
  isn't for anything private.
- The session's shots live in the coach's open page. They're gone when
  the page closes. Saving sessions, comparing them over weeks, and BALL
  MACHINE control are the next steps.
- `test_coach` covers the page over HTTP, the code on a real socket, the
  view's shot reports and the commands in main. In a flat-mode run, the
  page drove a full timed run end to end.

## Amendment (2026-10-28): START mid-run

The lead tested it ("it worked so well"). A coach who changed the drill
mid-run had to go to MENU and then START. Now START is always there:
mid-run it reads START NEW and starts the drill as set now. The run in
progress is let go, and its best is kept, as MENU would keep it.
