extends StaticBody2D

enum TimeMode { REAL_WORLD, TIME_WORLD }
@export var dimension = TimeMode.REAL_WORLD
# Señales
signal player_near_box(box, is_near)  # señal para comprobar si jugador esta cerca
var is_being_moved = false
var movement_speed = 100
var player = null
var current_velocity = 0


func _ready():
	asignar_grupo()
	add_to_group("Boxes")

func _physics_process(delta):
	if is_being_moved and current_velocity != 0:
		# Movemos la caja directamente con la velocidad proporcionada
		position.x += current_velocity * delta

func asignar_grupo() -> void:
	if dimension == TimeMode.REAL_WORLD:
		add_to_group("Real_world_object")
		$Sprite2D.texture = load("res://images/elements/Box_blue.png")
	else:
		add_to_group("Time_world_object")
		$Sprite2D.texture = load("res://images/elements/Box_red.png")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		#print("jugador cerca de caja")
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

func stop_moving():
	is_being_moved = false
