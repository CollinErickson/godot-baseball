extends Node2D

var swing_started = false
var swing_done = false
var swing_state = 'notstarted'
var swing_elapsed_sec = 0
var input_click = false
var swingx = false
var swingy = false

func _process(delta: float) -> void:
	#print(1)
	if not swing_started and not swing_done and input_click:
		print('Starting swing in batter:_process')
		swing_started = true
		# Move to next frame
		get_node('Sprite2D').set_frame(1)
		swing_elapsed_sec = 0
		swing_state = 'inzone'
	if input_click:
		input_click = false
	if swing_started and not swing_done:
		swing_elapsed_sec += delta
		if swing_state == 'inzone' and swing_elapsed_sec > .15:
			pass
			swing_state = 'backswing'
			swing_done = true
			# next animation
			get_node('Sprite2D').set_frame(2)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not swing_started and not swing_done:
		print('click')
		input_click = true
		print(event)
		swingx = event.position.x
		swingy = event.position.y
