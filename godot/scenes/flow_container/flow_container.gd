tool
extends Container

# The flow container will fit as many children in a row as it can
# using their minimum size, and will then continue on the next row.
# Does not use SIZE_EXPAND flags of children.
# TODO: half-respect vertical SIZE_EXPAND flags by expanding the child to match
#       the tallest child in that row?


# Used to make our parent re-evaluate our size when we have to create more or
# less rows to fit in all the children.
var _reported_height_at_last_minimum_size_call := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _get_minimum_size() -> Vector2:
	print("re-evaluated")
	# Our minimum width is the width of the widest child.
	var max_requested_width := 0
	for child in get_children():
		# Check if the child is actually a `Control`.
		if not child.has_method("get_combined_minimum_size"):
			break
		
		var requested_size: Vector2 = child.get_combined_minimum_size()
		if requested_size.x > max_requested_width:
			max_requested_width = requested_size.x
	
	# Calculate how hight we have to be given our current width.
	var height := _calculate_layout(false)
	_reported_height_at_last_minimum_size_call = height
	
	return Vector2(max_requested_width, height)


func _notification(what):
	if (what==NOTIFICATION_SORT_CHILDREN):
		# Must re-sort the children.
		var height = _calculate_layout(true)
		
		if height != _reported_height_at_last_minimum_size_call:
			# We are either smaller or larger than we thought we would
			# be, last time we menitioned it.
			# Have our parent re-evaluate our size.
			# TODO: Maybe find a better way instead of briefly 
			#       exceeding our reported minimum size.
			rect_min_size = Vector2(0, 20000)
			rect_min_size = Vector2(0, 0)


# If apply is true, the children will actually be moved to the calculated
# locations.
# Returns the resulting height.
func _calculate_layout(apply: bool) -> float:
	var next_location: Vector2 = Vector2(0, 0)
	var row_height: int = 0
	
	for child in get_children():
		# Check if the child is actually a `Control`.
		if not child.has_method("get_combined_minimum_size"):
			continue
		
		var requested_size: Vector2 = child.get_combined_minimum_size()
		# Would this control fit on this row?
		if requested_size.x + next_location.x > rect_size.x:
			# No it would not. Go to the next row.
			next_location = Vector2(0, next_location.y + row_height)
			row_height = 0
		
		fit_child_in_rect(child, Rect2(next_location, requested_size))
		
		if requested_size.y > row_height:
			row_height = requested_size.y
		next_location.x += requested_size.x
	
	return next_location.y + row_height
