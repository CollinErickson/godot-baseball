extends Control

func _ready() -> void:
	set_active(false)

signal button_pressed_signal
func _process(_delta: float) -> void:
	# Don't do anything within 1 second of reaching page
	if Time.get_ticks_msec() - time_set_active < 1000:
		return
	
	# Return to main menu if any button is pressed
	if (Input.is_action_just_pressed("ui_accept") or
		Input.is_action_just_pressed("swing") or
		Input.is_action_just_pressed("click")
	):
		set_active(false)
		button_pressed_signal.emit()

var time_set_active = null
func set_active(is_active:bool) -> void:
	set_process(is_active)
	visible = is_active
	time_set_active = Time.get_ticks_msec()
