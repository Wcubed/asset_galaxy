extends HBoxContainer

var _current_asset_node: Node = null

onready var _edit := $UrlEdit
onready var _edit_button := $EditButton

# Called when the node enters the scene tree for the first time.
func _ready():
	_cancel_editing()


func display_asset_node(node: Node):
	_cancel_editing()
	_current_asset_node = node
	_edit.text = node.source_url


func _on_EditButton_pressed():
	if !_edit.editable:
		_start_editing()
	else:
		_cancel_editing()


func _start_editing():
	_edit_button.text = "Cancel"
	
	_edit.editable = true
	_edit.mouse_default_cursor_shape = Control.CURSOR_IBEAM
	
	# For convenience, we drop the user into the edit field.
	_edit.grab_focus()
	_edit.caret_position = 9999


func _cancel_editing():
	if _current_asset_node != null:
		_edit.text = _current_asset_node.source_url
	
	_edit_button.text = "Edit"
	_edit.editable = false
	
	_edit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _on_UrlEdit_text_entered(new_url: String):
	_current_asset_node.source_url = new_url
	
	_cancel_editing()


func _on_UrlEdit_gui_input(event):
	if event.is_action_pressed("ui_cancel"):
		_cancel_editing()
		get_tree().set_input_as_handled()



func _on_EditButton_gui_input(event):
	# When the user clicks on the link edit, when not actually editing the link
	# we copy it to the clipboard.
	if _edit.editable == false:
		if event is InputEventMouseButton:
			if event.pressed == true and event.button_index == BUTTON_LEFT:
				OS.clipboard = _current_asset_node.source_url
