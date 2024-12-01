extends Camera2D

@export var target: Node2D:
	set(value):
		target = value
		# Reiniciar posición cuando cambia el target (cuando el jugador revive)
		if value:
			initial_y_position = target.global_position.y
			position = target.global_position
			position.y -= current_vertical_offset
@export var follow_speed_x: float = 5.0  # Velocidad de seguimiento en X
@export var follow_speed_y: float = 3.0  # Velocidad de seguimiento en Y
@export var base_vertical_offset: float = 40.0  # Desplazamiento vertical inicial
@export var height_threshold_1: float = 200.0  # Primera altura de transición
@export var height_threshold_2: float = 400.0  # Segunda altura de transición

# Variables para el seguimiento suave horizontal
var target_x_pos: float = 0.0
var current_x_pos: float = 0.0

# Variables para el seguimiento suave vertical
var target_y_pos: float = 0.0
var current_y_pos: float = 0.0

# Variables para el offset vertical dinámico
var initial_y_position: float = 0.0
var current_vertical_offset: float = 40.0

func _ready() -> void:
	# Guardar la posición inicial en Y
	initial_y_position = target.global_position.y
	
	# Inicializar posición de la cámara
	position = target.global_position
	position.y -= current_vertical_offset

func _process(delta: float) -> void:
	if not GLOBAL.player_is_alive:
		return
	
	# Seguimiento horizontal suave
	target_x_pos = target.global_position.x
	current_x_pos = lerp(current_x_pos, target_x_pos, delta * follow_speed_x)
	position.x = current_x_pos
	
	# Calcular cambio en Y respecto a la posición inicial
	var y_difference: float = initial_y_position - target.global_position.y
	
	# Calcular offset progresivo según la altura
	if y_difference <= height_threshold_1:
		# Sin cambio de offset
		current_vertical_offset = base_vertical_offset
	elif y_difference <= height_threshold_2:
		# Interpolación lineal entre offset base y 0
		current_vertical_offset = lerp(base_vertical_offset, 0.0, (y_difference - height_threshold_1) / (height_threshold_2 - height_threshold_1))
	else:
		# Más allá del segundo umbral, interpolar hacia offset negativo
		var extra_height: float = y_difference - height_threshold_2
		current_vertical_offset = lerp(0.0, -base_vertical_offset, extra_height / 200.0)
	
	# Seguimiento vertical suave
	target_y_pos = target.global_position.y - current_vertical_offset
	current_y_pos = lerp(current_y_pos, target_y_pos, delta * follow_speed_y)
	
	position.y = current_y_pos
