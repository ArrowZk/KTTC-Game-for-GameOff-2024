extends RigidBody2D
class_name GravityBox

# Señales
signal player_near_box(box, is_near)

enum TimeMode { REAL_WORLD, TIME_WORLD }
@export var dimension = TimeMode.REAL_WORLD

# Variables de estado
var is_being_moved = false
var current_velocity = Vector2.ZERO
var player = null
var initial_mode: int  # Guardar el modo inicial del RigidBody2D
var is_on_floor: bool = false  # Nueva variable para trackear el estado
var last_position: Vector2  # Nueva variable para guardar la última posición
# Constantes para ajustar el comportamiento
const MOVEMENT_THRESHOLD = 0.1  # Velocidad mínima para considerar movimiento
const MAX_PUSH_SPEED = 150.0   # Velocidad máxima al empujar
const MAX_PULL_SPEED = 150.0    # Velocidad máxima al jalar
const FRICTION = 0.1         # Fricción cuando no se está moviendo
const MAX_DISTANCE = 30.0         # Distancia máxima reducida para mejor control
const MIN_DISTANCE = 2.0         # Distancia mínima para mantener entre jugador y caja

var movement_speed = 100
# Nodo de colisión para detectar al jugador
@onready var detection_area = $Area2D

func _ready():
	last_position = global_position
	asignar_grupo()
	add_to_group("Boxes")
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC  # Inicialmente en modo kinemático para un comportamiento predecible

func _physics_process(delta):
	if is_being_moved and freeze_mode == RigidBody2D.FREEZE_MODE_KINEMATIC:
		# Movemos la caja ajustando su posición
		position.x += current_velocity * delta
	#Guardar la última posición válida si no está cayendo
	if is_on_floor or abs(linear_velocity.length()) < 0.1:
		last_position = global_position

func asignar_grupo() -> void:
	if dimension == TimeMode.REAL_WORLD:
		add_to_group("Real_world_object")
		$Sprite2D.texture = load("res://images/elements/GravityBox_blue.png")
	else:
		add_to_group("Time_world_object")
		$Sprite2D.texture = load("res://images/elements/GravityBox_red.png")

# Método para restaurar a la última posición conocida
func restore_last_position():
	if last_position != Vector2.ZERO:
		global_position = last_position
		linear_velocity = Vector2.ZERO
		freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player = body
		emit_signal("player_near_box", self, true)
		GLOBAL.is_in_interactive_area = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		stop_moving()
		player = null
		emit_signal("player_near_box", self, false)
		GLOBAL.is_in_interactive_area = false

func start_moving(velocity: float = 0.0):
	is_being_moved = true
	current_velocity = velocity
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC # Cambiamos a kinemático para un control directo

func stop_moving():
	is_being_moved = false
	current_velocity = 0
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC  # Regresamos a dinámico para simular gravedad

# Método para establecer la velocidad actual (llamado desde el script del jugador)
func set_velocity(vel: float):
	current_velocity = vel

# Nuevo método para verificar si está en el suelo
func is_grounded() -> bool:
	return is_on_floor
