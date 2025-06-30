extends navigable_button
class_name navigable_button_adjustable

var values:Array = ["test1", "test2", "test3"]
var current_index:int = 0
var self_update:bool = true

#func _ready() -> void:
	#if self_update:
		#text = values[current_index]
		#set_text(text)

func set_text(_text:String="ignored") -> void:
	if !self_update:
		return
	
	text = values[current_index]
	#set_text(text)
	$Panel/MarginContainer/Label.text = text

signal signal_clicked_left
signal signal_clicked_right
func clicked_left() -> void:
	signal_clicked_left.emit(id)
	current_index -= 1
	if current_index < 0:
		current_index = len(values) - 1
	set_text()
func clicked_right() -> void:
	signal_clicked_right.emit(id)

func disconnect_all_signals() -> void:
	disconnect_signal('signal_clicked')
	disconnect_signal('signal_clicked_left')
	disconnect_signal('signal_clicked_right')
