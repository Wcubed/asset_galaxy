extends PanelContainer

# Emitted when we want to display a certain asset.
signal request_asset_texture(asset_id)


var _asset_cell_scene: PackedScene = preload("res://scenes/asset_grid/asset_cell/asset_cell.tscn")


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


# This is called with the requested asset texture, when it is ready.
func _on_texture_ready(asset_id: String, texture: ImageTexture):
	var cell: Node = _asset_grid.get_node(asset_id)	
	if cell == null:
		return
	
	cell.display_texture(texture)


# Handles selecting and deselecting cells.
# `child_index`: The value of the child's "get_index()" method.
func _on_cell_clicked(child_index: int):
	print(child_index)
	# TODO: allow shift and ctrl selecting.
	for child in _asset_grid.get_children():
		child.set_selected(false)
	
	_asset_grid.get_child(child_index).set_selected(true)
