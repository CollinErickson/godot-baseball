extends navigable_page
class_name nav_schedule

var franchise:Franchise

func _ready() -> void:
	page_id = 'NavSchedule'
	
	parent_ready()

func handle_nav_button_click(id:String, _args:Dictionary={}) -> void:
	#printt('in nav franchise load handle nav button click', id)
	match id:
		"back":
			nav_up()
		"play":
			nav_to('NavGame', {
				'away_team':franchise.orgs[1].teams[0],
				'home_team':franchise.orgs[1].teams[1]
			})


func setup(args:Dictionary={}):
	if args['from'] == 'franchise_season_home':
		franchise = args['franchise']
	if this_is_root:
		franchise = Franchise.new()
		franchise.create_from_team_index(0)
