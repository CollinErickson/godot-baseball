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
	gc.columns = 1 + data.innings + 1
	var child_copy = gc.get_child(0).duplicate()
	
	# Delete all existing children to avoid duplicating
	while gc.get_child_count() > 0:
		gc.remove_child(gc.get_child(0))

	# Row 1: inning count
	gc.add_child(dup_label(child_copy, ''))
	#gc.get_child(0).text = ''
	for i in range(data.innings):
		gc.add_child(dup_label(child_copy, i+1))
	gc.add_child(dup_label(child_copy, "R"))

	# Row 2: Away team
	gc.add_child(dup_label(child_copy, data.away_team.city_name + " " +
		data.away_team.team_name))
	# Runs by inning
	for i in range(data.innings):
		gc.add_child(dup_label(child_copy, data.away_score_by_inning[i]))
	# Summary
	gc.add_child(dup_label(child_copy, data.away_runs))
	
	# Row 3: Home team
	gc.add_child(dup_label(child_copy, data.home_team.city_name + " " +
		data.home_team.team_name))
	# Runs by inning
	for i in range(data.innings):
		gc.add_child(dup_label(child_copy, data.home_score_by_inning[i]))
	# Summary
	gc.add_child(dup_label(child_copy, data.home_runs))

func dup_label(node:Node, text):
	var x = node.duplicate()
	x.text = str(text)
	return x
