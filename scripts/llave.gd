extends Area2D

var taken = false
@export var linked_door : NodePath
@export var key_id : String = "llave_default"  # Identificador único para cada llave
const NAME: String = "key"
enum TimeMode { REAL_WORLD, TIME_WORLD }
@export var dimension = TimeMode.REAL_WORLD
@export var key_texture : Texture2D
signal taken_key

func _ready():
	asignar_grupo()
	if linked_door.is_empty():
		print("Advertencia: la llave no tiene una puerta asignada.")
	else:
		var puerta = get_node(linked_door)
		connect("taken_key", Callable(puerta, "_on_key_taken"))

func asignar_grupo() -> void:
	if dimension == TimeMode.REAL_WORLD:
		add_to_group("Real_world_object")
		$Sprite2D.play("blue")
		key_texture = load("res://images/elements/llave_blue_idle.png")
	else:
		add_to_group("Time_world_object")
		$Sprite2D.play("red")
		key_texture = load("res://images/elements/llave_red_idle.png")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not taken:
		taken = true
		# Añadir la llave al inventario con información adicional
		var key_data = {
			"object_name": NAME,
			"door_path": linked_door,
			"dimension": dimension,
			"texture": key_texture
		}
		Inventario.add_item(key_id, key_data)
		emit_signal("taken_key")
		queue_free()
		print("Llave tomada y añadida al inventario")
