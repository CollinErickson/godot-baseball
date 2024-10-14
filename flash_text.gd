extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func new_text(text_in : String, duration: float) -> void:
	text = text_in
	#printt('in flashtext new_text')
	get_node("Timer").wait_time = duration
	get_node("Timer").start()

func clear_text() -> void:
	#printt("in flashtext timer clear_text")
	get_node("Timer").stop()
	text = ''


func _on_timer_timeout() -> void:
	clear_text()
