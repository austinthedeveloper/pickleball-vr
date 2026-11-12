## Critters (VR-101): between points only, each venue its own, display only.
extends TestSuite


func _view(venue: int, time := World.DAY, drill := true) -> MatchView:
	var s := Settings.new()
	var cfg := s.partner_config() if drill else s.match_config()
	cfg.venue = venue
	cfg.time = time
	var v := MatchView.new()
	runner.root.add_child(v)
	v.setup(cfg, false)
	return v


func test_each_venue_its_own() -> void:
	eq(Critters.for_venue(Venues.LAKESIDE, World.DAY), Critters.GULL, "a gull at LAKESIDE")
	eq(Critters.for_venue(Venues.DINOSAUR, World.DUSK), Critters.PTEROSAUR, "a pterosaur at DINOSAUR")
	eq(Critters.for_venue(Venues.SPACE, World.NIGHT), Critters.SATELLITE, "a satellite in SPACE")
	eq(Critters.for_venue(Venues.UNDERSEA, World.NIGHT), Critters.FISH, "a fish UNDERSEA")
	eq(Critters.for_venue(Venues.LAKESIDE, World.NIGHT), "", "birds keep to the day")
	eq(Critters.for_venue(Venues.PARK, World.DAY), "", "none at the PARK")


func test_only_between_points() -> void:
	var v := _view(Venues.LAKESIDE)
	var c := v.critters
	check(Critters.between_points(v.sim), "a drill waiting for its first feed: between points")
	c.wait = 0.0
	c.update(v.sim, 0.016)
	check(c.flying != null, "one sets off between points")
	eq(c.crossings, 1, "one")
	v.sim.drill.stage = Drill.FLY                       # the ball's in play
	check(not Critters.between_points(v.sim), "a rally")
	for i in 60:
		c.update(v.sim, 0.016)
	check(c.flying == null, "faded out once the rally began")
	c.wait = 0.0
	for i in 30:
		c.update(v.sim, 0.016)
	eq(c.crossings, 1, "and none sets off mid-rally")
	v.queue_free()


func test_it_crosses_and_goes() -> void:
	var v := _view(Venues.UNDERSEA)
	var c := v.critters
	c.launch()
	var start: Vector3 = c.flying.position
	for i in 120:
		c.update(v.sim, 0.05)
	check(c.flying == null or c.flying.position.distance_to(start) > 5.0, "it moves across")
	var n := 0
	while c.flying != null and n < 600:
		c.update(v.sim, 0.05)
		n += 1
	check(c.flying == null, "and is gone once across")
	check(c.wait >= Critters.EVERY[0], "the next one waits")
	v.queue_free()


func test_none_in_a_match_mid_rally_or_in_the_lobby() -> void:
	var lobby := MatchView.new()
	runner.root.add_child(lobby)
	var cfg := Settings.new().match_config()
	cfg.venue = Venues.SPACE
	lobby.setup(cfg, false, true, true)
	eq(lobby.critters.kind, "", "the lobby's demo: none")
	lobby.queue_free()
	var v := _view(Venues.SPACE, World.DAY, false)
	v.sim.phase = K.PHASE_LIVE
	check(not Critters.between_points(v.sim), "a match's live ball is a rally")
	v.sim.phase = K.PHASE_SERVE
	check(Critters.between_points(v.sim), "the serve is between points")
	v.queue_free()
