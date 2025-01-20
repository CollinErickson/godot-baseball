extends Control

# Settings
var throw_mode:String = "BarOneWay" # "Button", "Bar", "BarOneWay"
var bat_mode:String = "Target" # "Timing", "Target"
var pitch_mode:String = "BarTwoWay" # "Button", "Bar", "BarOneWay", "BarTwoWay"

# Game variables
var outs_per_inning:int = 3
var strikes_per_pa:int = 3
var balls_per_pa:int = 4

# State variables
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

var player = preload("res://scenes/player.tscn")
var batter:Player  = null
var runner1:Player = null
var runner2:Player = null
var runner3:Player = null

var team_class = preload("res://scenes/team.tscn")
var home_team:Team = team_class.instantiate().create_random()
var away_team:Team = team_class.instantiate().create_random()
var home_team_batting_order_index = 0
var away_team_batting_order_index = 0

var is_paused:bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#printt('test create player:', get_player())
	printt('in game ready', away_team, home_team)
	if !true:
		user_is_away_team = true
		user_is_home_team = false
	home_team.prepare_for_game()
	away_team.prepare_for_game()
	#batter = get_player(50)
	batter = away_team.roster[away_team.batting_order[0]]
	#batter.speed = 1.80
	#runner1 = get_player(50)
	#runner2 = get_player(50)
	#runner3 = get_player(99)
	reset_field()
	update_scorebug()
	
	$PauseMenu.visible = false
	$PauseMenu.is_active = false
	$PauseMenu.connect("return_index_selected", _on_return_index_selected_from_pause_menu)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	# Check for pause/unpause
	if Input.is_action_just_pressed("pause_game"):
		#if is_paused: # Unpause
			#unpause_game_menu()
		if not is_paused: # Pause
			pause_game_menu()
			is_paused = true

func update_scorebug() -> void:
	$Scorebug.update(inning, is_top, outs, balls, strikes, home_runs, away_runs,
					runner1!=null, runner2!=null, runner3!=null,
					away_team.abbr,
					home_team.abbr, outs_per_inning)

func _on_field_3d_signal_play_done(ball_in_play: bool, is_ball: bool, is_strike: bool,
									is_foul_ball: bool,
									outs_on_play: int, runs_on_play: int,
									runner0state: String, runner1state: String,
									runner2state: String, runner3state: String) -> void:
	printt('game received signal from field', ball_in_play, is_ball, is_strike, outs_on_play, runs_on_play)
	#assert(int(ball_in_play) + int(is_ball) + int(is_strike) == 1) fails
	
	var new_batter = false
	var was_top = is_top
	
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
			#TODO: walk
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
		runner1 = r1
		runner2 = r2
		runner3 = r3
	
	# End of half inning, change side and clear bases
	if outs > outs_per_inning - 0.5:
		if is_top:
			is_top = false
		else:
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
		user_input_method)

func get_player(speed:float=50) -> Player:
	var p = player.instantiate()
	p.create_random(speed)
	#p.print_()
	return p

func unpause_game_menu() -> void:
	#printt('Game unpaused!!!')
	$Field3D.unpause()
	$PauseMenu.visible = false
	$PauseMenu.is_active = false
	is_paused = false

func pause_game_menu() -> void:
	#printt('Game paused!!!')
	$Field3D.pause()
	$PauseMenu.visible = true
	$PauseMenu.is_active = true
	is_paused = true

func _on_return_index_selected_from_pause_menu(_index_selected):
	#printt("pause menu index:", index_selected)
	#get_tree().create_timer(1)
	unpause_game_menu()
