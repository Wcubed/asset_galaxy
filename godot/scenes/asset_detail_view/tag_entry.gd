extends LineEdit

# Menu metatada that indicates to create a new tag.
# -1 is never a valid tag id, so we can use it for this.
const CREATE_NEW_TAG_METADATA := -1
var _galaxy: Node = null

# The index (not id) of the currently selected item in the autocomplete list.
var _current_autocomplete_idx := -1

onready var _auto_complete_popup := $TagAutocompletePopup

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_galaxy_changed(galaxy_node: Node):
	_galaxy = galaxy_node


func _accept_input():
	# Default to creating a new tag.
	var tag_text := text
	
	var tag_id: int = _auto_complete_popup.get_item_id(_current_autocomplete_idx)
	var metadata = _auto_complete_popup.get_item_metadata(_current_autocomplete_idx)
	
	if metadata != CREATE_NEW_TAG_METADATA:
		# User has selected one of the tags.
		tag_text = _galaxy.get_tag_text(tag_id)
	
	emit_signal("text_entered", tag_text)
	
	# Clear the input.
	text = ""
	_auto_complete_popup.hide()


func _on_text_changed(new_text: String):
	_auto_complete_popup.clear()
	
	if new_text == "":
		# No text -> No popup.
		_auto_complete_popup.hide()
		return
	
	# There is always the option to add a new tag.
	# TODO: except when the tag already exists.
	_auto_complete_popup.add_radio_check_item("Create new tag: %s" % new_text)
	# When the text is changed, the "create tag" option is always the one selected.
	_check_autocomplete_item(0)
	# Mark this option as special.
	_auto_complete_popup.set_item_metadata(0, CREATE_NEW_TAG_METADATA)
	
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

# Check the given autocomplete item.
# and uncheck everything else.
func _check_autocomplete_item(item_idx: int):
	_auto_complete_popup.set_item_checked(_current_autocomplete_idx, false)
	_current_autocomplete_idx = item_idx
	_auto_complete_popup.set_item_checked(_current_autocomplete_idx, true)


# We use `_input` instead of `_gui_input` because it allows us to intercept
# the input before it goes to the gui focus changeing code.
func _input(event):
	if not _auto_complete_popup.visible:
		# Can't navigate an invisible popup.
		return
	
	# Navigate the autocomplete popup.
	if Input.is_action_just_pressed("ui_accept"):
		# Don't propagate the action further.
		# That way, the text entries own "accept" code will not fire.
		get_tree().set_input_as_handled()
		_accept_input()
		
	elif Input.is_action_just_pressed("ui_down"):
		# Don't propagate the action further.
		# That way the gui focus change code will not fire.
		get_tree().set_input_as_handled()
		
		# Select the next item.
		if _current_autocomplete_idx != _auto_complete_popup.get_item_count() - 1:
			_check_autocomplete_item(_current_autocomplete_idx + 1)
	
	elif Input.is_action_just_pressed("ui_up"):
		# Don't propagate the action further.
		# That way the gui focus change code will not fire.
		get_tree().set_input_as_handled()
		
		# Select the previous item.
		if _current_autocomplete_idx != 0:
			_check_autocomplete_item(_current_autocomplete_idx - 1)


func _on_TagAutocompletePopup_gui_input(event):
	if event is InputEventMouseMotion:
		# User moved their mouse over the autocomplete popup.
		# Which means we might need to select a different autocomplete item.
		var item_idx: int = _auto_complete_popup.get_current_index()
		if item_idx != -1:
			# User hovered over an option.
			_check_autocomplete_item(item_idx)


func _on_TagAutocompletePopup_index_pressed(index: int):
	_check_autocomplete_item(index)
	_accept_input()
