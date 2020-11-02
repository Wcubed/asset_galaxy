extends PanelContainer

# Emitted when we want to display a certain asset.
signal request_asset_texture(asset_id)


var _asset_cell_scene: PackedScene = preload("res://scenes/asset_grid/asset_cell/asset_cell.tscn")

# Keeps track of the last selected cell, for the purposes of multi-selection.
# `-1` means nothing has been selected yet.
var _last_selected_cell_index: int = -1

onready var _asset_grid: GridContainer = find_node("AssetGridContainer")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Clears the current assets in the grid, and displays the given ones.
func display_assets(asset_nodes: Array):
	for node in _asset_grid.get_children():
		node.queue_free()
	
	for node in asset_nodes:
		# Display the info that we currently have.
		var cell := _asset_cell_scene.instance()
		
		cell.name = node.name
		_asset_grid.add_child(cell)
		# For handling selecting and deselecting cells.
		cell.connect("clicked", self, "_on_cell_clicked")
		
		cell.display_asset_info(node)
		
		# Request the texture. (this could take a while).
		emit_signal("request_asset_texture", node.name)
	
	# Can't have selected anything if the cells were just created.
	_last_selected_cell_index = -1


# This is called with the requested asset texture, when it is ready.
func _on_texture_ready(asset_id: String, texture: ImageTexture):
	var cell: Node = _asset_grid.get_node(asset_id)	
	if cell == null:
		return
	
	cell.display_texture(texture)


# Handles selecting and deselecting cells.
# `child_index`: The value of the child's "get_index()" method.
func _on_cell_clicked(child_index: int, shift_pressed: bool, ctrl_pressed: bool):
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
