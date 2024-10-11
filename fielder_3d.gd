extends CharacterBody3D


const SPEED = 8.0

var assignment
var assignment_pos
var holding_ball

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
		assignment = null
		ball_fielded.emit()
		holding_ball = true
	
