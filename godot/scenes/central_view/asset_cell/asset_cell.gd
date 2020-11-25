extends PanelContainer

# The name of the AssetCell will be set to the same number as the asset it
# displays. Before the cell is added to the tree.

signal focused(child_index, shift_pressed, ctrl_pressed)

var normal_style: StyleBox = preload("./resources/cell_unselected.stylebox")
var selected_style: StyleBox = preload("./resources/cell_selected.stylebox")


var selected: bool = false setget set_selected

var _asset_node: Node = null

onready var title_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/Title
onready var texture_rect: TextureRect = $MarginContainer/VBoxContainer/TextureRect
onready var tag_count_panel: PanelContainer = $MarginContainer/VBoxContainer/HBoxContainer/TagCountPanel
onready var tag_count_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/TagCountPanel/TagCountLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	set_selected(false)


func display_asset_info(asset_node: Node):
	if _asset_node != null:
		# Disconnect the previous update signal.
		_asset_node.disconnect("data_changed", self, "_on_asset_data_changed")
	
	_asset_node = asset_node
	
	# Subscribe to updates.
	asset_node.connect("data_changed", self, "_on_asset_data_changed")
	_on_asset_data_changed()


func _on_asset_data_changed():
	title_label.text = _asset_node.title
	
	var tag_count := len(_asset_node.get_tag_ids())
	if tag_count > 0:
		tag_count_panel.visible = true
		tag_count_label.text = str(tag_count)
	else:
		tag_count_panel.visible = false


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


func _on_AssetCell_focus_entered():
	# We got either clicked, or moved through by arrow keys.
	var shift_pressed := Input.is_key_pressed(KEY_SHIFT)
	var ctrl_pressed := Input.is_key_pressed(KEY_CONTROL)
	
	emit_signal("focused", get_index(), shift_pressed, ctrl_pressed)
