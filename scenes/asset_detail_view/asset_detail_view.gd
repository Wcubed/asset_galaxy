extends PanelContainer

# The currently loaded galaxy.
var galaxy: Node = null

# List of id's that are currently selected.
var current_selection := []

onready var detail_label := find_node("DetailLabel")
onready var texture_rect := find_node("TextureRect")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_AssetGrid_selection_changed(asset_ids: Array):
	current_selection = asset_ids
	var amount = len(asset_ids)
	
	# Regardless of how many there were selected, we'll need to clear
	# the texture.
	texture_rect.texture = null
	
	if amount == 0:
		# Selection was cleared.
		detail_label.text = ""
	elif amount == 1:
		# Show detail view of single item.
		var id = asset_ids[0]
		var asset: Node = galaxy.get_asset(id)
		
		if asset != null:
			# Make sure we get the texture at some point.
			galaxy.request_texture(id)
			detail_label.text = asset.title
	else:
		# Show details of multiple items.
		detail_label.text = "%s selected" % len(asset_ids)


func _on_Main_new_galaxy(galaxy_node):
	galaxy = galaxy_node
	galaxy.connect("texture_ready", self, "_on_texture_ready")


func _on_texture_ready(texture_name, texture):
	# Display the texture if there is a single selection.
	if len(current_selection) == 1:
		if texture_name == current_selection[0]:
			texture_rect.texture = texture
