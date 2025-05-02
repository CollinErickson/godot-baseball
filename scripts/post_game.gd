extends Control

var this_is_root:bool = false
var start_active:bool = false

func _ready() -> void:
	if get_tree().root == get_parent():
		this_is_root = true
		start_active = true
		set_values({
			'home_team':'Real Bros',
			'away_team':'Simi Valley',
			'innings':8,
			'away_score_by_inning':[0,1,2,3,0,1,2,3],
			'home_score_by_inning':[1,2,1,2,3,4,3,4]
		})

#func _process(delta: float) -> void:
	#pass

func set_values(data):
	var gc = $VBoxContainer/GridContainer
	gc.columns = 1 + data.innings
	var child_copy = gc.get_child(0).duplicate()
	
	# Delete all existing children to avoid duplicating
	gc.get_child(10)
	printt('tenth child', gc.get_child(10))
	while gc.get_child(0) != null:
		gc.remove_child(gc.get_child(0))

	# Row 1: inning count
	gc.add_child(dup_label(child_copy, ''))
	#gc.get_child(0).text = ''
	for i in range(data.innings):
		gc.add_child(dup_label(child_copy, i+1))

	# Row 2: Away team
	gc.add_child(dup_label(child_copy, data.away_team))
	for i in range(data.innings):
		gc.add_child(dup_label(child_copy, data.away_score_by_inning[i]))
	
	# Row 3: Home team
	gc.add_child(dup_label(child_copy, data.home_team))
	for i in range(data.innings):
		gc.add_child(dup_label(child_copy, data.home_score_by_inning[i]))

func dup_label(node:Node, text):
	var x = node.duplicate()
	x.text = str(text)
	return x
