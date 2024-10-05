extends Node2D

const sz_x_left = 462
const sz_x_right = 717
const sz_y_top = 339
const sz_y_bottom = 556
var ball_in_play = false

func wait(seconds: float) -> void:
	print('Doesnt work - RUNNING WAIT!!!!!')
	await get_tree().create_timer(seconds).timeout

func _ready() -> void:
	pass# get_node('ball').scale = Vector2(1,1)*.05
	get_node('Camera2D').offset.x = 1280/2
	get_node('Camera2D').offset.y = 800/2
	

var pitch_in_progress = false
var pitch_done = false
var contact_done = false

func _process(delta: float) -> void:
	#print(get_global_mouse_position())
	#print(get_node('ball').position.x, " , ", get_node('ball').position.y)
	
	# Test Camera2D
	#get_node('Camera2D').offset.x += 1
	
	# Start pitch
	if Input.is_key_pressed(KEY_SPACE) and not pitch_done and not pitch_in_progress:
		#print('starting pitch in pv ', pitch_in_progress)
		# Need next line before the awaits so that it blocks the next iteration
		pitch_in_progress = true
		# Animate pitcher
		get_node('pitcher').get_node('AnimatedSprite2D').set_frame(1)
		#wait(1.5) # Didn't work
		await get_tree().create_timer(.3).timeout
		get_node('pitcher').get_node('AnimatedSprite2D').set_frame(2)
		await get_tree().create_timer(.15).timeout
		#get_node("Strikezone").scale.x=1.1
		print('calling start_pitch from pitchview script')
		get_node('ball').start_pitch(1, 580, 300, 500, 450, -150, -100)
		get_node('pitcher').get_node('AnimatedSprite2D').set_frame(3)
	if pitch_in_progress:
		pass
		# Check for contact
		if get_node('batter').swing_state == 'inzone' and not contact_done:
			var swingx = get_node('batter').swingx
			var swingy = get_node('batter').swingy
			# Ball needs to be near 0
			if abs(get_node('ball').z - 0) < 0.5:
				# Bat needs to be near ball
				var ballx = get_node('ball').position.x
				var bally = get_node('ball').position.y
				if (swingx - ballx)**2 + (swingy - bally)**2 < 100**2:
					print('CONTACT')
					contact_done = true
					ball_in_play = true
					get_node('ball').velocity.x = 100
					get_node('ball').velocity.y = -200
					get_node('ball').velocity_z = 10
					
				else:
					print('MISSED , ', swingx, ' , ', ballx)
				
		
		#get_node('ball').scale += Vector2(1,1)*.001
		##if get_node('ball').scale.x >= .2:
		#	pitch_in_progress = false
		#	pitch_done = true
		#	get_node('ball').stop_pitch()
	if ball_in_play:
		get_node('ball').move_after_hit(delta)
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()
