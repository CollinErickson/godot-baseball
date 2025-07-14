extends navigable_page
class_name nav_select_team

var current_index:int = 0

func _ready() -> void:
	# Test new class
	var x = ArrayNum.new().init([1,3,5,6])
	printt('array num is', x)
	
	read_in_teams()
	
	page_id = "select_team"
	
	parent_ready()

func handle_nav_button_click(id:String, _args:Dictionary={}) -> void:
	match id:
		'up':
			current_index -= 1
			if current_index < 0:
				current_index = len(teams) - 1
			set_team(current_index)
		'down':
			current_index += 1
			if current_index >= len(teams):
				current_index = 0
			set_team(current_index)
		'accept':
			nav_up({'from': 'select_team',
					'result': 'accept',
					'team_index': current_index})
		'back':
			nav_up({'from': 'select_team',
					'result': 'back'})
	pass

var teams:Array

func read_in_teams():
	#teams = load_from_file("res://data/teams/teams.json")
	#printt('teams csv is', FileUtils.read_csv("res://data/teams/teams.csv"))
	teams = FileUtils.json_cols_to_rows(FileUtils.read_csv("res://data/teams/teams.csv"))
	#printt('read teams', teams)

func set_team(index:int) -> void:
	$This/Panel/Label.text = teams[index]['location'] + "\n" + teams[index]['name']

func setup(_args:Dictionary={}) -> void:
	set_team(current_index)
