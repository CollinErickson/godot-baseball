extends navigable_page
class_name franchise_new

enum State {BEFORE, WAITING_FOR_SELECT_TEAM, PREOPTIONS}
var state:State = State.BEFORE 

func _ready() -> void:
	page_id = 'franchise_new'
	parent_ready()

#func setup(_args:Dictionary={}) -> void:
	## Nav to select team
	#pass

func after_set_active_true(args:Dictionary={}) -> void:
	if state == State.BEFORE:
		# Hasn't started yet, go to select team
		state = State.WAITING_FOR_SELECT_TEAM
		nav_to('NavSelectTeam')
	elif state == State.WAITING_FOR_SELECT_TEAM:
		if args['from'] != 'select_team':
			push_error(489124127, args)
		if args['result'] == 'back':
			state = State.BEFORE
			nav_up()
		elif args['result'] == 'accept':
			printt('select team here', args['team_index'])
			state = State.PREOPTIONS
			#nav_to('NavFranchiseNewOptions')
			# Create franchise with selected team_index
			var franchise:Franchise = Franchise.new()
			franchise.create_from_team_index(args['team_index'])
			# Done, return up
			state = State.BEFORE
			nav_up({
				#'from':'franchise_new',
				'team_index':args['team_index'],
				'franchise':franchise
			})
		else:
			push_error('bad option in select team', args['result'])
