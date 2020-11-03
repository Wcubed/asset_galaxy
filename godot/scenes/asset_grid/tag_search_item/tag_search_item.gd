extends Button


var tag_id := -1


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_tag(id: int, tag_text: String):
	tag_id = id
	text = tag_text
	
	pressed = false
