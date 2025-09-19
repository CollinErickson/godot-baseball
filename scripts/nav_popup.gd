extends navigable_page
class_name NavPopup

var franchise:Franchise
@onready var label:Label = \
	$This/PanelContainer/MarginContainer/VBoxContainer/Label
@onready var vbox:VBoxContainer = \
	$This/PanelContainer/MarginContainer/VBoxContainer

func _ready() -> void:
	page_id = 'NavPopup'
	
	parent_ready()

func handle_nav_button_click(id:String, _args:Dictionary={}) -> void:
	cleanup()
	nav_up({'result':int(id)})

func setup(args:Dictionary={}) -> void:
	if this_is_root:
		args['options'] = [
			'Accept',
			'Back'
		]
		args['label'] = 'This is a popup'
	
	if args.has('label'):
		label.text = args['label']
	else:
		label.text = ''
	
	assert(args.has('options'))
	var options:Array = args['options']
	for i in range(len(options)):
		var option:String = options[i]
		var nb:navigable_button = navigable_button_scene.instantiate()
		nb.setup(
			option, # text
			'NavPopup', # page id
			str(i), # id
			i, # row
			0, # col
		)
		nb.add_to_group('navbutton_popup')
		vbox.add_child(nb)

func cleanup() -> void:
	for node in get_tree().get_nodes_in_group('navbutton_popup'):
		node.remove_from_group('navigable_button')
		node.queue_free()
