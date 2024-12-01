# GUI_Inventario.gd
extends CanvasLayer

var max_value: float
var value: float
# Referencias a nodos
@onready var inventory_container = $InventoryContainer
@onready var status_container = $StatusContainer
@onready var grid = $InventoryContainer/PanelContainer/VBoxContainer/GridContainer
@onready var health_bar: ProgressBar = $StatusContainer/HBoxContainer/BarsContainer/StatusBars/HBoxContainer/HealthBar
@onready var stamina_bar: ProgressBar = $StatusContainer/HBoxContainer/BarsContainer/StatusBars/HBoxContainer2/StaminaBar
@onready var circular_progress: TextureProgressBar = $StatusContainer/HBoxContainer/ClockContainer/CircularProgressContainer/CircularProgressBar
@onready var circular_image: TextureRect = $StatusContainer/HBoxContainer/ClockContainer/CircularProgressContainer/CircularProgressBar/CircularImage
var selected_slot: Panel = null
@onready var player = get_tree().get_first_node_in_group("Player")
var tween: Tween = null
var tween2: Tween = null

# Estilo para el panel de estado
var status_style_blue = StyleBoxFlat.new()
var status_style_red = StyleBoxFlat.new()
# Estilo para el panel del inventario
var inventory_style_blue = StyleBoxFlat.new()
var inventory_style_red = StyleBoxFlat.new()
# Configurar estilo de las barras de estado
var health_style_blue = StyleBoxFlat.new()
var health_style_red = StyleBoxFlat.new()
var stamina_style_blue = StyleBoxFlat.new()
var stamina_style_red = StyleBoxFlat.new()
# Colores personalizados
# Colores para el mundo real
const COLORS_REAL_WORLD = {
	"background": Color("#9bb5cf"),
	"border": Color("#1f7a8c"),
	"slot_bg": Color("#9bb5cf"),
	"slot_selected": Color("#e1e5f2"),
	"health": Color("#1f7a8c"),
	"stamina": Color("#1f7a8c"),
	"claro": Color("e1e5f2")
}
# Colores para el mundo del tiempo
const COLORS_TIME_WORLD = {
	"background": Color("#DA9F93"),
	"border": Color("#B6465F"),
	"slot_bg": Color("#DA9F93"),
	"slot_selected": Color("#EBD4CB"),
	"health": Color("#B6465F"),
	"stamina": Color("#B6465F"),
	"claro": Color("#EBD4CB")
}
var colors = COLORS_REAL_WORLD
# Diccionario para mantener registro de los slots y sus llaves
var slots = {}
var regeneration_rate = 20.0  # Porcentaje de regeneracion por segundo
var blinking : bool = false
var is_regenerating = false  # Bandera para controlar la regeneración
func _ready():
	print("GUI: Iniciado")
	print("GUI: Buscando jugador...")
	find_player()
	# Conectar con las señales del inventario
	Inventario.item_added.connect(_on_item_added)
	Inventario.item_removed.connect(_on_item_removed)
	setup_gui_style()
	setup_circular_progress_bar()
	if !GLOBAL.can_change_dimentions:
		$StatusContainer/HBoxContainer/ClockContainer.visible = false
	# Conectar señal de cambio de dimensión
	if player and player.has_signal("dimension_changed"):
		player.connect("dimension_changed", Callable(self, "_on_dimension_changed"))

func find_player():
	player = get_tree().get_first_node_in_group("Player")
	if !player:
		push_error("No se encontró el jugador en el grupo 'player'")
	else:
		print("GUI: Jugador encontrado correctamente")
		
		# Reconectar señales
		if player.has_signal("ability_timer_changed"):
			player.connect("ability_timer_changed", Callable(self, "_on_ability_timer_changed"))
		
		# Configurar propiedades de la barra de progreso
		max_value = player.dimension_shift_max_time
		value = max_value
		
		# Actualizar barras de estado
		setup_status_bars()

# Configurar estilos de la barra circular
func setup_circular_progress_bar():
	# Configuración inicial
	circular_progress.max_value = 10
	circular_progress.value = 10
	# Configurar imagen en el centro
	circular_image.custom_minimum_size = circular_progress.custom_minimum_size  # Igualar tamaños
	circular_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	circular_image.texture = preload("res://images/UI/Reloj.png")
	# Centrar la imagen dentro de la barra de progreso
	circular_image.anchors_preset = Control.PRESET_CENTER


func _on_ability_timer_changed(current_time: float, max_time: float):
	circular_progress.value = current_time

func setup_gui_style():
	# Estilo para el panel del inventario
	# mundo real
	inventory_style_blue.bg_color = COLORS_REAL_WORLD.background
	inventory_style_blue.border_color = COLORS_REAL_WORLD.border
	inventory_style_blue.border_width_left = 2
	inventory_style_blue.border_width_right = 2
	inventory_style_blue.border_width_top = 2
	inventory_style_blue.border_width_bottom = 2
	inventory_style_blue.corner_radius_top_left = 10
	inventory_style_blue.corner_radius_top_right = 10
	inventory_style_blue.corner_radius_bottom_left = 10
	inventory_style_blue.corner_radius_bottom_right = 10
	inventory_style_blue.content_margin_left = 10
	inventory_style_blue.content_margin_right = 10
	inventory_style_blue.content_margin_top = 10
	inventory_style_blue.content_margin_bottom = 10
	# mundo de tiempo
	inventory_style_red.bg_color = COLORS_TIME_WORLD.background
	inventory_style_red.border_color = COLORS_TIME_WORLD.border
	inventory_style_red.border_width_left = 2
	inventory_style_red.border_width_right = 2
	inventory_style_red.border_width_top = 2
	inventory_style_red.border_width_bottom = 2
	inventory_style_red.corner_radius_top_left = 10
	inventory_style_red.corner_radius_top_right = 10
	inventory_style_red.corner_radius_bottom_left = 10
	inventory_style_red.corner_radius_bottom_right = 10
	inventory_style_red.content_margin_left = 10
	inventory_style_red.content_margin_right = 10
	inventory_style_red.content_margin_top = 10
	inventory_style_red.content_margin_bottom = 10
	$InventoryContainer/PanelContainer.add_theme_stylebox_override("panel", inventory_style_blue)

	# Estilo para el panel de estado
	# mundo real
	status_style_blue.bg_color = COLORS_REAL_WORLD.background
	status_style_blue.border_color = COLORS_REAL_WORLD.border
	status_style_blue.border_width_left = 2
	status_style_blue.border_width_right = 2
	status_style_blue.border_width_top = 2
	status_style_blue.border_width_bottom = 2
	status_style_blue.corner_radius_top_left = 10
	status_style_blue.corner_radius_top_right = 10
	status_style_blue.corner_radius_bottom_left = 10
	status_style_blue.corner_radius_bottom_right = 10
	status_style_blue.content_margin_left = 10
	status_style_blue.content_margin_right = 10
	status_style_blue.content_margin_top = 10
	status_style_blue.content_margin_bottom = 10
	# mundo de tiempo
	status_style_red.bg_color = COLORS_TIME_WORLD.background
	status_style_red.border_color = COLORS_TIME_WORLD.border
	status_style_red.border_width_left = 2
	status_style_red.border_width_right = 2
	status_style_red.border_width_top = 2
	status_style_red.border_width_bottom = 2
	status_style_red.corner_radius_top_left = 10
	status_style_red.corner_radius_top_right = 10
	status_style_red.corner_radius_bottom_left = 10
	status_style_red.corner_radius_bottom_right = 10
	status_style_red.content_margin_left = 10
	status_style_red.content_margin_right = 10
	status_style_red.content_margin_top = 10
	status_style_red.content_margin_bottom = 10
	$StatusContainer/HBoxContainer/BarsContainer.add_theme_stylebox_override("panel", status_style_blue)
	$StatusContainer/HBoxContainer/ClockContainer.add_theme_stylebox_override("panel", status_style_blue)
	# Configurar márgenes para el inventario
	$InventoryContainer.add_theme_constant_override("margin_left", 10)
	$InventoryContainer.add_theme_constant_override("margin_right", 10)
	$InventoryContainer.add_theme_constant_override("margin_top", 10)
	$InventoryContainer.add_theme_constant_override("margin_bottom", 10)

	# Configurar márgenes para el estado
	$StatusContainer.add_theme_constant_override("margin_left", 10)
	$StatusContainer.add_theme_constant_override("margin_right", 10)
	$StatusContainer.add_theme_constant_override("margin_top", 10)
	$StatusContainer.add_theme_constant_override("margin_bottom", 10)

	# Configurar estilo de las barras de estado
	#mundo real
	health_style_blue.bg_color = COLORS_REAL_WORLD.health
	health_style_blue.border_color = COLORS_REAL_WORLD.border
	health_style_blue.border_width_left = 1
	health_style_blue.border_width_right = 1
	health_style_blue.border_width_top = 1
	health_style_blue.border_width_bottom = 1
	health_style_blue.corner_radius_top_left = 5
	health_style_blue.corner_radius_top_right = 5
	health_style_blue.corner_radius_bottom_left = 5
	health_style_blue.corner_radius_bottom_right = 5
	# mundo de tiempo
	health_style_red.bg_color = COLORS_TIME_WORLD.health
	health_style_red.border_color = COLORS_TIME_WORLD.border
	health_style_red.border_width_left = 1
	health_style_red.border_width_right = 1
	health_style_red.border_width_top = 1
	health_style_red.border_width_bottom = 1
	health_style_red.corner_radius_top_left = 5
	health_style_red.corner_radius_top_right = 5
	health_style_red.corner_radius_bottom_left = 5
	health_style_red.corner_radius_bottom_right = 5
	health_bar.add_theme_stylebox_override("fill", health_style_blue)

	# mundo real
	stamina_style_blue.bg_color = COLORS_REAL_WORLD.stamina
	stamina_style_blue.border_color = COLORS_REAL_WORLD.border
	stamina_style_blue.border_width_left = 1
	stamina_style_blue.border_width_right = 1
	stamina_style_blue.border_width_top = 1
	stamina_style_blue.border_width_bottom = 1
	stamina_style_blue.corner_radius_top_left = 5
	stamina_style_blue.corner_radius_top_right = 5
	stamina_style_blue.corner_radius_bottom_left = 5
	stamina_style_blue.corner_radius_bottom_right = 5
	# mundo de tiempo
	stamina_style_red.bg_color = COLORS_TIME_WORLD.stamina
	stamina_style_red.border_color = COLORS_TIME_WORLD.border
	stamina_style_red.border_width_left = 1
	stamina_style_red.border_width_right = 1
	stamina_style_red.border_width_top = 1
	stamina_style_red.border_width_bottom = 1
	stamina_style_red.corner_radius_top_left = 5
	stamina_style_red.corner_radius_top_right = 5
	stamina_style_red.corner_radius_bottom_left = 5
	stamina_style_red.corner_radius_bottom_right = 5
	stamina_bar.add_theme_stylebox_override("fill", stamina_style_blue)

func setup_status_bars():
	# Actualizar los valores iniciales de las barras
	if player:
		# Configurar valores máximos
		health_bar.max_value = 100  # O el valor máximo que uses para la salud
		health_bar.value = GLOBAL.player_health
		stamina_bar.max_value = 100 # O el valor máximo que uses para la stamina
		stamina_bar.value = GLOBAL.player_stamina

func _process(delta: float) -> void:
	if GLOBAL.can_change_dimentions and $StatusContainer/HBoxContainer/ClockContainer.visible == false:
		$StatusContainer/HBoxContainer/ClockContainer.visible = true
	# Buscar el jugador si no existe
	if not player or not is_instance_valid(player):
		find_player()
	if player:
		# Actualizar barras de estado y se convierten los valores a float para el lerp
		health_bar.value = lerp(health_bar.value, float(GLOBAL.player_health), 0.1)
		stamina_bar.value = lerp(stamina_bar.value, float(GLOBAL.player_stamina), 0.1)
	if circular_progress.value == 0:
		start_blinking()
	elif circular_progress.value != 0 and blinking:
		stop_blinking()

func start_blinking():
	if blinking: 
		return  # Evita iniciar parpadeo si ya está en curso
	blinking = true
	# Asegúrate de que no hay tween en curso
	if tween and tween.is_valid():
		tween.kill()  # Detiene el Tween si existe
		tween = null
	if tween2 and tween2.is_valid():
		tween2.kill()  # Detiene el Tween si existe
		tween2 = null
	# Crear un nuevo Tween y configurarlo
	tween = create_tween()
	tween.set_loops(-1)  # Repetir indefinidamente
	tween.tween_property(circular_image, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)  # A transparente
	tween.tween_property(circular_image, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)  # A opaco
	tween2 = create_tween()
	tween2.set_loops(-1)  # Repetir indefinidamente
	tween2.tween_property(circular_progress, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)  # A transparente
	tween2.tween_property(circular_progress, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)  # A opaco

func stop_blinking():
	if tween and tween.is_valid():
		tween.kill()  # Detiene el Tween si existe
		tween = null
	if tween2 and tween2.is_valid():
		tween2.kill()  # Detiene el Tween si existe
		tween2 = null
	blinking = false
	circular_image.modulate.a = 1.0  # Restaura la opacidad completa
	circular_progress.modulate.a = 1.0  # Restaura la opacidad completa

func _on_item_added(item_name: String, item_data: Dictionary):
	# Crear un nuevo slot para la item
	var slot = Panel.new()
	slot.custom_minimum_size = Vector2(64, 64)
	
	# Estilo del slot
	var slot_style = StyleBoxFlat.new()
	slot_style.bg_color = colors.slot_bg
	slot_style.border_color = colors.border
	slot_style.border_width_left = 2
	slot_style.border_width_right = 2
	slot_style.border_width_top = 2
	slot_style.border_width_bottom = 2
	slot_style.corner_radius_top_left = 5
	slot_style.corner_radius_top_right = 5
	slot_style.corner_radius_bottom_left = 5
	slot_style.corner_radius_bottom_right = 5
	slot.add_theme_stylebox_override("panel", slot_style)
	
	# Añadir textura
	var texture_rect = TextureRect.new()
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)  # Ocupa todo el slot
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	'''
	# Seleccionar textura basada en la dimensión
	var texture
	if item_data.get("dimension") == 0:  # REAL_WORLD
		texture = preload("res://images/elements/llave.png")  # Ajusta la ruta
	else:  # TIME_WORLD
		texture = preload("res://images/elements/llave.png")  # Ajusta la ruta
	
	texture_rect.texture = texture
	slot.add_child(texture_rect)
	'''
	# Usar la textura proporcionada en item_data
	if item_data.has("texture"):
		texture_rect.texture = item_data.texture
	else:
		# Fallback a la textura de llave solo si no hay textura específica
		var dimension = item_data.get("dimension", 0)
		texture_rect.texture = preload("res://images/elements/llave_blue.png")
		push_warning("No se encontró textura para el item: " + item_name)
	
	slot.add_child(texture_rect)
	# Guardar referencia al slot
	slots[item_name] = slot
	
	# Añadir el slot al grid
	grid.add_child(slot)
	print("Item añadido al inventario: ", item_name)
	
	# Hacer el slot interactivo si es un objeto lanzable
	if item_data.get("throwable", false):
		slot.gui_input.connect(_on_slot_gui_input.bind(slot, item_name))

func _on_slot_gui_input(event: InputEvent, slot: Panel, item_name: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("GUI: Click en slot con item: ", item_name)  # Debug
		# Verificar si el slot anterior existe antes de modificarlo
		if selected_slot and is_instance_valid(selected_slot):
			var old_style = selected_slot.get_theme_stylebox("panel")
			if old_style:
				old_style.border_color = colors.border
		
		selected_slot = slot
		# Verificar si el nuevo slot existe
		if is_instance_valid(selected_slot):
			var style = selected_slot.get_theme_stylebox("panel")
			if style:
				style.border_color = colors.slot_selected
		
		# Buscar el jugador si no existe
		if not player or not is_instance_valid(player):
			find_player()
		print("GUI: ¿Se encontró el jugador?", player != null)  # Debug
		if player:
			print("GUI: Asignando item lanzable: ", item_name)  # Debug
			player.selected_throwable = item_name
		else:
			# Intentar obtener el jugador nuevamente en caso de que no se haya encontrado en _ready
			player = get_tree().get_first_node_in_group("Player")
			if player:
				print("GUI: Jugador encontrado y asignado item: ", item_name)
				player.selected_throwable = item_name
			else:
				push_error("No se puede encontrar el jugador para asignar el item")

func clear_selection():
	if selected_slot:
		var style = selected_slot.get_theme_stylebox("panel")
		style.border_color = colors.border
		selected_slot = null

func update_gui_colors():
	colors = COLORS_REAL_WORLD if GLOBAL.is_in_real_world else COLORS_TIME_WORLD
	if GLOBAL.is_in_real_world:
		$InventoryContainer/PanelContainer.add_theme_stylebox_override("panel", inventory_style_blue)
		$StatusContainer/HBoxContainer/BarsContainer.add_theme_stylebox_override("panel", status_style_blue)
		$StatusContainer/HBoxContainer/ClockContainer.add_theme_stylebox_override("panel", status_style_blue)
		health_bar.add_theme_stylebox_override("fill", health_style_blue)
		stamina_bar.add_theme_stylebox_override("fill", stamina_style_blue)
		circular_progress.texture_under = load("res://images/UI/circleprogressbar_under.png")
		circular_progress.texture_progress = load("res://images/UI/circleprogressbar_progress.png")
		$StatusContainer/HBoxContainer/BarsContainer/StatusBars/HBoxContainer/TextureRect.texture = load("res://images/UI/hearth.png")
		$StatusContainer/HBoxContainer/BarsContainer/StatusBars/HBoxContainer2/TextureRect.texture = load("res://images/UI/Stamina_blue.png")
		circular_image.texture = load("res://images/UI/Reloj_BLUE.png")
	else:
		$InventoryContainer/PanelContainer.add_theme_stylebox_override("panel", inventory_style_red)
		$StatusContainer/HBoxContainer/BarsContainer.add_theme_stylebox_override("panel", status_style_red)
		$StatusContainer/HBoxContainer/ClockContainer.add_theme_stylebox_override("panel", status_style_red)
		health_bar.add_theme_stylebox_override("fill", health_style_red)
		stamina_bar.add_theme_stylebox_override("fill", stamina_style_red)
		circular_progress.texture_under = load("res://images/UI/circleprogressbar_under_red.png")
		circular_progress.texture_progress = load("res://images/UI/circleprogressbar_progress_red.png")
		$StatusContainer/HBoxContainer/BarsContainer/StatusBars/HBoxContainer/TextureRect.texture = load("res://images/UI/hearth_red.png")
		$StatusContainer/HBoxContainer/BarsContainer/StatusBars/HBoxContainer2/TextureRect.texture = load("res://images/UI/Stamina_red.png")
		circular_image.texture = load("res://images/UI/Reloj_RED.png")
	
	# Actualizar colores de los slots existentes
	for slot in slots.values():
		var slot_style = slot.get_theme_stylebox("panel")
		slot_style.bg_color = colors.slot_bg
		slot_style.border_color = colors.border

func _on_dimension_changed():
	# Actualizar colores del GUI
	update_gui_colors()
	
	# Actualizar texturas de los slots existentes
	for item_name in slots:
		var item_data = Inventario.get_item_data(item_name)
		if item_data:
			# Get the slot
			var slot = slots[item_name]
			
			# Find the texture rect, using a more flexible approach
			var texture_rect = slot.get_node_or_null("TextureRect")
			if not texture_rect:
				# If the direct child is not found, try finding it among children
				texture_rect = slot.find_child("*TextureRect*", true, false)
			
			if not texture_rect:
				print("Could not find texture rect for item: ", item_name)
				continue
			
			# Existing texture update logic
			var object_name = item_data.get("object_name", "")
			var texture = null
			
			match object_name:
				"key":
					texture = preload("res://images/elements/llave_blue_idle.png") if GLOBAL.is_in_real_world else preload("res://images/elements/llave_red_idle.png")
				"cristal":
					texture = preload("res://images/elements/Throwable_blue.png") if GLOBAL.is_in_real_world else preload("res://images/elements/Throwable_red.png")
				# future cases for other objects
			
			if texture:
				texture_rect.texture = texture

func _on_item_removed(item_name: String):
	if slots.has(item_name):
		# Eliminar el slot
		slots[item_name].queue_free()
		slots.erase(item_name)
		print("Item removida del inventario: ", item_name)

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC para ocultar al pausar
		visible = false
