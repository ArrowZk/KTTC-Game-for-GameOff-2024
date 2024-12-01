extends Area2D

@onready var player: Player = $"../../Player"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Conecta la señal del player a un método de este script
	# Asumiendo que tienes una referencia al nodo del player
	player.connect("interaction_triggered", Callable(self, "_on_player_interact"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_player_interact():
	if GLOBAL.lvl2_go_door:
		print("¡Interacción detectada!")
		player.global_position = Vector2(125, 2000)

func _on_body_entered(body: Node2D) -> void:
	GLOBAL.lvl2_go_door = true


func _on_body_exited(body: Node2D) -> void:
	GLOBAL.lvl2_go_door = false
