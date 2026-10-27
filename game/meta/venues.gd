## The venues (ADR-008): the port kit's, rebuilt in 3D. The view builds
## them (World); this is just their names and who calls which home.
class_name Venues
extends RefCounted

const PARK := 0
const LAKESIDE := 1
const SUNSET := 2
const GYM := 3
const SPACE := 4
const NAMES := ["PARK", "LAKESIDE", "SUNSET", "GYM", "SPACE"]
## Port kit venues not built yet stand in with the nearest one built.
const STAND_INS := {"DINOSAUR": "GYM", "UNDERSEA": "LAKESIDE"}


## A port kit venue name to one of ours.
static func index(name: String) -> int:
	var i := NAMES.find(STAND_INS.get(name, name))
	return maxi(i, 0)


## The setting's venue (0 = HOME, the opponent's) to one of ours.
static func resolve(setting: int, opponent: int) -> int:
	if setting > 0:
		return clampi(setting - 1, 0, NAMES.size() - 1)
	if opponent < 0:
		return PARK
	return index(String(Opponents.team(opponent).get("venue", "PARK")))
