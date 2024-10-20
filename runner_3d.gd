extends CharacterBody3D


const SPEED = 8.0

@export_category("Baseball")
@export var start_base : int

var is_running = false
var running_progress
var exists_at_start = true
var out_on_play = false
var scored_on_play = false # TODO use this
var tagged_up_after_catch
var max_running_progress
var target_base

func is_active():
	return exists_at_start and not out_on_play and not scored_on_play

func runner_is_out() -> void:
	out_on_play = true
	set_physics_process(false)
	is_running = false
	visible = false

func _ready() -> void:
	running_progress = start_base*1.
	max_running_progress = running_progress
	target_base = start_base + 1

func _physics_process(delta: float) -> void:
	
	# Base running
	if is_running:
		#printt('running progress', running_progress, start_base, target_base)
		# Check if they will cross target_base
		var dir = 1
		if target_base < running_progress:
			dir = -1
		var next_running_progress = running_progress + delta*SPEED/30 * dir
		
		if ((running_progress <= target_base and next_running_progress >= target_base) or
			(running_progress >= target_base and next_running_progress <= target_base)):
			running_progress = target_base
			max_running_progress = running_progress
			is_running = false
			# Scored run
			if running_progress >= 4:
				is_running = false
				running_progress = 4
				scored_on_play = true
				visible = false
				#print('SCORED, SHOULDNT BE VISIBLE')
		else: # Not crossing base
			# Update progress
			running_progress = next_running_progress
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
				printerr('bad 0941029: ', running_progress, ' , ', start_base)
			#printt('RUN', is_running, running_progress, position)
		
func send_runner(direction: int) -> void:
	if not is_active():
		return
	if direction == 1:
		#printt('sending forward!!!')
		if running_progress-1e-8 - floor(running_progress-1e-8) > .5 or target_base < running_progress:
			target_base = floor(running_progress) + 1
			is_running = true 
	elif direction == -1:
		#print('sending backward!!!')
		if running_progress > 1 and running_progress > start_base + 1e-8: # Can't go back to home
			# Standing on base, go to previous
			if running_progress == floor(running_progress):
				# Go to previous base
				target_base = floor(running_progress) - 1
				is_running = true
			else:
				# In between bases, go back
				#printt('going back?', running_progress, target_base)
				target_base = floor(running_progress)
				is_running = true
	else:
		printerr("bad in send_runner", direction)
