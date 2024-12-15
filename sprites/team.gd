extends Node
class_name Team

# Metadata
var city_name:String
var team_name:String
var abbr:String
var color_primary:Color
var color_secondary:Color
#var logo

# Roster
var roster:Array = []
var batting_order:Array = []
var defense_order:Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
	# If this is root, test is
	if get_tree().root == get_parent():
		create("New York City", "Buildings", "NYC", "green", "orange")

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
	
	printt('New team is:', self)
	print_()
	
	return self

func create_roster():
	# Create roster
	for i in range(9):
		roster.push_back(get_player())
	
	# Index i equals j means that roster[j] bats i+1 in batting order
	batting_order = range(9)
	batting_order.shuffle()
	# Index i equals j means that roster[j] plays position i+1
	defense_order = range(9)
	defense_order.shuffle()

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
	
	return self


const player_class = preload("res://scenes/player.tscn")
func get_player(speed:float=randi_range(20,80)) -> Player:
	var p = player_class.instantiate()
	p.create_random(speed)
	return p

func print_():
	var s = 'Team: ' + city_name + ' ' + team_name
	print(s)
	print("Roster:")
	for player in roster:
		player.print_()
