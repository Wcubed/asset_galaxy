extends MenuButton

signal new_galaxy_pressed
signal load_galaxy_pressed

enum {
	NEW_GALAXY_ID,
	LOAD_GALAXY_ID
}


# Called when the node enters the scene tree for the first time.
func _ready():
	var popup := get_popup()
	
	popup.add_item("New Galaxy", NEW_GALAXY_ID)
	popup.add_item("Open Galaxy", LOAD_GALAXY_ID)
	
	popup.connect("id_pressed", self, "_on_id_pressed")


func _on_id_pressed(id: int):
	if id == NEW_GALAXY_ID:
		emit_signal("new_galaxy_pressed")
	elif id == LOAD_GALAXY_ID:
		emit_signal("load_galaxy_pressed")
