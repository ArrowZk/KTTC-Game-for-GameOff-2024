extends RigidBody2D
class_name ThrowableItem

@export var item_id: String
@export var item_texture: Texture2D
const NAME :String = "cristal"
enum TimeMode { REAL_WORLD, TIME_WORLD }
@export var dimension = TimeMode.REAL_WORLD
var item_data: Dictionary = {}
var is_picked_up: bool = false
var original_position: Vector2
var player_in_range: bool = false
var last_position: Vector2  # variable para guardar la última posición
var is_on_floor: bool = false  # variable para trackear el estado
func _ready():
	asignar_grupo()
	original_position = global_position
	add_to_group("Throwable")
	last_position = global_position

func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact") and !Inventario.has_item(item_id):
		print("Recogiendo objeto lanzable")
		$AudioStreamPlayer2D.play()
		Inventario.add_item(item_id, {
			"object_name": NAME,
			"throwable": true,
			"texture": item_texture,
			"dimension": dimension
		})
		queue_free()

func asignar_grupo() -> void:
	if dimension == TimeMode.REAL_WORLD:
		add_to_group("Real_world_object")
		$Sprite2D.texture = load("res://images/elements/Throwable_blue.png")
		item_texture = load("res://images/elements/Throwable_blue.png")
	else:
		add_to_group("Time_world_object")
		$Sprite2D.texture = load("res://images/elements/Throwable_red.png")
		item_texture = load("res://images/elements/Throwable_red.png")

# Método para restaurar a la última posición conocida
func restore_last_position():
	if last_position != Vector2.ZERO:
		global_position = last_position
		linear_velocity = Vector2.ZERO
		freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC

func _physics_process(delta: float) -> void:
	if is_on_floor or abs(linear_velocity.length()) < 0.1:
		last_position = global_position

func _on_body_entered(body: Node2D) -> void:
	pass

func _on_body_exited(body: Node2D) -> void:
	pass

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		print("Jugador en contacto con lanzable")
		player_in_range = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		print("Jugador fuera de rango del lanzable")
		player_in_range = false
