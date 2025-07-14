extends navigable_page
class_name nav_roster

func _ready() -> void:
	page_id = 'roster'
	
	parent_ready()

func handle_nav_button_click(id:String, _args:Dictionary={}) -> void:
	#printt('in nav franchise load handle nav button click', id)
	match id:
		_:
			push_error('unhandled nav button click ', page_id, ' , ', id)
