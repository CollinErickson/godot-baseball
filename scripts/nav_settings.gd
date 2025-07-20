extends navigable_page
class_name navigable_settings

func _ready() -> void:
	page_id = 'settings'
	
	parent_ready()

func handle_nav_button_click(id:String, _args:Dictionary={}) -> void:
	match id:
		'accept':
			var gc:GridContainer = $This/StandardBackground/VBoxContainer/GridContainer
			var gs:GameplaySettings = GameplaySettings.new()
			gs.innings_per_game = int(gc.get_node('Innings').text)
			gs.difficulty = gc.get_node('Difficulty').text
			gs.bat_mode = gc.get_node('BatMode').text
			gs.pitch_mode = gc.get_node('PitchMode').text
			gs.throw_mode = gc.get_node('ThrowMode').text
			gs.baserunning_control = gc.get_node('BRControl').text
			gs.defense_control = gc.get_node('DefControl').text
			assert(gs.is_valid())
			printt('passing up gs', gs, gs.innings_per_game)
			nav_up({
				'from':page_id,
				'result':'accept',
				'GameplaySettings':gs
			})
		'back':
			nav_up({
				'from':page_id,
				'result':'back'
			})
		_:
			#push_error('bad match id', id)
			pass

func setup(args:Dictionary={}) -> void:
	var gc:GridContainer = $This/StandardBackground/VBoxContainer/GridContainer
	var gs:GameplaySettings
	if this_is_root:
		gs = GameplaySettings.new()
	else:
		gs = args['GameplaySettings']
	assert(gs.is_valid())
	printt('gs:', gs.difficulty, gs.innings_per_game)
	gc.get_node('Difficulty').set_text2(gs.difficulty)
	gc.get_node('Innings').set_text2(gs.innings_per_game)
	gc.get_node('BatMode').set_text2(gs.bat_mode)
	gc.get_node('PitchMode').set_text2(gs.pitch_mode)
	gc.get_node('ThrowMode').set_text2(gs.throw_mode)
	gc.get_node('BRControl').set_text2(gs.baserunning_control)
	gc.get_node('DefControl').set_text2(gs.defense_control)
