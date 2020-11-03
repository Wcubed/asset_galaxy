extends Node
# Settings that do not belong in individual galaxies.
# For example: the last open galaxy.

# TODO: save on exit.

const SETTINGS_PATH: String = "user://settings.ini"

onready var config: ConfigFile = ConfigFile.new()

# Directory path of the last opened galaxy.
var last_opened_galaxy: String = "" setget set_last_opened_galaxy

# Called when the node enters the scene tree for the first time.
func _ready():
	var err := config.load(SETTINGS_PATH)
	
	if err == OK:
		last_opened_galaxy = config.get_value("general", "last_opened_galaxy")

func set_last_opened_galaxy(value: String):
	last_opened_galaxy = value
	config.set_value("general", "last_opened_galaxy", value)
	config.save(SETTINGS_PATH)
