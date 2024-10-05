extends CharacterBody3D

var swing_started = false
var swing_done = false
var swing_state = 'notstarted'
var swing_elapsed_sec = 0
var input_click = false
var swingx = false
var swingy = false

func _process(delta: float) -> void:
	#print(1)
	if not swing_started and not swing_done and Input.is_action_just_pressed("swing"):
		print('Starting swing in batter_3d:_process')
		swing_started = true
		# Change which sprite is visible
		get_node("AnimatedSprite3D").visible = true
		get_node("AnimatedSprite3DIdle").visible = false
		get_node("AnimatedSprite3DIdle").set_process(false)
		
		# Move to next frame
		get_node('AnimatedSprite3D').set_frame(1)
		swing_elapsed_sec = 0
		swing_state = 'inzone'
	if swing_started and not swing_done:
		swing_elapsed_sec += delta
		if swing_state == 'inzone' and swing_elapsed_sec > .15:
			swing_state = 'backswing'
			swing_done = true
			# next animation
			get_node('AnimatedSprite3D').set_frame(2)
			# Turn off mini bat for aiming
			var minibat = get_tree().root.get_node("Field3D/Headon/Bat3D")
			minibat.get_node("Sprite3D").visible = false
			minibat.set_process(false)
	
	# Make bat move with mouse
	# Place bat for swing target
	if not swing_started and not swing_done:
		var mouse_sz_pos = get_tree().root.get_node("Field3D").get_mouse_sz_pos()
		#printt('glove pos', mouse_sz_pos)
		#printt('catmitt is', get_tree().root.get_node("Field3D/Headon/CatchersMitt"))
		mouse_sz_pos.z -= .001
		get_tree().root.get_node("Field3D/Headon/Bat3D").position = mouse_sz_pos
