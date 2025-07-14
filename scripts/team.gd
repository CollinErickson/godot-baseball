extends Node
class_name Team

# Metadata
var city_name:String
var team_name:String
var abbr:String
var color_primary:Color
var color_secondary:Color
var jersey_style:String
var hat_style:String
#var logo

# Roster
var roster:Array = []
var rosterdict:Dictionary[String, Player] = {}
var batting_order:Array[int] = []
var defense_order:Array[int] = []
var rotation:Array[String] = []

func _ready() -> void:
	# If this is root, test it
	if get_tree().root == get_parent():
		create("New York City", "Buildings", "NYC", "green", "orange")
		print_()
		var ser:String = FileUtils.serialize(self, serialize_map)
		printt('serialized is', ser)
		# Randomize it
		create_random()
		print_()
		# Reload original
		FileUtils.deserialize(self, ser, serialize_map)
		# Check if it worked
		print_()

func create(city_name_,
			team_name_,
			abbr_,
			color_primary_,
			color_secondary_):
	# Set metadata
	city_name = city_name_
	team_name = team_name_
	abbr = abbr_
	color_primary = color_primary_
	color_secondary = color_secondary_
	
	create_roster()
	
	randomize_jersey()
	
	printt('New team is:', self)
	print_()
	
	return self

func create_roster():
	# Create roster
	roster = []
	for i in range(26):
		var player:Player = get_player()
		roster.push_back(player)
		rosterdict[player.player_id] = player
	
	# Index i equals j means that roster[j] bats i+1 in batting order
	batting_order = [0,1,2,3,4,5,6,7,8] # range(9)
	batting_order.shuffle()
	# Index i equals j means that roster[j] plays position i+1
	defense_order = [0,1,2,3,4,5,6,7,8] #range(9)
	defense_order.shuffle()
	
	# Set rotation, player ID in order of SP1 to SP5
	rotation = []
	# Put all pitchers in array
	for pid in rosterdict.keys():
		if rosterdict[pid].is_pitcher():
			rotation.push_back(pid)
	# TODO: Sort by SP and overall
	# Only keep top 5
	if len(rotation) > 5:
		rotation = rotation.slice(0,5)
	# TODO: Could have less than 5. Use nonpitchers or leave empty?

#const sample_colors = ["red", "yellow", "blue", "green", "white", "black",
						#Color(1,.5,.5), Color(0,.5,.5)]
func random_color() -> Color:
	var r = randf_range(0,1)
	var g = randf_range(0,1)
	var b = randf_range(0,1)
	return Color(r,g,b)

func create_random():
	
	
	city_name = ["Minnesota", "New York City", "Washington Heights", "Bronx", "Nashville"].pick_random()
	team_name = ["Otters", "Construction Workers", "Icebergs", "Burritos", "Tricycles"].pick_random()
	abbr = ["MIN", "NYC", "USA"].pick_random()
	
	color_primary = random_color()
	color_secondary = random_color()
	
	create_roster()
	
	randomize_jersey()
	
	return self


#const player_class = preload("res://scenes/player.tscn")
func get_player(speed:float=randi_range(20,80)) -> Player:
	#var p = player_class.instantiate()
	var p = Player.new()
	p.create_random(speed)
	return p

func print_():
	var s = 'Team: ' + city_name + ' ' + team_name
	print(s)
	print("Roster:")
	for player in roster:
		player.print_()
	printt('\tBatting order', batting_order)

func randomize_jersey() -> void:
	# Randomize jersey/hat style
	jersey_style = ["PP", "PS"].pick_random()
	hat_style = ["PP", "PS", "SP", "SS"].pick_random()

func prepare_for_game() -> bool:
	# Prepare team for a game
	# Reset pitcher stamina
	for player in roster:
		player.current_game_pitching_stamina = player.pitching_stamina
	# Return true if everything worked
	return true

var serialize_map:Array = [
	['c', 'city_name', 's'],
	['t', 'team_name', 's'],
	['a', 'abbr', 's'],
	['cp', 'color_primary', 'color'],
	['cs', 'color_secondary', 'color'],
	['j', 'jersey_style', 's'],
	['h', 'hat_style', 's'],
	['r', 'roster', 'a_player'],
	['b', 'batting_order', 'a_i'],
	['d', 'defense_order', 'a_i']
]

func serialize() -> String:
	return ''
