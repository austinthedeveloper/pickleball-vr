## A CPU player: a simple figure that stands where the sim says, faces the
## net, and reaches its paddle to the ball. Display only: it reads the sim.
class_name Avatar
extends Node3D

const SKIN := Color(0.93, 0.74, 0.58)
const REACH_START := 1.6             ## metres: the arm starts reaching

var slot := 2
var shirt := Color(0.95, 0.55, 0.12)
var shorts := Color(0.15, 0.18, 0.3)
var paddle: PaddleMesh
var _body: Node3D
var _swing := 0.0                    ## seconds since a swing, for the follow-through


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	for s in [-1, 1]:
		_part(CapsuleMesh, Vector3(s * 0.1, 0.42, 0), Vector2(0.075, 0.84), shorts)
	_part(CapsuleMesh, Vector3(0, 1.12, 0), Vector2(0.19, 0.66), shirt)
	_part(SphereMesh, Vector3(0, 1.6, 0), Vector2(0.12, 0.27), SKIN)
	# A long chin, the house style (see the port kit's faces).
	_part(SphereMesh, Vector3(0, 1.5, -0.04), Vector2(0.07, 0.12), SKIN)
	_part(SphereMesh, Vector3(0, 1.69, 0.01), Vector2(0.125, 0.16), Color(0.25, 0.16, 0.1))
	for s in [-1, 1]:
		_part(SphereMesh, Vector3(s * 0.045, 1.62, -0.105), Vector2(0.018, 0.036), Color(0.08, 0.08, 0.1))
	_part(CapsuleMesh, Vector3(-0.24, 1.1, 0), Vector2(0.05, 0.55), SKIN)
	paddle = PaddleMesh.new()
	paddle.color = Color(0.85, 0.15, 0.2) if slot < 2 else Color(0.2, 0.3, 0.85)   # your side's red
	paddle.top_level = true          # posed in world space
	add_child(paddle)


func _part(kind, at: Vector3, size: Vector2, c: Color) -> void:
	var mi := MeshInstance3D.new()
	var mesh: PrimitiveMesh = kind.new()
	if mesh is CapsuleMesh:
		(mesh as CapsuleMesh).radius = size.x
		(mesh as CapsuleMesh).height = size.y
	else:
		(mesh as SphereMesh).radius = size.x
		(mesh as SphereMesh).height = size.y
	mi.mesh = mesh
	mi.material_override = World.material(c)
	mi.position = at
	_body.add_child(mi)


## Place from the sim (the far side faces +z, the near side -z).
func show_from(sim: Sim, delta: float) -> void:
	var p := sim.players[slot]
	var side := K.side_sign(p.team)
	var at := World.m(p.x, 0, p.z)
	position = at
	_body.rotation.y = 0.0 if side > 0 else PI
	if p.swing_tick >= 0 and sim.tick - p.swing_tick < 2:
		_swing = 0.0
	_swing += delta
	# The paddle: ready by the forehand side, reaching to an incoming ball.
	var fore := Vector3(K.right_sign(p.team) * 0.42, 1.0, -side * 0.25)
	var ready := at + fore
	var ball := World.m(sim.ball.x, sim.ball.y, sim.ball.z)
	var target := ready
	var to_ball := Vector2(ball.x - at.x, ball.z - at.z).length()
	var incoming := sim.phase == K.PHASE_LIVE and sim.last_hitter >> 1 != p.team
	if incoming and to_ball < REACH_START:
		var k := clampf(1.0 - (to_ball - 0.5) / (REACH_START - 0.5), 0.0, 1.0)
		target = ready.lerp(ball, k * 0.85)
	if _swing < 0.35:
		# The follow-through: up and across toward the net.
		var f := _swing / 0.35
		target += Vector3(-K.right_sign(p.team) * 0.4 * f, 0.35 * sin(f * PI), -side * 0.3 * f)
	var face_n := Vector3(0, 0.15, -side).normalized()
	var pos := paddle.transform.origin + paddle.transform.basis * PaddleMesh.FACE_CENTER
	paddle.pose(pos.lerp(target, clampf(delta * 14.0, 0.0, 1.0)), face_n)
