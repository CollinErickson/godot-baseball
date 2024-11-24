extends Node3D

enum char_options {AJ, option_2}
@export var character:char_options = char_options.AJ

var char_AJ = load("res://characters3D/AJ/AJ.tscn")



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
	var charnode = null
	if character == char_options.AJ:
		print("in char 3d: Creating AJ")
		charnode = char_AJ.instantiate()
	else:
		print('nothing selected...')
		charnode = char_AJ.instantiate()
	print('charnode', charnode)
	charnode.name = 'charnode'
	add_child(charnode)
	start_animation('a')

func start_animation(anim_name:String) -> void:
	#$charnode
	if anim_name == "idle":
		$charnode/AnimationTree.set("parameters/conditions/moving", false)
		$charnode/AnimationTree.set("parameters/conditions/idle", true)
	elif anim_name == "running":
		$charnode/AnimationTree.set("parameters/conditions/idle", false)
		$charnode/AnimationTree.set("parameters/conditions/moving", true)
