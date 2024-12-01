extends Area2D
class_name Checkpoint

signal checkpoint_activated(checkpoint_position)

@export var checkpoint_id: int = 0
var is_activated: bool = false

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	print("Checkpoint ", checkpoint_id, " preparado")

func _on_body_entered(body: Node2D) -> void:
	print("Cuerpo entró en checkpoint: ", body)
	if body.is_in_group("Player") and not is_activated:
		print("Jugador en checkpoint ", checkpoint_id)
		activate_checkpoint()

func activate_checkpoint() -> void:
	is_activated = true
	# Emitir señal con la posición global del checkpoint
	emit_signal("checkpoint_activated", global_position)
	print("Checkpoint " + str(checkpoint_id) + " activado")
