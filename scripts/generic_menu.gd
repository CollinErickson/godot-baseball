extends Control

var is_active:bool = false
var left_indent:float = 300

@export_group("Generic menu")
@export var start_active:bool = false
@export var menu_title:String = "(title)"
@export var options:Array[String] = []
@export var background_color:Color = "pink"
@export var text_color:Color = "black"
@export var fill_color:Color = "yellow"
@export var hover_color:Color = "green"
@export var shadow_color:Color = "brown"
@export var hover_shadow_color:Color = "red"
@export var hover_text_color:Color = 'gray'
var index_selected:int = 0
signal return_index_selected

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$BackgroundRect.color = background_color
	$HeaderRect/Label.text = menu_title
	$HeaderRect/Label.set("theme_override_colors/font_color", text_color)
	$HeaderRect/Label.set("theme_override_font_sizes/font_size", 100)
	$HeaderRect.position = Vector2(left_indent, 50)
	$HeaderRect.size = Vector2(850, 120)
	$HeaderRect.color = fill_color
	#var b = Button.new()
	#add_child(b)
	for i in range(len(options)):
		var option = options[i]
		# Outer box, for now is a shadow
		var c2 = ColorRect.new()
		c2.position = Vector2(left_indent, 250 + 100*i)
		c2.size = Vector2(560,77)
		c2.color = shadow_color
		# Inner box
		var c = ColorRect.new()
		c.color = fill_color
		c.size = Vector2(550,70)
		# Label
		var l = Label.new()
		l.text = "  " + option
		l.set("theme_override_colors/font_color", text_color)
		l.set("theme_override_font_sizes/font_size", 50)
		c.add_child(l)
		c2.add_child(c)
		add_child(c2)
		#$MenuTitleHBox.add_child(h)
		set_hover(0)
	
	set_active(start_active)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#printt('in generic menu, is active', is_active)
	if not is_active:
		return
	if Input.is_action_just_pressed("movedown"):
		unset_hover(index_selected)
		index_selected += 1
		if index_selected >= len(options):
			index_selected = 0
		set_hover(index_selected)
	if Input.is_action_just_pressed("moveup"):
		unset_hover(index_selected)
		index_selected -= 1
		if index_selected < 0:
			index_selected = len(options)-1
		set_hover(index_selected)
	if Input.is_action_just_pressed("ui_accept"):
		printt('In generic_menu.gd: option selected', index_selected)
		return_index_selected.emit(index_selected)
		set_active(false)
		return

func set_hover(index) -> void:
	#printt('setting hover on index', index)
	var gc = get_children()
	var x = gc[2 + index]
	x.color = hover_shadow_color
	x.get_child(0).color = hover_color

func unset_hover(index) -> void:
	var gc = get_children()
	var x = gc[2 + index]
	x.color = shadow_color
	x.get_child(0).color = fill_color

#func return_selected_index() -> int:
	#return index_selected

func set_active(is_active_:bool):
	is_active = is_active_
	set_process(is_active_)
	visible = is_active_
