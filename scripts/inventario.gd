extends Node

signal item_added(item_name, item_data)
signal item_removed(item_name)

var inventory = {}  # diccionario para guardar la informacion de los items

func add_item(item_name: String, item_data: Dictionary = {}):
	print("Inventario: Añadiendo item ", item_name)
	inventory[item_name] = item_data
	emit_signal("item_added", item_name, item_data)

func remove_item(item_name: String):
	print("Inventario: Removiendo item ", item_name)
	if inventory.has(item_name):
		inventory.erase(item_name)
		emit_signal("item_removed", item_name)

func has_item(item_name: String) -> bool:
	print("Inventario: Verificando item ", item_name)  # Debug
	return inventory.has(item_name)

func has_throwable() -> bool:
	for item_name in inventory.keys():
		if inventory[item_name].get("throwable", false):
			return true
	return false

func get_item_data(item_name: String) -> Dictionary:
	print("Inventario: Obteniendo datos del item ", item_name)  # Debug
	return inventory.get(item_name, {})
