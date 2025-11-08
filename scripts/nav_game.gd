extends navigable_page
class_name navigable_game

var franchise:Franchise
@onready var game_node:GameNode = $This/Game
var away_team:Team
var home_team:Team
var currently_in_game:bool = false

func _ready() -> void:
	page_id = 'navigable_game'
	parent_ready()
	
	# Connect signal for game end
	game_node.connect('game_over', game_end)

func handle_nav_button_click(id:String, _args:Dictionary={}) -> void:
	match id:
		pass

func setup(args:Dictionary={}) -> void:
	if this_is_root:
		away_team = Team.new()
		away_team.create_random()
		home_team = Team.new()
		home_team.create_random()
	else:
		away_team = args.away_team
		home_team = args.home_team
	setup_game()

func setup_game() -> void:
	# 
	printt('in nav_game, setup_game, away team is',
			away_team.city_name, away_team.team_name)
	printt('in nav_game, setup_game, home team is',
			home_team.city_name, home_team.team_name)
	
	# Turn off navigable page
	skip_nav_page_process = true
	
	# Set up game
	#game_node.set_settings(franchise.gameplay_settings)
	game_node.away_team = away_team
	game_node.home_team = home_team
	game_node.start_game()

func game_end() -> void:
	printt('in nav game game_end')
	nav_up()
