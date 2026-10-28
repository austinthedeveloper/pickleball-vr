## The ladder's eight teams (data/opponents.json, imported from the port
## kit by tools/import_opponents.py): names, lines, shirts, CPU styles.
class_name Opponents
extends RefCounted

const PATH := "res://data/opponents.json"

static var _teams: Array = []


static func teams() -> Array:
	if _teams.is_empty():
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_teams = d["opponents"]
	return _teams


static func team(i: int) -> Dictionary:
	var t := teams()
	return t[clampi(i, 0, t.size() - 1)]


static func names() -> Array[String]:
	var out: Array[String] = []
	for t in teams():
		out.append(String(t["team"]))
	return out


## The team's players on the far side: slot 2 (and 3 in doubles).
static func apply(cfg: SimTypes.MatchConfig, i: int) -> void:
	var players: Array = team(i)["players"]
	cfg.styles = [null, null, SimTypes.CpuStyle.from_dict(players[0]["style"]),
		SimTypes.CpuStyle.from_dict(players[mini(1, players.size() - 1)]["style"])]
	cfg.opponent = i


static func player(i: int, slot: int) -> Dictionary:
	var players: Array = team(i)["players"]
	return players[clampi(slot - 2, 0, players.size() - 1)]


static func shirt(i: int, slot: int) -> Color:
	var c: Array = player(i, slot)["shirt"]
	return Color(c[0], c[1], c[2])


static func shorts(i: int, slot: int) -> Color:
	var c: Array = player(i, slot)["shorts"]
	return Color(c[0], c[1], c[2])


## Which of the ladder's players get the female body (ADR-018).
const WOMEN := ["MARGE", "RAVEN", "LANI", "MIA", "JADE"]


static func female(i: int, slot: int) -> bool:
	return String(player(i, slot)["name"]) in WOMEN
