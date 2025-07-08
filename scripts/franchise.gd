extends Object

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
var gameplay_settings
var teams:Array

func generate() -> void:
	team_location = "Abc"
	team_name = 'Def'

func create_from_team_index(team_index) -> void:
	pass

func serialize() -> String:
	return ''

func deserialize() -> void:
	pass
