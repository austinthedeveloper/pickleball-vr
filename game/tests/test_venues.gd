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
	eq(Venues.resolve(0, 2), Venues.GYM, "the GYM BROS' DINOSAUR stands in as the GYM")
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
