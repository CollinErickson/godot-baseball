extends navigable_page
class_name franchise_season_home

func _ready() -> void:
	page_id = 'franchise_season_home'
	parent_ready()

func handle_nav_button_click(id:String, _args:Dictionary={}) -> void:
	match id:
		'settings':
			nav_to('NavSettings')
		_:
			printt('unhandled nav click ', page_id, ' ', id)

func setup(args:Dictionary={}) -> void:
	if 'from' in args.keys():
		if args['from'] == 'settings':
			pass
