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
	#[0,400,10],
	#[90,600,90]
]

var mindist = 1e9
var mindists = Array()
func cosd(angle):
	return cos(angle*PI/180)
func sind(angle):
	return sin(angle*PI/180)
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	make_wall()
	
	for i in range(len(wall_array)-1):
		var u1 = Vector2(cosd(wall_array[i][0]), sind(wall_array[i][0])) * wall_array[i][1]
		var u2 = Vector2(cosd(wall_array[i+1][0]), sind(wall_array[i+1][0])) * wall_array[i+1][1]
		var w = u2 - u1
		var proj_u1_on_w = u1.dot(w) / w.dot(w) * w
		var u1_norm = u1 - proj_u1_on_w
		mindists.push_back(u1_norm.length())
	printt('mindists', mindists)
	#for i in wall_array:
	#	mindist = min(mindist, i[1])
	mindist = mindists.min()
	#printt("Min wall dist is", mindist)

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
		#printt('WALL VERTEXES', v1, v1up, v2, v2up)
		
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

var restitution_coef = .8 # multiplied by ball restituion_coefv
func check_ball_cross(pos, vel, cor):
	#printt('ball pos is', pos)
	if pos.x**2 + pos.z**2 < mindist/3:
		return [false]
	# Find angle of ball where 0 is LF, 90 is RF
	var ball_angle = atan(pos.z / pos.x) * 180 / PI
	ball_angle = fposmod(ball_angle, 360)
	if ball_angle > 270:
		ball_angle -= 360
	#printt('in check_ball_cross ball_angle is', ball_angle)
	for i in range(len(wall_array) - 1):
		# Find if between two points and at least as far as the closer
		if (#ball_angle >= wall_array[i][0] and 
			#ball_angle <= wall_array[i+1][0] and
			fposmod(ball_angle - wall_array[i][0], 360.) <=
				 fposmod(wall_array[i+1][0] - wall_array[i][0], 360.) and
			 sqrt(pos.x**2 + pos.z**2) >= mindists[i]/3.
			):
			#printt('check pos??', sqrt(pos.x**2 + pos.z**2), min(wall_array[i][1], wall_array[i+1][1])/3.)
			#print("maybe collision")
			#printt("WALL check:", pos, ball_angle, wall_array[i][0], wall_array[i+1][0],
			#
			#fposmod(720.+ball_angle - wall_array[i][0], 360.) ,
			#	 fposmod(wall_array[i+1][0] - wall_array[i][0], 360.) ,
			# sqrt(pos.x**2 + pos.z**2) >= mindists[i]/3.,
			# sqrt(pos.x**2 + pos.z**2) , wall_array[i][1]/3., wall_array[i+1][1]/3.)
			# Check if beyond that wall
			# This math was complicated, but essentially you find the intersection of two lines
			var m = (
				(wall_array[i+1][1]*cosd(wall_array[i+1][0]) - wall_array[i][1]*cosd(wall_array[i][0])) /
				(wall_array[i+1][1]*sind(wall_array[i+1][0]) - wall_array[i][1]*sind(wall_array[i][0]))
			)
			var z = wall_array[i+1][1]*cosd(wall_array[i+1][0]) - m*wall_array[i+1][1]*sind(wall_array[i+1][0])
			var x_intersect = -z / (m - 1/tan(ball_angle*PI/180))
			var y_intersect = m*x_intersect + z
			var v_intersect = Vector2(x_intersect, y_intersect)
			#printt("Wall check:", sqrt(pos.x**2 + pos.z**2) , v_intersect.length()/3.)
			if sqrt(pos.x**2 + pos.z**2) >= v_intersect.length()/3.:
				var wall_length_to_left = v_intersect.distance_to(
					Vector2(wall_array[i][1]*sind(wall_array[i][0]), wall_array[i][1]*cosd(wall_array[i][0])))
				var wall_length_to_right = v_intersect.distance_to(
					Vector2(wall_array[i+1][1]*sind(wall_array[i+1][0]), wall_array[i+1][1]*cosd(wall_array[i+1][0])))
				var weight = wall_length_to_right / (wall_length_to_right + wall_length_to_left)
				var wall_dist = v_intersect.length() #weight * wall_array[i][1] + (1 - weight) * wall_array[i+1][1]
				var wall_height = weight * wall_array[i][2] + (1 - weight) * wall_array[i+1][2]
				var is_over = pos.y > wall_height / 3.
				if is_over:
					return [true, is_over]
				# Bounce it off the vel
				var new_pos = pos
				var new_vel = vel
				# Reflect position vector across wall, dampen with cor
				# Reflect velocity vector across wall, dampen with cor
				return [true, is_over, new_pos, new_vel]
	# Found no contact
	return [false]
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
