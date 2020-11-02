extends ScrollContainer

# Makes sure more or less columns are displayed when this container is resized.

# TODO: Make sure the cells are actually this wide, instead of 
#       having to adjust this value manually to the cell width.
var desired_cell_width: float = 105

onready var asset_grid: GridContainer = $MarginContainer/AssetGridContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	_fit_columns_to_desired_width()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_resized():
	_fit_columns_to_desired_width()


func _fit_columns_to_desired_width():
	# Try to keep the individual cells to be the desired width.
	var columns_fit := floor(rect_size.x / desired_cell_width)
	asset_grid.columns = columns_fit