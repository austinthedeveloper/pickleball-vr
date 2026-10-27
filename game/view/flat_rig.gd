## Flat mode (ADR-001): the first-person view on a monitor. WASD or the
## arrows move you; the mouse aims (a ring on the far court); the bot
## swings the paddle you see. Space serves, Shift holds a soft shot.
class_name FlatRig
extends Node3D

const MOVE_SPEED := 4.0
const EYE := 1.65
const PITCH := -9.0

var camera: Camera3D
var paddle: PaddleMesh
var ring: MeshInstance3D
var head := Vector3(0, EYE, 7.0)
var aim := Vector3(0, 0, -4.5)       ## on the far court, metres
var soft := false
var serve_pressed := false
var menu_pressed := false
var demo := false                    ## the camera rides with the bot
var spectate := false                ## fixed camera, the mouse free for menus
var click := false
var pause_pressed := false
var nav := Vector2i.ZERO
var _click_was := false
var _keys_was := {}


func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 80.0
	camera.near = 0.03
	add_child(camera)
	paddle = PaddleMesh.new()
	add_child(paddle)
	ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.22
	tm.outer_radius = 0.3
	ring.mesh = tm
	var mat := World.material(Color(1.0, 0.85, 0.2, 0.8))
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = mat
	add_child(ring)
	var layer := CanvasLayer.new()
	add_child(layer)
	var help := Label.new()
	help.text = "WASD MOVE   MOUSE AIM   SPACE SERVE   SHIFT SOFT   ESC PAUSE"
	help.position = Vector2(16, 12)
	help.add_theme_font_size_override("font_size", 18)
	help.add_theme_color_override("font_outline_color", Color.BLACK)
	help.add_theme_constant_override("outline_size", 6)
	help.visible = not demo and not spectate
	layer.add_child(help)


func begin_frame(delta: float) -> void:
	var c := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	click = c and not _click_was
	_click_was = c
	nav = Vector2i(int(_edge(KEY_RIGHT)) - int(_edge(KEY_LEFT)), int(_edge(KEY_DOWN)) - int(_edge(KEY_UP)))
	if _edge(KEY_ENTER):
		click = true
	pause_pressed = _edge(KEY_ESCAPE)
	if not demo and not spectate:
		var move := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var keys := Vector2(
			float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
			float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
		move = (move + keys).limit_length(1.0)
		head += Vector3(move.x, 0, move.y) * MOVE_SPEED * delta
		var hl := K.COURT_HALF_LENGTH / float(K.M)
		head.x = clampf(head.x, -(K.COURT_HALF_WIDTH + K.RUNOFF_SIDE) / float(K.M),
			(K.COURT_HALF_WIDTH + K.RUNOFF_SIDE) / float(K.M))
		head.z = clampf(head.z, K.NET_GAP / float(K.M), hl + K.RUNOFF_BACK / float(K.M))
		soft = Input.is_physical_key_pressed(KEY_SHIFT)
		_aim_from_mouse()
	serve_pressed = Input.is_physical_key_pressed(KEY_SPACE)
	menu_pressed = Input.is_physical_key_pressed(KEY_ENTER)
	camera.global_position = head
	camera.rotation_degrees = Vector3(PITCH, 0, 0)
	ring.visible = not demo and not spectate
	ring.global_position = Vector3(aim.x, 0.03, aim.z)


func _aim_from_mouse() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var mouse := vp.get_mouse_position()
	var from := camera.project_ray_origin(mouse)
	var dir := camera.project_ray_normal(mouse)
	if dir.y >= -0.001:
		return
	var hit := from + dir * (-from.y / dir.y)
	var hw := K.COURT_HALF_WIDTH / float(K.M)
	var hl := K.COURT_HALF_LENGTH / float(K.M)
	aim = Vector3(clampf(hit.x, -hw + 0.3, hw - 0.3), 0, clampf(hit.z, -hl + 0.3, -0.3))


func recenter(at: Vector3) -> void:
	head = Vector3(at.x, EYE, at.z)


## Show the paddle where the bot holds it.
func show_paddle(h: SimTypes.HumanInput) -> void:
	paddle.pose(World.m(h.paddle_x, h.paddle_y, h.paddle_z),
		Vector3(h.normal[0], h.normal[1], h.normal[2]) / float(K.Q14))


func head_position() -> Vector3:
	return head


func _edge(key: Key) -> bool:
	var down := Input.is_physical_key_pressed(key)
	var was: bool = _keys_was.get(key, false)
	_keys_was[key] = down
	return down and not was


## The mouse's ray into the world.
func pointer() -> Array[Vector3]:
	var vp := get_viewport()
	var m := vp.get_mouse_position() if vp else Vector2.ZERO
	return [camera.project_ray_origin(m), camera.project_ray_normal(m)]


func forward() -> Vector3:
	return Vector3.FORWARD
