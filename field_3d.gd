extends Node3D

var contact_done = false
var ball_in_play = false
var ball_in_play_state = null
var ball_in_play_state_time = 0
const sz_z = 0.6
var is_foul_ball:bool = false

var outs_per_inning = 3
var outs_on_play = 0
var outs_before_play = 0
var runs_on_play = 0
var max_force_outs_at_start:int
var max_force_outs_left:int

var user_is_pitching_team = true
var user_is_batting_team = !true

var is_frozen: bool = false
var time_last_decide_automatic_runners_actions = Time.get_ticks_msec() - 10*1e3

@onready var runners = [
	get_node('Headon/Runners/Runner3DHome'),
	get_node('Headon/Runners/Runner3D1B'),
	get_node('Headon/Runners/Runner3D2B'),
	get_node('Headon/Runners/Runner3D3B')
]
@onready var fielders = get_tree().get_nodes_in_group('fielders')
@onready var pitcher = $Headon/Pitcher3D

func record_out(desc : String, duration : float = 3) -> void:
	outs_on_play += 1
	get_node("FlashText").new_text(desc, duration)
	update_max_force_outs_left()

func freeze() -> void:
	# Stop timers
	$Headon/Batter3D/Timer.stop()
	$TimerCameraChange.stop()
	$Headon/Defense/Fielder3DC/Timer.stop()
	$PlayOverTimer.stop()

	# Set children to be frozen
	$Headon/Ball3D.freeze()
	#var fielders = get_tree().get_nodes_in_group('fielders')
	for fielder in fielders:
		fielder.freeze()
	for runner in get_tree().get_nodes_in_group('runners'):
		runner.freeze()
	# Freeze this
	is_frozen = true
	visible = false
	set_process(false)

func pause() -> void:
	# Stop timers
	$Headon/Batter3D/Timer.stop()
	$TimerCameraChange.stop()
	$Headon/Defense/Fielder3DC/Timer.stop()
	$PlayOverTimer.stop()

	# Set children to be frozen
	$Headon/Ball3D.pause()
	#var fielders = get_tree().get_nodes_in_group('fielders')
	for fielder in fielders:
		fielder.pause()
	for runner in runners:
		runner.pause()
	$Headon/Batter3D.pause()
	$Headon/Pitcher3D.pause()
	
	# Pause this
	set_process(false)

func unpause() -> void:
	# Stop timers
	# TODO: restart these if they were running before
	#$Headon/Batter3D/Timer.stop()
	#$TimerCameraChange.stop()
	#$Headon/Defense/Fielder3DC/Timer.stop()
	#$PlayOverTimer.stop()

	# Set children to be frozen
	$Headon/Ball3D.unpause()
	#var fielders = get_tree().get_nodes_in_group('fielders')
	for fielder in fielders:
		fielder.unpause()
	for runner in runners:
		runner.unpause()
	$Headon/Batter3D.unpause()
	$Headon/Pitcher3D.unpause()
	
	# Unpause this
	set_process(true)

func reset(user_is_batting_team_, user_is_pitching_team_,
			batter, pitcher_,
			runner1, runner2, runner3,
			outs_before_play_,
			outs_per_inning_:int,
			fielding_team,
			batting_team,
			fielding_team_is_home:bool):
	printt('--------\n---- in field_3d reset\n--------')
	# Reset children
	$Headon/Ball3D.reset()
	printt('after field/ball reset', $Headon/Ball3D.hit_bounced)
	#var fielders = get_tree().get_nodes_in_group('fielders')
	for fielder in fielders:
		fielder.reset(fielding_team.color_primary)
		fielder.setup_player(fielding_team.roster[0], fielding_team, fielding_team_is_home)
		#printt('fielder posname is', fielder.posname)
		if fielder.posname in ["C", "P"]:
			fielder.visible = false
			#printt('INVISIBLE CATCHER')
	#var runners = get_tree().get_nodes_in_group('runners')
	for runner in runners:
		runner.reset(batting_team.color_primary)
		if runner.start_base == 0:
			runner.visible = false
			runner.setup_player(batter, batting_team, !fielding_team_is_home)
			#printt('INVISIBLE RUNNER 0')
		if runner.start_base == 1:
			runner.setup_player(runner1, batting_team, !fielding_team_is_home)
		elif runner.start_base == 2:
			runner.setup_player(runner2, batting_team, !fielding_team_is_home)
		elif runner.start_base == 3:
			runner.setup_player(runner3, batting_team, !fielding_team_is_home)
		else:
			assert(runner.start_base == 0)
	$Headon/Batter3D.reset(batting_team.color_primary)
	$Headon/Batter3D.setup_player(batter, batting_team, !fielding_team_is_home)
	$Headon/Pitcher3D.reset(fielding_team.color_primary)
	$Headon/Pitcher3D.setup_player(pitcher_, fielding_team, fielding_team_is_home)
	$Headon/Cameras/Camera3DBatting.current = true
	var mgl = get_node("Headon/MouseGroundLocation")
	mgl.visible = false
	mgl.set_process(false)
	if user_is_batting_team_:
		$Headon/Bat3D.visible = true
		$Headon/Bat3D.get_node("Sprite3D").visible = true
		$Headon/Bat3D.set_process(true)
	else:
		$Headon/Bat3D.visible = false
		$Headon/Bat3D.get_node("Sprite3D").visible = false
		$Headon/Bat3D.set_process(false)
	if user_is_pitching_team_:
		$Headon/CatchersMitt.visible = true
		$Headon/CatchersMitt.get_node("Sprite3D").visible=true
		$Headon/CatchersMitt.set_process(true)
	else:
		$Headon/CatchersMitt.visible = false
		$Headon/CatchersMitt.get_node("Sprite3D").visible=false
		$Headon/CatchersMitt.set_process(false)
	$Headon/Cameras.reset()
	$Headon/BallBounceAnnulus.visible = false

	# Reset this
	is_frozen = false
	#printt('in field_3d reset', $Headon/Defense/Fielder3DC.visible)
	visible = true
	set_process(true)
	# Reset vars
	time_since_check_if_play_done_checked = 0
	time_since_play_done_consecutive = 0
	contact_done = false
	is_foul_ball = false
	ball_in_play = false
	ball_in_play_state = null
	ball_in_play_state_time = 0
	ball_hit_bounced = false
	ball_caught_in_air = false
	outs_on_play = 0
	outs_before_play = outs_before_play_
	outs_per_inning = outs_per_inning_
	runs_on_play = 0
	user_is_batting_team = user_is_batting_team_
	user_is_pitching_team = user_is_pitching_team_
	rotate_camera_inertia = Vector2(0,0)
	#_ready()
	# Align fielders with the camera
	get_tree().call_group('fielders', 'align_sprite')
	# Set this to be an old time
	time_last_decide_automatic_runners_actions = Time.get_ticks_msec() - 10*1e3
	
	# Calculate max force outs left
	max_force_outs_at_start = 99
	update_max_force_outs_left()
	max_force_outs_at_start = max_force_outs_left
	assert(max_force_outs_at_start <= 4)
	
	# Set variables in children
	$Headon/Pitcher3D.user_is_pitching_team = user_is_pitching_team
	for fielder in fielders:
		fielder.user_is_pitching_team = user_is_pitching_team
	if not user_is_pitching_team:
		$Headon/CatchersMitt.visible = false
		$Headon/Pitcher3D/PitchSelectKeyboard.visible = false
	$Headon/Batter3D.user_is_batting_team = user_is_batting_team
	if not user_is_batting_team:
		$Headon/Bat3D.visible = false
	
	# Set if runners can be force out
	runners[0].can_be_force_out_before_play = true
	if runners[1].exists_at_start:
		runners[1].can_be_force_out_before_play = true
		if runners[2].exists_at_start:
			runners[2].can_be_force_out_before_play = true
			if runners[3].exists_at_start:
				runners[3].can_be_force_out_before_play = true
		
	
	#print('in field reset: printing batter')
	#batter.print_()
	printt('after field full reset', $Headon/Ball3D.hit_bounced, ball_hit_bounced)

func _on_ball_fielded_by_fielder(_fielder):
	var ball = get_node("Headon/Ball3D")
	#printt("in field: Ball fielded", ball.state, ball.hit_bounced)
	if ball.state == "ball_in_play" and not ball.hit_bounced:
		ball_caught_in_air = true
		printt("fly Out recorded!!!")
		#outs_on_play += 1
		#get_node("FlashText").new_text("Fly out!", 3)
		get_node("Headon/Runners/Runner3DHome").runner_is_out()
		record_out("Fly out!")
		
		#var runners = get_tree().get_nodes_in_group('runners')
		for runner in runners:
			runner.needs_to_tag_up = true
			runner.tagged_up_after_catch = runner.running_progress - runner.start_base < 1e-8
	
	# Do this last so that the type of out can be determined
	ball.ball_fielded()
	
	# Reassign other fielders to cover bases (only really needed when fielder assigned
	#   to a base go the ball
	assign_fielders_to_cover_bases([], null, [_fielder.posname])
#
	## TODO: If CPU is defense, decide where to throw
	#var throw_to = -1
	#if not user_is_pitching_team:
		#print('CPU decide what to do with ball now')
		## Check for active runners
		#var runners = get_tree().get_nodes_in_group("runners")
		#for runner in runners:
			#if runner.is_active():
				##printt('fielder is', fielder)
				#if runner.is_running and runner.target_base > runner.running_progress:
					#throw_to = max(throw_to, runner.target_base)
					#printt('could throw out runner', runner.target_base, runner.out_on_play)
		#printt("in field: ball will be thrown to", throw_to)
		#if throw_to > -0.5:
			#fielder.throw_ball_func(throw_to)
	
	$Headon/BallBounceAnnulus.visible = false



func _on_throw_ball_by_fielder(base, fielder, to_fielder, success) -> void:
	printt('In field_3d, throwing ball to:', base, fielder, to_fielder)

	# Set ball throw
	var ball = get_node("Headon/Ball3D")
	var target
	if base != null:
		if base == 1:
			target = Vector3(-1,0,1)*30/sqrt(2) + Vector3(0,1.4,0)
		elif base == 2:
			target = Vector3(0,0,1)*30*sqrt(2) + Vector3(0,1.4,0)
		elif base == 3:
			target = Vector3(1,0,1)*30/sqrt(2) + Vector3(0,1.4,0)
		elif base == 4:
			target = Vector3(0,0,0) + Vector3(0,1.4,0)
		else:
			printerr('should not happen bad throw to')
		target.y = 1
	elif to_fielder != null:
		target = to_fielder.position
		target.y = 1.4
	else:
		assert(false)
	#printt('target is', target, 'fielder pos is', fielder.position)
	#var velo_vec = fielder.max_throw_speed * (target - fielder.position).normalized()
	var ball_start = fielder.position
	ball_start.y = 1.4
	
	# If throw is not success, add noise
	if success:
		target.x += randf_range(-.2,.2)
		target.y += randf_range(-.2,.2)
		target.z += randf_range(-.2,.2)
	else:
		#printt('in field throw is not success')
		target.x += randf_range(-2,2)*2
		target.y += randf_range(-2,2)*2
		target.z += randf_range(-2,2)*2
	
	var velo_vec = ball.fit_approx_parabola_to_trajectory(ball_start, target, fielder.max_throw_speed, true)
	
	# TODO: Rotate for bad throws, instead of changing target above
	# If throw is not success, add noise
	#if success:
		#var v1 = velo_vec.normalized
		#velo_vec = velo_vec.rotated()
	
	if base != null:
		ball.throw_to_base(base, velo_vec, fielder.position, target)
	else:
		ball.throw_to_base(null, velo_vec, fielder.position, target)
	
	
	# Set new assignments
	assign_fielders_to_cover_bases([], null)
	
	# Set new targeted fielder
	if to_fielder != null:
		to_fielder.set_targeted_fielder()
	else:
		# Thrown to base. Find nearest fielder to target. Should
		var nearest_fielder = null
		var nearest_fielder_dist = 1e12
		for fielder_ in fielders:
			if fielder_.distance_xz(fielder_.position, target) < nearest_fielder_dist:
				nearest_fielder_dist = fielder_.distance_xz(fielder_.position, target)
				nearest_fielder = fielder_
		nearest_fielder.set_targeted_fielder()


func _on_stepped_on_base_with_ball_by_fielder(_fielder, base):
	# Check for force out
	#printt('in field3D, stepped on base with ball!!!!')
	#var runners = get_tree().get_nodes_in_group("runners")
	for runner in runners:
		# Check for tag up force outs
		if (base == runner.start_base and runner.exists_at_start and runner.is_active() and
			runner.needs_to_tag_up and not runner.tagged_up_after_catch):
			runner.runner_is_out()
			#outs_on_play += 1
			#get_node("FlashText").new_text("force out, didn't tag up!", 3)
			record_out("Force out, didn't tag up!")
			continue
		
		# Force out
		if (runner.exists_at_start and
			runner.start_base == base - 1 and
			not runner.out_on_play and 
			runner.is_active() and 
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
				#outs_on_play += 1
				#get_node("FlashText").new_text("force out!", 3)
				record_out('Force out!')
				#runner.runner_is_out()
			#else:
			#	printt('not force out, prev runner not there')
	return

func _on_tag_out_by_fielder():
	#outs_on_play += 1
	#get_node("FlashText").new_text("tag out!", 3)
	record_out('Tag out!')

func _on_new_fielder_selected_signal_by_fielder(fielder):
	assign_fielders_to_cover_bases([], null, [fielder.posname])

func _on_fielder_moved_reassign_fielders_by_fielder(fielder):
	assign_fielders_to_cover_bases([], null, [fielder.posname])

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
	printt('in field_3d ready', $Headon/Defense/Fielder3DC.visible)
	
	#get_node('Headon/Batter3D/AnimatedSprite3DIdle').modulate = Color(0,1,0,1)
	#var fielder_nodes = get_tree().get_nodes_in_group('fielders')
	# Set up signals from fielders
	for fielder in fielders:  
		fielder.connect("ball_fielded", _on_ball_fielded_by_fielder)
		fielder.connect("throw_ball", _on_throw_ball_by_fielder)
		fielder.connect("stepped_on_base_with_ball", _on_stepped_on_base_with_ball_by_fielder)
		fielder.connect("tag_out", _on_tag_out_by_fielder)
		fielder.connect("new_fielder_selected_signal", _on_new_fielder_selected_signal_by_fielder)
		fielder.connect("fielder_moved_reassign_fielders_signal", _on_fielder_moved_reassign_fielders_by_fielder)

	#var runners = get_tree().get_nodes_in_group('runners')
	# Set up signals from runners
	for runner in runners:  
		runner.connect("signal_scored_on_play", _on_signal_scored_on_play_by_runner)
		runner.connect("reached_next_base_signal", _on_reached_next_base_by_runner)
		runner.connect("tag_up_signal", _on_tag_up_by_runner)
	
	pitcher.connect("pitch_started", _on_pitcher_3d_pitch_started)
	pitcher.connect("pitch_released_signal", _on_pitcher_3d_pitch_released)
	
	# Test mesh array
	#test_mesh_array()
	

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

var rotate_camera_inertia:Vector2 = Vector2(0,0)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_frozen:
		return

	#if randf_range(0,1) < 1./1000:
		#printt('in field_3d, frame rate', (1./delta))
	#printt('get_mouse_z', get_mouse_sz_pos())
	#printt('get_mouse_y0', get_mouse_y0_pos())
	
	
	# R key reloads
	if Input.is_action_just_pressed("reload"):
		print('reload')
		get_tree().reload_current_scene()
		return
	
	# Pause game
	if Input.is_action_just_pressed("startbutton"):
		print('start button pressed')
		if get_tree().paused:
			_on_resume_button_pressed()
		else:
			_on_pause_button_pressed()
	#if Input.is_key_pressed(KEY_P):
		#Engine.time_scale = randf_range(.1,10)
	
	# Check for contact on swing
	if not contact_done and get_node_or_null("Headon/Ball3D")!=null:
		var ball3d = $Headon/Ball3D
		#print('found ball')
		# pitch is active
		if ball3d.velocity.length() > 0:
			if $Headon/Batter3D.swing_state == "inzone":
				#if (sz_z - ball3d.position.z)**2 < 1**2:
				if ball3d.position.z <= sz_z and ball3d.prev_position.z > sz_z:
					# Ball crossed the strike zone and batter is swinging.
					# Check if there is actual contact
					var actual_contact = true
					
					# Create ball velocity
					var exitvelo = randf_range(20,45)
					var vla = randf_range(-1,1)*20+20
					var hla = randf_range(-1,1)*20
					var inzone_prop = ($Headon/Batter3D.swing_elapsed_sec - 
						$Headon/Batter3D.swing_prezone_duration) / $Headon/Batter3D.swing_inzone_duration
					if inzone_prop < 0 or inzone_prop > 1:
						push_error("Error with inzone_prop", inzone_prop)
					#vla = -20
					#vla = randf_range(-1,1)*40 + 20
					hla = -45 + 90 * inzone_prop
					if $Headon/Batter3D.bats == 'L':
						hla *= -1
					var pci:Vector3 = Vector3.ZERO
					if user_is_batting_team:
						# Find distance from PCI to ball location
						pci = $Headon/Bat3D.position
					else:
						pci = ball3d.position
						pci.x += randfn(0, .5)
						pci.y += randfn(0, .5)
					# Set vla and exitvelo based on pci
					var pci_distance_from_ball = fielders[0].distance_xz(pci, ball3d.position)
					# If PCI wasn't close, it's a swing and miss
					if pci_distance_from_ball > 1:
						actual_contact = false
					vla = 15 + [1,-1].pick_random() * pci_distance_from_ball * 80
					vla = max(-50, min(80, vla))
					printt('pci is', pci, ball3d.position, pci_distance_from_ball, vla)
					# Debugging
					if !false:
						vla = -5
						hla = 40
						exitvelo = 43.8
					printt('hit exitvelo/vla/hla:', exitvelo, vla, hla)
					
					if actual_contact:
						print('CONTACT')
						contact_done = true
						ball_in_play = true
						ball3d.pitch_in_progress = false
						ball3d.pitch_already_done = true
						ball_in_play_state = "prereflex"
						# Zero out spin accel
						ball3d.spin_acceleration = Vector3()
						# Start with velo all in Z direction, then rotate with vla/hla
						ball3d.velocity.x = 0
						ball3d.velocity.y = 0
						ball3d.velocity.z = exitvelo
						ball3d.velocity = ball3d.velocity.rotated(Vector3(-1,0,0), (vla)*PI/180)
						ball3d.velocity = ball3d.velocity.rotated(Vector3(0,1,0), -(hla)*PI/180)
						printt('hit velo vec is', ball3d.velocity)
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
						# Hide strike zone dot at same time
						ball3d.remove_dot(.3)
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
					else: # Not actual contact
						printt("Swing and a miss due to bad PCI!")
					
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
			#var hit_will_bounce = assign_fielders_after_hit()
			# [found_someone, hit_bounced, min_ifielder, intercept_position,
			#elapsed_time, hit_bounced_position, hit_bounced_time]
			var fftib = assign_fielders_after_hit()
			var hit_will_bounce = fftib[1]
			printt('Will hit bounce?', hit_will_bounce)
			if hit_will_bounce:
				#printt("hit will bounce, send runners!!")
				#var runners = get_tree().get_nodes_in_group("runners")
				for runner in runners:
					#runner.is_running = true
					runner.send_runner(1)
					#printt('runner details', runner.target_base, runner.running_progress)
			else:
				#var runners = get_tree().get_nodes_in_group("runners")
				for runner in runners:
					runner.send_runner(-1)
			# Set ball land annulus
			$Headon/BallBounceAnnulus.position = fftib[5]
			$Headon/BallBounceAnnulus.visible = true
	
	# Move baserunners
	if ball_in_play:
		if user_is_batting_team:
			if Input.is_action_just_pressed("throwfirst"):
				#
				pass
			elif Input.is_action_just_pressed("throwsecond"):
				# Move all forward
				#var runners = get_tree().get_nodes_in_group("runners")
				for runner in runners:
					runner.send_runner(1)
			elif Input.is_action_just_pressed("throwthird"):
				pass
			elif Input.is_action_just_pressed("throwhome"):
				# Move all forward
				#var runners = get_tree().get_nodes_in_group("runners")
				for runner in runners:
					runner.send_runner(-1)
		else:
			#if randf_range(0,1) < .1:
			if Time.get_ticks_msec() - time_last_decide_automatic_runners_actions > 100:
				decide_automatic_runners_actions()
	
	# Adjust camera
	var cam = get_viewport().get_camera_3d()
	if get_viewport():
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
	
	# Move camera so that the ball stays in view
	cam = get_viewport().get_camera_3d()
	var ball_viewport_2d_position = cam.unproject_position(get_node_or_null("Headon/Ball3D").global_position)
	var viewport_size = get_viewport().size
	#if randf_range(0,1)< .1:
		#printt("TEST BALL 2d loc:", cam.unproject_position(get_node_or_null("Headon/Ball3D").global_position),
		#       get_viewport().size, cam.rotation)
	if ball_in_play:
		# Using inertia instead of changing angle based on single frames reduces jitter
		rotate_camera_inertia = .95 * rotate_camera_inertia
		var rotate_camera_inertia_increment = .05
		var rotate_speed = 0.1
		var rot_axis_y = cam.rotation
		rot_axis_y.y = 0
		rot_axis_y = rot_axis_y.normalized()
		var cam_rotated = false
		if ball_viewport_2d_position.x < viewport_size.x*.2: # Rotate left
			#cam.rotate(Vector3(0,1,0), delta * rotate_speed)
			#cam_rotated = true
			rotate_camera_inertia.x -= rotate_camera_inertia_increment
		if ball_viewport_2d_position.x > viewport_size.x*.8: # Rotate right
			#cam.rotate(Vector3(0,1,0), -delta * rotate_speed)
			#cam_rotated = true
			rotate_camera_inertia.x += rotate_camera_inertia_increment
		if ball_viewport_2d_position.y < viewport_size.y*.1: # Rotate up
			#cam.rotate(rot_axis_y, delta * rotate_speed)
			#cam_rotated = true
			rotate_camera_inertia.y += rotate_camera_inertia_increment
		if ball_viewport_2d_position.y > viewport_size.y*.5: # Rotate down
			#cam.rotate(rot_axis_y, -delta * rotate_speed)
			#cam_rotated = true
			rotate_camera_inertia.y -= rotate_camera_inertia_increment
		if abs(rotate_camera_inertia.x) > 1e-12:
			cam.rotate(Vector3(0,1,0), -delta * rotate_speed * rotate_camera_inertia.x)
			cam_rotated = true
		if abs(rotate_camera_inertia.y) > 1e-12:
			cam.rotate(rot_axis_y, delta * rotate_speed * rotate_camera_inertia.y)
			cam_rotated = true
			
		if cam_rotated:
			# TODO: Not sure this does anything usefuL
			transform = transform.orthonormalized()
		# TODO: Rotate camera to be level

	# Check if play is done, but not every time
	if ball_in_play:
		time_since_check_if_play_done_checked += delta
		if time_since_check_if_play_done_checked > .5:
			if check_if_play_done():
				printt('ball in play and play is done')
				time_since_play_done_consecutive += .5
				if time_since_play_done_consecutive > .6:
					#play_done_fully = true
					#get_node("FlashText").new_text("Play is done!", 3)
					#get_tree().reload_current_scene()
					play_done()
			else:
				time_since_play_done_consecutive = 0

var tmp_ball
var ball_3d_scene = load("res://ball_3d.tscn")

func find_fielder_to_intercept_ball() -> Array:
	#func assign_fielders_after_hit():
	#printt("\t\t\t\tStarting assign_fielders_after_hit !!")
	#var fielder_nodes = get_tree().get_nodes_in_group('fielders')
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
	tmp_ball.hit_bounced_position = ball.hit_bounced_position
	tmp_ball.hit_bounced_time = ball.hit_bounced_time
	
	#printt('pos before', tmp_ball.position)
	#tmp_ball._physics_process(1)
	#printt('pos after', tmp_ball.position)
	var take_steps = func(nsteps, delta_):
		for istep in range(nsteps):
			tmp_ball._physics_process(delta_)
			#if hit_bounce_position==null:
				#if tmp_ball.hit_bounced:
					#print("FOUND WHERE BALL HITS GROUND IN TMP_BALL")
					#hit_bounce_position = tmp_ball.position
					#hit_bounce_time = elapsed_time + istep * delta_
	# Check every ~.5 second to see if each fielder can reach the ball
	var iii = 0
	var numsteps = 1
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
			for ifielder in range(len(fielders)):
				var fielderi = fielders[ifielder]
				var ballgrounddist = fielderi.distance_xz(fielderi.position, tmp_ball.position)
				# TODO: fielders don't run at constant speed
				var timetoreach = max(0, (ballgrounddist - fielderi.catch_radius_xz) / fielderi.SPEED)
				#if fielderi.posname == 'C':
				#	print('checking fielder time', timetoreach, fielderi.time_to_reach_point(tmp_ball.position))
				
				if timetoreach <= elapsed_time:
					#printt('found fielder to field', elapsed_time, fielderi.position, tmp_ball.position)
					#fielderi.assign_to_field_ball(tmp_ball.position)
					#printt('ball bounced???', tmp_ball.hit_bounced, tmp_ball.state)
					if timetoreach < min_timetoreach:
						min_timetoreach = timetoreach
						min_ifielder = ifielder
						found_someone = true
			if found_someone:
				#fielders[min_ifielder].assign_to_field_ball(tmp_ball.position)
				break
	
	# Save important things to return
	var intercept_position = tmp_ball.position
	var hit_bounced = tmp_ball.hit_bounced
	for iiii in range(1e3):
		if tmp_ball.hit_bounced_position == null:
			tmp_ball._physics_process(1./60)
			if tmp_ball.elapsed_time > 10:
				break
		else:
			#printt("FOUND BALL BOUNCE!!!")
			break
	if tmp_ball.hit_bounced_position == null:
		printt("COULDN'T FIND BALL BOUNCE!!!", tmp_ball.state)
	var hit_bounced_position = tmp_ball.hit_bounced_position
	var hit_bounced_time = tmp_ball.hit_bounced_time
	#printt('BALL SIM FOUND HIT INFO', hit_bounced_position, hit_bounced_time)

	# Delete object at end
	tmp_ball.velocity = Vector3()
	get_node("Headon").remove_child(tmp_ball)
	#var tmp_ball_bounced = tmp_ball.hit_bounced
	tmp_ball.queue_free()
	
	#for i in range(3):
		#print('------- done with tmp_ball')
	
	return [found_someone, hit_bounced, min_ifielder, intercept_position,
			elapsed_time, hit_bounced_position, hit_bounced_time]
	#return [found_someone, ball_will_bounce, fielder name, intercept position, seconds_to_intercept]


func assign_fielders_after_hit() -> Array:
	# Returns whether ball will bounce before fielder intercepts
	# [found_someone, ball_will_bounce, fielder name, intercept position, seconds_to_intercept]
	var fftib = find_fielder_to_intercept_ball()
	var found_someone = fftib[0]
	#var tmp_ball_bounced = fftib[1]
	var min_ifielder = fftib[2]
	var intercept_position = fftib[3]
	if found_someone:
		fielders[min_ifielder].assign_to_field_ball(intercept_position)
		#break

	if not found_someone:
		print('no fielder found')
	if found_someone:
		# Assign someone to cover base
		#printt('fielder assigned name:', fielder_nodes[min_ifielder].name, fielder_nodes[min_ifielder].posname)
		#for ifielder in fielder_nodes:
		if fielders[min_ifielder].posname == "2B":
			get_fielder_with_posname("1B").assign_to_cover_base(1)
			get_fielder_with_posname("SS").assign_to_cover_base(2)
			get_fielder_with_posname("3B").assign_to_cover_base(3)
			get_fielder_with_posname("C").assign_to_cover_base(4)
		elif fielders[min_ifielder].posname == "SS":
			get_fielder_with_posname("1B").assign_to_cover_base(1)
			get_fielder_with_posname("2B").assign_to_cover_base(2)
			get_fielder_with_posname("3B").assign_to_cover_base(3)
			get_fielder_with_posname("C").assign_to_cover_base(4)
		elif fielders[min_ifielder].posname == "1B":
			get_fielder_with_posname("P").assign_to_cover_base(1)
			get_fielder_with_posname("SS").assign_to_cover_base(2)
			get_fielder_with_posname("3B").assign_to_cover_base(3)
			get_fielder_with_posname("C").assign_to_cover_base(4)
		elif fielders[min_ifielder].posname == "3B":
			get_fielder_with_posname("1B").assign_to_cover_base(1)
			get_fielder_with_posname("2B").assign_to_cover_base(2)
			get_fielder_with_posname("SS").assign_to_cover_base(3)
			get_fielder_with_posname("C").assign_to_cover_base(4)
		elif fielders[min_ifielder].posname == "P":
			get_fielder_with_posname("1B").assign_to_cover_base(1)
			get_fielder_with_posname("2B").assign_to_cover_base(2)
			get_fielder_with_posname("3B").assign_to_cover_base(3)
			get_fielder_with_posname("C").assign_to_cover_base(4)
		elif fielders[min_ifielder].posname == "C":
			get_fielder_with_posname("1B").assign_to_cover_base(1)
			get_fielder_with_posname("2B").assign_to_cover_base(2)
			get_fielder_with_posname("3B").assign_to_cover_base(3)
			get_fielder_with_posname("P").assign_to_cover_base(4)
		elif fielders[min_ifielder].posname in ["LF", "CF", "RF"]:
			get_fielder_with_posname("1B").assign_to_cover_base(1)
			get_fielder_with_posname("3B").assign_to_cover_base(3)
			get_fielder_with_posname("C").assign_to_cover_base(4)
			if tmp_ball.position.x > 0:
				get_fielder_with_posname("2B").assign_to_cover_base(2)
				get_fielder_with_posname("SS").assign_to_cover_base(5, intercept_position)
			else:
				get_fielder_with_posname("SS").assign_to_cover_base(2)
				get_fielder_with_posname("2B").assign_to_cover_base(5, intercept_position)
			
	
	# Return whether the ball bounced. Will be used to determine if runners run.
	#return tmp_ball_bounced
	return fftib

func assign_fielders_to_cover_bases(exclude_fielder_indexes:Array=[],
									_intercept_position=null,
									exclude_fielder_posname_array:Array=[]) -> void:
	printt('Running assign_fielders_to_cover_bases')
	var assigned_indexes = []
	for base in [2,1,3,4]:
		var min_time = 1e10
		var min_i = null
		var min_is_excluded = false
		for i in range(len(fielders)):
			if i in exclude_fielder_indexes or exclude_fielder_posname_array.has(fielders[i].posname):
				# Only include the excluded ones if they are super close
				if fielders[i].distance_xz(
					fielders[i].position,
					fielders[i].base_positions[base-1]
				) < 1:
					printt('ASSIGNING CLOSE ENOUGH EXCLUDED', fielders[i].posname,
							base, exclude_fielder_indexes, exclude_fielder_posname_array)
					min_time = 0
					min_i = i
					min_is_excluded = true
			else:
				var fielder_time = (
					fielders[i].distance_xz(fielders[i].position,
											fielders[i].base_positions[base-1]) /
					fielders[i].SPEED)
				if fielder_time < min_time:
					min_time = fielder_time
					min_i = i
		if min_i != null:
			if min_is_excluded:
				pass
			else:
				#printt('Assigning fielder to cover base', fielders[min_i].posname, base)
				fielders[min_i].assign_to_cover_base(base)
			exclude_fielder_indexes.push_back(min_i)
			assigned_indexes.push_back(min_i)
		else:
			printt('NO ONE ASSIGNED TO A BASE')
	
	# All fielders that were previously assigned to base and haven't reached it
	#   and weren't assigned this time to just wait
	for i in range(len(fielders)):
		if fielders[i].assignment == 'cover' and not assigned_indexes.has(i):
			fielders[i].assignment = 'wait_to_receive'
	
	return

func get_fielder_with_posname(posname):
	var f1 = fielders.filter(func(f): return f.posname == posname)
	#printt('in get_fielders_with_posname',fielders, posname, f1)
	assert(len(f1) == 1)
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
	runner_node.set_animation('running')
	
	# Turn off batter
	get_node("Headon/Batter3D").visible = false
	get_node("Headon/Batter3D").set_process(false)

func _on_pause_button_pressed():
	get_tree().paused = true
	#show()

func _on_resume_button_pressed():
	get_tree().paused = false

func _on_pitcher_3d_pitch_started(_pitch_x, _pitch_y, _pitch_t) -> void:
	# Replaced with pitch_released since pitch_t isn't known until then
	##printt('in field, pitch started!!!!!!!!!!!!!!!!!')
	#if not user_is_batting_team:
		#get_node("Headon/Batter3D").timer_action = 'begin_swing'
		#get_node("Headon/Batter3D/Timer").wait_time = $Headon/Pitcher3D.time_until_pitch_release + pitch_t
		#get_node("Headon/Batter3D/Timer").start()
	pass

func _on_pitcher_3d_pitch_released(_pitch_x, _pitch_y, pitch_t) -> void:
	printt('in field, _on_pitcher_3d_pitch_released', pitch_t)
	if not user_is_batting_team:
		get_node("Headon/Batter3D").timer_action = 'begin_swing'
		# Need to start swing before pitch arrives
		get_node("Headon/Batter3D/Timer").wait_time = (
			pitch_t - 
			$Headon/Batter3D.swing_prezone_duration -
			0.5 * $Headon/Batter3D.swing_inzone_duration )
		get_node("Headon/Batter3D/Timer").start()

var time_since_check_if_play_done_checked = 0
var time_since_play_done_consecutive = 0
#var play_done_fully = false
func check_if_play_done():
	time_since_check_if_play_done_checked = 0
	
	# Check if 3 outs
	# TODO: play should immediately end, no one else should get out, but scene shouldn't immediately reset
	if outs_before_play + outs_on_play > outs_per_inning - 0.5:
		play_done()
		return true
	
	# Check if runners aren't running and are near base
	#var runners = get_tree().get_nodes_in_group("runners")
	var n_runners_active:int = 0
	for runner in runners:
		if not runner.is_done_for_play():
			return false
		if runner.is_active():
			n_runners_active += 1
		#if runner.exists_at_start:
			#if runner.is_running:
				#return false
			#if runner.is_active() and abs(runner.running_progress - round(runner.running_progress)) > 1e-4:
				#return false
	if n_runners_active == 0:
		return true
	# None are running, all are near base
	# Check if fielder is holding ball
	#var fielders = get_tree().get_nodes_in_group("fielders")
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

signal signal_play_done(is_ball: bool, is_strike: bool, outs_on_play: int, runs_on_play: int)
func play_done(flash=null):
	printt('in field: running play_done()')
	#play_done_fully = true
	if flash != null:
		get_node("FlashText").new_text(flash, 3)
	#get_tree().reload_current_scene()
	freeze()
	# Check for swing and miss
	if pitch_is_ball:
		if $Headon/Batter3D.swing_started:
			pitch_is_ball = false
			pitch_is_strike = true
	signal_play_done.emit(ball_in_play, pitch_is_ball, pitch_is_strike, is_foul_ball,
	outs_on_play, runs_on_play,
	$Headon/Runners/Runner3DHome.end_state(),
	$Headon/Runners/Runner3D1B.end_state(),
	$Headon/Runners/Runner3D2B.end_state(),
	$Headon/Runners/Runner3D3B.end_state())

func _on_play_over_timer_timeout() -> void:
	$PlayOverTimer.stop()
	play_done()

func _on_ball_3d_ball_overthrown() -> void:
	assign_fielders_after_hit()


var pitch_is_ball:bool = false
var pitch_is_strike:bool = false
func _on_ball_3d_pitch_completed_unhit(pitch_is_ball_:bool, pitch_is_strike_:bool) -> void:
	pitch_is_ball = pitch_is_ball_
	pitch_is_strike = pitch_is_strike_
	assert(int(pitch_is_ball_) + int(pitch_is_strike_) == 1)
	$PlayOverTimer.wait_time = 1
	$PlayOverTimer.start()

func _on_signal_scored_on_play_by_runner() -> void:
	runs_on_play += 1
	get_node("FlashText").new_text("Run scored!", 3)

func _on_ball_3d_foul_ball() -> void:
	is_foul_ball = true
	play_done('Foul ball!')

var ball_hit_bounced:bool = false
var ball_caught_in_air:bool = false
func _on_ball_3d_hit_bounced_signal() -> void:
	printt('In field, _on_ball_3d_hit_bounced_signal, ball_hit_bounced = ', ball_hit_bounced)
	ball_hit_bounced = true
	#check_runners_able_to_score()
	update_max_force_outs_left()
	$Headon/BallBounceAnnulus.visible = false

func _on_reached_next_base_by_runner() -> void:
	# Only for first time they reached the base after start_base
	# Recalculate max force outs left
	update_max_force_outs_left()

func _on_tag_up_by_runner() -> void:
	print('IN TAG UP SIGNAL IN FIELD')
	# Recalculate max force outs left
	update_max_force_outs_left()

func update_max_force_outs_left() -> void:
	printt('In update_max_force_outs_left...')
	if ball_caught_in_air:
		print('.... ball caught in air')
		max_force_outs_left = 0
		# Number of active runners that haven't tagged up
		for i in [1,2,3]:
			if runners[i].is_active() and runners[i].needs_to_tag_up and not runners[i].tagged_up_after_catch:
				max_force_outs_at_start += 1
	elif ball_hit_bounced: # Force out each base if runner exists and all before it
		max_force_outs_left = 0
		if not $Headon/Runners/Runner3DHome.out_on_play:
			if not $Headon/Runners/Runner3DHome.reached_next_base:
				max_force_outs_left += 1
			if $Headon/Runners/Runner3D1B.exists_at_start and not $Headon/Runners/Runner3D1B.out_on_play:
				if not $Headon/Runners/Runner3D1B.reached_next_base:
					max_force_outs_left += 1
				if $Headon/Runners/Runner3D2B.exists_at_start and not $Headon/Runners/Runner3D2B.out_on_play:
					if not $Headon/Runners/Runner3D2B.reached_next_base:
						max_force_outs_left += 1
					if $Headon/Runners/Runner3D3B.exists_at_start and not $Headon/Runners/Runner3D3B.out_on_play:
						if not $Headon/Runners/Runner3D3B.reached_next_base:
							max_force_outs_left += 1
	else: # Possible to catch fly ball and get all runners before tagging
		max_force_outs_left = (
			1 + # Can catch ball to get hitter out
			int($Headon/Runners/Runner3D1B.exists_at_start) +
			int($Headon/Runners/Runner3D2B.exists_at_start) +
			int($Headon/Runners/Runner3D3B.exists_at_start)
		)
	printt('Updated max_force_outs_left: ', max_force_outs_left, ball_hit_bounced)
	assert(max_force_outs_left <= max_force_outs_at_start)
	assert(max_force_outs_left <= 4)
	check_runners_able_to_score()

func check_runners_able_to_score():
	# Able to score means they won't have to return (ball has bounced) and the
	#  max number of force outs left isn't enough to negate their scoring.
	printt('In check_runners_able_to_score, ', outs_before_play, outs_on_play, max_force_outs_left, ball_hit_bounced)
	if (outs_before_play + outs_on_play + max_force_outs_left < outs_per_inning - 0.5 and
		(ball_hit_bounced or ball_caught_in_air)):
		printt('RUNNERS CAN SCORE NOW')
		for runner in runners:
			runner.able_to_score = true

func coalesce_array(x:Array):
	for i in range(len(x) - 1):
		if x[i] != null:
			return x[i]
	return x[-1]

func coalesce(x1, x2=null, x3=null, x4=null, x5=null, x6=null, x7=null, x8=null, x9=null, x10=null):
	return coalesce_array([x1, x2, x3, x4, x5, x6, x7, x8, x9, x10])

func decide_automatic_runners_actions():
	time_last_decide_automatic_runners_actions = Time.get_ticks_msec()
	#print("Running decide_automatic_runners_actions")
	
	# 1. If fielded and need to tag up, do that.
	# 2. If ball can be caught:
	#  a. If can reach next base safely, wait on start base to tag up.
	#  b. Else, go as far as is safe and stop.
	# 3. If they are a force out and not at next base, go there
	# 4. Go to next next base if possible.
	# 5. Go to next base if possible.
	# 6. Stay on current base if possible.
	# 7. Go to previous base if possible.
	# 8. Go to closer of next and previous base.
	# After, make sure that the decisions make sense as a whole, to 
	#  avoid runners trying to pass others.
	
	var ball = get_node("Headon/Ball3D")
	var fielders_with_ball = get_tree().get_nodes_in_group('fielder_holding_ball')
	var decisions = [null, null, null, null]
	var decision_bases = [null, null, null, null]
	assert(len(fielders_with_ball) < 1.5)
	var fielder_with_ball = null
	var fftib = null
	var seconds_to_intercept = 0
	if len(fielders_with_ball) > .5:
		# Some fielder has the ball
		fielder_with_ball = fielders_with_ball[0]
		assert(ball.state == 'fielded')
	else:
		# Ball in play or thrown
		fftib = find_fielder_to_intercept_ball()
		# fftib:
		#[found_someone, hit_bounced, min_ifielder, intercept_position,
			#elapsed_time, hit_bounced_position, hit_bounced_time]
		seconds_to_intercept = fftib[4]


	# 1. If fielded and need to tag up, do that.
	if fielder_with_ball or outs_on_play > 0.5:
		for i in range(len(runners)):
			if i > .5 and runners[i].is_active() and runners[i].needs_to_tag_up and not runners[i].tagged_up_after_catch:
				decisions[i] = coalesce(decisions[i], -1)
				decision_bases[i] = coalesce(decision_bases[i], runners[i].start_base)
		
	# 2. If ball can be caught:
	#  a. If can reach next base safely, wait on start base to tag up.
	#  b. Else, go as far as is safe and stop.
	if fielder_with_ball == null:
		if not ball_hit_bounced and not fftib[1] and outs_before_play < outs_per_inning - 1.5 and outs_on_play < 0.5:
				for i in range(len(runners)):
					if i > .5 and runners[i].is_active() and decisions[i]==null:
						#printt('SENDING BACK, CAN CATCH!!!', i)
						# Check if can tag up
						var time_for_throw_to_get_to_next_base = (
							fielders[fftib[2]].distance_xz(
								fftib[3], # intercept position
								runners[i].base_positions[runners[i].start_base]
							) / fielders[fftib[2]].max_throw_speed
						)
						#printt('ON DECISION STEP 2', i, time_for_throw_to_get_to_next_base > 30./runners[i].SPEED,
								#time_for_throw_to_get_to_next_base , 30./runners[i].SPEED)
						if time_for_throw_to_get_to_next_base > 30./runners[i].SPEED:
							decisions[i] = coalesce(decisions[i], -1)
							decision_bases[i] = coalesce(decision_bases[i], runners[i].start_base)
							# TODO: Make sure runner can get back to tag up in time
						
						# Not really using decisions anymore, but something will be set here
						decisions[i] = coalesce(decisions[i], -1)
						#decision_bases[i] = coalesce(decision_bases[i], runners[i].start_base)
						# Send proportion of the way that they can make it safely back
						var prop_to_run:float = 0
						var time_for_ball_to_get_to_start_base = (
							max(seconds_to_intercept - 1./60, 0) +
							fielders[fftib[2]].distance_xz(
								fftib[3], # intercept position
								runners[i].base_positions[runners[i].start_base-1]
							) / fielders[fftib[2]].max_throw_speed
						)
						# This calculates how far they could be right now and be safe,
						#  but not where they should go to while remaining safe.
						# Baserunner decision is every 0.1 seconds, so calculate where they should
						#  be at that time plus a small margin
						prop_to_run = max(0, time_for_ball_to_get_to_start_base - 0.13) * runners[i].SPEED / 30.
						#if abs(runners[i].start_base-3)<1e-9:
							#printt('calculated prop_to_run', prop_to_run, time_for_ball_to_get_to_start_base,
								#seconds_to_intercept, runners[i].SPEED,
								#'progress:', runners[i].running_progress - runners[i].start_base,
								#Time.get_ticks_msec())
						# Times 0.9 makes them a little conservative
						prop_to_run = min(prop_to_run, runners[i].start_base + 1) * 0.9
						decision_bases[i] = coalesce(decision_bases[i], runners[i].start_base + prop_to_run)
		
	# 3. If they are a force out and not at next base, go there
	for i in range(len(runners)):
		if runners[i].is_active() and runners[i].can_be_force_out() and decisions[i]==null:
			#printt('Runner can be force out', i)
			decisions[i] = coalesce(decisions[i], 1)
			decision_bases[i] = coalesce(decision_bases[i], runners[i].start_base + 1)
	
	# 4-8: Decide base to go to.
	if fielder_with_ball == null:
		fielder_with_ball = fielders[fftib[2]]
	for i in range(len(runners)):
		if runners[i].is_active() and decisions[i]==null:
			# 4. Go to next next base if possible.
			if runners[i].running_progress - floor(runners[i].running_progress) > .7 and floor(runners[i].running_progress) < 2.5:
				var next_next_base = ceil(runners[i].running_progress) + 1
				var time_to_next_next_base = (next_next_base - runners[i].running_progress) * 30 / runners[i].SPEED
				var time_throw_next_next_base = (
					fielder_with_ball.distance_xz(
						fielder_with_ball.position,
						fielder_with_ball.base_positions[next_next_base-1]
					) / fielder_with_ball.max_throw_speed
				) + seconds_to_intercept
				if time_to_next_next_base < time_throw_next_next_base:
					#printt('decision for', i, next_base, time_to_next_base, time_throw_next_base)
					#print("Sending runner to next next base", next_next_base)
					decisions[i] = coalesce(decisions[i], 2)
					decision_bases[i] = coalesce(decision_bases[i], next_next_base)
			
			var next_base = ceil(runners[i].running_progress + 1e-14)
			if next_base < 4.5:
				var time_to_next_base = (next_base - runners[i].running_progress) * 30 / runners[i].SPEED
				var time_throw_next_base = (
					fielder_with_ball.distance_xz(
						fielder_with_ball.position,
						fielder_with_ball.base_positions[next_base-1]
					) / fielder_with_ball.max_throw_speed
				) + seconds_to_intercept
				#printt('decision for', i, decisions[i], next_base, time_to_next_base, time_throw_next_base)
				if time_to_next_base < time_throw_next_base:
					# 5. Go to next base if possible.
					#printt('decision for', i, decisions[i], next_base, time_to_next_base, time_throw_next_base)
					decisions[i] = coalesce(decisions[i], 1)
					decision_bases[i] = coalesce(decision_bases[i], next_base)
				elif abs(runners[i].running_progress - round(runners[i].running_progress)) < 1e-12:
					# 6. Stay on current base if possible.
					decisions[i] = coalesce(decisions[i], 0)
					decision_bases[i] = coalesce(decision_bases[i], round(runners[i].running_progress))
				else:
					# 7. Go to previous base if possible.
					# 8. Go to closer of next and previous base.
					var prev_base = ceil(runners[i].running_progress + 1e-14)
					var time_to_prev_base = (prev_base - runners[i].running_progress) * 30 / runners[i].SPEED
					var time_throw_prev_base = (seconds_to_intercept + fielder_with_ball.distance_xz(
						fielder_with_ball.position,
						fielder_with_ball.base_positions[prev_base-1]) / fielder_with_ball.max_throw_speed)
					if (time_to_next_base - time_throw_next_base) < (time_to_prev_base - time_throw_prev_base):
						decisions[i] = coalesce(decisions[i], 1)
						decision_bases[i] = coalesce(decision_bases[i], ceil(runners[i].running_progress))
					else:
						decisions[i] = coalesce(decisions[i], -1)
						decision_bases[i] = coalesce(decision_bases[i], floor(runners[i].running_progress))



	#if len(fielders_with_ball) > 0.5:
		## Fielder has ball
		#assert(ball.state == 'fielded')
		## If need to tag up, do it
		#for i in range(len(runners)):
			#if runners[i].is_active() and runners[i].needs_to_tag_up and not runners[i].tagged_up_after_catch:
				#decisions[i] = coalesce(decisions[i], -1)
		## If they are a force out and not at next base, go there
		#for i in range(len(runners)):
			#if runners[i].is_active() and runners[i].can_be_force_out():
				##printt('Runner can be force out', i)
				#decisions[i] = coalesce(decisions[i], 1)
		## Decide between going forward to next base, going forward, staying, or going backward
		#for i in range(len(runners)):
			#if runners[i].is_active():
				## Margin to go to next next base
				#if runners[i].running_progress - floor(runners[i].running_progress) > .7 and floor(runners[i].running_progress) < 2.5:
					#var next_next_base = ceil(runners[i].running_progress) + 1
					#var time_to_next_next_base = (next_next_base - runners[i].running_progress) * 30 / runners[i].SPEED
					#var time_throw_next_next_base = fielders_with_ball[0].distance_xz(
						#fielders_with_ball[0].position,
						#fielders_with_ball[0].base_positions[next_next_base-1]) / fielders_with_ball[0].max_throw_speed
					#if time_to_next_next_base < time_throw_next_next_base:
						##printt('decision for', i, next_base, time_to_next_base, time_throw_next_base)
						#print("Sending runner to next next base", next_next_base)
						#decisions[i] = coalesce(decisions[i], 2)
				## Margin to go to next base
				#var next_base = ceil(runners[i].running_progress + 1e-14)
				#if next_base < 4.5:
					#var time_to_next_base = (next_base - runners[i].running_progress) * 30 / runners[i].SPEED
					#var time_throw_next_base = fielders_with_ball[0].distance_xz(
						#fielders_with_ball[0].position,
						#fielders_with_ball[0].base_positions[next_base-1]) / fielders_with_ball[0].max_throw_speed
					#if time_to_next_base < time_throw_next_base:
						##printt('decision for', i, next_base, time_to_next_base, time_throw_next_base)
						#decisions[i] = coalesce(decisions[i], 1)
					#elif abs(runners[i].running_progress - round(runners[i].running_progress)) < 1e-12:
						## Stay on current base
						#decisions[i] = coalesce(decisions[i], 0)
					#else:
						## Not on base, can't make it to next base. Either go back or go to next
						## Margin for previous base
						#var prev_base = ceil(runners[i].running_progress + 1e-14)
						#var time_to_prev_base = (prev_base - runners[i].running_progress) * 30 / runners[i].SPEED
						#var time_throw_prev_base = fielders_with_ball[0].distance_xz(
							#fielders_with_ball[0].position,
							#fielders_with_ball[0].base_positions[prev_base-1]) / fielders_with_ball[0].max_throw_speed
						#if (time_to_next_base - time_throw_next_base) < (time_to_prev_base - time_throw_prev_base):
							#decisions[i] = coalesce(decisions[i], 1)
						#else:
							#decisions[i] = coalesce(decisions[i], -1)
	#elif ball.state in ['thrown__']:
		## Ball is thrown
		#pass
	#elif ball.state in ['ball_in_play', 'thrown']:
		## Ball in play
		## Simulate ball forward, see if it will bounce, where it will be caught, etc
		## [found_someone, ball_will_bounce, fielder name, intercept position, seconds_to_intercept]
		#var fftib = find_fielder_to_intercept_ball()
		#var seconds_to_intercept = fftib[4]
		## Determine if ball can be caught. If yes, go back.
		#if not ball_hit_bounced and not fftib[1]:
				##printt('SENDING BACK, CAN CATCH!!!')
				#for i in range(len(runners)):
					#decisions[i] = coalesce(decisions[i], -1)
		#else: # Ball will bounce before catch
			## If they are a force out and not at next base, go there
			#for i in range(len(runners)):
				##if runners[i].is_active():
					##printt('checking run force out:', runners[i].is_active(), runners[i].can_be_force_out(), ball_hit_bounced, fftib[1])
				#if runners[i].is_active() and runners[i].can_be_force_out():
					#printt('Runner can be force out', i)
					#decisions[i] = coalesce(decisions[i], 1)
			## Check if they can make it to next base before throw/run
			## Else if on base stay there
			## Else between bases, find safer direction
			#var fielder_with_ball = fielders[fftib[2]]
			## Decide between going forward, staying, or going backward
			#for i in range(len(runners)):
				#if runners[i].is_active():
					## Margin to go to next base
					#var next_base = ceil(runners[i].running_progress + 1e-14)
					#if next_base < 4.5:
						#var time_to_next_base = (next_base - runners[i].running_progress) * 30 / runners[i].SPEED
						#var time_throw_next_base = (seconds_to_intercept + fielder_with_ball.distance_xz(
							#fielder_with_ball.position,
							#fielder_with_ball.base_positions[next_base-1]) / fielder_with_ball.max_throw_speed)
						##printt('decision for', i, decisions[i], next_base, time_to_next_base, time_throw_next_base)
						#if time_to_next_base < time_throw_next_base:
							##printt('decision for', i, decisions[i], next_base, time_to_next_base, time_throw_next_base)
							#decisions[i] = coalesce(decisions[i], 1)
						#elif abs(runners[i].running_progress - round(runners[i].running_progress)) < 1e-12:
							## Stay on current base
							#decisions[i] = coalesce(decisions[i], 0)
						#else:
							## Not on base, can't make it to next base. Either go back or go to next
							## Margin for previous base
							#var prev_base = ceil(runners[i].running_progress + 1e-14)
							#var time_to_prev_base = (prev_base - runners[i].running_progress) * 30 / runners[i].SPEED
							#var time_throw_prev_base = (seconds_to_intercept + fielder_with_ball.distance_xz(
								#fielder_with_ball.position,
								#fielder_with_ball.base_positions[prev_base-1]) / fielder_with_ball.max_throw_speed)
							#if (time_to_next_base - time_throw_next_base) < (time_to_prev_base - time_throw_prev_base):
								#decisions[i] = coalesce(decisions[i], 1)
							#else:
								#decisions[i] = coalesce(decisions[i], -1)
	#else:
		## Shouldn't happen
		#printerr('error')
	#printt('Final decide_automatic_runners_actions:', decisions)
	
	# Adjust them so that two aren't sent to the same base (if trail runner is faster)
	#printt('decision bases before', decision_bases)
	var lead = null # target base of active runner in front of runner i
	for i in [3,2,1,0]:
		if decisions[i] != null:
			# If lead runner is going home (4), it doesn't prevent runners behind
			if lead != null and lead < 3.99999:
				# TODO: don't let trail runner go home if lead runner is only going 
				#      b/c of force out. It will make both out.
				# If runner on first is staying at first, batter still needs to
				#   go to first.
				if decision_bases[i] >= lead and not (i==0 and lead==1):
					#printt('changing decision from', decision_bases[i], lead - 1)
					# Change decision back one base
					decision_bases[i] = lead - 1
			# They are lead for the next one
			lead = decision_bases[i]
	#printt('decision bases after', decision_bases)
	
	
	# Do the action
	for i in range(len(runners)):
		if runners[i].is_active() and decisions[i] != null:
			#runners[i].send_runner(decisions[i], decisions[i] > 1.5)
			runners[i].send_runner_to_base(decision_bases[i])
