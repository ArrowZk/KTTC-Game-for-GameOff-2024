extends CharacterBody2D
class_name Agent


enum States { IDLE, PATROL, CHASE, ATTACK, JUMP }
var state: States = States.IDLE: set = set_state

@export_group("Options")
@export var health : int = 80
@export var score : int = 300
@export var is_patroling : bool
@export var damage : int = 10

@export_group("Motion")
@export var speed : int = 30
@export var gravity :int = 16

@onready var front_raycast = $AnimatedSprite2D/FrontRayCast2D
@onready var front_bottom_raycast = $AnimatedSprite2D/FrontBottomRayCast2D
@onready var attack_area = $AnimatedSprite2D/PunchingArea2D
@onready var chasing_timer: Timer = $ChasingTimer

const JUMP_VELOCITY = -180.0
const MAX_JUMP_HEIGHT = 64 # Altura máxima del salto en píxeles
var initial_jump_position : float = 0.0
var previous_state := state
var attack_timer = Timer.new()
var direction :int = 1
var previous_safe_position : Vector2
var can_attack = false
var is_at_edge : bool = false
var needs_correction : bool = false
var door_in_the_way : bool = false #para comprobar si hay puertas y no var a travez de ellas
var is_watching : bool = false
const WALL_SLIDE_GRAVITY = 10.0

var tween: Tween = null  # Referencia al Tween

func _ready() -> void:
	# Guardar la posición inicial como primera posición segura
	previous_safe_position = position
	if is_patroling:
		set_state(States.PATROL)

func _physics_process(delta: float) -> void:
	# aplicar gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta
	# condiciones de salto
	if (state == States.PATROL or state == States.CHASE) and is_on_floor():
		check_jump_condition()
		if $AnimatedSprite2D/RayCast2D.is_colliding():
			previous_safe_position = position
	if state == States.JUMP:
		check_jump_finished_condition()
	match state:
		States.IDLE:
			idle()
		States.PATROL:
			patrol()
		States.CHASE:
			chase()
		States.ATTACK:
			attack()
		States.JUMP:
			jump()
	move_and_slide()

func check_jump_finished_condition() -> void:
	if not front_bottom_raycast.is_colliding():
		print("termine de saltar ray")
		if is_on_floor() and velocity.y >= 0:
			print("necesito cambiar de estado")
			set_state(previous_state)  # Vuelve al estado anterior sin condiciones adicionales

func check_edge() -> bool:
	# cuando está persiguiendo y puede saltarla
	if state == States.CHASE and is_on_wall():
		return false if can_jump_obstacle() else true
	return not $AnimatedSprite2D/RayCast2D.is_colliding() or is_on_wall()

func can_jump_obstacle() -> bool:
	# verificar si un obstáculo puede ser saltado
	return front_bottom_raycast.is_colliding() and not front_raycast.is_colliding()


func check_jump_condition() -> void:
	# Verificamos si podemos saltar el obstáculo
	if is_on_floor() and (can_jump_obstacle() or (state == States.CHASE and is_on_wall())):
		initial_jump_position = position.y
		set_state(States.JUMP)

func _process(delta: float) -> void:
	if health <= 0:
		queue_free()

func set_state(new_state: int) -> void:
	previous_state = state
	state = new_state
	match state:
		States.IDLE:
			$AnimatedSprite2D.play("idle")
		States.PATROL:
			$AnimatedSprite2D.play("walk")
		States.CHASE:
			pass
			$AnimatedSprite2D.play("run")
		States.ATTACK:
			pass
			$AnimatedSprite2D.play("attack")
		States.JUMP:
			pass
			$AnimatedSprite2D.play("jump")
	# acciones extra
	if previous_state == States.ATTACK and state != States.ATTACK:
		pass
	if previous_state == States.CHASE and state!= States.CHASE and needs_correction:
		needs_correction = false
		velocity.x = 0

func idle() -> void:
	#print("estoy idle")
	stop_chasing()

func patrol() -> void:
	# Patrullaje cuando no está persiguiendo
	if check_edge():
		# Patrullaje en la dirección actual
		turn()
	velocity.x = direction * speed

func chase() -> void:
	print("funcion chase")
	# Persigue al jugador
	if check_edge():
		stop_chasing()
	else:
		# Si hay un obstáculo adelante y podemos saltarlo, saltamos
		# Mejora la lógica de salto
		if is_on_wall():
			if can_jump_obstacle():
				set_state(States.JUMP)
			else:
				# Si no puede saltar, gira
				turn()
				return
		
		velocity.x = direction * speed * 4
	needs_correction = true
	chasing_timer.start()

func stop_chasing() -> void:
	velocity.x = 0
	# Verificar si el jugador aún está vivo
	if GLOBAL.player_health <= 0:
		set_state(States.IDLE)
		return
	if is_watching:
		set_state(States.CHASE)
	elif chasing_timer.time_left > 0:
		set_state(States.IDLE)
	else:
		if is_patroling:
			set_state(States.PATROL)
		else:
			set_state(States.IDLE)

func jump() -> void:
	if is_on_floor():
		print("intento saltar")
		# Ajustamos la velocidad horizontal según el estado previo
		if previous_state == States.CHASE:
			velocity.x = direction * speed * 2  # Velocidad de persecución
			velocity.y = JUMP_VELOCITY * 1.5
		else:
			velocity.x = direction * speed      # Velocidad normal de patrulla
			velocity.y = JUMP_VELOCITY

func attack() -> void:
	if $AnimatedSprite2D.frame == 1 and !can_attack:
		can_attack = true
	if $AnimatedSprite2D.frame == 5 and $AnimatedSprite2D.animation == "attack" and can_attack:
		var bodies = $AnimatedSprite2D/PunchingArea2D.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("Player"):
				if GLOBAL.player_health > 0:
					# Llama a la función take_damage del jugador
					body.take_damage(damage)
					can_attack = false
				else:
					# Si la vida del jugador es 0, detener el ataque y volver al estado anterior
					set_state(previous_state)
				break

func turn() -> void:
	print("doy la vuelta")
	direction = -direction
	$AnimatedSprite2D.scale.x = direction

func take_damage(amount: int) -> void:
	health -= amount
	print("Vida restante de agente: ", health)
	start_blinking()  # Inicia el parpadeo al recibir daño
	if health <= 0:
		die()

func die() -> void:
	print("El agente ha muerto")
	queue_free()

func start_blinking():
	# detener cualquier tween previo
	if tween and tween.is_valid():
		tween.kill()
	# Crear un nuevo Tween para el parpadeo
	tween = create_tween()
	tween.tween_property($AnimatedSprite2D, "modulate:a", 0.0, 0.1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)  # Transparente
	tween.tween_property($AnimatedSprite2D, "modulate:a", 1.0, 0.1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)  # Visible
	tween.finished.connect(on_blinking_done)

func on_blinking_done():
	# el sprite esté visible al final
	$AnimatedSprite2D.modulate.a = 1.0
	print("Parpadeo terminado")

func _on_watching_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Doors"):
		door_in_the_way = true
	elif body.is_in_group("Player") and not door_in_the_way:
		print("te estoy persiguiendo")
		is_watching = true
		set_state(States.CHASE)
		#detiene el timer si estaba activo para reactivarlo
		chasing_timer.stop()

func _on_watching_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Doors"):
		door_in_the_way = false
	elif body.is_in_group("Player") and not door_in_the_way:
		is_watching = false
		if chasing_timer.time_left > 0:
			# Seguir persiguiendo durante el tiempo restante del temporizador
			pass
		else:
			stop_chasing()
		chasing_timer.start()

func _on_hearing_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Doors"):
		door_in_the_way = true
	elif body.is_in_group("Player") and not door_in_the_way and not is_watching:
		print("te escucho")
		if not is_watching:
			turn()

func _on_hearing_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Doors"):
		door_in_the_way = false
	elif body.is_in_group("Player") and not door_in_the_way and not is_watching:
		print("ya no te escucho")
		if is_patroling:
			set_state(States.PATROL)
		else:
			set_state(States.IDLE)

func _on_punching_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Doors"):
		door_in_the_way = true
	elif body.is_in_group("Player") and not door_in_the_way:
		# Detener el timer de persecución
		chasing_timer.stop()
		set_state(States.ATTACK)

func _on_punching_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Doors"):
		door_in_the_way = false
	elif body.is_in_group("Player") and not door_in_the_way:
		# Verificar si el jugador aún está vivo
		if GLOBAL.player_health <= 0:
			set_state(States.IDLE)
			return
		# Reiniciar el timer de persecución
		chasing_timer.start()
		# transición de estados
		if is_watching:
			# Si aún está viendo al jugador, continúa persiguiendo
			set_state(States.CHASE)
		else:
			if is_patroling:
				set_state(States.PATROL)
			else:
				set_state(States.IDLE)

func _on_chasing_timer_timeout() -> void:
	print("ya no te persigo")
	stop_chasing()
