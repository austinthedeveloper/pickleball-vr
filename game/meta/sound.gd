## SOUND (VR-100): how loud the ambience, the crowd and the announcer are,
## each on its own audio bus. The ambience and the crowd send through
## ZEN's bus (ADR-031), so HUSH still muffles them; the announcer goes
## straight out. Display and sound only: the sim never hears of it.
class_name Sound
extends RefCounted

const AMBIENCE := "Ambience"
const CROWD := "Crowd"
const ANNOUNCER := "Announcer"
const LEVELS := ["OFF", "LOW", "MID", "FULL"]
const GAIN := [0.0, 0.3, 0.6, 1.0]           ## each level's share of full


## The bus `name`, made once: sending to ZEN's bus, or (the announcer) Master.
static func bus(name: String) -> int:
	var i := AudioServer.get_bus_index(name)
	if i < 0:
		AudioServer.add_bus()
		i = AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, name)
		AudioServer.set_bus_send(i, "Master" if name == ANNOUNCER else Zen.BUS)
	if name != ANNOUNCER:
		Zen.bus()                            # ...which must exist first
		AudioServer.set_bus_send(i, Zen.BUS)
	return i


## The settings' levels on the buses.
static func apply(s: Settings) -> void:
	_level(AMBIENCE, s.ambience_level)
	_level(CROWD, s.crowd_level)
	_level(ANNOUNCER, s.announcer_level)


static func _level(name: String, level: int) -> void:
	var i := bus(name)
	var g: float = GAIN[clampi(level, 0, GAIN.size() - 1)]
	AudioServer.set_bus_mute(i, g <= 0.0)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(g, 0.0001)))
