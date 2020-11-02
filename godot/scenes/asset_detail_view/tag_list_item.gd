extends PanelContainer

signal remove_tag_requested(tag_id)

var _tag_id: int = 0
onready var label := $HBoxContainer/Label

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func show_tag(id: int, text: String):
	_tag_id = id
	label.text = text


func _on_Removebutton_pressed():
	emit_signal("remove_tag_requested", _tag_id)
