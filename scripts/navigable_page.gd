extends Control
class_name navigable_page

var is_active:bool = false

var this_is_root:bool = false
var time_active:int = Time.get_ticks_msec()
var nav_buttons:Array = []
@export var page_id:String = ''

func _ready() -> void:
	pass

func parent_ready() -> void:
	if get_tree().root == get_parent():
		this_is_root = true
		#start_active = true
	
	set_active(this_is_root)

func _process(_delta: float) -> void:
	assert(is_active)
	
	# Don't allow quick clicks
	if Time.get_ticks_msec() - time_active < 1000 * 0.4:
		return
	
	# Check for input
	if Input.is_action_just_pressed("movedown"):
		printt('in navigable page action just pressed down')
	
	
	if Input.is_action_just_pressed("click"):
		var mpos = get_local_mouse_position()
		#printt('in navigable page found click', mpos)
		#printt($VBoxContainer/NameRect1.position, $VBoxContainer/NameRect1.size)
		#var rects = [
			#$VBoxContainer/NameRect1,
			#$VBoxContainer/NameRect2,
			#$VBoxContainer/NameRect3,
			#$VBoxContainer/NameRect4,
		#]
		for i in range(len(nav_buttons)):
			var button = nav_buttons[i]
			if (
				mpos.x >= button.left() and
				mpos.y >= button.top() and
				mpos.x <= button.right() and
				mpos.y <= button.bottom()
			):
				print('click in rect', button, button.position, button.size)
				#click_in_rect.emit(i)
				button.clicked()
				return

func set_active(new_is_active:bool) -> void:
	#printt('in set_active', page_id, new_is_active)
	is_active = new_is_active
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

func get_navigable_buttons() -> void:
	nav_buttons = get_tree().get_nodes_in_group("navigable_button")
	#printt('in nav page nav buttons is', page_id, nav_buttons)
	# Filter out buttons from other sub-pages
	nav_buttons = nav_buttons.filter(func(r): return r.page_id == page_id)
	#printt('in nav page nav buttons after filter is', nav_buttons)
	connect_buttons(nav_buttons)

#func connect_buttons(_nav_buttons) -> void:
	#assert(false, "Child navigable page needs to implement connect_buttons")
func handle_nav_button_click(_id:String) -> void:
	assert(false, "Child navigable page needs to implement handle_nav_button_click")

func connect_buttons(nav_buttons_) -> void:
	#printt('in nav home page connect buttons', nav_buttons_)
	for button in nav_buttons_:
		button.connect('signal_clicked', handle_nav_button_click)

func unhandled_nav_button_click(page_id_:String, id_:String):
	push_error("Unhandled nav button click on page_id = ", page_id_,
				" clicked button with id = ", id_)

func disconnect_nav_button_signals() -> void:
	for button in nav_buttons:
		button.disconnect_all_signals()

func nav_to(subpage_name:String) -> void:
	# Stop this page
	set_active(false)
	# Make sure that subpages are visible (turned off when editing)
	get_node("Subpages").visible = true
	# Move to next page
	get_node("Subpages/" + subpage_name).set_active(true)

func nav_up() -> void:
	#printt('in nav up', get_parent())
	# Stop this page
	set_active(false)
	# Return control to page
	get_parent().get_parent().set_active(true)
