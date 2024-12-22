extends Control

func setup_pitcher(player) -> void:
	var vbox = $Pitcher/MarginContainer/VBoxContainer
	vbox.get_node("Line1").text = player.first
	vbox.get_node("Line2").text = player.last
	vbox.get_node("Line3").text = ""
	return


func setup_batter(player) -> void:
	var vbox = $Batter/MarginContainer/VBoxContainer
	vbox.get_node("Line1").text = player.first
	vbox.get_node("Line2").text = player.last
	vbox.get_node("Line3").text = ""
	return
