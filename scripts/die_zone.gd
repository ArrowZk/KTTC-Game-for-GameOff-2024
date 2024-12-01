extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		GLOBAL.emit_signal("player_take_damage", 2000)  # Mata al jugador al instante
