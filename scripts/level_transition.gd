extends Control

@onready var level_name_label = $MarginContainer/Label
@onready var timer = $Timer

func _ready():
	
	# Configura el nombre del nivel
	var current_level = GLOBALFORLEVELS.current_level
	level_name_label.text = "Level " + str(current_level)
	
	# Inicia un temporizador para cambiar a la siguiente escena
	timer.start()



func _on_timer_timeout() -> void:
	# Carga la escena del nivel
	get_tree().change_scene_to_file(GLOBALFORLEVELS.levels[GLOBALFORLEVELS.current_level - 1])
