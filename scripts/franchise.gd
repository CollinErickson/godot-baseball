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
var team_index:int
var gameplay_settings:GameplaySettings = GameplaySettings.new()
var teams:Array[Team] = []
var games_this_season:int

#func generate() -> void:
	#team_location = "Abc"
	#team_name = 'Def'

func create_from_team_index(team_index_) -> void:
	team_index = team_index_
	year = 0
	stage = Stage.FRANCHISE_YEAR_OPTIONS
	teams.push_back(Team.new())
	teams[0].create_random()

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

func setup_season() -> void:
	# Create schedule for each team
	pass
