extends Node3D

@export var inner_radius: float
@export var outer_radius: float
@export var color: Color
@export var segments = 64

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	make_annulus()

func make_annulus():
	print("Running make_annulus", inner_radius, outer_radius)
	assert(outer_radius > inner_radius)
	assert(inner_radius > 0)
	
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var verts = PackedVector3Array()
	var colors = PackedColorArray()
	var normals = PackedVector3Array()
	
	# Vertices
	var delta_angle = 2*PI/segments
	for i in range(segments):
		var angle1 = delta_angle * i
		var angle2 = delta_angle * (i+1)
		var inner1 = Vector3(sin(angle1), 0, cos(angle1)) * inner_radius
		var inner2 = Vector3(sin(angle2), 0, cos(angle2)) * inner_radius
		var outer1 = Vector3(sin(angle1), 0, cos(angle1)) * outer_radius
		var outer2 = Vector3(sin(angle2), 0, cos(angle2)) * outer_radius
		
		# First triangle
		verts.push_back(inner1)
		verts.push_back(inner2)
		verts.push_back(outer1)
		# Second triangle
		verts.push_back(outer1)
		verts.push_back(inner2)
		verts.push_back(outer2)
		
	
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
	meshnode.name = "MeshNode"
	meshnode.mesh = ArrayMesh.new()
	#meshnode.mesh.name = "Mesh"
	add_child(meshnode)
	#printt('annulus color is', color)
	#meshnode.mesh.local_to_scene
	meshnode.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	var your_material = StandardMaterial3D.new()
	your_material.vertex_color_use_as_albedo = true # will need this for the array of colors
	meshnode.mesh.surface_set_material(0, your_material)   # will need uvs if using a texture
	#print("Finished make annulua")

#func set_color(col:Color) -> void:
	#printt('starting annulus set_color', col)
	#get_node("MeshNode")
	#get_node("MeshNode").mesh
	#get_node("MeshNode").mesh
	#MeshInstance3D.new().get
	#printt('finished annulus set_color')
	
	# Couldn't get this to change color. Just going to have two annuli.
	
