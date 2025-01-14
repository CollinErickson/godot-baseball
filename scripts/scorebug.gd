extends Control

func update(inning: int, is_top: bool, outs: int, balls: int, strikes: int,
		home_runs:int, away_runs:int, runner1:bool, runner2:bool, runner3:bool,
		away_abbr:String, home_abbr:String, outs_possible: int) -> void:
	var hbox = $PanelContainer/MarginContainer/HBoxContainer
	hbox.get_node("Inning").text = str(inning)

	# Set outs
	assert(outs < outs_possible)
	hbox.get_node("Outs").text = "  "
	for i in range(outs):
		hbox.get_node("Outs").text += "◉ "
	for i in range(outs_possible - outs):
		hbox.get_node("Outs").text += "○ "
	hbox.get_node("Balls").text = "  " + str(balls)
	hbox.get_node("Strikes").text = str(strikes) + "  "
	hbox.get_node("Scores/HomeScore").text = str(home_runs)
	hbox.get_node("Scores/AwayScore").text = str(away_runs)
	if is_top:
		hbox.get_node("TopBottom").text = ' ▲'
	else:
		hbox.get_node("TopBottom").text = ' ▼'
	
	hbox.get_node("TeamNames/AwayName").text = away_abbr + "  "
	hbox.get_node("TeamNames/HomeName").text = home_abbr + "  "
	
	# Set baserunners
	$PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/BasesAllColorRect/BasesAll/Base1Black.visible = runner1
	$PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/BasesAllColorRect/BasesAll/Base2Black.visible = runner2
	$PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/BasesAllColorRect/BasesAll/Base3Black.visible = runner3
