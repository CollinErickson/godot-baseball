extends CharacterBody3D

var acceleration = Vector3()

const drag_coef = .01 # .3 took pitch from 40 at start to 34.8 at end
const gravity = 9.8*1.09361 # Gravity in yards/sec
const restitution_coef = 0.546 # MLB rules
var time_last_thrown = Time.get_ticks_msec()

var spin_acceleration = Vector3(0,0,0) # Acceleration from pitch type
var frame_rotation:Vector2 = Vector2.ZERO
# Rotation of ball (essentially spin, but already using spin for pitches),
#  done after movement
# Values in radians / second
# X: rotation left/right 
# Y: rotation up/down
# These match what you expect if ball has velo (0,0,1) (straight out)
# 0.1 is fairly large number, 1 is insanely large

var ball_sz_dot_scene = load("res://ball_sz_dot.tscn")
const sz_z = 0.6
var sz_top:float
var sz_bottom:float
var already_crossed_sz = false

var pitch_in_progress = false
var pitch_already_done = false
var ball_radius = 0.042
var delivery_bounced = false
var hit_bounced = false

var is_frozen = false
var is_sim = false # simulation

var state = 'prepitch'
const possible_states:Array = [
	'prepitch', 'ball_in_play', # Hit and not fielded yet
	'fielded',
	'thrown', 'thrown_loose']

var prev_position
var prev_velocity
var prev_global_position
var prev_global_velocity
var throw_progress
var bounced_previous_frame = false
var previous_bounce_pos = null
var pitch_is_strike:bool = false
var pitch_is_ball:bool = false
var touched_by_fielder:bool = false
var hit_bounced_position = null
var hit_bounced_time = null
var elapsed_time = 0
var fair_foul_determined:bool = false
var is_foul:bool = false

signal ball_overthrown
@onready var wallnodes = get_tree().get_nodes_in_group("walls")
@onready var cylinder_trail_node = get_parent().get_node('MeshInstance3DTube')

func freeze() -> void:
	is_frozen = true
	visible = false
	set_physics_process(false)

func pause() -> void:
	set_physics_process(false)

func unpause() -> void:
	set_physics_process(true)

func reset(sz_top_:float, sz_bottom_:float) -> void:
	is_frozen = false
	visible = true
	set_physics_process(true)
	# Reset vars
	position = Vector3()
	velocity = Vector3()
	spin_acceleration = Vector3()
	frame_rotation = Vector2()
	sz_top = sz_top_
	sz_bottom = sz_bottom_
	
	already_crossed_sz = false

	pitch_in_progress = false
	pitch_already_done = false
	delivery_bounced = false
	hit_bounced = false

	is_sim = false # simulation

	set_state('prepitch')

	prev_position = null
	prev_velocity = null
	prev_global_position = null
	prev_global_velocity = null
	throw_progress = null
	bounced_previous_frame = false
	previous_bounce_pos = null
	pitch_is_strike = false
	pitch_is_ball = false
	touched_by_fielder = false
	scale = 1*Vector3.ONE
	visible = false
	throw_start_pos = null
	throw_target = null
	hit_bounced_position = null
	hit_bounced_time = null
	elapsed_time = 0
	$TrailNode.visible = false
	cylinder_trail_node.reset()
	throw_start_pos = null
	throw_start_velo = null
	throw_target = null
	fair_foul_determined = false
	is_foul = false

	printt('finished ball reset, hit bounced', hit_bounced)
	
	var dot = get_parent().get_node_or_null('SZ_DOT')
	if dot != null:
		get_parent().remove_child(dot)

func pow_vec_components(x, a=2) :
	var y = Vector3()
	y.x = x.x ** a
	y.y = x.y ** a
	y.z = x.z ** a
	return y

func is_strike(pos):
	return (abs(pos.x) < .25 + ball_radius and 
		pos.y < sz_top + ball_radius and pos.y > sz_bottom - ball_radius and
		not delivery_bounced)

signal pitch_completed_unhit
signal hit_bounced_signal
signal ball_over_wall_signal
func _physics_process(delta: float) -> void:
	elapsed_time += delta
	if is_frozen:
		return
	#if randf_range(0,1) < 1.1 and not is_sim:
		#printt('in ball:', state, position, throw_start_pos, throw_target, throw_progress, hit_bounced, fair_foul_determined, is_foul)
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
		for wallnode in wallnodes:
			# check_ball_across returns array of 4 items:
			# 0: Did it cross?
			# 1: Was it over?
			# 2: Reflected position
			# 3: New velocity
			var wallout = wallnode.check_ball_cross(global_position, velocity, restitution_coef,
			prev_global_position, prev_velocity, is_sim)
			#if wallout[0] and not is_sim:
			#	assert(false)
			
			if wallout[0]: # Crossed wall
				if not is_sim:
					printt('in ball, crossed wall, should trigger _on_ball_over_wall_signal', wallout)
				if wallout[1]: # Over: home run or GRD or foul ball
					if not is_sim:
						printt('in ball, over wall, should trigger _on_ball_over_wall_signal')
					if not fair_foul_determined:
						is_foul = !is_in_fair_territory()
						fair_foul_determined = true
					ball_over_wall_signal.emit()
				else: # Hit wall: fair or foul
					global_position = wallout[2]
					if not is_sim:
						#printt('velo before and after', velocity, wallout[3])
						printt("In ball, hit wall at ball coords", position, name, is_sim)
					velocity = wallout[3]
					if check_if_foul_on_bounce():
						# If foul, exit. Otherwise it returns later, or something weird.
						# It emits a foul ball signal, so field should take over
						return
					if not hit_bounced:
						hit_bounced = true
						hit_bounced_position = position
						hit_bounced_time = elapsed_time
						if not is_sim:
							hit_bounced_signal.emit()
					#if not is_sim:
						#assert(false)
		# Move a throw
		if state == "thrown":
			#printt('in ball: state is thrown')
			throw_progress = 1
			if throw_start_pos != null:
				throw_progress = (distance_xz(throw_start_pos, position) /
					distance_xz(throw_target, throw_start_pos))
				# Fix when throw distance is very small
				var throw_target_distance = distance_xz(throw_target, throw_start_pos)
				if throw_target_distance < 1:
					throw_progress = 1
				if (throw_progress > 1.05 or
					(throw_start_velo!=null and
						velocity.length()/throw_start_velo.length() < .25)):
					printt('ball throw prog over 1', throw_progress)
					set_state('thrown_loose')
					throw_start_pos = null
					throw_target = null
					if not is_sim:
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
				velocity = Vector3.ZERO
				# Stop animation
				$AnimatedSprite3D.stop()
				# Fair/foul can be determined
				if not fair_foul_determined:
					fair_foul_determined = true
					if is_in_fair_territory():
						is_foul = false
					else:
						is_foul = true
						foul_ball.emit()
						return
			
			if pitch_in_progress:
				delivery_bounced = true
			if state == "ball_in_play" and not hit_bounced:
				#if not is_sim:
					#printt('hit_bounced true soon', hit_bounced, fair_foul_determined)
				#printt('setting hit_bounced = true', hit_bounced, position)
				hit_bounced = true
				hit_bounced_position = position
				hit_bounced_time = elapsed_time
				# Check foul before signaling that hit bounced
				if check_if_foul_on_bounce():
					# If foul, exit. Otherwise it returns later, or something weird.
					return
				if not is_sim:
					print('hit_bounced true')
				if not is_sim:
					hit_bounced_signal.emit()
			bounced_previous_frame = true
			previous_bounce_pos = position
		else:
			#printt('NOT bounce', delta)
			bounced_previous_frame = false
		
		# Check if ball crossed 1st/3rd base fair/foul
		if check_if_foul_on_passing_base():
			return
		
		# Do frame rotation after hit, not on pitch
		if pitch_already_done:# and frame_rotation.length_squared() > 1e-8:
			# Rotate velocity vector
			# If ball is directly out, vel (0,0,1),
			#  a is in +X direction
			if abs(velocity.x) + abs(velocity.z) > 1e-12:
				var a = -velocity.cross(Vector3(0,1,0)).normalized()
				#  b is in +Y direction
				var b = velocity.cross(a).normalized()
				#printt('test ab', velocity.normalized(), a, b, delta)
				if abs(frame_rotation.x) > 1e-12:
					velocity = velocity.rotated(b, frame_rotation.x * delta)
				if abs(frame_rotation.y) > 1e-12:
					velocity = velocity.rotated(a, frame_rotation.y * delta)
				# Dampen frame rotation if it bounced
				#print('fix this frame rot')
				if bounced_previous_frame:
					frame_rotation *= 0.1
		
		if not is_sim and prev_position != null:
			align_trail(position, prev_position, delta, velocity)
		if not is_sim and pitch_already_done:
			#printt('adding cyl value', position, state)
			cylinder_trail_node.add_value(position, .5, 1)
			cylinder_trail_node.update_mesh(true, 2)
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
			#printt('ball sz check:', prev_position, position, delta_cross_sz, dot.position)
			var color
			if is_strike(dot.position):
				pitch_is_strike = true
				color = Color(1,0,0,1) # Red
			else:
				pitch_is_ball = true
				color = Color(0,0,1,1) # Blue
			dot.get_node('MeshInstance3D').mesh.material.albedo_color = color
			dot.name = 'SZ_DOT'
			get_parent().add_child(dot)
			#print("global dot: ", dot.global_position)
			#print("local dot: ", dot.position)
			
		# Stop movement when reaches 0
		if position.z < 0:
			pitch_in_progress = false
			pitch_already_done = true
			is_frozen = true
			velocity = Vector3()
			if not is_sim:
				get_node("AnimatedSprite3D").stop()
				print('in ball: emitting that pitch completed without hit')
				spin_acceleration = Vector3(0,0,0)
				pitch_completed_unhit.emit(pitch_is_ball, pitch_is_strike)
	

func simulate_delivery(pos, vel, delta=1./60, return_time:bool=false):
	# Find position where the ball will cross the strike zone
	#print('starting simulate_Delivery inside ball_3d')
	# Simulate forward in time
	var accel
	var nsteps = 0
	var time = 0
	while pos.z > sz_z and nsteps < 1e6:
		#printt('sd step:', nsteps)
		nsteps += 1
		time += delta
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
	# sz_t should be negative, time to go back to when it crossed sz
	var sz_t = (sz_z - pos.z) / vel.z
	pos += sz_t * vel
	time += sz_t
	#printt('pos AFTER going back', pos)
	#printt('simulate delivery found', pos)
	if return_time:
		return time
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
func find_starting_velocity_vector_old(speed0, pos0, xfinal, yfinal, tol=1./36/36, vel0=null):
	# Find pitch velo vector using coordinate descent
	# It was never implemented well, failed often, and was slow.
	printt('starting find_starting_velocity_vector, tol is', tol)
	#return
	var time1 = Time.get_ticks_msec()

	
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
					#var time2 = Time.get_ticks_msec()
					#printt('ball test optim OLD bad solution: run time msec is', time2 - time1)
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
	var time2 = Time.get_ticks_msec()
	printt('ball test optim OLD bad solution: run time msec is', time2 - time1)
	return best_v

func find_starting_velocity_vector(speed0, pos0, xfinal, yfinal,
										tol=1./36/36, _vel0=null) -> Vector3:
	# New idea: use error from zero drag sim iteratively to reduce the error
	# no_drag_target[i]: where no drag pitch should end at
	# no_drag_vel[i]: velocity vec to get to no_drag_target[i]
	# drag_end_point_for_no_drag_vel[i]: end point when using drag
	# Start no_drag_target_0 = desired endpoint
	# no_drag_target[i+1] += (target - drag_end_point_for_no_drag_vel[i])
	#printt('ball test optim: start')
	#var time1 = Time.get_ticks_msec()
	var pos_final:Vector3 = Vector3(xfinal, yfinal, sz_z)
	var no_drag_target:Vector3 = pos_final
	var no_drag_vel_vec:Vector3 = Vector3()
	var drag_end_point_for_no_drag_vel:Vector3 = Vector3()
	for i in range(10):
		#printt('ball test optim: starting i=', i)
		no_drag_vel_vec = fit_approx_parabola_to_trajectory(pos0, no_drag_target, speed0, false)

		drag_end_point_for_no_drag_vel = simulate_delivery(pos0, no_drag_vel_vec, .001)
		var err:Vector3 = drag_end_point_for_no_drag_vel - pos_final
		#printt('ball test optim: error is', err.length(), err)
		if err.length() < tol:
			break
		no_drag_target += pos_final - drag_end_point_for_no_drag_vel
	
	#var time2 = Time.get_ticks_msec()
	#printt('ball test optim: run time msec is', time2 - time1)
	return no_drag_vel_vec

func fit_approx_parabola_to_trajectory(pos1, pos2, speed1, use_drag):
	# Fit parabola starting from pos1 going to pos2 with speed1
	# Return velocity vector at pos1
	# This is only an approximation to how drag works. 
	# For fielder throws, this may be good enough.
	# For pitches, this is used to get a
	#  good starting point, which is then passed as the starting point
	#  to the optimization algorithm to get better results.
	
	#var p1 = Vector3(0,0,0)
	var p2 = pos2 - pos1
	# Rotate so that 3rd dim is 0
	var anglep2
	if p2.z != 0:
		anglep2 = atan(p2.z / p2.x)
		p2 = p2.rotated(Vector3(0,1,0), anglep2)
	else:
		anglep2 = 0
	# Make sure x is positive
	if p2.x < 0:
		anglep2 += PI
		p2 = p2.rotated(Vector3(0,1,0), PI)
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
		# Throw won't make it, return something
		if quadratic_vx1_sq[0] < .5 or quadratic_vx1_sq[1] < 0:
			# TODO: fix bad throws
			printt('approx parabola will give error', quadratic_vx1_sq)
			# 30 degree throw
			vel1 = Vector3(1,.5,0).normalized() * speed1
		else:
			vx1 = sqrt(quadratic_vx1_sq[1])
			
			#printt('check quadratic', a*quadratic_vx1_sq[1]**2 + b*quadratic_vx1_sq[1]+c, 0,a,b,c, 1, b/a, c/a)
			#printt('check before quadratic', m**2*vx1**4+p2.y**2*m**4+p2.y*gravity*m**2*vx1**2+.25*gravity**2*m**4, m**2*speed1**2*vx1**2)
			#printt('check s1 terms', vx1**2, ((p2.y*vx1**2+.5*gravity*m**2)/(m*vx1))**2, speed1**2)
			#printt('all terms', gravity, m, speed1, p2.y)
			#assert(vx1)
			vy1 = (p2.y * vx1**2 + .5 * gravity * m**2) / (m * vx1)
			t = m / vx1
			if t <= 0 or t == null or is_nan(t):
				printt('assert t > 0', t, m, vx1, p2, pos1, pos2)
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

func ball_fielded(ball_position_before_fielded:Vector3):
	printt('In ball: in func ball_fielded, state will be fielded')
	visible = false
	velocity = Vector3()
	is_frozen = true
	set_state("fielded")
	set_process(false)
	touched_by_fielder = true
	printt('In ball: in func ball_fielded--', fair_foul_determined, is_foul,
		is_in_fair_territory(ball_position_before_fielded), ball_position_before_fielded,
		position, global_position)
	throw_start_pos = null
	throw_start_velo = null
	throw_target = null
	if not fair_foul_determined:
		fair_foul_determined = true
		is_foul = !is_in_fair_territory(ball_position_before_fielded)
		if is_foul:
			foul_ball.emit()
	
	cylinder_trail_node.reset()
	frame_rotation = Vector2()
	previous_bounce_pos = null

var throw_start_pos
var throw_start_velo
var throw_target
func throw_to_base(_base, velo_vec, start_pos, target):
	#printt('in ball: setting throw_to_base', _base, 'target is', target)
	visible = true
	is_frozen = false
	velocity = velo_vec
	throw_start_pos = start_pos
	throw_start_velo = velo_vec
	throw_target = target
	set_state("thrown")
	time_last_thrown = Time.get_ticks_msec()
	throw_progress = 0
	set_process(true)

func distance_xz(a:Vector3, b:Vector3) -> float:
	return sqrt((a.x - b.x)**2 +
				(a.z - b.z)**2)

signal foul_ball
func check_if_foul_on_bounce(emit:bool=true):
	# Return true if newly foul, otherwise false
	if is_sim:
		return false
	if fair_foul_determined:
		return false
	#printt('in check if foul', global_position, hit_bounced, touched_by_fielder)
	# If it bounces in fair territory past the base lines, it's fair
	if ((global_position.x >= 0 and global_position.z >= 30) or
			(global_position.z >= 0 and global_position.x >= 30)):
		#printt('in check_if_foul_on_bounce, setting fair', fair_foul_determined, is_foul)
		fair_foul_determined = true
		is_foul = false
		return false
	# If it bounces past the baselines in foul territory, it depends on where it
	#   was when it crossed the baselines connecting to 2nd base.
	if ((global_position.x < 0 and global_position.z > 30) or
			(global_position.z < 0 and global_position.x > 30)):
		#printt('in check_if_foul_on_bounce, setting foul', fair_foul_determined, is_foul, emit)
		fair_foul_determined = true
		is_foul = true
		printt('in ball check_if_foul_on_bounce, emitting signal FOUL BALL')
		if emit:
			foul_ball.emit()
		return true
	return false

func check_if_foul_on_passing_base(emit:bool = true) -> bool:
	# Return true if newly foul, otherwise false
	# Only determines fair/foul if already bounced but fair foul not determined
	if is_sim:
		return false
	if fair_foul_determined:
		return false
	if not hit_bounced:
		return false
	if global_position.x >= 30 and prev_global_position.x < 30:
		fair_foul_determined = true
		if global_position.z >= 0:
			is_foul = false
			return false
		else:
			is_foul = true
			printt('in ball check_if_foul_on_passing_base, emitting signal FOUL BALL')
			if emit:
				foul_ball.emit()
			return true
	if global_position.z >= 30 and prev_global_position.z < 30:
		fair_foul_determined = true
		if global_position.x >= 0:
			is_foul = false
			return false
		else:
			is_foul = true
			printt('in ball check_if_foul_on_passing_base, emitting signal FOUL BALL')
			if emit:
				foul_ball.emit()
			return true
	return false

func remove_dot(seconds):
	$Timer.wait_time = seconds
	$Timer.start()

func _on_timer_timeout() -> void:
	$Timer.stop()
	var dot = get_parent().get_node_or_null('SZ_DOT')
	if dot:
		dot.visible = false

func align_trail(pos:Vector3, pos_prev:Vector3, _delta:float, vel:Vector3) -> void:
	# Not using this anymore
	if true:
		return
	if not pitch_already_done:
		return
	#$Trail.rotation = Vector3.ZERO
	#$Trail.rotate_y(atan((pos.x - pos_prev.x) / (pos.z - pos_prev.z)))
	#$Trail.rotate_x(130*PI/180)
	#$Trail.rotate_z(230*PI/180)
	var target = (pos_prev - pos).normalized()
	#target = target.rotated(Vector3(1,0,0), -90.*PI/180) # Rotate to put behind ball
	target = target.rotated(Vector3(0,1,0), 45.*PI/180) # Rotate to global frame
	target *= 100 # look_at can't be too close
	$TrailNode.look_at(target)
	
	# Change length of tail
	#var speed = (pos - pos_prev).length() / delta
	var speed = vel.length()
	if speed < 5:
		$TrailNode.visible = false
	else:
		$TrailNode.visible = true
		var trail_length = 1. * speed / 80.
		$TrailNode/Trail.mesh.height = trail_length
		$TrailNode/Trail.position.z = -0.1 - trail_length / 2.
	if speed <= 1e-8:
		cylinder_trail_node.reset()

func is_in_fair_territory(pos=position) -> bool:
	#print('in ball is_in_fair_territory, pos:', position)
	pos = pos.rotated(Vector3(0,1,0), 45.*PI/180)
	return pos.x >= 0 and pos.z >= 0
	#return global_position.x >= 0 and global_position.z >= 0

func find_where_ball_will_hit_ground() -> Vector3:
	# Use this after ball is hit to find where to place bounce annulus
	# Not actually used since this data comes from assigning fielders
	var pos = position
	var vel = velocity
	var dt = 1e-3
	while pos.y > 0:
		pos += dt * vel
		vel += dt*Vector3(0,-gravity, 0)
	pos.y = 0
	return pos

func set_state(new_state:String) -> void:
	assert(possible_states.has(new_state))
	state = new_state

func can_be_caught() -> bool:
	return state in ['ball_in_play', 'thrown', 'thrown_loose']
