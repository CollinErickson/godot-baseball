extends Object
class_name DF

var _data:Dictionary = {}

func init(d:Dictionary) -> DF:
	# Check that all columns have the same length
	var ks:Array = d.keys()
	if len(ks) >= 2:
		# Check length of one col
		var l:int = len(d[ks[0]])
		# Make sure that all match that
		for i in range(1, len(ks)):
			if len(d[ks[1]]) != l:
				push_error("Bad lengths in DF init", d)
	
	_data = d
	return self
