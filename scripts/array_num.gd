extends Object
class_name ArrayNum

var _x:Array = []

func init(x:Array):
	# Example: ArrayNum.new().init([1,3,5,6])
	_x = x
	return self

func _to_string() -> String:
	return '<ArrayNum with length ' + str(len(_x)) + '>'

func max():
	var maxval = null
	for i in range(len(_x)):
		if maxval == null or _x[i] > maxval:
			maxval = _x[i]
	return maxval

func min():
	var minval = null
	for i in range(len(_x)):
		if minval == null or _x[i] < minval:
			minval = _x[i]
	return minval
