extends Control

@onready var label = $MarginContainer/VBoxContainer/Label
@onready var timer = $Timer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Configura el nombre del nivel
	var current_level = GLOBALFORLEVELS.current_level
	label.text = "Level " + str(current_level) + " finished"
	
	# Inicia un temporizador para cambiar a la siguiente escena
	timer.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_timer_timeout() -> void:
	pass


func _on_next_pressed() -> void:
	GLOBALFORLEVELS.load_next_level()


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/gui/main_menu.tscn")
