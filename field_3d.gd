extends Node3D

var contact_done = false
var ball_in_play = false
var ball_in_play_state = null
var ball_in_play_state_time = 0
const sz_z = 0.6

var outs_on_play = 0

var user_is_pitching_team = !false
var user_is_batting_team = false

#func record_out(type : String):
#	outs_on_play += 1

func _on_ball_fielded_by_fielder():
	# TODO pass in which fielder, to check their location and if stepping on base
	var ball = get_node("Headon/Ball3D")
	printt("in field: Ball fielded", ball.state, ball.hit_bounced)
	if ball.state == "ball_in_play" and not ball.hit_bounced:
		printt("fly Out recorded!!!")
		outs_on_play += 1
		get_node("FlashText").new_text("Fly out!", 3)
		get_node("Headon/Runners/Runner3DHome").runner_is_out()
	
	# Do this last so that the type of out can be determined
	ball.ball_fielded()

func _on_throw_ball_by_fielder(base, fielder):
	printt('In field_3d, throwing ball to:', base, fielder)
	# Set new assignments
	
	# Set ball throw
	var ball = get_node("Headon/Ball3D")
	var target
	if base == 1:
		target = Vector3(-1,0,1)*30/sqrt(2) + Vector3(0,1.4,0)
	elif base == 2:
		target = Vector3(0,0,1)*30*sqrt(2) + Vector3(0,1.4,0)
	elif base == 3:
		target = Vector3(1,0,1)*30/sqrt(2) + Vector3(0,1.4,0)
	elif base == 4:
		target = Vector3(0,0,0) + Vector3(0,1.4,0)
	else:
		assert(false)
	target.y = 1
	printt('target is', target, 'fielder pos is', fielder.position)
	var velo_vec = fielder.max_throw_speed * (target - fielder.position).normalized()
	ball.throw_to_base(base, velo_vec, fielder.position, target)

func _on_stepped_on_base_with_ball_by_fielder(_fielder, base):
	# Check for force out
	#printt('in field3D, stepped on base with ball!!!!')
	# TODO if runner before is out on play, then it's no longer force out
	var runners = get_tree().get_nodes_in_group("runners")
	for runner in runners:
		if (runner.exists_at_start and
			runner.start_base == base - 1 and
			not runner.out_on_play and 
			runner.max_running_progress < base - 1e-8):
			# Would be out, need to make sure that all previous runners are still active
			var prev_runner_out = false
			for otherrunner in runners:
				if otherrunner.start_base < runner.start_base-.5 and not otherrunner.is_active():
					prev_runner_out = true
			if not prev_runner_out:
				runner.runner_is_out()
				#printt("force Out recorded!!!", runner.start_base, base,
				#       runner.running_progress, runner.max_running_progress)
				outs_on_play += 1
				get_node("FlashText").new_text("force out!", 3)
				#runner.runner_is_out()
			#else:
			#	printt('not force out, prev runner not there')
	return

func _on_tag_out_by_fielder():
	outs_on_play += 1
	get_node("FlashText").new_text("tag out!", 3)

func test_mesh_array():
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var verts = PackedVector3Array()
	#var uvs = PackedVector2Array()
	#var normals = PackedVector3Array()
	#var indices = PackedInt32Array()
	var colors = PackedColorArray()
	
	# Vertices
	verts.push_back(Vector3(0,0,0))
	verts.push_back(Vector3(2,0,0))
	verts.push_back(Vector3(2,2,0))
	verts.push_back(Vector3(2,2,0))
	verts.push_back(Vector3(4,4,0))
	verts.push_back(Vector3(4,2,0))
	
	#uvs.push_back(Vector2(.3,.4))
	#uvs.push_back(Vector2(.3,.4))
	#uvs.push_back(Vector2(.3,.4))
	
	#normals.push_back(Vector3(0,0,1))
	#normals.push_back(Vector3(0,0,1))
	#normals.push_back(Vector3(0,0,1))
	
	# Colors
	for i in range(len(verts)):
		colors.push_back(Color(0,0,1,1))
	
	surface_array[Mesh.ARRAY_VERTEX] = verts
	#surface_array[Mesh.ARRAY_TEX_UV] = uvs
	#surface_array[Mesh.ARRAY_NORMAL] = normals
	#surface_array[Mesh.ARRAY_INDEX] = indices
	surface_array[Mesh.ARRAY_COLOR] = colors
	#printt('new mesh is', surface_array)

	# No blendshapes, lods, or compression used.
	var meshnode = get_node("Ground/testarraymeshdelete")
	meshnode.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	#meshnode.mesh
	#printt("printing dir?")
	#print((meshnode.mesh.get_method_list()))
	var your_material = StandardMaterial3D.new()
	meshnode.mesh.surface_set_material(0, your_material)   # will need uvs if using a texture
	your_material.vertex_color_use_as_albedo = true # will need this for the array of colors


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#print('in field_3d ready')
	# Align fielders with the camera
	get_tree().call_group('fielders', 'align_sprite')
	
	#get_node('Headon/Batter3D/AnimatedSprite3DIdle').modulate = Color(0,1,0,1)
	var fielder_nodes = get_tree().get_nodes_in_group('fielders')
	# Set up signals from fielders
	for fielder in fielder_nodes:  
		fielder.connect("ball_fielded", _on_ball_fielded_by_fielder)
		fielder.connect("throw_ball", _on_throw_ball_by_fielder)
		fielder.connect("stepped_on_base_with_ball", _on_stepped_on_base_with_ball_by_fielder)
		fielder.connect("tag_out", _on_tag_out_by_fielder)
	
	# Test mesh array
	#test_mesh_array()
	
	# Set variables in children
	$Headon/Pitcher3D.user_is_pitching_team = user_is_pitching_team
	for fielder in fielder_nodes:
		fielder.user_is_pitching_team = user_is_pitching_team
	if not user_is_pitching_team:
		$Headon/CatchersMitt.visible = false
	$Headon/Batter3D.user_is_batting_team = user_is_batting_team

	

func get_mouse_sz_pos():
	var cam = get_viewport().get_camera_3d()
	var mousepos = get_viewport().get_mouse_position()
	# depth is distance from cam to strike zone: +.6 for sz_z, +10 is arbitrary
	#  distance to project forward, will then be used to trace back to intersection
	var ppos = cam.project_position(mousepos, -cam.position.z +.6 + 10)
	ppos = $Headon.to_local(ppos)
	var prop_ppos = (sz_z - cam.position.z) / (ppos.z - cam.position.z)
	var cross_sz = prop_ppos * ppos + (1 - prop_ppos) * cam.position
	#printt('TEST POSITION MOUSE', mousepos,ppos, cross_sz, cam.position)
	return cross_sz

func get_mouse_y0_pos():
	# Find where mouse cross ground y==0
	var cam = get_viewport().get_camera_3d()
	var mousepos = get_viewport().get_mouse_position()
	# Find projection arbitrary z_depth
	var z_depth = 20
	var ppos = cam.project_position(mousepos, z_depth)
	ppos = $Headon.to_local(ppos)
	# Two points in line of camera view: camera.position and ppos
	var prop_ppos = (0 - cam.position.y) / (ppos.y - cam.position.y)
	var cross_y0 = prop_ppos * ppos + (1 - prop_ppos) * cam.position
	#printt('TEST POSITION MOUSE', mousepos,ppos, cross_sz, cam.position)
	return cross_y0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if randf_range(0,1) < 1./1000:
		printt('in field_3d, frame rate', (1./delta))
	#printt('get_mouse_z', get_mouse_sz_pos())
	#printt('get_mouse_y0', get_mouse_y0_pos())
	
	
	# R key reloads
	if Input.is_action_just_pressed("reload"):
		print('reload')
		get_tree().reload_current_scene()
	
	# Pause game
	if Input.is_action_just_pressed("startbutton"):
		print('start button pressed')
		if get_tree().paused:
			_on_resume_button_pressed()
		else:
			_on_pause_button_pressed()
	if Input.is_key_pressed(KEY_P):
		Engine.time_scale = randf_range(.1,10)
	
	# Check for contact on swing
	if not contact_done and get_node_or_null("Headon/Ball3D"):
		var ball3d = $Headon/Ball3D
		#print('found ball')
		# pitch is active
		if ball3d.velocity.length() > 0:
			if $Headon/Batter3D.swing_state == "inzone":
				if (sz_z - ball3d.position.z)**2 < 1**2:
					print('CONTACT')
					contact_done = true
					ball_in_play = true
					ball3d.pitch_in_progress = false
					ball3d.pitch_already_done = true
					ball_in_play_state = "prereflex"
					# Zero out spin accel
					ball3d.spin_acceleration = Vector3()
					# Create ball velocity
					var exitvelo = 30-4 #randf_range(10,50)
					var vla = randf_range(-1,1)*20+20
					var hla = randf_range(-1,1)*20
					vla = -20
					hla = 0
					printt(exitvelo, vla, hla)
					ball3d.velocity.x = 0
					ball3d.velocity.y = 0
					ball3d.velocity.z = exitvelo
					#print('velo vec before rot is')
					print(ball3d.velocity)
					ball3d.velocity = ball3d.velocity.rotated(Vector3(-1,0,0), (vla)*PI/180)
					ball3d.velocity = ball3d.velocity.rotated(Vector3(0,1,0), -(hla)*PI/180)
					print('velo vec is')
					print(ball3d.velocity)
					ball3d.state = "ball_in_play"
					
					# Start running after .5 seconds
					var batter = get_node("Headon/Batter3D")
					batter.timer_action = "start_running_after_hit"
					batter.get_node("Timer").wait_time = 0.5
					batter.get_node("Timer").start()
					
					
					# Change camera
					$TimerCameraChange.wait_time = .3
					next_camera = $Headon/Cameras/Camera3DHigherHome
					$TimerCameraChange.start()
					#$Headon/Camera3DHighHome.current = true
					# Make ball bigger
					#ball3d.scale=11*Vector3(1,1,1)
					
					# Make catcher visible
					var catcher = get_node("Headon/Defense/Fielder3DC")
					catcher.get_node("Timer").wait_time = .5
					catcher.timer_action = "set_visible_true"
					catcher.get_node("Timer").start()
					
					# Make mouse circle on ground visible
					var mgl = get_node("Headon/MouseGroundLocation")
					mgl.visible = true
					mgl.set_process(true)
					
					
				else:
					pass #print('MISSED')
	if ball_in_play:
		ball_in_play_state_time += delta
		
		if ball_in_play_state == "prereflex" and ball_in_play_state_time > .4:
			printt("REACT NOW")
			ball_in_play_state = "prefield"
			ball_in_play_state_time = 0
			#var fielder_nodes = get_tree().get_nodes_in_group('fielders')
			#printt('fielder nodes', fielder_nodes)
			var hit_will_bounce = assign_fielders_after_hit()
			if hit_will_bounce:
				#printt("hit will bounce, send runners!!")
				var runners = get_tree().get_nodes_in_group("runners")
				for runner in runners:
					runner.is_running = true
					#printt('runner details', runner.target_base, runner.running_progress)
			else:
				pass #printt("hit won't bounce, don't send runners!!")
	
	# Move baserunners
	if user_is_batting_team:
		if Input.is_action_just_pressed("throwfirst"):
			#
			pass
		elif Input.is_action_just_pressed("throwsecond"):
			# Move all forward
			var runners = get_tree().get_nodes_in_group("runners")
			for runner in runners:
				runner.send_runner(1)
		elif Input.is_action_just_pressed("throwthird"):
			pass
		elif Input.is_action_just_pressed("throwhome"):
			# Move all forward
			var runners = get_tree().get_nodes_in_group("runners")
			for runner in runners:
				runner.send_runner(-1)
	
	# Adjust camera
	if get_viewport():
		var cam = get_viewport().get_camera_3d()
		# Move current camera
		var cam_move_speed = 10
		var cam_rotate_speed = 0.3
		if Input.is_key_pressed(KEY_5):
			if Input.is_key_pressed(KEY_SHIFT):
				cam.rotate_y(delta*cam_rotate_speed)
			else:
				cam.position.x += delta * cam_move_speed
		if Input.is_key_pressed(KEY_6):
			if Input.is_key_pressed(KEY_SHIFT):
				cam.rotate_y(-delta*cam_rotate_speed)
			else:
				cam.position.x -= delta * cam_move_speed
		if Input.is_key_pressed(KEY_7):
			if Input.is_key_pressed(KEY_SHIFT):
				cam.rotate_x(delta*cam_rotate_speed)
			else:
				cam.position.y += delta * cam_move_speed
		if Input.is_key_pressed(KEY_8):
			if Input.is_key_pressed(KEY_SHIFT):
				cam.rotate_x(-delta*cam_rotate_speed)
			else:
				cam.position.y -= delta * cam_move_speed
		if Input.is_key_pressed(KEY_9):
			if Input.is_key_pressed(KEY_SHIFT):
				cam.rotate_z(delta*cam_rotate_speed)
			else:
				cam.position.z += delta * cam_move_speed
		if Input.is_key_pressed(KEY_0):
			if Input.is_key_pressed(KEY_SHIFT):
				cam.rotate_z(-delta*cam_rotate_speed)
			else:
				cam.position.z -= delta * cam_move_speed
		
		# Set different camera
		if Input.is_key_pressed(KEY_1):
			if Input.is_key_pressed(KEY_SHIFT):
				get_node("Headon/Cameras/Camera3DPitchSideView").current = true
			else:
				get_node("Headon/Cameras/Camera3DBatting").current = true
		elif Input.is_key_pressed(KEY_2):
			if Input.is_key_pressed(KEY_SHIFT):
				get_node("Headon/Cameras/Camera3DHigherHome").current = true
			else:
				get_node("Headon/Cameras/Camera3DHighHome").current = true
		elif Input.is_key_pressed(KEY_3):
			get_node("Headon/Cameras/Camera3DPitcherShoulderRight").current = true
		elif Input.is_key_pressed(KEY_4):
			get_node("Headon/Cameras/Camera3DAll22").current = true
	
	# Check if play is done, but not every time
	time_since_check_if_play_done_checked += delta
	if time_since_check_if_play_done_checked > .5:
		if check_if_play_done():
			time_since_play_done_consecutive += .5
			if time_since_play_done_consecutive > .6:
				play_done_fully = true
				get_node("FlashText").new_text("Play is done!", 3)
				get_tree().reload_current_scene()
		else:
			time_since_play_done_consecutive = 0

var tmp_ball
var ball_3d_scene = load("res://ball_3d.tscn")
func assign_fielders_after_hit():
	#printt("Starting assign_fielders_after_hit !!")
	var fielder_nodes = get_tree().get_nodes_in_group('fielders')
	#printt('fielder nodes', fielder_nodes)
	var ball = get_node_or_null("Headon/Ball3D")
	tmp_ball = ball_3d_scene.instantiate()
	tmp_ball.name = "tmp_ball"
	tmp_ball.is_sim = true
	tmp_ball.state = "ball_in_play"
	tmp_ball.hit_bounced = ball.hit_bounced
	get_node("Headon").add_child(tmp_ball)
	#printt('tmp_ball', tmp_ball, tmp_ball.state, tmp_ball.hit_bounced)
	tmp_ball.position = ball.position
	#printt('balls global pos', tmp_ball.global_position, ball.global_position)
	tmp_ball.velocity = ball.velocity
	tmp_ball.pitch_already_done = true 
	#printt('pos before', tmp_ball.position)
	#tmp_ball._physics_process(1)
	#printt('pos after', tmp_ball.position)
	var take_steps = func(nsteps, delta_):
		for istep in range(nsteps):
			tmp_ball._physics_process(delta_)
	# Check every ~.5 second to see if each fielder can reach the ball
	var iii = 0
	var numsteps = 5
	var delta = 1./30
	var elapsed_time = 0
	var found_someone = false
	var min_timetoreach = 1e9
	var min_ifielder
	while iii < 1000:
		iii += 1
		take_steps.call(numsteps, delta)
		elapsed_time += numsteps * delta
		# Make it's reachable
		if tmp_ball.position.y < 2:
			# Loop over fielder, see if can reach ball
			for ifielder in range(len(fielder_nodes)):
				var fielderi = fielder_nodes[ifielder]
				var ballgrounddist = sqrt((fielderi.position.x - tmp_ball.position.x)**2 +
					(fielderi.position.z - tmp_ball.position.z)**2)
				var timetoreach = ballgrounddist / fielderi.SPEED
				
				if timetoreach <= elapsed_time:
					#printt('found fielder to field', elapsed_time, fielderi.position, tmp_ball.position)
					#fielderi.assign_to_field_ball(tmp_ball.position)
					#printt('ball bounced???', tmp_ball.hit_bounced, tmp_ball.state)
					if timetoreach < min_timetoreach:
						min_timetoreach = timetoreach
						min_ifielder = ifielder
						found_someone = true
		if found_someone:
			fielder_nodes[min_ifielder].assign_to_field_ball(tmp_ball.position)
			break
	if not found_someone:
		print('no fielder found')
	if found_someone:
		# Assign someone to cover base
		#printt('fielder assigned name:', fielder_nodes[min_ifielder].name, fielder_nodes[min_ifielder].posname)
		#for ifielder in fielder_nodes:
		if fielder_nodes[min_ifielder].posname == "2B":
			get_fielder_with_posname(fielder_nodes, "1B").assign_to_cover_base(1)
			get_fielder_with_posname(fielder_nodes, "SS").assign_to_cover_base(2)
			get_fielder_with_posname(fielder_nodes, "3B").assign_to_cover_base(3)
			get_fielder_with_posname(fielder_nodes, "C").assign_to_cover_base(4)
		elif fielder_nodes[min_ifielder].posname == "SS":
			get_fielder_with_posname(fielder_nodes, "1B").assign_to_cover_base(1)
			get_fielder_with_posname(fielder_nodes, "2B").assign_to_cover_base(2)
			get_fielder_with_posname(fielder_nodes, "3B").assign_to_cover_base(3)
			get_fielder_with_posname(fielder_nodes, "C").assign_to_cover_base(4)
		elif fielder_nodes[min_ifielder].posname == "1B":
			get_fielder_with_posname(fielder_nodes, "P").assign_to_cover_base(1)
			get_fielder_with_posname(fielder_nodes, "SS").assign_to_cover_base(2)
			get_fielder_with_posname(fielder_nodes, "3B").assign_to_cover_base(3)
			get_fielder_with_posname(fielder_nodes, "C").assign_to_cover_base(4)
		elif fielder_nodes[min_ifielder].posname == "3B":
			get_fielder_with_posname(fielder_nodes, "1B").assign_to_cover_base(1)
			get_fielder_with_posname(fielder_nodes, "2B").assign_to_cover_base(2)
			get_fielder_with_posname(fielder_nodes, "SS").assign_to_cover_base(3)
			get_fielder_with_posname(fielder_nodes, "C").assign_to_cover_base(4)
		elif fielder_nodes[min_ifielder].posname in ["P", "LF", "CF", "RF"]:
			get_fielder_with_posname(fielder_nodes, "1B").assign_to_cover_base(1)
			get_fielder_with_posname(fielder_nodes, "2B").assign_to_cover_base(2)
			get_fielder_with_posname(fielder_nodes, "3B").assign_to_cover_base(3)
			get_fielder_with_posname(fielder_nodes, "C").assign_to_cover_base(4)
		elif fielder_nodes[min_ifielder].posname == "C":
			get_fielder_with_posname(fielder_nodes, "1B").assign_to_cover_base(1)
			get_fielder_with_posname(fielder_nodes, "2B").assign_to_cover_base(2)
			get_fielder_with_posname(fielder_nodes, "3B").assign_to_cover_base(3)
			get_fielder_with_posname(fielder_nodes, "P").assign_to_cover_base(4)
			
	# Delete object at end
	tmp_ball.velocity = Vector3()
	get_node("Headon").remove_child(tmp_ball)
	var tmp_ball_bounced = tmp_ball.hit_bounced
	tmp_ball.queue_free()
	
	for i in range(10):
		print('------- done with tmp_ball')
	
	# Return whether the ball bounced. Will be used to determine if runners run.
	return tmp_ball_bounced

func get_fielder_with_posname(fielders, posname):
	var f1 = fielders.filter(func(f): return f.posname == posname)
	#printt('in get_fielders_with_posname',fielders, posname, f1)
	assert(len(f1)== 1)
	return f1[0]

var next_camera = null
func _on_timer_camera_change_timeout() -> void:
	print('changing camera')
	pass # Replace with function body.
	if next_camera != null:
		next_camera.current = true
		next_camera = null
		
		$Headon/Ball3D.scale=11*Vector3(1,1,1)
	$TimerCameraChange.stop()


func _on_batter_3d_start_runner() -> void:
	# Start runner
	var runner_node = get_node("Headon/Runners/Runner3DHome")
	runner_node.set_process(true)
	runner_node.visible = true
	runner_node.is_running = true
	runner_node.running_progress = 0.04
	runner_node.max_running_progress = 0.04
	
	# Turn off batter
	get_node("Headon/Batter3D").visible = false
	get_node("Headon/Batter3D").set_process(false)

func _on_pause_button_pressed():
	get_tree().paused = true
	#show()

func _on_resume_button_pressed():
	get_tree().paused = false

func _on_pitcher_3d_pitch_started(_pitch_x, _pitch_y) -> void:
	#printt('in field, pitch started!!!!!!!!!!!!!!!!!')
	if not user_is_batting_team:
		get_node("Headon/Batter3D").timer_action = 'begin_swing'
		get_node("Headon/Batter3D/Timer").wait_time = .95
		get_node("Headon/Batter3D/Timer").start()

var time_since_check_if_play_done_checked = 0
var time_since_play_done_consecutive = 0
var play_done_fully = false
func check_if_play_done():
	time_since_check_if_play_done_checked = 0
	# Check if runners aren't running and are near base
	var runners = get_tree().get_nodes_in_group("runners")
	for runner in runners:
		if runner.is_running:
			return false
		if runner.is_active() and abs(runner.running_progress - round(runner.running_progress)) > 1e-4:
			return false
	# None are running, all are near base
	# Check if fielder is holding ball
	var fielders = get_tree().get_nodes_in_group("fielders")
	var holding_ball = false
	var ball_pos
	#printt('checking for holdin gball now')
	for fielder in fielders:
		if fielder.holding_ball:
			holding_ball = true
			ball_pos = fielder.position
			break
	if not holding_ball:
		return false
	# Someone is holding ball, check if they are close to infield
	var near_infield = sqrt((ball_pos.x-0)**2 + (ball_pos.z-20)**2) < 25
	#if near_infield:
	#	printt('NEAR INFIELD, PLAY IS OVER', time_since_play_done_consecutive, time_since_check_if_play_done_checked)
	#else:
	#	printt('not play over')
	return near_infield
