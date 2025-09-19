extends Node
class_name Org

# org_id is team_id of MLB team
var org_id:int
# MLB team is first, then AAA, etc
var teams:Array[Team] = []
var n_levels:int = 4

func create_random() -> void:
	for i in range(n_levels):
		var team:Team = Team.new()
		team.create_random()
		teams.push_back(team)

func create_from_file(teams_:DF, players:DF) -> void:
	players.print_(5, 'player df is')
	#assert(false)
	for i in range(n_levels):
		var team_row:DF = teams_.filter_val_copy('level_id', i + 1)
		if i > 0:
			team_row = teams_.head(1)
		printt('in create_from_file, team_row is', team_row, team_row.nrows(), i)
		assert(team_row.nrows() == 1)
		var team:Team = Team.new()
		# Create team with metadata
		team.create(
			team_row.d['location'][0],
			team_row.d['name'][0],
			team_row.d['abbr'][0],
			'red',
			'white'
		)
		# Put players on team
		var players_level:DF = players.filter_val_copy('level_id', i + 1)
		printt('player_level head is', players_level.head(5))
		printt('player_level print_ is')
		players_level.print_(5)
		printt('team before adding players is')
		team.print_()
		#assert(false)
		for j in range(players_level.nrows()):
			var player_j:Player = Player.new()
			player_j.setup_from_row(players_level.get_row(j))
			#printt('player after setup is')
			#player_j.print_()
			#assert(false)
			team.roster.push_back(player_j)
			team.rosterdict[player_j.player_id] = player_j
			#printt('\n\nteam roster is', team.roster)
		printt('\n\nteam after is')
		team.print_()
		printt('\n\nteam roster is', team.roster)
		if len(team.roster) == 0:
			team.create_random()
		else:
			team.optimize_lineup()
			team.optimize_rotation()

		#assert(false)
		teams.push_back(team)

func fix_roster() -> void:
	for team in teams:
		team.fix_roster()

func sign_player(player:Player) -> void:
	teams[0].add_player(player)
