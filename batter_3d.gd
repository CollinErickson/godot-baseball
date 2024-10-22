extends CharacterBody3D

var SPEED = 25
var swing_started = false
var swing_done = false
var swing_state = 'notstarted'
var swing_elapsed_sec = 0
var input_click = false
var swingx = false
var swingy = false
var swing_inzone_duration = 0.15

var user_is_batting_team

func begin_swing():
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

func _process(delta: float) -> void:
	if (not swing_started and not swing_done and 
		user_is_batting_team and 
		Input.is_action_just_pressed("swing")):
		begin_swing()
	if swing_started and not swing_done:
		swing_elapsed_sec += delta
		if swing_state == 'inzone' and swing_elapsed_sec > swing_inzone_duration:
			# Finish swing
			swing_state = 'backswing'
			swing_done = true
			# next animation
			get_node('AnimatedSprite3D').set_frame(2)
			# Turn off mini bat for aiming
			var minibat = get_tree().root.get_node("Field3D/Headon/Bat3D")
			minibat.get_node("Sprite3D").visible = false
			minibat.set_process(false)
			# Start running after .5 seconds
			#timer_action = "start_running_after_hit"
			#get_node("Timer").wait_time = 0.5
			#get_node("Timer").start()
	
	
	# Make bat move with mouse
	# Place bat for swing target
	if not swing_started and not swing_done and user_is_batting_team:
		var mouse_sz_pos = get_tree().root.get_node("Field3D").get_mouse_sz_pos()
		#printt('glove pos', mouse_sz_pos)
		#printt('catmitt is', get_tree().root.get_node("Field3D/Headon/CatchersMitt"))
		mouse_sz_pos.z -= .001
		get_tree().root.get_node("Field3D/Headon/Bat3D").position = mouse_sz_pos

var timer_action
signal start_runner
func _on_timer_timeout() -> void:
	get_node('Timer').stop()
	if not timer_action:
		printerr("bad timer 33512422")
	if timer_action == "start_running_after_hit":
		# Create Runner, place near 0, set to run
		start_runner.emit()
	elif timer_action == "begin_swing":
		begin_swing()
	else:
		printerr('bad 9012412')
