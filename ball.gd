extends Node2D

const z_far = 40
var z = z_far
const z_close = -3
#const width_far = 0.05
const width_close = 0.20
const camera_z_back = 10
const camera_z = z_close - camera_z_back
var velocity_z = 0
var pitch_in_progress = false
var pitch_done = false
var velocity = Vector2()
func get_width(z):
	return camera_z_back * width_close / (z - camera_z)

var x0
var y0
var x1
var y1
var dx
var dy
var pitch_sec_elapsed = 0
var sec_to_reach_end = -1

func start_pitch(sec_to_reach_end_, x0_, y0_, x1_, y1_, dx_, dy_):
	print("Starting pitch in ball:start_pitch!")
	get_node('CharacterBody2D/Baseball320').play()
	#var sec_to_reach_end = 1
	velocity_z = (z_far - z_close) / sec_to_reach_end
	pitch_in_progress = true
	x0 = x0_
	y0 = y0_
	x1 = x1_
	y1 = y1_
	dx = dx_
	dy = dy_
	sec_to_reach_end = sec_to_reach_end_
	pitch_sec_elapsed = 0
	visible = true
	
	

func stop_pitch():
	get_node('CharacterBody2D/Baseball320').stop()
	pitch_done = true

func move(delta):
	pitch_sec_elapsed += delta
	# Move in Z dimension
	#z += delta * velocity_z
	z = (pitch_sec_elapsed / sec_to_reach_end) * (z_close - z_far) + z_far
	# Set ball scale
	#var scalez = (z - z_close) / (z_far - z_close) * (width_far - width_close) + width_close
	var scalez = get_width(z)
	get_node('CharacterBody2D/Baseball320').scale.x=scalez
	get_node('CharacterBody2D/Baseball320').scale.y=scalez
	# Move in x and y
	position.x = pitch_sec_elapsed * (x1 - x0) + x0
	#print('calc x, ', pitch_sec_elapsed, ' , ', x0, ' , ', x1, ' , ', position.x)
	position.y = pitch_sec_elapsed * (y1 - y0) + y0
	# Add bend
	position.x += sin(pitch_sec_elapsed/sec_to_reach_end*PI)*dx
	position.y += sin(pitch_sec_elapsed/sec_to_reach_end*PI)*dy

func move_after_hit(delta):
	print('running move_after_hit , z= ', z, ' , ', position.x, ' , ', position.y)
	# Update position
	position.x += delta * velocity.x
	position.y += delta * velocity.y
	z += delta * velocity_z
	# Bounce
	if position.y > 600:
		position.y = 600 + 600 - position.y
		velocity *= .9
		velocity.y *= -1 # Flip to bounce up
		velocity_z *= .9
	# Update velocity
	velocity.y += delta * 280 # Some gravity term
	
	# Scale z
	#var scalez = (z - z_close) / (z_far - z_close) * (width_far - width_close) + width_close
	#var scalez = (width_close) * (10) / (10 + z - z_close)
	var scalez = get_width(z)
	get_node('CharacterBody2D/Baseball320').scale.x=scalez
	get_node('CharacterBody2D/Baseball320').scale.y=scalez

	

func _ready() -> void:
	#start_pitch()
	get_node('CharacterBody2D/Baseball320').stop()
	get_node('CharacterBody2D/Baseball320').scale.x = get_width(z_far)
	get_node('CharacterBody2D/Baseball320').scale.y = get_width(z_far)
	visible = false

func _process(delta: float) -> void:
	if get_parent() == get_tree().root:
		# Only done when this is the main for testing purposes
		1 #print('ball is main')
		if Input.is_key_pressed(KEY_SPACE) and not pitch_in_progress and not pitch_done:
			position.x=400
			position.y=400
			start_pitch(1, 600, 500, 400, 550, -150, -100)
			print('starting pitch in ball')
		if Input.is_key_pressed(KEY_ENTER):
			get_node('CharacterBody2D/Baseball320').set_frame([0,1,2,3].pick_random())
			
	if pitch_in_progress:
		
		#print(position.x, ' , ', position.y, ' , ', pitch_sec_elapsed, ' , ',
		#	sec_to_reach_end, ' , ', pitch_in_progress, ' , ', z)
		move(delta)
		if z < z_close:
			stop_pitch()
			pitch_done = true
			pitch_in_progress = false
