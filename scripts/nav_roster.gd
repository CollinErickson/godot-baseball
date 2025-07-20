extends navigable_page
class_name nav_roster

var franchise:Franchise

func _ready() -> void:
	page_id = 'roster'
	
	parent_ready()

func handle_nav_button_click(id:String, _args:Dictionary={}) -> void:
	#printt('in nav franchise load handle nav button click', id)
	match id:
		'pitching':
			nav_to('NavRotation', {'franchise':franchise})
		'free_agents':
			nav_to('NavFreeAgents', {'franchise':franchise})
		'back':
			nav_up()
		_:
			push_error('unhandled nav button click ', page_id, ' , ', id)

func setup(args:Dictionary={}):
	if args['from'] == 'franchise_season_home':
		franchise = args['franchise']
