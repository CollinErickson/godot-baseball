extends Control


var is_active:bool = false

@export_group("Generic adjustable menu")
@export var start_active:bool = false
@export var menu_title:String = "(default title)"
@export var options_names:Array[String] = ['Innings', 'Outs', 'Difficulty']
@export var options_values:Array[Array] = [['1', '3', '5', '7', '9'],
										   ['1', '2', '3', '4', '5'],
										   ['Easy', 'Medium', 'Hard']]
var index_selected:int = 0
var values_selected:Array = []
var this_is_root:bool = false

func _ready() -> void:
	if get_tree().root == get_parent():
		this_is_root = true
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
	

signal menu_selected
func _process(_delta: float) -> void:
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
