extends PanelContainer

# The name of the AssetCell will be set to the same number as the asset it
# displays. Before the cell is added to the tree.

signal selection_input_recieved(list_index, shift_pressed, ctrl_pressed)

var normal_style: StyleBox = preload("./resources/cell_unselected.stylebox")
var selected_style: StyleBox = preload("./resources/cell_selected.stylebox")


var selected: bool = false setget set_selected

var _asset_node: Node = null
# Where in the list the current asset is located.
# for selection purposes.
var _list_index: int = 0

onready var title_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/Title
onready var texture_rect: TextureRect = $MarginContainer/VBoxContainer/TextureRect
onready var tag_count_panel: PanelContainer = $MarginContainer/VBoxContainer/HBoxContainer/TagCountPanel
onready var tag_count_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/TagCountPanel/TagCountLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	set_selected(false)


func clear():
	if _asset_node != null:
		_asset_node.disconnect("data_changed", self, "_on_asset_data_changed")
		_asset_node = null
	
	texture_rect.texture = null


# list_index: Where in the list the current asset is located.
#           for selection purposes.
func display_asset_info(asset_node: Node, list_index: int):
	if _asset_node != null:
		# Disconnect the previous update signal.
		_asset_node.disconnect("data_changed", self, "_on_asset_data_changed")
	
	_asset_node = asset_node
	_list_index = list_index
	
	# Subscribe to updates.
	asset_node.connect("data_changed", self, "_on_asset_data_changed")
	_on_asset_data_changed()


# Call when data changes. Assumes texture stays the same.
func _on_asset_data_changed():
	title_label.text = _asset_node.title
	
	var tag_count := len(_asset_node.get_tag_ids())
	if tag_count > 0:
		tag_count_panel.visible = true
		tag_count_label.text = str(tag_count)
	else:
		tag_count_panel.visible = false


# Will get called when the asset texture has been loaded.
# Is separate from the `display_asset_info` because the texture will only
# be loaded when this cell is actually visible.
func display_texture(texture: ImageTexture):
	texture_rect.texture = texture

# Whether we have the texture we need.
func has_required_texture() -> bool:
	return texture_rect.texture != null


func set_selected(value: bool):
	selected = value
	
	if selected:
		set("custom_styles/panel", selected_style)
	else:
		set("custom_styles/panel", normal_style)


func toggle_selected():
	set_selected(not selected)


func _on_selection_input():
	# Get's called either when we are clicked, or moved through by mouse.
	# or we get the focus in some other way.
	var shift_pressed := Input.is_key_pressed(KEY_SHIFT)
	var ctrl_pressed := Input.is_key_pressed(KEY_CONTROL)
	
	emit_signal("selection_input_recieved", _list_index, shift_pressed, ctrl_pressed)


func _on_AssetCell_focus_entered():
	if not Input.is_mouse_button_pressed(BUTTON_LEFT):
		# Mouse button is handled by the _gui_input function.
		# The rest is handled via here.
		# If everything went through here, shift selecting a range and then
		# clicking on the last asset in that range, would not change the focus.
		# And therefore not call this function.
		_on_selection_input()

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT && event.pressed:
			# We were left clicked.
			# Regardless of whether we are already focused or not, we want
			# to act upon this.
			_on_selection_input()
