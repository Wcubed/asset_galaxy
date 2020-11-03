extends PanelContainer

# The currently loaded galaxy.
var _galaxy: Node = null

# List of id's that are currently selected.
var _current_selection := []

onready var detail_label := find_node("DetailLabel")
onready var texture_rect := find_node("TextureRect")
onready var tag_entry := find_node("TagEntry")
onready var delete_button := find_node("DeleteButton")

onready var tags_all_have_list := find_node("TagsAllHaveList")
onready var tags_some_have_list := find_node("TagsSomeHaveList")
onready var tags_all_have_label := find_node("AllSelectedTagsLabel")
onready var tags_some_have_label := find_node("SomeSelectedTagsLabel")

onready var confirm_delete_dialog := $ConfirmDeleteDialog

# Called when the node enters the scene tree for the first time.
func _ready():
	# Show 0 assets.
	_display_assets([])


func _display_assets(asset_ids: Array):
	_current_selection = asset_ids
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
		tag_entry.visible = false
		delete_button.visible = false
	elif amount == 1:
		# Show detail view of single item.
		if assets[0] != null:
			# Make sure we get the texture at some point.
			_galaxy.request_texture(assets[0].name)
			detail_label.text = assets[0].title
		
		tag_entry.visible = true
		delete_button.visible = true
		delete_button.text = "Delete Asset"
	else:
		# Show details of multiple items.
		detail_label.text = "%s selected" % amount
		
		tag_entry.visible = true
		delete_button.visible = true
		delete_button.text = "Delete %s Assets" % amount
	
	# ---- Show the tags of the selected asset(s) ----
	
	# Count how many times a tag appars in the selection.
	# So we can be sure which tags are common to all, and which are not.
	# Dictionary of tag_id -> Count of selected assets that have this tag.
	var tag_counts = {}
	for asset in assets:
		var asset_tags = asset.get_tag_ids()
		for tag in asset_tags:
			tag_counts[tag] = tag_counts.get(tag, 0) + 1
	
	var tags_all_have = []
	var tags_some_have = []
	
	for tag in tag_counts:
		if tag_counts[tag] == amount:
			# Every selected asset has this tag.
			tags_all_have.append(tag)
		else:
			tags_some_have.append(tag)
	
	tags_all_have_list.display_tags(tags_all_have)
	tags_some_have_list.display_tags(tags_some_have)
	
	# Hide the appropriate lists.
	if len(tags_all_have) == 0:
		tags_all_have_label.visible = false
		tags_all_have_list.visible = false
	else:
		# No need for the label if there is actually only 1 selected asset.
		# Because of course all the selected assets have that tag.
		tags_all_have_label.visible = amount != 1
		tags_all_have_list.visible = true
	
	if len(tags_some_have) == 0:
		tags_some_have_label.visible = false
		tags_some_have_list.visible = false
	else:
		tags_some_have_label.visible = true
		tags_some_have_list.visible = true


func _on_AssetGrid_selection_changed(asset_ids: Array):
	_display_assets(asset_ids)


func _on_Main_new_galaxy(galaxy_node):
	_galaxy = galaxy_node
	_galaxy.connect("texture_ready", self, "_on_texture_ready")
	_galaxy.connect("tag_list_changed", self, "_on_tag_list_changed")
	
	tags_all_have_list._on_galaxy_changed(galaxy_node)
	tags_some_have_list._on_galaxy_changed(galaxy_node)
	tag_entry._on_galaxy_changed(galaxy_node)


func _on_texture_ready(texture_name, texture):
	# Display the texture if there is a single selection.
	if len(_current_selection) == 1:
		if texture_name == _current_selection[0]:
			texture_rect.texture = texture


func _on_TagEntry_text_entered(new_text):
	# Add the given tag to all the selected assets.
	_galaxy.add_tag_to_assets(_current_selection, new_text)
	
	# Re-display the assets. To reflect the update.
	_display_assets(_current_selection)


func _on_remove_tag_requested(tag_id: int):
	_galaxy.remove_tag_from_assets_by_tag_id(_current_selection, tag_id)
	
	# Re-display the assets. To reflect the update.
	_display_assets(_current_selection)


func _on_DeleteButton_pressed():
	if len(_current_selection) > 0:
		confirm_delete_dialog.set_as_minsize()
		confirm_delete_dialog.popup_centered()


func _on_ConfirmDeleteDialog_confirmed():
	# We have been authorized to delete the selected assets!
	_galaxy.delete_assets(_current_selection)


func _on_tag_list_changed():
	# We need to re-display the assets.
	# because tags might have been removed.
	_display_assets(_current_selection)

