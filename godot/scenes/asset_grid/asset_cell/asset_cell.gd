extends PanelContainer

# The name of the AssetCell will be set to the same number as the asset it
# displays. Before the cell is added to the tree.

signal clicked(child_index, shift_pressed, ctrl_pressed)

var normal_style: StyleBox = preload("res://scenes/asset_grid/asset_cell/resources/cell_unselected.stylebox")
var selected_style: StyleBox = preload("res://scenes/asset_grid/asset_cell/resources/cell_selected.stylebox")


var selected: bool = false setget set_selected

onready var title_label: Label = $MarginContainer/VBoxContainer/Title
onready var texture_rect: TextureRect = $MarginContainer/VBoxContainer/TextureRect

# Called when the node enters the scene tree for the first time.
func _ready():
	set_selected(false)


func display_asset_info(asset_node: Node):
	title_label.text = asset_node.title


func display_texture(texture: ImageTexture):
	texture_rect.texture = texture


func set_selected(value: bool):
	selected = value
	
	if selected:
		set("custom_styles/panel", selected_style)
	else:
		set("custom_styles/panel", normal_style)


func toggle_selected():
	set_selected(not selected)


func _gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT:
		var shift_pressed := Input.is_key_pressed(KEY_SHIFT)
		var ctrl_pressed := Input.is_key_pressed(KEY_CONTROL)
		
		# Left mouse button was pressed on us.
		emit_signal("clicked", get_index(), shift_pressed, ctrl_pressed)
