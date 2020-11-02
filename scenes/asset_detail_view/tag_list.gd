extends VBoxContainer


var tag_list_item: PackedScene = preload("res://scenes/asset_detail_view/tag_list_item.tscn")

var _galaxy: Node = null


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_galaxy_changed(galaxy_node: Node):
	_galaxy = galaxy_node


func display_tags(tag_ids: Array):
	# Remove the previously displayed tags.
	for child in get_children():
		child.queue_free()
	
	for id in tag_ids:
		var new_list_item = tag_list_item.instance()
		add_child(new_list_item)
		new_list_item.show_tag(id, _galaxy.get_tag_text(id))
