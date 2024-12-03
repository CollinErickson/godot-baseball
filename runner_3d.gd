extends CharacterBody3D


var SPEED = 8.0 # yds/sec. 8 is avg

@export_category("Baseball")
@export var start_base : int

var is_running:bool = false
var running_progress:float
var exists_at_start:bool = true
var out_on_play:bool = false
var scored_on_play:bool = false
var tagged_up_after_catch:bool = true
var max_running_progress:float = -1
# 1/2/3/4 for bases, but can be inbetween (halfway on fly ball, no other reason)
var target_base:float = -1
var needs_to_tag_up:bool = false
var able_to_score:bool = false
var reached_next_base:bool = false
var can_be_force_out_before_play:bool = false
var runners :Array = []
var runners_before :Array = []
var runners_after :Array = []
var runner_before = null
var runner_after = null
var animation:String = "idle"

signal signal_scored_on_play
signal reached_next_base_signal

var is_frozen:bool = false
func freeze() -> void:
	is_frozen = true
	visible = false
	set_physics_process(false)

func reset(color) -> void:
	#print('RESET RUNNER', start_base)
	is_frozen = false
	visible = true
	set_physics_process(true)
	
	is_running = false
	running_progress = start_base*1. + 0.10 # Lead off
	exists_at_start = true
	out_on_play = false
	scored_on_play = false
	tagged_up_after_catch = true
	needs_to_tag_up = false
	max_running_progress = running_progress
	target_base = start_base + 1
	able_to_score = false
	
	set_look_at()
	set_animation("idle")
	$Char3D.set_color(color)

	
	update_position()
	

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
	
	runners = get_tree().get_nodes_in_group('runners')
	runners_before = []
	for runner in runners:
		if runner.start_base < start_base:
			runners_before.append(runner)
		elif runner.start_base > start_base:
			runners_after.append(runner)

signal tag_up_signal
func _physics_process(delta: float) -> void:
	if is_frozen or out_on_play or scored_on_play:
		return
	
	#print('running needs to tag', needs_to_tag_up, start_base)
	# Tag up
	if not tagged_up_after_catch and needs_to_tag_up and running_progress - start_base < 1e-8:
		tagged_up_after_catch = true
		tag_up_signal.emit()
	# Base running
	if is_running:
		#printt('is running, running progress', running_progress, start_base, target_base)
		# Check if they will cross target_base
		var dir = 1
		if target_base < running_progress:
			dir = -1
		var next_running_progress = running_progress + delta*SPEED/30 * dir
		
		# TODO: Check if they will get to close to next or previous runner
		var blocked = false
		if dir > 0:
			for runner in runners_after:
				if runner.is_active():
					if runner.running_progress - next_running_progress < 0.1:
						blocked = true
		else:
			for runner in runners_before:
				if runner.is_active():
					if next_running_progress - runner.running_progress < 0.1:
						blocked = true
		if blocked:
			next_running_progress = running_progress
		
		if max_running_progress < start_base + 1 and next_running_progress >= start_base + 1:
			reached_next_base = true
			reached_next_base_signal.emit()
		
		# Check if they will reach the target base, if yes, stop them there
		if ((running_progress <= target_base and next_running_progress >= target_base) or
			(running_progress >= target_base and next_running_progress <= target_base)):
			running_progress = target_base
			max_running_progress = max(max_running_progress, running_progress)
			is_running = false
			set_animation('idle')
		else: # Not crossing base
			# Update progress
			running_progress = next_running_progress
			max_running_progress = max(running_progress, max_running_progress)
			update_position()
	
	# Reset max_running_progress if need to return
	if needs_to_tag_up and not tagged_up_after_catch:
		max_running_progress = start_base
	
	# Scored run. Can't do it when they first reach 4 since they may not be eligible then
	if (running_progress >= 4 and not scored_on_play):
		if (able_to_score and
			(not needs_to_tag_up or tagged_up_after_catch)):
			is_running = false
			running_progress = 4
			scored_on_play = true
			visible = false
			signal_scored_on_play.emit()
			printt('RUNNER SCORED, SHOULDNT BE VISIBLE', start_base)
		else:
			#printt("RUNNER IS WAITING TO SCORE", start_base, able_to_score, needs_to_tag_up, tagged_up_after_catch)
			running_progress = 4

func update_position():
	# Update location on field based on running_progress
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
		
func send_runner(direction: int, can_go_past:bool=true) -> void:
	if not is_active():
		return
	if direction > 0.5:
		#printt('In runner, sending forward!!!', start_base, direction, can_go_past)
		#if running_progress-1e-8 - floor(running_progress-1e-8) > .5 or target_base < running_progress:
			#target_base = floor(running_progress) + 1
			#is_running = true 
			#printt('actually send forward')
		#else:
			#printt('didnt actually send forward', running_progress, target_base)
		is_running = true
		if target_base < running_progress:
			# If going backward, send forward to next
			target_base = ceil(running_progress)
		elif can_go_past and running_progress > target_base - .3:
			# If already going forward and near next base, send to following base
			target_base += 1
		elif not can_go_past:
			target_base = floor(running_progress) + 1
		else:
			pass
	elif direction == -1:
		#print('sending backward!!!')
		if running_progress > 1 and running_progress > start_base: # Can't go back to home
			# Standing on base, go to previous
			if abs(running_progress - floor(running_progress)) < 1e-16:
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
	if is_running:
		set_animation('running')
	else:
		set_animation('idle')

func send_runner_to_base(base:float) -> void:
	#printt('in runner send_runner_to_base', start_base, base)
	target_base = base
	if abs(target_base - running_progress) < 1e-12:
		is_running = false
		set_animation('idle')
	else:
		is_running = true 
		set_animation('running')

func end_state() -> String:
	#printt('checking runner end_state', start_base, scored_on_play, out_on_play, running_progress)
	if not exists_at_start:
		return ''
	if scored_on_play:
		return "scored"
	if out_on_play:
		return "out"
	#printt('runner end_state', start_base, str(round(running_progress)))
	return str(round(running_progress))

func setup_player(x) -> void:
	if x != null:
		exists_at_start = true
		SPEED = x.speed_mps()
		#x.print_()
		#printt('runner speed is', SPEED, start_base)
	else: # x is null, no runner
		exists_at_start = false
		set_physics_process(false)
		visible = false

func is_done_for_play() -> bool:
	if not exists_at_start:
		return true
	if out_on_play or scored_on_play:
		return true
	if needs_to_tag_up and not tagged_up_after_catch:
		return false
	if is_running:
		return false
	if abs(running_progress - round(running_progress)) > 1e-8:
		return false
	if running_progress > 3.5: # Can't be waiting for score at home
		return false
	# TODO: What if they are standing on a base but need to go to the next base?
	# Otherwise, they should be standing on a base
	return true

func can_be_force_out() -> bool:
	for runner in runners_before:
		if !runner.is_active():
			return false
	return (can_be_force_out_before_play and
		running_progress < start_base + 1 and
		max_running_progress < start_base + 1)


func set_animation(new_anim):
	if new_anim == animation:
		set_look_at() # Running but can change direction
		return
	animation = new_anim
	#if new_anim == "idle":
		#pass
	#if new_anim == "moving":
	$Char3D.start_animation(new_anim)
	set_look_at()

func set_look_at():
	var lookat
	if animation == "idle":
		lookat = position
		if floor(running_progress) < .5: # Running to 1st
			lookat += Vector3(30,0,30)
		elif floor(running_progress) < 1.5: # Running to 2nd
			lookat += Vector3(30,0,-30)
		elif floor(running_progress) < 2.5: # Running to 3rd
			lookat += Vector3(-30,0,-30)
		else: # Running to Home
			lookat += Vector3(-30,0,30)
	elif animation == "running":
		lookat = base_positions[min(round(target_base), 4) - 1]
		#printt('set_look_at()', start_base, lookat)
	else:
		push_error("Error in runner_3d.gd, set_look_at()", animation)
	
	# Set it
	#lookat = to_global(lookat)
	lookat = lookat.rotated(Vector3(0,1,0), 45.*PI/180)
	#printt('set_look_at() 2', start_base, lookat)
	$Char3D.look_at(lookat, Vector3.UP, true)


var base_positions = [
	Vector3(-1,0,1)*30/sqrt(2), # 1
	Vector3(0,0,1)*30*sqrt(2), # 2
	Vector3(1,0,1)*30/sqrt(2), # 3
	Vector3(0,0,0) # Home
]
