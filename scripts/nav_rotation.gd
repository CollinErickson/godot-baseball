extends navigable_page
class_name nav_rotation

var button_selected = null
var team:Team = null
var franchise:Franchise
var current_org_index:int = 0
var current_level:int = 0

@onready var rotationnode:GridContainer = \
	$This/StandardBackground/VBoxContainer/HBoxContainer/Rotation
@onready var relieversnode:GridContainer = \
	$This/StandardBackground/VBoxContainer/HBoxContainer/Relievers
@onready var level_button:navigable_button_adjustable = \
	$This/StandardBackground/VBoxContainer/Level
@onready var team_button:navigable_button_adjustable = \
	$This/StandardBackground/VBoxContainer/Team
@onready var back_button = \
	$This/StandardBackground/VBoxContainer/HBoxBottom/Back
var rp_buttons:Array = []
var rp_row_dict:Dictionary[String,bool] = {}

func _ready() -> void:
	page_id = 'rotation'
	parent_ready()

func setup(args:Dictionary={}) -> void:
	if this_is_root:
		# Debugging
		#args['team'] = Team.new().create_random()
		#args['team'].rotation[1] = ''
		#args['team'].rotation[2] = ''
		#args['team'].rotation[4] = ''
		args['franchise'] = Franchise.new()
		args['franchise'].create_from_team_index(0)
	if len(args.keys()) > 0:
		franchise = args['franchise']
		team_button.values = []
		for i in range(franchise.n_orgs):
			team_button.values.push_back(
				franchise.orgs[i].teams[current_level].city_name)
		team_button.current_index = franchise.user_org_index
		team_button.set_text()
	# Start with MLB team of user team
	printt('check args', args, franchise)
	team = franchise.orgs[current_org_index].teams[current_level]
	
	# Put designated SPs on left
	printt('team rotation is', team.rotation)
	for i in range(len(team.rotation)):
		var pid:String = team.rotation[i]
		var b = navigable_button_scene.instantiate()
		#printt('new button is', b)
		if pid == '':
			b.set_text("<empty>")
			b.data['is_empty'] = true
		else:
			var player:Player = team.rosterdict[pid]
			# Create button for new player
			#var b:navigable_button = navigable_button_scene.instantiate()
			#b.set_textL(player.pos)
			#b.set_textR(str(roundi(player.contact)))
			#b.set_text(player.last)
			set_button_text(b, player)
			b.data['player_id'] = player.player_id
		b.row = i
		b.col = 0
		b.id = "SP" + str(i)
		b.page_id = page_id
		b.add_to_group("nav_rotation_button_SP")
		
		# Replace existing node
		var control_i:Control = rotationnode.get_node("Control" + str(i+1))
		control_i.replace_by(b)
		control_i.queue_free()
	
	# Put all remaining Ps on right
	var i:int = 0
	for pid in team.rosterdict.keys():
		if pid in team.rotation:
			continue
		var player:Player = team.rosterdict[pid]
		if !player.is_pitcher():
			continue
		var b = navigable_button_scene.instantiate()
		#printt('new button is', b)
		#b.set_textL(player.pos)
		#b.set_textR(str(roundi(player.contact)))
		#b.set_text(player.last)
		set_button_text(b, player)
		b.row = i
		b.col = 1
		b.id = "RP" + str(i)
		b.data['player_id'] = player.player_id
		b.page_id = page_id
		b.add_to_group("nav_rotation_button_RP")
		relieversnode.add_child(b)
		rp_buttons.push_back(b)
		rp_row_dict[b.id] = true #b.row
		
		i += 1
	
	# Set correct row for back and accept buttons
	#$This/StandardBackground/VBoxContainer/HBoxBottom/Accept.row = max(5, i)
	#$This/StandardBackground/VBoxContainer/HBoxBottom/Cancel.row = max(5, i)
	back_button.row = max(5, i)
	team_button.row = back_button.row + 1
	level_button.row = back_button.row + 2

func handle_nav_button_click(id:String, args:Dictionary={}) -> void:
	if id == 'back':
		cleanup()
		nav_up({'result':'back'})
	elif id == 'team':
		if args['move'] == 'left':
			current_org_index -= 1
		else:
			current_org_index += 1
		current_org_index = maxi(0,
								mini(franchise.n_orgs - 1,
									current_org_index))
		team = franchise.orgs[current_org_index].teams[current_level]
		
		cleanup()
		setup()
		update_buttons()
	elif id == 'level':
		# Change level
		if args['move'] == 'left':
			current_level -= 1
		else:
			current_level += 1
		current_level = maxi(0, mini(franchise.n_levels - 1, current_level))
		
		cleanup()
		setup()
		update_buttons()
	else:
		# A pitcher button was pressed
		#printt('unhandled nav click ', page_id, ' ', id)
		if button_selected == null:
			# No player selected, so select it as first
			button_selected = id
			get_node_from_id(id).set_selected(true)
		elif button_selected == id:
			# Reselected same player, cancel
			button_selected = null
			get_node_from_id(id).set_selected(false)
		else:
			get_node_from_id(button_selected).set_selected(false)
			# Need to switch two
			var b1:navigable_button = get_node_from_id(button_selected)
			var b2:navigable_button = get_node_from_id(id)
			var b1_is_empty:bool = 'is_empty' in b1.data.keys()
			var b2_is_empty:bool = 'is_empty' in b2.data.keys()
			#print('did it find buttons?', b1, b2)
			# Switch on roster
			var b1_sp = null
			var b2_sp = null
			if b1.id.substr(0,2) == "SP":
				b1_sp = int(b1.id.substr(2)) #- 1
			if b2.id.substr(0,2) == "SP":
				b2_sp = int(b2.id.substr(2)) #- 1
			printt('team rotation before is', team.rotation)
			#printt(b1.data['player_id'], b2.data['player_id'], b1_sp, b2_sp, b1.id, b2.id)
			if b1_sp == null and b2_sp == null:
				# Nothing to do
				pass
			elif b1_sp == null:
				# b1 replaces b2 in rotation
				#if b2_is_empty:
				team.rotation[b2_sp] = b1.data['player_id']
				#else:
					#var b2_ind = team.rotation.find(b2.data['player_id'])
					#assert(b2_ind >= 0)
					#team.rotation[b2_ind] = b1.data['player_id']
			elif b2_sp == null:
				# b2 replaces b1 in rotation
				team.rotation[b1_sp] = b2.data['player_id']
				#var b1_ind = team.rotation.find(b1.data['player_id'])
				#assert(b1_ind >= 0)
				#team.rotation[b1_ind] = b2.data['player_id']
			else:
				# Both in rotation, switch them
				#var b1_ind = team.rotation.find(b1.data['player_id'])
				#assert(b1_ind >= 0)
				#var b2_ind = team.rotation.find(b2.data['player_id'])
				#assert(b2_ind >= 0)
				#team.rotation[b1_ind] = b2.data['player_id']
				#team.rotation[b2_ind] = b1.data['player_id']
				printt('switch:', b1_is_empty, b2_is_empty, b1_sp, b2_sp)
				if b2_is_empty:
					team.rotation[b1_sp] = ''
				else:
					team.rotation[b1_sp] = b2.data['player_id']
				if b1_is_empty:
					team.rotation[b2_sp] = ''
				else:
					team.rotation[b2_sp] = b1.data['player_id']
			printt('team rotation after is', team.rotation)
			# Switch the buttons
			var b1_info = [b1.text, '', true]
			if not b1_is_empty:
				b1_info = [b1.text, b1.data['player_id'], false,
							b1.textL, b1.textR]
			b1.set_textL(b2.textL)
			b1.set_textR(b2.textR)
			b1.set_text(b2.text)
			if b2_is_empty:
				b1.data.erase('player_id')
			else:
				b1.data['player_id'] = b2.data['player_id']
			if 'is_empty' in b2.data.keys():
				b1.data['is_empty'] = true
			else:
				b1.data.erase('is_empty')
			b2.set_textL(b1_info[3])
			b2.set_textR(b1_info[4])
			b2.set_text(b1_info[0])
			if b1_is_empty:
				b2.data.erase('player_id')
			else:
				b2.data['player_id'] = b1_info[1]
			if b1_info[2]:
				b2.data['is_empty'] = true
			else:
				b2.data.erase('is_empty')
			
			# Delete <empty> button if replaced
			if b1_is_empty and not b2_is_empty and b2_sp==null:
				# Already switched, so delete b2
				printt('about to delete', b2.id, b1.id)
				b2.remove_from_group('navigable_button')
				var del_row = b2.row
				rp_row_dict.erase(b2.id)
				b2.queue_free()
				#for bb in rp_buttons:
					#printt('bbrp', bb)
				for k in rp_row_dict.keys():
					var bk = get_node_from_id(k)
					if bk.row > del_row:
						bk.row -= 1
				if len(rp_row_dict.keys()) >= 5:
					back_button.row -= 1
					level_button.row -= 1
					team_button.row -= 1
				update_buttons()
			if b2_is_empty and not b1_is_empty and b1_sp==null:
				# Already switched, so delete b1
				printt('about to delete', b1.id, b2.id)
				b1.remove_from_group('navigable_button')
				var del_row = b1.row
				rp_row_dict.erase(b1.id)
				b1.queue_free()
				for k in rp_row_dict.keys():
					var bk = get_node_from_id(k)
					if bk.row > del_row:
						bk.row -= 1
				if len(rp_row_dict.keys()) >= 5:
					back_button.row -= 1
					level_button.row -= 1
					team_button.row -= 1
				update_buttons()
				#for bb in rp_buttons:
					#printt('bbrp', bb)
			
			# Clear selection
			button_selected = null

func get_node_from_id(id:String):
	if id.substr(0,2) == "SP":
		var cs:Array[Node] = rotationnode.get_children()
		for c in cs:
			if c.is_in_group('navigable_button'):
				if c.id == id:
					return c
	elif id.substr(0,2) == "RP":
		var cs:Array[Node] = relieversnode.get_children()
		for c in cs:
			if c.is_in_group('navigable_button'):
				if c.id == id:
					return c
	push_warning('Unable to find node from id: ', id)
	return null

func cleanup() -> void:
	# Remove SP
	var sps:Array = get_tree().get_nodes_in_group("nav_rotation_button_SP")
	sps.sort_custom(func (a,b): return a.id < b.id)
	#printt('sps are', sps)
	for i in range(len(sps)):
		var sp:navigable_button = sps[i]
		var c:Label = Label.new()
		c.name = "Control" + str(i+1)
		# replace_by keeps children, so delete them first
		sp.get_child(0).queue_free()
		sp.replace_by(c)
		sp.disconnect_all_signals()
		sp.remove_from_group('navigable_button')
		sp.queue_free()
	# Remove Relievers
	var rps:Array = get_tree().get_nodes_in_group("nav_rotation_button_RP")
	for i in range(len(rps)):
		var rp:navigable_button = rps[i]
		rp.disconnect_all_signals()
		rp.remove_from_group('navigable_button')
		rp.queue_free()
	# Clear vars
	button_selected = null
	team = null

func set_button_text(b:navigable_button, player:Player) -> void:
	b.set_textL(player.pos)
	b.set_textR(str(roundi(player.speed)))
	b.set_text(player.last)
