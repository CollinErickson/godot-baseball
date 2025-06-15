extends Node3D

enum char_options {AJ, Player1, Player2, none}
@export var character:char_options = char_options.Player1

var char_AJ = load("res://characters3D/AJ/AJ.tscn")
var char_Player1 = load("res://characters3D/Player1/player_1.tscn")
var char_Player2 = load("res://characters3D/Player2/unanimated/player_2_unanimated.tscn")

var current_animation_rotation:float = 0
var pause_info = null
var skeleton_node
var state_machine
var anim_player:AnimationPlayer = AnimationPlayer.new()

func _ready() -> void:
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
	
	charnode = char_Player2.instantiate()
	charnode.name = 'charnode'
	add_child(charnode)
	
	# Player2 has different skeleton node than Player1 had
	if character == char_options.Player2 or true:
		skeleton_node = charnode.get_node('Armature/GeneralSkeleton')
	else:
		skeleton_node = charnode.get_node('Armature/Skeleton3D')
	
	# Hide bats by default, the batter will need to turn them on
	skeleton_node.get_node('batR').visible = false
	skeleton_node.get_node('batL').visible = false
	
	anim_player = $charnode/AnimationPlayer
	
	# Testing signal on animation done (works, but also gives idle/walking)
	$charnode/AnimationPlayer.connect('animation_finished', _on_anim_fin)

signal animation_finished_signal
func _on_anim_fin(anim_name:String) -> void:
	var anim_name2 = anim_name.split("/")[1]
	var anim_name3 = map_anim_name_back(anim_name2)
	#printt('in char 3D, animation finished', anim_name, anim_name2, anim_name3)
	animation_finished_signal.emit(anim_name3)

func reset() -> void:
	# Undo current animation rotation
	rotate_y(-current_animation_rotation)
	current_animation_rotation = 0
	
	pause_info = null

func map_anim_name(anim_name:String, batsR:bool, throwsR:bool) -> String:
	if anim_name == "idle":
		return 'idle'
	elif anim_name == "running":
		return 'standard run'
	elif anim_name == "batter_idle":
		if batsR:
			return 'Baseball Idle R'
		else:
			return 'Baseball Idle L'
	elif anim_name == "swing":
		if batsR:
			return 'Baseball Hit R'
		else:
			return 'Baseball Hit L'
	elif anim_name == "pitch":
		if throwsR:
			return 'Baseball Pitching R'
		else:
			return 'Baseball Pitching L'
	elif anim_name == "throw":
		if throwsR:
			return 'Throw Object R'
		else:
			return 'Throw Object L'
	elif anim_name == "toss":
		if throwsR:
			return 'Frisbee Throw R'
		else:
			return 'Frisbee Throw L'
	elif anim_name == "catch":
		if throwsR:
			return 'Rifle Punch R'
		else:
			return 'Rifle Punch L'
	elif anim_name == "catch_grounder":
		return 'Goalkeeper Catch Low'
	elif anim_name == "catch_chest":
		return 'Goalkeeper Catch Face'
	elif anim_name == "catch_jump":
		return 'Goalkeeper Catch Jump Straight'
	elif anim_name == "slide":
		return 'Running slide'
	else:
		push_error("Error in char_3d.gd, start_animation:  \t", anim_name)
		# Returning something that won't break
		return 'idle'

func map_anim_name_back(anim_name:String) -> String:
	if anim_name == "idle":
		return 'idle'
	if anim_name == 'standard run':
		return 'running'
	if anim_name in ['Baseball Idle R', 'Baseball Idle L']:
		return 'batter_idle'
	if anim_name in ['Baseball Hit R', 'Baseball Hit L']:
		return 'swing'
	if anim_name in ['Baseball Pitching R', 'Baseball Pitching L']:
		return 'pitch'
	if anim_name in ['Throw Object R', 'Throw Object L']:
		return 'throw'
	if anim_name in ['Frisbee Throw R', 'Frisbee Throw L']:
		return 'toss'
	if anim_name in ['Rifle Punch R', 'Rifle Punch L']:
		return 'catch'
	if anim_name == 'Goalkeeper Catch Low':
		return 'catch_grounder'
	if anim_name == 'Goalkeeper Catch Face':
		return 'catch_chest'
	if anim_name == 'Goalkeeper Catch Jump Straight':
		return 'catch_jump'
	if anim_name == 'Running Slide':
		return 'slide'
	#if anim_name == '':
		#return ''
	push_error("In char3D, no result for map_anim_name_back", anim_name)
	return ''

func start_animation(anim_name:String, batsR:bool, throwsR:bool) -> void:
	var anim_speed:float = 1.
	if map_anim_name(anim_name, batsR, throwsR).begins_with("Rifle") or \
		map_anim_name(anim_name, batsR, throwsR).begins_with("Goalkeeper"):
			anim_speed = 2.5
	anim_player.play(ap(map_anim_name(anim_name, batsR, throwsR)),
		-1, anim_speed)

func force_animation_idle() -> void:
	# No longer useful, does same thing as start_animation('idle')
	# Set parameters for idle
	anim_player.play(ap("idle"))

func queue_animation(anim_name:String, batsR:bool, throwsR:bool) -> void:
	# Add anim to the AnimPlayer queue
	anim_player.queue(ap(map_anim_name(anim_name, batsR, throwsR)))

func set_color(col):
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	#mat.vertex_color_use_as_albedo = true # will need this for the array of colors
	#meshnode.mesh.surface_set_material(0, mat)   # will need uvs if using a texture
	#if character == char_options.AJ:
		#skeleton_node.get_node('Boy01_Body_Geo.set_material_override(mat)
	#elif character == char_options.Player1:
	#printt('exists', $charnode/Armature/Skeleton3D.get_children())
	skeleton_node.get_node('torso').set_material_override(mat)
	skeleton_node.get_node('shoulders').set_material_override(mat)
	skeleton_node.get_node('hat').set_material_override(mat)

	#print('dir mat', dir(mat))
	#printt('char test', $charnode/Armature/Skeleton3D/Boy01_Body_Geo.set_material_override)

func set_color_from_team(player, team, is_home_team:bool) -> void:
	if player == null:
		return
	
	var primary_body:Array = ["torso", "shoulders"]
	var secondary_body:Array = []
	
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
	
	# Make material for primary color and set it
	var mat_primary = StandardMaterial3D.new()
	mat_primary.albedo_color = team.color_primary
	for bp in primary_body:
		skeleton_node.get_node(bp).set_material_override(mat_primary)
	
	# Make material for secondary color and set it
	var mat_secondary = StandardMaterial3D.new()
	mat_secondary.albedo_color = team.color_secondary
	for bp in secondary_body:
		skeleton_node.get_node(bp).set_material_override(mat_secondary)
	
	# Change pants color based on home/away
	var matha = StandardMaterial3D.new()
	if is_home_team:
		matha.albedo_color = Color("white")
	else:
		matha.albedo_color = Color('gray')
	var ha_body = ["hips", "leg_left", "leg_right"]
	for bp in ha_body:
		skeleton_node.get_node(bp).set_material_override(matha)
	
	# Set skin color
	var skin_body:Array = ["arm_left", "arm_right", 
							"hand_left", 'hand_right',
							'head',
							]
	var mat_skin = StandardMaterial3D.new()
	mat_skin.albedo_color = player.skin_color
	for bp in skin_body:
		skeleton_node.get_node(bp).set_material_override(mat_skin)
	
	# Set height
	skeleton_node.scale = Vector3.ONE * player.height_mult

# Tested function that would replicate dir() in Python, not great
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
	pause_info = [anim_player.get_current_animation()]
	anim_player.pause()

func unpause() -> void:
	if pause_info == null:
		return
	if pause_info[0] == "":
		pause_info = null
		return
	anim_player.play(pause_info[0])
	pause_info = null

func set_glove_visible(throws:String) -> void:
	assert(['R', 'L', 'none'].has(throws))
	skeleton_node.get_node('gloveL').visible = (throws == 'R')
	skeleton_node.get_node('gloveR').visible = (throws == 'L')
	skeleton_node.get_node('hand_left').visible = (throws != 'R')
	skeleton_node.get_node('hand_right').visible = (throws != 'L')
	skeleton_node.get_node('thumb_left').visible = (throws != 'R')
	skeleton_node.get_node('thumb_right').visible = (throws != 'L')

func set_bat_visible(bats) -> void:
	assert(['R', 'L', 'none'].has(bats))
	skeleton_node.get_node('batR').visible = (bats=='R')
	skeleton_node.get_node('batL').visible = (bats=='L')

func ap(x:String) -> String:
	return 'Player2AnimPack/' + x

func get_hand_global_position(throws:String) -> Vector3:
	assert(['L', 'R'].has(throws))
	var bone_idx : int = skeleton_node.find_bone("glove" + throws)
	var local_bone_transform : Transform3D = skeleton_node.get_bone_global_pose(bone_idx)
	var global_bone_pos : Vector3 = skeleton_node.to_global(local_bone_transform.origin)
	return global_bone_pos

func time_left_in_current_anim() -> float:
	return anim_player.current_animation_length - anim_player.current_animation_position
