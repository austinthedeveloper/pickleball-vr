# Coaching: the companion and what's next

The coach companion (ADR-023) is a page the headset serves to a phone on
the same Wi-Fi. The lead asked for every idea from the brainstorm of
2026-10-28 ("I love every single idea"). This sheet tracks them. Status:
**Built** (works, tested), **Building**, **Planned**, **Later** (needs
something we don't have).

Data the game already had before this sheet: per shot, the result, the
landing, the ring and distance off the board, ball speed, contact height
and volley. The swing log adds paddle speed, face angle and off-centre.
The headset gives head and hand positions every frame. The sim is
deterministic: a rally can be re-run exactly.

| # | Idea | Status | Notes |
|---|------|--------|-------|
| C-1 | Live state, shot placement, session table, last shots, records, drill controls | Built | ADR-023, VR-53 |
| C-2 | START NEW mid-run | Built | VR-54 |
| C-3 | Net clearance on every shot | Built | Height over the tape as the ball crosses; the court can colour dots by it |
| C-4 | Forehand / backhand split | Built | Ball beside the head on the paddle side: forehand. Breakdown table |
| C-5 | Sweet-spot map | Built | Where on the face, in the paddle's own frame (headset or flat paddle) |
| C-6 | Footwork and ready position | Built | Behind the kitchen line at contact; paddle height as they strike (ready at 0.8 m and up) |
| C-7 | Cue buttons to the headset | Built | Six presets and your own; big over the net for 3.5 s with a soft ding |
| C-8 | Tap to place the target | Built | `CMD_PIN_TARGET`: stays until LET THE TARGET MOVE; a drill without a board gets one |
| C-9 | Tap where the partner feeds next | Built | `CMD_FEED_TO`: the partner's next dink lands there |
| C-10 | Saved sessions, history, trends | Built | `meta/sessions.gd`: user://sessions, newest 60; good % trend; open any past session |
| C-11 | Live pace and target-size sliders | Built | The drill's TUNING values at its level; live for this session, not saved |
| C-12 | Challenges | Built | In a row, on the board in a row, good balls, a score; shown over the net; applause when done |
| C-13 | Workouts: drill sequences | Built | Built on the phone, saved on the headset; each step timed; 5 s between drills |
| C-14 | Draw on the court | Built | Zones and lines, glowing cyan on the floor; kept across drills until cleared |
| C-15 | Automatic insights | Built | From the shots: clearance, the weak side, low contact, hard hands, paddle up, standing back, distance off the board |
| C-16 | Shareable session report | Built | Print / save as PDF (placement, breakdown, insights), or copy a text summary |
| C-17 | Rally replay | Built | Tap a shot: the ball in and out, from above and the side, about real time. Live session only |
| C-18 | Player profiles | Built | Each player's own records and sessions; records from before go to PLAYER 1 |
| C-19 | Two coaches or a parent watching | Built | Several phones can connect at once already |
| C-20 | Remote coaching over the internet | Later | Needs a relay server: cost and hosting |

## Built in one go (2026-10-28, ADR-024)

C-3 to C-18 shipped together on `feature/cld-vr-coaching`. They were
tried against the flat-mode game from a browser: a run started, a target
pinned, a feed placed, a cue, a challenge, marks, sliders, a workout
step, a replay, history, and a past session opened. `test_coach` covers
them.

Known limits:
- Replays are only for the session open on the phone. The saved
  sessions keep the numbers, not the ball paths.
- Sliders change values for this session only. Saving them as defaults
  goes through TUNING and `tune.sh sync`.
- A workout's steps are PRACTICE PARTNER drills, each timed.
