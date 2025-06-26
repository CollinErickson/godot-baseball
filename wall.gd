extends Node3D

@export var Type: String

var wall_color:Color = Color(0,0,1,1)
# Can't use the same color as dirt, this shows up too bright
var warning_track_color:Color = Color("#2b2b00")
var stands_color:Color = Color(1,0,0)

const gs1 = preload("res://resources/stadium/grandstand_1.tscn")

# wall_array is array with:
# (angle: 0 is LF, 90 is RF, distance from home in YD, height in YD)
# To connect back to starting point, duplicate first element at end
var wall_array1:Array = [
	[-15, 270./3, 20./3],
	[0, 320./3, 10./3],
	[30, 370./3, 15./3],
	[45, 408./3, 16./3],
	[60, 350./3, 15./3],
	[99, 310./3, 8./3],
	[105, 250./3, 20./3],
	[180, 90./3, 10./3],
	[270, 90./3, 10./3]
]
var wall_array:Array = [
	[-5, 150./3, 4./3],
	[0, 310./3, 37./3],
	[37, 380./3, 37./3],
	[37.01, 380./3, 18./3],
	[39, 375./3, 18./3],
	[50, 400./3, 18./3],
	[55, 380./3, 6./3],
	[83, 370./3, 6./3],
	[87, 355./3, 4./3],
	[90, 302./3, 4./3],
	[93, 230./3, 6./3],
	[96, 120./3, 6./3],
	[215, 40./3, 6./3],
	[225, 40./3, 6./3],
	[235, 40./3, 6./3],
	[330, 110./3, 6./3]
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

var grandstand_nodes:Array = []
var grandstand_normals:Array = []
var wall_coords:Array = []
var along_walls:Array = []
var normal_outs:Array = []
var mindist:float = 1e9
var mindists:Array = Array()
func cosd(angle):
	return cos(angle*PI/180)
func sind(angle):
	return sin(angle*PI/180)

func _ready() -> void:
	# Close the wall
	wall_array.push_back(wall_array[0])
	
	# Calculate values to be used later
	calculate_wall_info()
	
	# Create the mesh for the wall
	make_wall()
	
	# Create the warning track
	make_warning_track()
	
	# Create the stands
	#make_stands()
	make_grandstands()
	
	# Place foul poles (do after since need wall_coords)
	place_foul_poles()

func calculate_wall_info():
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
			wall_array[i][2],
			wall_array[i][1]*sind(wall_array[i][0])
		))
	for iwall in range(len(wall_array) - 1):
		# vector in direction of wall
		var along_wall:Vector3 = wall_coords[iwall+1] - wall_coords[iwall]
		along_wall.y = 0
		along_walls.push_back(along_wall)
		var normal_out:Vector3 = along_wall.rotated(
			Vector3(0,1,0), 90.*PI/180).normalized()
		normal_outs.push_back(normal_out)

func make_wall():
	#print("Running make_wall")
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var verts = PackedVector3Array()
	#var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	#var indices = PackedInt32Array()
	var colors = PackedColorArray()
	
	grandstand_nodes = []
	grandstand_normals = []
	
	# Vertices
	for i in range(len(wall_array) - 1):
		#if wall_array[i][0] >= wall_array[i+1][0]:
			#printerr("Bad angle in wall\t", wall_array[i], wall_array[i+1])
		var v1:Vector3 = wall_array[i][1] * Vector3(0,0,1).rotated(
			Vector3(0,1,0), (90-wall_array[i][0])*PI/180)
		var v1up:Vector3 = v1 + Vector3(0, wall_array[i][2],0)
		var v2:Vector3 = wall_array[i+1][1] * Vector3(0,0,1).rotated(
			Vector3(0,1,0), (90-wall_array[i+1][0])*PI/180)
		var v2up:Vector3 = v2 + Vector3(0, wall_array[i+1][2],0)
		#if wall_array[i][0] >= wall_array[i+1][0]:
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
		
		var norm_vec:Vector3 = (v1 - v2).cross(v1up - v1).normalized()
		for j in range(6):
			normals.push_back(norm_vec)
		
	# Colors
	for i in range(len(verts)):
		#colors.push_back(Color(0,0,1,1))
		colors.push_back(wall_color)
	
	assert(len(normals) == len(verts))
	
	surface_array[Mesh.ARRAY_VERTEX] = verts
	#surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
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

func make_warning_track():
	print("Running make_warning_track")
	var warning_track_width = 4
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var verts = PackedVector3Array()
	#var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	#var indices = PackedInt32Array()
	var colors = PackedColorArray()
	
	# Vertices
	for i in range(len(wall_array) - 1):
		#if wall_array[i][0] >= wall_array[i+1][0]:
			#printerr("Bad angle in wall\t", wall_array[i], wall_array[i+1])
		var v1:Vector3 = wall_array[i][1] * Vector3(0,0,1).rotated(
			Vector3(0,1,0), (90-wall_array[i][0])*PI/180)
		var v1close:Vector3 = v1 - v1.normalized() * warning_track_width
		var v2:Vector3 = wall_array[i+1][1] * Vector3(0,0,1).rotated(
			Vector3(0,1,0), (90-wall_array[i+1][0])*PI/180)
		var v2close:Vector3 = v2 - v2.normalized() * warning_track_width
		
		# Move them up a bit so they are above grass
		var y_offset:float = 0.001
		var y_offset_3d:Vector3 = Vector3(0,y_offset, 0)
		v1 += y_offset_3d
		v1close += y_offset_3d
		v2 += y_offset_3d
		v2close += y_offset_3d
		#if wall_array[i][0] >= wall_array[i+1][0]:
			#printt('WALL VERTEXES', v1, v1up, v2, v2up)
		
		# First triangle
		verts.push_back(v1)
		verts.push_back(v2)
		verts.push_back(v1close)
		# Second triangle
		verts.push_back(v1close)
		verts.push_back(v2)
		verts.push_back(v2close)
		
		for j in range(6):
			#uvs.push_back(Vector2(.3,.4))
			normals.push_back(Vector3(0,1,0))
			#indices.push_back(i)
	
	# Colors
	for i in range(len(verts)):
		#colors.push_back(Color(0,0,1,1))
		colors.push_back(warning_track_color)
	
	surface_array[Mesh.ARRAY_VERTEX] = verts
	#surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	#surface_array[Mesh.ARRAY_INDEX] = indices
	surface_array[Mesh.ARRAY_COLOR] = colors
	#printt('new mesh is', surface_array)

	# No blendshapes, lods, or compression used.
	var meshnode = get_node("WarningTrackMeshInstance3D")
	meshnode.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	var your_material = StandardMaterial3D.new()
	meshnode.mesh.surface_set_material(0, your_material)   # will need uvs if using a texture
	your_material.vertex_color_use_as_albedo = true # will need this for the array of colors
	#print("Finished make warning track")

func place_foul_poles() -> void:
	# Move foul pole mesh nodes to correct wall location
	# j==0 is left foul pole, j==1 is right
	for j in range(2):
		var target = null
		if j == 0:
			target = 0
		else:
			target = 90
		# Wall array has the first value copied as the last value, so no need
		#  to worry about wrap around
		for i in range(len(wall_array) - 1):
			var theta1 = wall_array[i][0]
			var theta2 = wall_array[i+1][0]
			var d1 = fposmod(target - theta1, 360)
			d1 = min(d1, 360 - d1)
			var d2 = fposmod(target - theta2, 360)
			d2 = min(d2, 360 - d2)
			var d12 = fposmod(theta2 - theta1, 360)
			if d1 + d2 <= d12 + 1e-12:
				var pole = get_parent().get_node("FoulPoleLeft" if j==0 else "FoulPoleRight")
				var x = intersect_two_lines(
					Vector2(0,0),
					Vector2(1,0) if j==0 else Vector2(0,1),
					Vector2(wall_coords[i].x,wall_coords[i].z),
					Vector2(wall_coords[i+1].x,wall_coords[i+1].z)
				)
				var target_dist = x[j]
				# Put it in front of the wall so it goes from ground up
				# It's 0.1 thick, so put it half in front. Also helps in case
				# wall is angled there.
				target_dist -= .05
				if target_dist > 30:
					if j==0:
						pole.position.x = target_dist
					else:
						pole.position.z = target_dist
				else:
					# Can't find foul pole location
					pole.visible = false
					push_error("Couldn't place foul pole", str(target_dist), x)
				break

func make_stands():
	print("Running make_stands")
	var stands_depth = 10
	var stands_slope = 1
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var verts = PackedVector3Array()
	#var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	#var indices = PackedInt32Array()
	var colors = PackedColorArray()
	
	# Vertices
	for i in range(len(wall_array) - 1):
		#if wall_array[i][0] >= wall_array[i+1][0]:
			#printerr("Bad angle in wall\t", wall_array[i], wall_array[i+1])
		var v1base:Vector3 = wall_array[i][1] * Vector3(0,0,1).rotated(
			Vector3(0,1,0), (90-wall_array[i][0])*PI/180)
		var v1up = v1base + Vector3(0, wall_array[i][2],0)
		var v1back = v1up + v1base.normalized() * stands_depth + stands_depth * stands_slope * Vector3(0,1,0)
		var v2base:Vector3 = wall_array[i+1][1] * Vector3(0,0,1).rotated(
			Vector3(0,1,0), (90-wall_array[i+1][0])*PI/180)
		var v2up = v2base + Vector3(0, wall_array[i+1][2],0)
		var v2back = v2up + v2base.normalized() * stands_depth + stands_depth * stands_slope * Vector3(0,1,0)
		
		# First triangle
		verts.push_back(v1up)
		verts.push_back(v1back)
		verts.push_back(v2up)
		# Second triangle
		verts.push_back(v1back)
		verts.push_back(v2back)
		verts.push_back(v2up)
		
		var norm_vec:Vector3 = (v2up - v1up).cross(v1back - v1up).normalized()
		for j in range(6):
			normals.push_back(norm_vec)
			#uvs.push_back(Vector2(.3,.4))
			#normals.push_back(Vector3(0,1,0))
			#indices.push_back(i)
	
	# Colors
	for i in range(len(verts)):
		#colors.push_back(Color(0,0,1,1))
		colors.push_back(stands_color)
	
	surface_array[Mesh.ARRAY_VERTEX] = verts
	#surface_array[Mesh.ARRAY_TEX_UV] = uvs
	#surface_array[Mesh.ARRAY_NORMAL] = normals
	#surface_array[Mesh.ARRAY_INDEX] = indices
	surface_array[Mesh.ARRAY_COLOR] = colors
	#printt('new mesh is', surface_array)

	# No blendshapes, lods, or compression used.
	var meshnode = get_node("StandsMeshInstance3D")
	meshnode.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	var your_material = StandardMaterial3D.new()
	meshnode.mesh.surface_set_material(0, your_material)   # will need uvs if using a texture
	your_material.vertex_color_use_as_albedo = true # will need this for the array of colors
	#print("Finished make warning track")

var restitution_coef = .6 # multiplied by ball restituion_coefv
func check_object_cross(pos:Vector3, prev_pos:Vector3):
	# Stopped using this since it wasn't working for foul balls
	## Check if ball crossed a wall
	##
	## Find if the ball crossed a wall. If it did, give the updated position
	## and velocity.
	#printt('ball pos is', pos)
	if pos.x**2 + pos.z**2 < mindist:
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
	#printt('in wall check_ball_cross ball_angle is', ball_angle, prev_ball_angle)
	for i in range(len(wall_array) - 1):
		# Find if between two points and at least as far as the closest point on that section
		if (
			(fposmod(ball_angle - wall_array[i][0], 360.) <=
				 fposmod(wall_array[i+1][0] - wall_array[i][0], 360.) or 
				fposmod(prev_ball_angle - wall_array[i][0], 360.) <=
				 fposmod(wall_array[i+1][0] - wall_array[i][0], 360.)
				) and
			 sqrt(pos.x**2 + pos.z**2) >= mindists[i]
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
						Vector2(wall_left_x, wall_left_z),
						Vector2(wall_right_x, wall_right_z),
						Vector2(prev_pos.x, prev_pos.z), 
						Vector2(pos.x, pos.z)
					)
			if not intersect_out[0]:
				return [false]
			else:
				return [true,
						intersect_out,
						i,
						[wall_left_x, wall_left_z, wall_right_x, wall_right_z]]
	# Found no contact
	return [false]

func check_object_cross2(pos, prev_pos) -> Array:
	# Trying to fix check_object_cross, it wasn't working on foul balls
	#printt('in wall check_object_cross2', pos, prev_pos)
	var pos_length = pos.length()
	if pos_length < mindist:
		return [false]
	for i in range(len(wall_array) - 1):
		if pos_length < mindists[i]:
			continue
		# Check that the ball position flipped sides of the wall using normal
		if ((normal_outs[i].dot(Vector3(pos.x,0,pos.z) -
						Vector3(wall_coords[i].x,0,wall_coords[i].z)) > 0) and
			(normal_outs[i].dot(Vector3(prev_pos.x,0,prev_pos.z) -
						Vector3(wall_coords[i].x,0,wall_coords[i].z)) <= 0)):
			# Use cross product to check if it's within the wall length
			var pos_diff_xz:Vector3 = Vector3(pos.x - prev_pos.x, 0, pos.z - prev_pos.z)
			var cross1:Vector3 = pos_diff_xz.cross(
				Vector3(wall_coords[i].x - prev_pos.x, 0, wall_coords[i].z - prev_pos.z))
			var cross2:Vector3 = pos_diff_xz.cross(
				Vector3(wall_coords[i+1].x - prev_pos.x, 0, wall_coords[i+1].z - prev_pos.z))
			if cross1.y * cross2.y <= 0:
				# Find the intersection point by solving system of equations
				# The two line segments must have overlapping point
				var u1 = prev_pos.x
				var u2 = prev_pos.z
				var d1 = pos.x - prev_pos.x
				var d2 = pos.z - prev_pos.z
				var v1 = wall_coords[i].x
				var v2 = wall_coords[i].z
				var e1 = wall_coords[i+1].x - wall_coords[i].x
				var e2 = wall_coords[i+1].z - wall_coords[i].z
				# Find where ball path crossed wall
				#u1 + t*d1 = v1 + s*e1 # (eqn for x)
				#u2 + t*d2 = v2 + s*e2 # (eqn for z)
				# 2 eqns, 2 unknowns
				# rearrange to matrix form
				#t*d1 - s*e1 = v1 - u1
				#t*d2 - s*e2 = v2 - u2
				#[d1  -e1] [t ] = [v1 - u1]
				#[d2  -e2] [s ] = [v2 - u2]
				# Inverse of left matrix
				#-1/(d1*e2 - d2*e1) [-e2  e1]
								   #[-d2  d1]
				var det = d1*-e2 +e1*d2
				var t = 1/det * (-e2*(v1 - u1) + e1*(v2 - u2))
				var s = 1/det * (-d2*(v1 - u1) + d1*(v2 - u2))
				var p_t = prev_pos + t*(pos - prev_pos)
				var _p_s = wall_coords[i] + s*(wall_coords[i+1] - wall_coords[i])
				
				return [true, [true, Vector2(p_t.x, p_t.z)], i, t, p_t]
	# Found no contact
	return [false]

func check_ball_cross(pos:Vector3, vel, cor, prev_pos:Vector3, _prev_vel,
						is_sim:bool):
	var wall_cross_info = check_object_cross2(pos, prev_pos)
	#if not is_sim:
		#printt('in wall check_ball_cross', pos, pos.length(), wall_cross_info,
			#check_object_cross2(pos, prev_pos))
	if !wall_cross_info[0]:
		return [false]
	# Now we know it crossed the wall in x-z dimensions, but not where on y
	var i = wall_cross_info[2]
	var intersect_out = wall_cross_info[1]
	#var wall_left_x = wall_cross_info[3][0]
	#var wall_left_z = wall_cross_info[3][1]
	#var wall_right_x = wall_cross_info[3][2]
	#var wall_right_z = wall_cross_info[3][3]
	var wall_left_x = wall_coords[i].x
	var wall_left_z = wall_coords[i].z
	var wall_right_x = wall_coords[i+1].x
	var wall_right_z = wall_coords[i+1].z
	
	# If the ball went from out of field back into play, don't reflect it
	# One line segment for wall, one from home plate to current position
	#if intersect_two_line_segments(
		#Vector2(wall_left_x, wall_left_z),
		#Vector2(wall_right_x, wall_right_z),
		#Vector2(0, 0),
		#Vector2(pos.x, pos.z)
	#):
	if (Vector3(pos.x, 0, pos.z) - Vector3(wall_left_x, 0, wall_left_z)).cross(
		Vector3(wall_right_x, 0, wall_right_z) - Vector3(wall_left_x, 0, wall_left_z)
	).y > 0:
		#printt('cross product is wrong way, allowing back through hit wall')
		return [false]
	
	##printt('found intersect', pos, prev_pos, intersect_out)
	#var intersect_x = intersect_out[1].x
	#var intersect_z = intersect_out[1].y
	## Find y coordinate of crossing
	#var second_intersect = intersect_two_line_segments(
		#Vector2(intersect_x, 0),
		#Vector2(intersect_x, 1e4),
		#Vector2(pos.x, pos.y),
		#Vector2(prev_pos.x, prev_pos.y)
	#)
	#var second_intersect = null
	##printt('found 2nd intersect', second_intersect)
	#var intersect_y = second_intersect[1].y
	## intersect_v is the intersect point
	#var intersect_v = Vector3(intersect_x, intersect_y, intersect_z)
	var intersect_v = wall_cross_info[4]
	#if not is_sim:
		#printt('wall intersect_v is', intersect_v, second_intersect, pos, prev_pos)
	var wall_length_to_left = intersect_out[1].distance_to(
			Vector2(wall_left_x, wall_left_z))
	var wall_length_to_right = intersect_out[1].distance_to(
			Vector2(wall_right_x, wall_right_z))
	var weight = wall_length_to_right / (wall_length_to_right + wall_length_to_left)
	#var wall_dist = v_intersect.length() #weight * wall_array[i][1] + (1 - weight) * wall_array[i+1][1]
	var wall_height_ft = weight * wall_array[i][2] + (1 - weight) * wall_array[i+1][2]
	#printt('check weight', wall_length_to_left, wall_length_to_right, wall_height_ft, weight)
	var is_over = intersect_v.y > wall_height_ft
	if is_over:
		if not is_sim:
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
	
	if (Vector3(pos.x, 0, pos.z) - Vector3(wall_left_x, 0, wall_left_z)).cross(
		Vector3(wall_right_x, 0, wall_right_z) - Vector3(wall_left_x, 0, wall_left_z)
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
	## Returns array: [bool whether on correct side, position where they should be]
	if sqrt(pos.x**2 + pos.z**2) < mindist:
		return [true]
	var adjusted_position:bool = false
	for iwall in range(len(wall_array) - 1):
		# vector in direction of wall
		var along_wall:Vector3 = along_walls[iwall]
		var normal_out:Vector3 = normal_outs[iwall]
		var f = (pos + buffer*normal_out) - wall_coords[iwall]
		f.y = 0
		# Check which side of wall player position is on 
		if normal_out.dot(f) > 0:
			# They are on the wrong side
			# Find where they should be
			pos = (f.dot(along_wall) * along_wall /
					along_wall.length_squared()
				) + wall_coords[iwall] - buffer*normal_out
			pos.y = 0
			adjusted_position = true
	if adjusted_position:
		return [false, pos]
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
	
func set_vis_based_on_camera(cam:Camera3D) -> void:
	# Set grandstand sections to only be visible if facing the camera
	# Updated to use the slant of the seats as the face
	# Issue when roof is in the way, but I think it's good	#print('in wall set_vis_based_on_camera')
	var camdir = cam.get_global_transform().basis.z
	#printt('in wall set gs nodes are', grandstand_nodes, camdir)
	for i in range(len(grandstand_nodes)):
		var gsn = grandstand_nodes[i]
		# Find vector along wall
		var gs_along:Vector3 = grandstand_normals[i].rotated(Vector3(0,1,0), PI/2)
		# Find the vector pointing into the face of the seats
		var gs_norm_face:Vector3 = grandstand_normals[i].rotated(gs_along, PI/4)
		#if randf() < .0001:
			#printt('in wall set gs', i, camdir, grandstand_normals[i],
				#gs_along, gs_norm_face,
				#grandstand_normals[i].dot(camdir), gs_norm_face.dot(camdir))
		# Old way just used the front
		#gsn.visible = grandstand_normals[i].dot(camdir) < 0
		# New way uses the face
		gsn.visible = gs_norm_face.dot(camdir) < 0
	#assert(false)

func make_grandstands():
	# Create and place stands around entire field
	for i in range(len(wall_array) - 1):
		var v1:Vector3 = wall_coords[i]
		var v2:Vector3 = wall_coords[i + 1]
		var v1up:Vector3 = v1 + Vector3(0, wall_array[i][2],0)
		var v2up:Vector3 = v2 + Vector3(0, wall_array[i+1][2],0)
		var norm_vec:Vector3 = normal_outs[i]
	
		# Add stadium section
		# Add multiple sections if needed
		# Each section is about 13m wide
		var n_sections:int = max(1, floori(v1.distance_to(v2) / 36))
		#printt('in wall gs n_sections', n_sections)
		for j in range(n_sections):
			var gs2 = gs1.instantiate()
			add_child(gs2)
			# Set rotation
			var rotate_angle_radians:float
			var vdiffnorm:Vector3 = (v2 - v1).normalized()
			if vdiffnorm.z >= 0:
				rotate_angle_radians = PI + asin(vdiffnorm.x)
			else:
				rotate_angle_radians = asin(-vdiffnorm.x)
			gs2.rotate_y(rotate_angle_radians)
			gs2.position = (v1 + v2) / 2.
			gs2.position = v1 + (2*j+1) * (v2 - v1) / 2. / n_sections
			gs2.position -= norm_vec * 17
			gs2.position.y = min(v1up.y, v2up.y)
			grandstand_nodes.push_back(gs2)
			
			# Store normal vector to know when to hide sections
			var gs_norm:Vector3 = norm_vec
			# Rotate to match the face of the seats?
			#gs_norm.rotated(v2 - v1, -PI/4)
			grandstand_normals.push_back(gs_norm)
