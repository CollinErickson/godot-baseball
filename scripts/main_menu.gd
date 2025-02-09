extends Control

var main_menu_settings:Dictionary = {
	'difficulty': 2,
	'innings': 3,
	'outs': 3,
	'balls': 4,
	'strikes': 3
}

func _ready() -> void:
	# Connect start menu
	$StartMenu.connect("return_index_selected", _on_main_menu_selection)
	# Connect settings menu
	$SettingsMenu.connect("menu_selected", _on_settings_menu_selection)

#func _process(delta: float) -> void:
	#pass

func _on_main_menu_selection(index_selected):
	if index_selected == 0:
		# Play ball
		pass
		# Start game
		$Game.visible
		$Game.start_game()
	elif index_selected == 1:
		# Settings
		# Make it active
		$SettingsMenu.set_active(true)
	else:
		push_error('bad selection in main menu', index_selected)

func _on_settings_menu_selection(out_array:Array):
	# Set values
	main_menu_settings['difficulty'] = out_array[0]
	main_menu_settings['innings'] = out_array[1]
	main_menu_settings['outs'] = out_array[2]
	main_menu_settings['balls'] = out_array[3]
	main_menu_settings['strikes'] = out_array[4]
	
	# Restart main menu
	$StartMenu.set_active(true)
