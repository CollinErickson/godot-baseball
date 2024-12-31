extends Node3D

@export var Type: String

#var wall_color = "Red"
var wall_color = Color(0,0,1,1)

# wall_array is array with:
# (angle: 0 is LF, 90 is RF, distance from home in FT, height in FT)
# To connect back to starting point, duplicate first element at end
var wall_array = [
	[-15, 270, 20],
	[0, 320, 10],
	[30, 370, 15],
	[45, 408, 16],
	[60, 350, 15],
	[90, 310, 8],
	[105, 250, 20]
	#[0,400,10],
	#[90,600,90]
]
# Aligned with coordinates, for testing
#var wall_array = [
	#[0, 400*sqrt(3)/2., 100],
	#[30, 400, 100],
	#[90, 200, 100]
#]
# Aligned with coordinates, for testing
#var wall_array = [
	#[0, 200, 100],
	#[60, 400, 100],
	#[90, 400*sqrt(3)/2., 100]
#]

var wall_coords:Array = []
var mindist:float = 1e9
var mindists:Array = Array()
func cosd(angle):
	return cos(angle*PI/180)
func sind(angle):
	return sin(angle*PI/180)

func _ready() -> void:
	# Create the mesh for the wall
	make_wall()
	
	# Find min distance to each wall segment
	for i in range(len(wall_array)-1):
		var u1 = Vector2(cosd(wall_array[i][0]), sind(wall_array[i][0])) * wall_array[i][1]
		var u2 = Vector2(cosd(wall_array[i+1][0]), sind(wall_array[i+1][0])) * wall_array[i+1][1]
		var w = u2 - u1
		var proj_u1_on_w = u1.dot(w) / w.dot(w) * w
		var u1_norm = u1 - proj_u1_on_w
		mindists.push_back(u1_norm.length())
	#printt('mindists', mindists)
	#for i in wall_array:
	#	mindist = min(mindist, i[1])
	mindist = mindists.min()
	#printt("Min wall dist is", mindist)
	
	# wall_coords: array of 3D points in global coords of top of wall
	for i in range(len(wall_array)):
		wall_coords.push_back(Vector3(
			wall_array[i][1]*cosd(wall_array[i][0]),
			wall_array[i][2]/3,
			wall_array[i][1]*sind(wall_array[i][0])
		))

func make_wall():
	#print("Running make_wall")
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
		colors.push_back(wall_color)
	
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
	#print("Finished make wall")

var restitution_coef = .6 # multiplied by ball restituion_coefv
func check_object_cross(pos:Vector3, prev_pos:Vector3):
	## Check if ball crossed a wall
	##
	## Find if the ball crossed a wall. If it did, give the updated position
	## and velocity.
	#printt('ball pos is', pos)
	if pos.x**2 + pos.z**2 < mindist/3:
		return [false]
	# Find angle of ball where 0 is LF, 90 is RF. In range [-90, 270].
	var ball_angle = atan(pos.z / pos.x) * 180 / PI
	ball_angle = fposmod(ball_angle, 360)
	if ball_angle > 270:
		ball_angle -= 360
	var prev_ball_angle = atan(prev_pos.z / prev_pos.x) * 180 / PI
	prev_ball_angle = fposmod(prev_ball_angle, 360)
	if prev_ball_angle > 270:
		prev_ball_angle -= 360
	#printt('in check_ball_cross ball_angle is', ball_angle)
	for i in range(len(wall_array) - 1):
		# Find if between two points and at least as far as the closest point on that section
		if (
			(fposmod(ball_angle - wall_array[i][0], 360.) <=
				 fposmod(wall_array[i+1][0] - wall_array[i][0], 360.) or 
				fposmod(prev_ball_angle - wall_array[i][0], 360.) <=
				 fposmod(wall_array[i+1][0] - wall_array[i][0], 360.)
				) and
			 sqrt(pos.x**2 + pos.z**2) >= mindists[i]/3.
			):
			#printt('ball angles', ball_angle, prev_ball_angle,
			#wall_array[i][0], wall_array[i+1][0])
			# Check if beyond that wall
			# This math was complicated, but essentially you find the intersection of two lines
			# Fit line z=mx+k (since walls are vertical, y is always 0), using points of wall
			var wall_left_x =  wall_array[i][1]*cosd(wall_array[i][0])
			var wall_left_z =  wall_array[i][1]*sind(wall_array[i][0])
			var wall_right_x =  wall_array[i+1][1]*cosd(wall_array[i+1][0])
			var wall_right_z =  wall_array[i+1][1]*sind(wall_array[i+1][0])
			
			var intersect_out = intersect_two_line_segments(
						Vector2(wall_left_x, wall_left_z)/3,
						Vector2(wall_right_x, wall_right_z)/3,
						Vector2(prev_pos.x, prev_pos.z), 
						Vector2(pos.x, pos.z)
					)
			if not intersect_out[0]:
				return [false]
			else:
				return [true, intersect_out, i, [wall_left_x, wall_left_z, wall_right_x, wall_right_z]]
	# Found no contact
	return [false]

func check_ball_cross(pos:Vector3, vel, cor, prev_pos:Vector3, _prev_vel,
						is_sim:bool):
	var wall_cross_info = check_object_cross(pos, prev_pos)
	if !wall_cross_info[0]:
		return [false]
	# Now we know it crossed the wall in x-z dimensions, but not where on y
	var i = wall_cross_info[2]
	var intersect_out = wall_cross_info[1]
	var wall_left_x = wall_cross_info[3][0]
	var wall_left_z = wall_cross_info[3][1]
	var wall_right_x = wall_cross_info[3][2]
	var wall_right_z = wall_cross_info[3][3]
	
	# If the ball went from out of field back into play, don't reflect it
	# One line segment for wall, one from home plate to current position
	#if intersect_two_line_segments(
		#Vector2(wall_left_x, wall_left_z),
		#Vector2(wall_right_x, wall_right_z),
		#Vector2(0, 0),
		#Vector2(pos.x, pos.z)
	#):
	if (Vector3(pos.x, 0, pos.z) - Vector3(wall_left_x, 0, wall_left_z)/3).cross(
		Vector3(wall_right_x, 0, wall_right_z)/3 - Vector3(wall_left_x, 0, wall_left_z)/3
	).y > 0:
		#printt('cross product is wrong way, allowing back through hit wall')
		return [false]
	
	#printt('found intersect', pos, prev_pos, intersect_out)
	var intersect_x = intersect_out[1].x
	var intersect_z = intersect_out[1].y
	# Find y coordinate of crossing
	var second_intersect = intersect_two_line_segments(
		Vector2(intersect_x, 0),
		Vector2(intersect_x, 1e4),
		Vector2(pos.x, pos.y),
		Vector2(prev_pos.x, prev_pos.y)
	)
	#printt('found 2nd intersect', second_intersect)
	var intersect_y = second_intersect[1].y
	# intersect_v is the intersect point
	var intersect_v = Vector3(intersect_x, intersect_y, intersect_z)
	var wall_length_to_left = intersect_out[1].distance_to(
			Vector2(wall_left_x, wall_left_z)/3)
	var wall_length_to_right = intersect_out[1].distance_to(
			Vector2(wall_right_x, wall_right_z)/3)
	var weight = wall_length_to_right / (wall_length_to_right + wall_length_to_left)
	#var wall_dist = v_intersect.length() #weight * wall_array[i][1] + (1 - weight) * wall_array[i+1][1]
	var wall_height_ft = weight * wall_array[i][2] + (1 - weight) * wall_array[i+1][2]
	#printt('check weight', wall_length_to_left, wall_length_to_right, wall_height_ft, weight)
	var is_over = intersect_y > wall_height_ft / 3.
	if is_over:
		print("in wall: OVER wall")
		return [true, is_over]
	#print('In wall: HIT wall')
	
	# Reflect position vector across wall for part after intersection point, dampen with cor proportionally
	var diff_pos_after_wall = pos - intersect_v
	if not is_sim:
		pass
	var mirrored_diff_pos_after_wall = mirror_vector_across_plane(
		diff_pos_after_wall,
		Vector3(wall_left_x, 10, wall_left_z),
		Vector3(wall_left_x, 0, wall_left_z),
		Vector3(wall_right_x, 0, wall_right_z)
	)
	var reflect_pos = intersect_v + cor * restitution_coef * mirrored_diff_pos_after_wall
	
	# Reflect velocity vector across wall, dampen with cor fully
	var reflect_vel = mirror_vector_across_plane(
		vel,
		Vector3(wall_left_x, 10, wall_left_z).rotated(Vector3(0,1,0), -45*PI/180),
		Vector3(wall_left_x, 0, wall_left_z).rotated(Vector3(0,1,0), -45*PI/180),
		Vector3(wall_right_x, 0, wall_right_z).rotated(Vector3(0,1,0), -45*PI/180)
	)
	var new_vel = cor * restitution_coef * reflect_vel
	#printt('check reflect vel', vel, rotated_vel, reflect_vel, new_vel)
	
	return [true, is_over, reflect_pos, new_vel]

func check_fielder_cross(pos, prev_pos) -> Array:
	var wall_cross_info = check_object_cross(pos, prev_pos)
	if !wall_cross_info[0]:
		return [false]
	# Now we know it crossed the wall in x-z dimensions, but not where on y
	#var i = wall_cross_info[2]
	var intersect_out = wall_cross_info[1]
	var wall_left_x = wall_cross_info[3][0]
	var wall_left_z = wall_cross_info[3][1]
	var wall_right_x = wall_cross_info[3][2]
	var wall_right_z = wall_cross_info[3][3]
	
	if (Vector3(pos.x, 0, pos.z) - Vector3(wall_left_x, 0, wall_left_z)/3).cross(
		Vector3(wall_right_x, 0, wall_right_z)/3 - Vector3(wall_left_x, 0, wall_left_z)/3
	).y > 0:
		#printt('cross product is wrong way, allowing back through hit wall')
		return [false]
	
	#printt('found intersect', pos, prev_pos, intersect_out)
	var intersect_x = intersect_out[1].x
	var intersect_z = intersect_out[1].y
	return [true, Vector3(intersect_x, 0, intersect_z)]

func check_fielder_correct_side(pos:Vector3, _prev_pos:Vector3, buffer:float=0) -> Array:
	## Check if fielder is on the correct side of the walls
	##
	## Returns [bool whether on correct side, position where they should be
	# TODO: in corners this returns after first wall. Keep doing next wall too.
	if sqrt(pos.x**2 + pos.z**2) < mindist/3:
		return [true]
	for iwall in range(len(wall_array) - 1):
		# vector in direction of wall
		# TODO: store along_walls and normal_outs so it's not recalculated every time
		var along_wall:Vector3 = wall_coords[iwall+1]/3 - wall_coords[iwall]/3
		along_wall.y = 0
		var normal_out:Vector3 = along_wall.rotated(
			Vector3(0,1,0), 90.*PI/180).normalized()
		var f = (pos + buffer*normal_out) - wall_coords[iwall]/3
		f.y = 0
		if normal_out.dot(f) > 0:
			# They are on the wrong side
			# Find where they should be
			var replace_pos = (f.dot(along_wall) * along_wall / along_wall.length_squared()
				) + wall_coords[iwall]/3 - buffer*normal_out
			replace_pos.y = 0
			#printt('in wall check_fielder_correct_side: on the wrong side of the wall')
			return [false, replace_pos]
	return [true]

func nearest_point_on_plane(v0, v1, v2, x):
	# https://www.physicsforums.com/threads/projection-of-a-point-on-the-plane-defined-by-3-other-points.704826/
	#var v0 = Vector3(0,0,0)
	#var v1 = Vector3(1,0,0)
	#var v2 = Vector3(0,-1,0)
	if v2.length_squared() <= 0:
		var tmp = v2
		v2 = v0
		v0 = tmp
	if v1.length_squared() <= 0:
		var tmp = v1
		v1 = v0
		v0 = tmp
	var cross = v1.cross(v2)
	printt('CROSS', cross)
	# Find closest point to x on plane
	#var v3 = Vector3(1,1,4)
	var t = -(cross[0]*(x[0]-v0[0]) + cross[1]*(x[1]-v0[1]) + cross[2]*(x[2]-v0[2])
				) / (cross[0]**2 + cross[1]**2 + cross[2]**2)
	printt('t is', t)
	var nearest_point = x + Vector3(cross[0]*t, cross[1]*t, cross[2]*t)
	printt('nearest point is', nearest_point)
	return nearest_point
	
func intersect_two_lines(u1: Vector2, u2: Vector2, v1: Vector2, v2: Vector2) -> Vector2:
	# u1 and u2 form one line, v1 and v2 form second. All in 2D.
	var mu = (u2.y - u1.y) / (u2.x - u1.x)
	var mv = (v2.y - v1.y) / (v2.x - v1.x)
	if u2.x == u1.x:
		return Vector2(u1.x, v2.y + mv*(u1.x - v2.x))
	if v2.x == v1.x:
		return Vector2(v1.x, u2.y + mu*(v1.x - u2.x))
	assert(mu != mv)
	var bu = u2.y - mu * u2.x
	var bv = v2.y - mv * v2.x
	var x = -(bv - bu) / (mv - mu)
	var y = mu*x + bu
	return Vector2(x, y)

func intersect_two_line_segments(u1: Vector2, u2: Vector2, v1: Vector2, v2: Vector2) -> Array:
	# u1 and u2 form one line, v1 and v2 form second. All in 2D.
	# Returns array: [whether there is intersection, intersect point]
	var w = intersect_two_lines(u1, u2, v1, v2)
	if sign((u1 - w).dot(u2 - w)) >= 0:
		return [false, w, (u1 - w).dot(u2 - w), u1, u2, w]
	if sign((v1 - w).dot(v2 - w)) >= 0:
		return [false, w, (v1 - w).dot(v2 - w), v1, v2, w]
	return [true, w]

func mirror_vector_across_plane(v: Vector3, u1: Vector3, u2: Vector3, u3: Vector3) -> Vector3:
	var normal_u = (u3 - u1).cross(u2 - u1).normalized()
	var normal_v = (v.dot(normal_u) / normal_u.dot(normal_u)) * normal_u
	var tangent_v = v - normal_v
	#printt("mirroring", tangent_v - normal_v, v, tangent_v, normal_v, normal_u)
	#printt('MIRRORING lengths', (tangent_v - normal_v).length(), v.length())
	return tangent_v - normal_v
	
