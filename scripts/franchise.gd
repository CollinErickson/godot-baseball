extends Object
class_name Franchise

enum Stage {
	FRANCHISE_YEAR_OPTIONS,
	SEASON,
	PLAYOFFS
}

var year:int
var stage:Stage
var team_location:String
var team_name:String
var team_index:int
var gameplay_settings:GameplaySettings = GameplaySettings.new()
var teams:Array[Team]

func generate() -> void:
	team_location = "Abc"
	team_name = 'Def'

func create_from_team_index(_team_index) -> void:
	pass

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
	
	var d:Dictionary = JSON.parse_string(x)
	
	# Assert that the version is right
	
	# Deserialize all components
