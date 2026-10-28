## The headset rig: an XROrigin3D with the camera and both controllers.
## The paddle rides on the right (or left, for lefties) controller's grip
## pose; the free hand holds the ball at the serve. Each frame it records
## the poses, and `sample` gives the sim an input interpolated between
## the last frame and this one (ADR-003). Every OpenXR name lives in this
## file, so the on-device check is one file (KNOWN_ISSUES #1).
class_name XrRig
extends XROrigin3D

const MOVE_SPEED := 3.0              ## m/s on the stick
const SNAP_TURN := deg_to_rad(45.0)
const DEADZONE := 0.25

var camera: XRCamera3D
var paddle_hand: XRController3D
var free_hand: XRController3D
var paddle: PaddleMesh
var held_ball: MeshInstance3D
var left_handed := false
var paddle_tilt := 0.0               ## degrees, the face tipped forward in the hand
var paddle_twist := 0.0              ## degrees, the face turned about the handle (profiles, ADR-015)
var paddle_reach := 0.0              ## metres, the paddle slid out along its handle

var _prev_head := Vector3.ZERO
var _head := Vector3.ZERO
var _prev_face := Vector3.ZERO
var _face := Vector3.ZERO
var _prev_n := Vector3.RIGHT
var _n := Vector3.RIGHT
var _prev_hand := Vector3.ZERO
var _hand := Vector3.ZERO
var _toss := false
var _trigger_was := false
var _turned := false
var _menu_was := false
var menu_pressed := false            ## A/X this frame: the match's button
var pause_pressed := false           ## the menu button (or B/Y) this frame
var _pause_was := false
## Menus: the laser's click and the stick's steps this frame.
var click := false
var nav := Vector2i.ZERO
var _click_was := false
var _nav_was := Vector2i.ZERO
var laser: MeshInstance3D


func _ready() -> void:
	camera = XRCamera3D.new()
	add_child(camera)
	var right := XRController3D.new()
	right.tracker = &"right_hand"
	right.pose = &"grip"
	add_child(right)
	var left := XRController3D.new()
	left.tracker = &"left_hand"
	left.pose = &"grip"
	add_child(left)
	paddle_hand = left if left_handed else right
	free_hand = right if left_handed else left
	paddle = PaddleMesh.new()
	paddle.transform = grip(paddle_tilt, paddle_twist, paddle_reach)
	paddle_hand.add_child(paddle)
	held_ball = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = K.BALL_RADIUS / float(K.M)
	sm.height = sm.radius * 2
	held_ball.mesh = sm
	held_ball.material_override = Look.ball_material()
	# In the fingers on the palm side (the grip pose's -x for the left hand,
	# +x for the right), a little forward: where a held ball sits.
	var palm := -1.0 if free_hand == left else 1.0
	held_ball.position = Vector3(palm * 0.05, -0.015, -0.035)
	free_hand.add_child(held_ball)
	held_ball.visible = false
	laser = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.003
	cm.bottom_radius = 0.003
	cm.height = 3.0
	laser.mesh = cm
	var lm := World.material(Color(1.0, 0.85, 0.2, 0.7))
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	laser.material_override = lm
	laser.rotation.x = -PI / 2
	laser.position = Vector3(0, 0, -1.5)
	free_hand.add_child(laser)
	laser.visible = false


## The paddle's place in the hand: tipped forward by `tilt` about the
## normal's axis (the face stays square), turned by `twist` about the
## handle, and slid `reach` out along it (an accessory's longer grip).
static func grip(tilt: float, twist: float, reach: float) -> Transform3D:
	var b := Basis(Vector3.RIGHT, -deg_to_rad(tilt)) * Basis(Vector3.BACK, deg_to_rad(twist))
	return Transform3D(b, b * Vector3(0, 0, -reach))


## Locomotion and turning from the sticks, then this frame's poses.
func begin_frame(delta: float) -> void:
	var move := free_hand.get_vector2("primary")
	if move.length() > DEADZONE:
		var yaw := camera.global_transform.basis.get_euler().y
		var dir := Vector3(move.x, 0, -move.y).rotated(Vector3.UP, yaw)
		global_position += dir * MOVE_SPEED * delta
	var turn := paddle_hand.get_vector2("primary").x
	if absf(turn) > 0.7 and not _turned:
		_turned = true
		var pivot := camera.global_position
		global_transform = global_transform.rotated(Vector3.UP, -signf(turn) * SNAP_TURN)
		global_position += pivot - camera.global_position
	elif absf(turn) < 0.3:
		_turned = false
	_prev_head = _head
	_prev_face = _face
	_prev_n = _n
	_prev_hand = _hand
	_head = camera.global_position
	var t := paddle.global_transform
	_face = t * PaddleMesh.FACE_CENTER
	_n = t.basis.x.normalized()
	_hand = held_ball.global_position      # the ball leaves from where you see it
	var trig := free_hand.get_float("trigger") > 0.6
	_toss = trig and not _trigger_was
	_trigger_was = trig
	var menu := paddle_hand.is_button_pressed("ax_button") or free_hand.is_button_pressed("ax_button")
	menu_pressed = menu and not _menu_was
	_menu_was = menu
	var pz := free_hand.is_button_pressed("menu_button") or paddle_hand.is_button_pressed("by_button") \
		or free_hand.is_button_pressed("by_button")
	pause_pressed = pz and not _pause_was
	_pause_was = pz
	var c := trig or paddle_hand.get_float("trigger") > 0.6
	click = c and not _click_was
	_click_was = c
	var stick := paddle_hand.get_vector2("primary") + free_hand.get_vector2("primary")
	var step := Vector2i(int(signf(stick.x)) if absf(stick.x) > 0.7 else 0,
		int(signf(stick.y)) if absf(stick.y) > 0.7 else 0)
	nav = Vector2i(step.x if step.x != _nav_was.x else 0, -step.y if step.y != _nav_was.y else 0)
	_nav_was = step


## The sim's input at `alpha` (0..1) between last frame and this one.
func sample(alpha: float, first: bool) -> SimTypes.HumanInput:
	var h := SimTypes.HumanInput.new()
	var head := _prev_head.lerp(_head, alpha)
	var face := _prev_face.lerp(_face, alpha)
	var n := _prev_n.slerp(_n, alpha) if _prev_n.dot(_n) > -0.99 else _n
	var hand := _prev_hand.lerp(_hand, alpha)
	var hp := World.um(head)
	h.head_x = hp[0]
	h.head_z = hp[2]
	var fp := World.um(face)
	h.paddle_x = fp[0]
	h.paddle_y = fp[1]
	h.paddle_z = fp[2]
	h.normal = [roundi(n.x * K.Q14), roundi(n.y * K.Q14), roundi(n.z * K.Q14)]
	var hd := World.um(hand)
	h.hand_x = hd[0]
	h.hand_y = hd[1]
	h.hand_z = hd[2]
	h.toss = _toss and first
	return h


## Move the play space so your head stands on (x, z) metres.
func recenter(at: Vector3) -> void:
	var head := camera.global_position
	global_position += Vector3(at.x - head.x, 0, at.z - head.z)
	_head = camera.global_position
	_prev_head = _head


## Turn the play space so you face -z (down the court).
func face_court() -> void:
	var fwd := -camera.global_transform.basis.z
	var yaw := atan2(-fwd.x, -fwd.z)
	var pivot := camera.global_position
	global_transform = global_transform.rotated(Vector3.UP, -yaw)
	global_position += pivot - camera.global_position


func pulse(strength: float, seconds := 0.06) -> void:
	paddle_hand.trigger_haptic_pulse(&"haptic", 0.0, clampf(strength, 0.1, 1.0), seconds, 0.0)


func show_held_ball(on: bool) -> void:
	held_ball.visible = on


func head_position() -> Vector3:
	return camera.global_position


## True once the headset reports a real pose (the head above the floor).
func tracking() -> bool:
	return camera.position.y > 0.3


## The menu laser, from the free hand.
func pointer() -> Array[Vector3]:
	var t := free_hand.global_transform
	return [t.origin, -t.basis.z]


func show_laser(on: bool) -> void:
	laser.visible = on


func forward() -> Vector3:
	var f := -camera.global_transform.basis.z
	f.y = 0
	return f.normalized() if f.length() > 0.01 else Vector3.FORWARD
