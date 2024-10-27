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
	update_scorebug()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_scorebug() -> void:
	$Scorebug.update(inning, is_top, outs, balls, strikes, home_runs, away_runs)

func _on_field_3d_signal_play_done(is_ball: bool, is_strike: bool, outs_on_play: int, runs_on_play: int) -> void:
	printt('game received signal from field', is_ball, is_strike, outs_on_play, runs_on_play)
	if is_ball:
		balls += 1
	if is_strike:
		strikes += 1
	outs += outs_on_play
	if is_top:
		away_runs += runs_on_play
	else:
		home_runs += runs_on_play
	#get_node('Field3D').freeze()
	update_scorebug()
	printt('in game, about to reset field')
	$Field3D.reset()
