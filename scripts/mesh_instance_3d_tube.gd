extends Node3D

var data_array:Array = []
var max_N:int = 16
var start_index:int = 0
var values_entered:int = 0
var std_material:StandardMaterial3D
var cylinder_mesh_array:Array = []
var cylinder_instance_array:Array = []

func _ready() -> void:
	# Set up data array
	data_array = []
	for i in range(max_N):
		data_array.push_back([Vector3(), 0])
	
	# Create the Standard Material Resource
	var cyl_material = StandardMaterial3D.new()
	# Set the main color (albedo) to red
	#cyl_material.albedo_color = Color.RED
	cyl_material.albedo_color = Color(1.,1.,0.,.19)
	# You can adjust other material properties here if needed:
	# cyl_material.metallic = 0.5
	# cyl_material.roughness = 0.2
	
	# Enable Alpha Blending
	# This tells Godot to actually use the alpha channel for transparency
	cyl_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# Create a sequence of cylinders
	# One less than max_N since 16 points are made with 15 cylinders
	assert(max_N >= 2)
	for i in range(max_N - 1):
		# Create the Cylinder Mesh Resource
		var cylinder_mesh = CylinderMesh.new()
		# Configure the cylinder's shape (not needed)
		#cylinder_mesh.height = 2.0
		#cylinder_mesh.top_radius = 0.5
		#cylinder_mesh.bottom_radius = 0.5
		cylinder_mesh.radial_segments = 16 # Controls how smooth the round part is
		#cylinder_mesh.cap_top = false
		#cylinder_mesh.cap_bottom = false
		cylinder_mesh_array.push_back(cylinder_mesh)

		# Create the MeshInstance3D Node
		var cylinder_instance = MeshInstance3D.new()

		# Assign the Mesh Resource to the MeshInstance3D
		cylinder_instance.mesh = cylinder_mesh

		# Assign the Material Resource to the MeshInstance3D
		# Using material_override applies the material to all surfaces of the mesh.
		cylinder_instance.material_override = cyl_material

		# Give the node a name (not needed)
		cylinder_instance.name = "CylinderInstance_" + str(i)
		
		# Add it to the array
		cylinder_instance_array.push_back(cylinder_instance)

		# Add the MeshInstance3D node as a child of this node
		add_child(cylinder_instance)
	
	# Reset parameters
	reset()
	
	# For testing
	if false:
		add_value(Vector3(0,1,10), .99)
		add_value(Vector3(1,2,10), 1)
		add_value(Vector3(2,3,10), 1)
		add_value(Vector3(3,2,10), 1)
	
	# Update display (will clear it)
	update_mesh()

#func _process(_delta: float) -> void:
	#pass

func reset() -> void:
	# Set up controls
	start_index = 0
	values_entered = 0
	# Hide nodes
	for ci in cylinder_instance_array:
		ci.visible = false

func add_value(pos:Vector3, width:float, shrink_factor:float=1) -> void:
	# Shrink existing widths first
	if abs(shrink_factor-1) > 1e-8:
		#printt('shrinking', shrink_factor, data_array)
		assert(shrink_factor >= 0)
		assert(shrink_factor < 1)
		for i in range(max_N):
			data_array[i][1] *= shrink_factor
	
	# Add new value
	data_array[(start_index + values_entered) % max_N] = [pos, width]
	values_entered += 1
	if values_entered > max_N:
		assert(values_entered == max_N + 1)
		values_entered = max_N
		start_index = (start_index + 1) % max_N

func update_mesh(shrink:bool=true, n_skip:int=0) -> void:
	var last_cyl_mesh = null
	# Loop over cylinders (not points) from oldest to newest
	for i in range(max_N - 1):
		# j is the index in array of the ith point
		var j = (i + start_index + max_N) % max_N
		# k is the index in array of the (i+1)th point
		var k = (j + 1) % max_N
		
		var vis = (
			(values_entered >= 2) and
			(i <= values_entered - 2) and
			(i <= values_entered - 2 - n_skip)
		)
		var cylinder_instance:MeshInstance3D = cylinder_instance_array[i]
		var cylinder_mesh:CylinderMesh = cylinder_mesh_array[i]
		
		cylinder_instance.visible = vis
		#printt('cyl test --', i, j, k, start_index, values_entered, vis)
		if vis:
			# Make cylinder from j to k
			cylinder_mesh.cap_bottom = (i==0)
			cylinder_mesh.cap_top = false
			last_cyl_mesh = cylinder_mesh
			#printt('cyl test', data_array[j], data_array[k], 1. - 1.*i/values_entered,1. - (i+1.)/values_entered)
			cylinder_mesh.height = data_array[j][0].distance_to(data_array[k][0])
			cylinder_mesh.top_radius = data_array[k][1]
			cylinder_mesh.bottom_radius = data_array[j][1]
			if shrink:
				cylinder_mesh.top_radius *= (1.*(i+1)/values_entered)
				cylinder_mesh.bottom_radius *= (1.*(i+0)/values_entered)
			cylinder_instance.position = (data_array[j][0] + data_array[k][0])/2.
			#cylinder_instance.look_at(data_array[k][0], Vector3(1,1,0).normalized())
			
			# --- Calculate Midpoint ---
			# The node's origin should be in the middle of the line segment
			#var mid_point: Vector3 = p_bottom + direction / 2.0
			# Or equivalently: var mid_point: Vector3 = (p_bottom + p_top) / 2.0

			# --- Set Position ---
			#node_to_orient.global_position = mid_point

			# --- Calculate and Apply Rotation (Basis) ---
			# The target Y-axis for the node should be the normalized direction vector
			var direction = data_array[k][0] - data_array[j][0]
			var new_y_axis: Vector3 = direction.normalized()

			# We need to construct the other two basis vectors (X and Z)
			# We use a reference 'up' vector (like global UP) to define the roll
			var reference_up = Vector3.UP

			var node_to_orient = cylinder_instance
			# Handle edge case: If the cylinder points straight up or down along the global Y axis
			if new_y_axis.is_equal_approx(Vector3.UP):
				# Already aligned with global Y up, use identity basis (no rotation needed relative to global)
				node_to_orient.basis = Basis.IDENTITY
			elif new_y_axis.is_equal_approx(Vector3.DOWN):
				# Pointing straight down, rotate 180 degrees around Z (or X)
				node_to_orient.basis = Basis.IDENTITY.rotated(Vector3.FORWARD, PI) # PI is 180 degrees
			else:
				# General case: Calculate orthogonal X and Z axes
				# Use cross products to find vectors perpendicular to the new Y axis and the reference UP
				var new_x_axis = reference_up.cross(new_y_axis).normalized()
				var new_z_axis = new_x_axis.cross(new_y_axis).normalized()
				# Important: Godot's Basis takes X, Y, Z vectors as columns
				node_to_orient.basis = Basis(new_x_axis, new_y_axis, new_z_axis)
	if last_cyl_mesh != null:
		last_cyl_mesh.cap_top = true
