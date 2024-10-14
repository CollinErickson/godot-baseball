extends CharacterBody3D

@export_group("Baseball")
@export var posname: String

const SPEED = 8.0
const max_throw_speed = 30

var assignment
var assignment_pos
var holding_ball = false

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

func _physics_process(delta: float) -> void:
	if not assignment:
		return
	#print("Moving fielder to ball!!!!!!")
	if assignment in ["ball", "cover"]:
		var distance_from_target = sqrt((position.x - assignment_pos.x)**2 +
										(position.z - assignment_pos.z)**2)
		var distance_can_move = delta * SPEED
		#printt('ball distance to fielder is', sqrt((position.x-assignment_pos.x)**2+(position.z-assignment_pos.z)**2))
		if distance_can_move < distance_from_target:
			# Can't reach it, move full distance. Don't move vertically
			var direction_unit_vec = (assignment_pos - position).normalized()
			position.x += delta * SPEED * direction_unit_vec.x
			position.z += delta * SPEED * direction_unit_vec.z
		else:
			# Can reach it, go to that point and stop
			printt('ball distance to fielder is', sqrt((position.x-assignment_pos.x)**2+(position.z-assignment_pos.z)**2))
			position = assignment_pos
			if assignment == "ball":
				#assignment = "holding_ball"
				#ball_fielded.emit()
				#holding_ball = true
				assignment = "wait_to_receive"
			elif assignment == "cover":
				assignment = "wait_to_receive"
	
	# Check if they caught the ball
	if assignment in ["cover", "wait_to_receive"]:
		var ball = get_tree().get_first_node_in_group("ball")
		var distance_from_ball = sqrt((position.x - ball.position.x)**2 +
										(position.z - ball.position.z)**2)
		var throw_progress = 1
		if ball.throw_start_pos != null:
			throw_progress = (sqrt((ball.throw_start_pos.x - ball.position.x)**2 +
				(ball.throw_start_pos.z - ball.position.z)**2) /
				sqrt((ball.throw_target.x - ball.throw_start_pos.x)**2 +
				(ball.throw_target.z - ball.throw_start_pos.z)**2))
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

	# If holding, check if they throw it or step on base or move
	if holding_ball:
		# Check for throwing ball
		if Input.is_action_just_pressed("throwfirst"):
			throw_ball_func(1)
		elif Input.is_action_just_pressed("throwsecond"):
			throw_ball_func(2)
		elif Input.is_action_just_pressed("throwthird"):
			throw_ball_func(3)
		elif Input.is_action_just_pressed("throwhome"):
			throw_ball_func(4)
		
		# Check for movement
		if Input.is_action_pressed("moveleft"):
			position.x += delta * SPEED
		if Input.is_action_pressed("moveright"):
			position.x -= delta * SPEED
		if Input.is_action_pressed("moveup"):
			position.z += delta * SPEED
		if Input.is_action_pressed("movedown"):
			position.z -= delta * SPEED
		
		
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
func is_stepping_on_base() -> Array:
	var bases = [
		Vector3(-1,0,1)*30/sqrt(2),
		Vector3(0,0,1)*30*sqrt(2),
		Vector3(1,0,1)*30/sqrt(2),
		Vector3(0,0,0)
	]
	#printt('is_stepping_on_base', posname, bases[0], position)
	for i in range(4):
		if sqrt((position.x - bases[i].x)**2 +
				(position.z - bases[i].z)**2) < 1:
			return [true, i + 1]
	return [false]

signal stepped_on_base_with_ball

signal throw_ball
func throw_ball_func(base):
	holding_ball = false
	var ball = get_tree().get_first_node_in_group("ball")
	ball.throw_start_pos = null
	ball.throw_target = null
	throw_ball.emit(base, self)


var timer_action
func _on_timer_timeout() -> void:
	get_node("Timer").stop()
	if timer_action == "set_visible_true":
		visible = true
