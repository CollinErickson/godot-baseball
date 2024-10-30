extends Node3D

var camera_dict:Dictionary = {}

func _ready() -> void:
	pass
	for cam in get_children():
		#printt('camera child:', cam, cam.name, cam.position, cam.rotation)
		camera_dict[cam.name] = {'pos': cam.position, 'rot': cam.rotation}
	#printt('cam dict is', camera_dict)

func reset() -> void:
	pass
	# Reset all cameras to original position and angle
	#printt('Resetting all cameras')
	for cam in get_children():
		if cam.name in camera_dict.keys():
			#printt('about to reset camera', cam.name, camera_dict[cam.name])
			cam.position = camera_dict[cam.name]['pos']
			cam.rotation = camera_dict[cam.name]['rot']
			#printt('reset camera', cam.name)
