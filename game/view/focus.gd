## FOCUS (ADR-013, after the port kit's rally heat, port ADR-068): in a long
## rally everything outside the court dims, step by step, a spotlight on
## the rally: the court, net, players and ball stay bright. The port kit's
## numbers, counted in shots by both sides: the first step at 15, one more
## every 5, each 13% darker, capped at 62% so it never goes black. In
## practice only your shots count, so a practice streak counts double
## (the lead's ask: "the same numbers, halved").
##
## The first piece of the "zen state" the lead wants to grow: more can hang
## off the same amount later (sound, colour, the crowd's hush).
class_name Focus
extends RefCounted

const AT := 15                       ## shots (both sides): the first step
const STEP := 5                      ## shots between steps
const ALPHA := 0.13                  ## each step's darkness
const MAX := 0.62                    ## never black
const EASE_IN := 2.0                 ## per second: in over about half a second
const EASE_OUT := 1.2                ## ...out a little slower


## How dark at a rally of `shots` (both sides' shots).
static func amount(shots: int) -> float:
	if shots < AT:
		return 0.0
	return minf((1 + (shots - AT) / STEP) * ALPHA, MAX)


## The rally as focus counts it: a match's shots, a practice streak doubled.
static func shots_of(sim: Sim) -> int:
	if sim.drill:
		return sim.drill.streak * 2
	return sim.shots if sim.phase == K.PHASE_LIVE else 0
