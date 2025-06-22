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
	is_active = new_is_active
	if new_is_active:
		get_navigable_buttons()
	else:
		disconnect_nav_button_signals()
	set_process(new_is_active)

func get_navigable_buttons() -> void:
	nav_buttons = get_tree().get_nodes_in_group("navigable_button")
	printt('in nav page nav buttons is', nav_buttons)
	# Filter out buttons from other sub-pages
	nav_buttons = nav_buttons.filter(func(r): return r.page_id == page_id)
	#printt('in nav page nav buttons after filter is', nav_buttons)
	connect_buttons(nav_buttons)

#func connect_buttons(_nav_buttons) -> void:
	#assert(false, "Child navigable page needs to implement connect_buttons")
func handle_nav_button_click(_id:String) -> void:
	assert(false, "Child navigable page needs to implement handle_nav_button_click")

func connect_buttons(nav_buttons_) -> void:
	printt('in nav home page connect buttons', nav_buttons_)
	for button in nav_buttons_:
		button.connect('signal_clicked', handle_nav_button_click)

func unhandled_nav_button_click(page_id_:String, id_:String):
	push_error("Unhandled nav button click on page_id = ", page_id_,
				" clicked button with id = ", id_)

func disconnect_nav_button_signals() -> void:
	for button in nav_buttons:
		button.disconnect_all_signals()
