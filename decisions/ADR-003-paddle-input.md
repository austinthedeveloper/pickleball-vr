# ADR-003: The paddle is the input; a shot assist helps it land

**Status:** Accepted (2026-10-27)

## Context

In first person there are no shot buttons. The racket is in your hand.
VR sports games that leave contact to raw physics feel honest, but
beginners net or overhit most shots. Controllers also report poses once
a frame (72-120 Hz), and a fast paddle moves 10+ cm between samples.

## Decision

- **A human's input per tick** (`SimTypes.HumanInput`): the head's ground
  position, the paddle face's centre and normal, the free hand's
  position, and "let go of the ball". The view samples the controllers,
  interpolates them to the sim's 120 Hz ticks, and quantises them to ints.
  Nothing else crosses into the sim.
- **Contact is swept.** The face is a disc (8 x 10 in paddle: 115 mm)
  of some thickness. Each tick the sim tests the ball's path against the
  face's motion since the last tick, so a fast swing can't tunnel. Both
  faces hit (forehand and backhand). The response is a restitution bounce
  off the moving face (e = 0.5), so paddle speed and angle set pace and
  direction.
- **The shot assist** (MATCH SETUP: OFF / LOW / MID / FULL = 0/35/65/100%,
  MID by default) works out where the raw shot would land, clamps that
  spot inside the lines (into the service box on a serve, over the net if
  it would net), and pulls the ball's velocity that share of the way
  toward the same-pace shot to that spot. Your aim and pace still count;
  the assist only rescues the miss.
- **Serving:** the ball sits in your free hand. Pull that hand's trigger
  to let go: lift as you pull for a toss, hold still for a drop (the drop
  serve is legal). Then hit it. A toss nobody hits is served again, with
  no fault.
- **Flat mode and DEMO** drive the same input from `Bot`, which plans a
  swing through the ball on the sim's own prediction. In flat mode you
  move and aim and the bot swings; in DEMO it does all of it.

## Consequences

- Tests can play whole matches with nothing but `Sim.step([bot.input()])`.
- Spin is left out of the first contact model. Its ADR comes with the
  feature (roadmap phase 3).
- Body reach isn't enforced in VR: the paddle is wherever your hand is.
  Locomotion is the view's job (thumbstick, comfort options).
