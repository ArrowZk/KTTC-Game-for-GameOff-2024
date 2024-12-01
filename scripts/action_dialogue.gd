extends Area2D

const BALLOON_SCENE = preload("res://dialogue_balloon/balloon.tscn")
@export var dialogue_resource: DialogueResource
@export var dialogue_start: String

func action() -> void:
	var balloon : Node = BALLOON_SCENE.instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(dialogue_resource,dialogue_start)
	# Desactiva el área después de reproducir el diálogo
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)


func _on_body_entered(body: Node2D) -> void:
	action()
	if body.is_in_group("Player"):
		body.velocity = Vector2.ZERO


func _on_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
