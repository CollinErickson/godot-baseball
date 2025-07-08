extends navigable_page
class_name franchise_load

func _ready() -> void:
	page_id = 'franchise_load'
	parent_ready()

func handle_nav_button_click(id:String, _args:Dictionary={}) -> void:
	#printt('in nav franchise load handle nav button click', id)
	match id:
		'create':
			printt('clicked on create')
			#cleanup()
			nav_to("NavFranchiseNew")
		'back':
			printt('clicked on back')
			cleanup()
			nav_up()
		_:
			unhandled_nav_button_click(page_id, id)

func setup(_args:Dictionary={}) -> void:
	#printt('in nav franch starting setup')
	# Load saved franchises
	var saved_franchises:Array = []
	for saved_franchise in saved_franchises:
		pass
	
	# Create new franchise
	#var nb = navigable_button_scene.instantiate()
	#nb.setup(
		#"Create new franchise",
		#page_id,
		#"create",
		#0,
		#0
	#)
	#nb.name = "Create"
	#nb.grow_vertical = true
	#$This/StandardBackground/CenterContainer/VBoxContainer.add_child(nb)
	
	# Move the back button to the bottom
	var back_button:navigable_button = $This/StandardBackground/CenterContainer/VBoxContainer/Back
	back_button.row = 1 + len(saved_franchises)
	$This/StandardBackground/CenterContainer/VBoxContainer.move_child(
		back_button,
		2 + len(saved_franchises))

func cleanup() -> void:
	# Remove franchise load/create buttons since next time will recreate them
	var nbs:Array = get_tree().get_nodes_in_group("navigable_button")
	#printt('in cleanup nbs before is', nbs)
	for nb in nbs:
		printt('\tnb', page_id, nb.id, nb.page_id, nb)
	nbs = nbs.filter(func(x): return x.page_id == page_id)
	nbs = nbs.filter(func(x): return x.id != "back" and x.id != 'create')
	for nb in nbs:
		nb.queue_free()
	#printt('in cleanup nbs is', nbs)

func after_set_active_true(args:Dictionary={}) -> void:
	# Check if returned from creating new franchise
	if 'from' in args.keys():
		if args['from'] == 'franchise_new':
			if 'team_index' in args.keys():
				printt('need to implement team_index')
			else:
				push_error('Error in nav_franchise_load, came from',
				' franchise_new, but no team_index')
