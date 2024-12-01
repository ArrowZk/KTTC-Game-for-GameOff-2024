extends CanvasLayer
@onready var resume_button: Button = $MarginContainer/VBoxContainer/Resume
@onready var main_menu_button: Button = $MarginContainer/VBoxContainer/MainMenu

func _ready() -> void:
	resume_button.grab_focus()
	# Verificar si los botones existen
	if not resume_button:
		print("Error: No se encontró el botón de reanudar")
	else:
		# Verificar si la señal se conectó
		print("Botón de reanudar conectado: ", resume_button.is_connected("pressed", _on_resume_pressed))
	
	if not main_menu_button:
		print("Error: No se encontró el botón de menú principal")
	else:
		# Verificar si la señal se conectó
		print("Botón de menú principal conectado: ", main_menu_button.is_connected("pressed", _on_main_menu_pressed))
	
	if resume_button:
		resume_button.grab_focus()

func _on_resume_pressed() -> void:
	# Llama al nodo padre para que reanude el juego
	print("Botón de reanudar presionado")  # Debug
	get_parent().resume_game()
	var gui_node = get_parent().find_child("Gui", false, false)
	if gui_node and not gui_node.visible:
		gui_node.visible = true


func _on_main_menu_pressed() -> void:
	# Cambia a la escena principal del menú
	print("Botón de menú principal presionado")  # Debug
	get_tree().paused = false  # reanudar antes de cambiar de escena
	get_tree().change_scene_to_file("res://scenes/gui/main_menu.tscn")
