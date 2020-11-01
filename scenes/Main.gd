extends Control

var galaxy_scene: PackedScene = preload("res://data_structures/galaxy.tscn")

# Our current project.
var galaxy: Node = null

onready var new_galaxy_dialog := $NewGalaxyDialog
onready var load_galaxy_dialog := $LoadGalaxyDialog
onready var folder_not_empty_notification := $FolderNotEmptyNotification


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# `path` optional argument. If nothing is given the last selected folder is used
func _open_new_galaxy_dialog(path: String = ""):
	if path != "":
		# Open the requested path
		new_galaxy_dialog.current_dir = path
	
	new_galaxy_dialog.set_as_minsize()
	new_galaxy_dialog.popup_centered()


func _open_load_galaxy_dialog():
	load_galaxy_dialog.set_as_minsize()
	load_galaxy_dialog.popup_centered()


func _on_NewGalaxyDialog_dir_selected(path: String):
	# The user has selected a directory.
	# Now we check if it is empty.
	# TODO: check if it actually exists?
	var dir := Directory.new()
	dir.open(path)
	
	if not _is_directory_empty(dir):
		# Let the user know they should select an empty directory.
		folder_not_empty_notification.set_as_minsize()
		folder_not_empty_notification.popup_centered()
		
		# Clicking "ok" on the dialog will re-open the directory selector
		# at the path where we left off.
		folder_not_empty_notification.connect("confirmed", self, "_open_new_galaxy_dialog", [path])
	else:
		_new_galaxy(dir)


func _is_directory_empty(dir: Directory) -> bool:
	dir.list_dir_begin(true)
	
	var empty := true
	if dir.get_next() != "":
		# We have a file or directory.
		# This directory is therefore not empty.
		empty = false
	dir.list_dir_end()
	
	return empty

# `from_disk`, if true it will attempt to load the galaxy from the disk.
func _new_galaxy(dir: Directory, from_disk: bool = false):
	# Save the project that we had open.
	if galaxy:
		galaxy.save()
		remove_child(galaxy)
	
	# Create and save the new galaxy.
	galaxy = galaxy_scene.instance()
	galaxy.save_directory = dir
	
	add_child(galaxy)
	
	if from_disk:
		# Load an existing galaxy from the disk.
		galaxy.load_from_disk()
	else:
		galaxy.save()

func _load_galaxy(file_path: String):
	var dir_path := file_path.get_base_dir()
	var dir := Directory.new()
	dir.open(dir_path)
	
	_new_galaxy(dir, true)
