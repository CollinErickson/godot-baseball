extends Node
class_name GameplaySettings

var innings_per_game:int = 9
var difficulty:String = ''
var bat_mode:String = ''
var pitch_mode:String = ''
var throw_mode:String = ''
var baserunning_control:String = ''
var defense_control:String = ''

func is_valid() -> bool:
	return true

func serialize() -> String:
	var d:Dictionary = {}
	
	d['ipg'] = str(innings_per_game)
	
	return FileUtils.dict_to_JSON_string(d)

#func deserialize(x:Dictionary) -> void:
	#return
