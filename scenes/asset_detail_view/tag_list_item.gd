extends PanelContainer

onready var label := $Label

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func show_tag(id: int, text: String):
	name = str(id)
	label.text = text
