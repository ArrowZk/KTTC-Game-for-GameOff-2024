extends Node2D

var level_instance = Level.new()
var first_time_loading : bool = true
@onready var llaves = $Keys.get_children()  # grupo de llaves en el nivel
@onready var puertas = $Doors.get_children()  # grupo de puertas en el nivel
@onready var player = $Player
@onready var camera = $Cam
var last_checkpoint_position: Vector2 = Vector2.ZERO
var player_scene = preload("res://scenes/player.tscn")

@onready var pause_scene = preload("res://scenes/gui/pause.tscn")
var pause_instance: Node = null
var is_paused: bool = false

@export var dialogue_resource : DialogueResource = preload("res://Dialogues/lvl2_d1.dialogue")
@export var dialogue_start: String = "intro"
const BALLOON_SCENE = preload("res://dialogue_balloon/balloon.tscn")
var balloon
func _ready() -> void:
	balloon = BALLOON_SCENE.instantiate()
	get_tree().current_scene.add_child(balloon)
	# Cambiar el color de fondo global
	RenderingServer.set_default_clear_color(Color("#e1e5f2"))
	GLOBAL.connect("world_state_changed", Callable(self, "_on_world_state_changed"))
	# Configura el estado inicial al cargar la escena
	_on_world_state_changed(GLOBAL.is_in_real_world)
	for llave in llaves:
		if llave is Area2D and llave.has_signal("taken_key"):
			llave.connect("taken_key", Callable(self, "_on_llave_tomada"))
	# Conectar señales
	player.connect("player_died", Callable(self, "_on_player_died"))
	
	# Establecer posición inicial como primer checkpoint
	last_checkpoint_position = player.global_position
	
	# Configurar checkpoints
	var checkpoints = $Checkpoints.get_children() # grupo de checkpoints en el nivel
	print("Checkpoints encontrados: ", checkpoints.size())
	
	# Conectar señales de checkpoints
	for checkpoint in checkpoints:
		print("Conectando checkpoint: ", checkpoint)
		if not checkpoint.is_connected("checkpoint_activated", Callable(self, "_on_checkpoint_activated")):
			checkpoint.connect("checkpoint_activated", Callable(self, "_on_checkpoint_activated"))
			print("Señal conectada para checkpoint")
	$Extras/Timer.start()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # Tecla "ESC" para pausa
		toggle_pause()
		get_viewport().set_input_as_handled()  # Prevenir propagación del evento

func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()

func pause_game() -> void:
	is_paused = true
	get_tree().paused = true  # Pausa el juego
	if not pause_instance:
		pause_instance = pause_scene.instantiate() # agregar escena de pausa
		add_child(pause_instance)  # Agregarla al árbol de nodos
	pause_instance.visible = true  # hacerla visible
	pause_instance.process_mode = Node.PROCESS_MODE_ALWAYS

func resume_game() -> void:
	is_paused = false
	get_tree().paused = false  # Reanuda el juego
	if pause_instance:
		pause_instance.queue_free()  # Libera la instancia de la pausa
		pause_instance = null

func _on_checkpoint_activated(checkpoint_position: Vector2) -> void:
	print("Checkpoint activado: ", checkpoint_position)
	# Actualizar último checkpoint
	last_checkpoint_position = checkpoint_position

func _on_player_died() -> void:
	print("Función _on_player_died llamada")
	respawn_player()

func respawn_player() -> void:
	print("Respawn intentado en posición: ", last_checkpoint_position)
	
	# Instanciar nuevo jugador al respawnear
	var new_player = player_scene.instantiate()
	new_player.name = "Player"
	new_player.global_position = last_checkpoint_position
	
	# Reconectar señales
	new_player.connect("player_died", Callable(self, "_on_player_died"))
	# Actualizar el target de la cámara
	camera.target = new_player
	# Añadir nuevo jugador a la escena
	add_child(new_player)

func _on_llave_tomada():
	print("Una llave ha sido tomada")

func _on_world_state_changed(is_in_real_world):
	# Verifica si el jugador está en el área y ajusta GLOBAL.is_in_interactive_area en consecuencia
	var bodies = $Area2D.get_overlapping_bodies()
	var player_inside = false
	
	for body in bodies:
		if body.is_in_group("Player"):
			player_inside = true
			break
	GLOBAL.is_in_interactive_area = player_inside and not is_in_real_world
	if is_in_real_world:
		show_real_world()
	elif not is_in_real_world:
		show_time_world()

func show_real_world()-> void:
	$Tilesets/RealWorld.enabled = true
	$Tilesets/RealWorldBackground.enabled = true
	$Tilesets/TimeWorld.enabled = false
	$Tilesets/TimeWorldBackground.enabled = false
	if first_time_loading:
		first_time_loading = false
	else: 
		for node in get_tree().get_nodes_in_group("Real_world_object"): # obtiene todos los nodos del mundo real
			level_instance.restore_node(node)
	for node in get_tree().get_nodes_in_group("Time_world_object"):
		level_instance.deactivate_node(node)

func show_time_world()-> void:
	$Tilesets/RealWorld.enabled = false
	$Tilesets/RealWorldBackground.enabled = false
	$Tilesets/TimeWorld.enabled = true
	$Tilesets/TimeWorldBackground.enabled = true
	for node in get_tree().get_nodes_in_group("Time_world_object"): # obtiene todos los nodos del mundo alterno
		level_instance.restore_node(node)
	for node in get_tree().get_nodes_in_group("Real_world_object"):
		level_instance.deactivate_node(node)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not GLOBAL.is_in_real_world:
		GLOBAL.is_in_interactive_area = true
		print("se puede interactuar")

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") or GLOBAL.is_in_real_world:
		GLOBAL.is_in_interactive_area = false
		print("No se puede interactuar")


func _on_timer_timeout() -> void:
	balloon.start(dialogue_resource,dialogue_start)


func _on_audio_stream_player_2d_finished() -> void:
	#DialogueManager.show_example_dialogue_balloon(load("res://Dialogues/lvl1_d1.dialogue"),"intro")
	balloon.start(dialogue_resource,dialogue_start)



func _on_unlock_body_entered(body: Node2D) -> void:
	$Dialogue/ActionDialogue3.set_deferred("monitoring", true)
	$Dialogue/ActionDialogue3.set_deferred("monitorable", true)


func _on_go_next_2_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player.global_position = Vector2(1125,500)


func _on_go_next_3_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player.global_position = Vector2(1955, 510)
