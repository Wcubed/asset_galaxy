extends Node

# Stores image textures of the assets, and their thumbnails.
# TODO: Savely remove unused textures when we approach a certain memory usage.

signal texture_ready(texture_name, texture)

# Dictionary of name to ImageTexture.
var _textures := {}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Returns a texture if a texture with that name is already in memory.
# Else it will load the texture from the given path.
func request_texture(texture_name: String, path: String):
	if _textures.has(texture_name):
		# We can serve the image from memory.
		emit_signal("texture_ready", texture_name, _textures.get(texture_name))
		return
	
	# TODO: do this in a different thread?
	# We cannot serve the image from memory. Load it from disk.
	# TODO: Check if the image file exists.
	var image := Image.new()
	image.load(path)
	
	var texture := ImageTexture.new()
	texture.create_from_image(image)
	
	_textures[texture_name] = texture
	
	emit_signal("texture_ready", texture_name, texture)
