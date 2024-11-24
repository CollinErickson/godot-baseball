extends Control


func update(inning: int, is_top: bool, outs: int, balls: int, strikes: int,
		home_runs:int, away_runs:int, runner1:bool, runner2:bool, runner3:bool,
		away_abbr:String, home_abbr:String) -> void:
	$HBoxContainer/Inning.text = str(inning)
	#$HBoxContainer/Outs.text = str(outs)
	if outs == 0:
		$HBoxContainer/Outs.text = "○ ○ ○"
	elif outs == 1:
		$HBoxContainer/Outs.text = "◉ ○ ○"
	elif outs == 2:
		$HBoxContainer/Outs.text = "◉ ◉ ○"
	elif outs == 3:
		$HBoxContainer/Outs.text = "◉ ◉ ◉"
	else:
		printerr('error in scorebug, outs is ', outs)
	$HBoxContainer/Balls.text = str(balls)
	$HBoxContainer/Strikes.text = str(strikes)
	$HBoxContainer/Scores/HomeScore.text = str(home_runs)
	$HBoxContainer/Scores/AwayScore.text = str(away_runs)
	if is_top:
		$HBoxContainer/TopBottom.text = '▲'
	else:
		$HBoxContainer/TopBottom.text = '▼'
	var br = ''
	if runner3:
		br += '<'
	else:
		br += ' '
	if runner2:
		br += '^'
	else:
		br += ' '
	if runner1:
		br += '>'
	else:
		br += ' '
	$HBoxContainer/Baserunners.text = br
	
	$HBoxContainer/TeamNames/AwayName.text = away_abbr
	$HBoxContainer/TeamNames/HomeName.text = home_abbr
