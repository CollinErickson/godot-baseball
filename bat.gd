extends Node2D

func _process(delta: float) -> void:
	
	var mp = get_global_mouse_position()
	
	#get_node('bat').position.x = mp[0]
	#print(get_node('CharacterBody2D'))
	#print('before', position)
	position.x = mp[0]
	position.y = mp[1]
	#print(mp[0], " , ", mp[1])
	#position.x = 100
	#position.y = 200
	#print('after', position)
