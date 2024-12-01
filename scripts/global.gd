extends Node

signal world_state_changed(is_in_real_world)
signal player_take_damage(damage_amount)

var is_in_real_world : bool = true:
	set(value):
		if is_in_real_world != value:
			is_in_real_world = value
			emit_signal("world_state_changed", is_in_real_world)
	get:
		return is_in_real_world
var is_in_interactive_area : bool = false
var force_change : bool = false
var dont_move: bool = false
var player_is_alive : bool = true
# definir lo que el jugador puede hacer
var can_change_dimentions : bool = false
var can_walk : bool = false
var can_jump : bool = false
var can_run : bool = false
var can_move_boxes : bool = false
var can_throw_stuff : bool = false
var can_crouch : bool = false
var can_attack : bool = false

var player_health : int = 100
var player_stamina : int = 100

var show_door_instructions = false

#para definir si es necesario mostrar las indicaciones en la pantalla
var should_show_button_door = false
var lvl2_go_door = false
