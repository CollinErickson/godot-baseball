extends navigable_page
class_name navigable_home_page

func _ready() -> void:
	page_id = 'home'
	parent_ready()
#
#func connect_buttons(nav_buttons_) -> void:
	#printt('in nav home page connect buttons', nav_buttons_)
	#for button in nav_buttons_:
		#button.connect('signal_clicked', handle_nav_button_click)

func handle_nav_button_click(id:String) -> void:
	printt('in nav main menu handle nav button click', id)
	match id:
		'play_now':
			printt('clicked on play now')
		'franchise':
			printt('clicked on franchise')
		'about':
			printt('clicked on about')
			nav_to("NavigableAbout")
		'quit':
			printt('clicked on quit')
			get_tree().quit()
		_:
			unhandled_nav_button_click(page_id, id)
