## Paddle profiles (ADR-015): DEFAULT is the angle you had; the others
## override angle, twist and reach for a paddle accessory.
extends TestSuite


func test_default_is_the_paddle_angle() -> void:
	var s := Settings.new()
	eq(s.paddle_profile, 0, "DEFAULT to start")
	s.paddle_angle = 2
	eq(s.paddle_pose(), [30.0, 0.0, 0.0] as Array[float], "DEFAULT: the PADDLE ANGLE, no twist or reach")
	s.paddle_profile = 2
	s.profiles[1] = {"angle": -20, "twist": 15, "reach": 12}
	eq(s.paddle_pose(), [-20.0, 15.0, 0.12] as Array[float], "a profile overrides it")


func test_profiles_are_saved() -> void:
	var s := Settings.new()
	s.paddle_profile = 3
	s.profiles[2] = {"angle": 60, "twist": -10, "reach": 30}
	s.save()
	var t := Settings.new()
	t.load_settings()
	eq(t.paddle_profile, 3, "the profile in use")
	eq(t.profiles[2], {"angle": 60, "twist": -10, "reach": 30}, "its numbers")
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
	eq(main.settings.profiles[0]["reach"], 6, "6 cm")
	near(int(main.view.paddle_reach * 100), 6, 0, "the paddle in your hand follows")
	main.menu.select("angle")
	main.menu.change(-4)
	eq(main.settings.profiles[0]["angle"], -5, "an angle the DEFAULT can't")
	main._on_pressed("reset")
	eq(main.settings.profiles[0], {"angle": 15, "twist": 0, "reach": 0}, "RESET: the DEFAULT paddle")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.settings.path))
	main.queue_free()
