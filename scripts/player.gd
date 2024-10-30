extends Node
class_name Player

var first:String
var last:String
var speed:float
var throwspeed:float

func setup(first_:String, last_:String, speed_:float, throwspeed_:float):
	first = first_
	last = last_
	speed = speed_
	throwspeed = throwspeed_
	return self

func print_():
	print('Player object:')
	print('\tName: ', first, ' ', last)
	print('\tSpeed: ', speed)
