extends StaticBody2D

@onready var collision_shape = $CollisionShape2D

enum TimeMode { REAL_WORLD, TIME_WORLD }
@export var dimension = TimeMode.REAL_WORLD

func _ready() -> void:
	asignar_grupo()

func _process(delta: float) -> void:
	pass

func asignar_grupo() -> void:
	if dimension == TimeMode.REAL_WORLD:
		add_to_group("Real_world_object")
	else:
		add_to_group("Time_world_object")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.set_on_platform(self)  # Indica al jugador que está sobre este StaticBody2D

func disable_collision():
	collision_shape.disabled = true  # Desactiva la colisión
	await get_tree().create_timer(2).timeout
	collision_shape.disabled = false
