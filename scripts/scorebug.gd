extends Control


func update(inning: int, _is_top: bool, outs: int, balls: int, strikes: int, home_runs:int, away_runs:int) -> void:
	$HBoxContainer/Inning.text = str(inning)
	$HBoxContainer/Outs.text = str(outs)
	$HBoxContainer/Balls.text = str(balls)
	$HBoxContainer/Strikes.text = str(strikes)
	$HBoxContainer/Scores/HomeScore.text = str(home_runs)
	$HBoxContainer/Scores/AwayScore.text = str(away_runs)
