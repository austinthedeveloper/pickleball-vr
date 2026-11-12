## Venues (ADR-008): each builds, HOME follows the opponent, the colours
## come from the port kit's presets.
extends TestSuite


func test_every_venue_builds() -> void:
	for v in Venues.NAMES.size():
		var w := World.new()
		w.venue = v
		runner.root.add_child(w)
		check(w.get_child_count() > 20, "%s has a court and surroundings" % Venues.NAMES[v])
		check(ResourceLoader.exists(World.ambience(v)), "%s has its ambience" % Venues.NAMES[v])
		w.queue_free()


func test_home_follows_the_ladder() -> void:
	eq(Venues.resolve(0, 0), Venues.PARK, "HENDERSON play at the PARK")
	eq(Venues.resolve(0, 1), Venues.LAKESIDE, "the SNOWBIRDS at LAKESIDE")
	eq(Venues.resolve(0, 2), Venues.DINOSAUR, "the GYM BROS at DINOSAUR (VR-97)")
	eq(Venues.resolve(0, 5), Venues.UNDERSEA, "the SURF CREW UNDERSEA (VR-98)")
	check(Venues.STAND_INS.is_empty(), "no stand-ins left: every ladder home is built")
	for t in 8:
		var home := String(Opponents.team(t).get("venue", ""))
		check(Venues.NAMES.has(home), "%s's home %s is a venue" % [Opponents.team(t)["team"], home])
	eq(Venues.resolve(0, 4), Venues.SPACE, "the GOTH CLUB in SPACE")
	eq(Venues.resolve(0, 7), Venues.SUNSET, "the CHAMPS at SUNSET")
	eq(Venues.resolve(3, 7), Venues.SUNSET, "a chosen venue wins over HOME (index 3 = SUNSET)")
	eq(Venues.resolve(0, -1), Venues.PARK, "no team: the PARK")


func test_venue_reaches_the_view() -> void:
	var s := Settings.new()
	s.opponent = 4
	var cfg := s.match_config()
	eq(cfg.venue, Venues.SPACE, "HOME for the GOTH CLUB")
	var v := MatchView.new()
	runner.root.add_child(v)
	v.setup(cfg, false, true)
	eq(v.world.venue, Venues.SPACE, "built in SPACE")
	v.queue_free()


func test_court_colours_are_the_presets() -> void:
	eq(World.c8(World.SURFACES["CLAY"]), Color8(176, 84, 52), "CLAY")
	for v in World.VENUES:
		check(World.SURFACES.has(v["surface"]) and World.SURFACES.has(v["kitchen"]), "known surface")
		check(World.SURROUNDS.has(v["surround"]) and World.LINES.has(v["lines"]), "known surround and lines")


func test_the_water_and_the_void() -> void:
	# UNDERSEA's water is fog from the start; ZEN's DRIFT takes over from it.
	var w := World.new()
	w.venue = Venues.UNDERSEA
	runner.root.add_child(w)
	eq(w._env.fog_depth_begin, World.WATER_NEAR, "the water closes in past the court")
	eq(w._env.fog_light_color, World.WATER, "blue-green")
	w.set_drift(1.0, Color.BLACK, 13.0, 30.0)
	eq(w._env.fog_depth_begin, 13.0, "DRIFT: the void")
	w.set_drift(0.0, Color.BLACK, 13.0, 30.0)
	eq(w._env.fog_depth_begin, World.WATER_NEAR, "and back to the water")
	w.set_focus(0.5)
	check(w._shaders.all(func(m: ShaderMaterial) -> bool: return is_equal_approx(float(m.get_shader_parameter("dim")), 0.5)),
		"the kelp and the light dim with FOCUS")
	w.queue_free()
	var park := World.new()
	runner.root.add_child(park)
	check(park._env.fog_depth_begin >= 1000.0, "elsewhere, no fog till DRIFT")
	park.queue_free()


static func _lum(c: Color) -> float:
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b


func _world(venue: int, time: int) -> World:
	var w := World.new()
	w.venue = venue
	w.time = time
	runner.root.add_child(w)
	return w


func _sun(w: World) -> DirectionalLight3D:
	return w.find_children("*", "DirectionalLight3D", false, false)[0]


func test_night_plays_under_lights() -> void:
	# VR-99: DAY, DUSK, NIGHT; at night the court plays under lights (bible 5.6).
	var day := _world(Venues.PARK, World.DAY)
	var night := _world(Venues.PARK, World.NIGHT)
	var sky: ProceduralSkyMaterial = night._sky_mat
	check(_lum(sky.sky_top_color) < 0.05, "a dark sky")
	check(_sun(night).rotation_degrees.x < -60.0, "the light comes from high over the court")
	check(_sun(night).light_energy >= 1.0, "bright enough to play")
	var poles := night.find_children("*", "MeshInstance3D", false, false).filter(
		func(m: MeshInstance3D) -> bool: return m.position.y > 7.5).size()
	eq(poles, 4, "four lamps on poles")
	var tree_day: Color = day._dim[0][1]
	var tree_night: Color = night._dim[0][1]
	check(tree_night.v < tree_day.v * 0.5, "the surroundings in the dark")
	# The ball against the night: at least the port kit's 2:1 (court_colors.json min_ball_contrast).
	var contrast := (_lum(Look.BALL) + 0.05) / (_lum(sky.sky_horizon_color) + 0.05)
	check(contrast >= 2.0, "the ball stands out against the night: %.1f : 1" % contrast)
	day.queue_free()
	night.queue_free()


func test_dusk_and_the_rooms_that_have_no_time() -> void:
	var dusk := _world(Venues.LAKESIDE, World.DUSK)
	check(_sun(dusk).rotation_degrees.x > -20.0, "a low sun at dusk")
	check(dusk._sky_mat.sky_horizon_color.r > dusk._sky_mat.sky_horizon_color.b, "a warm horizon")
	dusk.queue_free()
	for v in [Venues.GYM, Venues.SPACE]:
		var a := _world(v, World.DAY)
		var b := _world(v, World.NIGHT)
		eq(a._env.background_color, b._env.background_color, "%s is as it is" % Venues.NAMES[v])
		check(not b.timed(), "no TIME in %s" % Venues.NAMES[v])
		a.queue_free()
		b.queue_free()
	var sea := _world(Venues.UNDERSEA, World.NIGHT)
	check(_lum(sea._env.fog_light_color) < _lum(World.WATER) * 0.5, "the water darker at night")
	sea.queue_free()


func test_time_is_a_setting_that_reaches_the_view() -> void:
	var s := Settings.new()
	s.time_of_day = World.NIGHT
	s.save()
	var t := Settings.new()
	t.load_settings()
	eq(t.time_of_day, World.NIGHT, "saved")
	eq(t.match_config().time, World.NIGHT, "in a match's config")
	eq(t.partner_config().time, World.NIGHT, "and practice's")
	var v := MatchView.new()
	runner.root.add_child(v)
	v.setup(t.match_config(), false, true)
	eq(v.world.time, World.NIGHT, "the view builds it")
	v.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.default_path))


func test_the_time_row() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	runner.root.add_child(main)
	for page in ["match", "partner", "machine"]:
		var m: Menu3D = main._page(page)
		check(not m.row("tod").is_empty(), "TIME on %s" % page)
		m.free()
	main._on_changed("tod", World.DUSK)
	eq(main.settings.time_of_day, World.DUSK, "changing it sets it")
	main.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.default_path))


# --- COURT (VR-102) --------------------------------------------------------------

func test_court_colours_over_the_venues() -> void:
	var w := World.new()
	w.venue = Venues.PARK
	var own := w.colours()
	eq(own["surface"], World.c8(World.SURFACES["BLUE"]), "the venue's own surface")
	w.court = "CLAY,SAME,SNOW,YELLOW"
	var c := w.colours()
	eq(c["surface"], World.c8(World.SURFACES["CLAY"]), "SURFACE")
	eq(c["kitchen"], c["surface"], "KITCHEN SAME follows the surface")
	eq(c["surround"], World.c8(World.SURROUNDS["SNOW"]), "GROUND")
	eq(c["lines"], World.c8(World.LINES["YELLOW"]), "LINES")
	w.court = ",PURPLE,,"
	eq(w.colours()["surface"], own["surface"], "\"\": the venue's own")
	eq(w.colours()["kitchen"], World.c8(World.SURFACES["PURPLE"]), "with a kitchen of its own")
	w.free()


func test_the_lines_always_read() -> void:
	# Any surface with any lines: at least the port kit's 2.5:1, a fallback if not.
	var w := World.new()
	for s in World.SURFACES:
		for l in World.LINES:
			w.court = "%s,,,%s" % [s, l]
			var c := w.colours()
			check(World.contrast(c["lines"], c["surface"]) >= World.MIN_LINE_CONTRAST or c["line_name"] != l,
				"%s lines on %s: %.1f" % [l, s, World.contrast(c["lines"], c["surface"])])
	near(roundi(World.contrast(Color.WHITE, Color.BLACK)), 21, 0, "white on black is 21:1")
	w.free()


func test_court_reaches_the_view_and_the_page() -> void:
	var s := Settings.new()
	s.court_surface = "PINK"
	s.court_lines = "LIME"
	s.save()
	var t := Settings.new()
	t.load_settings()
	eq(t.match_config().court, "PINK,,,LIME", "saved, in the config")
	var v := MatchView.new()
	runner.root.add_child(v)
	v.setup(t.match_config(), false, true)
	eq(v.world.line_color, World.c8(World.LINES["LIME"]), "the court is built in it")
	v.queue_free()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	runner.root.add_child(main)
	var m: Menu3D = main._page("court")
	for id in ["venue", "tod", "c_surface", "c_kitchen", "c_ground", "c_lines"]:
		check(not m.row(id).is_empty(), "COURT has %s" % id)
	m.free()
	var names: Array = main.COURT_ROWS["c_kitchen"][1]
	main._on_changed("c_kitchen", names.find("SAME"))
	eq(main.settings.court_kitchen, "SAME", "KITCHEN SAME")
	main._on_changed("c_surface", 0)
	eq(main.settings.court_surface, "", "back to the venue's own")
	main.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.default_path))
