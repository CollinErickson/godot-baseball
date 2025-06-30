extends Control
class_name navigable_button

@export var text:String = 'test123'
@export var page_id:String = 'null'
@export var id:String = ''
@export var row:int = 0
@export var col:int = 0
var is_hover:bool = false

func _ready() -> void:
	#printt('in failing ready', $Panel)
	set_text(text)
	#change_panel_color(Color("green"))

func top() -> int:
	return $Panel.global_position.y
func bottom() -> int:
	return $Panel.global_position.y + $Panel.size.y
func left() -> int:
	return $Panel.global_position.x
func right() -> int:
	return $Panel.global_position.x + $Panel.size.x
func holds_pos(pos:Vector2) -> bool:
	return pos.x >= left() and \
			pos.y >= top() and \
			pos.x <= right() and \
			pos.y <= bottom()

signal signal_clicked
func clicked() -> void:
	signal_clicked.emit(id)
func disconnect_all_signals() -> void:
	disconnect_signal('signal_clicked')
	
func disconnect_signal(signal_name:String) -> void:
	#get_signal_list()
	var signal_list = get_signal_connection_list(signal_name)
	#printt('signal list is', signal_list)
	for signal_info in signal_list:
		#var signal_name = signal_info["signal"]
		var target_callable = signal_info["callable"]
		#printt('trying to disconnect', signal_name, target_callable)
		disconnect(signal_name, target_callable)

func set_hover(val:bool) -> void:
	#printt('in button set_hover', page_id, id)
	#get_node("Panel")
	#var p = Panel.new()
	#p.stylebox
	#p.add_theme_color_override(Color('red'))
	if is_hover == val:
		return
	is_hover = val
	# Hover status changed, so change color
	if val:
		change_panel_color(Color("#760076"))
		add_to_group("button_hover-" + page_id)
	else:
		change_panel_color(Color("#990099"))
		remove_from_group("button_hover-" + page_id)

func change_panel_color(new_color: Color):
	var panel_node:Panel = get_node("Panel")
	# Get the current StyleBox for the panel
	# 'panel' is the default name for the Panel's background style.
	var current_stylebox: StyleBox = panel_node.get_theme_stylebox("panel")
	# Duplicate
	var stylebox_flat = current_stylebox.duplicate() as StyleBoxFlat
	# Set the background color
	stylebox_flat.bg_color = new_color
	# Apply the modified StyleBox as an override.
	# The first argument "panel" refers to the style name.
	panel_node.add_theme_stylebox_override("panel", stylebox_flat)

func setup(text_:String, page_id_:String, id_:String, row_:int, col_:int
	) -> void:
	text = text_
	page_id = page_id_
	id = id_
	row = row_
	col = col_

func set_text(text_:String) -> void:
	$Panel/MarginContainer/Label.text = text_
