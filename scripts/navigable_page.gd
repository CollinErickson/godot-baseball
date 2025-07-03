extends Control
class_name navigable_page

var is_active:bool = false
var this_is_root:bool = false
var time_active:int = Time.get_ticks_msec()
var nav_buttons:Array = []
var buttons_by_row:Array = []
var buttons_by_col:Array = []
var page_id:String = '' # Should be overwritten when extended in _ready()
var prev_mouse_pos:Vector2
#const navigable_button = preload("res://scripts/navigable_button.gd")
const navigable_button_scene = preload("res://scenes/navigable_button.tscn")

func _ready() -> void:
	pass

func parent_ready() -> void:
	if get_tree().root == get_parent():
		this_is_root = true
	
	set_active(this_is_root)

func _process(_delta: float) -> void:
	assert(is_active)
	
	# Don't allow quick clicks
	if Time.get_ticks_msec() - time_active < 1000 * 0.4:
		return
	
	# Check for input ----
	
	# Check for keyboard/controller input
	# If select, click current button
	if Input.is_action_just_pressed("swing"):
		# Find current hover button
		var hov = get_tree().get_nodes_in_group("button_hover-" + page_id)
		printt('in nav page hov button on keyboard select', page_id, hov)
		if len(hov) == 0:
			printt('button pressed but no hover button')
		elif len(hov) == 1:
			#printt('button pressed, exactly one hover button')
			hov[0].clicked()
			return # Don't process anything else after click
		else:
			push_error("button pressed on nav page, but multiple hover buttons")
	if Input.is_action_just_pressed("movedown"):
		#printt('in navigable page action just pressed down')
		handle_keyboard_input('movedown')
	elif Input.is_action_just_pressed("moveup"):
		handle_keyboard_input('moveup')
	elif Input.is_action_just_pressed("moveleft"):
		handle_keyboard_input('moveleft')
	elif Input.is_action_just_pressed("moveright"):
		handle_keyboard_input('moveright')
	
	#return # test only keyboard input for now
	# Check for click
	if Input.is_action_just_pressed("click"):
		var mpos = get_local_mouse_position()
		#printt('in navigable page found click', mpos)
		for i in range(len(nav_buttons)):
			var button:navigable_button = nav_buttons[i]
			if button.holds_pos(mpos):
				print('click in rect', button, button.position, button.size)
				button.clicked(mpos)
				return
	# Check for mouse hover
	var mpos2 = get_local_mouse_position()
	# If mouse hasn't moved, don't do anything
	if mpos2 != prev_mouse_pos:
		# Run on every button to make sure they turn off
		for i in range(len(nav_buttons)):
			var button = nav_buttons[i]
			button.set_hover(button.holds_pos(mpos2))
	prev_mouse_pos = mpos2

func set_active(new_is_active:bool, args:Dictionary={}) -> void:
	printt('in set_active', page_id, new_is_active)
	is_active = new_is_active
	# Update the page as needed, needs to happen before getting buttons
	if new_is_active:
		setup(args)
	# Set visibility
	visible = true
	if get_node_or_null("This") != null:
		get_node_or_null("This").visible = new_is_active
	else:
		push_warning("Navigable page doesn't have 'This' child node", page_id)
	# Update buttons
	if new_is_active:
		get_navigable_buttons()
	else:
		disconnect_nav_button_signals()
	set_process(new_is_active)
	
	# Some pages will immediately navigate to a subpage
	if new_is_active:
		after_set_active_true(args)

func setup(_args:Dictionary={}) -> void:
	# Any class that inherits this needs to implement it if needed
	return

func after_set_active_true(_args:Dictionary={}) -> void:
	# Any class that inherits this needs to implement it if needed
	return
	

func get_navigable_buttons() -> void:
	nav_buttons = get_tree().get_nodes_in_group("navigable_button")
	#printt('in nav page nav buttons is', page_id, nav_buttons)
	# Filter out buttons from other sub-pages
	nav_buttons = nav_buttons.filter(func(r): return r.page_id == page_id)
	#printt('in nav page nav buttons after filter is', nav_buttons)
	# Make sure that all ids are distinct
	var id_dict:Dictionary = {}
	for nb in nav_buttons:
		if str(nb.id) in id_dict:
			push_error("Multiple buttons in page = ", page_id,
				" have id = ", nb.id)
		id_dict[str(nb.id)] = true
	
	# Make sure that row+col are distinct
	var rc_dict:Dictionary = {}
	for nb in nav_buttons:
		if str(nb.row) + "_" + str(nb.col) in rc_dict:
			push_error("Multiple buttons in page = ", page_id,
				" have row = ", nb.row, " and col = ", nb.col)
		rc_dict[str(nb.row) + "_" + str(nb.col)] = true
	
	connect_buttons(nav_buttons)
	
	# Add buttons to grid for traversal later
	for nb in nav_buttons:
		while len(buttons_by_row) <= nb.row:
			buttons_by_row.push_back([])
		buttons_by_row[nb.row].push_back(nb)
		while len(buttons_by_col) <= nb.col:
			buttons_by_col.push_back([])
		buttons_by_col[nb.col].push_back(nb)
	
	# Make sure that there aren't empty rows/cols
	for i in range(len(buttons_by_row)):
		if len(buttons_by_row[i]) == 0:
			push_error("In nav page " + page_id +
				" there are no buttons in row=" + str(i))
	for i in range(len(buttons_by_col)):
		if len(buttons_by_col[i]) == 0:
			push_error("In nav page " + page_id +
				" there are no buttons in col=" + str(i))
	
	# Sort each row/col
	for i in range(len(buttons_by_row)):
		buttons_by_row[i].sort_custom(sort_row)
	for i in range(len(buttons_by_col)):
		buttons_by_col[i].sort_custom(sort_col)
	#printt('buttons by row is', buttons_by_row)
	#printt('buttons by col is', buttons_by_col)

func sort_row(a,b) -> bool:
	return a.col < b.col
func sort_col(a,b) -> bool:
	return a.row < b.row

func handle_nav_button_click(_id:String, _args:Dictionary) -> void:
	assert(false, "Child navigable page needs to implement handle_nav_button_click")

func connect_buttons(nav_buttons_) -> void:
	for button in nav_buttons_:
		button.connect('signal_clicked', handle_nav_button_click)

func unhandled_nav_button_click(page_id_:String, id_:String):
	push_error("Unhandled nav button click on page_id = ", page_id_,
				" clicked button with id = ", id_)

func disconnect_nav_button_signals() -> void:
	buttons_by_col = []
	buttons_by_row = []
	for button in nav_buttons:
		button.disconnect_all_signals()

func nav_to(subpage_name:String) -> void:
	# Stop this page
	set_active(false)
	# Make sure that the subpage exists
	if get_node_or_null("Subpages") == null:
		push_error("No Subpages node on page_id = ", page_id)
	# Make sure that subpages are visible (turned off when editing)
	get_node("Subpages").visible = true
	# Move to next page
	if get_node_or_null("Subpages/" + subpage_name) == null:
		push_error("No Subpage with name", subpage_name, "on page", page_id)
	get_node("Subpages/" + subpage_name).set_active(true)

func nav_up(args:Dictionary={}) -> void:
	#printt('in nav up', get_parent())
	# Check if nav up is possible
	if get_parent() == null or get_parent().get_parent() == null:
		print("Can't nav_up from page_id = ", page_id,
			", staying on current page")
		return
	
	# Stop this page
	set_active(false)
	get_parent().get_parent().set_active(true, args)

func handle_keyboard_input(val:String) -> void:
	var hov = get_tree().get_nodes_in_group("button_hover-" + page_id)
	printt('in nav page hov handle_keyboard_input on keyboard select', page_id, hov)
	if len(hov) == 0:
		printt('button pressed but no hover button')
		# Pick a button to set to hover
		nav_buttons[0].set_hover(true)
	elif len(hov) == 1:
		#printt('button pressed, exactly one hover button')
		# Move to next button
		hov = hov[0]
		if val == "moveleft":
			if hov.uses_move_left():
				hov.use_move_left()
				return
		if val == "moveright":
			if hov.uses_move_right():
				hov.use_move_right()
				return
		# Button didn't use it, so traverse buttons
		var new_hov = traverse_buttons(hov, val)
		if new_hov != null:
			# Remove this button from hover
			hov.set_hover(false)
			# Make new button the hover
			new_hov.set_hover(true)
	else:
		push_error("button pressed on nav page, but multiple hover buttons, " +
			"in handle_keyboard_input")
		# Remove all from the group, hope that it fixes itself
		for h in hov:
			h.set_hover(false)

func traverse_buttons(hov, val):
	printt('in traverse_buttons', hov, val, hov.row, buttons_by_row)
	var new_row:int = hov.row
	var new_col:int = hov.col
	if val == "movedown":
		new_row += 1
		if new_row >= len(buttons_by_row):
			new_row = 0
		return nearest_button_in_1d(buttons_by_row[new_row], new_col)
	if val == "moveup":
		new_row -= 1
		if new_row < 0:
			new_row = len(buttons_by_row) - 1
		return nearest_button_in_1d(buttons_by_row[new_row], new_col)
	if val == "moveright":
		new_col += 1
		if new_col >= len(buttons_by_col):
			new_col = 0
		return nearest_button_in_1d(buttons_by_col[new_col], new_row)
	if val == "moveleft":
		new_col -= 1
		if new_col < 0:
			new_col = len(buttons_by_col) - 1
		return nearest_button_in_1d(buttons_by_col[new_col], new_row)
	return null

func nearest_button_in_1d(arr:Array, index:int):
	# TODO: Actually check the row/col values.
	#  A row could have buttons in cols 1 and 3, but not 2.
	if len(arr) == 0:
		printt('error in nearest_button_in_1d', arr, index)
	if index < len(arr):
		return arr[index]
	return arr[len(arr) - 1]
