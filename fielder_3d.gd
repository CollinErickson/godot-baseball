extends CharacterBody3D

@export_group("Baseball")
@export var posname: String
@export var posnum: int

var SPEED:float = 8.0
const MAX_ACCEL:float = 100.0
var max_throw_speed:float = 30.0
const catch_radius_xz:float = 2
var catch_max_y:float = 2.5
var throws:String = 'R'
const time_throw_animation_release_point:float = 0.41
const time_toss_animation_release_point:float = 0.31

var assignment # cover, ball, ball_click, ball_carry, wait_to_receive, holding_ball, over_wall
var assignment_pos # Position to go to for assignment
var holding_ball:bool = false
var user_is_pitching_team:bool
var time_last_began_holding_ball
var position_holding_ball_reassigned_fielders = null
var position_assignment_ball_reassigned_fielders = null
var running_with_ball_to_base = null
var start_position = Vector3()
@onready var fielders = get_tree().get_nodes_in_group('fielders')
@onready var runners = get_tree().get_nodes_in_group("runners")
const BallClass = preload("res://ball_3d.gd")
@onready var ball:BallClass = get_tree().get_first_node_in_group("ball")
var animation:String = "idle"
const possible_states:Array = ['free', 'throwing', 'precatch', 'catching']
var state:String = "free"
var time_in_state:float = 0
var throw_mode:String = "" # "Button", "Bar"
var defense_control:String = "" # "Automatic", "Throwing", "Manual"
var user_fields:bool # If user is defense, whether they are controlling fielding
var user_throws:bool # If user is defense, whether they are controlling throwing
var prev_position:Vector3
var prev_global_position:Vector3
var turn_off_bad_throw_label_timer:float = 0
var turn_off_bad_catch_label_timer:float = 0
var target_fielder_info:Dictionary = {}

const Player_tscn = preload("res://scripts/player.gd")
var player: Player_tscn

var timers_to_restart_on_unpause:Array = []
var timer_action
var timer_args

var is_frozen:bool = false
func freeze() -> void:
	set_not_selected_fielder()
	is_frozen = true
	visible = false
	set_physics_process(false)

func pause() -> void:
	$Char3D.pause()
	set_physics_process(false)
	
	# Pause timers
	for timer in [$Timer]:
		if timer.time_left > 0:
			timers_to_restart_on_unpause += [[$Timer, timer.time_left]]
			timer.stop()

func unpause() -> void:
	$Char3D.unpause()
	set_physics_process(true)
	
	# Unpause timers
	for i in range(len(timers_to_restart_on_unpause)):
		var timer = timers_to_restart_on_unpause[i][0]
		timer.wait_time = timers_to_restart_on_unpause[i][1]
		timer.start()
	timers_to_restart_on_unpause = []

func reset(throw_mode_:String, defense_control_:String,
			user_is_pitching_team_:bool) -> void:
	is_frozen = false
	visible = true
	set_physics_process(true)
	# Reset vars
	position = start_position
	velocity = Vector3()
	
	player = null
	assignment = null
	assignment_pos = null
	#holding_ball = false
	#time_last_began_holding_ball = null
	#remove_from_group('fielder_holding_ball')
	set_holding_ball(false)
	state = 'free'
	time_in_state = 0
	
	# End start throw
	start_throw_started = false
	start_throw_base = null
	start_throw_fielder = null
	start_throw_key_check_release = null
	throw_ready = false
	throw_ready_success = true
	throw_ready_intensity = 1
	$ThrowBar.visible = false
	$ThrowBar.active = false
	$ThrowBarOneWay.visible = false
	$ThrowBarOneWay.active = false
	$Timer.stop()
	timer_action = null
	timer_args = null
	timers_to_restart_on_unpause = []
	
	user_is_pitching_team = user_is_pitching_team_
	throw_mode = throw_mode_
	defense_control = defense_control_
	assert(defense_control_ in ['Automatic', 'Throwing', 'Manual'])
	user_fields = user_is_pitching_team_ and (defense_control_ in ['Manual'])
	user_throws = user_is_pitching_team_ and (defense_control_ in ['Throwing', 'Manual'])
	
	$BadThrowLabel3D.visible = false
	turn_off_bad_throw_label_timer = 0
	turn_off_bad_catch_label_timer = 0
	target_fielder_info = {}
	running_with_ball_to_base = null
	remove_from_group("fielder_running_with_ball_to_base")
	$Arrow2DOffscreenDirection.visible = false
	
	$Char3D.reset() # Resets rotation
	#$Char3D.look_at(Vector3(0,0,0), Vector3.UP, true)
	if posname == 'P':
		#set_look_at_position(Vector3(100,0,position.z))
		set_look_at_position(Vector3(0,0,0))
	else:
		set_look_at_position(Vector3(0,0,0))
	set_animation("idle")
	force_animation_idle()
	#$Char3D.set_color(color)
	
	set_not_selected_fielder()
	set_not_targeted_fielder()
	set_not_cutoff_fielder()
	set_not_alt_fielder()

# Rotate sprites to face the camera
func align_sprite():
	var cam = get_viewport().get_camera_3d()
	#print('in align_sprite, cam is')
	#print(cam)
	var tantheta = (position.x - cam.position.x) / (position.z - cam.position.z)
	#printt("tantheta is:", tantheta)
	rotation.y = atan(tantheta)

func assign_to_field_ball(pos):
	printt('in fielder, assign_to_field_ball', posname, pos)
	set_assignment('ball')
	assignment_pos = pos
	assignment_pos.y = 0
	if user_is_pitching_team:
		set_selected_fielder()
	set_not_cutoff_fielder()

func assign_to_cover_base(base, ball_pos=null, distance_away:float=10):
	set_not_cutoff_fielder()
	set_assignment('cover')
	if base == 1:
		assignment_pos = Vector3(-1,0,1) * 30/sqrt(2)
	elif base == 2:
		assignment_pos = Vector3(0,0,1) * 30/sqrt(2) * 2
	elif base == 3:
		assignment_pos = Vector3(1,0,1) * 30/sqrt(2)
	elif base == 4:
		assignment_pos = Vector3(0,0,0)
	elif base == 5:
		# Cutoff
		set_cutoff_fielder()
		# Assign to halfway between ball position and 2nd base
		# TODO: make this most relevant base, not always 2nd base
		assignment_pos = .5*(Vector3(0,0,1)*30*sqrt(2) + ball_pos)
		assignment_pos.y = 0
		#printt('in fielder assigning to cutoff:', posname, position,
		#	assignment_pos, Time.get_ticks_msec()/1e3)
	elif base == 6:
		# Assign to location
		assert(distance_away != null)
		assert(distance_away > 0)
		if distance_xz(position, ball_pos) < distance_away:
			# Close enough
			pass
			#printt('in fielder NOT assigning to 6:', posname, position,
			#	Time.get_ticks_msec()/1e3, ball_pos)
		else:
			# Move toward ball_pos
			ball_pos.y = 0
			#assignment_pos = ball_pos - distance_away * (ball_pos - position).normalized()
			# Stay to left or right, not in front. Messes with cutoff and looks bad.
			var move_vec
			if position.cross(ball_pos).y > 0:
				# Assign right
				move_vec = ball_pos.normalized().rotated(Vector3(0,1,0), -PI/2.)
				assignment_pos = ball_pos + distance_away * move_vec
			else:
				# Assign left
				move_vec = ball_pos.normalized().rotated(Vector3(0,1,0), PI/2.)
				assignment_pos = ball_pos + distance_away * move_vec
			#printt('in fielder assigning to 6:', posname, position,
			#	assignment_pos, Time.get_ticks_msec()/1e3, ball_pos, move_vec)
			assignment_pos.y = 0
	else:
		assert(false)

func begin_chase():
	pass

func _ready():
	start_position = position
	
	$Char3D.connect("animation_finished_signal", _on_animation_finished_from_char3d)

signal ball_fielded
signal tagged_runner
signal new_fielder_selected_signal
signal fielder_moved_reassign_fielders_signal
signal fielder_dropped_catch_reassign_fielders_signal
signal alt_fielder_selected_signal
@onready var wallnodes = get_tree().get_nodes_in_group("walls")

func _physics_process(delta: float) -> void:
	#if is_selected_fielder:
	#printt('selected fielder', posname, assignment)
	#if randf_range(0,1)<1.1 and posname == '2B':
		#printt('in fielder process:', posname, user_is_pitching_team, state,
			#assignment, animation, is_selected_fielder, is_targeted_fielder,
			#Time.get_ticks_msec()/1000.)
	if is_frozen:
		return
	#if posname == 'SS':
		#printt('SS fielder', state, assignment, animation, assignment_pos,
			#position, Time.get_ticks_msec())
	
	prev_position = position
	prev_global_position = global_position
	time_in_state += delta
	
	if turn_off_bad_throw_label_timer > 0:
		turn_off_bad_throw_label_timer -= delta
		if turn_off_bad_throw_label_timer <= 0:
			$BadThrowLabel3D.visible = false
			turn_off_bad_throw_label_timer = 0
	
	if turn_off_bad_catch_label_timer > 0:
		turn_off_bad_catch_label_timer -= delta
		if turn_off_bad_catch_label_timer <= 0:
			$BadThrowLabel3D.visible = false
			turn_off_bad_catch_label_timer = 0
			if not user_is_pitching_team or !user_fields:
				if len(get_tree().get_nodes_in_group('fielder_holding_ball')) < 0.5:
					fielder_dropped_catch_reassign_fielders_signal.emit(self)
	
	if assignment==null:
		return
	
	if assignment == 'over_wall':
		return

	if state == 'throwing':
		# If not released, check for cancel throw
		if holding_ball:
			if Input.is_action_just_pressed("cancel_throw"):
				# Cancel throw
				cancel_throw()
		# Exit state if there's a bug
		if time_in_state > 5000:
			set_state('free')
			push_error('error in fielder, was in throwing state too long', posname)
		# Exit state happens when animation ends, not here
		return

	if state == 'catching':
		#printt('in fielder state is catching', time_in_state)
		check_stepping_on_base()
		check_tagging_runner()
		# Need to update ball's position every frame for camera
		ball.global_position = $Char3D.get_hand_global_position(throws)
		# Check for throw loading
		check_user_throw_input()
		# Exit state if there's a bug
		if time_in_state > 5000:
			set_state('free')
			push_error('error in fielder, was in catching state too long', posname)
		# Remain in catching state until anim finishes
		return
	
	if state == 'precatch':
		# Check for throw loading
		check_user_throw_input()
		# Exit state if there's a bug
		if time_in_state > 5000:
			set_state('free')
			push_error('error in fielder, was in precatch state too long', posname)
		# Switch to catch if is catchable, even if didn't catch it
		if check_for_catch()[0]:
			set_state('catching')
		return

	assert(state == 'free')
	
	# Check if targeted fielder should change to precatch state
	if is_targeted_fielder and target_fielder_info['time_until_catch'] != null:
		#printt('in fielder targeted time until catch is',
			#target_fielder_info['time_until_catch'], state)
		target_fielder_info['time_until_catch'] = \
			target_fielder_info['time_until_catch'] - delta
		if target_fielder_info['time_until_catch'] <= .20:
			# Catch will start soon, so start precatch now for animation
			# Start precatch
			set_state('precatch')
			set_animation('catch')
			# Don't let it repeat this
			target_fielder_info['time_until_catch'] = null
			return
	
	var moved_this_process = false
	
	# Check if user changed to alt fielder (only check from current selected fielder)
	if user_is_pitching_team and Input.is_action_just_pressed("alt_fielder") \
		and user_fields \
		and is_selected_fielder:
		var alt_fielders = get_tree().get_nodes_in_group("alt_fielder")
		if (len(alt_fielders) > 0.5 and
			Time.get_ticks_msec() - alt_fielders[0].time_set_alt_fielder > 1./10 * 1000):
			set_not_selected_fielder()
			set_animation('idle')
			alt_fielders[0].set_selected_fielder()
			alt_fielders[0].set_assignment("ball")
			alt_fielder_selected_signal.emit(alt_fielders[0], self)
			return
	
	# Move fielder to their assignment
	if (((assignment in ["cover", "ball_click", "ball_carry"]) or
		(assignment == 'ball' and (not user_is_pitching_team or !user_fields))) and 
		assignment_pos != null and 
		turn_off_bad_catch_label_timer <= 0):
		var distance_from_target = distance_xz(position, assignment_pos)
		var distance_can_move = delta * SPEED
		moved_this_process = true
		# Face target
		if distance_from_target > 2:
			set_look_at_position(assignment_pos)
		elif distance_xz(position, ball.position) > 2:
			set_look_at_position(ball.position)

		#printt('ball distance to fielder is', sqrt((position.x-assignment_pos.x)**2+(position.z-assignment_pos.z)**2))
		if distance_can_move < distance_from_target:
			# Can't reach it, move full distance. Don't move vertically
			var direction_unit_vec = (assignment_pos - position).normalized()
			position.x += delta * SPEED * direction_unit_vec.x
			position.z += delta * SPEED * direction_unit_vec.z
			set_animation("running")
		else:
			# Can reach it, go to that point and stop
			#printt('ball distance to fielder is', sqrt((position.x-assignment_pos.x)**2+(position.z-assignment_pos.z)**2))
			position = assignment_pos
			if assignment == "ball":
				set_assignment("wait_to_receive")
			elif assignment == "cover":
				set_assignment("wait_to_receive")
				set_animation("idle")
			elif assignment == "ball_carry":
				set_assignment('holding_ball')
			elif assignment == "ball_click":
				set_assignment('ball')
			else:
				printt("Bad assignment, didn't update", assignment)
			# They have reached assignment, so changed anim to idle
			set_animation("idle")
	
	# Check if they caught the ball
	if assignment in ["ball", "cover", "wait_to_receive", "ball_click"]:
		var check_catch_out = check_for_catch()
		if check_catch_out[0] and check_catch_out[1]:
			# Change of state, don't check for movement and other stuff
			return

	# Check if user moves
	if (user_is_pitching_team and
		(holding_ball or assignment in ["ball", "ball_click"]) and
		is_selected_fielder and
		turn_off_bad_catch_label_timer <= 0):
		# Check for movement
		var anymovement:bool = false
		var move:Vector3 = Vector3()
		var move_needs_cam_fix:bool = true
		if Input.is_action_pressed("moveleft"):
			move.x += 1
			anymovement = true
		if Input.is_action_pressed("moveright"):
			move.x -= 1
			anymovement = true
		if Input.is_action_pressed("moveup"):
			move.z += 1
			anymovement = true
		if Input.is_action_pressed("movedown"):
			move.z -= 1
			anymovement = true
		if Input.is_action_pressed("run_to_base"):
			var target_base:int = -1
			if Input.is_action_pressed("throwfirst"):
				target_base = 1
			if Input.is_action_pressed("throwsecond"):
				target_base = 2
			if Input.is_action_pressed("throwthird"):
				target_base = 3
			if Input.is_action_pressed("throwhome"):
				target_base = 4
			if target_base > 0:
				# Don't do it if already standing on location
				var run_diff:Vector3 = base_positions[target_base - 1] - position
				if run_diff.length() > 0.1:
					move_needs_cam_fix = false
					anymovement = true
					move = run_diff
		if anymovement:
			if move.length() > 0: # Could press opposite directions
				moved_this_process = true
				#move = move.normalized() * delta * SPEED
				# move is the move direction
				move = move.normalized()
				if move_needs_cam_fix:
					# Rotate move based on camera angle
					var cam = get_viewport().get_camera_3d()
					move = move.rotated(Vector3(0,1,0), cam.rotation.y - PI)
				# Update velocity with acceleration, but keep under max
				velocity += delta * MAX_ACCEL * move
				if velocity.length() > SPEED:
					velocity = velocity.normalized() * SPEED
				#$Char3D.look_at(position + 100*move.rotated(Vector3(0,1,0), 45.*PI/180), Vector3.UP, true)
				set_look_at_position(position + 1e2*move.normalized())
				set_animation("running")

			if assignment == 'ball_click':
				# If moving due to click then user does other movement, switch to that
				set_assignment('ball')
		else: # No movement but moved last step -> stop
			if velocity.length() > 1e-12:
				move = Vector3(-velocity.x, 0, -velocity.z)
				move = move.normalized()
				var dvel = delta * MAX_ACCEL * move
				if dvel.length() > velocity.length(): # Cancel to 0
					velocity = Vector3.ZERO
					set_animation("idle")
					set_look_at_position(ball.position)
				else:
					velocity += dvel
		#printt('cam fielder movement', cam.rotation)
		position += delta * velocity
		#var ball = get_tree().get_first_node_in_group("ball")
		#ball.position = position
	
	var click_used = false
	
	click_used = check_user_throw_input()
	
	# If holding, check if they throw it or step on base or move
	if holding_ball:
		# Update ball position
		ball.global_position = $Char3D.get_hand_global_position(throws)
	check_stepping_on_base()
	check_tagging_runner()
	
		
	if holding_ball:
		# Throw is ready
		if user_is_pitching_team and throw_ready:
			# Only if throw was completed recently
			if Time.get_ticks_msec() - throw_ready_time < 1000*2:
				#printt('THROW IS READY')
				# Execute throw
				#throw_ball_func(start_throw_base, start_throw_fielder, throw_ready_success)
				start_throw_ball_animation(start_throw_base, start_throw_fielder,
					throw_ready_success, throw_ready_intensity)
				# Clear vars
				start_throw_base = null
				start_throw_fielder = null
				throw_ready = false
				throw_ready_success = true
				throw_ready_intensity = 1
			else: # Timed out, clear the throw info
				throw_ready = false
		
		# If user ran a distance with the ball, reassign fielders to maybe cover
		#  base they vacated
		if (position_holding_ball_reassigned_fielders!= null and 
			distance_xz(position, position_holding_ball_reassigned_fielders) > 4):
			fielder_moved_reassign_fielders_signal.emit(self)
			# Not a good variable name if updating like this
			position_holding_ball_reassigned_fielders = position
		
		# CPU defense
		if not user_is_pitching_team or not user_fields:
			if assignment != "ball_carry" or assignment == "ball_carry":
				# Adding this for ball_carry so that they rethink regularly
				#   Avoids issue of fielder running long distance when they shouldn't
				# Make sure that some frames passed while holding
				if (Time.get_ticks_msec() - time_last_began_holding_ball > 1000.*0.10
					and Time.get_ticks_msec() - time_last_decide_what_to_do_with_ball > 1000.*0.20):
					# Decide what to do with ball
					var decision_out = decide_what_to_do_with_ball()
					printt('  decide_what_to_do_with_ball result:', posname, decision_out)
					if decision_out[0] == null:
						# No decision, keep holding
						remove_from_group("fielder_running_with_ball_to_base")
						running_with_ball_to_base = null
						# Prevent them from running aimlessly
						assignment_pos = null
						set_animation('idle')
					else: # Throw or run ball
						var throw_to = decision_out[0]
						var run_it = decision_out[1]
						
						if run_it:
							# Run somewhere
							assignment_pos = base_positions[throw_to-1]
							set_assignment("ball_carry")
							add_to_group("fielder_running_with_ball_to_base")
							running_with_ball_to_base = throw_to
							#printt('fielder running to base', throw_to, posname)
						elif !user_is_pitching_team or !user_throws:
							# Throw somewhere
							remove_from_group("fielder_running_with_ball_to_base")
							running_with_ball_to_base = null
							if throw_to > 4.5:
								# Throw to a fielder
								start_throw_ball_animation(null, decision_out[2])
							elif throw_to > -0.5:
								# Throw to a base
								printt("in field: ball will be thrown to", throw_to)
								#throw_ball_func(throw_to)
								start_throw_ball_animation(throw_to)
							else:
								pass #printt('deciding not to throw', posname)
	else: # Not holding ball
		# If user ran a distance while chasing the ball, reassign fielders to
		# maybe cover base they vacated.
		if (assignment == "ball" and
			position_assignment_ball_reassigned_fielders != null and 
			distance_xz(position, position_assignment_ball_reassigned_fielders) > 4):
			fielder_moved_reassign_fielders_signal.emit(self)
			position_assignment_ball_reassigned_fielders = position
	
	# Check for click to move selected player or change selected player
	if user_is_pitching_team and user_fields and not click_used and \
		Input.is_action_just_pressed("click") and is_selected_fielder:
		#printt('unused click')
		var click_y0_pos = get_parent().get_parent().get_parent().get_mouse_y0_pos()
		# Find nearest fielder (besides selected fielder), maybe change to them
		var min_i = null
		var min_dist = 1e8
		for i in range(len(fielders)):
			if fielders[i].posname != posname:
				var i_dist = distance_xz(click_y0_pos, fielders[i].position)
				if i_dist < min_dist:
					min_dist = i_dist
					min_i = i
		if min_dist < 2:
			# Change to that player
			set_not_selected_fielder()
			fielders[min_i].set_selected_fielder()
			fielders[min_i].set_not_alt_fielder()
			fielders[min_i].set_assignment("ball")
			set_assignment("wait_to_receive")
			new_fielder_selected_signal.emit(fielders[min_i])
			printt('fielder i assignment new assignment is', fielders[min_i].assignment, fielders[min_i].posname)
		else:
			# Run to that position
			set_assignment("ball_click")
			assignment_pos = click_y0_pos
		click_used = true
	
	if (assignment == 'wait_to_receive' or
		(assignment == 'ball' and not moved_this_process and false)):
		if distance_xz(position, ball.position) > 2:
			#$Char3D.look_at(ball.global_position * Vector3(1,0,1), Vector3.UP, true)
			set_look_at_position(ball.position)
	
	# Check if moved past a wall, move back within field
	if (position - prev_position).length() > 1e-14:
		# If fielder is on wrong side of wall, put them back in field
		for wallnode in wallnodes:
			var cfcs = wallnode.check_fielder_correct_side(global_position, prev_global_position, 1)
			if !cfcs[0]:
				global_position = cfcs[1]
	
	# If selected fielder is offscreen, have arrow point where they are
	update_offscreen_arrow()

var stepping_on_base_with_ball = false

func distance_xz(a:Vector3, b:Vector3) -> float:
	return sqrt((a.x - b.x)**2 +
				(a.z - b.z)**2)

var base_positions = [
	Vector3(-1,0,1)*30/sqrt(2), # 1
	Vector3(0,0,1)*30*sqrt(2), # 2
	Vector3(1,0,1)*30/sqrt(2), # 3
	Vector3(0,0,0) # Home
]
func is_stepping_on_base() -> Array:
	#printt('is_stepping_on_base', posname, bases[0], position)
	for i in range(4):
		if distance_xz(position, base_positions[i]) < 1:
			return [true, i + 1]
	return [false]

signal stepped_on_base_with_ball

var start_throw_started = false
var start_throw_base = null
var start_throw_fielder = null
var start_throw_key_check_release = null
func start_throw_ball_func(base, fielder, key_check_release):
	# If already throw stored, clear it
	if throw_ready:
		throw_ready = false
	
	# Setup
	start_throw_started = true
	start_throw_base = base
	start_throw_fielder = fielder
	start_throw_key_check_release = key_check_release
	
	# If throw_mode=="Button", immediately start throw
	if throw_mode == "Button":
		start_throw_end()
		return
	elif throw_mode == "Bar":
		# Turn on throw bar
		$ThrowBar.visible = true
		var cam = get_viewport().get_camera_3d()
		$ThrowBar.position = cam.unproject_position(global_position)
		$ThrowBar.reset(50, .5)
	elif throw_mode == "BarOneWay":
		# Turn on throw bar
		$ThrowBarOneWay.visible = true
		var cam = get_viewport().get_camera_3d()
		$ThrowBarOneWay.position = cam.unproject_position(global_position)
		var gradient_width = 80 - 70 * (player.throwaccuracy / 100)
		#printt('in fielder about to throw, throwacc and gradient_width',
			#player.throwaccuracy, gradient_width)
		$ThrowBarOneWay.reset(gradient_width, .5)
	else:
		printt('in fielder: invalid throw_mode', throw_mode)
		assert(false)

func cancel_throw():
	if state == 'throwing' and holding_ball:
		$Timer.stop()
		timer_action = null
		timer_args = null
		set_animation("idle")
		set_state('free')
	elif state == 'free':
		start_throw_started = false
		start_throw_base = null
		start_throw_fielder = null
		start_throw_key_check_release = null
		$ThrowBar.visible = false
		$ThrowBarOneWay.visible = false
	else:
		push_error("error in fielder cancel_throw")

var throw_ready:bool = false
var throw_ready_success:bool = true
var throw_ready_intensity:float = 1
var throw_ready_time = null
func start_throw_end():
	# This ends getting the throw ready. The throw info will be stored
	#  for up to 2 seconds to begin throw later if fielder doesn't have ball.
	
	if throw_mode == "Button":
		throw_ready_success = randf() < .9
		throw_ready_intensity = 1
	elif throw_mode == "Bar":
		# Check throw bar
		throw_ready_success = $ThrowBar.check_success(true, true)
		throw_ready_intensity = 1
	elif throw_mode == "BarOneWay":
		# Check throw bar
		var barout = $ThrowBarOneWay.check_success(true, true)
		throw_ready_success = randf() >= barout[1]
		# Put intensity between .7 and 1.
		throw_ready_intensity = barout[0]/100. * 0.3 + 0.7
	else:
		push_error("Fielder throw error 3819249")
	
	## Actually start throw
	#throw_ball_func(start_throw_base, start_throw_fielder, success)
	throw_ready = true
	throw_ready_time = Time.get_ticks_msec()
	
	# End start throw
	start_throw_started = false
	#start_throw_base = null
	#start_throw_fielder = null
	start_throw_key_check_release = null

signal throw_ball
func throw_ball_func(base, fielder=null, success:bool=true,
					intensity:float=1) -> void:
	# This begins the release of the throw.
	printt('in fielder throw_ball_func', base, fielder)
	
	# Only throw if not close to that base
	var do_throw:bool = false
	if base != null:
		if base == 5:
			# Cutoff
			# Why is this pass, does this ever happen?
			assert(false,
				'in fielder throw_ball_funcshould not throw to base 5, delete this?')
		elif distance_xz(position, base_positions[base-1]) > 3:
			do_throw = true
	elif fielder != null: # Throw to a fielder
		if distance_xz(position, fielder.position) > 3:
			do_throw = true
			
	if do_throw:
		set_holding_ball(false)
		# Set ball release point
		ball.global_position = $Char3D.get_hand_global_position(throws)
		ball.throw_start_pos = null
		ball.throw_target = null
		# This needs to be before throw_ball.emit() since that can reassign this fielder
		set_assignment('wait_to_receive')
		throw_ball.emit(base, self, fielder, success, intensity)
		if user_is_pitching_team:
			set_not_selected_fielder()
	
	# Remove cutoff status from any fielder
	var cutoff_fielders = get_tree().get_nodes_in_group("cutoff_fielder")
	for cutoff_fielder in cutoff_fielders:
		cutoff_fielder.set_not_cutoff_fielder()

# Begin throw animation, ball to be released when animation is ready
func start_throw_ball_animation(base, fielder=null, success:bool=true,
								intensity:float=1) -> void:
	printt('In fielder start_throw_ball_animation', posname, state, Time.get_ticks_msec(),
		base, fielder, success, intensity)
	# Don't overwrite throw already in progress
	if timer_action == 'throw' and timer_args != null:
		printt("In fielder, not overwriting throw", posname, timer_args, base, fielder)
		return
	
	# Determine if throw is throw or toss based on distance
	var throw_type:String = 'throw'
	if fielder != null:
		if distance_xz(position, fielder.position) < 8:
			throw_type = 'toss'
	else:
		assert(base >= 1)
		assert(base <= 4)
		if distance_xz(position, base_positions[base-1]) < 8:
			throw_type = 'toss'
	
	# Throw is starting for real
	if !throw_ready_success:
		$BadThrowLabel3D.visible = true
		turn_off_bad_throw_label_timer = 2
	
	# Turn to face target
	if fielder != null:
		set_look_at_position(fielder.position)
	else:
		set_look_at_position(base_positions[base-1])
	set_state('throwing')
	$Timer.stop()
	if throw_type == 'throw':
		set_animation('throw')
		$Timer.wait_time = time_throw_animation_release_point # Time for animation to reach release point
	elif throw_type == 'toss':
		set_animation('toss')
		$Timer.wait_time = time_toss_animation_release_point # Time for animation to reach release point
	else:
		assert(false)
	$Timer.start()
	timer_action = 'throw'
	timer_args = [base, fielder, success, intensity]

func _on_timer_timeout() -> void:
	$Timer.stop()
	if timer_action == "set_visible_true":
		visible = true
	elif timer_action == "throw":
		throw_ball_func(timer_args[0], timer_args[1], timer_args[2],
						timer_args[3])
	else:
		push_error("Bad timer_action in fielder", posname, timer_action)
	timer_action = null
	timer_args = null

var is_selected_fielder:bool = false
var is_targeted_fielder:bool = false # Throw is coming at them, so can start throw but not move
func set_selected_fielder() -> void:
	printt('in fielder, set_selected_fielder', posname)
	# Unselect all other players
	var selected_fielders = get_tree().get_nodes_in_group("selected_fielder")
	for fielder in selected_fielders:
		fielder.set_not_selected_fielder()
	# Untarget all other players
	var targeted_fielders = get_tree().get_nodes_in_group("targeted_fielder")
	for fielder in targeted_fielders:
		fielder.set_not_targeted_fielder()
	# Remove as cutoff fielder
	set_not_cutoff_fielder()
	# Remove as alt fielder
	set_not_alt_fielder()
	# Select this player
	add_to_group("selected_fielder")
	is_selected_fielder = true
	if holding_ball:
		#$Annulus.set_color("red")
		$Annulus.visible = true
	else:
		$Annulus2.visible = true

func set_targeted_fielder(time_until_catch) -> void:
	printt('in fielder, set_targeted_fielder', posname)
	# Store info
	target_fielder_info = {'time_until_catch':time_until_catch}
	# Unselect all other players
	var selected_fielders = get_tree().get_nodes_in_group("selected_fielder")
	for fielder in selected_fielders:
		fielder.set_not_selected_fielder()
	# Untarget all other players
	var targeted_fielders = get_tree().get_nodes_in_group("targeted_fielder")
	for fielder in targeted_fielders:
		fielder.set_not_targeted_fielder()
	# Target this player
	add_to_group("targeted_fielder")
	is_targeted_fielder = true
	# Not putting annulus on targeted players
	#$Annulus.visible = true

func set_not_selected_fielder():
	remove_from_group("selected_fielder")
	is_selected_fielder = false
	$Annulus.visible = false
	$Annulus2.visible = false

func set_not_targeted_fielder():
	remove_from_group("targeted_fielder")
	is_targeted_fielder = false
	#get_node("Annulus").visible = false

func set_cutoff_fielder():
	# Unset all other players as cutoff
	var cutoff_fielders = get_tree().get_nodes_in_group("cutoff_fielder")
	for fielder in cutoff_fielders:
		fielder.set_not_cutoff_fielder()

	add_to_group("cutoff_fielder")
	if user_is_pitching_team and user_fields:
		if $AltFielderLabel3D.visible:
			$AltFielderAndCutLabel3D.visible = true
			$AltFielderLabel3D.visible = false
		else:
			$CutoffLabel3D.visible = true

func set_not_cutoff_fielder():
	remove_from_group("cutoff_fielder")
	if user_is_pitching_team and user_fields:
		if $AltFielderAndCutLabel3D.visible:
			$AltFielderAndCutLabel3D.visible = false
			$AltFielderLabel3D.visible = true
		else:
			$CutoffLabel3D.visible = false

var time_set_alt_fielder #= Time.get_ticks_msec() - 1000
func set_alt_fielder():
	var alt_fielders = get_tree().get_nodes_in_group("alt_fielder")
	for alt_fielder in alt_fielders:
		alt_fielder.set_not_alt_fielder()
	
	time_set_alt_fielder = Time.get_ticks_msec()
	add_to_group("alt_fielder")
	if user_is_pitching_team and user_fields:
		if $CutoffLabel3D.visible:
			$AltFielderAndCutLabel3D.visible = true
			$CutoffLabel3D.visible = false
		else:
			$AltFielderLabel3D.visible = true

func set_not_alt_fielder():
	remove_from_group("alt_fielder")
	#time_set_alt_fielder = Time.get_ticks_msec() - 1000
	if $AltFielderAndCutLabel3D.visible:
		$AltFielderAndCutLabel3D.visible = false
		$CutoffLabel3D.visible = true
	else:
		$AltFielderLabel3D.visible = false

func time_to_reach_point(to:Vector3):
	# Simulate how long it will take to get to a point. 
	#var time_to_full_speed
	var pos = position
	to.y = 0
	pos.y = 0
	var vel = velocity
	vel.y = 0
	var delta = 1./60
	var time = 0.
	var iii=0
	while true:
		iii += 1
		if iii > 995:
			printt('prob error in time_to_reach_point', posname, pos, to, (to-pos).length())
		if iii > 1e3:
			printt('error in time_to_reach_point', posname, pos, to, (to-pos).length())
			return time
		# Check if close enough to reach point
		if (to - pos).length() < 1e-4:
			return time
		
		# Update position
		var move = (to - pos)
		move = move.normalized()
		vel += delta * MAX_ACCEL * move
		if vel.length() > SPEED:
			vel = vel.normalized() * SPEED
		#printt('cam fielder movement', cam.rotation)
		pos += delta * vel
		time += delta

func set_animation(new_anim):
	if posname == '2B':
		printt('in fielder setting animation', new_anim, state)
	if new_anim == animation:
		return
	animation = new_anim
	$Char3D.start_animation(new_anim, false, throws=='R')

func force_animation_idle() -> void:
	animation = 'idle'
	$Char3D.force_animation_idle()

func set_animation_if_free(new_anim:String) -> void:
	# Used to avoid overwriting throw/catch animations
	if state == 'free':
		set_animation(new_anim)

func queue_animation(new_anim):
	$Char3D.queue_animation(new_anim, false, throws=='R')

func set_state(state_:String):
	assert(state_ in possible_states)
	#if state_ == 'catching':
		#printt('in fielder set state catching', posname)
	state = state_
	time_in_state = 0

func set_assignment(assignment_):
	assert(assignment_ in ['cover', 'ball', 'ball_click', 'ball_carry',
							'wait_to_receive', 'holding_ball', 'over_wall'])
	
	if assignment == assignment_:
		return
	
	# Exit assignment changes
	if assignment == "ball":
		position_assignment_ball_reassigned_fielders = null
	
	# New assignment changes
	if assignment_ == "ball":
		position_assignment_ball_reassigned_fielders = position
	
	# Set new assignment
	assignment = assignment_
	

func set_look_at_position(pos) -> void:
	# Can't look at current position, gives error
	if distance_xz(pos, position) < 1:
		return
	# Always stay vertical
	pos.y = 0
	# Rotate to global frame
	pos = pos.rotated(Vector3(0,1,0), 45.*PI/180)
	# Look at global position
	$Char3D.look_at(pos, Vector3.UP, true)

func set_holding_ball(hb:bool) -> void:
	# This is for the bool of holding ball, not the state.
	# State can be "holding_ball" or "ball_carry".
	holding_ball = hb
	if hb:
		add_to_group('fielder_holding_ball')
		position_holding_ball_reassigned_fielders = position
		time_last_began_holding_ball = Time.get_ticks_msec()
		$Annulus.visible = true
		$Annulus2.visible = false
		set_not_cutoff_fielder()
		# No need for alt fielders, including this one
		for alt_fielder in get_tree().get_nodes_in_group("alt_fielder"):
			alt_fielder.set_not_alt_fielder()
	else:
		remove_from_group('fielder_holding_ball')
		position_holding_ball_reassigned_fielders = null
		time_last_began_holding_ball = null
		if !user_is_pitching_team:
			# Why do I need this here?
			$Annulus.visible = false

func setup_player(player_, team, is_home_team:bool) -> void:
	player = player_
	throws = player.throws
	SPEED = player.speed_yps()
	max_throw_speed = player.throwspeed_yps()
	catch_max_y = player.height_mult * 2.5
	$Char3D.set_color_from_team(player, team, is_home_team)
	$Char3D.set_glove_visible(throws)

var time_last_decide_what_to_do_with_ball = Time.get_ticks_msec() - 30*1e3
func decide_what_to_do_with_ball() -> Array:
	time_last_decide_what_to_do_with_ball = Time.get_ticks_msec()
	printt('Starting decide_what_to_do_with_ball in fielder', posname,
		time_last_decide_what_to_do_with_ball)
	# When CPU fielder has ball, decide where to throw/run it to
	# Return [base to throw to, run_it, fielder to throw to]
	
	# Runners that are active, first one should be furthest ahead
	var runners_ = runners.filter(func(r): return r.is_active())
	runners_.sort_custom(func(r1, r2): return r1.start_base > r2.start_base)
	# If no runners, return no instructions
	if len(runners_) < 0.5:
		return [null]
	
	# Check which bases are covered for throws
	var base_covered:Array = [false, false, false, false] # 1B, 2B, 3B, Home
	var base_will_be_covered:Array = [false, false, false, false]
	#var base_covered_by:Array = [null, null, null, null]
	var base_will_be_covered_by:Array = [null, null, null, null]
	for base in range(1,5):
		for fielder in fielders:
			if fielder.posname != posname: # Can't be this fielder
				# Check if they are covering
				if distance_xz(fielder.position, base_positions[base - 1]) < 1:
					base_covered[base-1] = true
					base_will_be_covered[base-1] = true
					base_will_be_covered_by[base-1] = fielder
					break
				# Check if they would be covering before throw could arrive
				if (fielder.assignment == 'cover' and
					distance_xz(fielder.assignment_pos, base_positions[base - 1]) < 1 and
					distance_xz(fielder.position, base_positions[base - 1]) / fielder.SPEED < 
						distance_xz(fielder.position, base_positions[base - 1]
							) / max_throw_speed + time_throw_animation_release_point):
					base_will_be_covered[base-1] = true
					base_will_be_covered_by[base-1] = fielder
	#printt('\tin fielder decide_what_to_do_with_ball: runners_ and base_covered',
		#runners_, base_covered, base_will_be_covered, base_will_be_covered_by)
	
	# Calculate time to throw in front+behind, to run in front+behind
	var time_throw_front = []
	var time_throw_behind = []
	var time_throw_start = []
	var time_run_behind = []
	var time_run_front = []
	var time_run_start = []
	var time_runner_run_forward = []
	var time_runner_run_back = []

	var base_front = []
	var base_behind = []
	var base_front_pos = []
	var base_behind_pos = []
	var base_start_pos = []
	for i in range(len(runners_)):
		var runner = runners_[i]
		base_front.push_back(min(floor(runner.running_progress) + 1, 4))
		base_behind.push_back(floor(runner.running_progress))
		base_front_pos.push_back(base_positions[base_front[i] - 1])
		base_behind_pos.push_back(base_positions[base_behind[i] - 1])
		base_start_pos.push_back(base_positions[runner.start_base - 1])
		
		time_throw_front.push_back(distance_xz(position, base_front_pos[i]) / max_throw_speed + time_throw_animation_release_point)
		time_throw_behind.push_back(distance_xz(position, base_behind_pos[i]) / max_throw_speed + time_throw_animation_release_point)
		time_throw_start.push_back(distance_xz(position, base_start_pos[i]) / max_throw_speed + time_throw_animation_release_point)
		
		time_run_front.push_back(distance_xz(position, base_front_pos[i]) / SPEED)
		time_run_behind.push_back(distance_xz(position, base_behind_pos[i]) / SPEED)
		time_run_start.push_back(distance_xz(position, base_start_pos[i]) / SPEED)
		
		time_runner_run_forward.push_back(abs(base_front[i] - runner.running_progress) * 30 / runner.SPEED)
		time_runner_run_back.push_back(abs(base_behind[i] - runner.running_progress) * 30 / runner.SPEED)

	# Check if there's a fielder covering each base
	
	# 1. If runner needs to tag up:
	#  a. If throw can get them, throw behind.
	#  b. If can beat them to base, run behind.
	for i in range(len(runners_)):
		if runners_[i].needs_to_tag_up and not runners_[i].tagged_up_after_catch:
			#if (time_throw_start[i] < time_runner_run_back[i] and
				#base_will_be_covered[runners_[i].start_base - 1]):
				#return [runners_[i].start_base, false]
			#if time_run_start[i] < time_runner_run_back[i]:
				#return [runners_[i].start_base, true]
			var throw_beat = time_runner_run_back[i] - time_throw_start[i]
			var run_beat = time_runner_run_back[i] - time_run_start[i]
			if (throw_beat > 0 and
				throw_beat > run_beat and
				base_will_be_covered[runners_[i].start_base - 1]):
				return [runners_[i].start_base, false]
			if run_beat > 0:
				var cover_fielder = base_will_be_covered_by[runners_[i].start_base - 1]
				divert_cover_fielder(cover_fielder)
				return [runners_[i].start_base, true]
	
	# 2. If runner can be force out:
	#  a. If throw can get them, throw ahead.
	#  b. If can beat them to base, run ahead.
	for i in range(len(runners_)):
		if runners_[i].can_be_force_out():
			#if (time_throw_front[i] < time_runner_run_forward[i] and
				#base_will_be_covered[base_front[i] - 1]):
				#return [base_front[i], false]
			#if time_run_front[i] < time_runner_run_forward[i]:
				#return [base_front[i], true]
			var throw_beat = time_runner_run_forward[i] - time_throw_front[i]
			var run_beat = time_runner_run_forward[i] - time_run_front[i]
			#printt('in fielder decide checking force out', throw_beat, run_beat,
				#time_runner_run_forward[i], time_throw_front[i], time_run_front[i])
			if (throw_beat > 0 and
				throw_beat > run_beat and
				base_will_be_covered[base_front[i] - 1]):
				return [base_front[i], false]
			if run_beat > 0:
				# Move fielder assigned to cover away from base
				var cover_fielder = base_will_be_covered_by[base_front[i] - 1]
				divert_cover_fielder(cover_fielder)
				return [base_front[i], true]
	
	# 3. If runner is between bases and no force out:
	#  a. If ahead of them in baseline, run them back
	#  b. If throw can beat them to next base, throw ahead.
	#  c. If can beat them to next base, run ahead.
	for i in range(len(runners_)):
		# Only do something if they are off base
		if abs(runners_[i].running_progress - round(runners_[i].running_progress)) > .02:
			# If ahead of them in path to next base, run them back
			if distance_to_line(position, base_behind_pos[i], base_front_pos[i]) < 0.5:
				var fielder_progress = progress_on_line(position,
					base_behind_pos[i], base_front_pos[i])
				if (fielder_progress <= 1.02 and
					fielder_progress > runners_[i].running_progress -
						(runners_[i].running_progress)):
					return [base_behind[i], true]
			# Throw/run in front of them if can beat them
			#if (time_throw_front[i] < time_runner_run_forward[i] and
				#base_will_be_covered[base_front[i] - 1]):
				#return [base_front[i], false]
			#if time_run_front[i] < time_runner_run_forward[i]:
				#return [base_front[i], true]
			var throw_beat = time_runner_run_forward[i] - time_throw_front[i]
			var run_beat = time_runner_run_forward[i] - time_run_front[i]
			if (throw_beat > 0 and
				throw_beat > run_beat and
				base_will_be_covered[base_front[i] - 1]):
				return [base_front[i], false]
			if run_beat > 0:
				return [base_front[i], true]
	
	# Can't beat them to base, not in front of them in baseline
	# X. If in outfield, throw it in front of lead runner
	if abs(position.x) + abs(position.z - 20) > 25:
		for i in range(len(runners_)):
			# Throw in front of them if can beat them
			if (time_throw_front[i] < time_runner_run_forward[i] and
				base_will_be_covered[base_front[i] - 1]):
				return [base_front[i], false]
			
			# Otherwise throw to next next base, using cutoff if far
			if base_front[i] < 3.5 and base_will_be_covered[base_front[i]+1-1]:
				# Throw at next next base
				if distance_xz(position, base_positions[base_front[i]+1-1]) > 50:
					var cutoff_fielders = get_tree().get_nodes_in_group("cutoff_fielder")
					if len(cutoff_fielders) > 0.5:
						return [5, false, cutoff_fielders[0]]
				return [base_front[i] + 1, false]
			# Otherwise throw to current base if covered
			if base_will_be_covered[base_front[i]-1]:
				if distance_xz(position, base_front_pos[i]) > 50:
					var cutoff_fielders = get_tree().get_nodes_in_group("cutoff_fielder")
					if len(cutoff_fielders) > 0.5:
						return [5, false, cutoff_fielders[0]]
				return [base_front[i], false]
			# Otherwise run to base in front
			if distance_xz(position, base_front_pos[i]) < 20:
				return [base_front[i], true]
		# No runner (or no one covering base), so throw/run toward nearest base
		var nearest_base
		var nearest_base_dist = 1e12
		for i in range(1,4):
			if distance_xz(position, base_positions[i-1]) < nearest_base_dist:
				nearest_base_dist = distance_xz(position, base_positions[i-1])
				nearest_base = i
		
		# If far away, throw to cutoff
		if distance_xz(position, base_positions[nearest_base-1]) > 40:
			var cutoff_fielders = get_tree().get_nodes_in_group("cutoff_fielder")
			if len(cutoff_fielders) > 0.5:
				return [5, false, cutoff_fielders[0]]
		if base_covered[nearest_base - 1]:
			return [nearest_base, false]
		else:
			return [nearest_base, true]
	
	# No decision made, happens when no runner running and fielder with ball
	#   in infield
	#printt('in fielder, pos from center returning no action', posname)
	return [null, null, null]

func divert_cover_fielder(cover_fielder) -> void:
	# Move fielder assigned to cover away from base to avoid player overlap
	# The assignment will have assignment changed again when reassigning defense
	if cover_fielder != null:
		cover_fielder.set_assignment('cover')
		cover_fielder.assignment_pos = cover_fielder.position + Vector3(4,0,-4)

func distance_to_line(p:Vector3, l1:Vector3, l2:Vector3) -> float:
	# Ignore height dim
	p.y = 0
	l1.y = 0
	l2.y = 0
	
	# Recenter
	var q = p - l1
	var l = l2 - l1
	
	var q_proj_on_l = q.dot(l) / l.dot(l) * l
	var q_perp_l = q - q_proj_on_l
	
	return q_perp_l.length()

func progress_on_line(p:Vector3, l1:Vector3, l2:Vector3) -> float:
	# Ignore height dim
	p.y = 0
	l1.y = 0
	l2.y = 0
	
	# Recenter
	var q = p - l1
	var l = l2 - l1
	
	var q_proj_on_l = q.dot(l) / l.dot(l) * l
	
	return q_proj_on_l.length() / l.length()

func ball_over_wall() -> void:
	if not user_is_pitching_team or not user_fields:
		# Set assignment to have them stand
		set_assignment('over_wall')
		# Set animation to sad
		set_animation('idle')

func update_offscreen_arrow() -> void:
	# If selected fielder is offscreen, have arrow point where they are
	if $Arrow2DOffscreenDirection.visible:
		$Arrow2DOffscreenDirection.visible = false
	if is_selected_fielder and not holding_ball:
		# Find their location
		var pos2d:Vector2 = get_viewport().get_camera_3d().unproject_position(global_position)
		var vpsize:Vector2 = get_viewport().size
		var vpcenter:Vector2 = vpsize / 2.
		# If off-screen, add arrow and put in right space with right rotation
		if pos2d.x < -50 or pos2d.y < -50 or \
			pos2d.x > vpsize.x + 50 or pos2d.y > vpsize.y + 50:
			# Make visible
			$Arrow2DOffscreenDirection.visible = true
			var dx = pos2d.x - vpsize.x / 2.
			var dy = pos2d.y - vpsize.y / 2.
			# Give correct rotation
			$Arrow2DOffscreenDirection.rotation = atan(dy / dx) + PI/2. + (0. if dx > 0 else PI)
			# Put in correct location
			var arrowpos:Vector2 = pos2d
			var marg:float = 50
			if arrowpos.x < marg:
				var shrink:float = abs(vpcenter.x - marg) / abs(vpcenter.x - arrowpos.x)
				arrowpos = vpcenter + shrink * (arrowpos - vpcenter)
			if arrowpos.y < marg:
				var shrink:float = abs(vpcenter.y - marg) / abs(vpcenter.y - arrowpos.y)
				arrowpos = vpcenter + shrink * (arrowpos - vpcenter)
			if arrowpos.x > vpsize.x - marg:
				var shrink:float = abs(vpcenter.x - marg) / abs(vpcenter.x - arrowpos.x)
				arrowpos = vpcenter + shrink * (arrowpos - vpcenter)
			if arrowpos.y > vpsize.y - marg:
				var shrink:float = abs(vpcenter.y - marg) / abs(vpcenter.y - arrowpos.y)
				arrowpos = vpcenter + shrink * (arrowpos - vpcenter)
			$Arrow2DOffscreenDirection.position = arrowpos
			# Change scale based on how far they are
			# For now using 2D distance, would be better to use 3D distance
			#get_viewport().get_camera_3d().project_position(arrowpos)
			var arrowscale:float = 5 - arrowpos.distance_to(pos2d) / 400
			arrowscale = max(2, min(5, arrowscale))
			$Arrow2DOffscreenDirection.scale = Vector2(1,1) * arrowscale

func _on_animation_finished_from_char3d(anim_name) -> void:
	#printt('in fielder anim finished', anim_name)
	if anim_name in ["throw", "toss"]:
		# End of throw: change state and anim.
		# Should already have assignment wait_to_receive or assigned to base
		set_state('free')
		set_animation('idle')
	elif anim_name in ["catch", 'catch_grounder', 'catch_chest', 'catch_jump',
		'catch_high']:
		# End of catch: change state and anim.
		# Should already have assignment holding_ball if they caught it
		# If they didn't catch, they should have assignment too?
		set_state('free')
		set_animation('idle')
	elif anim_name == 'pitch':
		# State is already free, assignment should be fine too
		set_animation('idle')

func check_stepping_on_base() -> void:
	if not holding_ball:
		stepping_on_base_with_ball = false
		return
	
	# Check if step on base
	var step_on_base = is_stepping_on_base()
	# Returns [false] if not, [true, base] if true
	
	if step_on_base[0]:
		# If wasn't stepping on base before
		if not stepping_on_base_with_ball:
			remove_from_group("fielder_running_with_ball_to_base")
			running_with_ball_to_base = null
			#print("STEPPING ON BASE!!!", posname, step_on_base)
			stepped_on_base_with_ball.emit(self, step_on_base[1])
			stepping_on_base_with_ball = true
		# If was stepping on base last frame, there can be no new outs
	else: # Not holding ball
		stepping_on_base_with_ball = false

func check_tagging_runner() -> void:
	if not holding_ball:
		return
	
	# Check if tagging active runner not on base
	for runner in runners:
		if (runner.is_active() and
			(abs(runner.running_progress - round(runner.running_progress)) > 1e-4 or
				(runner.needs_to_tag_up and not runner.tagged_up_after_catch and
					runner.running_progress - runner.start_base > .15)) and
			distance_xz(position, runner.position) < 1):
			#runner.runner_is_out()
			tagged_runner.emit(self, runner)

func check_user_throw_input() -> bool:
	# Returns whether the click of mouse was used
	var click_used:bool = false
	
	# Check if user is starting throw. Can be done before holding ball, but only by selected fielder
	if is_selected_fielder or is_targeted_fielder:
		# Check for throw
		if user_is_pitching_team and user_throws:
			# Check for throwing ball end, this will start throw
			if start_throw_started:
				if Input.is_action_just_pressed("cancel_throw"):
					cancel_throw()
				elif Input.is_action_just_released(start_throw_key_check_release):
					start_throw_end()
			
			# Check for throwing ball start
			if Input.is_action_pressed("run_to_base"):
				# Don't let the throw start
				pass
			elif Input.is_action_just_pressed("throwfirst"):
				#printt('throw to first')
				#throw_ball_func(1)
				start_throw_ball_func(1, null, "throwfirst")
			elif Input.is_action_just_pressed("throwsecond"):
				#throw_ball_func(2)
				start_throw_ball_func(2, null, "throwsecond")
			elif Input.is_action_just_pressed("throwthird"):
				#throw_ball_func(3)
				start_throw_ball_func(3, null, "throwthird")
			elif Input.is_action_just_pressed("throwhome"):
				#throw_ball_func(4)
				start_throw_ball_func(4, null, "throwhome")
			elif Input.is_action_just_pressed("throwcutoff"):
				var cutoff_fielders = get_tree().get_nodes_in_group("cutoff_fielder")
				if len(cutoff_fielders) > 0.5:
					start_throw_ball_func(null, cutoff_fielders[0], "throwcutoff")
				#for cutoff_fielder in cutoff_fielders:
					#cutoff_fielder.set_not_cutoff_fielder()
			
			# Check for click that throws ball
			if Input.is_action_just_pressed("click"):
				var mgl = get_parent().get_parent().get_node("MouseGroundLocation")
				#printt('in fielder, mgl pos is', mgl, mgl.position)
				# Throw to base
				for i in range(4):
					if distance_xz(mgl.position, base_positions[i]) < 2:
						# This func determines whether to run or throw to that position
						#throw_ball_func(i+1)
						start_throw_ball_func(i+1, null, "click")
						click_used = true
						break
					#else:
					#	printt('click not near base')
				# Throw to teammate
				if not click_used:
					for fielder in fielders:
						#printt('checking click throw to fielder', distance_xz(mgl.position, fielder.position))
						if fielder.posname != posname and distance_xz(mgl.position, fielder.position) < 2:
							#throw_ball_func(null, fielder)
							start_throw_ball_func(null, fielder, "click")
							click_used = true
							break
	return click_used

func reach_ball_info(ball_pos:Vector3) -> Array:
	# Returns array of length 1 or 2
	# If can't reach ball ever at that position, then [false]
	# If can reach ball ever, then [true, time_to_reach]
	if ball_pos.y < catch_max_y:
		var ballgrounddist = distance_xz(position, ball_pos)
		# TODO: fielders don't run at constant speed
		var timetoreach = max(0, (ballgrounddist - catch_radius_xz) / SPEED)
		# Add time if still in a catch animation
		if state == 'catching':
			timetoreach += $Char3D.time_left_in_current_anim() / 2.5
		return [true, timetoreach, ballgrounddist]
	else:
		return [false]

func reach_cover_info(base_position:Vector3) -> float:
	# Returns time it would take for fielder to cover pos
	var timetoreach = distance_xz(position,base_position) / SPEED
	if state == 'catching':
		timetoreach += $Char3D.time_left_in_current_anim() / 2.5
	return timetoreach

func time_for_throw_to_reach(from_pos:Vector3, to_pos:Vector3) -> float:
	# Air time
	var out = distance_xz(from_pos, to_pos) / max_throw_speed + \
		time_throw_animation_release_point
	# Release time
	if holding_ball and state == 'throwing':
		pass
	else:
		out += time_throw_animation_release_point
	return out

func time_to_run_to_pos(from_pos:Vector3, to_pos:Vector3) -> float:
	return distance_xz(from_pos, to_pos) / SPEED

func logit(x:float) -> float:
	# x is between 0 and 1
	x = max(1e-16, min(1 - 1e-16, x))
	# Output is -Inf to Inf (actually capped to avoid Inf)
	x = log(x / (1-x))
	return x

func invlogit(x:float) -> float:
	# x is between -Inf and Inf, but not actually Inf
	# Output is 0 to 1
	x = 1 / (1 + exp(-x))
	return x

func logit_adjust(x:float, y:float) -> float:
	# x is probability
	# y is how much to adjust it on the logit scale
	#   +/-0.5 moves 50% to 62.2% / 37.8%
	#   +/-  1 moves 50% to 73.1% / 26.9%
	#   +/-  2 moves 50% to 88.1% / 11.9%
	# Avoid NaN/Inf issues, 0 and 1 don't get adjusted
	if x <= 0:
		return 0
	if x >= 1:
		return 1
	return invlogit(logit(x) + y)


func check_for_catch() -> Array:
	# Returns array
	# If can't catch [false]
	# If dropped [true, false]
	# If caught ball [true,true]
	if !ball.can_be_caught():
		return [false]
	
	var distance_from_ball_xz = distance_xz(position, ball.position)
	#if posname == '2B':
		#printt('in fielder 2B checking catch', distance_from_ball_xz,
		#1)
	if !(distance_from_ball_xz < catch_radius_xz and ball.position.y < catch_max_y and 
		Time.get_ticks_msec() - ball.time_last_thrown > 250 and
		(ball.throw_start_pos==null or ball.throw_progress >= .9) and
		turn_off_bad_catch_label_timer <= 0):
		# Not within reach
		return [false]
	# Catchable ball and within catch box
	# Catch prob depends on throw speed and distance since last bounce
	var catch_prob:float = 1
	var catch_prob_mult:float = 1
	# Bounces are harder to catch
	if ball.previous_bounce_pos != null:
		if ball.previous_bounce_pos.distance_to(ball.position) < 4:
			catch_prob_mult *= 4
		else:
			catch_prob_mult *= 2
	# Hard hits/throws harder to catch
	catch_prob -= (ball.velocity.length() - 5) * .001 * catch_prob_mult
	var catch_prob_avg_fielder:float = catch_prob
	# Player fielding skill
	catch_prob = logit_adjust(catch_prob, (player.catching - 50) / 100)
	
	var catch_success:bool = randf() <= catch_prob
	printt('in fielder: catch prob = ', catch_prob,
		'catch_success=', catch_success,
		'catch prob avg fielder = ', catch_prob_avg_fielder,
		ball.velocity.length(),
		ball.previous_bounce_pos,
		player.catching,
		catch_prob_mult)
	if catch_success:
		# Catch successful
		printt('In fielder, caught ball', posname,
			distance_from_ball_xz, position,
			ball.position,
			Time.get_ticks_msec() - ball.time_last_thrown,
			ball.throw_progress, Time.get_ticks_msec())
		var ball_position_before_fielded = ball.position
		ball.global_position = $Char3D.get_hand_global_position(throws)
		set_holding_ball(true)
		set_assignment("holding_ball")
		if state == 'precatch':
			# Already in animation
			printt('in fielder, caught ball from precatch, dont change anim, do change state to catching')
			pass
		else:
			printt('in fielder, caught ball but not precatch, set anim to catch and state to catching')
			var anim_name:String = ''
			if Time.get_ticks_msec() -  ball.time_last_thrown < 3000 and \
				 ball_position_before_fielded.y > player.height()*.25 and \
				 ball_position_before_fielded.y < player.height()*.95:
				# If ball was thrown and in chest region, do 1B style catch
				anim_name = 'catch'
			elif ball_position_before_fielded.y < player.height()*.5:
				anim_name = 'catch_grounder'
			elif ball_position_before_fielded.y < player.height()*0.9:
				anim_name = 'catch_chest'
			elif ball_position_before_fielded.y < player.height()*1.9:
				anim_name = 'catch_high'
			else:
				# Avoiding jump for now, looks bad
				anim_name = 'catch_jump'
			set_animation(anim_name)
		set_state('catching')
		assignment_pos = null
		ball_fielded.emit(self, ball_position_before_fielded)
		if user_is_pitching_team:
			set_selected_fielder()
		# Since new state, return (avoid movement anim change)
		return [true, true]
	else:
		# Catch dropped
		printt('in fielder: catch dropped')
		# Move ball in random direction
		ball.velocity = Vector3(randfn(0,1),randfn(0,1),randfn(0,1)
			).normalized() * max_throw_speed / 10
		turn_off_bad_catch_label_timer = 1
		$BadThrowLabel3D.visible = true
		# Stop them
		if state != 'precatch':
			set_animation('idle')
		if user_is_pitching_team and user_fields:
			set_assignment('ball')
		else:
			set_assignment("wait_to_receive")
			assignment_pos = null
			# Reassign fielders since no one is chasing ball
			#fielder_moved_reassign_fielders_signal.emit(self)
		# Catchable but dropped
		return [true, false]
