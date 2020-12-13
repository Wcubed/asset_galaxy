extends Node


signal texture_ready(texture_name, texture)

signal asset_search_completed(asset_nodes)

# Emitted when a previously unseen tag is added, or a tag is removed completely.
signal tag_list_changed()


const SAVE_FILE_NAME = "galaxy.json"
const ASSETS_DIRECTORY_NAME = "assets"

const SAVEKEY_FORMAT = "save_format"
const SAVE_FORMAT_VERSION = 1
const SAVEKEY_TAGS = "tags"

# Licences dictate what you can do with a particular asset.
# An example would be: CC0 (public domain)
# For new assets, defaults to 0: "Unknown"
# Can also be used to indicate original content made by the user of the
# program, or assets they have bought.
# Integer to licence name. This is a dictinary instead of a list, so that
# re-ordering things here won't mess up older saves.
const _LICENSES := {
	0: "Unknown",
	1: "Original content",
	2: "Bought",
	3: "CC0"
}


var _asset_scene: PackedScene = preload("res://asset_data/asset.tscn")

var save_dir_path: String = "" setget set_save_dir_path
var _assets_dir_path: String = ""

# Id to use for the next asset.
# Increments each time an asset is added.
var _next_asset_id: int = 0

# Integer to tag string.
var _tags: Dictionary = {}
var _next_tag_key = 0

# Last search input.
var _last_title_search := ""
var _last_tag_search := []

onready var _assets: Node = $Assets

onready var image_texture_pool: Node = $ImageTexturePool

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func get_assets() -> Array:
	return _assets.get_children()

func get_asset(id: String) -> Node:
	return _assets.get_node(id)

func add_tag_to_assets(asset_ids: Array, tag: String):
	# We never use capitalization on tags.
	tag = tag.to_lower()
	
	# First, check if this is a known tag.
	var tag_key: int = 0
	var tag_already_exists := false
	
	for key in _tags:
		if _tags[key] == tag:
			tag_already_exists = true
			tag_key = key
			break
	
	if not tag_already_exists:
		# make a new tag.
		tag_key = _next_tag_key
		_tags[tag_key] = tag
		_next_tag_key += 1
		
		emit_signal("tag_list_changed")
	
	# Now add the tag to the assets.
	for id in asset_ids:
		var asset := get_asset(id)
		if asset != null:
			asset.add_tag(tag_key)

func remove_tag_from_assets_by_tag_id(asset_ids: Array, tag: int):
	# TODO: remove unused tags from the galaxy completely?
	#       or do we want a button to do that. That would probably be easier.
	for id in asset_ids:
		var asset := get_asset(id)
		if asset != null:
			asset.remove_tag(tag)


# Completely removes the given tag from the galaxy and from all the assets in it.
func delete_tag(tag_id: int):
	if not tag_id in _tags.keys():
		# This tag does not actually exists.
		# Nothing to do.
		return
	
	for asset in get_assets():
		asset.remove_tag(tag_id)
	
	_tags.erase(tag_id)
	
	emit_signal("tag_list_changed")

func get_tag_text(tag_id: int) -> String:
	return _tags[tag_id]


func get_tag_ids() -> Array:
	return _tags.keys()


func get_licenses() -> Dictionary:
	return _LICENSES


func get_license_text(license_id: int) -> String:
	return _LICENSES.get(license_id, _LICENSES[0])


func change_license_for_assets(asset_ids: Array, new_license: int):
	if new_license in _LICENSES:
		for id in asset_ids:
			get_asset(id).license_id = new_license


func set_source_url_on_asset(id: String, new_url: String):
	var asset := get_asset(id)
	if asset != null:
		asset.source_url = new_url


# If the texture can be found, this node will emit an `texture_ready`
# signal sometime in the future.
func request_textures(asset_ids: Array):
	for id in asset_ids:
		var asset := get_asset(id)
		if asset == null:
			return
		
		# Request that the full image be retrieved.
		image_texture_pool.request_texture(id, _assets_dir_path + "/" + asset.get_filename())


# Runs a search through the assets.
# If `title_search` is an empty string, the title won't be used in the search.
# If `tag_search` is an empty string, the tags won't be used in the search.
func run_asset_search(title_search: String, tag_search: Array):
	# Remember the search terms, so we can re-run the search later.
	_last_title_search = title_search
	_last_tag_search = tag_search
	
	# TODO: Run in a separate thread?
	var found_assets := []

	# We don't care about capitalization.
	title_search = title_search.to_lower()
	for asset in _assets.get_children():
		# TODO: Add some kind of fuzzy search?
		
		# We don't care about capitalization.
		if asset.title.to_lower().find(title_search) != -1 or title_search == "":
			found_assets.append(asset)
	
	# Now check the tags.
	# We currently go for an "OR" approach: an asset needs to have at least one
	# of the selected tags.
	if not tag_search.empty():
		var assets_not_matching := []
		
		for asset in found_assets:
			var tag_found := false
			
			for tag in asset.get_tag_ids():
				if tag in tag_search:
					# Asset has at least one matching tag.
					tag_found = true
					break
			
			if not tag_found:
				# this asset has no matching tags.
				assets_not_matching.append(asset)
		
		# Now remove all assets from the list that did not match.
		for asset in assets_not_matching:
			found_assets.erase(asset)
	
	
	emit_signal("asset_search_completed", found_assets)


# Run the last asset search again.
# Usually because assets were added or removed.
func re_run_asset_search():
	run_asset_search(_last_title_search, _last_tag_search)


func delete_assets(asset_ids: Array):
	var dir := Directory.new()
	
	for id in asset_ids:
		var asset := get_asset(id)
		var file_name := asset.get_filename()
		
		dir.remove(_assets_dir_path + "/" + file_name)
		
		_assets.remove_child(asset)
		asset.queue_free()
	
	# Always save after messing with the file system.
	# Otherwise the files on-disk, and the ones in the save-file might
	# get out of sync.
	save()
	# Update any views that use the search data.
	re_run_asset_search()


func set_save_dir_path(path: String):
	save_dir_path = path
	_assets_dir_path = path + "/" + ASSETS_DIRECTORY_NAME
	
	# Make sure the files directory exists.
	var dir := Directory.new()
	if not dir.dir_exists(_assets_dir_path):
		dir.make_dir(_assets_dir_path)


func add_assets_from_disk(asset_paths: Array):
	for path in asset_paths:
		_add_asset_from_disk(path)
	
	# Always save after adding new assets.
	save()


func _add_asset_from_disk(path: String):
	var new_asset = _asset_scene.instance()
	
	new_asset.name = str(_next_asset_id)
	new_asset.extension = path.get_extension()
	# Title defaults to the asset's file name (without extension) before importing.
	new_asset.title = path.get_file()
	if new_asset.extension != "":
		new_asset.title = new_asset.title.left(new_asset.title.length() - (new_asset.extension.length() + 1))
	
	# Copy the file over.
	var dir := Directory.new()
	var err := dir.copy(path, _assets_dir_path + "/" + new_asset.get_filename())
	
	if err == OK:
		_next_asset_id += 1
		_assets.add_child(new_asset)
		print("Added new asset: %s" % path)
	else:
		# TODO: Notify the user.
		print("Could not add asset: %s, because of error: %s" % [path, err])


func _add_asset_from_dict(dict: Dictionary):
	var new_asset = _asset_scene.instance()
	
	new_asset.from_dict(dict)
	
	# Make sure our next asset id is always higher than what we load.
	# Otherwise we might trample over this assets id at some point.
	var asset_id: int = int(new_asset.name)
	if asset_id >= _next_asset_id:
		_next_asset_id = asset_id + 1
	
	# TODO: check if the asset file exists?
	#       what to do if it doesn't?
	_assets.add_child(new_asset)


func save():
	# TODO: make a backup?
	print("Saving galaxy to: %s" % save_dir_path)
	
	var save_dict = {
		SAVEKEY_FORMAT: SAVE_FORMAT_VERSION,
		SAVEKEY_TAGS: _tags,
	}
	
	var file := File.new()
	file.open(save_dir_path + "/" + SAVE_FILE_NAME, File.WRITE)
	
	# First line has the general galaxy settings.
	file.store_line(to_json(save_dict))
	
	# Then each line is an asset.
	for child in _assets.get_children():
		file.store_line(to_json(child.to_dict()))
	
	# Done!
	file.close()
	print("Save done.")


func load_from_disk():
	var file := File.new()
	var file_name := save_dir_path + "/" + SAVE_FILE_NAME
	
	if not file.file_exists(file_name):
		# TODO: show some kind of message.
		return
	
	file.open(file_name, File.READ)
	
	# First line has the general galaxy settings.
	var load_dict: Dictionary = parse_json(file.get_line())
	
	if load_dict[SAVEKEY_FORMAT] == SAVE_FORMAT_VERSION:
		print("Save format versions match.")
	else:
		# TODO: allow conversion from previous save formats.
		# If we have converted the save format, do we want to immediately save it in the new format?
		print("Save format versions do not match. We need to do some conversion.")
	
	if load_dict.has(SAVEKEY_TAGS):
		# TODO: do we want to check if all the asset tag id's are actually
		#       pointing to valid tags?
		
		var tag_dict: Dictionary= load_dict[SAVEKEY_TAGS]

		# Convert the tag keys to integer, and check which tag key to use next.
		for tag_key_string in tag_dict:
			var tag_key_int = int(tag_key_string)
			
			var tag = tag_dict[tag_key_string]
			
			_tags[tag_key_int] = tag
			if tag_key_int >= _next_tag_key:
				_next_tag_key = tag_key_int + 1
	
	# Each next line is an asset.
	while not file.eof_reached():
		var line := file.get_line()
		
		if line != "":
			var dict: Dictionary = parse_json(line)
			_add_asset_from_dict(dict)
		else:
			break
	
	# Done!
	print("Loaded %s assets." % _assets.get_child_count())


func _on_ImageTexturePool_texture_ready(texture_name, texture):
	emit_signal("texture_ready", texture_name, texture)
