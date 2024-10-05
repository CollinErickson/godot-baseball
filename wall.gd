extends Node3D

@export var Type: String

# (angle: 0 is LF, 90 is RF, distance from home in FT, height in FT)
var col = "Red"
var wall_array = [
	[-15, 270, 20],
	[0, 320, 10],
	[30, 370, 15],
	[45, 408, 15],
	[60, 350, 15],
	[90, 310, 8],
	[105, 250, 20]
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	make_wall()

func make_wall():
	print("Running make_wall")
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var verts = PackedVector3Array()
	#var uvs = PackedVector2Array()
	#var normals = PackedVector3Array()
	#var indices = PackedInt32Array()
	var colors = PackedColorArray()
	
	# Vertices
	#verts.push_back(Vector3(0,0,0))
	#verts.push_back(Vector3(2,0,0))
	#verts.push_back(Vector3(2,2,0))
	#verts.push_back(Vector3(2,2,0))
	#verts.push_back(Vector3(4,4,0))
	#verts.push_back(Vector3(4,2,0))
	for i in range(len(wall_array) - 1):
		if wall_array[i][0] >= wall_array[i+1][0]:
			printerr("Bad angle in wall")
		var v1 = wall_array[i][1]/3.*Vector3(0,0,1).rotated(Vector3(0,1,0), (90-wall_array[i][0])*PI/180)
		var v1up = v1 + Vector3(0, wall_array[i][2]/3.,0)
		var v2 = wall_array[i+1][1]/3.*Vector3(0,0,1).rotated(Vector3(0,1,0), (90-wall_array[i+1][0])*PI/180)
		var v2up = v2 + Vector3(0, wall_array[i+1][2]/3.,0)
		printt('WALL VERTEXES', v1, v1up, v2, v2up)
		
		# First triangle
		verts.push_back(v1)
		verts.push_back(v1up)
		verts.push_back(v2)
		# Second triangle
		verts.push_back(v1up)
		verts.push_back(v2up)
		verts.push_back(v2)
		
	
	#uvs.push_back(Vector2(.3,.4))
	#uvs.push_back(Vector2(.3,.4))
	#uvs.push_back(Vector2(.3,.4))
	
	#normals.push_back(Vector3(0,0,1))
	#normals.push_back(Vector3(0,0,1))
	#normals.push_back(Vector3(0,0,1))
	
	# Colors
	for i in range(len(verts)):
		#colors.push_back(Color(0,0,1,1))
		colors.push_back(col)
	
	surface_array[Mesh.ARRAY_VERTEX] = verts
	#surface_array[Mesh.ARRAY_TEX_UV] = uvs
	#surface_array[Mesh.ARRAY_NORMAL] = normals
	#surface_array[Mesh.ARRAY_INDEX] = indices
	surface_array[Mesh.ARRAY_COLOR] = colors
	#printt('new mesh is', surface_array)

	# No blendshapes, lods, or compression used.
	var meshnode = get_node("MeshInstance3D")
	meshnode.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	#meshnode.mesh
	#printt("printing dir?")
	#print((meshnode.mesh.get_method_list()))
	var your_material = StandardMaterial3D.new()
	meshnode.mesh.surface_set_material(0, your_material)   # will need uvs if using a texture
	your_material.vertex_color_use_as_albedo = true # will need this for the array of colors
	print("Finished make wall")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
