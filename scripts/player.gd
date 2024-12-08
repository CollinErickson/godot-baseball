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

# Skills
var speed:float
var throwspeed:float
var contact:float
var power:float
var pitching:float

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
	contact = 0.
	power = 0.
	pitching = 0.
	
	skin_color = skin_colors.pick_random()
	
	return self

func print_():
	print('Player object:')
	print('\tName: ', first, ' ', last)
	print('\tSpeed: ', speed)

func create_random(speed_:float=randi_range(20,80)):
	var f = ["Nick", "Britt", "Greg", "Troy"]
	var l = ["Farinacci", "Fugett", "Ferrara", 'Vergara']
	setup(f.pick_random(), l.pick_random(), speed_, 39.,
		["R","L"].pick_random(), 
		["R","L"].pick_random())
	#p.print_()
	return self

func speed_mps() -> float:
	var SPEED = max(1e-8, speed / 10. + 3)
	return SPEED

func throwspeed_mps() -> float:
	var throwspeed_mps_ = 40
	return throwspeed_mps_
	
var skin_colors = [Color(.79,.46,.42), Color(.24,.14,.08)]
