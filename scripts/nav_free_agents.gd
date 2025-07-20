extends navigable_page
class_name nav_free_agents

var franchise:Franchise

func _ready() -> void:
	page_id = 'NavFreeAgents'
	
	parent_ready()

func handle_nav_button_click(id:String, _args:Dictionary={}) -> void:
	match id:
		'back':
			nav_up({'result':'back'})
		_:
			printt('unhandled nav click ', page_id, ' ', id)

func setup(args:Dictionary={}):
	if this_is_root:
		var f:Franchise = Franchise.new()
		f.create_from_team_index(1)
		args['franchise'] = f
	franchise = args['franchise']
	var FAs = $This/StandardBackground/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer
	var i:int = 0
	for player in franchise.free_agents.values():
		var n:navigable_button = navigable_button_scene.instantiate()
		n.page_id = page_id
		n.set_text(player.last)
		n.id = player.player_id
		n.row = i
		n.set_custom_min_size(100)
		#n.custom_minimum_size.x=500
		#n.custom_minimum_size.y=500
		FAs.add_child(n)
		
		#printt('added button', n)
		i += 1
	$This/StandardBackground/VBoxContainer/Back.row = i

func set_button_hover_true(button:navigable_button) -> void:
	if button.id == 'back':
		return
	printt('hover true on', button)
	var sc:ScrollContainer = $This/StandardBackground/VBoxContainer/ScrollContainer
	sc.ensure_control_visible(button)
