extends Control

@onready var label = $MarginContainer/VBoxContainer/Label
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/gui/main_menu.tscn")
