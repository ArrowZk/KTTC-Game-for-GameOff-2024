extends Node
class_name Level

func deactivate_node(node: Node) -> void:
	# Inicializa un diccionario para guardar el estado de cada nodo
	GLOBALFORLEVELS.original_states[node] = {}
	# Guardar propiedades del nodo si tiene esos métodos y desactivarlos
	# Desactivar visibilidad
	if node.has_method("set_visible"):
		GLOBALFORLEVELS.original_states[node]["visible"] = node.visible
		node.visible = false
	# Desactivar colisiones
	if node.has_method("set_collision_layer"):
		GLOBALFORLEVELS.original_states[node]["collision_layer"] = node.collision_layer
		node.set_collision_layer(0)
	if node.has_method("set_collision_mask"):
		GLOBALFORLEVELS.original_states[node]["collision_mask"] = node.collision_mask
		node.set_collision_mask(0)
	# Desactivar procesamiento
	if node.has_method("set_process"):
		GLOBALFORLEVELS.original_states[node]["process"] = node.is_processing()
		node.set_process(false)
	if node.has_method("set_physics_process"):
		GLOBALFORLEVELS.original_states[node]["physics_process"] = node.is_physics_processing()
		node.set_physics_process(false)
	# Desactivar interacciones de señales
	if node.has_method("disconnect"):
		var area = node.get_node_or_null("Area2D")  # O "CollisionShape2D" si es un StaticBody2D
		if area and area.is_connected("body_entered", Callable(self, "_on_area_2d_body_entered")):
			area.disconnect("body_entered", Callable(self, "_on_area_2d_body_entered"))
		if area and area.is_connected("body_exited", Callable(self, "_on_area_2d_body_exited")):
			area.disconnect("body_exited", Callable(self, "_on_area_2d_body_exited"))
	# Si el nodo tiene hijos, recorrerlos
	for child in node.get_children():
		deactivate_node(child)

func restore_node(node: Node) -> void:
	# Restaurar nodos a su estado original
	if GLOBALFORLEVELS.original_states.has(node):
		var state = GLOBALFORLEVELS.original_states[node] 
		# Restaurar visibilidad
		if state.has("visible"):
			node.visible = state["visible"]
		# Restaurar capas de colisión
		if state.has("collision_layer"):
			node.set_collision_layer(state["collision_layer"])
		if state.has("collision_mask"):
			node.set_collision_mask(state["collision_mask"])
		# Restaurar procesamiento
		if state.has("process"):
			node.set_process(state["process"])
		if state.has("physics_process"):
			node.set_physics_process(state["physics_process"])
		# Restaurar las señales
		if node.has_method("connect"):
			var area = node.get_node_or_null("Area2D")
			if area:
				# Conectar las señales si no están conectadas
				if not area.is_connected("body_entered", Callable(self, "_on_area_2d_body_entered")):
					area.connect("body_entered", Callable(self, "_on_area_2d_body_entered"))
				if not area.is_connected("body_exited", Callable(self, "_on_area_2d_body_exited")):
					area.connect("body_exited", Callable(self, "_on_area_2d_body_exited"))
		# Si el nodo es un GravityBox, restaura su última posición
		if node is GravityBox or node is ThrowableItem:
			node.restore_last_position()
		# Restaurar los hijos del nodo
		for child in node.get_children():
			restore_node(child)
