extends CharacterBody3D


const SPEED = 8.0

@export_category("Baseball")
@export var start_base : int

var is_running = false
var running_progress
var exists_at_start = true
var out_on_play = false
var tagged_up_after_catch
var max_running_progress

func runner_is_out() -> void:
	out_on_play = true
	set_physics_process(false)
	is_running = false
	visible = false

func _ready() -> void:
	running_progress = start_base*1.
	max_running_progress = running_progress

func _physics_process(delta: float) -> void:
	
	# Base running
	if is_running:
		# Update progress
		running_progress += delta*SPEED/30
		if running_progress >= 4:
			is_running = false
			running_progress = 4
		max_running_progress = max(running_progress, max_running_progress)
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
		
