extends Control

var inning:int = 1
var is_top:bool = true
var outs:int = 0
var balls:int = 0
var strikes:int = 0
var home_runs:int = 0
var away_runs:int = 0
var user_is_away_team:bool = false
var user_is_home_team:bool = true
var player = preload("res://scenes/player.tscn")
var batter:Player  = null
var runner1:Player = null
var runner2:Player = null
var runner3:Player = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#printt('test create player:', get_player())
	if !true:
		user_is_away_team = true
		user_is_home_team = false
	batter = get_player(50)
	#runner1 = get_player(50)
	#runner2 = get_player(50)
	#runner3 = get_player(99)
	reset_field()
	update_scorebug()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func update_scorebug() -> void:
	$Scorebug.update(inning, is_top, outs, balls, strikes, home_runs, away_runs,
					runner1!=null, runner2!=null, runner3!=null)

func _on_field_3d_signal_play_done(ball_in_play: bool, is_ball: bool, is_strike: bool,
									is_foul_ball: bool,
									outs_on_play: int, runs_on_play: int,
									runner0state: String, runner1state: String,
									runner2state: String, runner3state: String) -> void:
	printt('game received signal from field', ball_in_play, is_ball, is_strike, outs_on_play, runs_on_play)
	#assert(int(ball_in_play) + int(is_ball) + int(is_strike) == 1) fails
	
	var new_batter = false
	if ball_in_play:
		# Ball must have been in play
		if is_foul_ball:
			if strikes < 1.5:
				strikes += 1
		else:
			new_batter = true
	else:
		if is_ball:
			balls += 1
		if is_strike:
			strikes += 1
		if balls > 3.5:
			#TODO: walk
			balls = 0
			new_batter = true
		elif strikes > 2.5:
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
	if outs > 2.5:
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
		batter = get_player()
	#get_node('Field3D').freeze()
	update_scorebug()
	printt('\n\n\n\n\n\n\n\n\n\n\n\n\nin game, about to reset field')
	reset_field()

func reset_field() -> void:
	batter.print_()
	$Field3D.reset(
		(is_top and user_is_away_team) or (!is_top and user_is_home_team),
		(is_top and user_is_home_team) or (!is_top and user_is_away_team),
		batter,
		runner1,
		runner2,
		runner3,
		outs)

func get_player(speed:float=50) -> Player:
	var p = player.instantiate()
	var f = ["Nick", "Britt", "Greg", "Troy"]
	var l = ["Farinacci", "Fugett", "Ferrara", 'Vergara']
	p.setup(f.pick_random(), l.pick_random(), speed, 39.)
	#p.print_()
	return p
