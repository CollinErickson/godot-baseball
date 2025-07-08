extends navigable_button
class_name navigable_button_adjustable

@export var values:Array = ["test1", "test2", "test3"]
@export var current_index:int = 0
var self_update:bool = true

#func _ready() -> void:
	#if self_update:
		#text = values[current_index]
		#set_text(text)

func set_text(_text:String="ignored") -> void:
	if !self_update:
		return
	printt('setting new text in nba', current_index)
	text = values[current_index]
	#set_text(text)
	$Panel/MarginContainer/Label.text = text

func current_value():
	return values[current_index]
#signal signal_clicked_left
#signal signal_clicked_right
#func clicked_left() -> void:
	#signal_clicked_left.emit(id)
	#current_index -= 1
	#if current_index < 0:
		#current_index = len(values) - 1
	#set_text()
#func clicked_right() -> void:
	#signal_clicked_right.emit(id)

func clicked(mpos:Vector2=Vector2.ZERO) -> void:
	#signal_clicked.emit(id)
	printt('need to implement clicked in nba')
	if holds_pos_left(mpos):
		use_move_left()
	elif holds_pos_right(mpos):
		use_move_right()

func disconnect_all_signals() -> void:
	disconnect_signal('signal_clicked')
	#disconnect_signal('signal_clicked_left')
	#disconnect_signal('signal_clicked_right')

func uses_move_left() -> bool:
	printt('in nba use move left')
	return true

func uses_move_right() -> bool:
	printt('in nba use move right')
	signal_clicked.emit(id, {'move':'right'})
	return true

func use_move_left() -> void:
	#signal_clicked.emit(id, {'move':'left'})
	current_index -= 1
	if current_index < 0:
		current_index = len(values) - 1
	set_text()

func use_move_right() -> void:
	#signal_clicked.emit(id, {'move':'right'})
	current_index += 1
	if current_index >= len(values):
		current_index = 0
	set_text()

func holds_pos(pos:Vector2) -> bool:
	return holds_pos_left(pos) or holds_pos_right(pos)

func holds_pos_left(pos:Vector2) -> bool:
	return pos.x >= left() and \
			pos.y >= top() and \
			pos.x <= (2*left() + right()) / 3. and \
			pos.y <= bottom()

func holds_pos_right(pos:Vector2) -> bool:
	return pos.x >= (left() + 2*right()) / 3. and \
			pos.y >= top() and \
			pos.x <= right() and \
			pos.y <= bottom()
