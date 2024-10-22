extends CharacterBody3D

var acceleration = Vector3()

const drag_coef = .01 # .3 took pitch from 40 at start to 34.8 at end
const gravity = 9.8*1.09361 # Full gravity seemed high
const restitution_coef = 0.546 # MLB rules
var time_last_thrown = Time.get_ticks_msec()

var spin_acceleration = Vector3(0,0,0) # Acceleration from pitch type

var ball_sz_dot_scene = load("res://ball_sz_dot.tscn")
const sz_z = 0.6
var already_crossed_sz = false

var pitch_in_progress = false
var pitch_already_done = false
var ball_radius = 0.042
var delivery_bounced = false
var hit_bounced = false

var is_frozen = false
var is_sim = false # simulation

var state = 'prepitch'

var prev_position
var prev_velocity
var prev_global_position
var prev_global_velocity
var throw_progress
var bounced_previous_frame = false

signal ball_overthrown

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

signal pitch_completed_unhit
func _physics_process(delta: float) -> void:
	#printt('pitch_in_progress', pitch_in_progress)
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
	if not is_frozen and state not in ["prepitch", "fielded"]:
		acceleration = Vector3()
		if abs(velocity.y) < 1e-8 and abs(position.y - ball_radius) < 1e-8:
			# No accel if on ground and stopped
			acceleration.y = 0
			#printt('actually is on ground, no gravity', spin_acceleration, velocity)
		else: 
			acceleration.y = -gravity
		acceleration += spin_acceleration
		if velocity.length_squared() > 0:
			acceleration -= drag_coef * velocity.length_squared() * velocity.normalized()
		#prev_position = position
		#printt('accel', acceleration, velocity, position)
		velocity += delta * acceleration
		# If you do velocity first, then subtract accel, more accurate
		position += delta * velocity - 0.5 * delta**2 * acceleration
		#printt('new ball pos', position)
		for wallnode in get_tree().get_nodes_in_group("walls"):
			var wallout = wallnode.check_ball_cross(global_position, velocity, restitution_coef,
			prev_global_position, prev_velocity, is_sim)
			#if wallout[0] and not is_sim:
			#	assert(false)
			if wallout[0] and not wallout[1]:
				global_position = wallout[2]
				#printt('velo before and after', velocity, wallout[3])
				#printt("In ball, hit wall at ball coords", position)
				velocity = wallout[3]
				#if not is_sim:
					#assert(false)
		# Move a throw
		if state == "thrown":
			throw_progress = 1
			if throw_start_pos != null:
				throw_progress = (distance_xz(throw_start_pos, position) /
					distance_xz(throw_target, throw_start_pos))
				# Fix when throw distance is very small
				var throw_target_distance = distance_xz(throw_target, throw_start_pos)
				if throw_target_distance < 1:
					throw_progress = 1
				if throw_progress > 1.05 or velocity.length() < .5:
					printt('ball throw prog over 1', throw_progress)
					state = 'ball_in_play'
					throw_start_pos = null
					throw_target = null
					ball_overthrown.emit()
		
		# Bounce
		if position.y < ball_radius:
			#printt('BOUNCE', state, velocity.length(), velocity, position, bounced_previous_frame, ball_radius - position.y)
			position.y = ball_radius + (ball_radius - position.y)* restitution_coef
			#velocity.y *= -1*restitution_coef # coef restitution
			velocity.y *= -1 # bounce up
			velocity *= restitution_coef
			# If it would bounce next frame, stop it
			#var next_pos_y = position.y + (1./60)*(velocity.y - .5*gravity*(1./60)) + .5*gravity*(1./60)**2
			#if position.y + 1./60*velocity.y - .5*gravity*(1./60)**2 < ball_radius:
			if bounced_previous_frame:
				#printt('ball stopped on ground')
				velocity.y = 0
				position.y = ball_radius
			#else:
			#	printt('bounced up, not stopped', position, velocity, position.y + 1./60*velocity.y - .5*gravity*(1./60)**2, ball_radius, next_pos_y)
			# Stop it if slow enough to avoid infinite bounce
			if velocity.length_squared() < .5**2:
				velocity = Vector3()
			if pitch_in_progress:
				delivery_bounced = true
			if state == "ball_in_play":
				#printt('setting hit_bounced = true')
				hit_bounced = true
			bounced_previous_frame = true
		else:
			#printt('NOT bounce', delta)
			bounced_previous_frame = false
	#if position.z < 10:
	#	velocity = Vector3()
	
	if pitch_in_progress:
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
			pitch_in_progress = false
			pitch_already_done = true
			is_frozen = true
			velocity = Vector3()
			get_node("AnimatedSprite3D").stop()
			pitch_completed_unhit.emit()
	

func simulate_delivery(pos, vel, delta=1./60):
	# Find position where the ball will cross the strike zone
	#print('starting simulate_Delivery inside ball_3d')
	# Simulate forward in time
	var accel
	var nsteps = 0
	while pos.z > sz_z and nsteps < 1e6:
		#printt('sd step:', nsteps)
		nsteps += 1
		accel = Vector3()
		accel.y = -gravity
		accel += spin_acceleration
		if vel.length_squared() > 0:
			accel -= drag_coef * vel.length_squared() * vel.normalized()
		vel += delta * accel
		pos += delta * vel - 0.5 * delta**2 * accel
		#if nsteps % 10 ==0:
		#	printt('  \tSimulate delivery step', nsteps, pos, vel)
		if vel.z >= 0:
			printt('vel.z not less than 0', vel.z, vel, accel)
		assert(vel.z < 0)
	#printt('pos before going back', pos)
	# Go back in trajectory to where it cross sz_z
	vel -= delta * accel
	var sz_t = (sz_z - pos.z) / vel.z
	pos += sz_t * vel
	#printt('pos AFTER going back', pos)
	#printt('simulate delivery found', pos)
	return pos

func secant_step(x0, x1, f0, f1, step_size = 1, max_mult=10) -> float:
	# https://en.wikipedia.org/wiki/Secant_method
	var x2 =  x1 - f1 * (x1 - x0) / (f1 - f0) * step_size
	if max_mult != null:
		assert(max_mult >= 1)
		var xL = min(x0, x1)
		var xR = max(x0, x1)
		if x2 > xR:
			if x2 - xR > max_mult * (xR - xL):
				x2 = xR + max_mult * (xR - xL)
		if x2 < xL:
			if xL - x2 > max_mult * (xR - xL):
				x2 = xL - max_mult * (xR - xL)
	return x2

var best_dist2 = 1e9
var best_v
func find_starting_velocity_vector(speed0, pos0, xfinal, yfinal, tol=1./36/36, vel0=null):
	printt('starting find_starting_velocity_vector, tol is', tol)
	#return
	
	
	# Function to evaluate a velocity vector
	#var last_pf
	best_dist2 = 1e9
	#var best_v
	var eval = func(v):
		#printt("\t\t", "Evaluating", v)
		var pf = simulate_delivery(pos0, v, .001)
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
	var v0
	var x0
	var y0
	if vel0 and vel0.length_squared() > 0 :
		vel0 = vel0.normalized() * speed0
		v0 = vel0
		x0 = vel0.normalized().x
		y0 = vel0.normalized().y
		#print('NEW PARS', v0, x0, y0)
	else:		
		v0 = Vector3(0,0,-1) * speed0
		x0 = 0
		y0 = 0
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
				printt("Starting with y", y0, y1)
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
					printt('secant step x:', x0, x1, x2)
				else:
					y2 = secant_step(y0, y1, eval0, eval1, secant_step_size)
					v2 = make_v.call(x0, y2)
					printt('secant step y:', y0, y1, y2)
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
					printt('REJECTED!', eval0, eval1, eval2)
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

func fit_approx_parabola_to_trajectory(pos1, pos2, speed1, use_drag):
	# Fit parabola starting from pos1 going to pos2 with speed1
	# Return velocity vector at pos1
	#var p1 = Vector3(0,0,0)
	var p2 = pos2 - pos1
	# Rotate so that 3rd dim is 0
	var anglep2
	if p2.z != 0:
		anglep2 = atan(p2.z / p2.x)
		p2 = p2.rotated(Vector3(0,1,0), anglep2)
		# Make sure x is positive
		if p2.x < 0:
			anglep2 += PI
			p2 = p2.rotated(Vector3(0,1,0), PI)
	else:
		anglep2 = 0
	#printt('check rotate', pos1, pos2, pos2 - pos1, anglep2, 'rot1', p2)
	var t
	var vel1
	var vy1
	if use_drag:
		#assert(false)
		#printt('FITTING WITH DRAG, speed1', speed1)
		var d = drag_coef * 1
		var m = p2.x * (1 + .5 * d * p2.x)
		#printt('m is', m)
		var a = m**2 + p2.y**2
		var b = p2.y * gravity * m**2 - m**2 * speed1**2
		var c = 0.25 * gravity**2 * m**4
		#var quadratic_vx1_sq = quadratic(a, b, c)
		var quadratic_vx1_sq = quadratic(1, b/a, c/a)
		#printt("quadratic_vx1_sq", quadratic_vx1_sq)
		#printt("quadratic_vx1_sq v2", quadratic(a/b, 1, c/b))
		var vx1
		if quadratic_vx1_sq[0] < .5 or quadratic_vx1_sq[1] < 0:
			printt('approx parabola will give error', quadratic_vx1_sq)
			#return ???
		if p2.x > 0:
			vx1 = sqrt(quadratic_vx1_sq[1])
		else:
			vx1 = sqrt(quadratic_vx1_sq[1])
		#printt('check quadratic', a*quadratic_vx1_sq[1]**2 + b*quadratic_vx1_sq[1]+c, 0,a,b,c, 1, b/a, c/a)
		#printt('check before quadratic', m**2*vx1**4+p2.y**2*m**4+p2.y*gravity*m**2*vx1**2+.25*gravity**2*m**4, m**2*speed1**2*vx1**2)
		#printt('check s1 terms', vx1**2, ((p2.y*vx1**2+.5*gravity*m**2)/(m*vx1))**2, speed1**2)
		#printt('all terms', gravity, m, speed1, p2.y)
		#assert(vx1)
		vy1 = (p2.y * vx1**2 + .5 * gravity * m**2) / (m * vx1)
		t = m / vx1
		if t <= 0:
			printt('assert t > 0', t, m, vx1)
		assert(t > 0)
		#var k = d * (p2.x / t)**2
		vel1 = Vector3(vx1, vy1, 0)
		#printt('check t', t)
		#printt('check speed1 eqn', vx1**2 + vy1**2, speed1**2)
		#printt('check dx eqn', p2.x, vx1*t-.5*k*t**2)
		#printt('check dy eqn', p2.y, vy1*t-.5*gravity*t**2)
		#printt('check drag eqn', k, d, p2.x)
		#printt('drag velo vec before rotation', vel1)
		#var endvelo = Vector2(vx1 - k*t, vy1 - gravity*t)
		#printt('with drag, start speed', Vector2(vx1, vy1), Vector2(vx1,vy1).length(), speed1, 'end speed', endvelo, endvelo.length())
	else: # no drag
		var a = .25 * gravity**2
		var b = gravity * (p2.y) - speed1**2
		var c = (p2.x)**2 + (p2.y)**2
		var quadratic_t_sq = quadratic(a, b, c)
		if quadratic_t_sq[0] < .5: # No solution
			return null
		elif quadratic_t_sq[1] < 1.5: # One solution, linear
			t = sqrt(quadratic_t_sq[1])
		else:
			t = sqrt(min(quadratic_t_sq[1], quadratic_t_sq[2]))
		var vx1 = (p2.x) / t
		vy1 = (p2.y + .5 * gravity * t**2) / t
		vel1 = Vector3(vx1, vy1, 0)
		#printt('check eqn vx1', vx1)
		#printt('check eqn t', t, a*t**4 + b*t**2 + c)
		#printt('check eqn x2', p2.x, p1.x +t*vx1)
		#printt('check eqn y2', p2.y, p1.y +t*vy1 - .5*gravity*t**2)
	# Rotate it back to original direction
	#printt('check result 1', p2, t, vel1)
	vel1 = vel1.rotated(Vector3(0,1,0), -anglep2)
	
	#printt('check result', vel1, vel1.length())
	#printt('endpoint given was', pos2)
	#printt('simulate endpoint is', simulate_delivery(pos1, vel1, 1./60))
	#printt('calculate endpoint x', pos1.x + t*vel1.x)
	#printt('calculate endpoint y', pos1.y + t*vy1 - .5*gravity*t**2)
	#printt('calculate endpoint z', pos1.z + t*vel1.z)
	#printt('DO THESE MATCH??')
	#printt('simtraj2', simtraj2(pos1, vel1))
	#printt('simulate inputs is', pos1, vel1)
	
	return vel1

func simtraj2(pos, vel):
	var dt = 1e-3
	while pos.z > sz_z:
		pos += dt * vel
		vel += dt*Vector3(0,-gravity, 0)
		
	return pos

func quadratic(a, b, c) -> Array:
	var t1 = b**2 - 4*a*c
	if t1 < 0:
		return [0, null, null]
	if t1 == 0:
		return [1, -b / (2*a)]
	else:
		var out = [2, (-b + sqrt(t1)) / (2*a), (-b - sqrt(t1)) / (2*a)]
		if out[1] < out[2]:
			out = [out[0], out[2], out[1]]
		return out

func _ready() -> void:
	pass
	#fit_approx_parabola_to_trajectory(Vector3(1,2,20), Vector3(3,.5,.6), 80, false)

func ball_fielded():
	#printt('running ball ball_fielded, state will be fielded')
	visible = false
	velocity = Vector3()
	is_frozen = true
	state = "fielded"
	set_process(false)

var throw_start_pos
var throw_target
func throw_to_base(_base, velo_vec, start_pos, target):
	#printt('setting throw_to_base', _base)
	visible = true
	is_frozen = false
	velocity = velo_vec
	throw_start_pos = start_pos
	throw_target = target
	state = "thrown"
	time_last_thrown = Time.get_ticks_msec()
	set_process(true)


func distance_xz(a:Vector3, b:Vector3) -> float:
	return sqrt((a.x - b.x)**2 +
				(a.z - b.z)**2)
