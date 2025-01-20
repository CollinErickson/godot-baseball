extends Control

var is_active:bool = true

signal click_in_rect

func _process(_delta) -> void:
	if is_active:
		if Input.is_action_just_pressed("click"):
			var mpos = get_local_mouse_position()
			#printt('in pitch_select_click', get_local_mouse_position())
			#printt($VBoxContainer/NameRect1.position, $VBoxContainer/NameRect1.size)
			var rects = [
				$VBoxContainer/NameRect1,
				$VBoxContainer/NameRect2,
				$VBoxContainer/NameRect3,
				$VBoxContainer/NameRect4,
			]
			for i in range(len(rects)):
				var rect = rects[i]
				if (
					mpos.x >= rect.position.x and
					mpos.y >= rect.position.y and
					mpos.x <= rect.position.x + rect.size.x and
					mpos.y <= rect.position.y + rect.size.y
				):
					#print('click in rect', rect)
					click_in_rect.emit(i)
					return


func set_active(value:bool) -> void:
	is_active = value
	visible = value
