extends Node

# The data in this node should only be changed via the Galaxy node.

# Emitted when any data of the asset changes.
signal data_changed()


const SAVEKEY_ID = "id"
const SAVEKEY_EXTENSION = "ext"
const SAVEKEY_TITLE = "title"
const SAVEKEY_TAGS = "tags"

# File extension of the asset.
# Will be set before the node is added to the tree.
var extension: String = ""

# Human readable title of this asset.
var title: String = "" setget set_title

# Array of integers, which index into the tag dicitonary.
var _tags: Array = []

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


# Converts this node into a dictionary that can be saved.
func to_dict() -> Dictionary:
	var dict := {
		SAVEKEY_ID: name,
		SAVEKEY_EXTENSION: extension,
		SAVEKEY_TITLE: title,
	}
	
	if len(_tags) > 0:
		# No need in saving the tags if there aren't any.
		dict[SAVEKEY_TAGS] = _tags
	
	return dict


# Sets this node's state from a dictionary.
func from_dict(dict: Dictionary):
	# TODO: check for missing values.
	self.name = dict[SAVEKEY_ID]
	self.extension = dict[SAVEKEY_EXTENSION]
	self.title = dict[SAVEKEY_TITLE]
	
	if dict.has(SAVEKEY_TAGS):
		# Make sure we dont read in floats, or strings.
		for tag in dict[SAVEKEY_TAGS]:
			_tags.append(int(tag))
