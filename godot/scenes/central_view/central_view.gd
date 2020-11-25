extends VBoxContainer

# Emitted when we want to display a certain asset.
signal request_asset_texture(asset_id)

# Emitted when the user selects or deselects assets.
# Passes an array of selected id's.
signal selection_changed(asset_ids)


signal asset_search_requested(title_search)


var _asset_cell_scene: PackedScene = preload("./asset_cell/asset_cell.tscn")

# Keeps track of the last selected cell, for the purposes of multi-selection.
# `-1` means nothing has been selected yet.
var _last_selected_cell_index: int = -1

onready var _asset_grid: GridContainer = find_node("AssetGridContainer")
onready var _asset_search: PanelContainer = find_node("AssetSearch")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Clears the current assets in the grid, and displays the given ones.
func display_assets(asset_nodes: Array):
	# TODO: allow for sorting?
	
	# We will re-use any existing grid cells.
	var i := 0
	for child in _asset_grid.get_children():
		# Make sure existing cells are not using node names we need.
		child.name = "__"
		
		# Clear any selections.
		child.set_selected(false)
		
		if i >= len(asset_nodes):
			# These are no longer needed.
			child.queue_free()
		
		i += 1
	
	var existing_cell_count := _asset_grid.get_child_count()
	i = 0
	for node in asset_nodes:
		var cell: Node = null
		if i < existing_cell_count:
			# We can use an exisiting cell.
			cell = _asset_grid.get_child(i)
		else:
			# We have to use a new cell.
			cell = _asset_cell_scene.instance()
			_asset_grid.add_child(cell)
			# For handling selecting and deselecting cells.
			cell.connect("selection_input_recieved", self, "_on_cell_focused")
		
		cell.name = node.name
		cell.display_asset_info(node)
		
		# Request the texture. (this could take a while).
		emit_signal("request_asset_texture", node.name)
		
		i += 1
	
	_connect_grid_focus_chain()
	
	# Can't have selected anything if the cells were just created.
	_last_selected_cell_index = -1
	emit_signal("selection_changed", [])


func _connect_grid_focus_chain():
	# Protect against calling this function before we are correctly added
	# to the node tree.
	if _asset_grid == null:
		return
	
	# Correctly connect the "focus" chain, so that we can move through the
	# grid via arrow keys.
	var columns := _asset_grid.columns
	var rows := floor(_asset_grid.get_child_count() / columns)
	
	for j in range(0, _asset_grid.get_child_count()):
		var source_node: Control = _asset_grid.get_child(j)
		if j != 0:
			# Not the first node, so we have a previous node.
			source_node.focus_neighbour_left = _asset_grid.get_child(j - 1).get_path()
		if j < _asset_grid.get_child_count() -1:
			# Not the last node, so we have a next node.
			source_node.focus_neighbour_right = _asset_grid.get_child(j + 1).get_path()
		
		var row := floor(j / columns)
		if row != 0:
			# Not in the top row, so there is a node above this in the grid.
			source_node.focus_neighbour_top = _asset_grid.get_child(j - columns).get_path()
		if row < rows - 1:
			# One node down.
			# Bottom row might not be entirely full, so double-check.
			var target_node := _asset_grid.get_child(j + columns)
			if target_node != null:
				source_node.focus_neighbour_bottom = target_node.get_path()
			else:
				# Just go to the last node in the list.
				source_node.focus_neighbour_bottom = _asset_grid.get_child(
					_asset_grid.get_child_count() - 1).get_path()


# This is called with the requested asset texture, when it is ready.
func _on_texture_ready(asset_id: String, texture: ImageTexture):
	var cell: Node = _asset_grid.get_node(asset_id)	
	if cell == null:
		return
	
	cell.display_texture(texture)


# Handles selecting and deselecting cells.
# `child_index`: The value of the child's "get_index()" method.
func _on_cell_focused(child_index: int, shift_pressed: bool, ctrl_pressed: bool):
	if shift_pressed and _last_selected_cell_index != -1:
		# Shift: select everything between the last selected cell, and the
		# current one.
		# Takes precedence over Ctrl selection.
		var start := _last_selected_cell_index
		var stop := child_index
		
		# Should the order be reversed?
		if start > stop:
			start = child_index
			stop = _last_selected_cell_index
		
		for i in range(start, stop + 1):
			_asset_grid.get_child(i).set_selected(true)
	elif ctrl_pressed:
		# Ctrl means: toggle single cell.
		_asset_grid.get_child(child_index).toggle_selected()
	else:
		# No modifier pressed.
		# Deselect all, then reselect the target cell.
		for child in _asset_grid.get_children():
			child.set_selected(false)
		_asset_grid.get_child(child_index).set_selected(true)
	
	# Remember this for the next time the user selects using shift.
	_last_selected_cell_index = child_index
	
	# Let the rest of the program know the current selection.
	var selection := []
	
	for child in _asset_grid.get_children():
		if child.selected:
			selection.append(child.name)
	
	emit_signal("selection_changed", selection)

func _on_new_galaxy(galaxy_node: Node):
	_asset_search._on_new_galaxy(galaxy_node)


func _on_AssetScrollContainer_column_amount_changed():
	# This means the focus chain of the cells is no longer correct for
	# up and down.
	_connect_grid_focus_chain()
