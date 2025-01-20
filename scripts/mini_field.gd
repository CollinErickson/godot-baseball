extends Node2D

var mini_scale:float = 1

func _ready() -> void:
	for posname in ['C', '1B', '2B', '3B', 'SS', 'LF', 'CF', 'RF', 'P']:
		add_child_with_name("Fielder" + posname, Color(1,0,0))
	for r in ['1B', '2B', '3B', 'Home']:
		add_child_with_name("Runner3D" + r, Color(0,0,1))
	
	$Base1B.position = Vector2(30/sqrt(2), -30/sqrt(2))
	$Base2B.position = Vector2(0, -30*sqrt(2))
	$Base3B.position = Vector2(-30/sqrt(2), -30/sqrt(2))

func add_child_with_name(name_:String, col:Color) -> void:
	var y = Sprite2D.new()
	var rect = load("res://white_rectangle_rounded_8_8.png")
	y.set_texture(rect)
	y.modulate = col
	y.name = name_
	add_child(y)

func convert_position(pos:Vector3) -> Vector2:
	var p = Vector2(pos.x, pos.z)
	p.x *= -1
	p.y *= -1
	return p

func update_position(node, pos:Vector3) -> void:
	if node == null:
		printt("in minifield update_position", node, pos)
		assert(false)
	var pos2 = convert_position(pos)
	node.position = pos2
