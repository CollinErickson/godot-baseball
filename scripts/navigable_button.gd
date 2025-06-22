extends Control

@export var text:String = 'test123'
@export var page_id:String = 'null'
@export var id:String = ''

func _ready() -> void:
	$Panel/MarginContainer/Label.text = text
	pass

func top() -> int:
	return $Panel.global_position.y
func bottom() -> int:
	return $Panel.global_position.y + $Panel.size.y
func left() -> int:
	return $Panel.global_position.x
func right() -> int:
	return $Panel.global_position.x + $Panel.size.x
signal signal_clicked
func clicked() -> void:
	signal_clicked.emit(id)
func disconnect_all_signals() -> void:
	#get_signal_list()
	var signal_list = get_signal_connection_list('signal_clicked')
	printt('signal list is', signal_list)
	for signal_info in signal_list:
		#var signal_name = signal_info["signal"]
		var target_callable = signal_info["callable"]
		#printt('trying to disconnect', signal_name, target_callable)
		disconnect('signal_clicked', target_callable)
