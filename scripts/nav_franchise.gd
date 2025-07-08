extends navigable_page
class_name nav_franchise

enum State {PRELOAD, WAITING_FOR_PRESEASON_OPTIONS}
var state:State = State.PRELOAD

func _ready() -> void:
	page_id = 'franchise'
	parent_ready()

func after_set_active_true(args:Dictionary={}) -> void:
	match state:
		State.PRELOAD:
			# Go to preseason options
			state = State.WAITING_FOR_PRESEASON_OPTIONS
			nav_to('NavFranchisePreseasonOptions')
		_:
			push_error('bad state in asat')

#func handle_nav_button_click(id:String, _args:Dictionary={}) -> void:
	#pass
