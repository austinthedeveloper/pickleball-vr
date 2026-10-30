## COACH VIEW's controls (ADR-028, VR-80): the coach tablet's source in a
## coach's game watching a player. What a tap asks goes to the player's
## headset as the phone page's message, over the watch link; what the
## tablet shows is the state and shots the headset sends its coaches. It
## answers the tablet as CoachDesk does (handle, state, run_shots,
## pending, machine_settings, current_view).
class_name RemoteCoach
extends RefCounted

const KEEP := 400                    ## shots kept, as CoachDesk.LIVE_KEEP

var remote := true
var link: RelayLink
var main: Node                       ## for the view on screen
var pending := {}                    ## the player's taps while paused: theirs to show, not ours
var _state := {}
var _shots: Array = []
var _run := ""                       ## the drill the shots are from


func _init(l: RelayLink, owner_main: Node) -> void:
	link = l
	main = owner_main


## A message from the player's headset to its coaches.
func on_json(msg: Variant) -> void:
	if not msg is Dictionary:
		return
	match String(msg.get("type", "")):
		"state":
			_state = msg
			var run := String((msg.get("run", {}) as Dictionary).get("name", ""))
			if run != _run:
				_run = run
				_shots = []              # a new drill: its own numbers, as on the headset
		"shot":
			_shots.append(msg)
			if _shots.size() > KEEP:
				_shots.pop_front()


func handle(msg: Dictionary) -> void:
	if link:
		link.send_json(msg)


func state() -> Dictionary:
	return _state


func run_shots() -> Array:
	return _shots


func machine_settings() -> Dictionary:
	return _state.get("machine", {})


func current_view() -> MatchView:
	return main.view if main else null
