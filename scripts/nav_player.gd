extends navigable_page
class_name NavPlayer

var player:Player
var team:Team
var franchise:Franchise
@onready var iso:Node = $This/SubViewportContainer/SubViewport/PlayerIsolated
@onready var sign_button:navigable_button = $This/VBoxContainer/VBoxContainer/Sign


enum PopupOptions {None, Sign, Cut}
var popup:PopupOptions = PopupOptions.None

func _ready() -> void:
	page_id = 'NavPlayer'
	
	parent_ready()

func handle_nav_button_click(id:String, _args:Dictionary={}) -> void:
	match id:
		'back':
			popup = PopupOptions.None
			nav_up({'result':'back'})
		'sign':
			popup = PopupOptions.Sign
			nav_to('NavPopup',
					{'options':['Sign?', 'Cancel'],
					 'label':'Sign'},
					true)

func setup(args:Dictionary={}) -> void:
	if this_is_root:
		if player == null:
			args['player'] = Player.new().create_random()
			args['team'] = Team.new().create_random()
			args['franchise'] = Franchise.new().create_from_team_index(0)
		else:
			args = {
				'player':player,
				'team':team,
				'franchise':franchise
			}
	
	if args['from'] == 'NavPopup':
		if popup == PopupOptions.Sign:
			printt('signing player')
			franchise.sign_player(player)
			update_buttons_on_player()
		return
	
	
	# Setup new player
	assert(args.has('player'))
	player = args['player']
	# Must give in franchise
	assert(args.has('franchise'))
	franchise = args['franchise']
	# Team only used to set jersey?
	if args.has('team'):
		team = args['team']
	else:
		team = Team.new().create_random()
	
	iso.setup_player(player, team, true)
	iso.set_animation('running')
	
	var gc:GridContainer = $This/VBoxContainer/GridContainer
	gc.get_node('NameR').text = player.first + " " + player.last
	gc.get_node('PosR').text = player.pos
	
	update_buttons_on_player()

func update_buttons_on_player() -> void:
	printt('checking if FA has player', franchise.free_agents.has(player.player_id))
	# Only can sign free agents
	sign_button.visible = franchise.free_agents.has(player.player_id)
	sign_button.is_selectable = franchise.free_agents.has(player.player_id)
