extends Node

# The data in this node should only be changed via the Galaxy node.

# Emitted when any data of the asset changes.
signal data_changed()

# Mandatory keys.
const SAVEKEY_ID = "id"
const SAVEKEY_EXTENSION = "ext"
const SAVEKEY_TITLE = "title"
# Optional keys.
const SAVEKEY_TAGS = "tags"
const SAVEKEY_LICENSE = "license"
const DEFAULT_LICENSE = 0
const SAVEKEY_SOURCEURL = "url"

# File extension of the asset.
# Will be set before the node is added to the tree.
var extension: String = ""

# Human readable title of this asset.
var title: String = "" setget set_title

# Array of integers, which index into the tag dicitonary.
# Should not be edited directly.
var _tags: Array = []

# Id into the license dictionary of `galaxy.gd`
var license_id: int = DEFAULT_LICENSE setget set_license_id

# Url to the asset's source. If applicable.
var source_url: String = "" setget set_source_url

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func get_filename() -> String:
	return name + "_" + title + "." + extension


func add_tag(tag_key: int):
	if not tag_key in _tags:
		_tags.append(tag_key)
	
	emit_signal("data_changed")

func remove_tag(tag_key: int):
	_tags.erase(tag_key)
	
	emit_signal("data_changed")

func get_tag_ids() -> Array:
	return _tags


func set_title(new_title: String):
	# TODO: check if the name would be valid in a file name.
	title = new_title
	
	emit_signal("data_changed")


func set_license_id(new_license: int):
	license_id = new_license
	
	emit_signal("data_changed")


func set_source_url(new_url: String):
	source_url = new_url
	
	emit_signal("data_changed")


# Converts this node into a dictionary that can be saved.
func to_dict() -> Dictionary:
	# ---- Mandatory keys ----
	var dict := {
		SAVEKEY_ID: name,
		SAVEKEY_EXTENSION: extension,
		SAVEKEY_TITLE: title,
	}
	
	# ---- Optional keys ----
	if len(_tags) > 0:
		# Only save the tags if there are any.
		dict[SAVEKEY_TAGS] = _tags
	
	if license_id != DEFAULT_LICENSE:
		# Only save the license if it deviates from the default.
		dict[SAVEKEY_LICENSE] = license_id
	
	if source_url != "":
		dict[SAVEKEY_SOURCEURL] = source_url
	
	return dict


# Sets this node's state from a dictionary.
func from_dict(dict: Dictionary):
	# ---- Mandatory keys ----
	# TODO: check for missing values.
	self.name = dict[SAVEKEY_ID]
	self.extension = dict[SAVEKEY_EXTENSION]
	self.title = dict[SAVEKEY_TITLE]
	
	# ---- Optional keys ----
	if dict.has(SAVEKEY_TAGS):
		# Make sure we dont read in floats, or strings.
		for tag in dict[SAVEKEY_TAGS]:
			_tags.append(int(tag))
	
	license_id = int(dict.get(SAVEKEY_LICENSE, DEFAULT_LICENSE))
	source_url = dict.get(SAVEKEY_SOURCEURL, "")
