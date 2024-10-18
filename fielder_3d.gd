extends CharacterBody3D

@export_group("Baseball")
@export var posname: String

const SPEED = 8.0
const max_throw_speed = 30

var assignment
var assignment_pos
var holding_ball = false
var user_is_pitching_team

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
	if assignment in ["ball", "cover"]:
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
				#assignment = "holding_ball"
				#ball_fielded.emit()
				#holding_ball = true
				assignment = "wait_to_receive"
			elif assignment == "cover":
				assignment = "wait_to_receive"
	
	# Check if they caught the ball
	if assignment in ["ball", "cover", "wait_to_receive"]:
		var ball = get_tree().get_first_node_in_group("ball")
		var distance_from_ball = distance_xz(position, ball.position)
		var throw_progress = 1
		if ball.throw_start_pos != null:
			throw_progress = (distance_xz(ball.throw_start_pos, ball.position) /
				distance_xz(ball.throw_target, ball.throw_start_pos))
			# Fix when throw distance is very small
			var throw_target_distance = distance_xz(ball.throw_target, ball.throw_start_pos)
			if throw_target_distance < 1:
				throw_progress = 1
		#if randf_range(0,1) < .3:
		#	printt('throw progress', throw_progress, ball.position.y, ball.throw_start_pos)
		if (distance_from_ball < 2 and ball.position.y < 2.5 and 
			Time.get_ticks_msec() - ball.time_last_thrown > 300 and
			throw_progress >= .9):
			ball.position = position
			ball.position.y = 1.4
			holding_ball = true
			assignment = "holding_ball"
			assignment_pos = null
			#printt('fielder emiting ball_fielded')
			ball_fielded.emit()
			if user_is_pitching_team:
				set_selected_fielder()

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
					#else:
					#	printt('click not near base')
			
			# Check for movement
			var anymovement = false
			var move = Vector3()
			if Input.is_action_pressed("moveleft"):
				move.x += delta * SPEED
				anymovement = true
			if Input.is_action_pressed("moveright"):
				move.x -= delta * SPEED
				anymovement = true
			if Input.is_action_pressed("moveup"):
				move.z += delta * SPEED
				anymovement = true
			if Input.is_action_pressed("movedown"):
				move.z -= delta * SPEED
				anymovement = true
			if anymovement:
				if move.length() > 0:
					move = move.normalized() * delta * SPEED
					position += move
					var ball = get_tree().get_first_node_in_group("ball")
					ball.position = position
		
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
	else:
		stepping_on_base_with_ball = false
var stepping_on_base_with_ball = false

func distance_xz(a:Vector3, b:Vector3) -> float:
	return sqrt((a.x - b.x)**2 +
				(a.z - b.z)**2)

var base_positions = [
	Vector3(-1,0,1)*30/sqrt(2),
	Vector3(0,0,1)*30*sqrt(2),
	Vector3(1,0,1)*30/sqrt(2),
	Vector3(0,0,0)
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
	# Only throw if not close to that base
	if distance_xz(position, base_positions[base-1]) > 3:
		holding_ball = false
		var ball = get_tree().get_first_node_in_group("ball")
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
	add_to_group("selected_fielder")
	is_selected_fielder = true
	get_node("Annulus").visible = true
func set_not_selected_fielder():
	remove_from_group("selected_fielder")
	is_selected_fielder = false
	get_node("Annulus").visible = false
