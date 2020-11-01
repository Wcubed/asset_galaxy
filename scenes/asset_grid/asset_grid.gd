extends PanelContainer


var asset_cell_scene: PackedScene = preload("res://scenes/asset_grid/asset_cell/asset_cell.tscn")


onready var asset_grid: GridContainer = find_node("AssetGridContainer")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Clears the current assets in the grid, and displays the given ones.
func display_assets(asset_nodes: Array):
	for node in asset_grid.get_children():
		node.queue_free()
	
	for node in asset_nodes:
		var cell := asset_cell_scene.instance()
		
		cell.name = node.name
		asset_grid.add_child(cell)
		
		cell.display_asset(node)
