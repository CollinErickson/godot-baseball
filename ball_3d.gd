extends CharacterBody3D

var acceleration = Vector3()

const drag_coef = .01 # .3 took pitch from 40 at start to 34.8 at end
const gravity = -9.8*1.09361 # Full gravity seemed high
const restitution_coef = 0.546 # MLB rules

var spin_acceleration = Vector3() # Acceleration from pitch type

var ball_sz_dot_scene = load("res://ball_sz_dot.tscn")
const sz_z = 0.6
var already_crossed_sz = false

var pitch_in_progress = false
var pitch_already_done = false
var ball_radius = 0.042
var delivery_bounced = false

var is_frozen = false
var is_sim = false # simulation


var prev_position
var prev_velocity
var prev_global_position
var prev_global_velocity

func pow_vec_components(x, a=2) :
	var y = Vector3()
	y.x = x.x ** a
	y.y = x.y ** a
	y.z = x.z ** a
	return y

func is_strike():
	return (abs(position.x) < .25 + ball_radius and 
		position.y < 1.05 + ball_radius and position.y > 0.45 - ball_radius and
		not delivery_bounced)

func _physics_process(delta: float) -> void:
	#print('in ball pp, ', position)
	#print('in ball pp vel, ', velocity)
	#print('in ball pp globalpos, ', global_position)
	#printt('ball is sim', is_sim)
	prev_position = position
	prev_velocity = velocity
	prev_global_position = global_position
	#printt(' check prev pos', position, prev_position, global_position, to_global(position), to_global(prev_position), prev_global_position)
	#printt(' check prev vel', position, prev_position, global_position, prev_global_position, velocity, prev_velocity, to_global(velocity))
	if velocity.length_squared() > 0:
		pass
		#print('in ball pp, velo is: ', velocity.length())
	#print('in ball pp, velo is: ', velocity.)
	#position.x = 0
	#move_and_slide()
	if not is_frozen:
		acceleration = Vector3()
		acceleration.y = gravity
		acceleration += spin_acceleration
		if velocity.length_squared() > 0:
			acceleration -= drag_coef * velocity.length_squared() * velocity.normalized()
		#prev_position = position
		velocity += delta * acceleration
		# If you do velocity first, then subtract accel, more accurate
		position += delta * velocity - 0.5 * delta**2 * acceleration
		for wallnode in get_tree().get_nodes_in_group("walls"):
			var wallout = wallnode.check_ball_cross(global_position, velocity, restitution_coef,
			prev_global_position, prev_velocity, is_sim)
			if wallout[0] and not is_sim:
				assert(false)
	#if position.z < 10:
	#	velocity = Vector3()
	
	# Cross strikezone
	if not already_crossed_sz and position.z < sz_z:
		already_crossed_sz = true
		var dot = ball_sz_dot_scene.instantiate()
		#var cur_weight = 1 - (sz_z - position.z) / (prev_position.z - position.z)
		#printt('prev pos is', prev_position)
		#printt('pos is', position)
		#printt('cur weight is', cur_weight)
		#dot.position = cur_weight * position + (1 - cur_weight) * prev_position
		var delta_cross_sz = (sz_z - position.z) / velocity.z
		dot.position = position + delta_cross_sz * velocity
		#print("MESHDOTCOLOR")
		var color
		if is_strike():
			color = Color(1,0,0,1)
		else:
			color = Color(0,0,1,1)
		dot.get_node('MeshInstance3D').mesh.material.albedo_color = color
		get_parent().add_child(dot)
		#print("global dot: ", dot.global_position)
		#print("local dot: ", dot.position)
		
	# Stop movement when reaches 0
	if position.z < 0:
		is_frozen = true
		velocity = Vector3()
		get_node("AnimatedSprite3D").stop()
	
	# Bounce
	if position.y < 0.042:
		#print('BOUNCE')
		position.y = 0.042 + (0.042 - position.y)* restitution_coef
		velocity.y *= -1*restitution_coef # coef restitution
		# Stop it if slow enough to avoid infinite bounce
		if velocity.length_squared() < .5**2:
			velocity = Vector3()

func simulate_delivery(pos, vel, delta=1./30):
	# Find position where the ball will cross the strike zone
	#print('starting simulate_Delivery inside ball_3d')
	# Simulate forward in time
	var accel
	var nsteps = 0
	while pos.z > sz_z and nsteps < 30*4:
		#printt('sd step:', nsteps)
		nsteps += 1
		accel = Vector3()
		accel.y = gravity
		accel += spin_acceleration
		if vel.length_squared() > 0:
			accel -= drag_coef * vel.length_squared() * vel.normalized()
		vel += delta * accel
		pos += delta * vel - 0.5 * delta**2 * accel
		
	# Go back in trajectory to where it cross sz_z
	vel -= delta * accel
	var sz_t = (sz_z - pos.z) / vel.z
	pos += sz_t * vel
	#printt('simulate delivery found', pos)
	return pos

func secant_step(x0, x1, f0, f1, step_size = 1):
	# https://en.wikipedia.org/wiki/Secant_method
	return x1 - f1 * (x1 - x0) / (f1 - f0) * step_size

var best_dist2 = 1e9
var best_v
func find_starting_velocity_vector(speed0, pos0, xfinal, yfinal, tol=1./36/36):
	printt('starting find_starting_velocity_vector, tol is', tol)
	#return
	
	
	# Function to evaluate a velocity vector
	#var last_pf
	best_dist2 = 1e9
	#var best_v
	var eval = func(v):
		#printt("\t\t", "Evaluating", v)
		var pf = simulate_delivery(pos0, v)
		#printt("\t\t", "Sim del gave", pf)
		#last_pf = pf
		#printt('in eval pf is', pf)
		var out = (pf.x - xfinal)**2 + (pf.y - yfinal)**2
		#printt("\t\t", "Out is", out)
		if out < best_dist2:
			best_dist2 = out
			best_v = v
			#printt("NEW BEST", best_dist2, best_v)
		return out
	
	# Starting points
	var v0 = Vector3(0,0,-1) * speed0
	var x0 = 0
	var y0 = 0
	#var v1 = Vector3(0,.01,-1).normalized() * speed0
	var eval0 = eval.call(v0)
	var v1
	var x1
	var y1
	var eval1
	var tmp
	var x2
	var y2
	var eval2
	var v2
	var make_v = func(xx,yy):
		return Vector3(xx, yy, -1).normalized() * speed0
	#var eval1 = eval.call(v1)
	#printt("start points", v0, v1, eval0, eval1)
	var nsteps = 0
	var nstepsper = 10
	var secant_step_size = .1 # Shorten secant step to get better results
	while nsteps < 100:
		printt('in while', nsteps, best_dist2, best_v, secant_step_size)
		for idim in range(2):
			if idim == 0:
				#v1 = (v0.normalized() + Vector3(.01,0,0)).normalized() * speed0
				x1 = x0 + randf_range(-1,1) * 1e-2
				v1 = make_v.call(x1, y0)
			else:
				#v1 = (v0.normalized() + Vector3(0,.01,0)).normalized() * speed0
				y1 = y0  + randf_range(-1,1) * 1e-2
				v1 = make_v.call(x0, y1)
			#printt('evaluating v1', v1)
			eval1 = eval.call(v1)
			
			# Make sure eval0 is worse than eval1
			if eval1 > eval0:
				tmp = eval1
				eval1 = eval0
				eval0 = tmp
				tmp = v1
				v1 = v0
				v0 = tmp
				if idim == 0:
					tmp = x1
					x1 = x0
					x0 = tmp
				else:
					tmp = y1
					y1 = y0
					y0 = tmp
			
			for i_innerstep in range(nstepsper):
				#printt('inner step', i_innerstep)
				nsteps += 1
				#var sec
				if idim == 0:
					x2 = secant_step(x0, x1, eval0, eval1, secant_step_size)
					v2 = make_v.call(x2, y0)
				else:
					y2 = secant_step(y0, y1, eval0, eval1, secant_step_size)
					v2 = make_v.call(x0, y2)
				# Eval new point
				eval2 = eval.call(v2)
				
				if eval2 < eval1:
					# New one is best, update all
					eval0 = eval1
					eval1 = eval2
					v0 = v1
					v1 = v2
					if idim == 0:
						x0 = x1
						x1 = x2
					else:
						y0 = y1
						y1 = y2
					# Lengthen secant step size
					secant_step_size = max(min(1, secant_step_size*1.05), .1)
				elif eval2 < eval0:
					# New one is second best, put it at index 0
					eval0 = eval2
					v0 = v2
					if idim == 0:
						x0 = x2
					else:
						y0 = y2
					# Lengthen secant step size
					secant_step_size = max(min(1, secant_step_size*1.05), .1)
				else:
					# New one is worst, reject, pick new point between existing
					if idim == 0:
						x2 = .5*(x0 + x1)
						v2 = make_v.call(x2, y0)
					else:
						y2 = .5*(y0 + y1)
						v2 = make_v.call(x0, y2)
					eval2 = eval.call(v2)
					# Keep new point either way
					if eval2 < eval1:
						# Move both up
						eval0 = eval1
						eval1 = eval2
						v0 = v1
						v1 = v2
						if idim == 0:
							x0 = x1
							x1 = x2
						else:
							y0 = y1
							y1 = y1
					else:
						# Replace index 0
						eval0 = eval2
						v0 = v2
						if idim == 0:
							x0 = x2
						else:
							y0 = y2
					# Shorten secant step since result was bad
					secant_step_size *= .7
				
				if best_dist2 < tol:
					printt('found good solution, return', best_v, best_dist2)
					printt('num steps was', nsteps)
					return best_v
			# After for loop, make sure best is in index0 now
			if eval1 < eval0:
				v0 = v1
				eval0 = eval1
				if idim == 0:
					x0 = x1
				else:
					y0 = y1
				
			
	printt('couldnt find good solution, returning', best_v, best_dist2, nsteps)
	return best_v
	

func ball_fielded():
	visible = false
	set_process(false)
