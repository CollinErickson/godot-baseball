extends Control

@export var width:int = 100
@export var height:int = 30
var black_pct:float = 10
var black_speed:float = 1 # seconds for go from left end to right
var black_dir:int = 1
var active:bool = false
var green_left_pct:float
var green_right_pct:float
var this_is_root:bool = false
var black_width_pct:float = 9
var background_margin:float = 6



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	visible = false
	#printt('rr size', $RedRect.size)
	#$RedRect.
	$BackgroundRect.size[0] = width + 6
	$BackgroundRect.size[1] = height + 6
	$BackgroundRect.position.x = - 6./2
	$BackgroundRect.position.y = - 6./2
	$RedRect.size[0] = width
	$RedRect.size[1] = height
	$GreenRect.size[0] = width/2.
	$GreenRect.size[1] = height
	$GreenRect.size[0] = width/50.
	$BlackRect.size[0] = width * black_width_pct / 100.
	$BlackRect.size[1] = height
	if get_tree().root == get_parent():
		position = Vector2(100,100)
		printt('THIS IS ROOT')
		this_is_root = true
		reset(randf_range(5,95),randf_range(.5,2))

func reset(green_width_pct, black_speed_):
	if green_width_pct > 100:
		green_width_pct = 100
	green_left_pct = randf_range(0, 100 - green_width_pct)
	green_right_pct = green_left_pct + green_width_pct
	$GreenRect.position.x = green_left_pct / 100. * width
	$GreenRect.size.x = green_width_pct / 100. * width
	#printt('gr size', $GreenRect.size)
	black_speed = black_speed_
	active = true
	visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if active:
		#printt('checking root', this_is_root)
		if this_is_root:
			if Input.is_action_just_pressed("ui_accept"):
				var _success = check_success()
				#printt("Bar success?", success)
				
				reset(randf_range(5,95),randf_range(.5,2))
				return

		# Update black position
		black_pct += delta * black_dir * 100. / black_speed
		if black_pct > 100:
			black_dir = -1
			black_pct = 100
		if black_pct < 0:
			black_dir = 1
			black_pct = 0
		
		# Update black rect pos, align center
		$BlackRect.position.x = width * (black_pct - black_width_pct / 2)/100.

func check_success(stop:bool=false,hide_:bool=false) -> bool:
	var success = false
	if black_pct > green_left_pct and black_pct < green_right_pct:
		success = true
	if stop:
		active = false
	if hide_:
		visible = false
	return success
