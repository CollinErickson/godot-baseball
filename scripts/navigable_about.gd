extends navigable_page
class_name navigable_about

func _ready() -> void:
	page_id = 'about'
	parent_ready()

func handle_nav_button_click(id:String) -> void:
	match id:
		"back":
			printt('clicked back on about page')
			nav_up()
		_:
			unhandled_nav_button_click(page_id, id)
