extends TestCase
## Eleven clubs, each at home in its own park, each with a full, playable
## roster and its own colors and identity.


func test_every_club_has_its_own_park() -> void:
	var parks := {}
	for team in content().teams:
		check(team.stadium_def != null, "%s has a home park" % team.id)
		if team.stadium_def != null:
			check(not parks.has(team.stadium_def.id), "%s's park is nobody else's" % team.id)
			parks[team.stadium_def.id] = team.id
			check(team.stadium_def.blurb.begins_with(team.team_name), "%s park names its home club" % team.id)
	check_eq(content().teams.size(), 11, "eleven clubs")
	check_eq(parks.size(), content().parks.size(), "every park is somebody's home")


func test_every_club_can_field_a_team() -> void:
	var abbrs := {}
	var colors := {}
	for team in content().teams:
		check(not abbrs.has(team.abbreviation), "%s abbreviation unique" % team.id)
		abbrs[team.abbreviation] = true
		var key := team.primary_color.to_html(false)
		check(not colors.has(key), "%s jersey color unique" % team.id)
		colors[key] = true
		check(team.rival != &"" and content().team(team.rival) != null, "%s has a real rival" % team.id)
		check_eq(team.batting_order.size(), 9, "%s bats nine" % team.id)
		check(team.starting_pitcher != &"" and team.bullpen.size() >= 3, "%s has a staff" % team.id)
		var ids := {}
		for p in team.roster:
			check(not ids.has(p.id), "%s: %s listed once" % [team.id, p.id])
			ids[p.id] = true
		for id in team.batting_order:
			check(ids.has(id), "%s: %s in the order is on the roster" % [team.id, id])
		var s := MatchState.from_teams(team, content().team(team.rival), content().rules)
		check(s.defense[MatchState.AWAY].size() >= 9, "%s fills every position" % team.id)


func test_any_two_clubs_can_play() -> void:
	var teams := content().teams
	for i in [2, 5, 8]:
		var away: TeamDef = teams[i]
		var home: TeamDef = teams[(i + 3) % teams.size()]
		var sim := AutoMatch.play(i, content(), away.id, home.id, home.stadium_def.id)
		check(sim.state.game_over, "%s at %s plays to the end" % [away.id, home.id])
