extends StaticBody2D

var opened = false
var key_taken = false
@export var required_key_id : String = "llave_default"  # Debe coincidir con el key_id de la llave

@onready var collision = $CollisionShape2D

enum TimeMode { REAL_WORLD, TIME_WORLD }
@export var dimension = TimeMode.REAL_WORLD

signal door_opened
signal player_near(door)

func _ready() -> void:
	asignar_grupo()

func _on_area_2d_body_entered(body: Node2D) -> void:
	# comprueba si el cuerpo es el jugador, si la llave ha sido recogida y si la puerta está cerrada
	if body.is_in_group("Player"):
		print("Jugador se acerca a puerta")
		if GLOBAL.should_show_button_door:
			$AnimatedSprite2D.visible = true
			$AnimatedSprite2D.play("default")
		emit_signal("player_near", self)
		GLOBAL.is_in_interactive_area = true #establece que el jugador se encuentra en un area interactiva

func asignar_grupo() -> void:
	if dimension == TimeMode.REAL_WORLD:
		add_to_group("Real_world_object")
		$AnimatedSprite2D2.play("idle")
	elif dimension == TimeMode.TIME_WORLD:
		add_to_group("Time_world_object")
		$AnimatedSprite2D2.play("idle_red")
	else:
		if GLOBAL.is_in_real_world:
			$AnimatedSprite2D2.play("idle")
		else:
			$AnimatedSprite2D2.play("idle_red")

func try_open() -> void:
	if (key_taken or Inventario.has_item(required_key_id)) and not opened:
		if is_in_group("Real_world_object"):
			$AnimatedSprite2D2.play("open")
		elif is_in_group("Time_world_object"):
			$AnimatedSprite2D2.play("open_red")
		else:
			if GLOBAL.is_in_real_world:
				$AnimatedSprite2D2.play("open")
			else:
				$AnimatedSprite2D2.play("open_red")
		collision.set_deferred("disabled", true)
		opened = true
		emit_signal("door_opened")
		print("Puerta abierta")
		Inventario.remove_item(required_key_id)
	else:
		print("No tienes la llave correcta para esta puerta")

# función para manejar la señal de la llave cuando se recoge
func _on_key_taken() -> void:
	key_taken = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if $AnimatedSprite2D.visible:
			$AnimatedSprite2D.visible = false
			$AnimatedSprite2D.stop()
		GLOBAL.is_in_interactive_area = false #establece que el jugador ya no se encuentra en un area interactiva
