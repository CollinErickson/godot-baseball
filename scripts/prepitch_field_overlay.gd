extends Control

func setup_pitcher(player) -> void:
	var vbox = $Pitcher/MarginContainer/MarginContainer/VBoxContainer
	vbox.get_node("Line1").text = player.first + " " + player.last
	vbox.get_node("Line2").text = (
		"Stamina: " +
		str(round(100. * player.current_game_pitching_stamina /
					player.pitching_stamina))
		+ "%"
	)
	vbox.get_node("Line3").text = "Pitching: " + str(player.pitching)
	return

func setup_batter(player) -> void:
	var vbox = $Batter/MarginContainer/MarginContainer/VBoxContainer
	vbox.get_node("Line1").text = player.first + " " + player.last
	vbox.get_node("Line2").text = "Contact: " + str(player.contact)
	vbox.get_node("Line3").text = "Speed: " + str(player.speed)
	# Didn't work, if changing size, need to change position
	#$Batter.size.x = $Batter/MarginContainer/MarginContainer/VBoxContainer.size.x
	return
