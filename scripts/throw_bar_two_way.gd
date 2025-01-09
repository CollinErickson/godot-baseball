## Bar that fills up left to right and can be stopped at any time.
## If not stopped, then it gets the max value.

extends Control

@export var width:int = 100
@export var height:int = 30
var selector_pct:float = 0
var selector_speed:float = 1 # seconds for go from left end to right
var dir:int = 1 # is 1 for first part, then -1 going back
var active:bool = false
var gradient_width_pct:float
var green_left_pct:float
var green_right_pct:float
var this_is_root:bool = false
var selector_width_pct:float = 9
var background_margin:float = 6
var release_pct:float
var release_red_pct:float
var bar_reached_end_without_forward_release:float = false



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	visible = false
	#printt('rr size', $RedRect.size)
	#$RedRect.
	$BackgroundRect.size[0] = width + 6
	$BackgroundRect.size[1] = height + 6
	$BackgroundRect.position.x = - 6./2
	$BackgroundRect.position.y = - 6./2
	#$RedRect.size[0] = width
	#$RedRect.size[1] = height
	#$GreenRect.size[0] = width/2.
	#$GreenRect.size[1] = height
	#$GreenRect.size[0] = width/50.
	$BlackRect.size[0] = width
	$BlackRect.size[1] = height
	$GradientRect.size[0] = width * gradient_width_pct / 100.
	$GradientRect.size[1] = height
	$GradientRect.position.x = width * (1 - gradient_width_pct / 100.)
	$GradientRect.position.y = 0
	$SelectorRect.size[0] = width * selector_width_pct / 100.
	$SelectorRect.size[1] = height
	$GreenRect.visible = false
	$GreenRect.size[1] = height
	if get_tree().root == get_parent():
		this_is_root = true
		printt('In throw_bar_two_way: THIS IS ROOT')
		position = Vector2(100,100)
		reset(randf_range(5,95),randf_range(.5,2))

func reset(gradient_width_pct_, selector_speed_):
	if this_is_root:
		printt('In reset: ', gradient_width_pct_, selector_speed_)
	selector_pct = 0
	# Put between 0-100
	gradient_width_pct = max(min(gradient_width_pct_, 100), 0)
	# Put it at right spot
	$GradientRect.position.x = width * (1 - gradient_width_pct / 100.)
	# Shrink to specified width. Be careful, must resize texture before rect
	$GradientRect.texture.set_width(width * gradient_width_pct / 100.)
	$GradientRect.size.x = width * gradient_width_pct / 100.
	#$GradientRect.set_size(Vector2(width * gradient_width_pct / 100., height))
	selector_speed = selector_speed_
	active = true
	visible = true
	release_pct = -100
	release_red_pct = -100
	bar_reached_end_without_forward_release = false
	dir = 1
	$GreenRect.visible = false
	$GradientRect.visible = true

#signal throw_bar_one_way_reached_max
func _process(delta: float) -> void:
	if active:
		#printt('checking root', this_is_root)
		if this_is_root:
			if dir > 0:
				if Input.is_action_just_pressed("ui_accept"):
					printt('Bar forward release')
					forward_release()
			else:
				if Input.is_action_just_pressed("ui_accept"):
					var success = check_success()
					printt("    Bar success?", success)
					if !success[0]:
						return
					
					reset(randf_range(5,95),randf_range(.5,1))
					return

		# Update selector position
		selector_pct += delta * dir * 100. / selector_speed
		if selector_pct > 100:
			selector_pct = 100
			dir = -1
			# Switch to second step by default if user hasn't already
			if release_pct < 0:
				forward_release()
		
		# End it
		if dir < 0 and selector_pct < 0:
			selector_pct = 0
			bar_reached_end_without_forward_release = true
		
		# Update selector rect pos, align center
		$SelectorRect.position.x = width * (selector_pct - selector_width_pct / 2)/100.

func check_success(stop:bool=false,hide_:bool=false) -> Array:
	## Reverse press
	# Return array: [worked properly, % filled, % red, reverse press is in green]
	# Prevent way too early releases, they are likely late presses in forward
	if selector_pct > 85:
		return [false]
	if stop:
		active = false
	if hide_:
		visible = false
	var success:bool = false
	if selector_pct >= green_left_pct and selector_pct <= green_right_pct:
		success = true
	return [true, selector_pct, release_red_pct, success]

func forward_release() -> bool:
	# Returns if it worked successfully
	# Don't let this happen twice
	if release_red_pct > -1:
		return false
	
	# Find intensity and % red
	release_pct = selector_pct
	
	if selector_pct < 100 - gradient_width_pct:
		release_red_pct = 0
	else:
		release_red_pct = (selector_pct - (100 - gradient_width_pct)) / gradient_width_pct
	
	# Set size of green rect
	var green_width = (1-release_red_pct)*30. + 15
	green_left_pct = 10
	green_right_pct = green_left_pct + green_width
	$GreenRect.size.x = green_width * width / 100.
	$GreenRect.position.x = green_left_pct * width / 100.
	$GreenRect.visible = true
	$GradientRect.visible = false
	return true
