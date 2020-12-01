extends VBoxContainer

# Emitted when asset cells need new textures to display.
signal textures_requested(asset_ids)

# Emitted when the user selects or deselects assets.
# Passes an array of selected id's.
signal selection_changed(asset_ids)


signal asset_search_requested(title_search)


onready var _asset_search: PanelContainer = find_node("AssetSearch")

onready var _fast_grid: Container = find_node("FastGridContainer")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Clears the current assets in the grid, and displays the given ones.
func display_assets(asset_nodes: Array):
	# TODO: move the whole asset display logic to the FastGridContainer
	#       for now, we just pass on the assets.
	_fast_grid.display_assets(asset_nodes)


# This is called with the requested asset texture, when it is ready.
func _on_texture_ready(asset_id: String, texture: ImageTexture):
	_fast_grid.texture_ready(asset_id, texture)


func _on_new_galaxy(galaxy_node: Node):
	_asset_search._on_new_galaxy(galaxy_node)


func _on_FastGridContainer_textures_requested(asset_ids):
	emit_signal("textures_requested", asset_ids)
