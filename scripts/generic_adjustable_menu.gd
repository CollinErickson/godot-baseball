extends Control


var is_active:bool = false

@export_group("Generic adjustable menu")
@export var start_active:bool = false
# Default to main settings menu
@export var menu_title:String = "Settings"
@export var options_names:Array[String] = ['Difficulty', 'Innings', 'Outs', 
	'Balls', 'Strikes']
func range_to_str_array(low:int, high:int) -> Array:
	return range(low, high + 1).map(func(x): return str(x))
func combine_arrays(x:Array, y:Array) -> Array:
	for z in y:
		x.push_back(z)
	return x
func double_range_to_str_array(a:int, b:int, c:int) -> Array:
	return combine_arrays(range_to_str_array(a, b), range_to_str_array(c, a-1))
@export var options_values:Array[Array] = [
	['Easy', 'Medium', 'Hard'],
	double_range_to_str_array(9, 27, 1),
	double_range_to_str_array(9, 27, 1),
	double_range_to_str_array(4, 10, 1),
	double_range_to_str_array(3, 10, 1),
]
var index_selected:int = 0
var values_selected:Array = []
var this_is_root:bool = false

func _ready() -> void:
	printt('in generic adjustable menu: options_values', options_values)
	if get_tree().root == get_parent():
		this_is_root = true
		start_active = true
		#options_na
	assert(len(options_names) == len(options_values))
	assert(len(options_names) > 0.5)
	values_selected = []
	# Start all on 0 (first in array)
	for i in range(len(options_names)):
		values_selected.push_back(0)
	
	# Set title
	$HeaderRect/Label.text = menu_title
	
	# Create the options and put values in
	set_left_col(0)
	set_right_col(0)
	if len(options_names) > 1.5:
		for i in range(1, len(options_names)):
			# Duplicate left and right
			var dupL = get_left_col(0).duplicate()
			$GridContainer.add_child(dupL)
			var dupR = get_right_col(0).duplicate()
			$GridContainer.add_child(dupR)
			# Set text
			set_left_col(i)
			set_right_col(i)
	set_right_col_active(0)
	
	set_active(is_active)

signal menu_selected
func _process(_delta: float) -> void:
	if not is_active:
		return
	if Input.is_action_just_pressed("movedown"):
		index_selected = posmod(index_selected + 1, len(options_names))
		set_right_col_active(index_selected)
	elif Input.is_action_just_pressed("moveup"):
		index_selected = posmod(index_selected - 1, len(options_names))
		set_right_col_active(index_selected)
	elif Input.is_action_just_pressed("moveright"):
		#printt('move right', index_selected, values_selected)
		values_selected[index_selected] = posmod(values_selected[index_selected] + 1, len(options_values[index_selected]))
		#print(index_selected, values_selected, options_values)
		#$VBoxRight.get_children()[index_selected].text = options_values[index_selected][values_selected[index_selected]]
		set_right_col(index_selected)
	elif Input.is_action_just_pressed("moveleft"):
		#printt('move left', index_selected, values_selected)
		values_selected[index_selected] = posmod(values_selected[index_selected] - 1, len(options_values[index_selected]))
		#$VBoxRight.get_children()[index_selected].text = options_values[index_selected][values_selected[index_selected]]
		set_right_col(index_selected)
	elif Input.is_action_just_pressed("ui_accept"):
		var out_array:Array = []
		for i in range(len(options_values)):
			out_array.push_back(options_values[i][values_selected[i]])
		printt('generic adjustable menu out_array:', out_array)
		menu_selected.emit(out_array)
		set_active(false)
		return

func get_left_col(index:int):
	return $GridContainer.get_child(2*index)
func get_right_col(index:int):
	#printt('get right col', index, $GridContainer.get_children(), $GridContainer.get_child(2*index+1))
	return $GridContainer.get_child(2*index + 1)
func set_left_col(index:int):
	get_left_col(index).get_child(0).get_child(0).text = options_names[index]
func set_right_col(index:int):
	#printt('set right col', index, get_right_col(index))
	get_right_col(index).get_child(0).get_child(0).text = options_values[index][values_selected[index]]
	#printt('try to set panel', $GridContainer.get_child(2*index + 1).get_child(0).)
	#set_right_col_active(index)

func set_right_col_active(index):
	# First set all to be default color
	for i in range(len(options_names)):
		var style1 = StyleBoxFlat.new()
		var color1 = Color(0.3, 0.3, 0.3)
		style1.set_bg_color(color1)
		$GridContainer.get_child(2*i + 1).add_theme_stylebox_override('panel', style1)
	
	# Then set specified index to be
	var style = StyleBoxFlat.new()
	var color = Color(0.1, 0.1, 0.1)
	style.set_bg_color(color)
	$GridContainer.get_child(2*index + 1).add_theme_stylebox_override('panel', style)

func set_active(is_active_:bool):
	is_active = is_active_
	set_process(is_active_)
	visible = is_active_
