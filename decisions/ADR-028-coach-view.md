# ADR-028: COACH VIEW, watching a player's drill in a coach's game

**Status:** Accepted (2026-10-29). Watching (VR-79) and the coach's
controls on their screen (VR-80) are built. Instant replay (VR-81) is
planned.

## Context

The coach page (ADR-023, ADR-026) shows numbers and a 2D court. The lead
asked for more: "a way to be a coach and he can see me hitting on the
court", with the coach still in control, from a panel on screen or a
phone.

Three things already existed. The VR sim is deterministic (ADR-002), and
since ADR-027 it saves and loads its whole state. COACH FROM ANYWHERE
gives the headset a room on the relay that takes 8 guests. The friend's
body (ADR-027) is drawn from real paddle and hand inputs.

## Decision

**A coach watches by running the drill too.** In the coach's game (a Mac,
or another headset): MAIN > WATCH A PLAYER, the four letters of the
room the player's COACH page shows, WATCH ROOM. The game joins that room
as one more guest (`pb94-vr-coach`, as the phones do) and says
`{"type": "watch"}`.

**The stream (`net/watch.gd`).** For each guest that asked, the player's
headset (CoachDesk with `Watch.Feed`) sends two kinds of message:

- **"W", the state:** the config whole (`Watch.config_save`: the CPUs'
  styles and the drill's settings too), `Sim.save_state()`, and a line
  about what's on (the player, the mode, in the menu or not). It goes
  when a coach joins, mid-drill or not, and whenever a new view starts:
  a drill, the lobby's demo, a lesson.
- **"T", the ticks:** each tick's input (slot 0's, the HumanInput as 12
  ints) and commands, in batches of 8, so about 15 messages a second. The
  relay closes a connection past 200 a second. A hash of the state rides
  along every 120 ticks.

`MatchView.tap` records each tick as it steps, and the desk drains it
into the batches. Only guests that asked to watch get the stream, and
`Coach.broadcast` (the phones' JSON) skips them.

**The coach's game replays it (`Watch`).** It builds the same Sim from
"W" and steps it on the inputs, keeping 24 ticks (200 ms) in hand and
stepping two a tick when it falls far behind. A hash that differs (a
TUNING change on the player's side, say) or a missing batch asks for the
state again, and the drill rebuilds from it.

**On the coach's screen.** MatchView's watch mode is a spectator
(`setup(..., watching)`). The player is a human Avatar on their real
paddle, in drills too, with the partner or machine as the player sees
them. On the Mac, four cameras follow the player: BEHIND, SIDE, ACROSS
and ABOVE (keys 1 to 4, or CAMERA in the menu). In a headset, the coach
stands at the lobby's spot beside the court and can walk. The menu (Esc
or the menu button) has CAMERA, BACK TO WATCHING and STOP WATCHING; the
replay plays on behind it.

**The coach's controls, in the coach's game (VR-80).** The coach tablet
(C-22) now talks to a source instead of CoachDesk itself: `handle(msg)`,
`state()`, `run_shots()`, `pending`, `machine_settings()`,
`current_view()`.

- **Two sources.** In the headset the source is CoachDesk, as before. In
  a watching game it's `RemoteCoach`, which sends each tap to the
  player's headset as the phone page's message over the watch link, and
  shows the state and shots the headset broadcasts to its coaches. The
  watching games get that JSON now, next to their stream.
- **The session's own controls,** for a remote source only: the drill and
  level, START, PAUSE or RESUME, RESTART, MENU, and the six cues, as on
  the phone. Then the tablet's own: the numbers, the court (tap for the
  target or the partner's next ball, or the machine's spot and bounce),
  what the numbers say, the partner's pace and size, the ball machine.
- **On a Mac** the tablet is drawn on the screen (`overlay`), at the
  right, as tall as it fits, and the mouse uses it directly. Tab hides it
  and brings it back. The picture's centre moves left (the camera's
  `h_offset`) so the player stays in the part that's left.
- **In a headset** the tablet stands beside the watching menu, as it
  does beside PAUSED.
- The phone page still works alongside, in the same room.

A fix to VR-79 came with it. The watching menu (Esc) stands at the
lobby's spot, which a following camera may not see, so on a Mac the
camera turns to it while it's open.

**Not yet watchable:** a FRIENDLY DINK match (ADR-027). Its other
player's inputs aren't on the headset in time. The coach's page says so.

## Consequences

- **Measured (2026-10-29), two games on the Mac through the live relay:**
  the player's room in 22 s (the relay asleep), the coach watching 0.28 s
  after WATCH ROOM, and 30 s later 30 ticks (0.25 s) behind with the same
  state as the player's and no resyncs. When the player switched to the
  ball machine, the coach's screen followed in 0.09 s.
- **Measured (VR-80), coaching from the Mac through the live relay:** the
  player paused 52 ms after the coach's tap, with the level the coach
  picked; RESUME with the coach's target took 61 ms; the target showed in
  the coach's replay 235 ms later, still in step.
- **Cheap:** one guest's stream is a few KB a second through the relay.
- **Exact, not a video:** the coach's game can show any angle. Because it
  holds the inputs, instant replay (VR-81) is a matter of keeping them and
  stepping a saved state again.
- **The player's settings for the view** (the partner's look, a prank's
  silly ball) aren't sent; the coach sees the classic looks.
- Tests: `test_watch` covers a drill replayed exactly from its stream
  (joined mid-drill, a coach's command in it), a ladder match's and a
  drill's config whole, a drift and a gap asking for the state again, an
  online match not watched, and two whole games, the player in a drill
  and the coach watching through the menus over a stand-in relay. That
  last one checks the coach's state against the player's at the same
  tick, the player's body, the camera menu, a new drill following, and
  STOP. VR-80 adds, in the same game: the panel on the screen, its
  state from the player's headset, the level, PAUSE and RESUME, a cue
  and a target from the panel reaching the player, the target then in
  the coach's replay, and the camera turning to the menu. The stand-in
  relay moved to `tests/stand_in_relay.gd`.
