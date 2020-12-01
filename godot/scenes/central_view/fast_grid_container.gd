extends Container

# Only ever has just enough children to fill the space allocated to the container.
# And scrolls the content over the children,
# instead of scrolling the children themselves.

# Is definately faster than updating a long list of children with new assets
# every time a search completes. And then removing all of the children when
# there are only a few assets to display.

# TODO: Implement cell selecting and deselecting and such.
# TODO: and implement scrolling with the mouse wheel.
# TODO: And implement going though the assets with the arrow keys.

signal textures_requested(asset_ids)

# Child scene should have a constant minimum size.
# Otherwise the layout messes up.
var _child_scene := preload("./asset_cell/asset_cell.tscn")
var _child_min_size := Vector2()

# How many columns and rows we can currently fit in the size.
var _current_columns: int = 1
var _current_rows: int = 1

# Assets that we want to display.
var _asset_nodes := []

onready var _scroll_bar := VScrollBar.new()
# Parent for all the grid children, so things like the scrollbar don't
# interfere.
onready var _grid_parent := Container.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	rect_clip_content = true
	
	add_child(_scroll_bar)
	add_child(_grid_parent)
	
	_scroll_bar.connect("scrolling", self, "_on_scrolled")
	
	# Add the first child, so we know their minimal size.
	var first_child := _child_scene.instance()
	_grid_parent.add_child(first_child)
	_child_min_size = first_child.get_combined_minimum_size()


func display_assets(asset_nodes: Array):
	_asset_nodes = asset_nodes
	# New assets, so scroll all the way up.
	_scroll_bar.value = 0
	
	_update_scrollbar_dimensions()
	_update_grid_child_positions()
	_update_shown_assets()


func texture_ready(asset_id: String, texture: ImageTexture):
	var child := _grid_parent.get_node_or_null(asset_id)
	if child != null:
		child.display_texture(texture)


func _on_scrolled():
	_update_grid_child_positions()
	_update_shown_assets()


# Makes sure the right grid cells display the right assets.
func _update_shown_assets():
	# The value might not be an exact integer.
	# We round down to the nearest one, so the rows are consistent.
	# And elsewhere we can use the fractional value to determine how far behind 
	# the top border the top row should be.
	var top_row := floor(_scroll_bar.value)
	var first_asset_idx := top_row * _current_columns
	var last_asset_idx := first_asset_idx + _current_columns * _current_rows
	
	var texture_ids := []
	
	# First make sure the names do not overlap.
	for child in _grid_parent.get_children():
		child.name = "__"
	
	var asset_idx := int(first_asset_idx)
	for child in _grid_parent.get_children():
		if asset_idx < _asset_nodes.size():
			child.visible = true
			
			var asset: Node = _asset_nodes[asset_idx]
			child.display_asset_info(asset)
			# We can later set the texture via the node name.
			child.name = asset.name
			texture_ids.append(asset.name)
		else:
			# There is no asset for this child at the moment.
			child.visible = false
			child.clear()
		
		asset_idx += 1
	
	emit_signal("textures_requested", texture_ids)


func _update_scrollbar_dimensions():
	var scroll_factor := _scroll_bar.value / _scroll_bar.max_value
	
	var rows_to_fit_all_assets := max(ceil(_asset_nodes.size() / float(_current_columns)), 1)
	
	_scroll_bar.max_value = rows_to_fit_all_assets
	
	if rows_to_fit_all_assets >= _current_rows:
		# The scroll bar is 2 row higher than all the rows for the assets
		# because the last visible row can be clipped, and during scrolling,
		# the top row can be clipped as well. So the user needs to 
		# be able to scroll up one more to get those assets in full view.
		_scroll_bar.max_value += 2
	
	_scroll_bar.page = clamp(_current_rows, 1, rows_to_fit_all_assets)
	
	# Make sure we don't change how far down the scrollbar is, even
	# though we might have changed the max and the page values.
	_scroll_bar.value = lerp(0, rows_to_fit_all_assets, scroll_factor)


# Layout the children in a grid pattern.
# Use the fracional part of the scroll value to determine how far behind
# offset the top row should be.
func _update_grid_child_positions():
	var y_offset := fmod(_scroll_bar.value, 1) * _child_min_size.y
	
	for i in range(0, _grid_parent.get_child_count()):
		var x := (i % _current_columns) * _child_min_size.x
		var y := (i / _current_columns) * _child_min_size.y
		y -= y_offset
		_grid_parent.fit_child_in_rect(_grid_parent.get_child(i), Rect2(Vector2(x, y), _child_min_size))
	


# Makes sure the grid cells, and the scrollbar are in the right locations.
func _calculate_layout():
	var our_size := rect_size
	# Remember these so we update the scroll bar and grid view only when needed.
	var _last_columns := _current_columns
	var _last_rows := _current_rows
	
	# First make sure the scrollbar is in the right place.
	var bar_width: float = _scroll_bar.get_combined_minimum_size().x
	# Vertical bar goes on the right.
	fit_child_in_rect(_scroll_bar, Rect2(Vector2(our_size.x - bar_width, 0), 
		Vector2(bar_width, our_size.y)))
	
	# Adjust the space for the grid, because the scrollbar takes up space.
	our_size.x -= bar_width
	fit_child_in_rect(_grid_parent, Rect2(Vector2(0, 0), our_size))
	
	# Now make sure we have as many children as fit.
	_current_columns = floor(our_size.x / _child_min_size.x)
	# The last row is allowed to be clipped off, so `ceil` instead of `floor`.
	# The plus one is because when scrolling we can also clip the top row,
	# so we need 2 "extra" bottom rows in total.
	_current_rows = ceil(our_size.y / _child_min_size.y) + 1
	
	var required_children := _current_columns * _current_rows
	var current_count := _grid_parent.get_child_count()
	
	if current_count > required_children:
		# Remove superfluous children.
		for i in range(required_children, current_count):
			_grid_parent.get_child(i).queue_free()
	elif current_count < required_children:
		# Create missing children.
		for i in range(current_count, required_children):
			var new_child := _child_scene.instance()
			_grid_parent.add_child(new_child)
	
	_update_grid_child_positions()
	
	# See if anything changed that would necessitate updating the view
	# or scrollbar.
	if _last_columns != _current_columns or _last_rows != _current_rows:
		_update_scrollbar_dimensions()
		
		# Now make sure the assets are actually displayed correctly.
		_update_shown_assets()


func _notification(what):
	if (what==NOTIFICATION_SORT_CHILDREN):
		_calculate_layout()


func _get_minimum_size() -> Vector2:
	# Always fit at least 1 child.
	return _child_min_size


func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP or event.button_index == BUTTON_WHEEL_DOWN:
			# Scrolling input.
			# Pass through to scroll bar for consistent handling of the mouse
			# wheel.
			_scroll_bar._gui_input(event)
