extends CharacterBody3D


var pitch_in_progress = false
var pitch_done = false
var time_since_pitch_start = 0
var pitch_frame = 0

var ball_3d_scene = load("res://ball_3d.tscn")

func _physics_process(delta: float) -> void:
	if pitch_in_progress:
		time_since_pitch_start += delta
	if not pitch_done and not pitch_in_progress and Input.is_action_just_pressed("ui_select"):
		# Begin pitch
		pitch_in_progress = true
		pitch_frame = 1
		$AnimatedSprite3D.set_frame(1)
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
		var ball = ball_3d_scene.instantiate()
		#print('ball basis'); print(ball.basis)
		#print('basis'); print(basis)
		#print('headon basis'); print($Headon)
		#ball.transform = transform
		#ball.basis = basis
		ball.position.x = -.5 # put in lefty hand
		ball.position.y=position.y + 1.5 # 1.5 yards higher than ground of pitcher
		ball.position.z= position.z - 2 # 2 yards closer than pitcher
		ball.velocity.z = -40*.75 # about 90 mph
		ball.velocity.x=1 # to get over home plate
		ball.velocity.y = .62+1.6 # downward throw
		#ball.acceleration.y = -9.8*.6 # gravity
		ball.spin_acceleration.y = randf_range(-3,1)
		ball.spin_acceleration.x = randf_range(-3,3) # Side movement
		var pitchspeed = 40
		var catchers_mitt = get_tree().root.get_node("Field3D/Headon/CatchersMitt")
		
		var velo_vec = ball.find_starting_velocity_vector(pitchspeed, ball.position, 
			catchers_mitt.position.x, catchers_mitt.position.y)
		catchers_mitt.get_node("Sprite3D").visible=false
		catchers_mitt.set_process(false)
		ball.velocity = velo_vec
		
		#ball.acceleration.z = 10 # drag
		print(ball)
		ball.get_node("AnimatedSprite3D").play()
		#get_tree().current_scene.get_node('Headon').add_child(ball)
		# Put ball under Headon node
		get_parent().add_child(ball)
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
	
	# Place catcher's mitt for pitch target
	if not pitch_done and not pitch_in_progress:
		var mouse_sz_pos = get_tree().root.get_node("Field3D").get_mouse_sz_pos()
		#printt('glove pos', mouse_sz_pos)
		#printt('catmitt is', get_tree().root.get_node("Field3D/Headon/CatchersMitt"))
		mouse_sz_pos.z -= .001
		get_tree().root.get_node("Field3D/Headon/CatchersMitt").position = mouse_sz_pos
