extends CharacterBody3D


var pitch_in_progress = false
var pitch_done = false
var time_since_pitch_start = 0
var pitch_frame = 0
var pitch_type = "FB"
var max_pitch_speed = 40
var pitch_hand = "L"
var user_is_pitching_team

var ball_3d_scene = load("res://ball_3d.tscn")

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
func begin_pitch():
	pitch_in_progress = true
	pitch_frame = 1
	$AnimatedSprite3D.set_frame(1)
	#printt('BEGINNING PITCH IN PITCHER')
	pitch_started.emit(pitch_x, pitch_y)
	#printt('signal was emitted.......')

func _physics_process(delta: float) -> void:
	if pitch_in_progress:
		time_since_pitch_start += delta
	# Pre-pitch
	if not pitch_done and not pitch_in_progress: 
		if user_is_pitching_team:
			# Pitch type
			if Input.is_action_just_pressed("throwhome"):
				pitch_type = "FB"
			elif Input.is_action_just_pressed("throwfirst"):
				pitch_type = "2SFB"
			elif Input.is_action_just_pressed("throwthird"):
				pitch_type = "SL"
			elif Input.is_action_just_pressed("throwsecond"):
				pitch_type = "CB"
			# Begin pitch
			if Input.is_action_just_pressed("ui_select") or Input.is_action_just_pressed("click"):
				begin_pitch()
		else:
			if timer_action == null:
				# Start pitch
				pitch_type = ["FB", "2SFB", "SL", "CB"].pick_random()
				select_pitch_location()
				timer_action = 'begin_pitch'
				printt('starting timer')
				$Timer.wait_time = 1.3
				$Timer.start()
		
	if not pitch_done and pitch_in_progress and pitch_frame == 1 and time_since_pitch_start > .25:
		# Advance delivery animation
		pitch_frame = 2
		$AnimatedSprite3D.set_frame(2)
	if not pitch_done and pitch_in_progress and pitch_frame == 2 and time_since_pitch_start > .5:
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
		ball.position.x = -.5 # put in lefty hand
		ball.position.y=position.y + 1.5 # 1.5 yards higher than ground of pitcher
		ball.position.z= position.z - 2 # 2 yards closer than pitcher
		#ball.velocity.z = -40*.75 # 40 is about about 90 mph
		#ball.velocity.x=1 # to get over home plate
		#ball.velocity.y = .62+1.6 # downward throw
		#ball.acceleration.y = -9.8*.6 # gravity
		ball.spin_acceleration.y = randf_range(-3,1)
		ball.spin_acceleration.x = randf_range(-3,3) # Side movement
		var spin_and_speed = get_spin_acceleration_and_speed()
		ball.spin_acceleration = spin_and_speed[0]
		#var pitchspeed = 40
		var pitchspeed = spin_and_speed[1]
		var catchers_mitt = get_tree().root.get_node("Field3D/Headon/CatchersMitt")
		
		#var velo_vec = ball.find_starting_velocity_vector(pitchspeed, ball.position, 
		#	pitch_x, pitch_y)
		if user_is_pitching_team:
			pitch_x = catchers_mitt.position.x
			pitch_y = catchers_mitt.position.y
		
		
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
		ball.pitch_in_progress = true
		ball.state = "pitch"
		
		#ball.acceleration.z = 10 # drag
		#print(ball)
		ball.get_node("AnimatedSprite3D").play()
		#get_tree().current_scene.get_node('Headon').add_child(ball)
		# Put ball under Headon node
		#get_parent().add_child(ball)
		print(ball.position)
		print(ball.global_position)
		print(position)
		print(global_position)
		
		
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
		var mouse_sz_pos = get_tree().root.get_node("Field3D").get_mouse_sz_pos()
		#printt('glove pos', mouse_sz_pos)
		#printt('catmitt is', get_tree().root.get_node("Field3D/Headon/CatchersMitt"))
		mouse_sz_pos.z -= .001
		get_tree().root.get_node("Field3D/Headon/CatchersMitt").position = mouse_sz_pos


var timer_action

func _on_timer_timeout() -> void:
	printt("Pitcher timeout is done")
	$Timer.stop()
	if timer_action == "begin_pitch":
		begin_pitch()

var pitch_x
var pitch_y
func select_pitch_location():
	pitch_x = randf_range(-9,9)/12/3
	pitch_y = randf_range(0.5,1.2)
