extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AudioStreamPlayer.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	GLOBALFORLEVELS.current_level += 1
	get_tree().change_scene_to_file("res://scenes/gui/LevelTransition.tscn")

func setup_audio_loop():
	var audio_stream_player = $AudioStreamPlayer
	
	# Configuración del stream
	#audio_stream_player.stream.loop = true
	audio_stream_player.stream.loop_begin = 28.8 * 1000  # Milisegundos
	
	# Reproducir
	audio_stream_player.play()


func _on_audio_stream_player_finished() -> void:
	$AudioStreamPlayer.play()
