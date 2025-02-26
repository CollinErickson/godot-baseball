extends Control

var main_menu_settings:Dictionary = {
	'difficulty': 2,
	'innings': 3,
	'outs': 3,
	'balls': 4,
	'strikes': 3,
	'bat_mode': 'Timing',
	'pitch_mode': 'BarTwoWay',
	'throw_mode': 'BarOneWay',
}

func _ready() -> void:
	# Connect start menu
	$StartMenu.connect("return_index_selected", _on_main_menu_selection)
	# Connect settings menu
	$SettingsMenu.connect("menu_selected", _on_settings_menu_selection)
	# Connect game
	$Game.connect("game_over", _on_game_over_from_game)

#func _process(delta: float) -> void:
	#pass

func _on_main_menu_selection(index_selected):
	if index_selected == 0:
		# Play ball
		pass
		# Start game
		$Game.set_vis(true)
		$Game.set_settings(main_menu_settings)
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
	main_menu_settings['innings'] = int(out_array[1])
	main_menu_settings['outs'] = int(out_array[2])
	main_menu_settings['balls'] = int(out_array[3])
	main_menu_settings['strikes'] = int(out_array[4])
	main_menu_settings['bat_mode'] = out_array[5]
	# Pitch mode
	match out_array[6]:
		'Bar':
			main_menu_settings['pitch_mode'] = 'Bar'
		'Button':
			main_menu_settings['pitch_mode'] = 'Button'
		'Bar one way':
			main_menu_settings['pitch_mode'] = 'BarOneWay'
		'Bar two way':
			main_menu_settings['pitch_mode'] = 'BarTwoWay'
		_:
			push_warning('Bad pitch_mode from main menu settings')
	# Throw mode
	match out_array[7]:
		'Bar':
			main_menu_settings['throw_mode'] = 'Bar'
		'Button':
			main_menu_settings['throw_mode'] = 'Button'
		'Bar one way':
			main_menu_settings['throw_mode'] = 'BarOneWay'
		'Bar two way':
			main_menu_settings['throw_mode'] = 'BarTwoWay'
		_:
			push_warning('Bad throw_mode from main menu settings')
	
	# Restart main menu
	$StartMenu.set_active(true)

func _on_game_over_from_game():
	$Game.set_vis(false)
	$StartMenu.set_active(true)
