extends LineEdit

# Menu id to create a new tag.
# -1 is never a valid tag, so this is ok to use.
const CREATE_NEW_TAG_ID := -1

var _galaxy: Node = null


onready var _auto_complete_popup := $TagAutocompletePopup

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_galaxy_changed(galaxy_node: Node):
	_galaxy = galaxy_node


func _on_text_changed(new_text: String):
	_auto_complete_popup.clear()
	
	if new_text == "":
		# No text -> No popup.
		_auto_complete_popup.hide()
		return
	
	# There is always the option to add a new tag.
	# TODO: except when the tag already exists.
	_auto_complete_popup.add_radio_check_item("Create new tag: %s" % new_text, CREATE_NEW_TAG_ID)
	# When the text is changed, the top option is always the one selected.
	_auto_complete_popup.set_item_checked(0, true)
	
	# Add possible tags.
	for tag_id in _galaxy.get_tag_ids():
		var tag_text: String = _galaxy.get_tag_text(tag_id)
		if tag_text.find(new_text) != -1:
			# Possible auto-complete tag.
			_auto_complete_popup.add_radio_check_item(tag_text, tag_id)
	
	var requested_size: Vector2 = _auto_complete_popup.get_combined_minimum_size()
	# Popup just beneath this text entry, as wide as this entry.
	_auto_complete_popup.popup(Rect2(
		rect_global_position.x, rect_global_position.y + rect_size.y,
		rect_size.x, requested_size.y))
	
	


func _on_TagEntry_focus_exited():
	text = ""
	_auto_complete_popup.hide()
