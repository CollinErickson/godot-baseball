extends navigable_page
class_name nav_free_agents

var franchise:Franchise
@onready var FAs:VBoxContainer = \
	$This/StandardBackground/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer

func _ready() -> void:
	page_id = 'NavFreeAgents'
	
	parent_ready()

func handle_nav_button_click(id:String, _args:Dictionary={}) -> void:
	match id:
		'back':
			if this_is_root:
				return
			cleanup()
			nav_up({'result':'back'})
		_:
			cleanup()
			nav_to('NavPlayer',{
				'player':franchise.free_agents[id],
				'franchise':franchise
			})

func setup(args:Dictionary={}):
	if this_is_root:
		if franchise == null:
			var f:Franchise = Franchise.new()
			f.create_from_team_index(1)
			args['franchise'] = f
		else:
			args['franchise'] = franchise
	if args.has('franchise'):
		franchise = args['franchise']
	var FA_array:Array = franchise.free_agents.values()
	FA_array.sort_custom(func(a,b): return a.speed > b.speed)
	var custom_x:int = 0
	var i:int = 0
	for player in FA_array:
		var n:navigable_button = navigable_button_scene.instantiate()
		n.page_id = page_id
		n.set_textL(player.pos)
		n.set_textR(str(roundi(player.speed)))
		n.set_text(player.last)
		n.id = player.player_id
		n.row = i
		n.set_custom_min_size(0)
		custom_x = roundi(n.custom_minimum_size.x)
		#n.custom_minimum_size.x=500
		#n.custom_minimum_size.y=500
		#FAs.add_child(n)
		var mc:MarginContainer = MarginContainer.new()
		mc.add_theme_constant_override('margin_left', 10)
		mc.add_theme_constant_override('margin_right', 10)
		#mc.add_theme_constant_override('margin_top', 10)
		#mc.add_theme_constant_override('margin_bottom', 10)
		mc.add_child(n)
		FAs.add_child(mc)
		#FAs.custom_minimum_size.x = n.custom_minimum_size.x + 100
		custom_x += 100
		
		#printt('added button', n)
		i += 1
	$This/StandardBackground/VBoxContainer/Back.row = i
	$This/StandardBackground/VBoxContainer/ScrollContainer.custom_minimum_size.x = custom_x

func set_button_hover_true(button:navigable_button) -> void:
	if button.id == 'back':
		return
	printt('hover true on', button)
	var sc:ScrollContainer = $This/StandardBackground/VBoxContainer/ScrollContainer
	sc.ensure_control_visible(button)

func cleanup() -> void:
	for node in FAs.get_children():
		var nb = node.get_child(0)
		printt('nb is', nb)
		remove_from_group('navigable_button')
		nb.queue_free()
		node.queue_free()
