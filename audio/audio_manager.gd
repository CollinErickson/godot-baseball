extends Node

const BAT_HIT_SOUND: AudioStream = preload("res://audio/sounds/thud1.wav")

func _ready() -> void:
	play_sound("thud1")

func play_sound(_name:String) -> void:
	var x:AudioStreamPlayer = AudioStreamPlayer.new()
	x.stream = BAT_HIT_SOUND
	add_child(x)
	printt('playing thud')
	
	x.finished.connect(x.queue_free)
	x.play()
	#await x.finished
	#remove_child(x)
	#x.queue_free()
