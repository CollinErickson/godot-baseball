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
