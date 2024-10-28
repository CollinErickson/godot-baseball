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


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset_field()
	update_scorebug()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func update_scorebug() -> void:
	$Scorebug.update(inning, is_top, outs, balls, strikes, home_runs, away_runs,
					false, true, true)

func _on_field_3d_signal_play_done(ball_in_play: bool, is_ball: bool, is_strike: bool,
									outs_on_play: int, runs_on_play: int) -> void:
	printt('game received signal from field', is_ball, is_strike, outs_on_play, runs_on_play)
	if is_ball:
		balls += 1
	if is_strike:
		strikes += 1
	var new_batter = false
	if ball_in_play:
		# Ball must have been in play
		new_batter = true
	elif balls > 3.5:
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
	if outs > 2.5:
		if is_top:
			is_top = false
		else:
			inning += 1
			is_top = true
		outs = 0
		new_batter = true
	if new_batter:
		balls = 0
		strikes = 0
	#get_node('Field3D').freeze()
	update_scorebug()
	printt('in game, about to reset field')
	reset_field()

func reset_field() -> void:
	$Field3D.reset((is_top and user_is_away_team) or (!is_top and user_is_home_team),
		(is_top and user_is_home_team) or (!is_top and user_is_away_team))
