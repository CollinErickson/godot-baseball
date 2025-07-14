extends navigable_page
class_name nav_rotation

var button_selected = null
var team:Team = null

func _ready() -> void:
	page_id = 'rotation'
	
	parent_ready()

func setup(args:Dictionary={}) -> void:
	if this_is_root:
		# Debugging
		args['team'] = Team.new().create_random()
	team = args['team']
	var rotationnode:GridContainer = $This/StandardBackground/VBoxContainer/HBoxContainer/Rotation
	var relieversnode:GridContainer = $This/StandardBackground/VBoxContainer/HBoxContainer/Relievers
	
	# Put designated SPs on left
	printt('team rotation is', team.rotation)
	for i in range(len(team.rotation)):
		var pid:String = team.rotation[i]
		if pid == '':
			continue
		var player:Player = team.rosterdict[pid]
		# Create button for new player
		#var b:navigable_button = navigable_button_scene.instantiate()
		var b = navigable_button_scene.instantiate()
		printt('new button is', b)
		b.set_text(player.last)
		b.row = i
		b.col = 0
		b.id = "SP" + str(i)
		b.data['player_id'] = player.player_id
		b.page_id = page_id
		
		
		# Replace existing node
		#printt('rotation node is', rotationnode.get_node("Control1"))#.replace_by(b)
		rotationnode.get_node("Control" + str(i+1)).replace_by(b)
	
	# Put all remaining Ps on right
	var i:int = 0
	for pid in team.rosterdict.keys():
		if pid in team.rotation:
			continue
		var player:Player = team.rosterdict[pid]
		if !player.is_pitcher():
			continue
		var b = navigable_button_scene.instantiate()
		printt('new button is', b)
		b.set_text(player.last)
		b.row = i
		b.col = 1
		b.id = "RP" + str(i)
		b.data['player_id'] = player.player_id
		b.page_id = page_id
		#relieversnode.add_child()
		relieversnode.add_child(b)
		
		i += 1
	
	# Set correct row for back and accept buttons
	$This/StandardBackground/VBoxContainer/HBoxBottom/Accept.row = max(5, i)
	$This/StandardBackground/VBoxContainer/HBoxBottom/Cancel.row = max(5, i)

func handle_nav_button_click(id:String, _args:Dictionary={}) -> void:
	if id == 'cancel':
		cleanup()
		nav_up({'result':'cancel'})
	elif id == 'accept':
		cleanup()
		nav_up({'result':'accept'})
	else:
		# A pitcher button was pressed
		#printt('unhandled nav click ', page_id, ' ', id)
		if button_selected == null:
			# No player selected
			button_selected = id
		elif button_selected == id:
			# Reselected same player, cancel
			button_selected = null
		else:
			# Need to switch two
			var b1:navigable_button = get_node_from_id(button_selected)
			var b2:navigable_button = get_node_from_id(id)
			#print('did it find buttons?', b1, b2)
			# Switch on roster
			var b1_sp = null
			var b2_sp = null
			if b1.id.substr(0,2) == "SP":
				b1_sp = int(b1.id.substr(2)) - 1
			if b2.id.substr(0,2) == "SP":
				b2_sp = int(b2.id.substr(2)) - 1
			#printt('team rotation before is', team.rotation)
			#printt(b1.data['player_id'], b2.data['player_id'], b1_sp, b2_sp, b1.id, b2.id)
			if b1_sp == null and b2_sp == null:
				# Nothing to do
				pass
			elif b1_sp == null:
				# b1 replaces b2 in rotation
				var b2_ind = team.rotation.find(b2.data['player_id'])
				assert(b2_ind >= 0)
				team.rotation[b2_ind] = b1.data['player_id']
			elif b2_sp == null:
				# b2 replaces b1 in rotation
				var b1_ind = team.rotation.find(b1.data['player_id'])
				assert(b1_ind >= 0)
				team.rotation[b1_ind] = b2.data['player_id']
			else:
				# Both in rotation, switch them
				var b1_ind = team.rotation.find(b1.data['player_id'])
				assert(b1_ind >= 0)
				var b2_ind = team.rotation.find(b2.data['player_id'])
				assert(b2_ind >= 0)
				team.rotation[b1_ind] = b2.data['player_id']
				team.rotation[b2_ind] = b1.data['player_id']
			#printt('team rotation after is', team.rotation)
			# Switch the buttons
			var b1_info = [b1.text, b1.data['player_id']]
			b1.set_text(b2.text)
			b1.data['player_id'] = b2.data['player_id']
			b2.set_text(b1_info[0])
			b2.data['player_id'] = b1_info[1]
			
			# Clear selection
			button_selected = null

func get_node_from_id(id:String):
	if id.substr(0,2) == "SP":
		var cs:Array[Node] = \
			$This/StandardBackground/VBoxContainer/HBoxContainer/Rotation.get_children()
		for c in cs:
			if c.is_in_group('navigable_button'):
				if c.id == id:
					return c
	elif id.substr(0,2) == "RP":
		var cs:Array[Node] = \
			$This/StandardBackground/VBoxContainer/HBoxContainer/Relievers.get_children()
		for c in cs:
			if c.is_in_group('navigable_button'):
				if c.id == id:
					return c
	return null

func cleanup() -> void:
	# TODO: Remove SP
	# TODO: Remove Relievers
	# Clear vars
	button_selected = null
	team = null
