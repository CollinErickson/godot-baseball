extends navigable_page
class_name navigable_settings

func _ready() -> void:
	page_id = 'settings'
	parent_ready()

func handle_nav_button_click(id:String, _args:Dictionary={}) -> void:
	match id:
		'accept':
			nav_up({
				'from':page_id,
				'result':'accept'
			})
		'back':
			nav_up({
				'from':page_id,
				'result':'back'
			})
		_:
			#push_error('bad match id', id)
			pass
