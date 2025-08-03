extends Object
class_name Franchise

enum Stage {
	FRANCHISE_YEAR_OPTIONS,
	SEASON,
	PLAYOFFS
}

var year:int
var stage:Stage
#var team_location:String
#var team_name:String
var user_org_index:int
var gameplay_settings:GameplaySettings = GameplaySettings.new()
var orgs:Array[Org] = []
var games_this_season:int
var free_agents:Dictionary[String, Player] = {}
var n_levels:int = 4
var n_orgs:int = 30
enum salary_cap_options {None, Realistic, Equal}
var salary_cap_option:salary_cap_options

#func generate() -> void:
	#team_location = "Abc"
	#team_name = 'Def'

func create_from_team_index(team_index_) -> void:
	user_org_index = team_index_
	year = 0
	stage = Stage.FRANCHISE_YEAR_OPTIONS
	var teamsd:Dictionary = FileUtils.read_csv("res://data/teams/teams.csv")
	var teams:DF = DF.new().init(teamsd)
	printt('teams df is')
	teams.print_()
	#var playersd:Dictionary = FileUtils.read_json("res://data/players/players.json")
	var playersd:Dictionary = FileUtils.read_csv("res://data/players/players.csv")
	var players:DF = DF.new().init(playersd)
	players.print_(5,'player df is')
	for i in range(n_orgs):
		orgs.push_back(Org.new())
		orgs[i].n_levels = n_levels
		#orgs[i].create_random()
		var org_teams:DF = teams.filter_val_copy('team_id', i + 1)
		var org_players:DF = players.filter_val_copy('org_id', i + 1)
		#printt('org_teams')
		org_teams.print_(5, 'org_teams is')
		org_players.print_(5, 'org_players is')
		orgs[i].create_from_file(org_teams, org_players)
		#assert(false)
		orgs[i].fix_roster()
	# Create FAs
	for i in range(100):
		#free_agents.push_back(Player.new().create_random())
		var player = Player.new().create_random()
		free_agents[player.player_id] = player

func serialize() -> String:
	# Converts this object to a string that can be written to file
	
	# Put everything in dictionary, then convert to JSON string at end
	var d = {}
	
	# Version
	d['v'] = '1'
	
	# Store stage
	d['stage'] = stage
	
	# Store gameplay settings
	
	# Store teams
	
	# Store ...
	
	# Convert to string
	var s = FileUtils.dict_to_JSON_string(d)
	
	# Return string
	return s

func deserialize(x:String) -> void:
	# Converts a string (saved to file) back into a full franchise object
	
	var _d:Dictionary = JSON.parse_string(x)
	
	# Assert that the version is right
	
	# Deserialize all components

func set_preseason_options(games_this_season_:int) -> void:
	games_this_season = games_this_season_
	games_this_season = 29

func setup_season() -> void:
	# Create schedule for each team
	# Clear each teams games
	for i in range(n_levels):
		for j in range(n_orgs):
			orgs[j].teams[i].games = []
	
	# For each level
	var games_by_level:Array = []
	for i in range(n_levels):
		# Clear games
		var games_this_level:Array[Game] = []
		games_this_level.resize(roundi(games_this_season * n_orgs / 2.))
		var l:int = 0
		# Add game between each pair of teams
		for j in range(n_orgs - 1):
			for k in range(j+1, n_orgs):
				games_this_level[l] = Game.new()
				games_this_level[l].init(j, k, i)
				orgs[j].teams[i].games.push_back(games_this_level[l])
				orgs[k].teams[i].games.push_back(games_this_level[l])
				l += 1
		assert(l == roundi(games_this_season * n_orgs / 2.))
		games_this_level.shuffle()
