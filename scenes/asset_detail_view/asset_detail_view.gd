extends PanelContainer

# The currently loaded galaxy.
var _galaxy: Node = null

# List of id's that are currently selected.
var current_selection := []

onready var detail_label := find_node("DetailLabel")
onready var texture_rect := find_node("TextureRect")
onready var tag_entry := find_node("TagEntry")

onready var tag_list := find_node("TagList")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_AssetGrid_selection_changed(asset_ids: Array):
	current_selection = asset_ids
	var amount = len(asset_ids)
	
	# Retrieve the actual asset nodes indexed by the given id's.
	var assets := []
	for id in asset_ids:
		var asset: Node = _galaxy.get_asset(id)
		if asset != null:
			assets.append(asset)
	
	# Regardless of how many there were selected, we'll need to clear
	# the texture.
	texture_rect.texture = null
	
	if amount == 0:
		# Selection was cleared.
		detail_label.text = ""
	elif amount == 1:
		# Show detail view of single item.
		if assets[0] != null:
			# Make sure we get the texture at some point.
			_galaxy.request_texture(assets[0].name)
			detail_label.text = assets[0].title
	else:
		# Show details of multiple items.
		detail_label.text = "%s selected" % amount
	
	# Show the tags of the asset(s).
	# TODO: have a list of "all have these tags" and a list for "some have these tags"
	var tag_ids = []
	for asset in assets:
		for tag_id in asset.get_tag_ids():
			# Did we already see this tag?
			if not tag_id in tag_ids:
				tag_ids.append(tag_id)
	
	tag_list.display_tags(tag_ids)


func _on_Main_new_galaxy(galaxy_node):
	_galaxy = galaxy_node
	_galaxy.connect("texture_ready", self, "_on_texture_ready")
	
	tag_list._on_galaxy_changed(galaxy_node)


func _on_texture_ready(texture_name, texture):
	# Display the texture if there is a single selection.
	if len(current_selection) == 1:
		if texture_name == current_selection[0]:
			texture_rect.texture = texture


func _on_TagEntry_text_entered(new_text):
	# Add the given tag to all the selected assets.
	_galaxy.add_tag_to_assets(current_selection, new_text)
	tag_entry.text = ""
