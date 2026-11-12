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
