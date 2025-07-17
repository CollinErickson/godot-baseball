extends navigable_page
class_name nav_franchise

enum State {
	PRELOAD,
	GOTO_PRESEASON_OPTIONS,
	WAITING_FOR_PRESEASON_OPTIONS,
	GOTO_SEASON,
	WAITING_FOR_SEASON
}
var state:State = State.PRELOAD
var franchise:Franchise

func _ready() -> void:
	page_id = 'franchise'
	parent_ready()

func after_set_active_true(args:Dictionary={}) -> void:
	# If just loaded, get set up
	if args['from'] == 'franchise_load':
		printt('in nav_franchise, loading franchise')
		# Set up
		printt('TODO: set up here')
		#var f:Franchise = args['franchise']
		franchise = args['franchise']
		match franchise.stage:
			franchise.Stage.FRANCHISE_YEAR_OPTIONS:
				state = State.GOTO_PRESEASON_OPTIONS
			_:
				push_error('bad f stage', franchise.stage)
	elif args['from'] == 'franchise_season_home':
		if args['result'] == 'quit':
			nav_up({'result':'quit'})
		else:
			printt('up from franch season home, no result', args['result'])
	else:
		# Handle input from previous page, prepare for next step
		# state is where it is coming from
		match state:
			State.PRELOAD:
				push_error('This should not happen')
			State.WAITING_FOR_PRESEASON_OPTIONS:
				# It returned from preseason options
				printt('in nav fr waiting for presopts', args)
				if args['from'] != "franchise_preseason_options":
					push_error('bad from', args['from'])
				match args['result']:
					'accept':
						franchise.set_preseason_options(args['games'])
						franchise.setup_season()
					'back':
						push_error('do not allow this')
						# Not sure why this is even an option...
					_:
						push_error('bad result', args['result'])
				# Go to preseason options
				state = State.GOTO_SEASON
			State.WAITING_FOR_SEASON:
				printt('NEED TO HANDLE THIS')
				#nav_to('NavFranchiseSeasonMain')
				state = State.GOTO_SEASON
			_:
				push_error('bad state in nav_franchise after_set_active_true ', state)
	
	# Navigate to the next page
	match state:
		State.GOTO_PRESEASON_OPTIONS:
			state = State.WAITING_FOR_PRESEASON_OPTIONS
			nav_to('NavFranchisePreseasonOptions')
		State.GOTO_SEASON:
			state = State.WAITING_FOR_SEASON
			nav_to('NavFranchiseSeasonHome', {'franchise':franchise})
		_:
			push_error('bad state for go to: ', state)
#func handle_nav_button_click(id:String, _args:Dictionary={}) -> void:
	#pass
