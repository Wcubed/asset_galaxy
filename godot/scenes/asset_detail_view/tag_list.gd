extends MarginContainer

# Signal is emitted when the "x" is pressed on one of the tags in this list.
# This node will not remove the tag by itself, it is for the receiver of the
# signal to decide what to do with the request.
signal remove_tag_requested(tag_id)

var tag_list_item: PackedScene = preload("res://scenes/asset_detail_view/tag_list_item.tscn")

var _galaxy: Node = null


onready var flow_container := $FlowContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_galaxy_changed(galaxy_node: Node):
	_galaxy = galaxy_node


func display_tags(tag_ids: Array):
	# Remove the previously displayed tags.
	for child in flow_container.get_children():
		child.queue_free()
	
	for id in tag_ids:
		var new_list_item = tag_list_item.instance()
		flow_container.add_child(new_list_item)
		new_list_item.show_tag(id, _galaxy.get_tag_text(id))
		
		new_list_item.connect("remove_tag_requested", self, "_on_remove_tag_requested")


func _on_remove_tag_requested(tag_id: int):
	emit_signal("remove_tag_requested", tag_id)
