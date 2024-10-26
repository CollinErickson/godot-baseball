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

# Rotate sprites to face the camera
func align_sprite():
	var cam = get_viewport().get_camera_3d()
	#print('in align_sprite, cam is')
	#print(cam)
	var tantheta = (position.x - cam.position.x) / (position.z - cam.position.z)
	#printt("tantheta is:", tantheta)
	rotation.y = atan(tantheta)

func assign_to_field_ball(pos):
	assignment = 'ball'
	assignment_pos = pos
	assignment_pos.y = 0
	if user_is_pitching_team:
		set_selected_fielder()

func assign_to_cover_base(base):
	assignment = 'cover'
	if base == 1:
		assignment_pos = Vector3(-1,0,1) * 30/sqrt(2)
	elif base == 2:
		assignment_pos = Vector3(0,0,1) * 30/sqrt(2) * 2
	elif base == 3:
		assignment_pos = Vector3(1,0,1) * 30/sqrt(2)
	elif base == 4:
		assignment_pos = Vector3(0,0,0)
	else:
		assert(false)

func begin_chase():
	pass

func change_color():
	pass #var image = get_node("AnimatedSprite3D")#.texture.get_data()

func _ready():
	change_color()

signal ball_fielded
signal tag_out

func _physics_process(delta: float) -> void:
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
		#printt('ball distance to fielder is', sqrt((position.x-assignment_pos.x)**2+(position.z-assignment_pos.z)**2))
		if distance_can_move < distance_from_target:
			# Can't reach it, move full distance. Don't move vertically
			var direction_unit_vec = (assignment_pos - position).normalized()
			position.x += delta * SPEED * direction_unit_vec.x
			position.z += delta * SPEED * direction_unit_vec.z
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
	
	# Check if they caught the ball
	if assignment in ["ball", "cover", "wait_to_receive", "ball_click"]:
		var ball = get_tree().get_first_node_in_group("ball")
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
				assignment = "holding_ball"
				assignment_pos = null
				time_last_began_holding_ball = Time.get_ticks_msec()
				#printt('fielder emiting ball_fielded')
				ball_fielded.emit(self)
				if user_is_pitching_team:
					set_selected_fielder()

	# Check if user moves
	if user_is_pitching_team and (holding_ball or assignment=="ball") and is_selected_fielder:
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
			if move.length() > 0:
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
				#printt('cam fielder movement', cam.rotation)
				position += delta * velocity
				#var ball = get_tree().get_first_node_in_group("ball")
				#ball.position = position
		
	var click_used = false
	# If holding, check if they throw it or step on base or move
	if holding_ball:
		# Check if tagging runner
		var runners = get_tree().get_nodes_in_group("runners")
		for runner in runners:
			if (runner.exists_at_start and not runner.out_on_play and
				abs(runner.running_progress - round(runner.running_progress)) > 1e-4 and
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
				
		# Check for throw
		if user_is_pitching_team:
			# Check for throwing ball
			if Input.is_action_just_pressed("throwfirst"):
				#printt('throw to first')
				throw_ball_func(1)
			elif Input.is_action_just_pressed("throwsecond"):
				throw_ball_func(2)
			elif Input.is_action_just_pressed("throwthird"):
				throw_ball_func(3)
			elif Input.is_action_just_pressed("throwhome"):
				throw_ball_func(4)
			
			# Check for click that throws ball
			if Input.is_action_just_pressed("click"):
				var mgl = get_parent().get_parent().get_node("MouseGroundLocation")
				#printt('in fielder, mgl pos is', mgl, mgl.position)
				for i in range(4):
					if distance_xz(mgl.position, base_positions[i]) < 2:
						throw_ball_func(i+1)
						click_used = true
					#else:
					#	printt('click not near base')
		else: # CPU defense
			if assignment != "ball_carry":
				# Make sure that some frames passed while holding
				if Time.get_ticks_msec() - time_last_began_holding_ball > 1000.*0.10:
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
							if distance_xz(position, Vector3(0,0,20)) > 25 and max_running_progress > -0.5:
								throw_to = ceil(max_running_progress)
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
		assignment = "ball_click"
		assignment_pos = get_parent().get_parent().get_parent().get_mouse_y0_pos()
	
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

signal throw_ball
func throw_ball_func(base):
	printt('throw_ball_func', base)
	# Only throw if not close to that base
	if distance_xz(position, base_positions[base-1]) > 3:
		holding_ball = false
		var ball = get_tree().get_first_node_in_group("ball")
		ball.position = position
		ball.position.y = 1.4
		ball.throw_start_pos = null
		ball.throw_target = null
		throw_ball.emit(base, self)
		assignment = 'wait_to_receive' # Not the best name for it
		if user_is_pitching_team:
			set_not_selected_fielder()

var timer_action
func _on_timer_timeout() -> void:
	get_node("Timer").stop()
	if timer_action == "set_visible_true":
		visible = true

var is_selected_fielder = false
func set_selected_fielder():
	# Unselect all other players
	var selected_fielders = get_tree().get_nodes_in_group("selected_fielder")
	for fielder in selected_fielders:
		fielder.set_not_selected_fielder()
	# Select this player
	add_to_group("selected_fielder")
	is_selected_fielder = true
	get_node("Annulus").visible = true
func set_not_selected_fielder():
	remove_from_group("selected_fielder")
	is_selected_fielder = false
	get_node("Annulus").visible = false
