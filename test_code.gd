extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	var a=0
	var b=1
	#a, b = b, a
	printt('ab', a, b)
	var accel = Vector3(1,2,3)
	#print(pow(accel, 2)
	nearest_point_on_plane(Vector3(1,0,0), Vector3(0,1,0), Vector3(0,0,0), Vector3(1,2,5))
	
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
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
