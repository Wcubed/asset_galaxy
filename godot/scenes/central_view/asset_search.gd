extends PanelContainer


var _tag_search_item_scene: PackedScene = preload("./tag_search_item/tag_search_item.tscn")

var _galaxy: Node = null

# This holds which tag we were requested to delete, while the user
# sees the confirmation dialog.
var _requested_tag_id_to_delete := 0

onready var _search_edit: LineEdit = $SearchContainer/SearchEdit
onready var _tag_flow_container: Container = $SearchContainer/TagFlowContainer
onready var _tag_delete_confirm_dialog: Popup = $TagDeleteConfirmDialog


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_new_galaxy(galaxy_node: Node):
	# No need to disconnect the signals.
	# The previous galaxy node will have been removed completely.
	
	_galaxy = galaxy_node
	_galaxy.connect("tag_list_changed", self, "_on_tag_list_changed")
	
	# For sure this galaxy has different tags than the one previously open.
	# (if there was one open at all)
	_on_tag_list_changed()


func _run_new_search():
	var title_search := _search_edit.text
	var tag_search := []
	
	for tag_item in _tag_flow_container.get_children():
		if tag_item.pressed:
			tag_search.append(tag_item.tag_id)
	
	_galaxy.run_asset_search(title_search, tag_search)


func _on_SeachEdit_text_changed(new_text:String):
	_run_new_search()



func _on_tag_list_changed():
	var tag_ids: Array = _galaxy.get_tag_ids()
	
	# Remove any tags that are no longer relevant.
	for child in _tag_flow_container.get_children():
		if not child.tag_id in tag_ids:
			# This tag has been removed.
			child.queue_free()
		else:
			# Tag is already in the display.
			tag_ids.erase(child.tag_id)
	
	# Now add the new tags, which remain in the list.
	for tag_id in tag_ids:
		var new_tag_item := _tag_search_item_scene.instance()
		_tag_flow_container.add_child(new_tag_item)
		
		var tag_text: String = _galaxy.get_tag_text(tag_id)
		new_tag_item.set_tag(tag_id, tag_text)
		
		new_tag_item.connect("toggled", self, "_on_tag_item_toggled")
		new_tag_item.connect("tag_delete_requested", self, "_on_tag_delete_requested")


func _on_tag_item_toggled(state: bool):
	_run_new_search()


func _on_tag_delete_requested(tag_id: int, tag_text: String):
	_requested_tag_id_to_delete = tag_id
	_tag_delete_confirm_dialog.dialog_text = "Are you sure you want to delete the tag \"%s\" and remove it from all assets?" % tag_text
	
	_tag_delete_confirm_dialog.popup_centered()


func _on_TagDeleteConfirmDialog_confirmed():
	# Delete authorised.
	_galaxy.delete_tag(_requested_tag_id_to_delete)
