extends CharacterBody3D


const SPEED = 5.0

var is_running = false
var running_progress

func _physics_process(delta: float) -> void:
	
	# Base running
	if is_running:
		# Update progress
		running_progress += delta*SPEED/30
		if running_progress >= 4:
			is_running = false
			running_progress = 4
		# Update location
		if running_progress < 1:
			position = Vector3(-1,0,1).normalized() * (running_progress * 30)
		elif running_progress < 2:
			position = Vector3(-1,0,1).normalized() * (30) + Vector3(1,0,1).normalized() * ((running_progress-1) * 30)
		elif running_progress < 3:
			position = Vector3(1,0,1).normalized() * (30) + Vector3(-1,0,1).normalized() * ((3 - running_progress) * 30)
		elif running_progress <= 4:
			position = Vector3(1,0,1).normalized() * ((4 - running_progress) * 30)
		else:
			printerr('bad 0941029')
		#printt('RUN', is_running, running_progress, position)
