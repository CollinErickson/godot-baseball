extends Node3D

var contact_done = false
var ball_in_play = false
var ball_in_play_state = null
var ball_in_play_state_time = 0
const sz_z = 0.6

func _on_ball_fielded_by_fielder():
	get_node("Headon/Ball3D").ball_fielded()

func test_mesh_array():
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
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
	
	get_node('Headon/Batter3D/AnimatedSprite3DIdle').modulate = Color(0,1,0,1)
	
	# Set up signals from fielders
	for enemy in get_tree().get_nodes_in_group('fielders'):  
		enemy.connect("ball_fielded", _on_ball_fielded_by_fielder)
	
	# Test mesh array
	test_mesh_array()

	

func get_mouse_sz_pos():
	var cam = get_viewport().get_camera_3d()
	var mousepos = get_viewport().get_mouse_position()
	var ppos = cam.project_position(mousepos, -cam.position.z +.6 + 10)
	ppos = $Headon.to_local(ppos)
	var prop_ppos = (sz_z - cam.position.z) / (ppos.z - cam.position.z)
	var cross_sz = prop_ppos * ppos + (1 - prop_ppos) * cam.position
	#printt('TEST POSITION MOUSE', mousepos,ppos, cross_sz, cam.position)
	return cross_sz

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#printt('get_mouse_z', get_mouse_sz_pos())
	
	# R key reloads
	if Input.is_action_just_pressed("reload"):
		print('reload')
		get_tree().reload_current_scene()
	
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
					ball_in_play_state = "prereflex"
					# Zero out spin accel
					ball3d.spin_acceleration = Vector3()
					# Create ball velocity
					var exitvelo = 60#randf_range(10,50)
					var vla = randf_range(-1,1)*20+20
					var hla = randf_range(-1,1)*20
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
					
					# Start running after .5 seconds
					var batter = get_node("Headon/Batter3D")
					batter.timer_action = "start_running_after_hit"
					batter.get_node("Timer").wait_time = 0.5
					batter.get_node("Timer").start()
					
					
					# Change camera
					$TimerCameraChange.wait_time = .3
					next_camera = $Headon/Camera3DHighHome
					$TimerCameraChange.start()
					#$Headon/Camera3DHighHome.current = true
					# Make ball bigger
					#ball3d.scale=11*Vector3(1,1,1)
					
					
				else:
					pass #print('MISSED')
	if ball_in_play:
		ball_in_play_state_time += delta
		
		if ball_in_play_state == "prereflex" and ball_in_play_state_time > .4:
			printt("REACT NOW")
			ball_in_play_state = "prefield"
			ball_in_play_state_time = 0
			var fielder_nodes = get_tree().get_nodes_in_group('fielders')
			printt('fielder nodes', fielder_nodes)
			assign_fielders_after_hit()
	
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
			get_node("Headon/Camera3DBatting").current = true
		elif Input.is_key_pressed(KEY_2):
			get_node("Headon/Camera3DHighHome").current = true
		elif Input.is_key_pressed(KEY_3):
			get_node("Headon/Camera3DPitcherShoulderRight").current = true
		elif Input.is_key_pressed(KEY_4):
			get_node("Headon/Camera3DAll22").current = true

var tmp_ball
var ball_3d_scene = load("res://ball_3d.tscn")
func assign_fielders_after_hit():
	#printt("Starting assign_fielders_after_hit !!")
	var fielder_nodes = get_tree().get_nodes_in_group('fielders')
	#printt('fielder nodes', fielder_nodes)
	var ball = get_node_or_null("Headon/Ball3D")
	tmp_ball = ball_3d_scene.instantiate()
	tmp_ball.name = "tmp_ball"
	get_node("Headon").add_child(tmp_ball)
	#printt('tmp_ball', tmp_ball)
	tmp_ball.position = ball.position
	#printt('balls global pos', tmp_ball.global_position, ball.global_position)
	tmp_ball.velocity = ball.velocity
	tmp_ball.pitch_already_done = true 
	#printt('pos before', tmp_ball.position)
	#tmp_ball._physics_process(1)
	#printt('pos after', tmp_ball.position)
	var take_steps = func(nsteps, delta):
		for istep in range(nsteps):
			tmp_ball._physics_process(delta)
	# Check every ~.5 second to see if each fielder can reach the ball
	var iii = 0
	var numsteps = 5
	var delta = 1./30
	var elapsed_time = 0
	var found_someone = false
	var min_timetoreach = 1e9
	var min_ifielder
	while iii < 100:
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
					printt('found fielder to field', elapsed_time, fielderi.position, tmp_ball.position)
					#fielderi.assign_to_field_ball(tmp_ball.position)
					if timetoreach < min_timetoreach:
						min_timetoreach = timetoreach
						min_ifielder = ifielder
						found_someone = true
		if found_someone:
			fielder_nodes[min_ifielder].assign_to_field_ball(tmp_ball.position)
			break
	if not found_someone:
		print('no fielder found')
	# Delete object at end
	tmp_ball.velocity = Vector3()
	get_node("Headon").remove_child(tmp_ball)
	tmp_ball.queue_free()


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
	var runner_node = get_node("Headon/Runner3DHome")
	runner_node.set_process(true)
	runner_node.visible = true
	runner_node.is_running = true
	runner_node.running_progress = .04
	
	# Turn off batter
	get_node("Headon/Batter3D").visible = false
	get_node("Headon/Batter3D").set_process(false)
