extends CharacterBody3D

var SPEED = 25
var swing_started = false
var swing_done = false
var swing_state = 'notstarted' # ['notstarted', 'inzone', 'backswing'
var swing_elapsed_sec = 0
var input_click = false
var swingx = false
var swingy = false
var swing_inzone_duration = 0.15
var animation = "idle"

var user_is_batting_team
var is_frozen:bool = false

func freeze() -> void:
	is_frozen = true
	visible = false
	set_process(false)

func reset(color:Color) -> void:
	is_frozen = false
	visible = true
	set_process(true)
	
	swing_started = false
	swing_done = false
	swing_state = 'notstarted'
	swing_elapsed_sec = 0
	input_click = false
	swingx = false
	swingy = false
	
	get_node('AnimatedSprite3D').set_frame(0)
	get_node('AnimatedSprite3D').visible = false
	get_node('AnimatedSprite3DIdle').visible = true
	
	#$Char3D.look_at(Vector3(0,0,0), Vector3.UP, true)
	set_look_at_position(Vector3(0,0,100))
	#$Char3D/charnode/AnimationTree.set("parameters/conditions/swing", false)
	#set_animation("idle")
	set_animation("batter_idle")
	#set_animation("swing")
	$Char3D.set_color(color)
	#$Char3D/charnode/AnimationPlayer.speed_scale=.1
	#$Char3D/charnode/Animation.set('parameters/TimeScale/scale', 10)

	

func begin_swing():
	print('Starting swing in batter_3d:_process')
	swing_started = true
	# Change which sprite is visible
	get_node("AnimatedSprite3D").visible = true
	get_node("AnimatedSprite3DIdle").visible = false
	get_node("AnimatedSprite3DIdle").set_process(false)
	
	set_animation('swing')
	
	# Move to next frame
	get_node('AnimatedSprite3D').set_frame(1)
	swing_elapsed_sec = 0
	swing_state = 'inzone'

func _process(delta: float) -> void:
	#if randf_range(0,1) < .04:
		#printt('batter process conditions',
		#$Char3D/charnode/AnimationTree.get("parameters/conditions/batter_idle"),
		#$Char3D/charnode/AnimationTree.get("parameters/conditions/swing"),
		#$Char3D/charnode/AnimationTree.get("parameters/conditions/idle"))
	if is_frozen:
		return
	if (not swing_started and not swing_done and 
		user_is_batting_team and 
		Input.is_action_just_pressed("swing")):
		# Make sure pitch hasn't started yet
		if get_parent().get_node('Ball3D').pitch_in_progress:
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
			var minibat = get_parent().get_node("Bat3D")
			minibat.get_node("Sprite3D").visible = false
			minibat.set_process(false)
			# Start running after .5 seconds
			#timer_action = "start_running_after_hit"
			#get_node("Timer").wait_time = 0.5
			#get_node("Timer").start()
	
	
	# Make bat move with mouse
	# Place bat for swing target
	if not swing_started and not swing_done and user_is_batting_team:
		var mouse_sz_pos = get_parent().get_parent().get_mouse_sz_pos()
		#printt('glove pos', mouse_sz_pos)
		#printt('catmitt is', get_tree().root.get_node("Field3D/Headon/CatchersMitt"))
		mouse_sz_pos.z -= .001
		get_parent().get_node("Bat3D").position = mouse_sz_pos

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

func set_animation(new_anim):
	printt('Batter setting animation:', new_anim)
	if new_anim == animation:
		return
	animation = new_anim
	#if new_anim == "idle":
		#pass
	#if new_anim == "moving":
	$Char3D.start_animation(new_anim)

func set_look_at_position(pos) -> void:
	# Always stay vertical
	pos.y = 0
	# Rotate to global frame
	pos = pos.rotated(Vector3(0,1,0), 45.*PI/180)
	# Look at global position
	$Char3D.look_at(pos, Vector3.UP, true)
