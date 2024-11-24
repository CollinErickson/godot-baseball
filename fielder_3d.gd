extends CharacterBody3D

@export_group("Baseball")
@export var posname: String

const SPEED = 8.0
const MAX_ACCEL = 100.0
const max_throw_speed = 30.0

var assignment # cover, ball_click, ball_carry, wait_to_receive, holding_ball
var assignment_pos
var holding_ball = false
var user_is_pitching_team
var time_last_began_holding_ball
var start_position = Vector3()
@onready var fielders = get_tree().get_nodes_in_group('fielders')
@onready var ball = get_tree().get_first_node_in_group("ball")
var animation = "idle"

var is_frozen:bool = false
func freeze() -> void:
	set_not_selected_fielder()
	is_frozen = true
	visible = false
	set_physics_process(false)

func reset() -> void:
	is_frozen = false
	visible = true
	set_physics_process(true)
	# Reset vars
	position = start_position
	velocity = Vector3()
	
	assignment = null
	assignment_pos = null
	holding_ball = false
	time_last_began_holding_ball = null
	remove_from_group('selected_fielder')
	remove_from_group('fielder_holding_ball')
	
	# End start throw
	start_throw_started = false
	start_throw_base = null
	start_throw_fielder = null
	start_throw_key_check_release = null
	throw_ready = false
	throw_ready_success = true
	$ThrowBar.visible = false
	$ThrowBar.active = false
	
	$Char3D.look_at(Vector3(0,0,0), Vector3.UP, true)
	animation = "idle"
	
	

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
	assignment = 'ball'
	assignment_pos = pos
	assignment_pos.y = 0
	if user_is_pitching_team:
		set_selected_fielder()

func assign_to_cover_base(base, ball_pos=null):
	assignment = 'cover'
	if base == 1:
		assignment_pos = Vector3(-1,0,1) * 30/sqrt(2)
	elif base == 2:
		assignment_pos = Vector3(0,0,1) * 30/sqrt(2) * 2
	elif base == 3:
		assignment_pos = Vector3(1,0,1) * 30/sqrt(2)
	elif base == 4:
		assignment_pos = Vector3(0,0,0)
	elif base == 5:
		assignment_pos = .5*(Vector3(0,0,1)*30*sqrt(2) + ball_pos)
	else:
		assert(false)

func begin_chase():
	pass

func change_color():
	pass #var image = get_node("AnimatedSprite3D")#.texture.get_data()

func _ready():
	start_position = position
	change_color()

signal ball_fielded
signal tag_out
signal new_fielder_selected_signal

func _physics_process(delta: float) -> void:
	#if is_selected_fielder:
	#printt('selected fielder', posname, assignment)
	#if randf_range(0,1)<.01:
	#	printt('fielder user pit team', posname, user_is_pitching_team)
	if is_frozen:
		return
	#if posname == 'C':
	#	printt('catcher fielder', assignment)
	if not assignment:
		return
	#print("Moving fielder to ball!!!!!!")
	# Move fielder
	#if assignment in ["ball", "cover"]:
	if (assignment in ["cover", "ball_click", "ball_carry"]) or (assignment == 'ball' and not user_is_pitching_team):
		var distance_from_target = distance_xz(position, assignment_pos)
		var distance_can_move = delta * SPEED
		# Face target
		#$Char3D.look_at(ball.global_position * Vector3(1,0,1), Vector3.UP, true)
		if distance_from_target > 0:
			$Char3D.look_at(to_global(assignment_pos), Vector3.UP, true)
		elif position.distance_squared_to(ball.position) > 1e-12:
			$Char3D.look_at(to_global(ball.position), Vector3.UP, true)

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
				#printt('pitcher made it to ball assignment')
				#if posname == 'P':
				#	pass
				#assignment = "holding_ball"
				#ball_fielded.emit()
				#holding_ball = true
				assignment = "wait_to_receive"
			elif assignment == "cover":
				assignment = "wait_to_receive"
			elif assignment == "ball_carry":
				assignment = 'holding_ball'
			elif assignment == "ball_click":
				assignment = 'ball'
			else:
				printt("Bad assignment, didn't update", assignment)
			# They have reached assignment, so changed anim to idle
			set_animation("idle")
	
	# Check if they caught the ball
	if assignment in ["ball", "cover", "wait_to_receive", "ball_click"]:
		#var ball = get_tree().get_first_node_in_group("ball")
		if ball.state in ["ball_in_play", "thrown"]:
			#printt('ball here', ball.position)
			#if ball.state =='thrown'
			var distance_from_ball = distance_xz(position, ball.position)
			#var throw_progress = 1
			#if ball.throw_start_pos != null:
				#throw_progress = (distance_xz(ball.throw_start_pos, ball.position) /
					#distance_xz(ball.throw_target, ball.throw_start_pos))
				## Fix when throw distance is very small
				#var throw_target_distance = distance_xz(ball.throw_target, ball.throw_start_pos)
				#if throw_target_distance < 1:
					#throw_progress = 1
			#if randf_range(0,1) < .3:
			#	printt('throw progress', throw_progress, ball.position.y, ball.throw_start_pos)
			#if posname=='P':
			#	printt('FIELD BALL???', posname, distance_from_ball, position, ball.position)
			#printt('fielder check next', distance_from_ball, ball.position.y, ball.time_last_thrown, ball.throw_start_pos, ball.throw_progress)
			if (distance_from_ball < 2 and ball.position.y < 2.5 and 
				Time.get_ticks_msec() - ball.time_last_thrown > 300 and
				(ball.throw_start_pos==null or ball.throw_progress >= .9)):
				printt('FIELD BALL', posname, distance_from_ball, position, ball.position, Time.get_ticks_msec() - ball.time_last_thrown, ball.throw_progress)
				ball.position = position
				ball.position.y = 1.4
				#printt('FIELD BALL', posname, distance_from_ball, position, ball.position)
				holding_ball = true
				add_to_group('fielder_holding_ball')
				assignment = "holding_ball"
				assignment_pos = null
				time_last_began_holding_ball = Time.get_ticks_msec()
				#printt('fielder emiting ball_fielded')
				ball_fielded.emit(self)
				if user_is_pitching_team:
					set_selected_fielder()

	# Check if user moves
	if user_is_pitching_team and (holding_ball or assignment in ["ball", "ball_click"]) and is_selected_fielder:
		# Check for movement
		var anymovement = false
		var move = Vector3()
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
		if anymovement:
			if move.length() > 0: # Could press opposite directions
				#move = move.normalized() * delta * SPEED
				# move is the move direction
				move = move.normalized()
				# Rotate move based on camera angle
				var cam = get_viewport().get_camera_3d()
				move = move.rotated(Vector3(0,1,0), cam.rotation.y - PI)
				# Update velocity with acceleration, but keep under max
				velocity += delta * MAX_ACCEL * move
				if velocity.length() > SPEED:
					velocity = velocity.normalized() * SPEED
			$Char3D.look_at(position + 100*move.rotated(Vector3(0,1,0), 45.*PI/180), Vector3.UP, true)
			set_animation("running")

			if assignment == 'ball_click':
				# If moving due to click then user does other movement, switch to that
				assignment = 'ball'
		else: # No movement -> stop
			if velocity.length() > 1e-12:
				move = Vector3(-velocity.x, 0, -velocity.z)
				move = move.normalized()
				var dvel = delta * MAX_ACCEL * move
				if dvel.length() > velocity.length(): # Cancel to 0
					velocity = Vector3.ZERO
					set_animation("idle")
				else:
					velocity += dvel
		#printt('cam fielder movement', cam.rotation)
		position += delta * velocity
		#var ball = get_tree().get_first_node_in_group("ball")
		#ball.position = position
	
	var click_used = false
	
	# Check if user is starting throw. Can be done before holding ball, but only by selected fielder
	if is_selected_fielder:
		# Check for throw
		if user_is_pitching_team:
			# Check for throwing ball end
			if start_throw_started:
				if Input.is_action_just_released(start_throw_key_check_release):
					start_throw_end()
			
			var new_throw = false
			# Check for throwing ball start
			if Input.is_action_just_pressed("throwfirst"):
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
	
	# If holding, check if they throw it or step on base or move
	if holding_ball:
		# Update ball position
		ball.position = position + Vector3(0,1.4,0)
		
		# Check if tagging active runner not on base
		var runners = get_tree().get_nodes_in_group("runners")
		for runner in runners:
			if (runner.is_active() and
				(abs(runner.running_progress - round(runner.running_progress)) > 1e-4 or
					(runner.needs_to_tag_up and not runner.tagged_up_after_catch and
						runner.running_progress - runner.start_base > .15)) and
				distance_xz(position, runner.position) < 1):
				runner.runner_is_out()
				tag_out.emit()
		
		# Check if step on base
		var step_on_base = is_stepping_on_base()
		#printt(posname, step_on_base)
		if step_on_base[0]:
			if not stepping_on_base_with_ball:
				#print("STEPPING ON BASE!!!", posname, step_on_base)
				stepped_on_base_with_ball.emit(self, step_on_base[1])
				stepping_on_base_with_ball = true
		elif not step_on_base[0]: # Not holding ball
				stepping_on_base_with_ball = false
		
		# Throw is ready
		if user_is_pitching_team and throw_ready:
			# Only if throw was completed recently
			if Time.get_ticks_msec() - throw_ready_time < 1000*2:
				#printt('THROW IS READY')
				# Execute throw
				throw_ball_func(start_throw_base, start_throw_fielder, throw_ready_success)
				# Clear vars
				start_throw_base = null
				start_throw_fielder = null
				throw_ready = false
				throw_ready_success = true
			else:
				throw_ready = false
		
		# CPU defense
		if not user_is_pitching_team:
			if assignment != "ball_carry":
				# Make sure that some frames passed while holding
				if Time.get_ticks_msec() - time_last_began_holding_ball > 1000.*0.40:
					#printt('TRYING TO CPU THROW NOW', posname)
					# Decide what to do with ball
					# TODO: Don't throw if the throw won't beat them
					# TODO: Throw to better base for double play.
					# TODO: Throw to better base for force out.
					# TODO: Baserunners running backward
					var throw_to = -1
					var max_running_progress = -1
					var run_it = false
					if not user_is_pitching_team:
						#print('CPU decide what to do with ball now')
						# Check for active runners that need to tag up, throw at lead
						if throw_to < -0.5:
							#printt('CHECKING THROW OUT TAG UP')
							for runner in runners:
								#printt('CHECKING THROW OUT TAG UP', runner.needs_to_tag_up, runner.tagged_up_after_catch)
								if runner.is_active() and runner.needs_to_tag_up and not runner.tagged_up_after_catch:
									throw_to = max(throw_to, runner.start_base)
									#printt('CAN THROW OUT TAG UP')
						# Check for active runners, throw in front of lead
						#var runners = get_tree().get_nodes_in_group("runners")
						if throw_to < -0.5:
							for runner in runners:
								if runner.is_active():
									max_running_progress = max(max_running_progress, runner.running_progress)
									#printt('fielder is', fielder)
									if runner.is_running and runner.target_base > runner.running_progress:
										throw_to = max(throw_to, runner.target_base)
										#printt('could throw out runner', runner.target_base, runner.out_on_play)
									
						# If OF, throw to IF
						if throw_to < -0.5:
							if distance_xz(position, Vector3(0,0,20)) > 25:
								if max_running_progress > -0.5:
									throw_to = ceil(max_running_progress)
								else:
									throw_to = 2
						if distance_xz(position, base_positions[throw_to-1]) < 10:
							run_it = true
							assignment_pos = base_positions[throw_to-1]
							assignment = "ball_carry"
						
						if run_it:
							printt('fielder running to base', throw_to, posname)
						else:
							
							if throw_to > -0.5:
								printt("in field: ball will be thrown to", throw_to)
								throw_ball_func(throw_to)
							else:
								pass #printt('deciding not to throw', posname)
	else:
		stepping_on_base_with_ball = false
	
	# Check for click to move selected player or change selected player
	if user_is_pitching_team and not click_used and Input.is_action_just_pressed("click") and is_selected_fielder:
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
			fielders[min_i].assignment = "ball"
			assignment = "wait_to_receive"
			new_fielder_selected_signal.emit(fielders[min_i])
			printt('fielder i assignment new assignment is', fielders[min_i].assignment, fielders[min_i].posname)
		else:
			# Run to that position
			assignment = "ball_click"
			assignment_pos = click_y0_pos
		click_used = true
	
	if assignment == 'wait_to_receive':
		$Char3D.look_at(ball.global_position * Vector3(1,0,1), Vector3.UP, true)
	
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
	
	# Turn on throw bar
	$ThrowBar.visible = true
	var cam = get_viewport().get_camera_3d()
	$ThrowBar.position = cam.unproject_position(global_position)
	$ThrowBar.reset(20, .7)

var throw_ready:bool = false
var throw_ready_success:bool = true
var throw_ready_time = null
func start_throw_end():
	# Check throw bar
	throw_ready_success = $ThrowBar.check_success(true, true)
	
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
func throw_ball_func(base, fielder=null, success=true) -> void:
	printt('throw_ball_func', base, fielder)
	
	# Only throw if not close to that base
	if base != null:
		if distance_xz(position, base_positions[base-1]) > 3:
			holding_ball = false
			remove_from_group('fielder_holding_ball')
			#var ball = get_tree().get_first_node_in_group("ball")
			ball.position = position
			ball.position.y = 1.4
			ball.throw_start_pos = null
			ball.throw_target = null
			# This needs to be before throw_ball.emit() since that can reassign this fielder
			assignment = 'wait_to_receive' # Not the best name for it
			throw_ball.emit(base, self, null, success)
			if user_is_pitching_team:
				set_not_selected_fielder()
	elif fielder != null: # Throw to a fielder
		if distance_xz(position, fielder.position) > 3:
			holding_ball = false
			remove_from_group('fielder_holding_ball')
			#var ball = get_tree().get_first_node_in_group("ball")
			ball.position = position
			ball.position.y = 1.4
			ball.throw_start_pos = null
			ball.throw_target = null
			# This needs to be before throw_ball.emit() since that can reassign this fielder
			assignment = 'wait_to_receive' # Not the best name for it
			throw_ball.emit(base, self, fielder, success)
			if user_is_pitching_team:
				set_not_selected_fielder()

var timer_action
func _on_timer_timeout() -> void:
	get_node("Timer").stop()
	if timer_action == "set_visible_true":
		visible = true

var is_selected_fielder = false
func set_selected_fielder():
	printt('in fielder, set_selected_fielder', posname)
	# Unselect all other players
	var selected_fielders = get_tree().get_nodes_in_group("selected_fielder")
	for fielder in selected_fielders:
		fielder.set_not_selected_fielder()
	# Select this player
	add_to_group("selected_fielder")
	is_selected_fielder = true
	get_node("Annulus").visible = true
	#printt('annulus should be on')

func set_not_selected_fielder():
	remove_from_group("selected_fielder")
	is_selected_fielder = false
	get_node("Annulus").visible = false

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
	if new_anim == animation:
		return
	animation = new_anim
	#if new_anim == "idle":
		#pass
	#if new_anim == "moving":
	$Char3D.start_animation(new_anim)
