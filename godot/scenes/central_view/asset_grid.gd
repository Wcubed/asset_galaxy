extends ScrollContainer

# Makes sure more or less columns are displayed when this container is resized.

signal column_amount_changed()
# Emitted when new textures are needed.
signal textures_requested(asset_ids)

# TODO: Make sure the cells are actually this wide, instead of 
#       having to adjust this value manually to the cell width.
var desired_cell_width: float = 105

onready var asset_grid: GridContainer = $AssetGridContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	_fit_columns_to_desired_width()
	
	get_v_scrollbar().connect("scrolling", self, "_on_vertical_scroll")


# Calculate which asset cells are visible, and start the texture loading
# if needed.
func load_textures_for_visible_cells():
	var scroll := get_v_scrollbar()
	var value := scroll.value
	
	var rows := ceil(asset_grid.get_child_count() / asset_grid.columns)
	# Calculate which rows are currently in view.
	var start_row := floor(range_lerp(value, 0, scroll.max_value, 0, rows))
	var end_row := ceil(range_lerp(value + scroll.page, 0, scroll.max_value, 0, rows))
	
	var start_child := min(start_row * asset_grid.columns, asset_grid.get_child_count())
	var end_child := min((end_row + 1) * asset_grid.columns, asset_grid.get_child_count())
	
	# Check which of the asset cells still need a texture.
	var textures_to_load = []
	for i in range(start_child, end_child):
		var child := asset_grid.get_child(i)
		
		if not child.has_required_texture() and child.name.is_valid_integer():
			# This asset cell doesn't yet have it's texture.
			# The name of the cell is equal to the asset that it displays.
			textures_to_load.append(child.name)
	
	if not textures_to_load.empty():
		emit_signal("textures_requested", textures_to_load)
	
	


func _fit_columns_to_desired_width():
	# Try to keep the individual cells to be the desired width.
	var columns_fit := floor(rect_size.x / desired_cell_width)
	
	if columns_fit != asset_grid.columns:
		asset_grid.columns = columns_fit
		
		load_textures_for_visible_cells()
		
		emit_signal("column_amount_changed")


func _on_resized():
	# Check if this event did not fire before we are actually ready.
	if asset_grid != null:
		_fit_columns_to_desired_width()


# Currently the signals `scroll_started` and `scroll_ended` don't work.
# https://github.com/godotengine/godot/issues/22936
# So we have to use some workarounds.
# The vertical scrollbars `scrolling` signal is connected to this.
# As well as the mouse wheel input on this node itself.
func _on_vertical_scroll():
	load_textures_for_visible_cells()

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_DOWN || event.button_index == BUTTON_WHEEL_UP:
			# Probably scrolled. A workaround for the fact that the
			# signals `scroll_started` and `scroll_ended` don't work.
			_on_vertical_scroll()
