extends CharacterBody3D


var pitch_in_progress = false
var pitch_done = false
var time_since_pitch_start = 0
var pitch_frame = 0
var pitch_type = "FB"
var max_pitch_speed = 34
var pitch_hand = "L"
var user_is_pitching_team
var prev_mouse_sz_pos
var catchermitt_speed = 0.5 # non-mouse movement
var animation = "idle"
var throws:String = 'R'
const time_until_pitch_release:float = 1.2
var pitch_mode:String
var pitch_select_step:int = 0
var pitch_select_key = null
var action_to_pitch_type:Dictionary = {
	"throwhome": "FB",
	"throwfirst": "2SFB",
	"throwsecond": "CB",
	"throwthird": "SL"
}
var pitch_bar_success:bool = true

var ball_3d_scene = load("res://ball_3d.tscn")
@onready var pitcher_fielder_node = get_parent().get_node('Defense/Fielder3DP/')
var player = null

var is_frozen:bool = false
func freeze() -> void:
	is_frozen = true
	visible = false
	set_physics_process(false)

func pause() -> void:
	$Char3D.pause()
	set_physics_process(false)

func unpause() -> void:
	$Char3D.unpause()
	set_physics_process(true)

func reset(pitch_mode_:String) -> void:
	is_frozen = false
	visible = true
	set_physics_process(true)
	# Reset vars
	pitch_in_progress = false
	pitch_done = false
	time_since_pitch_start = 0
	pitch_frame = 0
	pitch_type = "FB"
	$AnimatedSprite3D.set_frame(0)
	$AnimatedSprite3D.visible = false
	pitch_mode = pitch_mode_
	assert(pitch_mode in ["Button", "Bar", "BarOneWay", "BarTwoWay"])
	pitch_select_step = 0
	pitch_select_key = null
	
	$Char3D.reset() # Resets rotation
	#$Char3D.look_at(Vector3(0,0,0), Vector3.UP, true)
	set_look_at_position(Vector3(100,0,position.z))
	set_animation("idle")
	#$Char3D.set_color(color)
	player = null
	pitch_bar_success = true

func get_spin_acceleration_and_speed():
	var sign_
	if pitch_hand == "L":
		sign_ = 1
	else:
		sign_ = -1
	if pitch_type == 'FB':
		return [Vector3(0,3,0)*sign_, max_pitch_speed]
	elif pitch_type == '2SFB':
		return [Vector3(-3,1,0)*sign_, .95*max_pitch_speed]
	elif pitch_type == 'SL':
		return [Vector3(4,0,0)*sign_, .85*max_pitch_speed]
	elif pitch_type == 'CB':
		return [Vector3(0,-4,0)*sign_, .7*max_pitch_speed]
	print("BAD PITCH TYPE")
	return [Vector3(0,3,0)*sign_, max_pitch_speed]

signal pitch_started#(pitch_x, pitch_y)
signal pitch_released_signal
func begin_pitch():
	pitch_in_progress = true
	pitch_frame = 1
	$AnimatedSprite3D.set_frame(1)
	#printt('BEGINNING PITCH IN PITCHER')
	pitch_started.emit(pitch_x, pitch_y, pitch_t)
	#printt('signal was emitted.......')
	
	set_look_at_position(Vector3(0,0,0))
	set_animation('pitch')

func _physics_process(delta: float) -> void:
	#if randf_range(0,1) < .04:
		#printt('pitcher process conditions',
		#$Char3D/charnode/AnimationTree.get("parameters/conditions/pitch"),
		#$Char3D/charnode/AnimationTree.get("parameters/conditions/idle"))
	if is_frozen:
		return
		
	#printt('in pitcher:', pitch_mode, pitch_select_key, pitch_select_step)
	
	if pitch_in_progress:
		time_since_pitch_start += delta
	
	# If it started the pitch animation, change to idle. It will finish the 
	#  pitch animation before transitioning.
	if animation == 'pitch':
		set_animation('idle')
	
	# Pre-pitch
	if not pitch_done and not pitch_in_progress: 
		if user_is_pitching_team:
			# Pitch type
			if pitch_mode == "Button":
				# Single press starts pitch
				for action in action_to_pitch_type.keys():
					if Input.is_action_just_pressed(action):
						pitch_type = action_to_pitch_type[action]
						begin_pitch()
			elif pitch_mode == "Bar":
				assert(false)
			elif pitch_mode == "BarOneWay":
				# Press (0) and release (1)
				if pitch_select_step == 0:
					# Check for press
					for action in action_to_pitch_type.keys():
						if Input.is_action_just_pressed(action):
							pitch_type = action_to_pitch_type[action]
							pitch_select_step = 1
							pitch_select_key = action
							$ThrowBarOneWay.visible = true
							var cam = get_viewport().get_camera_3d()
							$ThrowBarOneWay.position = cam.unproject_position(global_position)
							$ThrowBarOneWay.reset(50, .5)
				elif pitch_select_step == 1:
					# Check for release
					if Input.is_action_just_released(pitch_select_key):
						pitch_select_step = 2
						var barout = $ThrowBarOneWay.check_success(true, true)
						var bar_success = randf() >= barout[1]
						if !bar_success:
							#pitch_x += 1
							#pitch_y += 1
							pitch_bar_success = false
						begin_pitch()
			elif pitch_mode == "BarTwoWay":
				# Press (0) and release (1) and return press (2)
				if pitch_select_step == 0:
					# Check for press
					for action in action_to_pitch_type.keys():
						if Input.is_action_just_pressed(action):
							pitch_type = action_to_pitch_type[action]
							pitch_select_step = 1
							pitch_select_key = action
							$ThrowBarTwoWay.visible = true
							var cam = get_viewport().get_camera_3d()
							$ThrowBarTwoWay.position = cam.unproject_position(global_position)
							$ThrowBarTwoWay.reset(50, .5)
				elif pitch_select_step == 1:
					# Check for release
					if Input.is_action_just_released(pitch_select_key):
						pitch_select_step = 2
						$ThrowBarTwoWay.forward_release()
				elif pitch_select_step == 2:
					# Check for return press
					if (Input.is_action_just_pressed(pitch_select_key) or 
							$ThrowBarTwoWay.bar_reached_end_without_forward_release):
						pitch_select_step = 3
						var barout = $ThrowBarTwoWay.check_success(true, true)
						var bar_success = barout[3]
						if !bar_success:
							#pitch_x += 1
							#pitch_y += 1
							pitch_bar_success = false
						begin_pitch()
			else:
				assert(false)
			# Begin pitch
			#if click and on keyboard thing:
			#if Input.is_action_just_pressed("begin_pitch"):
				#begin_pitch()
		else:
			if timer_action == null:
				# Start pitch
				pitch_type = ["FB", "2SFB", "SL", "CB"].pick_random()
				select_pitch_location()
				timer_action = 'begin_pitch'
				$Timer.wait_time = 1.3
				$Timer.start()
		
	if not pitch_done and pitch_in_progress and pitch_frame == 1 and time_since_pitch_start > .25:
		# Advance delivery animation
		pitch_frame = 2
		$AnimatedSprite3D.set_frame(2)
		$PitchSelectKeyboard.visible = false
	if not pitch_done and pitch_in_progress and pitch_frame == 2 and time_since_pitch_start > time_until_pitch_release:
		# Begin pitch
		pitch_in_progress = false
		pitch_done = true
		pitch_frame = 3
		$AnimatedSprite3D.set_frame(3)
		# Create ball
		#var ball = ball_3d_scene.instantiate()
		var ball = get_parent().get_node("Ball3D")
		ball.visible = true
		#print('ball basis'); print(ball.basis)
		#print('basis'); print(basis)
		#print('headon basis'); print($Headon)
		#ball.transform = transform
		#ball.basis = basis
		ball.position.x = 0.35 # put in righty hand
		if throws == "L":
			ball.position.x *= -1 # put in lefty hand
		ball.position.y=position.y + 1.7 # 1.5 yards higher than ground of pitcher
		# Adjust ball height for pitcher height
		ball.position.y *= player.height_mult
		ball.position.z= position.z - 2 # 2 yards closer than pitcher
		#ball.velocity.z = -40*.75 # 40 is about about 90 mph
		#ball.velocity.x=1 # to get over home plate
		#ball.velocity.y = .62+1.6 # downward throw
		#ball.acceleration.y = -9.8*.6 # gravity
		var spin_and_speed = get_spin_acceleration_and_speed()
		ball.spin_acceleration = spin_and_speed[0]
		var pitchspeed = spin_and_speed[1]
		var catchers_mitt = get_parent().get_node("CatchersMitt")
		
		#var velo_vec = ball.find_starting_velocity_vector(pitchspeed, ball.position, 
		#	pitch_x, pitch_y)
		if user_is_pitching_team:
			pitch_x = catchers_mitt.position.x
			pitch_y = catchers_mitt.position.y
		if not pitch_bar_success:
			pitch_x += randfn(0, 0.5)
			pitch_y += randfn(0, 0.5)
		
		# Test my parabola solution
		#printt('test parabola solution')
		#printt('velo from optimization', velo_vec)
		var parabola_approx_velo = ball.fit_approx_parabola_to_trajectory(
			ball.position,
			Vector3(pitch_x, pitch_y, ball.sz_z),
			pitchspeed, false
		)
		printt("Now fit with drag")
		
		var parabola_approx_velo_with_drag = ball.fit_approx_parabola_to_trajectory(
			ball.position,
			Vector3(pitch_x, pitch_y, ball.sz_z),
			pitchspeed, true
		)
		printt("compare drag", parabola_approx_velo_with_drag,
		" to", parabola_approx_velo)
		#print('velo from parabola approx', parabola_approx_velo)
		#printt('from optimization', ball.simulate_delivery(ball.position, velo_vec))
		#printt('from approx', ball.simulate_delivery(ball.position, parabola_approx_velo))
		#printt('target was', Vector3(pitch_x, pitch_y, ball.sz_z))
		#printt('now find start velo with good starting point')
		var velo_vec_with_start = ball.find_starting_velocity_vector(pitchspeed, ball.position, 
			pitch_x, pitch_y, 1./36/36, parabola_approx_velo)
		#printt('is this better? (fewer steps?)', velo_vec_with_start)
		printt("Pitch start velo is", velo_vec_with_start)
		catchers_mitt.get_node("Sprite3D").visible=false
		catchers_mitt.set_process(false)
		ball.velocity = velo_vec_with_start
		pitch_t = ball.simulate_delivery(ball.position, ball.velocity, 1./60, true)
		printt('pitch_t is', pitch_t)
		ball.pitch_in_progress = true
		ball.state = "pitch"
		
		#ball.acceleration.z = 10 # drag
		#print(ball)
		ball.get_node("AnimatedSprite3D").play()
		#get_tree().current_scene.get_node('Headon').add_child(ball)
		# Put ball under Headon node
		#get_parent().add_child(ball)
		#print(ball.position)
		#print(ball.global_position)
		#print(position)
		#print(global_position)
		pitch_released_signal.emit(pitch_x, pitch_y, pitch_t)
		
		
		# Testing simulate_delivery
		#print("Testing simulate_delivery")
		#print(ball.simulate_delivery(ball.position, ball.velocity))
		
		# Testing find_starting_velocity_vector
		#print("Testing find_starting_velocity_vector")
		#print(ball.find_starting_velocity_vector(40, ball.position, 0, 1))
		
		# Hide pitcher and activate Fielder3DP
		visible = false
		set_physics_process(false)
		set_process(false)
		var fielderP = get_parent().get_node("Defense/Fielder3DP")
		fielderP.visible = true
		fielderP.position = position
		
	
	# Place catcher's mitt for pitch target
	if not pitch_done and not pitch_in_progress:
		var mouse_sz_pos = get_parent().get_parent().get_mouse_sz_pos()
		#printt('glove pos', mouse_sz_pos)
		#printt('catmitt is', get_tree().root.get_node("Field3D/Headon/CatchersMitt"))
		mouse_sz_pos.z -= .001 # Move so it is behind the strike zone
		if prev_mouse_sz_pos==null or prev_mouse_sz_pos != mouse_sz_pos:
			get_parent().get_node("CatchersMitt").position = mouse_sz_pos
		else: # No mouse movement
			var mitt = get_parent().get_node("CatchersMitt")
			#if Input.is_action_pressed("movedown"):
				#mitt.position.y -= delta*catchermitt_speed
			#if Input.is_action_pressed("moveup"):
				#mitt.position.y += delta*catchermitt_speed
			#if Input.is_action_pressed("moveleft"):
				#mitt.position.x += delta*catchermitt_speed
			#if Input.is_action_pressed("moveright"):
				#mitt.position.x -= delta*catchermitt_speed
			var LR = Input.get_axis("moveleft", "moveright")
			var DU = Input.get_axis("movedown", "moveup")
			#printt('LR DU', LR, DU)
			mitt.position.x += delta*catchermitt_speed * LR * (-1)
			mitt.position.y += delta*catchermitt_speed * DU
		
		prev_mouse_sz_pos = mouse_sz_pos


var timer_action

func _on_timer_timeout() -> void:
	#printt("Pitcher timeout is done")
	$Timer.stop()
	if timer_action == "begin_pitch":
		begin_pitch()
	timer_action = null

var pitch_x
var pitch_y
var pitch_t
func select_pitch_location():
	pitch_x = randf_range(-9,9)/12/3
	pitch_y = randf_range(0.5,1.2)


func set_animation(new_anim):
	if new_anim == animation:
		return
	animation = new_anim
	#if new_anim == "idle":
		#pass
	#if new_anim == "moving":
	$Char3D.start_animation(new_anim, false, throws=='R')
	pitcher_fielder_node.set_animation(new_anim)

func set_look_at_position(pos) -> void:
	# Always stay vertical
	pos.y = 0
	# Rotate to global frame
	pos = pos.rotated(Vector3(0,1,0), 45.*PI/180)
	# Look at global position
	$Char3D.look_at(pos, Vector3.UP, true)

func setup_player(player_, team, is_home_team:bool) -> void:
	if player_ == null:
		push_error("no player in pitcher")
	player = player_
	throws = player.throws
	if throws == 'R':
		set_look_at_position(Vector3(100,0,position.z))
	else:
		set_look_at_position(Vector3(-100,0,position.z))
	if team != null:
		$Char3D.set_color_from_team(player, team, is_home_team)
		$Char3D.set_glove(throws=="R")
