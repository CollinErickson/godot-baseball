extends CharacterBody3D

var SPEED = 25
var swing_started = false
var swing_done = false
var swing_state = 'notstarted' # ['notstarted', 'inzone', 'backswing'
var swing_elapsed_sec = 0
var input_click = false
var swingx = false
var swingy = false
var swing_prezone_duration = 0.25
var swing_inzone_duration = 0.15
var animation = "idle"
var bats:String # "L", "R"
var bat_mode:String

var user_is_batting_team
var is_frozen:bool = false

@onready var minibat = get_parent().get_node("Bat3D")

func freeze() -> void:
	is_frozen = true
	visible = false
	set_process(false)

func pause() -> void:
	$Char3D.pause()
	set_physics_process(false)
	set_process(false)

func unpause() -> void:
	$Char3D.unpause()
	set_physics_process(true)
	set_process(true)

func reset(bat_mode_:String, user_is_batting_team_:bool) -> void:
	is_frozen = false
	visible = true
	set_process(true)
	
	user_is_batting_team = user_is_batting_team_
	swing_started = false
	swing_done = false
	swing_state = 'notstarted'
	swing_elapsed_sec = 0
	input_click = false
	swingx = false
	swingy = false
	bat_mode = bat_mode_
	assert(bat_mode in ["Timing", "Target"])
	if user_is_batting_team:
		if bat_mode == "Timing":
			disable_minibat()
		else:
			enable_minibat()
	else:
		disable_minibat()
	
	get_node('AnimatedSprite3D').set_frame(0)
	get_node('AnimatedSprite3D').visible = false
	get_node('AnimatedSprite3DIdle').visible = false
	$Char3D.set_glove_visible('none')
	
	$Char3D.reset() # Resets rotation
	#$Char3D.look_at(Vector3(0,0,0), Vector3.UP, true)
	set_look_at_position(Vector3(-100,0,0))
	#$Char3D/charnode/AnimationTree.set("parameters/conditions/swing", false)
	#set_animation("idle")
	set_animation("batter_idle")
	#set_animation("swing")
	#$Char3D.set_color(color)
	#$Char3D/charnode/AnimationPlayer.speed_scale=.1
	#$Char3D/charnode/Animation.set('parameters/TimeScale/scale', 10)

	

func begin_swing():
	print('Starting swing in batter_3d:_process')
	swing_started = true
	# Change which sprite is visible
	get_node("AnimatedSprite3D").visible = false
	get_node("AnimatedSprite3DIdle").visible = false
	get_node("AnimatedSprite3DIdle").set_process(false)
	
	set_animation('swing')
	
	# Move to next frame
	get_node('AnimatedSprite3D').set_frame(1)
	swing_elapsed_sec = 0
	swing_state = 'prezone'

func _process(delta: float) -> void:
	#if randf_range(0,1) < .04:
		#printt('batter process conditions',
		#$Char3D/charnode/AnimationTree.get("parameters/conditions/batter_idle"),
		#$Char3D/charnode/AnimationTree.get("parameters/conditions/swing"),
		#$Char3D/charnode/AnimationTree.get("parameters/conditions/idle"))
	if is_frozen:
		return
	if randf() < .1:
		printt('in batter running process', Time.get_ticks_msec())
	if (not swing_started and not swing_done and 
		user_is_batting_team and 
		Input.is_action_just_pressed("swing")):
		# Make sure pitch hasn't started yet
		if get_parent().get_node('Ball3D').pitch_in_progress:
			begin_swing()
	if swing_started and not swing_done:
		swing_elapsed_sec += delta
		
		# If prezone, check if should be inzone
		if (swing_state == 'prezone' and
			swing_elapsed_sec > swing_prezone_duration):
			swing_state = "inzone"
		
		# If inzone, check if should be done/backswing
		if (swing_state == 'inzone' and
			swing_elapsed_sec > swing_prezone_duration + swing_inzone_duration):
			# Finish swing
			swing_state = 'backswing'
			swing_done = true
			# next animation
			get_node('AnimatedSprite3D').set_frame(2)
			# Turn off mini bat for aiming
			disable_minibat()
			# Start running after .5 seconds
			#timer_action = "start_running_after_hit"
			#get_node("Timer").wait_time = 0.5
			#get_node("Timer").start()
	
	
	# Make bat move with mouse
	# Place bat for swing target
	if not swing_started and not swing_done and user_is_batting_team and bat_mode == "Target":
		var mouse_sz_pos = get_parent().get_parent().get_mouse_sz_pos()
		#printt('glove pos', mouse_sz_pos)
		#printt('catmitt is', get_tree().root.get_node("Field3D/Headon/CatchersMitt"))
		mouse_sz_pos.z -= .001
		minibat.position = mouse_sz_pos

var timer_action
signal start_runner
func _on_timer_timeout() -> void:
	get_node('Timer').stop()
	if timer_action==null:
		printerr("bad timer 33512422")
	if timer_action == "start_running_after_hit":
		# Create Runner, place near 0, set to run
		start_runner.emit()
	elif timer_action == "begin_swing":
		begin_swing()
	else:
		printerr('bad 9012412')

func set_animation(new_anim):
	#printt('Batter setting animation:', new_anim)
	if new_anim == animation:
		return
	animation = new_anim
	#if new_anim == "idle":
		#pass
	#if new_anim == "moving":
	printt('in batter, bats', bats, bats=='R', bats=='')
	$Char3D.start_animation(new_anim, bats=="R", false)

func set_look_at_position(pos) -> void:
	#printt('setting batter to look at ', pos)
	# Always stay vertical
	pos.y = 0
	# Rotate to global frame
	pos = pos.rotated(Vector3(0,1,0), 45.*PI/180)
	#printt('setting batter to look at global position ', pos)
	# Look at global position
	$Char3D.look_at(pos, Vector3.UP, true)

func setup_player(player, team, is_home_team:bool) -> void:
	if player != null:
		bats = player.bats
		assert(['R', 'L'].has(bats))
		printt('in batter setting bats', bats, player.bats)
		position = Vector3(1, 0, 0.5)
		if bats == 'R':
			#set_look_at_position(Vector3(0,0,-100))
			# Make bat visible
			get_node('Char3D').set_bat_visible('R')
		else:
			position.x *= -1
			#set_look_at_position(Vector3(0,0,100))
			
			# Make bat visible
			get_node('Char3D').set_bat_visible('L')
	if team != null:
		$Char3D.set_color_from_team(player, team, is_home_team)

func disable_minibat() -> void:
	minibat.visible = false
	minibat.get_node("Sprite3D").visible = false
	minibat.set_process(false)

func enable_minibat() -> void:
	minibat.visible = true
	minibat.get_node("Sprite3D").visible = true
	minibat.set_process(true)
