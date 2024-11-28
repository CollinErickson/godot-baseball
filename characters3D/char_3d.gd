extends Node3D

enum char_options {AJ, option_2}
@export var character:char_options = char_options.AJ

var char_AJ = load("res://characters3D/AJ/AJ.tscn")



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
	var charnode = null
	if character == char_options.AJ:
		#print("in char 3d: Creating AJ")
		charnode = char_AJ.instantiate()
	else:
		print('In char3d, no character selected!!!!')
		charnode = char_AJ.instantiate()
	#print('charnode', charnode)
	charnode.name = 'charnode'
	add_child(charnode)
	#start_animation('a')

func start_animation(anim_name:String) -> void:
	#$charnode
	if anim_name == "idle":
		$charnode/AnimationTree.set("parameters/conditions/moving", false)
		$charnode/AnimationTree.set("parameters/conditions/idle", true)
		$charnode/AnimationTree.set("parameters/conditions/swing", false)
		$charnode/AnimationTree.set("parameters/conditions/pitch", false)
	elif anim_name == "running":
		$charnode/AnimationTree.set("parameters/conditions/idle", false)
		$charnode/AnimationTree.set("parameters/conditions/swing", false)
		$charnode/AnimationTree.set("parameters/conditions/pitch", false)
		$charnode/AnimationTree.set("parameters/conditions/moving", true)
	elif anim_name == "batter_idle":
		$charnode/AnimationTree.set("parameters/conditions/idle", false)
		$charnode/AnimationTree.set("parameters/conditions/swing", false)
		$charnode/AnimationTree.set("parameters/conditions/batter_idle", true)
	elif anim_name == "swing":
		$charnode/AnimationTree.set("parameters/conditions/batter_idle", false)
		$charnode/AnimationTree.set("parameters/conditions/swing", true)
		$charnode/AnimationTree.set("parameters/conditions/idle", false)
	elif anim_name == "pitch":
		$charnode/AnimationTree.set("parameters/conditions/idle", false)
		$charnode/AnimationTree.set("parameters/conditions/pitch", true)
	else:
		push_error("Error in char_3d.gd, start_animation:  \t", anim_name)

func set_color(col):
	#printt('\t\t\t\tIN SET COLOR FOR CHAR3D')
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	#mat.vertex_color_use_as_albedo = true # will need this for the array of colors
	#meshnode.mesh.surface_set_material(0, mat)   # will need uvs if using a texture
	$charnode/Armature/Skeleton3D/Boy01_Body_Geo.set_material_override(mat)

	#print('dir mat', dir(mat))
	#printt('char test', $charnode/Armature/Skeleton3D/Boy01_Body_Geo.set_material_override)

func dir(class_instance):
	var output = {}
	var methods = []
	for method in class_instance.get_method_list():
		methods.append(method.name)
	
	output["METHODS"] = methods
	
	var properties = []
	for prop in class_instance.get_property_list():
		if prop.type == 3:
			properties.append(prop.name)
	output["PROPERTIES"] = properties
	
	return output
