extends navigable_button_adjustable
class_name navigable_button_adjustable_int_range

@export var from:int = 0
@export var to:int = 1

func _ready() -> void:
	assert(from <= to)
	values = []
	for i in range(from, to + 1):
		values.push_back(i)
	
	super._ready()
