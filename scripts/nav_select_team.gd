extends navigable_page
class_name nav_select_team

var current_index:int = 0

func _ready() -> void:
	
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
			nav_up({'result': 'accept', 'team_index': current_index})
		'back':
			nav_up({'result': 'back'})
	pass

var teams:Array

func read_in_teams():
	teams = load_from_file("res://data/teams/teams.json")
	#teams = read_csv("res://data/teams/teams.csv")
func load_from_file(path:String):
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	printt('file is', file)
	printt('content is', content)
	#return content
	
	var json_string = content
	## Retrieve data
	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK:
		var data_received = json.data
		if typeof(data_received) == TYPE_ARRAY:
			printt('data array is', len(data_received), data_received) # Prints the array.
			printt('element one', data_received[0], data_received[0]['name'])
			return data_received
		else:
			print("Unexpected data")
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())

func set_team(index:int) -> void:
	$This/Panel/Label.text = teams[index]['name']

func setup(_args:Dictionary={}) -> void:
	set_team(current_index)

func json_rows_to_cols(x:Array) -> Dictionary:
	#printt('in nav select team json_rows_to_cols', x)
	var y:Dictionary = {}
	for i in range(len(x)):
		var xi:Dictionary = x[i]
		for key in xi.keys():
			if i == 0:
				y[key] = [xi[key]]
			else:
				y[key].push_back(xi[key])
	return y

func json_cols_to_rows(x:Dictionary) -> Array:
	#printt('in nav select team json_cols_to_rows', x)
	var y:Array = []
	var ks:Array = x.keys()
	for i in range(len(x[ks[0]])):
		var yi:Dictionary = {}
		for k in ks:
			yi[k] = x[k][i]
		y.push_back(yi)
	return y
