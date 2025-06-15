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
var may_need_to_tag_up:bool = false
var able_to_score:bool = false
var reached_next_base:bool = false
var can_be_force_out_before_play:bool = false
var runners :Array = []
var runners_before :Array = []
var runners_after :Array = []
var runner_before = null
var runner_after = null
var animation:String = "idle"
#var state:String = "nonexistant" # nonexistant, 
var post_play_target_position:Vector3 = Vector3(10, 0, -5)
var force_to_base = null # When ball is over wall
var slide_prop:float = -1
const slide_anim_duration:float = 0.6 # full is 1.2
const slide_speed_multiplier:float = 1.5
var sliding_to_base = -1 # -1 if not, otherwise int to base

const possible_states:Array = [
	# Done for play states
	'not_exist', 'out_done', 'out_running_to_sideline',
	'scored_done', 'scored_running_to_sideline', 'sliding_out',
	# Active states (except sliding could be out, check after anim done)
	'standing_on_base', 'running', 'sliding_not_out', 'changing_direction',
	# Waiting to score states: if may have to tag up, then potentially active
	'waiting_to_score_done', 'waiting_to_score_running_to_sideline',
	'waiting_to_score_may_need_to_tag']
var state:String = 'standing_on_base'

signal signal_scored_on_play
signal reached_next_base_signal
@onready var ball = get_tree().get_first_node_in_group("ball")

var is_frozen:bool = false
func freeze() -> void:
	is_frozen = true
	visible = false
	set_physics_process(false)

func pause() -> void:
	$Char3D.pause()
	#super().pause()
	#$Player3D.pause()
	set_physics_process(false)

func unpause() -> void:
	$Char3D.unpause()
	#super().pause()
	#$Player3D.pause()
	set_physics_process(true)

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
	may_need_to_tag_up = true
	max_running_progress = running_progress
	target_base = start_base + 1
	able_to_score = false
	force_to_base = null
	sliding_to_base = -1
	$ClickToRunArrow.visible = false
	
	$Char3D.reset() # Resets rotation
	set_look_at()
	set_animation("idle")
	$Char3D.set_color(color)

	
	update_position()
	

func is_active():
	return (exists_at_start and
			not out_on_play and
			not scored_on_play and
			not (force_to_base != null and
				abs(force_to_base - running_progress) < 1e-8))

func runner_is_out() -> void:
	assert(state in [
		'standing_on_base', 'running', 'sliding_not_out', 'changing_direction',
		'waiting_to_score_may_need_to_tag'
	])
	out_on_play = true
	is_running = false
	if state == 'sliding_not_out':
		set_state('sliding_out')
	else:
		set_state('out_running_to_sideline')

func _ready() -> void:
	running_progress = start_base*1.
	max_running_progress = running_progress
	target_base = start_base + 1
	
	post_play_target_position += Vector3(2, 0, 2) * start_base
	
	runners = get_tree().get_nodes_in_group('runners')
	runners_before = []
	for runner in runners:
		if runner.start_base < start_base:
			runners_before.append(runner)
		elif runner.start_base > start_base:
			runners_after.append(runner)
	runners_before.sort_custom(sort_runners)
	runners_after.sort_custom(sort_runners)
	#printt('sorted runners_after', runners_after)
	#printt('sorted runners_before', runners_before)
	
	$Char3D.connect("animation_finished_signal", _on_animation_finished_from_char3d)

func sort_runners(a,b) -> bool:
	return a.start_base < b.start_base

signal tag_up_signal
func _physics_process(delta: float) -> void:
	if start_base == 2 and randf() < .1:
		printt('in runner pp', start_base, state, animation, is_running, running_progress, target_base, able_to_score)
	if is_frozen:
		return
	
	# States that do nothing
	if state in [
		'not_exist', 
		'waiting_to_score_may_need_to_tag'
		]:
		return
	# Standing on base can only 
	if state == 'standing_on_base':
		check_tag_up()
		return
	# States that watch ball but don't ever move
	if state in ['out_done',
		'scored_done', 'waiting_to_score_done']:
		# On target, watch ball
		look_at_ball()
		return
	# States that run to sideline
	if state in ['out_running_to_sideline', 'scored_running_to_sideline',
		'waiting_to_score_running_to_sideline']:
		if animation == 'idle':
			set_animation('running')
		var dist = position.distance_to(post_play_target_position)
		var distance_can_move = delta * SPEED * .7 # (Jog)
		if distance_can_move >= dist:
			# Move to end point
			position = post_play_target_position
			# Stop animation
			set_animation('idle')
			# Update state
			if state == 'out_running_to_sideline':
				set_state('out_done')
			elif state == 'scored_running_to_sideline':
				set_state('scored_done')
			elif state == 'waiting_to_score_running_to_sideline':
				set_state('waiting_to_score_done')
			# Look at ball
			look_at_ball()
		else:
			# Move towards target
			position += distance_can_move * (post_play_target_position - position).normalized()
			# Face target
			set_look_at_pos(post_play_target_position)
		return
	
	assert(state in ['running', 'sliding_not_out', 'sliding_out', 'changing_direction'])
	
	if state in ['sliding_not_out', 'sliding_out']:
		assert(sliding_to_base > 0.5)
		var time_left_in_slide = max(0,
			min($Char3D.time_left_in_current_anim(), slide_anim_duration))
		# Update position
		if sliding_to_base > running_progress:
			printt('in runner sliding forward rprog before is', running_progress, slide_anim_duration,
				slide_prop, time_left_in_slide, slide_anim_duration)
			# Sliding forward
			var next_running_progress = sliding_to_base - \
				slide_prop * time_left_in_slide / slide_anim_duration
			check_will_reach_next_base(next_running_progress)
			running_progress = next_running_progress
			printt('in runner sliding forward rprog after is', running_progress, slide_anim_duration, slide_prop)
		else:
			# Sliding backward
			running_progress = sliding_to_base + \
				slide_prop * time_left_in_slide / slide_anim_duration
		update_position()
		max_running_progress = max(max_running_progress, running_progress)
		return
	
	assert(state == 'running')
	
	# Check for tag up in case ball was just caught and they are close enough to base
	check_tag_up()
	
	assert(is_running)
	# Base running
	if is_running:
		#printt('is running, running progress', running_progress, start_base, target_base)
		# Find next position
		var dir = 1
		if target_base < running_progress:
			dir = -1
		var next_running_progress = running_progress + delta*SPEED/30 * dir
		
		# Check if they will get to close to next or previous runner,
		#  don't get closer than certain distance
		var blocked = false
		if dir > 0:
			var runner_in_front = active_runner_after()
			if runner_in_front != null:
				if runner_in_front.running_progress - next_running_progress < 0.1:
					blocked = true
		else:
			var runner_behind = active_runner_before()
			if runner_behind != null:
				if next_running_progress - runner_behind.running_progress < 0.1:
					blocked = true
		if blocked:
			next_running_progress = running_progress
		
		# Check if they will cross base after start base
		#  Field needs to know for force out reasons
		check_will_reach_next_base(next_running_progress)
		
		# Check if they will reach or cross a base or neither
		if randf() < .01:
			printt('in runner checking for slide', start_base, running_progress, target_base, slide_prop,
			 target_base - running_progress > slide_prop and 
					target_base - next_running_progress < slide_prop and 
					!needs_to_tag_up and target_base > 1.5
			)
		if ((running_progress <= target_base and next_running_progress >= target_base) or
			(running_progress >= target_base and next_running_progress <= target_base)):
			# Reaching target base, stop them there
			running_progress = target_base
			is_running = false
			set_state('standing_on_base')
			set_animation('idle')
			set_look_at()
		elif floor(running_progress) < floor(next_running_progress):
			# Crossing a base in forward direction, update look position
			running_progress = next_running_progress
			set_look_at()
		elif ((dir > 0  and target_base - running_progress > slide_prop and 
					target_base - next_running_progress < slide_prop and 
					!needs_to_tag_up and target_base > 1.5) or
			(dir < 0 and running_progress - target_base > slide_prop and
					next_running_progress - target_base < slide_prop)):
			printt('in runner starting to slide', start_base, running_progress, next_running_progress, target_base, slide_prop)
			# Cross a sliding position, change state
			running_progress = next_running_progress
			sliding_to_base = roundi(target_base)
			set_state('sliding_not_out')
			set_animation('slide')
		else: # Not crossing any base
			# Update progress
			running_progress = next_running_progress
		max_running_progress = max(running_progress, max_running_progress)
		update_position()
	
	# Reset max_running_progress if need to return
	if needs_to_tag_up and not tagged_up_after_catch:
		max_running_progress = start_base
	
	# Check for tag up in case they went back
	check_tag_up()
	
	check_scored()

func check_scored() -> void:
	# Scored run. Can't do it when they first reach 4 since they may not be eligible then
	if (running_progress >= 4 and not scored_on_play):
		running_progress = 4
		if (able_to_score and
			(not needs_to_tag_up or tagged_up_after_catch)):
			# Runner scores
			is_running = false
			scored_on_play = true
			#visible = false
			signal_scored_on_play.emit()
			set_state('scored_running_to_sideline')
			printt('RUNNER SCORED, SHOULDNT BE VISIBLE', start_base)
		elif needs_to_tag_up and not tagged_up_after_catch:
			# Doesn't score, needs to go back, stays in play
			set_state('standing_on_base')
		elif may_need_to_tag_up:
			# May need to tag up, so stay there
			set_state('waiting_to_score_may_need_to_tag')
		else:
			# Runner can't score yet, but is done with baserunning
			#   (never need to go back)
			assert(not able_to_score)
			set_state('waiting_to_score_running_to_sideline')
			#printt("RUNNER IS WAITING TO SCORE", start_base, able_to_score, needs_to_tag_up, tagged_up_after_catch)

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
	# direction: 1 if forward, -1 if backward
	# can_go_past: If near next base, should they go to following base?
	#printt('In runner send_runner', start_base, direction, can_go_past)
	if not is_active():
		return
	assert(state in ['standing_on_base', 'running', 'sliding_not_out',
		'waiting_to_score_may_need_to_tag'])
	var new_target_base:int = -1
	if direction == 1:
		#printt('In runner, sending forward!!!', start_base, direction, can_go_past)
		#if running_progress-1e-8 - floor(running_progress-1e-8) > .5 or target_base < running_progress:
			#target_base = floor(running_progress) + 1
			#is_running = true 
			#printt('actually send forward')
		#else:
			#printt('didnt actually send forward', running_progress, target_base)
		if running_progress >= 4:
			# If made it home and just waiting, don't send forward
			pass
		else:
			# Run forward
			if target_base < running_progress:
				# If going backward, send forward to next
				new_target_base = ceil(running_progress)
			elif can_go_past and running_progress > floor(running_progress) + 1 - .3:
				# If already going forward and near next base, send to following base
				new_target_base = floor(running_progress)
			else:
				# Can't go past, only go to next
				new_target_base = floor(running_progress) + 1
	elif direction == -1:
		#print('sending backward!!!')
		if running_progress > 1 and running_progress > start_base:
			# Can't go back to home or if standing where started
			# Standing on base, go to previous
			if state in ['standing_on_base', 'waiting_to_score_may_need_to_tag']:
				# Go to previous base, unless reached home and no reason to return
				assert(abs(running_progress - round(running_progress)) < 1e-8)
				new_target_base = roundi(running_progress)
			else:
				# In between bases, go back
				assert(state in ['running', 'sliding_not_out'], state)
				#printt('going back?', running_progress, target_base, may_need_to_tag_up)
				new_target_base = floor(running_progress)
	else:
		printerr("bad in send_runner, should be +1 or -1", direction)
	
	if new_target_base > -0.5:
		printt("in runner send_runner, new target base is", new_target_base)
		send_runner_to_base(new_target_base)

func send_runner_to_base(base:float) -> void:
	printt('in runner send_runner_to_base', start_base, base)
	assert(state in ['standing_on_base', 'running',
		'sliding_not_out',
		'waiting_to_score_may_need_to_tag'], state)
	if base < .9999 or base > 4.0001:
		push_warning('in runner send_runner_to_base bad value for base', base)
		return
	if not is_active():
		return
	target_base = base
	if abs(target_base - running_progress) < 1e-12:
		# No need to run, already where want to be
		if state in ['running']:
			# Switch from running to standing
			is_running = false
			set_animation('idle')
			set_state('standing_on_base')
			running_progress = target_base
		else:
			# Already in state that knows it's standing on base
			assert(state in
				['standing_on_base', 'waiting_to_score_may_need_to_tag',
				'running', 'sliding_not_out'],
				state)
	else:
		#printt('in runner send_runner_to_base changing state to running')
		if state != 'sliding_not_out':
			is_running = true 
			set_animation('running')
			set_state('running')

func end_state() -> String:
	# Not related to the state variable, maybe need to rename
	#printt('checking runner end_state', start_base, scored_on_play, out_on_play, running_progress)
	if not exists_at_start:
		return ''
	if scored_on_play:
		return "scored"
	if out_on_play:
		return "out"
	if needs_to_tag_up and not tagged_up_after_catch:
		# This covers cases where final out is fly out
		return str(start_base)
	#printt('runner end_state', start_base, str(round(running_progress)))
	return str(roundi(running_progress))

func setup_player(player, team, is_home_team:bool) -> void:
	if player != null:
		exists_at_start = true
		SPEED = player.speed_mps()
		slide_prop = slide_speed_multiplier * SPEED * slide_anim_duration / 30
	else: # x is null, no runner
		exists_at_start = false
		set_physics_process(false)
		visible = false
	if team != null:
		$Char3D.set_color_from_team(player, team, is_home_team)
	if is_home_team and post_play_target_position.x > 0:
		post_play_target_position.x *= 1
	if exists_at_start:
		set_state('standing_on_base')
		set_animation('idle')
	else:
		set_state('not_exist')

func active_runner_before():
	for i in range(len(runners_before)-1,-1, -1):
		var r = runners_before[i]
		if r.is_active():
			return r
	return null

func active_runner_after():
	for r in runners_after:
		if r.is_active():
			return r
	return null

func is_done_for_play() -> bool:
	if not exists_at_start:
		return true
	if out_on_play or scored_on_play:
		return true
	if force_to_base != null and abs(force_to_base - running_progress) < 1e-8:
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
	$Char3D.start_animation(new_anim, false, false)
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
	elif animation in ["running", "slide"]:
		#lookat = base_positions[min(round(target_base), 4) - 1]
		if target_base < running_progress:
			lookat = base_positions[min(round(target_base), 4) - 1]
		else:
			lookat = base_positions[min(floor(running_progress) + 1, 4) - 1]
		#printt('set_look_at()', start_base, lookat)
	else:
		push_error("Error in runner_3d.gd, set_look_at()", animation)
	
	# Skip if already at point, otherwise gives error
	if lookat.distance_to(position) < .2:
		return
	# Set it
	#lookat = to_global(lookat)
	lookat = lookat.rotated(Vector3(0,1,0), 45.*PI/180)
	#printt('set_look_at() 2', start_base, lookat)
	$Char3D.look_at(lookat, Vector3.UP, true)

func set_look_at_pos(pos:Vector3) -> void:
	if pos.distance_to(position) < .2:
		return
	pos = pos.rotated(Vector3(0,1,0), 45.*PI/180)
	$Char3D.look_at(pos, Vector3.UP, true)

var base_positions = [
	Vector3(-1,0,1)*30/sqrt(2), # 1
	Vector3(0,0,1)*30*sqrt(2), # 2
	Vector3(1,0,1)*30/sqrt(2), # 3
	Vector3(0,0,0) # Home
]

func ball_over_wall(base:int) -> void:
	if is_active():
		force_to_base = base
		send_runner_to_base(force_to_base)

func set_click_arrow(mpos:Vector3, just_clicked:bool) -> int:
	# Returns:
	#  0 - click not used
	#  1 - send forward
	#  -1 - send backward
	# Runner must be active
	# Mouse must be close to runner
	# Can't be too close, hard to tell direction
	if ((not is_active()) or
		(mpos.distance_to(position) > 7.5) or 
		(mpos.distance_to(position) <= 1e-8)
		):
		$ClickToRunArrow.visible = false
		return 0
	var front_base:int = floor(running_progress) + 1
	var back_base:int = ceil(running_progress) - 1
	var diff:Vector3 = mpos - position
	if front_base <= 4:
		var front_base_pos:Vector3 = base_positions[front_base - 1]
		var a:Vector3 = front_base_pos - position
		var angle_forward:float = angle_between(a, diff)
		#printt('angle_forward', angle_forward, back_base)
		if angle_forward <= 45*PI/180:
			#var arrow_angle = angle_between(a, Vector3(0,0,1))
			var arrow_angle_deg = -135 + 90 * front_base
			$ClickToRunArrow.visible = true
			$ClickToRunArrow.set_color(Color(1.,1.,0.5,1.), arrow_angle_deg)
			if just_clicked:
				send_runner(+1, true)
				var base1 = target_base
				var runner_temp = active_runner_after()
				while true:
					if runner_temp == null:
						break
					if runner_temp.target_base > base1:
						break
					runner_temp.send_runner_to_base(base1 + 1)
					runner_temp = runner_temp.active_runner_after()
					base1 = base1 + 1
			return 1
	if back_base >= 1 and back_base <= 3:
		var back_base_pos:Vector3 = base_positions[back_base - 1]
		var a:Vector3 = back_base_pos - position
		var angle_backward:float = angle_between(a, diff)
		#printt('angle_backward is', angle_backward)
		if angle_backward <= 45*PI/180:
			var arrow_angle_deg = 135 + 90 * back_base
			$ClickToRunArrow.visible = true
			$ClickToRunArrow.set_color(Color('red'), arrow_angle_deg)
			if just_clicked:
				send_runner(-1, false)
				var base1 = target_base
				var runner_temp = active_runner_before()
				while true:
					if runner_temp == null:
						break
					if runner_temp.target_base < base1:
						break
					runner_temp.send_runner_to_base(base1 - 1)
					runner_temp = runner_temp.active_runner_before()
					base1 = base1 - 1
			return -1
	$ClickToRunArrow.visible = false
	# No action taken
	return 0

func angle_between(a:Vector3, b:Vector3) -> float:
	return acos((a.dot(b)) / (a.length() * b.length()))

func _on_animation_finished_from_char3d(anim_name) -> void:
	printt('in runner anim finished', anim_name)
	if anim_name == 'slide':
		set_animation('idle')
		running_progress = sliding_to_base
		sliding_to_base = -1
		check_will_reach_next_base(running_progress)
		max_running_progress = running_progress
		is_running = false
		if state == 'sliding_out':
			set_state('out_running_to_sideline')
		elif state == 'sliding_not_out':
			if running_progress > 3.5:
				# Standing on home, maybe scored, let this func figure it out
				set_state('standing_on_base')
				check_scored()
			elif abs(target_base - running_progress) < 1e-8:
				set_state('standing_on_base')
			else:
				# Input was given to update target base
				set_state('running')
				is_running = true
		else:
			assert(false, 'runner state cannot be here')

func set_state(new_state:String) -> void:
	if !possible_states.has(new_state):
		printt('in runner set_state error with new state', new_state)
	assert(possible_states.has(new_state))
	state = new_state

func look_at_ball() -> void:
	set_look_at_pos(ball.position * Vector3(1,0,1))

func now_able_to_score() -> void:
	able_to_score = true
	if state in ['waiting_to_score_done',
		'waiting_to_score_running_to_sideline',
		'waiting_to_score_may_need_to_tag']:
		# Runner scores
		is_running = false
		running_progress = 4
		scored_on_play = true
		#visible = false
		signal_scored_on_play.emit()
		set_state('scored_running_to_sideline')

func check_tag_up() -> void:
	if not tagged_up_after_catch and needs_to_tag_up and running_progress - start_base < 1e-8:
		tagged_up_after_catch = true
		tag_up_signal.emit()

func check_will_reach_next_base(next_running_progress:float) -> void:
	# Check if they will cross base after start base
	#  Field needs to know for force out reasons
	if max_running_progress < start_base + 1 and next_running_progress >= start_base + 1:
		reached_next_base = true
		reached_next_base_signal.emit()
