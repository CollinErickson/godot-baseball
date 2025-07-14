extends navigable_page
class_name franchise_season_home

func _ready() -> void:
	page_id = 'franchise_season_home'
	parent_ready()

func handle_nav_button_click(id:String, _args:Dictionary={}) -> void:
	match id:
		'settings':
			nav_to('NavSettings')
		'quit':
			nav_up({'result':'quit'})
		_:
			printt('unhandled nav click ', page_id, ' ', id)

func setup(args:Dictionary={}) -> void:
	if args['from'] == 'settings':
			printt('TODO save settings')
