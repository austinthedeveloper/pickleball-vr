## The courtside scoreboard (left of the net, angled to the near side) and
## the call: OUT!, NET!, POINT, GAME, floating over the far court.
class_name Scoreboard
extends Node3D

const BOARD := Color(0.08, 0.1, 0.16)

var them := "CPU"
var drill := false                   ## practice: the streak, or the lesson's count
var score_label: Label3D
var info_label: Label3D
var call_label: Label3D
var _call_time := 0.0


func _ready() -> void:
	var board := Node3D.new()
	board.position = Vector3(-(K.NET_POST_X / float(K.M)) - 0.9, 1.9, -0.4)
	board.rotation_degrees = Vector3(0, 35, 0)
	add_child(board)
	var panel := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.9, 1.0, 0.06)
	panel.mesh = bm
	panel.material_override = World.material(BOARD)
	board.add_child(panel)
	for s in [-1, 1]:
		var leg := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.04
		cm.bottom_radius = 0.04
		cm.height = 1.9
		leg.mesh = cm
		leg.material_override = World.material(Color(0.2, 0.2, 0.22))
		leg.position = Vector3(s * 0.8, -0.95, -0.02)
		board.add_child(leg)
	score_label = _label(board, Vector3(0, 0.08, 0.035), 150, Color(1.0, 0.85, 0.2))
	info_label = _label(board, Vector3(0, -0.32, 0.035), 80, Color(0.85, 0.9, 1.0))
	call_label = _label(self, Vector3(0, 2.4, -3.0), 260, Color(1, 1, 1))
	call_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	call_label.outline_size = 24
	call_label.visible = false


func _label(parent: Node3D, at: Vector3, size: int, c: Color) -> Label3D:
	var l := Label3D.new()
	l.font_size = size
	l.pixel_size = 0.002
	l.modulate = c
	l.outline_modulate = Color(0, 0, 0, 0.8)
	l.position = at
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l


## Scores read server first, as the umpire calls them.
func show_from(sim: Sim, delta: float) -> void:
	if drill:
		var d := sim.drill
		var tgt := "   TARGETS %d" % d.target_hits if d.targets else ""
		if d.partner:
			score_label.text = "%d" % d.rally
			info_label.text = "RALLY   BEST %d%s" % [d.best_rally, tgt]
		elif d.goal > 0:
			score_label.text = "%d / %d" % [mini(d.good, d.goal), d.goal]
			info_label.text = "LESSON" if d.stage != Drill.DONE else "DONE!"
		else:
			score_label.text = "%d" % d.streak
			info_label.text = "STREAK   BEST %d%s" % [d.best, tgt]
		_fade(delta)
		return
	var srv := sim.serving_team
	score_label.text = "%d - %d" % [sim.score[srv], sim.score[1 - srv]]
	var who := them
	if srv == 0:
		who = "YOU" if sim.server_slot == 0 else "PARTNER"
	match sim.phase:
		K.PHASE_MATCH_RESULT:
			info_label.text = "YOU WIN!" if sim.match_winner == 0 else "%s WIN" % them
		K.PHASE_SERVE, K.PHASE_SERVE_SETUP, K.PHASE_TOSS:
			info_label.text = "%s TO SERVE  -  TO %d" % [who, sim.config.points_to_win]
		_:
			info_label.text = "%s %d   %s %d" % ["US" if sim.config.doubles else "YOU", sim.score[0], them, sim.score[1]]
	_fade(delta)


func _fade(delta: float) -> void:
	if _call_time > 0.0:
		_call_time -= delta
		call_label.visible = _call_time > 0.0


func announce(text: String, c: Color, seconds := 1.6) -> void:
	call_label.text = text
	call_label.modulate = c
	call_label.visible = true
	_call_time = seconds
