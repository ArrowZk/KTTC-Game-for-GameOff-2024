extends Panel


var item_name: String = ""
var item_data: Dictionary = {}
@onready var texture_rect = $TextureRect

func set_item(new_item_name: String, new_item_data: Dictionary):
	item_name = new_item_name
	item_data = new_item_data
	
	# Cargar la textura correspondiente según el ID de la llave
	var texture_path = "res://assets/sprites/keys/" + item_name + ".png"  # Ajusta la ruta
	if ResourceLoader.exists(texture_path):
		texture_rect.texture = load(texture_path)
	
