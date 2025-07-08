extends Node
class_name GameplaySettings

var innings_per_game:int = 9

func serialize() -> String:
	var d:Dictionary = {}
	
	d['ipg'] = str(innings_per_game)
	
	return FileUtils.dict_to_JSON_string(d)

func deserialize(x:Dictionary) -> void:
	return
