extends Node3D

enum char_options {AJ, Player1, none}
@export var character:char_options = char_options.Player1

var char_AJ = load("res://characters3D/AJ/AJ.tscn")
var char_Player1 = load("res://characters3D/Player1/player_1.tscn")

var current_animation_rotation:float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
	var charnode = null
	if character == char_options.AJ:
		#print("in char 3d: Creating AJ")
		#charnode = char_AJ.instantiate()
		#charnode = char_Player1.instantiate()
		pass
	else:
		print('In char3d, no character selected!!!!')
		#charnode = char_AJ.instantiate()
	
	charnode = char_Player1.instantiate()
	#print('charnode', charnode)
	charnode.name = 'charnode'
	add_child(charnode)
	#start_animation('a')

func reset() -> void:
	# Undo current animation rotation
	rotate_y(-current_animation_rotation)
	current_animation_rotation = 0
	

func start_animation(anim_name:String, batsR:bool, throwsR:bool) -> void:
	# Undo current animation rotation
	rotate_y(-current_animation_rotation)
	current_animation_rotation = 0
	
	#$charnode
	if anim_name == "idle":
		$charnode/AnimationTree.set("parameters/conditions/moving", false)
		$charnode/AnimationTree.set("parameters/conditions/idle", true)
		$charnode/AnimationTree.set("parameters/conditions/swingR", false)
		$charnode/AnimationTree.set("parameters/conditions/swingL", false)
		$charnode/AnimationTree.set("parameters/conditions/pitchR", false)
		$charnode/AnimationTree.set("parameters/conditions/pitchL", false)
		$charnode/AnimationTree.set("parameters/conditions/throw", false)
	elif anim_name == "running":
		$charnode/AnimationTree.set("parameters/conditions/idle", false)
		$charnode/AnimationTree.set("parameters/conditions/swingR", false)
		$charnode/AnimationTree.set("parameters/conditions/swingL", false)
		$charnode/AnimationTree.set("parameters/conditions/pitchR", false)
		$charnode/AnimationTree.set("parameters/conditions/pitchL", false)
		$charnode/AnimationTree.set("parameters/conditions/moving", true)
	elif anim_name == "batter_idle":
		$charnode/AnimationTree.set("parameters/conditions/idle", false)
		$charnode/AnimationTree.set("parameters/conditions/swingR", false)
		$charnode/AnimationTree.set("parameters/conditions/swingL", false)
		$charnode/AnimationTree.set("parameters/conditions/batter_idle", true)
	elif anim_name == "swing":
		current_animation_rotation = PI/2 * (1 if batsR else -1)
		rotate_y(current_animation_rotation)
		$charnode/AnimationTree.set("parameters/conditions/batter_idle", false)
		if batsR:
			$charnode/AnimationTree.set("parameters/conditions/swingR", true)
		else:
			$charnode/AnimationTree.set("parameters/conditions/swingL", true)
		$charnode/AnimationTree.set("parameters/conditions/idle", false)
	elif anim_name == "pitch":
		#current_animation_rotation = PI/2 * (1 if !batsR else -1)
		#rotate_y(current_animation_rotation)
		$charnode/AnimationTree.set("parameters/conditions/idle", false)
		if throwsR:
			$charnode/AnimationTree.set("parameters/conditions/pitchR", true)
		else:
			$charnode/AnimationTree.set("parameters/conditions/pitchL", true)
	elif anim_name == "throw":
		$charnode/AnimationTree.set("parameters/conditions/idle", false)
		$charnode/AnimationTree.set("parameters/conditions/moving", false)
		$charnode/AnimationTree.set("parameters/conditions/throw", true)
	else:
		push_error("Error in char_3d.gd, start_animation:  \t", anim_name)

func set_color(col):
	#printt('\t\t\t\tIN SET COLOR FOR CHAR3D')
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	#mat.vertex_color_use_as_albedo = true # will need this for the array of colors
	#meshnode.mesh.surface_set_material(0, mat)   # will need uvs if using a texture
	#if character == char_options.AJ:
		#$charnode/Armature/Skeleton3D/Boy01_Body_Geo.set_material_override(mat)
	#elif character == char_options.Player1:
	#printt('exists', $charnode/Armature/Skeleton3D.get_children())
	$charnode/Armature/Skeleton3D/torso.set_material_override(mat)
	$charnode/Armature/Skeleton3D/shoulders.set_material_override(mat)
	$charnode/Armature/Skeleton3D/hat.set_material_override(mat)

	#print('dir mat', dir(mat))
	#printt('char test', $charnode/Armature/Skeleton3D/Boy01_Body_Geo.set_material_override)

func set_color_from_team(player, team, is_home_team:bool) -> void:
	if player == null:
		return
	var mat = StandardMaterial3D.new()
	mat.albedo_color = team.color_primary
	var primary_body = ["torso", "shoulders", "hat"]
	for bp in primary_body:
		$charnode/Armature/Skeleton3D.get_node(bp).set_material_override(mat)
	#$charnode/Armature/Skeleton3D/torso.set_material_override(mat)
	#$charnode/Armature/Skeleton3D/shoulders.set_material_override(mat)
	#$charnode/Armature/Skeleton3D/hat.set_material_override(mat)
	var mat2 = StandardMaterial3D.new()
	mat2.albedo_color = team.color_secondary
	var secondary_body = ["hat_bill", "sleeve_left", "sleeve_right"]
	for bp in secondary_body:
		$charnode/Armature/Skeleton3D.get_node(bp).set_material_override(mat2)
	
	# Change pants color based on home/away
	var matha = StandardMaterial3D.new()
	if is_home_team:
		matha.albedo_color = Color("white")
	else:
		matha.albedo_color = Color('gray')
	var ha_body = ["hips", "leg_left", "leg_right"]
	for bp in ha_body:
		$charnode/Armature/Skeleton3D.get_node(bp).set_material_override(matha)
	
	# Set skin color
	var skin_body = ["arm_left", "arm_right", 
					"hand_left", 'hand_right',
					'head',
					]
	var mat_skin = StandardMaterial3D.new()
	mat_skin.albedo_color = player.skin_color
	for bp in skin_body:
		$charnode/Armature/Skeleton3D.get_node(bp).set_material_override(mat_skin)
	

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

func pause() -> void:
	$charnode/AnimationTree.active = false

func unpause() -> void:
	$charnode/AnimationTree.active = true
