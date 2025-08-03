extends navigable_page
class_name NavPlayer

var player:Player

func _ready() -> void:
	page_id = 'NavPlayer'
	
	parent_ready()

func handle_nav_button_click(id:String, _args:Dictionary={}) -> void:
	match id:
		'back':
			pass

func setup(args:Dictionary={}) -> void:
	if this_is_root:
		args['player'] = Player.new().create_random()
	player = args['player']
	
	var gc:GridContainer = $This/VBoxContainer/GridContainer
	gc.get_node('NameR').text = player.first + " " + player.last
	gc.get_node('PosR').text = player.pos
