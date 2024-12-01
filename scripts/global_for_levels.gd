extends Node


var key_taken : bool = false

# Define el diccionario en el nodo principal o un autoload para guardar los estados de los nodos
var original_states = {}
var current_level : int = 0
var scene_current_level: String = ""

var levels = [
	"res://scenes/levels/levelone.tscn",
	"res://scenes/levels/leveltwo.tscn",
	"res://scenes/levels/levelthree.tscn"
]


# funcion para pasar al siguiente nivel
func load_next_level() -> void:
	if current_level < levels.size():
		current_level += 1
		scene_current_level = levels[current_level - 1]
		# escena de transición en lugar de directamente al nivel
		get_tree().change_scene_to_file("res://scenes/gui/LevelTransition.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/gui/GameEnd.tscn")
		print("¡Juego completado!")
