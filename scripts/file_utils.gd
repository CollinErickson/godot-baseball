extends Node

func read_json(path:String):
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	printt('file is', file)
	printt('content is', content)
	#return content
	
	var json_string = content
	## Retrieve data
	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK:
		var data_received = json.data
		if typeof(data_received) == TYPE_ARRAY:
			printt('data array is', len(data_received), data_received) # Prints the array.
			printt('element one', data_received[0], data_received[0]['name'])
			return data_received
		else:
			print("Unexpected data")
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())

func json_rows_to_cols(x:Array) -> Dictionary:
	#printt('in nav select team json_rows_to_cols', x)
	var y:Dictionary = {}
	for i in range(len(x)):
		var xi:Dictionary = x[i]
		for key in xi.keys():
			if i == 0:
				y[key] = [xi[key]]
			else:
				y[key].push_back(xi[key])
	return y

func json_cols_to_rows(x:Dictionary) -> Array:
	#printt('in nav select team json_cols_to_rows', x)
	var y:Array = []
	var ks:Array = x.keys()
	for i in range(len(x[ks[0]])):
		var yi:Dictionary = {}
		for k in ks:
			yi[k] = x[k][i]
		y.push_back(yi)
	return y

func read_csv(path:String, _has_col_types:bool=true) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	#var content = file.get_as_text() # Gets whole file as text
	#printt('file is', file)
	#printt('content is', content)
	var types:Array = file.get_csv_line()
	#print('types', types)
	var colnames:Array = file.get_csv_line()
	#printt('colnames', colnames)
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
		#printt('iii is', iii, row)
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
				push_error("Error in read csv, bad col type:", types[i])
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

func dict_to_JSON_string(x:Dictionary) -> String:
	return JSON.stringify(x)

func JSON_string_to_dict(s:String) -> Dictionary:
	return JSON.parse_string(s)

func serialize(obj, s_map_=null) -> String:
	if s_map_ == null:
		s_map_ = obj.serialize_map
	var s_map:Array = s_map_
	var d:Dictionary = {}
	for row in s_map:
		d[row[0]] = obj.get(row[1])
		# Modify complicated objects
		if row[2] == 'color':
			var c:Color = d[row[0]]
			d[row[0]] = str(c.r) + ',' + str(c.g) + ',' + str(c.b) + ',' +\
				str(c.a)
		if row[2] in ['a_i', 'a_f', 'a_i']:
			# Array of basic type
			#print('ser a_i', d[row[0]], JSON.stringify(d[row[0]]))
			d[row[0]] = JSON.stringify(d[row[0]])
		if row[2] == 'a_player':
			printt('in fu ser a_p')
			# Array of player objects
			var a:Array[String] = []
			for p in d[row[0]]:
				#printt('p is', p)
				#printt('serialized is', FileUtils.serialize(p))
				a.push_back(FileUtils.serialize(p))
			d[row[0]] = JSON.stringify(a)
			
	var s:String = dict_to_JSON_string(d)
	printt('in fileutils serialize s at end is:', s)
	return s

func deserialize(obj, s:String, s_map_=null) -> void:
	if s_map_ == null:
		s_map_ = obj.serialize_map
	var s_map:Array = s_map_
	var d:Dictionary = JSON_string_to_dict(s)
	printt('in file util deserialize, d:', d)
	for row in s_map:
		if row[2] == 'color':
			var c:String = d[row[0]]
			var c2:Array = c.split(',')
			if len(c2) == 4:
				var col:Color = Color(float(c2[0]), float(c2[1]),
					float(c2[2]), float(c2[3]))
				obj.set(row[1], col)
			else:
				# Push error, skip it
				push_error("Unable to deserialize color", c, c2)
		elif row[2] in ['a_i', 'a_f', 'a_s']:
			#printt('deser a_i', row, d[row[0]], JSON.parse_string(d[row[0]]))
			var x:Array = JSON.parse_string(d[row[0]])
			obj.set(row[1], x)
		elif row[2] == 'a_player':
			var x:Array = JSON.parse_string(d[row[0]])
			# Deserialize each element
			var p:Array[Player] = []
			for y in x:
				var pl:Player = Player.new()
				FileUtils.deserialize(pl, y)
				p.push_back(pl)
			obj.set(row[1], p)
		else:
			assert(row[2] in ['s', 'i', 'f'])
			# String, int, float
			obj.set(row[1], d[row[0]])
