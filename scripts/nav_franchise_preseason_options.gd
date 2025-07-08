extends navigable_page
class_name franchise_preseason_options

func _ready() -> void:
	page_id = 'franchise_preseason_options'
	parent_ready()

func handle_nav_button_click(id:String, _args:Dictionary={}) -> void:
	match id:
		'accept':
			nav_up({
				'from':'franchise_preseason_options',
				'result':'accept',
				'games':int($This/VBoxContainer/GridContainer/Games.current_value())
			})
		'back':
			nav_up({
				'from':'franchise_preseason_options',
				'result':'back'
			})
		_:
			push_error('bad ID', id)
