extends VBoxContainer

# The name of the AssetCell will be set to the same number as the asset it
# displays. Before the cell is added to the tree.

onready var title_label: Label = $Title
onready var texture_rect: TextureRect = $TextureRect

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func display_asset_info(asset_node: Node):
	title_label.text = asset_node.title


func display_texture(texture: ImageTexture):
	texture_rect.texture = texture
