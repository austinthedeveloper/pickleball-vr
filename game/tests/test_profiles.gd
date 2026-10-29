## Paddle profiles (ADR-015): DEFAULT is the angle you had; the others
## override angle, twist and reach for a paddle accessory.
extends TestSuite


func test_default_is_the_paddle_angle() -> void:
	var s := Settings.new()
	eq(s.paddle_profile, 0, "DEFAULT to start")
	s.paddle_angle = 2
	eq(s.paddle_pose(), [30.0, 0.0, 0.0, 0.0] as Array[float], "DEFAULT: the PADDLE ANGLE, no twist or reach")
	s.paddle_profile = 2
	s.profiles[1] = {"angle": -20, "turn": 35, "twist": 15, "reach": 12}
	eq(s.paddle_pose(), [-20.0, 15.0, 0.12, 35.0] as Array[float], "a profile overrides it")


func test_profiles_are_saved() -> void:
	var s := Settings.new()
	s.paddle_profile = 3
	s.profiles[2] = {"angle": 60, "turn": -30, "twist": -150, "reach": -18}
	s.save()
	var t := Settings.new()
	t.load_settings()
	eq(t.paddle_profile, 3, "the profile in use")
	eq(t.profiles[2], {"angle": 60, "turn": -30, "twist": -150, "reach": -18}, "its numbers")
	eq(t.profiles[0], Settings.new_profile(), "the others untouched")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(s.path))


func test_an_old_save_loads_with_default() -> void:
	var c := ConfigFile.new()
	c.set_value("player", "paddle_angle", 3)
	var s := Settings.new()
	c.save(s.path)
	s.load_settings()
	eq(s.paddle_profile, 0, "DEFAULT")
	eq(s.paddle_pose()[0], 45.0, "the old angle kept")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(s.path))


func test_the_grip_transform() -> void:
	var old := Transform3D(Basis(Vector3.RIGHT, -deg_to_rad(15.0)), Vector3.ZERO)
	check(XrRig.grip(15.0, 0.0, 0.0).is_equal_approx(old), "DEFAULT's grip unchanged")
	var face := XrRig.grip(15.0, 0.0, 0.1) * PaddleMesh.FACE_CENTER
	var face0 := XrRig.grip(15.0, 0.0, 0.0) * PaddleMesh.FACE_CENTER
	near(int((face - face0).length() * 1000), 100, 1, "REACH slides the face 10 cm further out")
	near(int(face.length() * 1000), int(face0.length() * 1000) + 100, 1, "...along the handle")
	var t := XrRig.grip(0.0, 30.0, 0.0)
	near(int(rad_to_deg(t.basis.x.angle_to(Vector3.RIGHT))), 30, 1, "TWIST turns the face")
	check(t.basis.z.is_equal_approx(Vector3.BACK), "about the handle")


func test_the_paddle_page() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	runner.root.add_child(main)
	check(main.menu.row("to_paddle").size() > 0, "PADDLE on MAIN")
	main.lobby("paddle")
	check(main.menu.row("twist").is_empty(), "DEFAULT: just the angle")
	main.menu.select("profile")
	main.menu.change(1)
	main.lobby()
	eq(main.settings.paddle_profile, 1, "PROFILE 1")
	check(main.menu.row("twist").size() > 0 and main.menu.row("reach").size() > 0, "a profile: twist and reach")
	main.menu.select("reach")
	main.menu.change(3)
	main.lobby()
	eq(main.settings.profiles[0]["reach"], 3, "3 cm")
	near(int(main.view.paddle_reach * 100), 3, 0, "the paddle in your hand follows")
	main.menu.select("angle")
	main.menu.change(-4)
	eq(main.settings.profiles[0]["angle"], -5, "an angle the DEFAULT can't")
	main._on_pressed("reset")
	eq(main.settings.profiles[0], {"angle": 15, "turn": 0, "twist": 0, "reach": 0}, "RESET: the DEFAULT paddle")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.settings.path))
	main.queue_free()


func test_any_way_round() -> void:
	# A paddle accessory can hold the controller any way: a full turn of
	# TWIST, ANGLE and TURN to 90 either way (the lead's needed more than 45).
	check(Settings.PROFILE_TWISTS.has(-180) and Settings.PROFILE_TWISTS.has(180), "TWIST: a full turn")
	check(Settings.PROFILE_ANGLES.has(-90) and Settings.PROFILE_ANGLES.has(90), "ANGLE: +-90")
	check(Settings.PROFILE_TURNS.has(-90) and Settings.PROFILE_TURNS.has(90), "TURN: +-90")
	var t := XrRig.grip(0.0, 0.0, 0.0, 90.0)
	check(t.basis.x.is_equal_approx(Vector3.FORWARD), "TURN 90 swings the face a quarter turn")
	check(t.basis.y.is_equal_approx(Vector3.UP), "about the controller's up")
	check(XrRig.grip(15.0, 20.0, 0.0, 0.0).is_equal_approx(XrRig.grip(15.0, 20.0, 0.0)), "TURN 0: as before")
	# A profile saved before TURN loads with none.
	var s := Settings.new()
	var c := ConfigFile.new()
	c.set_value("paddle", "profiles", [{"angle": 30, "twist": 40, "reach": 4}])
	c.save(s.path)
	s.load_settings()
	eq(s.profiles[0]["turn"], 0, "no turn")
	eq(s.profiles[0]["twist"], 40, "its twist kept")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(s.path))


## The lead's accessory holds the controller up the handle, 15-20 cm above
## the hand: REACH goes back toward the hand, and 40 cm out was too much.
func test_reach_goes_back_toward_the_hand() -> void:
	check(Settings.PROFILE_REACHES.has(-30) and Settings.PROFILE_REACHES.has(-18), "back to -30 cm")
	eq(Settings.PROFILE_REACHES[-1], 20, "out to 20 cm")
	var face := XrRig.grip(15.0, 0.0, -0.18) * PaddleMesh.FACE_CENTER
	var face0 := XrRig.grip(15.0, 0.0, 0.0) * PaddleMesh.FACE_CENTER
	near(int(face0.length() * 1000) - int(face.length() * 1000), 180, 1, "-18 cm: the face 18 cm nearer the hand")
	var s := Settings.new()
	var c := ConfigFile.new()
	c.set_value("paddle", "profiles", [{"angle": 30, "twist": 0, "reach": 40}])
	c.save(s.path)
	s.load_settings()
	eq(s.profiles[0]["reach"], 20, "an old 40 cm comes back as the most there is now")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(s.path))


## Drift (ADR-015): the face laid flat on the floor reads about 0 cm up and
## 0 degrees off; held up and tipped, it says so.
func test_the_paddle_check() -> void:
	var rig := XrRig.new()
	runner.root.add_child(rig)
	var flat := Basis(Vector3(0, 0, 1), deg_to_rad(90))    # the face's normal (its x) straight up
	rig.paddle.top_level = true
	rig.paddle.global_transform = Transform3D(flat, Vector3.ZERO)
	var centre := rig.paddle.global_transform * PaddleMesh.FACE_CENTER
	rig.paddle.global_position.y += PaddleMesh.FACE_T / 2 - centre.y   # its lower side on the floor
	var c := rig.paddle_check()
	near(int(c[0] * 10), 0, 1, "flat on the floor: 0 cm up (%.1f)" % c[0])
	near(int(c[1]), 0, 1, "and level (%.1f)" % c[1])
	rig.paddle.global_transform = Transform3D(flat.rotated(Vector3.RIGHT, deg_to_rad(8)), rig.paddle.global_position + Vector3(0, 0.03, 0))
	c = rig.paddle_check()
	check(c[1] > 7.0 and c[1] < 9.0, "tipped 8 degrees reads 8 (%.1f)" % c[1])
	check(c[0] > 2.0, "and lifted reads up (%.1f cm)" % c[0])
	rig.queue_free()
