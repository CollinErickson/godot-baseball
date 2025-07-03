extends navigable_page
class_name navigable_home_page

func _ready() -> void:
	page_id = 'home'
	parent_ready()

func handle_nav_button_click(id:String, _args:Dictionary={}) -> void:
	printt('in nav main menu handle nav button click', id)
	match id:
		'play_now':
			printt('clicked on play now')
		'franchise':
			printt('clicked on franchise')
			nav_to('NavFranchiseLoad')
		'about':
			printt('clicked on about')
			nav_to("NavigableAbout")
		'quit':
			printt('clicked on quit')
			get_tree().quit()
		_:
			unhandled_nav_button_click(page_id, id)
