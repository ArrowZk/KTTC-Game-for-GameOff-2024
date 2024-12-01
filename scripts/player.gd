extends CharacterBody2D
class_name Player

signal ability_timer_changed(current_time, max_time)
signal player_died  # señal para comunicar muerte
signal dimension_changed
signal interaction_triggered()

@export var health : int = 100
# RayCast2D nodes para detectar esquina
@onready var front_raycast = $RayCast/FrontRayCast2D
@onready var top_raycast = $RayCast/TopRayCast2D
@onready var up_front_raycast = $RayCast/UpFrontRayCast2D
@onready var down_front_raycast = $RayCast/DownFrontRayCast2D
@onready var coyote_timer: Timer = $Timers/CoyoteTimer
@onready var jump_buffer_timer: Timer = $Timers/JumpBufferTimer
@onready var dimension_timer: Timer = $Timers/DimensionTimer
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

@onready var collision_shape = $CollisionShape2D
@onready var ladder_ray_cast = $RayCast/LadderRayCast2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var dimension_shift_max_time = 10.0  # Tiempo máximo de la habilidad
@export var damage: float = 10.0 #daño que hace el jugador
var dimension_shift_current_time = dimension_shift_max_time
var is_dimension_shifting = false
var regeneration_speed = 1.0  # Velocidad de regeneración

var step_timer: float = 0.0
var step_interval: float = 0.5  # Ajusta este valor para controlar la frecuencia de los pasos
var step_interval_run: float = 0.4

var tween: Tween = null  # Referencia al Tween

var selected_item: Dictionary = {}
var selected_throwable: String = "" :
	set(value):
		selected_throwable = value
		print("Player: selected_throwable cambiado a: ", value)  # Debug
# Al inicio de la clase, después de las otras variables
var last_movement_direction: Vector2 = Vector2.RIGHT  # Dirección por defecto

const JUMP_BUFFER_TIME = 0.1  # Tiempo en segundos para el buffer del salto
# Define las dimensiones de colisión para las animaciones necesarias
const STAND_COLLISION = Vector2(12, 30)
const CROUCH_COLLISION = Vector2(16, 24)
const WALL_COLLISION = Vector2(12, 32)
# Constantes de offset para la collision shape
const STAND_OFFSET = Vector2(0, 9)
const CROUCH_OFFSET = Vector2(0, 9)
const WALL_OFFSET = Vector2(0, 10)

const CORNER_CORRECTION_HORIZONTAL = 5.0  # Píxeles de corrección horizontal
const CORNER_CORRECTION_VERTICAL = 5.0    # Píxeles de corrección vertical
const CORNER_CHECK_DISTANCE = 20.0        # Distancia para verificar colisiones
const CORRECTION_COLLISION_MASK = (1 << 0) | (1 << 2)  # Capas 1 y 3
var corner_rays_left: Array[RayCast2D]
var corner_rays_right: Array[RayCast2D]
var ceiling_rays: Array[RayCast2D]

const MAX_FALL_SPEED = 500.0  # Velocidad máxima de caída normal
const MAX_FALL_SPEED_FAST = 700.0  # Velocidad máxima de caída rápida
const FAST_FALL_GRAVITY_MULTIPLIER = 1.5  # Multiplicador de gravedad para caída rápida
const WALL_SLIDE_MAX_SPEED = 200.0  # Velocidad máxima durante wall slide

const ACCELERATION = 400.0  # Qué tan rápido alcanza la velocidad máxima
const DECELERATION = 600.0  # Qué tan rápido se detiene
const AIR_ACCELERATION = 400.0  # Aceleración más baja en el aire
const AIR_DECELERATION = 400.0  # Desaceleración más baja en el aire
const TURN_ACCELERATION_MULTIPLIER = 2.0  # Multiplicador para cambiar de dirección más rápido

const CROUCH_COLLISION_SIZE = Vector2(20, 30)
const STAND_COLLISION_SIZE = Vector2(15, 45)
const SPEED = 100.0
const SPEED_RUN = 250.0
const JUMP_VELOCITY = -180.0
const JUMP_VELOCITY_RUN = -250.0
const WALL_SLIDE_GRAVITY = 30.0
const COYOTE_TIME_MAX = 0.2
const CLIMB_SPEED = 100.0
const CLIMB_HEIGHT = 90.0
const WALL_JUMP_FORCE = Vector2(250, -250)  # Nuevo: fuerza específica para wall jump

const MAX_STAMINA = 100.0
const STAMINA_DRAIN_RATES = {
	"RUN": 10.0,          # Unidades por segundo
	"WALL_SLIDE": 20.0,   # Unidades por segundo
	"CLIMB": 20.0,        # Unidades por segundo
	"WALL_JUMP": 15.0,     # Costo fijo por wall jump
	"PUSH": 10.0,         # Unidades por segundo
	"PULL": 10.0,          # Unidades por segundo
	"JUMP": 5.0,          # Unidades por segundo
	"JUMP_RUN": 10.0
}
const STAMINA_RECOVERY_RATE = 15.0  # Unidades por segundo
const MIN_STAMINA_FOR_ACTIONS = 1.0  # Mínima stamina necesaria para acciones

# Añade estas variables junto a las otras variables de clase
var current_stamina: float = MAX_STAMINA
var can_use_stamina: bool = true
var stamina_recovery_timer: float = 0.0
const STAMINA_RECOVERY_DELAY = 1.0  # Segundos antes de empezar a recuperar stamina

var coyote_time = 0.0
var puerta_cercana: Node = null  # Almacena la puerta cercana
var current_platform = null  # Referencia al StaticBody2D en el que está
var caja_cercana: Node = null  # Caja cercana para empujar o jalar
var already_climb : bool = false
var delta_aux : float
var was_on_floor: bool = false
var has_buffered_jump: bool = false
var climb_box: bool = false
# Añade estas nuevas constantes junto a las otras
const JUMP_CUT_MULTIPLIER = 0.4  # Factor de reducción al soltar el botón de salto
const MIN_JUMP_VELOCITY = -50.0  # Velocidad mínima del salto al cortar

# Añade estas variables junto a las otras variables de clase
var is_jump_pressed: bool = false
var can_cut_jump: bool = false

# Variables para el sistema de daño por caída
const FALL_DAMAGE_THRESHOLD = 400.0  # Velocidad Y mínima para empezar a recibir daño
const MAX_FALL_DAMAGE = 90  # Daño máximo por caída
const FATAL_FALL_VELOCITY = 900.0  # Velocidad que causará el daño máximo
var max_fall_velocity = 0.0  # Rastrear la máxima velocidad de caída
var is_tracking_fall = false  # Bandera para saber si estamos rastreando una caída
var last_checkpoint_position: Vector2 = Vector2.ZERO

var throw_direction: Vector2 = Vector2.RIGHT
var throw_power: float = 500.0  # Adjust as needed
var throw_angle: float = 45.0  # Initial throw angle
var max_throw_angle: float = 80.0
var min_throw_angle: float = 10.0
var trajectory_line: Line2D  # For drawing throw trajectory
# Modificaciones para la visualización de trayectoria
var is_trajectory_visible: bool = false
# Añadir estas variables para depuración
var is_in_throw_mode: bool = false
var throw_offset: Vector2 = Vector2(5, 0)  # Ajusta según la distancia deseada
var can_attack: bool = false
enum States { IDLE, WALK, RUN, JUMP, CROUCH, WALL_SLIDE, CLIMB, CLIMB_LADDER, HANG, OPEN_DOOR, FALL, WALL_JUMP, HOLD_BOX, PUSH, PULL, THROW, ATTACK}
var state: States = States.IDLE: set = set_state
var previous_state: States

func _ready() -> void:
	GLOBAL.player_take_damage.connect(take_damage)
	#hace global la variable health
	GLOBAL.player_health = health
	GLOBAL.player_stamina = current_stamina  # Sincronizar con variable global
	# Crear la línea de trayectoria
	trajectory_line = Line2D.new()
	trajectory_line.width = 3.0
	trajectory_line.default_color = Color("#1f7a8c")
	trajectory_line.antialiased = true
	trajectory_line.z_index = 100  # Asegúrate de que esté por encima de otros nodos
	add_child(trajectory_line)
	# Conectar la señal de animación terminada
	$AnimatedSprite2D.connect("animation_finished", Callable(self, "_on_attack_animation_finished"))
	# Conectarse a la señal de todas las puertas en el nivel
	for puerta in get_tree().get_nodes_in_group("Doors"):
		puerta.connect("player_near", Callable(self, "_on_player_near_door"))
	# Conectarse a la señal de las cajas en el nivel
	for caja in get_tree().get_nodes_in_group("Boxes"):
		if not caja.is_connected("player_near_box", Callable(self, "_on_player_near_box")):
			caja.connect("player_near_box", Callable(self, "_on_player_near_box"))
		#assert(caja.has_signal("player_near_box"), "La caja no tiene la señal player_near_box")
		#caja.connect("player_near_box", Callable(self, "_on_player_near_box"))
	setup_corner_correction()

func adjust_collision_shape(is_crouching: bool = false, is_wall: bool = false):
	if collision_shape.shape is RectangleShape2D:
		var new_size: Vector2
		var new_offset: Vector2
		if is_crouching:
			new_size = CROUCH_COLLISION
			new_offset = CROUCH_OFFSET
		elif is_wall:
			new_size = WALL_COLLISION
			new_offset = WALL_OFFSET
		else:
			new_size = STAND_COLLISION
			new_offset = STAND_OFFSET
		# Calcula la diferencia en altura para mantener los pies alineados
		var height_difference = (collision_shape.shape.size.y - new_size.y) / 2
		var final_offset = new_offset + Vector2(0, height_difference)
		
		collision_shape.shape.size = new_size
		collision_shape.position = final_offset
		#print("Collision shape adjusted - Size: ", new_size, " Offset: ", final_offset)

func _process(delta: float) -> void:
	if GLOBAL.force_change:
		change()
		GLOBAL.force_change = false
	if GLOBAL.dont_move:
		velocity = Vector2.ZERO
		return
	update_raycasts_direction()
	if GLOBAL.player_health <= 0:
		die()
	# Solo se agota la barra si está en la otra dimensión
	if GLOBAL.is_in_real_world == false and is_dimension_shifting:
		dimension_shift_current_time -= delta
		
		# Emitir señal para actualizar la barra
		emit_signal("ability_timer_changed", dimension_shift_current_time, dimension_shift_max_time)
		
		# Si la barra se agota completamente, volver a la dimensión original
		if dimension_shift_current_time <= 0:
			exit_dimension_shift()
	
	# Regeneración de la barra cuando no está en la otra dimensión
	if GLOBAL.is_in_real_world and dimension_shift_current_time < dimension_shift_max_time:
		dimension_shift_current_time += delta * regeneration_speed
		dimension_shift_current_time = min(dimension_shift_current_time, dimension_shift_max_time)
		
		# Emitir señal para actualizar la barra
		emit_signal("ability_timer_changed", dimension_shift_current_time, dimension_shift_max_time)
	#print(dimension_timer.time_left)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventario"):
		var inventario_gui = $"../Gui"
		inventario_gui.visible = !inventario_gui.visible
	if event.is_action_pressed("interact"):
		interact()
		# Emite la señal de interacción
		emit_signal("interaction_triggered")
	# Añadir lógica para activar el estado de lanzamiento
	if event.is_action_pressed("throw"):
		print("DEBUG: Tecla throw presionada")
		if selected_throwable and Inventario.has_item(selected_throwable):
			print("DEBUG: Iniciando estado THROW")
			set_state(States.THROW)
	if state == States.THROW:
		if event.is_action_pressed("ui_left"):
			adjust_throw_angle(1)  # Increase angle
		elif event.is_action_pressed("ui_right"):
			adjust_throw_angle(-1)  # Decrease angle
		
		if event.is_action_pressed("ui_cancel"):
			cancel_throw()
		
		if event.is_action_pressed("interact"):
			execute_throw()

func _physics_process(delta: float) -> void:
	if state == States.ATTACK:
		handle_attack_state()
		return
	# Modificar la lógica de estados para que el estado THROW tenga prioridad
	if state != States.THROW:
		handle_stamina(delta)
		# Rastrear la velocidad máxima de caída
		if not is_on_floor():
			if velocity.y > 0:  # Si está cayendo (velocidad Y positiva)
				is_tracking_fall = true
				max_fall_velocity = max(max_fall_velocity, velocity.y)
		elif is_tracking_fall:  # Si acaba de aterrizar
			apply_fall_damage()
			reset_fall_tracking()
		if not is_on_floor():
			if state == States.WALL_SLIDE:
				#print(" cambia gravedad para deslizar")
				if ((Input.is_action_pressed("ui_left") and not $AnimatedSprite2D.flip_h) or (Input.is_action_pressed("ui_right") and $AnimatedSprite2D.flip_h)):
					velocity.y += WALL_SLIDE_GRAVITY * delta
				#if ((Input.is_action_just_released("ui_left") and not $AnimatedSprite2D.flip_h) or (Input.is_action_just_released("ui_right") and $AnimatedSprite2D.flip_h)):
				# Limitar la velocidad de deslizamiento en pared
					velocity.y = min(velocity.y, WALL_SLIDE_MAX_SPEED)
				else:
					set_state(States.FALL)
				#delta_aux = delta
			else:
				velocity += get_gravity() * delta
		
		check_coyote_time()
		
		# Manejar el salto ANTES de las transiciones de estado
		handle_jump()
		 # No aplicar movimiento normal durante estados de interacción con cajas
		if not state in [States.WALL_SLIDE, States.WALL_JUMP, States.HOLD_BOX, States.PUSH, States.PULL, States.THROW, States.ATTACK] and GLOBAL.can_walk:
				handle_movement() # Nueva función para manejar el movimiento horizontal
		handle_state_transitions()
		handle_box_interaction()
		
		# Añadir una llamada explícita para verificar la escalada
		if can_climb_corner():
			print("Escalada de esquina detectada en physics_process")
			set_state(States.CLIMB)
		
		if Input.is_action_just_pressed("ui_accept") and state == States.HANG:
			# Verificar si está colgado de una caja
			var hanging_object = front_raycast.get_collider()
			
			if hanging_object and hanging_object.is_in_group("Boxes"):
				# Si está colgado de una caja, escalar la caja
				already_climb = true
				set_state(States.CLIMB)
				print("Escalando caja")
			else:
				# Comportamiento original para otras superficies
				already_climb = true
				set_state(States.CLIMB)
		
		if Input.is_action_pressed("attack") and GLOBAL.can_attack:
			if not state in [States.WALL_SLIDE, States.WALL_JUMP, States.HOLD_BOX, States.PUSH, States.PULL, States.THROW, States.CROUCH, States.CLIMB, States.CLIMB_LADDER, States.HANG, States.OPEN_DOOR, States.FALL]:
				set_state(States.ATTACK)
		if Input.is_action_just_pressed("change_dimension") and GLOBAL.can_change_dimentions:
			change()
			set_state(States.IDLE)
			#dimension_timer.start()
		if Input.is_action_just_pressed("interact"):
			if GLOBAL.is_in_interactive_area and puerta_cercana:
				set_state(States.OPEN_DOOR)
			if GLOBAL.is_in_interactive_area and caja_cercana:
				set_state(States.PUSH)
		if Input.is_action_just_pressed("ui_down") and current_platform:
			current_platform.disable_collision()
			current_platform = null
	if state == States.THROW and is_trajectory_visible:
		update_throw_trajectory()
	match state:
		States.IDLE:
			handle_idle_state()
		States.WALK:
			handle_walk_state()
		States.RUN:
			handle_run_state()
		States.JUMP:
			handle_jump_state()
		States.CROUCH:
			handle_crouch_state()
		States.WALL_SLIDE:
			handle_wall_slide_state()
		States.WALL_JUMP:
			handle_wall_jump_state()
		States.CLIMB:
			handle_climb_state(delta)
		States.CLIMB_LADDER:
			handle_climb_ladder_state()
		States.HANG:
			handle_hang_state()
		States.OPEN_DOOR:
			handle_open_door_state()
		States.FALL:
			handle_fall_state()
		States.HOLD_BOX:
			handle_hold_box_state()
		States.PUSH:
			handle_push_state()
		States.PULL:
			handle_pull_state()
		States.THROW:
			pass
		States.ATTACK:
			handle_attack_state()
	# Aplicar corrección de bordes antes de move_and_slide
	var was_corrected = apply_corner_correction()
	# Actualizar la línea de trayectoria si estamos en estado de lanzamiento
	#if state == States.THROW:
		#update_throw_trajectory()
	# Si hubo corrección y estábamos en estado FALL, permitir un pequeño tiempo
	# extra para saltar (similar al coyote time)
	if was_corrected and state == States.FALL:
		coyote_timer.start(COYOTE_TIME_MAX * 0.5)  # Dar la mitad del tiempo normal de coyote
	
	move_and_slide()
	if state != States.PULL:
		update_sprite_direction()

func start_dimension_shift():
	if dimension_shift_current_time > 0:
		is_dimension_shifting = true
		GLOBAL.is_in_real_world = false
		emit_signal("dimension_changed")

func exit_dimension_shift():
	is_dimension_shifting = false
	GLOBAL.is_in_real_world = true
	emit_signal("dimension_changed")

func update_throw_trajectory() -> void:
	if not trajectory_line:
		return
	
	# Limpiar los puntos previos
	trajectory_line.clear_points()
	
	# Obtener la posición inicial y calcular la trayectoria
	var start_pos = global_position
	var angle_rad = deg_to_rad(throw_angle)
	var trajectory_points = calculate_trajectory(start_pos, throw_power, angle_rad)
	
	# Convertir puntos a locales si es necesario
	for i in range(trajectory_points.size()):
		trajectory_points[i] = to_local(trajectory_points[i])
	
	# Agregar puntos a la línea
	if trajectory_points.size() > 0:
		trajectory_line.points = trajectory_points
		trajectory_line.visible = true
	else:
		trajectory_line.visible = false

func calculate_trajectory(
	start_pos: Vector2, 
	initial_velocity: float, 
	angle: float
) -> PackedVector2Array:
	var points = PackedVector2Array()
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	
	# Componentes de velocidad inicial
	var vx = initial_velocity * cos(angle) * throw_direction.x
	var vy = -initial_velocity * sin(angle)

	# Configuración de cálculo
	var time_step = 0.1
	var max_points = 50

	for t in range(max_points):
		var time = t * time_step
		var x = start_pos.x + vx * time
		var y = start_pos.y + vy * time + 0.5 * gravity * time * time

		points.append(Vector2(x, y))

		# Detener si la trayectoria cae por debajo de la posición inicial
		if y > start_pos.y and t > 1:
			break
	print(points)
	return points

# Ajustar el ángulo de lanzamiento
func adjust_throw_angle(direction: int) -> void:
	throw_angle = clamp(throw_angle + (5 * direction), min_throw_angle, max_throw_angle)
	if state == States.THROW:
		update_throw_trajectory()

func execute_throw() -> void:
	if not Inventario.has_item(selected_throwable):
		cancel_throw()
		return
	
	# Spawn throwable object
	var throwable_scene = load("res://scenes/elements/ThrowableItem.tscn")
	var throwable_instance = throwable_scene.instantiate()
	
	# Configure throwable
	throwable_instance.item_id = selected_throwable
	# Calcular la posición inicial ajustada con el offset
	var launch_position = global_position + throw_offset.rotated(deg_to_rad(throw_angle)) * get_facing_direction()
	throwable_instance.global_position = launch_position
	throwable_instance.linear_velocity = calculate_throw_velocity()
	#sprite.play("punch")
	# Add to scene and remove from inventory
	get_parent().add_child(throwable_instance)
	Inventario.remove_item(selected_throwable)
	audio_stream_player_2d.play()
	# Reset throw state
	trajectory_line.visible = false
	set_state(States.IDLE)
	selected_throwable = ""

func calculate_throw_velocity() -> Vector2:
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	var angle_rad = deg_to_rad(throw_angle)
	
	var vx = throw_power * cos(angle_rad) * throw_direction.x
	var vy = -throw_power * sin(angle_rad)
	
	return Vector2(vx, vy)

func cancel_throw() -> void:
	trajectory_line.visible = false
	set_state(States.IDLE)

func apply_gravity(delta: float) -> void:
	var gravity_multiplier = 1.0
	
	# Aumentar la gravedad si se mantiene presionado "abajo"
	if Input.is_action_pressed("ui_down") and velocity.y > 0:
		gravity_multiplier = FAST_FALL_GRAVITY_MULTIPLIER
	
	# Aplicar gravedad
	velocity.y += get_gravity() * gravity_multiplier * delta
	
	# Limitar la velocidad de caída
	var max_speed = MAX_FALL_SPEED
	if Input.is_action_pressed("ui_down"):
		max_speed = MAX_FALL_SPEED_FAST
	
	# Estados especiales donde queremos una velocidad terminal diferente
	match state:
		States.WALL_SLIDE:
			max_speed = WALL_SLIDE_MAX_SPEED
		States.WALL_JUMP:
			# Durante el wall jump, permitir la velocidad normal
			pass
	
	velocity.y = min(velocity.y, max_speed)

func apply_fall_damage() -> void:
	if max_fall_velocity > FALL_DAMAGE_THRESHOLD:
		# Calcular el daño basado en la velocidad de caída
		var damage_percent = (max_fall_velocity - FALL_DAMAGE_THRESHOLD) / (FATAL_FALL_VELOCITY - FALL_DAMAGE_THRESHOLD)
		damage_percent = clamp(damage_percent, 0.0, 1.0)
		
		var damage = ceil(damage_percent * MAX_FALL_DAMAGE)
		if damage > 0:
			take_damage(damage)
			print("Daño por caída: ", damage, " (velocidad: ", max_fall_velocity, ")")

func reset_fall_tracking() -> void:
	max_fall_velocity = 0.0
	is_tracking_fall = false

func take_damage(amount: int) -> void:
	health -= amount
	print("Vida restante: ", health)
	start_blinking()  # Inicia el parpadeo al recibir daño
	audio_stream_player_2d.stream = preload("res://audio/Retro Swooosh 07.wav")
	audio_stream_player_2d.play()
	GLOBAL.player_health = health
	if health <= 0:
		die()

func die() -> void:
	# Implementar la lógica de muerte del jugador
	print("El jugador ha muerto")
	#GLOBAL.player_is_alive = false
	# Emitir señal de muerte en lugar de manejar respawn directamente
	emit_signal("player_died")
	queue_free()

# Método para actualizar el último checkpoint
func update_checkpoint(checkpoint_position: Vector2) -> void:
	last_checkpoint_position = checkpoint_position

func start_blinking():
	# Asegúrate de detener cualquier tween previo
	if tween and tween.is_valid():
		tween.kill()
	# Crear un nuevo Tween para el parpadeo
	tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)  # Transparente
	tween.tween_property(sprite, "modulate:a", 1.0, 0.1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)  # Visible
	# Opcional: Conectar al final del parpadeo si necesitas ejecutar algo adicional
	tween.finished.connect(on_blinking_done)

func on_blinking_done():
	# Asegurarse de que el sprite esté visible al final
	sprite.modulate.a = 1.0
	print("Parpadeo terminado")

# Función para inicializar los raycasts en _ready()
func setup_corner_correction():
	# Obtener la altura del CollisionShape2D
	var collision_height = 0.0
	if $CollisionShape2D.shape is CapsuleShape2D:
		collision_height = $CollisionShape2D.shape.height
	elif $CollisionShape2D.shape is RectangleShape2D:
		collision_height = $CollisionShape2D.shape.size.y * 2
	
	# Solo dos rayos horizontales izquierdos
	corner_rays_left = []
	for i in range(2):
		var ray = RayCast2D.new()
		ray.target_position = Vector2(-CORNER_CHECK_DISTANCE, 0)
		# El rayo inferior en la base y el superior un poco más arriba
		ray.position.y = (collision_height/2.6) - (i * 4)  # Aumentado el espaciado a 12
		ray.collision_mask = CORRECTION_COLLISION_MASK
		add_child(ray)
		corner_rays_left.append(ray)
	
	# Solo dos rayos horizontales derechos
	corner_rays_right = []
	for i in range(2):
		var ray = RayCast2D.new()
		ray.target_position = Vector2(CORNER_CHECK_DISTANCE, 0)
		ray.position.y = (collision_height/2.6) - (i * 4)  # Aumentado el espaciado a 12
		ray.collision_mask = CORRECTION_COLLISION_MASK
		add_child(ray)
		corner_rays_right.append(ray)
	
	# Tres rayos verticales para el techo
	ceiling_rays = []
	for i in range(3):
		var ray = RayCast2D.new()
		ray.target_position = Vector2(0, -CORNER_CHECK_DISTANCE)
		# Distribuir los rayos: izquierda, centro y derecha
		ray.position.x = ((i - 1) * 6)
		ray.position.y = -collision_height/22
		ray.collision_mask = CORRECTION_COLLISION_MASK
		add_child(ray)
		ceiling_rays.append(ray)

func can_apply_corner_correction() -> bool:
	# Solo aplicar corrección durante salto o caída
	return state in [States.JUMP, States.FALL]

func check_horizontal_edge(rays: Array[RayCast2D]) -> bool:
	# Solo corregir si el rayo inferior colisiona pero el superior no
	return rays[0].is_colliding() and not rays[1].is_colliding()

func check_ceiling_edge() -> Dictionary:
	var left_ray = ceiling_rays[0]
	var center_ray = ceiling_rays[1]
	var right_ray = ceiling_rays[2]
	
	# Si todos los rayos colisionan, no hacer corrección
	if left_ray.is_colliding() and center_ray.is_colliding() and right_ray.is_colliding():
		return {"should_correct": false, "direction": 0}
	
	# Corrección hacia la derecha si el rayo izquierdo colisiona
	if left_ray.is_colliding() and not center_ray.is_colliding() and not right_ray.is_colliding():
		return {"should_correct": true, "direction": 1}
	
	# Corrección hacia la izquierda si el rayo derecho colisiona
	if right_ray.is_colliding() and not center_ray.is_colliding() and not left_ray.is_colliding():
		return {"should_correct": true, "direction": -1}
	
	return {"should_correct": false, "direction": 0}

func apply_corner_correction() -> bool:
	if not can_apply_corner_correction():
		return false
		
	var was_corrected = false
	
	# Corrección horizontal (para bordes de paredes)
	if velocity.x != 0:
		var rays = corner_rays_right if velocity.x > 0 else corner_rays_left
		if check_horizontal_edge(rays):
			position.y -= CORNER_CORRECTION_VERTICAL
			was_corrected = true
	
	# Corrección vertical (para techos)
	if velocity.y < 0:  # Solo cuando estamos subiendo
		var ceiling_correction = check_ceiling_edge()
		if ceiling_correction.should_correct:
			position.x += CORNER_CORRECTION_HORIZONTAL * ceiling_correction.direction
			was_corrected = true
	
	return was_corrected

func check_coyote_time() -> void:
	# Start coyote timer when player leaves the ground
	if not is_on_floor() and was_on_floor and not state in [States.CLIMB, States.CLIMB_LADDER, States.HANG]:
		coyote_timer.start()
		print("inicia coyote timer")
	was_on_floor = is_on_floor()

func handle_stamina(delta: float) -> void:
	var is_using_stamina = false
	
	# Verificar si estamos en un estado que consume stamina
	match state:
		States.RUN:
			if Input.is_action_pressed("shift") and (Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right")):
				drain_stamina(STAMINA_DRAIN_RATES["RUN"] * delta)
				is_using_stamina = true
		States.WALL_SLIDE:
			drain_stamina(STAMINA_DRAIN_RATES["WALL_SLIDE"] * delta)
			is_using_stamina = true
		States.CLIMB:
			drain_stamina(STAMINA_DRAIN_RATES["CLIMB"] * delta)
			is_using_stamina = true
		States.PUSH:
			drain_stamina(STAMINA_DRAIN_RATES["PUSH"] * delta)
			is_using_stamina = true
		States.PULL:
			drain_stamina(STAMINA_DRAIN_RATES["PULL"] * delta)
			is_using_stamina = true
		States.JUMP:
			if Input.is_action_pressed("shift"):
				drain_stamina(STAMINA_DRAIN_RATES["JUMP_RUN"] * delta)
			else:
				drain_stamina(STAMINA_DRAIN_RATES["JUMP"] * delta)
			is_using_stamina = true
		States.FALL:
			if previous_state == States.JUMP:
				if Input.is_action_pressed("shift"):
					drain_stamina(STAMINA_DRAIN_RATES["JUMP_RUN"] * delta)
				else:
					drain_stamina(STAMINA_DRAIN_RATES["JUMP"] * delta)
				is_using_stamina = true
	# Manejar la recuperación de stamina
	if is_using_stamina:
		stamina_recovery_timer = STAMINA_RECOVERY_DELAY
	else:
		if stamina_recovery_timer > 0:
			stamina_recovery_timer -= delta
		else:
			recover_stamina(STAMINA_RECOVERY_RATE * delta)
	
	# Actualizar la variable global
	GLOBAL.player_stamina = current_stamina

func drain_stamina(amount: float) -> void:
	if can_use_stamina and current_stamina > 0:
		current_stamina = max(0, current_stamina - amount)
		if current_stamina < MIN_STAMINA_FOR_ACTIONS:
			can_use_stamina = false

func recover_stamina(amount: float) -> void:
	current_stamina = min(MAX_STAMINA, current_stamina + amount)
	if current_stamina >= MIN_STAMINA_FOR_ACTIONS:
		can_use_stamina = true

func handle_attack_state() -> void:
	velocity = Vector2.ZERO
	# Detectar golpe
	if sprite.frame == 5 and sprite.animation == "punch" and can_attack:
		var bodies = $AnimatedSprite2D/AttackArea2D.get_overlapping_bodies()
		print("en frame 5")
		print("Cuerpos detectados: ", bodies.size())
		for body in bodies:
			if body.is_in_group("Enemy"):
				print("haciendo daño al enemigo")
				body.take_damage(damage)
				can_attack = false
			break

func _on_attack_animation_finished():
	# Cuando la animación de punch termina, volver a idle
	if state == States.ATTACK:
		set_state(States.IDLE)


func handle_box_interaction() -> void:
	if GLOBAL.can_move_boxes:
		if caja_cercana:
			if Input.is_action_pressed("interact"):
				# Si no estamos en ningún estado de interacción con la caja
				if state != States.HOLD_BOX and state != States.PUSH and state != States.PULL:
					set_state(States.HOLD_BOX)
				
				# Si estamos sosteniendo la caja y nos movemos
				if state == States.HOLD_BOX:
					var direction = Input.get_axis("ui_left", "ui_right")
					if direction != 0:
						# Verificamos la dirección del jugador en relación a la caja
						var box_direction = sign(caja_cercana.global_position.x - global_position.x)
						var moving_direction = sign(direction)
						
						# Si la dirección del movimiento es hacia la caja, empujamos
						if box_direction == moving_direction:
							set_state(States.PUSH)
						else:
							set_state(States.PULL)
			else:
				if state in [States.HOLD_BOX, States.PUSH, States.PULL]:
					set_state(States.IDLE)
					if caja_cercana:
						caja_cercana.stop_moving()

func handle_hold_box_state() -> void:
	velocity.x = 0
	if not caja_cercana or not Input.is_action_pressed("interact"):
		set_state(States.IDLE)
		if caja_cercana:
			caja_cercana.stop_moving()

func handle_push_state() -> void:
	if not caja_cercana or not Input.is_action_pressed("interact"):
		set_state(States.IDLE)
		if caja_cercana:
			caja_cercana.stop_moving()
		return
	# Incrementar el temporizador
	step_timer += get_physics_process_delta_time()
	
	# Verificar si está en movimiento y ha pasado suficiente tiempo desde el último paso
	if step_timer >= step_interval:
		audio_stream_player_2d.stream = preload("res://audio/Retro FootStep 03.wav")
		audio_stream_player_2d.play()
		
		# Reiniciar el temporizador
		step_timer = 0.0
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction == 0:
		set_state(States.HOLD_BOX)
		if caja_cercana:
			caja_cercana.stop_moving()
		return
	elif !can_use_stamina or current_stamina < MIN_STAMINA_FOR_ACTIONS:
		return
	# Usamos una velocidad constante para empujar
	velocity.x = direction * (SPEED * 0.5)
	if caja_cercana:
		caja_cercana.is_being_moved = true
		if caja_cercana is GravityBox:
			caja_cercana.set_velocity(velocity.x * 0.8)
		else:
			caja_cercana.current_velocity = velocity.x * 0.8

func handle_pull_state() -> void:
	if not caja_cercana or not Input.is_action_pressed("interact"):
		set_state(States.IDLE)
		if caja_cercana:
			caja_cercana.stop_moving()
		return
	
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction == 0:
		set_state(States.HOLD_BOX)
		if caja_cercana:
			caja_cercana.stop_moving()
		return
	elif !can_use_stamina or current_stamina < MIN_STAMINA_FOR_ACTIONS:
		return
	# Incrementar el temporizador
	step_timer += get_physics_process_delta_time()
	
	# Verificar si está en movimiento y ha pasado suficiente tiempo desde el último paso
	if step_timer >= step_interval:
		audio_stream_player_2d.stream = preload("res://audio/Retro FootStep 03.wav")
		audio_stream_player_2d.play()
		
		# Reiniciar el temporizador
		step_timer = 0.0
	# Usamos una velocidad constante para jalar
	velocity.x = direction * (SPEED * 0.4)
	if caja_cercana:
		caja_cercana.is_being_moved = true
		if caja_cercana is GravityBox:
			caja_cercana.set_velocity(velocity.x)
		else:
			caja_cercana.current_velocity = velocity.x

func handle_fall_state() -> void:
	if is_on_floor():
		if max_fall_velocity > FATAL_FALL_VELOCITY:
			die()
		elif max_fall_velocity > FALL_DAMAGE_THRESHOLD:
			# animación de aterrizaje para despues
			pass
		set_state(States.IDLE)

func handle_wall_jump_state():
	# El movimiento ya está establecido en handle_jump()
	# Solo necesitamos manejar la transición a otros estados
	if is_on_floor():
		set_state(States.IDLE)
	elif can_wall_slide():
		set_state(States.WALL_SLIDE)
	elif velocity.y > 0:  # Si está cayendo después del wall jump
		set_state(States.FALL)

func handle_movement() -> void:
	var input_direction = Vector2.ZERO
	input_direction.x = Input.get_axis("ui_left", "ui_right")
	input_direction.y = Input.get_axis("ui_up", "ui_down")
	
	if input_direction != Vector2.ZERO:
		last_movement_direction = input_direction.normalized()
	var direction = Input.get_axis("ui_left", "ui_right")
	
	var target_speed = 0.0
	var current_acceleration = 0.0
	var is_turning = sign(velocity.x) != 0 and sign(input_direction.x) != 0 and sign(velocity.x) != sign(input_direction.x)
	# Solo aplicamos el movimiento si no estamos en estados específicos
	if not state in [States.WALL_SLIDE, States.CLIMB, States.CLIMB_LADDER, States.HANG, States.OPEN_DOOR, States.WALL_JUMP]:
		# Determinar la velocidad objetivo
		if input_direction.x != 0:
			target_speed = input_direction.x * (SPEED_RUN if Input.is_action_pressed("shift") and state != States.CROUCH else SPEED)
			
			# Ajustar la velocidad si está agachado
			if state == States.CROUCH:
				target_speed *= 0.5
		
		# Determinar la aceleración a usar
		if is_on_floor():
			if is_turning:
				current_acceleration = ACCELERATION * TURN_ACCELERATION_MULTIPLIER
			else:
				current_acceleration = ACCELERATION
		else:
			if is_turning:
				current_acceleration = AIR_ACCELERATION * TURN_ACCELERATION_MULTIPLIER
			else:
				current_acceleration = AIR_ACCELERATION
		
		# Aplicar aceleración o desaceleración
		if input_direction.x != 0:
			# Aceleración
			velocity.x = move_toward(velocity.x, target_speed, current_acceleration * get_physics_process_delta_time())
		else:
			# Desaceleración
			var current_deceleration = DECELERATION if is_on_floor() else AIR_DECELERATION
			velocity.x = move_toward(velocity.x, 0, current_deceleration * get_physics_process_delta_time())

	
	'''
	# Solo aplicamos el movimiento si no estamos en estados específicos
	if not state in [States.WALL_SLIDE, States.CLIMB, States.CLIMB_LADDER, States.HANG, States.OPEN_DOOR, States.WALL_JUMP]:
		if direction:
			if Input.is_action_pressed("shift") and state != States.CROUCH:
				velocity.x = direction * SPEED_RUN
			elif state == States.WALL_SLIDE:
				pass
			else:
				velocity.x = direction * SPEED
			if state == States.CROUCH:
				sprite.play("crouch_walk")
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

func handle_jump():
	# Debug para ver cuándo podemos saltar
	if Input.is_action_just_pressed("ui_accept"):
		print("Presionó salto")
		print("En suelo: ", is_on_floor())
		print("Coyote time: ", coyote_timer.time_left)
	#MOVER ESTO A HANDLE WALL SLIDE
	# Para salto en la pared
	if Input.is_action_just_pressed("ui_accept") and state == States.WALL_SLIDE:
		print("Saltando en la pared!")
		var facing_right = not $AnimatedSprite2D.flip_h
		# Si está mirando a la derecha (en pared izquierda), salta a la derecha
		# Si está mirando a la izquierda (en pared derecha), salta a la izquierda
		velocity.x = 0
		if facing_right:
			velocity.x = -WALL_JUMP_FORCE.x  # Salta hacia la izquierda
			print("impulso a la izquierda")
		else:
			velocity.x = WALL_JUMP_FORCE.x   # Salta hacia la derecha
			print("impulso a la derecha")
		velocity.y = WALL_JUMP_FORCE.y  # Impulso hacia arriba
		set_state(States.WALL_JUMP)
		#return  # Salir para evitar conflictos con otros saltos
	
	# Verificar si podemos saltar desde el suelo o con coyote time
	if Input.is_action_just_pressed("ui_accept") and (is_on_floor() or !coyote_timer.is_stopped()) and state in [States.IDLE, States.WALK, States.RUN, States.FALL]:
		print("Saltando desde el suelo!")
		velocity.y = JUMP_VELOCITY_RUN if Input.is_action_pressed("shift") else JUMP_VELOCITY
		set_state(States.JUMP)
		coyote_timer.stop()  # Detener el coyote time si saltamos desde el suelo
		print("se detiene el coyote timer")
'''
# Modifica la función handle_jump para simplificar el wall jump
func handle_jump():
	if GLOBAL.can_jump:
		# Actualizar el estado del botón de salto
		if Input.is_action_just_pressed("ui_accept"):
			is_jump_pressed = true
			# Iniciar el buffer del salto si no estamos en el suelo
			if not is_on_floor() and state != States.WALL_SLIDE:
				has_buffered_jump = true
				jump_buffer_timer.start()
		if Input.is_action_just_released("ui_accept"):
			is_jump_pressed = false
			# Solo cortar el salto si estamos ascendiendo y podemos cortarlo
			if velocity.y < 0 and can_cut_jump:
				velocity.y = max(velocity.y * JUMP_CUT_MULTIPLIER, MIN_JUMP_VELOCITY)
				can_cut_jump = false
		# Ejecutar el salto si:
		# 1. Acabamos de presionar el botón y podemos saltar
		# 2. Tenemos un salto en buffer y acabamos de tocar el suelo
		if (Input.is_action_just_pressed("ui_accept") or has_buffered_jump) and ((is_on_floor() or !coyote_timer.is_stopped()) and state in [States.IDLE, States.WALK, States.RUN, States.FALL]):
			print("Saltando desde el suelo!")
			velocity.y = JUMP_VELOCITY_RUN if Input.is_action_pressed("shift") else JUMP_VELOCITY
			set_state(States.JUMP)
			can_cut_jump = true
			has_buffered_jump = false
			jump_buffer_timer.stop()
			coyote_timer.stop()
			print("se detiene el coyote timer")

func handle_state_transitions():
	if state in [States.OPEN_DOOR, States.PUSH, States.PULL, States.THROW]:
		return  # No permitir transiciones mientras realiza estas acciones
	# Si tocamos el suelo y tenemos un salto en buffer, no cambiamos a IDLE
	if has_buffered_jump and is_on_floor():
		handle_jump()
		return
	# Primero, comprobar específicamente la escalada de esquinas
	if can_climb_corner():
		print("Condición de escalada de esquina detectada")
		set_state(States.CLIMB)
		return
	if can_hang():
		set_state(States.HANG)
	elif can_wall_slide() and state != States.WALL_SLIDE:
		print("puede wall slide")
		set_state(States.WALL_SLIDE)
	elif can_climb_ladder():
		set_state(States.CLIMB_LADDER)
	elif is_on_floor():
		if Input.is_action_pressed("crouch") and GLOBAL.can_crouch:
			set_state(States.CROUCH)
		elif Input.is_action_just_released("crouch"):
			#stand_up()
			set_state(States.IDLE)
		elif Input.is_action_pressed("shift") and (Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right")) and GLOBAL.can_run:
			set_state(States.RUN)
		elif Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right") and GLOBAL.can_walk:
			set_state(States.WALK)
		elif velocity.x == 0 and not state in [States.CLIMB_LADDER, States.HANG, States.CLIMB, States.ATTACK]:
			set_state(States.IDLE)
	elif not is_on_floor():
		if state == States.WALL_SLIDE or state == States.WALL_JUMP:
			pass
		elif state == States.JUMP:
			pass
		elif not state in [States.CLIMB_LADDER, States.HANG, States.CLIMB, States.JUMP]:
			set_state(States.FALL)

func handle_idle_state():
	velocity.x = move_toward(velocity.x, 0, SPEED)
	#if Input.is_action_just_pressed("ui_accept") and (is_on_floor() or coyote_time > 0):
		#velocity.y = JUMP_VELOCITY
		#set_state(States.JUMP)

func handle_walk_state():
	# Incrementar el temporizador
	step_timer += get_physics_process_delta_time()
	
	# Verificar si está en movimiento y ha pasado suficiente tiempo desde el último paso
	if step_timer >= step_interval:
		audio_stream_player_2d.stream = preload("res://audio/Retro FootStep 03.wav")
		audio_stream_player_2d.play()
		
		# Reiniciar el temporizador
		step_timer = 0.0

func handle_run_state():
	if !can_use_stamina or current_stamina < MIN_STAMINA_FOR_ACTIONS:
		set_state(States.WALK)
		return
	# Incrementar el temporizador
	step_timer += get_physics_process_delta_time()
	
	# Verificar si está en movimiento y ha pasado suficiente tiempo desde el último paso
	if step_timer >= step_interval_run:
		audio_stream_player_2d.stream = preload("res://audio/Retro FootStep 03.wav")
		audio_stream_player_2d.play()
		
		# Reiniciar el temporizador
		step_timer = 0.0
	#var direction = Input.get_axis("ui_left", "ui_right")
	#velocity.x = direction * SPEED_RUN
	#if Input.is_action_just_pressed("ui_accept") and (is_on_floor() or coyote_time > 0):
		#velocity.y = JUMP_VELOCITY_RUN
		#set_state(States.JUMP)

func handle_jump_state():
	#var direction = Input.get_axis("ui_left", "ui_right")
	#if previous_state != States.WALL_SLIDE:
		#velocity.x = direction * (SPEED_RUN if Input.is_action_pressed("shift") else SPEED)
	
	# Si el jugador suelta el botón de salto mientras sube, reducir la velocidad
	if not is_jump_pressed and velocity.y < 0 and can_cut_jump:
		velocity.y = max(velocity.y * JUMP_CUT_MULTIPLIER, MIN_JUMP_VELOCITY)
		can_cut_jump = false

func handle_crouch_state():
	var direction = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * (SPEED / 1.5)
	
	# Cambiar animación en función de la entrada del jugador
	if direction == 0:  # Si no hay entrada horizontal
		if GLOBAL.is_in_real_world:
			sprite.play("crouch_idle")
		else:
			sprite.play("crouch_idle_time")
	else:  # Si hay entrada horizontal
		if GLOBAL.is_in_real_world:
			sprite.play("crouch_walk")
		else:
			sprite.play("crouch_walk_time")

'''
func handle_wall_slide_state():
	var direction = Input.get_axis("ui_left", "ui_right")
	var facing_right = not $AnimatedSprite2D.flip_h
	var other_side : bool = false
	# Si está mirando a la derecha, apunta hacia la derecha
	if facing_right:
		if Input.is_action_just_pressed("ui_right"):
			other_side = true
	else:
		if Input.is_action_just_pressed("ui_left"):
			other_side = true
	if is_on_floor() or other_side:
		other_side = false
		set_state(States.IDLE)
'''
# Modifica la función handle_wall_slide_state
func handle_wall_slide_state():
	if !can_use_stamina or current_stamina < MIN_STAMINA_FOR_ACTIONS:
		set_state(States.FALL)
		return
	# Si presionamos en dirección contraria a la pared, salimos del wall slide
	var direction = Input.get_axis("ui_left", "ui_right")
	var facing_right = not $AnimatedSprite2D.flip_h
	# Incrementar el temporizador
	step_timer += get_physics_process_delta_time()
	
	# Verificar si está en movimiento y ha pasado suficiente tiempo desde el último paso
	if step_timer >= step_interval:
		audio_stream_player_2d.stream = preload("res://audio/Retro Swooosh 16.wav")
		audio_stream_player_2d.play()
		
		# Reiniciar el temporizador
		step_timer = 0.0
	# Si está en la pared derecha y presiona derecha, o en la pared izquierda y presiona izquierda
	# (intentando presionar contra la pared), mantenemos el wall slide
	if (facing_right and direction > 0) or (not facing_right and direction < 0):
		if velocity.y > 0:  # Solo aplicamos la gravedad reducida si estamos cayendo
			velocity.y = min(WALL_SLIDE_GRAVITY, WALL_SLIDE_MAX_SPEED)
	else:
		# Si presiona en dirección contraria o no presiona ninguna dirección
		set_state(States.FALL)
		# Dar un pequeño impulso en la dirección opuesta
		velocity.x = SPEED * (-0.3 if facing_right else 0.3)
	
	# Si está en el suelo, volver a idle
	if is_on_floor():
		if has_buffered_jump:
			handle_jump()
		else:
			set_state(States.IDLE)
	if Input.is_action_just_pressed("ui_accept"):
		# Wall jump
		if state == States.WALL_SLIDE:
			print("Saltando en la pared!")
			velocity = Vector2.ZERO
			
			# Si está en la pared derecha, salta hacia la izquierda
			# Si está en la pared izquierda, salta hacia la derecha
			if facing_right:
				velocity.x = -WALL_JUMP_FORCE.x  # Salta hacia la izquierda
			else:
				velocity.x = WALL_JUMP_FORCE.x   # Salta hacia la derecha
			
			velocity.y = WALL_JUMP_FORCE.y  # Impulso hacia arriba
			has_buffered_jump = false  # Cancelar cualquier buffer al hacer wall jump
			jump_buffer_timer.stop()
			set_state(States.WALL_JUMP)
			return

func handle_hang_state():
	velocity = Vector2.ZERO
	if Input.is_action_pressed("shift"):
		# Al presionar shift, forzar caída
		velocity.y = 100  # Puedes ajustar este valor según qué tan rápido quieres que caiga
		set_state(States.FALL)

func handle_open_door_state():
	if puerta_cercana and not puerta_cercana.opened:
		puerta_cercana.try_open()
	set_state(previous_state)

func handle_climb_state(delta: float) -> void:
	if !can_use_stamina or current_stamina < MIN_STAMINA_FOR_ACTIONS:
		set_state(States.FALL)
		return
	
	# Verificar si está escalando una caja
	var climbing_object = front_raycast.get_collider() if front_raycast.is_colliding() else null
	var is_climbing_box = climbing_object and climbing_object.is_in_group("Boxes")
	
	# Debug específico para cajas
	if climb_box:
		print("Escalando caja: ", climbing_object)
	
	# Control más preciso de la velocidad de escalada
	var climb_speed = CLIMB_SPEED
	
	# Si está escalando una caja, reducir la velocidad para más control
	if climb_box:
		climb_speed *= 1.5  # Reducir la velocidad a la mitad para cajas
	
	velocity.y = -climb_speed
	
	# Verificar condiciones de finalización de escalada
	if !down_front_raycast.is_colliding() or !is_on_wall():
		print("Finalizando escalada")
		
		# Ajuste de posición más preciso
		var collision_point = down_front_raycast.get_collision_point()
		var facing_left = $AnimatedSprite2D.flip_h
		
		if climb_box:
			if facing_left:
				position.x = collision_point.x - 10
			else:
				position.x = collision_point.x + 10
		else:
			if facing_left:
				position.x = collision_point.x - 10
			else:
				position.x = collision_point.x + 10
		
		# Limitar la altura de la escalada para evitar elevación excesiva
		#if climb_box:
			#position.y = min(position.y, collision_point.y + 10)  # Limitar subida vertical
		
		finish_climb()
	
	# Mecanismo de seguridad para salir del estado de escalada
	if not already_climb:
		set_state(States.IDLE)
	
	'''
	# Usar already_climb para mantener la referencia al objeto
	var climbing_object = front_raycast.get_collider() if front_raycast.is_colliding() else null
	
	# Controlar la velocidad de escalada
	velocity.y = -CLIMB_SPEED  # Usa una velocidad constante en lugar de mover la posición directamente
	
	# Verifica si la escalada ha terminado
	if !down_front_raycast.is_colliding() or !is_on_wall():
		print("Escalada completada")
		
		# Ajustar la posición final de manera más precisa
		var collision_point = down_front_raycast.get_collision_point()
		
		# Ajuste de posición dependiendo de la dirección
		var facing_left = $AnimatedSprite2D.flip_h
		if facing_left:
			position.x = collision_point.x - 10  # Ajuste fino del lado izquierdo
		else:
			position.x = collision_point.x + 10  # Ajuste fino del lado derecho
		
		finish_climb()
	
	# Mecanismo de seguridad para salir del estado de escalada
	if not already_climb:
		set_state(States.IDLE)
	
	# Usar already_climb para mantener la referencia al objeto
	var climbing_object = front_raycast.get_collider() if front_raycast.is_colliding() else null
	
	# Detecta el punto superior de la esquina y mueve al personaje verticalmente
	position.y -= CLIMB_HEIGHT * delta
	
	# Verifica si la animación de escalada ha terminado basándose en las colisiones y la pared
	if !down_front_raycast.is_colliding() or !is_on_wall():
		print("escalo")
		# Calcula el tamaño del objeto para ajustar la posición después de escalar
		var ledge_size: Vector2
		if climbing_object and climbing_object.is_in_group("Boxes"):
			printerr("Esta intentando escalar caja")
			# Si está escalando una caja, ajustar la posición de manera diferente
			ledge_size = Vector2(
				climbing_object.get_node("CollisionShape2D").shape.extents.x * 2, 
				climbing_object.get_node("CollisionShape2D").shape.extents.y * 2
			)
		elif $CollisionShape2D.shape is RectangleShape2D:
			ledge_size = $CollisionShape2D.shape.extents * 2
		else:
			print("Tipo de shape no soportado para detección de esquinas.")
		
		# Posición final en la esquina, dependiendo de la dirección
		var facing_left = $AnimatedSprite2D.flip_h
		var collision_point = down_front_raycast.get_collision_point()
		if facing_left:
			# Ajusta la posición horizontal para alinearla con el borde de la esquina
			position.x = collision_point.x - ledge_size.x * 0.5 + 6
		else:
			position.x = collision_point.x + ledge_size.x * 0.5 - 6
		
		# Termina la escalada y establece el personaje sobre la esquina
		finish_climb()
	
	# Agregar un mecanismo de seguridad para salir del estado de escalada
	if not already_climb:
		set_state(States.IDLE)
'''
func finish_climb() -> void:
	print("terminó de escalar")
	# Ajuste fino en la posición Y para asegurarse de que esté sobre el borde
	if climb_box:
		position.y -= 12
	else:
		position.y -= 30
	set_state(States.IDLE)
	velocity = Vector2.ZERO  # Reinicia la velocidad para evitar movimiento no deseado

func handle_climb_ladder_state() -> void:
	var vertical_direction := Input.get_axis("ui_up", "ui_down")
	var horizontal_direction := Input.get_axis("ui_left", "ui_right")
	# Control vertical en la escalera
	if vertical_direction != 0:
		velocity.y = vertical_direction * SPEED / 2
		sprite.play()
	else:
		velocity.y = 0  # Detenerse verticalmente si no hay entrada
		sprite.stop()
	# Control horizontal mientras está en la escalera
	velocity.x = horizontal_direction * SPEED / 2
	#move_and_slide()
	if not ladder_ray_cast.is_colliding():
		set_state(States.IDLE)

func set_state(new_state: int) -> void:
	#print("Player: Cambiando estado de ", state, " a ", new_state)  # Debug
	# Al entrar en estado de lanzamiento
	if new_state == States.THROW:
		is_trajectory_visible = true
		throw_direction = last_movement_direction.normalized()  # Usar la última dirección de movimiento
		update_throw_trajectory()
	else:
		is_trajectory_visible = false
		trajectory_line.clear_points()
		trajectory_line.visible = false
	if state == new_state:
		return
	previous_state = state
	state = new_state
	
	match state:
		States.IDLE:
			print("idle")
			if GLOBAL.is_in_real_world:
				sprite.play("idle")
			else:
				sprite.play("idle_time")
			adjust_collision_shape()
		States.WALK:
			print("walk")
			if GLOBAL.is_in_real_world:
				sprite.play("walk")
			else:
				sprite.play("walk_time")
			adjust_collision_shape()
		States.RUN:
			print("run")
			if GLOBAL.is_in_real_world:
				sprite.play("run")
			else:
				sprite.play("run_time")
			adjust_collision_shape()
		States.JUMP:
			print("jump")
			if GLOBAL.is_in_real_world:
				sprite.play("jump")
			else:
				sprite.play("jump_time")
			audio_stream_player_2d.stream = preload("res://audio/Retro Jump StereoUP Simple 05.wav")
			audio_stream_player_2d.play()
			adjust_collision_shape()
		States.CROUCH:
			print("crouch")
			#crouch()
			if GLOBAL.is_in_real_world:
				sprite.play("crouch_idle")
			else:
				sprite.play("crouch_idle_time")
			adjust_collision_shape(true)
		States.WALL_SLIDE:
			print("wall slide")
			if GLOBAL.is_in_real_world:
				sprite.play("wall_slide")
			else:
				sprite.play("wall_slide_time")
			adjust_collision_shape(false, true)
		States.WALL_JUMP:
			print("wall jump")
			adjust_collision_shape()
			audio_stream_player_2d.stream = preload("res://audio/Retro Jump StereoUP Simple 05.wav")
			audio_stream_player_2d.play()
			#sprite.play("wall_jump")  # Si tienes 
		States.CLIMB:
			print("climb")
			if GLOBAL.is_in_real_world:
				sprite.play("climb")
			else:
				sprite.play("climb_time")
			adjust_collision_shape()
		States.CLIMB_LADDER:
			print("climb ladder")
			if GLOBAL.is_in_real_world:
				sprite.play("climb_ladder")
			else:
				sprite.play("climb_ladder_time")
			adjust_collision_shape()
		States.HANG:
			print("hang")
			if GLOBAL.is_in_real_world:
				sprite.play("hang")
			else:
				sprite.play("hang_time")
			adjust_collision_shape()
		States.OPEN_DOOR:
			print("open_door")
			adjust_collision_shape()
		States.FALL:
			print("falling")
			if GLOBAL.is_in_real_world:
				sprite.play("fall")
			else:
				sprite.play("fall_time")
			adjust_collision_shape()
		States.HOLD_BOX:
			print("holding box")
			adjust_collision_shape()
			if GLOBAL.is_in_real_world:
				sprite.play("push_idle")
			else:
				sprite.play("push_idle_time")
		States.PUSH:
			print("pushing")
			adjust_collision_shape()
			if GLOBAL.is_in_real_world:
				sprite.play("push")
			else:
				sprite.play("push_time")
		States.PULL:
			print("pulling")
			adjust_collision_shape()
			if GLOBAL.is_in_real_world:
				sprite.play("pull")
			else:
				sprite.play("pull_time")
		States.THROW:
			adjust_collision_shape()
			print("throwing")
			velocity = Vector2.ZERO
			if GLOBAL.is_in_real_world:
				sprite.play("throwing")
			else:
				sprite.play("throwing_time")
			audio_stream_player_2d.stream = preload("res://audio/Retro Impact Punch Hurt 01.wav")
		States.ATTACK:
			if GLOBAL.is_in_real_world:
				sprite.play("punch")
			else:
				sprite.play("punch_time")
			can_attack = true
			print("attacking")
			audio_stream_player_2d.stream = preload("res://audio/Retro Impact Punch Hurt 01.wav")
			audio_stream_player_2d.play()
			#sprite.play("idle")
	#if state == States.WALL_SLIDE:
			#print(" cambia gravedad para deslizar")
			#velocity.y += WALL_SLIDE_GRAVITY * delta_aux

func set_on_platform(platform):
	current_platform = platform

# Manejar cercanía a una caja
func _on_player_near_box(caja: Node, near: bool) -> void:
	if near:
		print("jugador cerca de la caja")
		caja_cercana = caja
	else:
		print("jugador lejos de la caja")
		caja_cercana = null

func _on_player_near_door(door):
	# Almacena la puerta a la que el jugador se acercó
	puerta_cercana = door

func interact() -> void:
	if GLOBAL.is_in_interactive_area:
		print("estoy intentando interactuar")
		if puerta_cercana:
			print("Estoy intentando interactuar con una puerta")
			if puerta_cercana.opened == false:
				var inventario = get_node("/root/Inventario")
				if inventario.has_item(puerta_cercana.required_key_id):
					puerta_cercana.try_open()
				else:
					if state == States.OPEN_DOOR:
						audio_stream_player_2d.stream = preload("res://audio/Retro Event Wrong Simple 03.wav")
						audio_stream_player_2d.play()
			else:
				print("No hay puerta en el área o ya esta abierta")
		else:
			print("no es puerta")
	else:
		print("no hay area de interaccion")

func change()-> void:
	if GLOBAL.is_in_real_world == false:
		GLOBAL.is_in_real_world = true
		# Cambiar el color de fondo global
		RenderingServer.set_default_clear_color(Color("#e1e5f2"))
		exit_dimension_shift()
	elif GLOBAL.is_in_real_world == true:
		GLOBAL.is_in_real_world = false
		# Cambiar el color de fondo global
		RenderingServer.set_default_clear_color(Color("#EBD4CB"))
		start_dimension_shift()

'''
func crouch() -> void:
	collision_shape.shape.extents = CROUCH_COLLISION_SIZE / 2
	print("se reduce colision")

func stand_up() -> void:
	collision_shape.shape.extents = STAND_COLLISION_SIZE / 2
	print("vuelve al tamaño normal")
'''
func can_hang() -> bool:
	# Detecta la esquina: el raycast inferior colisiona y el superior no
	#return front_raycast.is_colliding() and !top_raycast.is_colliding() and !up_front_raycast.is_colliding() and is_on_wall() and (!is_on_floor() or !front_raycast.get_collider().is_in_group("Boxes"))
	var can_hang_result = (
		front_raycast.is_colliding() and 
		!top_raycast.is_colliding() and 
		!up_front_raycast.is_colliding() and 
		is_on_wall() and 
		(
			!is_on_floor() or 
			!front_raycast.get_collider().is_in_group("Boxes")
		)
	)
	
	# Añade estos prints para depuración
	if can_hang_result:
		print("Colgándose de: ", front_raycast.get_collider())
		print("Es una caja: ", front_raycast.get_collider().is_in_group("Boxes"))
		if front_raycast.get_collider().is_in_group("Boxes"):
			climb_box = true
		else:
			climb_box = false
	return can_hang_result

func can_climb_ladder() -> bool:
	return ladder_ray_cast.is_colliding() and (Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"))

func can_wall_slide() -> bool:
	return not is_on_floor() and is_on_wall() and front_raycast.is_colliding() and velocity.y > 0

func can_climb_corner() -> bool:
	# Almacenar el objeto antes de las verificaciones
	var climbing_object = front_raycast.get_collider()
	
	var is_climbing_box = (climbing_object and climbing_object.is_in_group("Boxes"))
	
	var can_climb_result = (
		front_raycast.is_colliding() and 
		(
			is_climbing_box or 
			is_on_wall()
		) and 
		!top_raycast.is_colliding() and 
		# Condición diferente para cajas vs paredes normales
		(
			(is_climbing_box and Input.is_action_pressed("ui_accept")) or 
			(!is_climbing_box and Input.is_action_just_pressed("ui_accept"))
		) and state == States.HANG
	)
	
	if can_climb_result:
		# Almacenar una referencia global al objeto que se va a escalar
		already_climb = true
	
	# Logs de depuración detallados
	if can_climb_result:
		printerr("Condiciones de escalada:")
		print("- Objeto frente al jugador: ", climbing_object)
		print("- Es una caja: ", is_climbing_box)
		print("- Está en una pared: ", is_on_wall())
	
	return can_climb_result

# Comprobar si el jugador está frente a la caja
func is_facing_box(caja: Node) -> bool:
	var direction_to_box = caja.global_position.x - global_position.x
	return (direction_to_box > 0 and not $AnimatedSprite2D.flip_h) or (direction_to_box < 0 and $AnimatedSprite2D.flip_h)

func get_facing_direction() -> Vector2:
	return Vector2(1 if not $AnimatedSprite2D.flip_h else -1, 0)

func update_raycasts_direction() -> void:
	# Asume que el personaje tiene un AnimatedSprite2D
	var facing_right = not $AnimatedSprite2D.flip_h
	# Si está mirando a la derecha, apunta hacia la derecha
	if !facing_right:
		front_raycast.target_position = Vector2(-15, 0)
		top_raycast.target_position = Vector2(-14, -46)
		up_front_raycast.target_position = Vector2(-15, 0)
		down_front_raycast.target_position = Vector2(-15, 0)
	else:
		# Si está mirando a la izquierda, `cast_to` apunta hacia la izquierda
		front_raycast.target_position = Vector2(15, 0)  # Ajusta el valor según el alcance deseado
		top_raycast.target_position = Vector2(14, -46)  # Ajusta según la posición deseada
		up_front_raycast.target_position = Vector2(15, 0)
		down_front_raycast.target_position = Vector2(15, 0)

func update_sprite_direction() -> void:
	if previous_state == States.PULL:
		return
	if velocity.x < 0:
		$AnimatedSprite2D.flip_h = true
		# Invertir la escala para cambiar la dirección del área de ataque
		$AnimatedSprite2D/AttackArea2D.scale.x = -1
		update_raycasts_direction()
	elif velocity.x > 0:
		$AnimatedSprite2D.flip_h = false
		# Invertir la escala para cambiar la dirección del área de ataque
		$AnimatedSprite2D/AttackArea2D.scale.x = 1
		update_raycasts_direction()

func _on_jump_buffer_timer_timeout() -> void:
	has_buffered_jump = false

func _on_dimension_timer_timeout() -> void:
	pass
	#change()
