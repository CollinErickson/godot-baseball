extends navigable_page
class_name nav_franchise

enum State {
	PRELOAD,
	WAITING_FOR_PRESEASON_OPTIONS,
	WAITING_FOR_SEASON
}
var state:State = State.PRELOAD

func _ready() -> void:
	page_id = 'franchise'
	parent_ready()

func after_set_active_true(args:Dictionary={}) -> void:
	if args['from'] == 'franchise_load':
		printt('in nav_franchise, loading franchise')
		# Set up
		printt('TODO: set up here')
		var f:Franchise = args['franchise']
		match f.stage:
			f.Stage.FRANCHISE_YEAR_OPTIONS:
				state = State.WAITING_FOR_PRESEASON_OPTIONS
			_:
				push_error('bad f stage', f.stage)
		
	match state:
		State.PRELOAD:
			push_error('This should not happen')
		State.WAITING_FOR_PRESEASON_OPTIONS:
			# Go to preseason options
			#state = State.WAITING_FOR_PRESEASON_OPTIONS
			state = State.WAITING_FOR_SEASON
			nav_to('NavFranchisePreseasonOptions')
		_:
			push_error('bad state in nav_franchise after_set_active_true ', state)

#func handle_nav_button_click(id:String, _args:Dictionary={}) -> void:
	#pass
