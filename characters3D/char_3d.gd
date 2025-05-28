extends Node3D

enum char_options {AJ, Player1, none}
@export var character:char_options = char_options.Player1

var char_AJ = load("res://characters3D/AJ/AJ.tscn")
var char_Player1 = load("res://characters3D/Player1/player_1.tscn")

var current_animation_rotation:float = 0
var pause_info = null

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
		pass
		#print('In char3d, no character selected!!!!')
		#charnode = char_AJ.instantiate()
	
	charnode = char_Player1.instantiate()
	#print('charnode', charnode)
	charnode.name = 'charnode'
	add_child(charnode)
	#start_animation('a')
	
	# Hide bats by default, the batter will need to turn them on
	charnode.get_node('Armature/Skeleton3D/batR').visible = false
	charnode.get_node('Armature/Skeleton3D/batL').visible = false

func reset() -> void:
	# Undo current animation rotation
	rotate_y(-current_animation_rotation)
	current_animation_rotation = 0
	pause_info = null
	

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

func force_animation_idle() -> void:
	# Set parameters for idle
	$charnode/AnimationTree.set("parameters/conditions/moving", false)
	$charnode/AnimationTree.set("parameters/conditions/idle", true)
	$charnode/AnimationTree.set("parameters/conditions/swingR", false)
	$charnode/AnimationTree.set("parameters/conditions/swingL", false)
	$charnode/AnimationTree.set("parameters/conditions/pitchR", false)
	$charnode/AnimationTree.set("parameters/conditions/pitchL", false)
	$charnode/AnimationTree.set("parameters/conditions/throw", false)
	# https://docs.godotengine.org/en/stable/classes/class_animationnodestatemachineplayback.html#class-animationnodestatemachineplayback-method-start
	var state_machine = $charnode/AnimationTree.get("parameters/playback")
	state_machine.start("idle")

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
	
	
	var primary_body = ["torso", "shoulders"]
	var secondary_body = []
	
	match team.jersey_style:
		"PP":
			primary_body.append_array(["sleeve_left", "sleeve_right"])
		"PS":
			secondary_body.append_array(["sleeve_left", "sleeve_right"])
		_:
			push_error("Error in char_3d.gd team.jersey_style #91386")
	
	match team.hat_style:
		"PP":
			primary_body.append_array(["hat", "hat_bill"])
		"PS":
			primary_body.append("hat")
			secondary_body.append("hat_bill")
		"SP":
			primary_body.append("hat_bill")
			secondary_body.append("hat")
		"SS":
			secondary_body.append_array(["hat", "hat_bill"])
		_:
			push_error("Error in char_3d.gd team.hat_style #129728")
	
	#printt('prim body', primary_body, secondary_body)
	#printt('team stuff', team.jersey_style, team.hat_style)
	
	var mat_primary = StandardMaterial3D.new()
	mat_primary.albedo_color = team.color_primary
	for bp in primary_body:
		$charnode/Armature/Skeleton3D.get_node(bp).set_material_override(mat_primary)
	
	var mat_secondary = StandardMaterial3D.new()
	mat_secondary.albedo_color = team.color_secondary
	for bp in secondary_body:
		$charnode/Armature/Skeleton3D.get_node(bp).set_material_override(mat_secondary)
	
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
	
	# Set height
	$charnode/Armature/Skeleton3D.scale = Vector3.ONE * player.height_mult

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
	# Can't get animations to restart where they stopped. Giving up for now.
	#$charnode/AnimationTree.active = false
	#$charnode/AnimationTree.set_process(false)
	#$charnode/AnimationPlayer.pause()
	#$charnode/AnimationTree.set("parameters")
	#printt('$charnode/AnimationTree.set_process_callback', 
	#$charnode/AnimationTree.get_process_callback())
	#printt('char3d callback mode', $charnode/AnimationTree.get_callback_mode_process())
	#$charnode/AnimationTree.set_process_callback(2)
	#$charnode/AnimationTree.set_process(false)
	#$charnode/AnimationTree.set_physics_process(false)
	#$charnode/AnimationPlayer.set_process(false)
	#$charnode/AnimationPlayer.set_physics_process(false)
	###$charnode/AnimationTree.set_callback_mode_process(2)
	#printt('char3d callback mode', $charnode/AnimationTree.get_callback_mode_process())
	
	var state_machine = $charnode/AnimationTree.get("parameters/playback")
	
	pause_info = [state_machine.get_current_node()]
	state_machine.start("idle")

func unpause() -> void:
	#$charnode/AnimationTree.active = true
	#$charnode/AnimationTree.set_process_callback(1)
	###$charnode/AnimationTree.set_callback_mode_process(1)
	if pause_info == null:
		return
	var state_machine = $charnode/AnimationTree.get("parameters/playback")
	state_machine.start(pause_info[0], false)
	pause_info = null


func set_glove(throwsR:bool) -> void:
	$charnode/Armature/Skeleton3D/gloveL.visible = throwsR
	$charnode/Armature/Skeleton3D/gloveR.visible = !throwsR
	$charnode/Armature/Skeleton3D/hand_left.visible = !throwsR
	$charnode/Armature/Skeleton3D/hand_right.visible = throwsR
	$charnode/Armature/Skeleton3D/thumb_left.visible = !throwsR
	$charnode/Armature/Skeleton3D/thumb_left.visible = throwsR
