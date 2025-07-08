extends Node
class_name Player

# Info
var first:String
var last:String
var age:int
var bats:String
var throws:String
var pos:String
var skin_color:Color = Color("green")
var height_mult:float # 1 is average. Scales all dimensions of body

# Skills
var speed:float
var throwspeed:float
var throwaccuracy:float
var catching:float
var contact:float
var power:float
var pitching:float
var pitchspeed:float
var pitching_stamina:float
var current_game_pitching_stamina:float

var serialize_map:Array = [
	['f', 'first', 's'],
	['l', 'last', 's'],
	['a', 'age', 'i'],
	['b', 'bats', 's'],
	['t', 'throws', 's'],
	['sk', 'skin_color', 'color'],
	['hm', 'height_mult', 'f'],
	['s', 'speed', 'f'],
	['ts', 'throwspeed', 'f'],
	['ta', 'throwaccuracy', 'f'],
	['c', 'catching', 'f'],
	['co', 'contact', 'f'],
	['p', 'power', 'f'],
	['pi', 'pitching', 'f'],
	['ps', 'pitchspeed', 'f'],
	['st', 'pitching_stamina', 'f'],
	#['', '']
]

func _ready() -> void:
	# If this is root, debugging/testing
	if get_tree().root == get_parent():
		printt('in player as root')
		create_random()
		var s:String = FileUtils.serialize(self, serialize_map)
		printt('serialized:', s)
		print_()
		first = 'Hober'
		print_()
		FileUtils.deserialize(self, s, serialize_map)
		print_()

func setup(first_:String, last_:String, speed_:float, throwspeed_:float,
			bats_:String, throws_:String):
	first = first_
	last = last_
	assert(bats_ in ["L", "R", "S"])
	bats = bats_
	assert(throws_ in ["L", "R"])
	throws = throws_
	pos = "?"
	
	speed = speed_
	throwspeed = throwspeed_
	pitchspeed = 0
	contact = 0.
	power = 0.
	pitching = 0.
	throwaccuracy = round(randf_range(40, 100))*1.
	pitching_stamina = round(randf_range(40, 100))*1./20
	catching = round(randf_range(40, 100))*1./20
	current_game_pitching_stamina = pitching_stamina
	
	skin_color = skin_colors.pick_random()
	height_mult = randfn(1,.1)
	
	return self

func print_():
	print('Player object:')
	print('\tName: ', first, ' ', last)
	print('\tSpeed: ', speed)

func create_random(speed_:float=randi_range(20,80)):
	var f = ["Alan", "Alfonso", "Britt", "Greg", "Ollie", "Nick", "Pasqual", "Troy"]
	var l = ["Bennett", "Caraccioli", "Farinacci", "Fugett", "Ferrara", "Hayden", "Vergara"]
	setup(f.pick_random(), l.pick_random(), speed_, 39.,
		["R","L"].pick_random(), 
		["R","L"].pick_random())
	#p.print_()
	return self

func speed_yps() -> float:
	var SPEED = max(1e-8, speed / 10. + 3)
	return SPEED

func throwspeed_yps() -> float:
	# Yards per second
	var throwspeed_yps_ = 40
	return throwspeed_yps_

func pitchspeed_yps() -> float:
	# Yards per second
	var pitchspeed_yps_ = 40
	return pitchspeed_yps_
	
var skin_colors = [Color( .79, .46, .42),
					Color(.24, .14, .08),
					Color(.88, .61, .57),
					Color(.94, .72, .74),
					Color(.58, .30, .27),
					Color(.39, .26, .16),
				]

func update_pitcher_stamina() -> void:
	#printt('in player update_pitcher_stamina before:', first, last, current_game_pitching_stamina)
	current_game_pitching_stamina = max(0,
										current_game_pitching_stamina - 3)
	#printt('in player update_pitcher_stamina after:', first, last, current_game_pitching_stamina)

func height() -> float:
	# Return player height in yards
	return 1.7 * height_mult

func strike_zone_top() -> float:
	# Return height of the top of the strike zone in yards
	return .58 * height()
	
func strike_zone_bottom() -> float:
	# Return height of the top of the strike zone in yards
	return .22 * height()
