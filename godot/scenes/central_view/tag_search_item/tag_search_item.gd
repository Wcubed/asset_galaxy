extends Button

signal tag_delete_requested(tag_id, tag_text)

enum MenuId {
	DELETE,
}

var tag_id := -1

onready var _context_menu: PopupMenu = $ContextMenu


# Called when the node enters the scene tree for the first time.
func _ready():
	_context_menu.add_item("Delete", MenuId.DELETE)


func set_tag(id: int, tag_text: String):
	tag_id = id
	text = tag_text
	
	pressed = false


func _on_ContextMenu_id_pressed(id):
	if id == MenuId.DELETE:
		emit_signal("tag_delete_requested", tag_id, text)


func _gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_RIGHT:
		# Popup at mouse position.
		_context_menu.popup(Rect2(get_global_mouse_position(), _context_menu.get_combined_minimum_size()))
