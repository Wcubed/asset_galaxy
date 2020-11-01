extends Control

var galaxy_scene: PackedScene = preload("res://data_structures/galaxy.tscn")

# Our current project.
var galaxy: Node = null

onready var new_galaxy_dialog := $NewGalaxyDialog
onready var folder_not_empty_notification := $NewGalaxyDialog/FolderNotEmptyNotification
onready var load_galaxy_dialog := $LoadGalaxyDialog
onready var add_assets_dialog := $AddAssetsDialog

onready var asset_grid := find_node("AssetGrid")

onready var image_texture_pool: Node = $ImageTexturePool


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


func _open_add_assets_dialog():
	add_assets_dialog.set_as_minsize()
	add_assets_dialog.popup_centered()


func _on_NewGalaxyDialog_dir_selected(path: String):
	# The user has selected a directory.
	# Now we check if it is empty.
	# TODO: check if it actually exists?
	
	if not _is_directory_empty(path):
		# Let the user know they should select an empty directory.
		folder_not_empty_notification.set_as_minsize()
		folder_not_empty_notification.popup_centered()
		
		# Clicking "ok" on the dialog will re-open the directory selector
		# at the path where we left off.
		folder_not_empty_notification.connect("confirmed", self, "_open_new_galaxy_dialog", [path])
	else:
		_new_galaxy(path)


# Utility function to check whether a given directory has anything in it.
func _is_directory_empty(path: String) -> bool:
	var dir := Directory.new()
	dir.open(path)
	dir.list_dir_begin(true)
	
	var empty := true
	if dir.get_next() != "":
		# We have a file or directory.
		# This directory is therefore not empty.
		empty = false
	dir.list_dir_end()
	
	return empty


# `from_disk`, if true it will attempt to load the galaxy from the disk.
func _new_galaxy(dir_path: String, from_disk: bool = false):
	# Save the project that we had open.
	if galaxy:
		galaxy.save()
		remove_child(galaxy)
	
	# Create and save the new galaxy.
	galaxy = galaxy_scene.instance()
	galaxy.save_dir_path = dir_path
	
	add_child(galaxy)
	galaxy.image_texture_pool.connect("texture_ready", self, "_on_texture_ready")
	
	if from_disk:
		# Load an existing galaxy from the disk.
		galaxy.load_from_disk()
	else:
		galaxy.save()
	
	# TODO: make this nicer. Dont just blatantly get all the children.
	asset_grid.display_assets(galaxy.get_assets())


func _load_galaxy(file_path: String):
	var dir_path := file_path.get_base_dir()
	
	_new_galaxy(dir_path, true)


func _add_assets(asset_paths: Array):
	# TODO if we don't have a galaxy loaded, what do we do then?
	#      or do we always load a default one, in a location in the users home directory?
	# TODO: check if the given paths actually exist?
	galaxy.add_assets_from_disk(asset_paths)
	
	# TODO: make this nicer. Dont just blatantly get all the children.
	asset_grid.display_assets(galaxy.get_assets())



func _on_AssetGrid_request_asset_texture(asset_id: String):
	print("requested texture for asset: %s" % asset_id)
	galaxy.request_texture(asset_id)

func _on_texture_ready(asset_id: String, texture: ImageTexture):
	asset_grid._on_texture_ready(asset_id, texture)
