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
