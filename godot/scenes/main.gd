extends Control

signal new_galaxy(galaxy_node)

var galaxy_scene: PackedScene = preload("res://asset_data/galaxy.tscn")

# Our current project.
var galaxy: Node = null

onready var user_settings := $UserSettings

onready var new_galaxy_dialog := $NewGalaxyDialog
onready var folder_not_empty_notification := $NewGalaxyDialog/FolderNotEmptyNotification
onready var load_galaxy_dialog := $LoadGalaxyDialog
onready var add_assets_dialog := $AddAssetsDialog

onready var asset_grid := find_node("AssetGrid")


# Called when the node enters the scene tree for the first time.
func _ready():
	# We want to save before quiting.
	get_tree().set_auto_accept_quit(false)
	
	# Can we load a previously loaded galaxy?
	# So that the user can immediately continue where they left off?
	if user_settings.last_opened_galaxy != "":
		_load_galaxy_dir(user_settings.last_opened_galaxy)


# This is where the application's `quit` request is handled.
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		# Save before quit.
		galaxy.save()
		get_tree().quit()


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
	galaxy.connect("texture_ready", self, "_on_texture_ready")
	galaxy.connect("asset_search_completed", self, "_on_asset_search_completed")
	
	if from_disk:
		# Load an existing galaxy from the disk.
		galaxy.load_from_disk()
	else:
		galaxy.save()
	
	# Remember the galaxy so we can quickly open it next time.
	user_settings.set_last_opened_galaxy(dir_path)
	
	asset_grid.display_assets(galaxy.get_assets())
	
	emit_signal("new_galaxy", galaxy)


# Load a galaxy project from a directory.
func _load_galaxy_dir(dir_path: String):
	_new_galaxy(dir_path, true)

# Load a galaxy project given a "galaxy.json" file.
# actually calls `_load_galaxy_dir` internally.
func _load_galaxy_file(file_path: String):
	var dir_path := file_path.get_base_dir()
	_load_galaxy_dir(dir_path)


func _add_assets(asset_paths: Array):
	# TODO if we don't have a galaxy loaded, what do we do then?
	#      or do we always load a default one, in a location in the users home directory?
	# TODO: check if the given paths actually exist?
	galaxy.add_assets_from_disk(asset_paths)
	
	# TODO: make this nicer. Dont just blatantly get all the children.
	asset_grid.display_assets(galaxy.get_assets())


func _on_AssetGrid_request_asset_texture(asset_id: String):
	galaxy.request_texture(asset_id)

func _on_texture_ready(asset_id: String, texture: ImageTexture):
	asset_grid._on_texture_ready(asset_id, texture)


func _on_AssetGrid_asset_search_requested(title_search: String):
	galaxy.run_asset_search(title_search)

func _on_asset_search_completed(asset_nodes: Array):
	asset_grid.display_assets(asset_nodes)


func _on_AddAssetsDialog_file_selected(path: String):
	_add_assets([path])


func _on_AddAssetsDialog_files_selected(paths: Array):
	_add_assets(paths)


func _on_AddAssetsDialog_dir_selected(dir_path: String):
	_add_assets(_scan_dir_for_assets_recursively(dir_path))

# Recursively scan the given directory for assets.
# Returns an array of file paths.
func _scan_dir_for_assets_recursively(dir_path: String) -> Array:
	# TODO: have this filter stored somewhere central.
	var asset_extensions := ["png", "jpg"]
	
	# TODO: Check for errors.
	var dir := Directory.new()
	dir.open(dir_path)
	
	var asset_paths := []
	
	dir.list_dir_begin(true)
	var file_name := dir.get_next()
	
	while file_name != "":
		var full_path := dir_path + "/" + file_name
		
		if dir.current_is_dir():
			# Another directory. Scan it recursively.
			asset_paths += _scan_dir_for_assets_recursively(full_path)
		else:
			# Extension capitalization should not matter.
			if file_name.get_extension().to_lower() in asset_extensions:
				# This is an asset.
				asset_paths.append(full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	return asset_paths


func _on_AutoSaveTimer_timeout():
	# Autosave!
	# TODO: only save if the galaxy has actually changed?
	if galaxy != null:
		galaxy.save()
