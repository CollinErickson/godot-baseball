extends Node3D

@export var body_width: float
@export var body_length: float
@export var head_width: float
@export var head_length: float
@export var color: Color
@export var angle_degrees: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	make_arrow()

func make_arrow():
	#print("Running make_annulus")
	assert(body_width >= 0)
	assert(body_length >= 0)
	assert(head_width >= 0)
	assert(head_length >= 0)
	
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var verts = PackedVector3Array()
	var colors = PackedColorArray()
	var normals = PackedVector3Array()
	
	# Vertices	
	var tail_left = Vector3(-body_width/2.,0,0).rotated(Vector3(0,1,0), angle_degrees/180.*PI)
	var tail_right = Vector3(body_width/2.,0,0).rotated(Vector3(0,1,0), angle_degrees/180.*PI)
	var split_left = Vector3(-body_width/2.,0,body_length).rotated(Vector3(0,1,0), angle_degrees/180.*PI)
	var split_right = Vector3(body_width/2.,0,body_length).rotated(Vector3(0,1,0), angle_degrees/180.*PI)
	var head_tip = Vector3(0,0,body_length + head_length).rotated(Vector3(0,1,0), angle_degrees/180.*PI)
	var head_left = Vector3(-head_width/2.,0,body_length).rotated(Vector3(0,1,0), angle_degrees/180.*PI)
	var head_right = Vector3(head_width/2.,0,body_length).rotated(Vector3(0,1,0), angle_degrees/180.*PI)
	
	# First triangle of body
	verts.push_back(tail_left)
	verts.push_back(tail_right)
	verts.push_back(split_right)
	# Second triangle of body
	verts.push_back(tail_left)
	verts.push_back(split_right)
	verts.push_back(split_left)
	# Triangle of head
	verts.push_back(head_left)
	verts.push_back(head_right)
	verts.push_back(head_tip)
	# You think this is slicked back? This is pushed back.
		
	
	# Colors
	for i in range(len(verts)):
		colors.push_back(color)
	
	# Normals
	for i in range(len(verts)):
		normals.push_back(Vector3(0,1,0))
	
	surface_array[Mesh.ARRAY_VERTEX] = verts
	#surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	#surface_array[Mesh.ARRAY_INDEX] = indices
	surface_array[Mesh.ARRAY_COLOR] = colors

	# No blendshapes, lods, or compression used.
	#var meshnode = get_node("MeshInstance3D")
	var meshnode = MeshInstance3D.new()
	meshnode.mesh = ArrayMesh.new()
	add_child(meshnode)
	#printt('arrow color is', color)
	#meshnode.mesh.local_to_scene
	meshnode.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	var your_material = StandardMaterial3D.new()
	your_material.vertex_color_use_as_albedo = true # will need this for the array of colors
	meshnode.mesh.surface_set_material(0, your_material)   # will need uvs if using a texture
	#print("Finished make arrow")
