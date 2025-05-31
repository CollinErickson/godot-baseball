extends Control

# Settings
var throw_mode:String = "BarOneWay" # "Button", "Bar", "BarOneWay"
var bat_mode:String = "Target" # "Timing", "Target"
var pitch_mode:String = "BarTwoWay" # "Button", "Bar", "BarOneWay", "BarTwoWay"

# Game variables
var innings_per_game:int = 1
var outs_per_inning:int = 3
var strikes_per_pa:int = 3
var balls_per_pa:int = 1

# State variables
var state:String = "pregame" # pregame, ingame, postgame
var inning:int = 1
var is_top:bool = true
var outs:int = 0
var balls:int = 0
var strikes:int = 0
var home_runs:int = 0
var away_runs:int = 0
var user_is_away_team:bool = false
var user_is_home_team:bool = true
var user_input_method:String = "keyboard" # "mouse", "keyboard", "controller"
var game_data:Dictionary = {}

var player = preload("res://scenes/player.tscn")
var batter:Player  = null
var runner1:Player = null
var runner2:Player = null
var runner3:Player = null

var team_class = preload("res://scenes/team.tscn")
var home_team:Team = team_class.instantiate().create_random()
var away_team:Team = team_class.instantiate().create_random()
var home_team_batting_order_index:int = 0
var away_team_batting_order_index:int = 0

var is_paused:bool = false
var this_is_root:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#printt('test create player:', get_player())
	printt('in game ready', away_team, home_team)
	
	if get_tree().root == get_parent():
		this_is_root = true
	
	if true:
		user_is_away_team = true
		user_is_home_team = false
	
	$PauseMenu.connect("return_index_selected", _on_return_index_selected_from_pause_menu)

	if this_is_root:
		#$Game.visible()
		start_game()

func start_game() -> void:
	# Reset game params
	state = 'ingame'
	inning = 1
	is_top = true
	outs = 0
	balls = 0
	strikes = 0
	home_runs = 0
	away_runs = 01
	home_team_batting_order_index = 0
	away_team_batting_order_index = 0
	
	# Prepare teams/players
	home_team.prepare_for_game()
	away_team.prepare_for_game()
	#batter = get_player(50)
	batter = away_team.roster[away_team.batting_order[0]]
	#batter.speed = 1.80
	#runner1 = get_player(50)
	#runner2 = get_player(50)
	#runner3 = get_player(99)
	reset_field()
	$Scorebug.visible = true
	update_scorebug()
	
	$PauseMenu.visible = false
	$PauseMenu.is_active = false
	
	game_data = {
		'home_team':home_team,
		'away_team':away_team,
		'away_score_by_inning':[],
		'home_score_by_inning':[]
	}

func _process(_delta: float) -> void:
	#printt('in game _process, scorebug visible', $Scorebug.visible)
	if state == "ingame":
		# Check for pause
		if Input.is_action_just_pressed("pause_game"):
			if not is_paused: # Pause
				pause_game_menu()
			# Unpause is done in the pause menu and returned to game as a signal
	elif state == 'postgame':
		if Input.is_action_just_pressed("ui_accept"):
			$PostGame.visible = false
			game_over.emit()

func update_scorebug() -> void:
	$Scorebug.update(inning, is_top, outs, balls, strikes, home_runs, away_runs,
					runner1!=null, runner2!=null, runner3!=null,
					away_team.abbr,
					home_team.abbr, outs_per_inning)

signal game_over
func _on_field_3d_signal_play_done(ball_in_play: bool, is_ball: bool, is_strike: bool,
									is_foul_ball: bool,
									outs_on_play: int, runs_on_play: int,
									runner0state: String, runner1state: String,
									runner2state: String, runner3state: String) -> void:
	printt('game received signal from field', ball_in_play, is_ball, is_strike,
		outs_on_play, runs_on_play, runner0state)
	#assert(int(ball_in_play) + int(is_ball) + int(is_strike) == 1) fails
	
	var new_batter:bool = false
	var was_inning:int = inning
	var was_top:bool = is_top
	
	if ball_in_play:
		# Ball must have been in play
		if is_foul_ball:
			if strikes < strikes_per_pa - 1.5:
				strikes += 1
		else:
			new_batter = true
	else:
		if is_ball:
			balls += 1
		if is_strike:
			strikes += 1
		if balls > balls_per_pa - 0.5:
			# Walk
			# Move runners, it isn't done in field
			runner0state = '1'
			if runner1state == '1':
				runner1state = '2'
				if runner2state == '2':
					runner2state = '3'
					if runner3state == '3':
						runner3state = 'scored'
						runs_on_play += 1
			
			# Prepare for next
			balls = 0
			new_batter = true
		elif strikes > strikes_per_pa - 0.5:
			strikes = 0
			outs_on_play += 1
			new_batter = true
		else:
			# Was ball/strike, but not enough to go to next batter
			pass
	outs += outs_on_play
	if is_top:
		away_runs += runs_on_play
	else:
		home_runs += runs_on_play
	# Update runners
	if !is_foul_ball:
		var r1 = null
		var r2 = null
		var r3 = null
		var runner_pairs = [[batter, runner0state], [runner1, runner1state],
							[runner2, runner2state], [runner3, runner3state]]
		for pair in runner_pairs:
			if pair[1] == '1':
				r1 = pair[0]
			elif pair[1] == '2':
				r2 = pair[0]
			elif pair[1] == '3':
				r3 = pair[0]
			else:
				assert(pair[1] in ["", "out", "scored", "0"])
		runner1 = r1
		runner2 = r2
		runner3 = r3
	
	# End of half inning, change side and clear bases
	if outs > outs_per_inning - 0.5:
		if is_top:
			if inning == 1:
				game_data.away_score_by_inning.push_back(away_runs)
			else:
				game_data.away_score_by_inning.push_back(
					away_runs - game_data.away_score_by_inning.back())
			is_top = false
		else:
			if inning == 1:
				game_data.home_score_by_inning.push_back(home_runs)
			else:
				game_data.home_score_by_inning.push_back(
					home_runs - game_data.home_score_by_inning.back())
			inning += 1
			is_top = true
		outs = 0
		new_batter = true
		runner1 = null
		runner2 = null
		runner3 = null
	if new_batter:
		balls = 0
		strikes = 0
		#batter = get_player()
		if was_top:
			away_team_batting_order_index += 1
			if away_team_batting_order_index > 8.5:
				away_team_batting_order_index = 0
		else:
			home_team_batting_order_index += 1
			if home_team_batting_order_index > 8.5:
				home_team_batting_order_index = 0
		if is_top:
			batter = away_team.roster[away_team.batting_order[away_team_batting_order_index]]
		else:
			batter = home_team.roster[home_team.batting_order[home_team_batting_order_index]]
	#get_node('Field3D').freeze()
	update_scorebug()
	
	# Check if game is over 
	if ((inning > innings_per_game and away_runs != home_runs and was_inning < inning) or
		(inning >= innings_per_game and not is_top and away_runs < home_runs)):
		#game_over.emit()
		state = 'postgame'
		$Field3D.set_vis(false)
		$Scorebug.visible = false
		$PostGame.visible = true
		
		# Finalize game_data and give to Postgame
		game_data['innings'] = inning - (1 if is_top else 0)
		game_data['home_runs'] = home_runs
		game_data['away_runs'] = away_runs
		$PostGame.set_values(game_data)
		
		return
	
	# Otherwise continue the game
	printt('\n\n\n\n\n\n\n\n\n\n\n\n\nin game, about to reset field')
	reset_field()

func reset_field() -> void:
	$Field3D.reset(
		(is_top and user_is_away_team) or (!is_top and user_is_home_team),
		(is_top and user_is_home_team) or (!is_top and user_is_away_team),
		batter,
		#home_team.roster[0] if is_top else away_team.roster[0],
		runner1,
		runner2,
		runner3,
		outs,
		outs_per_inning,
		home_team if is_top else away_team,
		home_team if !is_top else away_team,
		is_top,
		throw_mode,
		bat_mode,
		pitch_mode,
		user_input_method,
		strikes + 1 >= strikes_per_pa - 0.5, # potential strikeout
		balls + 1 >= balls_per_pa - 0.5 # potential walk
		)

func get_player(speed:float=50) -> Player:
	var p = player.instantiate()
	p.create_random(speed)
	#p.print_()
	return p

func unpause_game_menu() -> void:
	#printt('Game unpaused!!!')
	$Field3D.unpause()
	#$PauseMenu.visible = false
	#$PauseMenu.is_active = false
	$PauseMenu.set_active(true)
	is_paused = false

func pause_game_menu() -> void:
	#printt('Game paused!!!')
	$Field3D.pause()
	#$PauseMenu.visible = true
	#$PauseMenu.is_active = true
	$PauseMenu.set_active(true)
	is_paused = true

func _on_return_index_selected_from_pause_menu(_index_selected):
	#printt("pause menu index:", index_selected)
	#get_tree().create_timer(1)
	unpause_game_menu()

func set_settings(s:Dictionary) -> void:
	printt('in game set_settings:', s)
	innings_per_game = s.innings
	outs_per_inning = s.outs
	balls_per_pa = s.balls
	strikes_per_pa = s.strikes
	bat_mode = s.bat_mode
	pitch_mode = s.pitch_mode
	throw_mode = s.throw_mode

func set_vis(val:bool) -> void:
	visible = val
	$Field3D.set_vis(val)
