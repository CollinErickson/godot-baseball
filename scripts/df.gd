extends Object
class_name DF

var d:Dictionary = {}

func init(d_:Dictionary) -> DF:
	# Check that all columns have the same length
	var ks:Array = d_.keys()
	if len(ks) >= 2:
		# Check length of one col
		var l:int = len(d_[ks[0]])
		# Make sure that all match that
		for i in range(1, len(ks)):
			if len(d_[ks[i]]) != l:
				push_error("Bad lengths in DF init", l, ks[i], len(d_[ks[i]]))
	
	d = d_
	#printt('in df, created df,', nrows(), ncols(), d.keys())
	return self

#func init_from_

func nrows() -> int:
	return len(d[d.keys()[0]])

func ncols() -> int:
	return len(d.keys())

func filter_bool(tf:Array) -> void:
	assert(len(tf) == nrows())
	
	var remove_inds:Array = []
	for i in range(nrows()):
		if !tf[i]:
			remove_inds.push_back(i)
	remove_inds.reverse()
	for k in d.keys():
		for i in remove_inds:
			d[k].remove_at(i)

func filter_val(col:String, val) -> void:
	assert(col in d.keys())
	
	var tf:Array = []
	for i in range(nrows()):
		tf.push_back(d[col][i] == val)
	
	filter_bool(tf)

func filter_val_exclude(col:String, val) -> void:
	assert(col in d.keys())
	
	var tf:Array = []
	for i in range(nrows()):
		tf.push_back(d[col][i] != val)
	
	filter_bool(tf)

func filter_bool_copy(tf:Array) -> DF:
	assert(len(tf) == nrows())
	
	assert(len(tf) == nrows())
	
	var new_d:Dictionary = {}
	
	for k in d.keys():
		new_d[k] = []
	
	for i in range(nrows()):
		if tf[i]:
			for k in d.keys():
				new_d[k].push_back(d[k][i])
	
	var new_DF:DF = DF.new().init(new_d)
	return new_DF

func filter_val_copy(col:String, val) -> DF:
	printt('filter_val_copy', col, val, d.keys())
	assert(col in d.keys())
	
	var tf:Array = []
	
	for i in range(nrows()):
		tf.push_back(d[col][i] == val)
	
	return filter_bool_copy(tf)

func copy() -> DF:
	var new_d:Dictionary = {}
	
	for k in d.keys():
		new_d[k] = []
	
	for i in range(nrows()):
		for k in d.keys():
			new_d[k].push_back(d[k][i])
	
	return DF.new().init(new_d)

func head(n:int) -> DF:
	if nrows() < n:
		return copy()
	
	var tf:Array = []
	for i in range(nrows()):
		tf.push_back(i < n)
	
	return filter_bool_copy(tf)

func get_row(i:int) -> DF:
	assert(i >= 0 and i < nrows())
	var tf:Array = []
	for j in range(nrows()):
		tf.push_back(j == i)
	return filter_bool_copy(tf)

func print_(n:int = -1, prefix:String='') -> void:
	#var pdf:DF = self
	#if n >= 0:
		#pdf = head(n)
	
	var s1:String = ''
	if prefix != "":
		s1 = prefix + " - "
	s1 += "DF with " + str(nrows()) + " rows and " + str(ncols()) +  " cols:"
	print(s1)
	
	if n < 0:
		# Default to 5
		n = 5
	n = min(n, nrows())
	for k in d.keys():
		var s:String = "\t" + k + ": "
		for j in range(n):
			s += str(d[k][j])
			if j < n - 1:
				s += ", "
		print(s)
