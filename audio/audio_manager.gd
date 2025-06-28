extends Node

const BAT_HIT_SOUND: AudioStream = preload("res://audio/sounds/thud1.wav")
var commentator_json:Dictionary

func _ready() -> void:
	printt('in audio_manager running ready')
	load_commentator()
	
	# Test commentator
	play_commentator_post_play({
		'strike':true,
		'ball':false,
		'strikeout':false,
		'walk':false,
		'home_run':false,
		'swing_miss':false,
		'hit':false,
	})
	
	play_sound("thud1")

func play_sound(_name:String) -> void:
	var x:AudioStreamPlayer = AudioStreamPlayer.new()
	x.stream = BAT_HIT_SOUND
	add_child(x)
	printt('playing thud')
	
	x.finished.connect(x.queue_free)
	x.play()
	#await x.finished
	#remove_child(x)
	#x.queue_free()


func play_sound_from_path(path:String) -> void:
	var x:AudioStreamPlayer = AudioStreamPlayer.new()
	
	var SOUND: AudioStream = load(path)
	x.stream = SOUND
	add_child(x)
	printt('playing something')
	
	x.finished.connect(x.queue_free)
	x.play()

func load_commentator() -> void:
	commentator_json = \
		read_csv("res://audio/sounds/commentator/commentator.csv")
	
	#printt("commentator_json before", commentator_json)
	json_filter_out(commentator_json, "file", null)
	#printt("commentator_json after", commentator_json)

func read_csv(path:String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	#var content = file.get_as_text() # Gets whole file as text
	printt('file is', file)
	#printt('content is', content)
	var types:Array = file.get_csv_line()
	print('types', types)
	var colnames:Array = file.get_csv_line()
	printt('colnames', colnames)
	var x:Dictionary = {}
	#printt(file.get_csv_line())
	#return content
	# Create empty array for each col
	for c in colnames:
		x[c] = []
	
	# Read all rows
	for iii in range(20000):
		if file.eof_reached():
			break
		var row:Array = file.get_csv_line()
		printt('iii is', iii, row)
		#if len(row) == 1 and row[0] == "":
			#printt('breaking on iii', iii, row)
			#break
		# Loop over each column in the row
		for i in range(len(row)):
			if row[i] == "":
				x[colnames[i]].push_back(null)
			elif types[i] == "String":
				x[colnames[i]].push_back(row[i])
			elif types[i] == "int":
				x[colnames[i]].push_back(int(row[i]))
			else:
				push_error("Error in read csv ", types[i])
	#print('read csv x is', x)
	return x

func json_filter_out(x:Dictionary, colname:String, value) -> void:
	# x is dictionary from json in column form with column colname
	# value is the value to filter out from all rows when found in colname
	var ks:Array = x.keys()
	var remove_inds:Array = []
	for i in range(len(x[colname])):
		if x[colname][i] == value:
			remove_inds.push_back(i)
	remove_inds.reverse()
	for k in ks:
		for i in remove_inds:
			x[k].remove_at(i)

func json_filter_in(x:Dictionary, colname:String, value) -> void:
	# x is dictionary from json in column form with column colname
	# value is the value to filter for from all rows when found in colname
	var ks:Array = x.keys()
	var remove_inds:Array = []
	for i in range(len(x[colname])):
		if x[colname][i] != value:
			remove_inds.push_back(i)
	remove_inds.reverse()
	for k in ks:
		for i in remove_inds:
			x[k].remove_at(i)

func play_commentator_post_play(x:Dictionary) -> void:
	#commentator_json.duplicate()
	# valid has the index if valid, -1 if invalid
	var valid:Array = range(len(commentator_json['text']))
	var points:Array = rep(0, len(commentator_json['text']))
	#printt('valid after creating is', valid)
	#printt('commentator_json is', commentator_json)
	#printt('commentator_json keys are', commentator_json.keys())
	# x is dictionary with play results
	for k in x.keys():
		assert(k in commentator_json.keys(), k)
		assert(x[k] is bool)
		for i in range(len(commentator_json[k])):
			#printt('checking', k, i, x[k], commentator_json[k])
			# Disallowed event happened, so invalid
			if x[k] and commentator_json[k][i] != null \
			and commentator_json[k][i] < -0.5:
				valid[i] = -1
			# Requisite event didn't happen, so invalid
			if !x[k] and commentator_json[k][i] != null \
			and commentator_json[k][i] > 0.5:
				valid[i] = -1
			# Requisite event did happen, add points
			if x[k] and commentator_json[k][i] != null \
			and commentator_json[k][i] > 0.5 and \
			k in points_dict.keys():
				points[i] += 1. / points_dict[k]
			if k not in points_dict.keys():
				push_warning("key not found in points_dict ", k)
	printt('text is', commentator_json['text'])
	printt('valid after key loop is', valid)
	printt('points after key loop is', points)
	points = array_index_bool(points, valid.map(func(xx):return xx>-0.5))
	printt('points after filter valid', points)
	valid = valid.filter(func(xx): return xx > -0.5)
	printt('valid after filter is', valid)
	assert(len(points) == len(valid))
	var i:int = which_max(points)
	var best_ind:int = valid[i]
	var max_points = array_max(points)
	var all_max:Array = []
	for k in range(len(points)):
		if points[k] >= max_points:
			all_max.push_back(valid[k])
	best_ind = all_max.pick_random()
	# Skip if most points is 0? No, some generic statements always get 0
	# TODO: pick among all the best
	printt('best ind is', i, best_ind)
	printt('commentator line is:', commentator_json['text'][best_ind])
	var path:String = "res://audio/sounds/commentator/" + \
		commentator_json['file'][best_ind] + ".wav"
	printt('path for commentator sound is', path)
	play_sound_from_path(path)

# Points are based on how frequent the event occurs
# Roughly how many times it happens per team in a regular game
# The inverse will be used
var points_dict:Dictionary = {
	strike=50,
	ball=40,
	walk=6,
	strikeout=10,
	swing=50,
	swing_miss=15,
	hit=8,
	home_run=2,
	end_half_inning=9,
	end_game=1,
	runs_on_play_0=30,
	runs_on_play_1=4,
	runs_on_play_2=1,
	runs_on_play_3=.4,
	runs_on_play_4=.05,
	outs_on_play_0=10,
	outs_on_play_1=25,
	outs_on_play_2=2,
	outs_on_play_3=.01,
}

func rep(x, n:int) -> Array:
	var out:Array = range(n)
	for i in range(n):
		out[i] = x
	return out

func which_min(x:Array) -> int:
	var min_val = null
	var min_ind:int = -1
	for i in range(len(x)):
		if min_val == null or x[i] < min_val:
			min_val = x[i]
			min_ind = i
	assert(min_ind > -0.5)
	return min_ind

func which_max(x:Array) -> int:
	return which_min(x.map(func(xx):return -xx))

func array_index_bool(x:Array, y:Array) -> Array:
	print('in array_index_bool', x, y)
	var z:Array = []
	assert(len(x) == len(y))
	for i in range(len(x)):
		if y[i]:
			z.push_back(x[i])
	return z

func array_max(x:Array):
	return x[which_max(x)]
