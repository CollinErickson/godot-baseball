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
var roster:Array[Player] = []
var rosterdict:Dictionary[String, Player] = {}
var batting_order:Array[String] = []
var current_game_batting_order:Array[String] = []
var defense_order:Array[String] = []
var current_game_defense_order:Array[String] = []
var rotation:Array[String] = []
var rotation_next_starter_index:int = 0

# Season data
var games:Array[Game] = []

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
	
	#create_roster()
	
	randomize_jersey()
	
	printt('New team is:', self)
	print_()
	
	return self

func create_roster():
	# Create roster
	roster = []
	rosterdict = {}
	for i in range(26):
		var player:Player = get_player()
		roster.push_back(player)
		rosterdict[player.player_id] = player
	
	optimize_lineup()
	optimize_rotation()

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
	# Set lineups
	current_game_defense_order = defense_order.duplicate()
	current_game_defense_order[0] = rotation[rotation_next_starter_index]
	rotation_next_starter_index = (rotation_next_starter_index + 1
		) % len(rotation)
	current_game_batting_order = batting_order.duplicate()
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

func fix_roster() -> void:
	# Make sure rotation, batting order, defense are set
	#rotation = [roster[0].player_id, '', '', '', '']
	pass

func optimize_rotation() -> void:
	roster.sort_custom(rotation_sort)
	rotation = []
	for i in range(min(5, len(roster))):
		rotation.push_back(roster[i].player_id)
	while len(rotation) < 5:
		rotation.push_back('')

func rotation_sort(p1:Player, p2:Player) -> bool:
	# If one is pitcher and other isn't, put pitcher first
	if p1.is_pitcher() and not p2.is_pitcher():
		return true
	if not p1.is_pitcher() and p2.is_pitcher():
		return false
	# If one is SP and other isn't (is RP), put SP first
	if p1.pos == 'SP' and p2.pos != 'SP':
		return true
	if p1.pos != 'SP' and p2.pos == 'SP':
		return false
	# Both are same position
	#return p1.pitching > p2.pitching
	return p1.speed > p2.speed

func optimize_lineup() -> void:
	# Copy roster
	#printt('roster is', roster)
	var r:Array = roster.map(func(p):return p)
	#printt('r is set to be', r)
	var pos_order:Array[String] = [
		'C', 'SS', 'CF',
		'2B', '3B', 'RF',
		'LF', '1B', 'DH'
	]
	var pos_index:Array[int] = [
		1,5,7,
		3,4,8,
		6,2,9
	]
	# Set of players in lineup, to be ordered later
	var lineup_set:Array[Player] = []
	defense_order = ['','','','','','','','','','']
	for i in range(len(pos_order)):
		var pos:String = pos_order[i]
		var pos_ind:int = pos_index[i]
		if len(r) == 0:
			push_error("No one left on roster in optimize_lineup")
			break
		r.sort_custom(func(a,b):return lineup_sort(a,b,pos))
		# Remove player from roster so that they don't get selected again
		#printt('r before pop', r)
		var p:Player = r.pop_front()
		#printt('r after pop', r, p)
		lineup_set.push_back(p)
		#put in defense
		defense_order[pos_ind] = p.player_id
	# Sort by hitting to get batting order
	lineup_set.sort_custom(func(a,b):return a.speed > b.speed)
	batting_order = []
	for i in range(len(lineup_set)):
		batting_order.push_back(lineup_set[i].player_id)

func lineup_sort(p1:Player, p2:Player, pos:String) -> bool:
	# If DH, ignore defense
	if pos == 'DH':
		return p1.contact > p2.contact
	# Prefer matching position
	if p1.pos == pos and p2.pos != pos:
		return true
	if p1.pos != pos and p2.pos == pos:
		return false
	# Matching position, so pick best
	return p1.overall > p2.overall

func add_player(player:Player) -> void:
	roster.push_back(player)
	rosterdict[player.player_id] = player
