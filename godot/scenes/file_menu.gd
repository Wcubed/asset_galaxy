extends MenuButton

signal new_galaxy_pressed
signal load_galaxy_pressed
signal add_assets_pressed

enum Id {
	NEW_GALAXY,
	LOAD_GALAXY,
	ADD_ASSETS,
}


# Called when the node enters the scene tree for the first time.
func _ready():
	var popup := get_popup()
	
	popup.add_item("New Galaxy", Id.NEW_GALAXY)
	popup.add_item("Open Galaxy", Id.LOAD_GALAXY)
	popup.add_item("Add Assets", Id.ADD_ASSETS)
	
	popup.connect("id_pressed", self, "_on_id_pressed")


func _on_id_pressed(id: int):
	if id == Id.NEW_GALAXY:
		emit_signal("new_galaxy_pressed")
	elif id == Id.LOAD_GALAXY:
		emit_signal("load_galaxy_pressed")
	elif id == Id.ADD_ASSETS:
		emit_signal("add_assets_pressed")
