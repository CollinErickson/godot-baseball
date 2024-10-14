extends Node3D

func _ready() -> void:
	set_process(false)

func _process(_delta: float) -> void:
	position = get_parent().get_parent().get_mouse_y0_pos()
