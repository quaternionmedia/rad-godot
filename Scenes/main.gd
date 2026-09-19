extends Node3D

# --- Constants & Preloads ---
const DEPTH_DRAW_MODE_ALWAYS = 2  # Our workaround: using 2 as the depth draw mode value.
# (Adjust as needed.)

# Preload our modules if desired (or ensure they’re in your project):
# For example:
# const Graph = preload("res://Graph.gd")
# const NodeVisual = preload("res://NodeVisual.gd")
# const EdgeVisual = preload("res://EdgeVisual.gd")

# --- Global Variables ---
var graph: Graph = Graph.new()       # Holds our graph data.
var node_positions: Dictionary = {}    # Map node_id → world position (Vector3).
var node_visuals: Dictionary = {}      # Map node_id → NodeVisual instance.
var edge_visuals: Array = []           # Array of EdgeVisual instances.

var node_counter: int = 0
var selected_node_id: String = ""        # For connecting nodes via right-click.
var dragged_node_id: String = ""         # For dragging nodes.
var dragged_node_offset: Vector3 = Vector3.ZERO

# Hover-related variables:
var hovered_node_id: String = ""
var hovered_edge_index: int = -1

# For “type” selection (set by number keys 0–9):
var current_type: int = 0
var type_colors = {
	0: Color(1, 0, 0, 0.5),    # Red
	1: Color(0, 1, 0, 0.5),    # Green
	2: Color(0, 0, 1, 0.5),    # Blue
	3: Color(1, 1, 0, 0.5),    # Yellow
	4: Color(1, 0, 1, 0.5),    # Magenta
	5: Color(0, 1, 1, 0.5),    # Cyan
	6: Color(1, 0.5, 0, 0.5),  # Orange
	7: Color(0.5, 0, 1, 0.5),  # Purple
	8: Color(0.5, 0.5, 0.5, 0.5),  # Gray
	9: Color(1, 1, 1, 0.5)     # White
}

var camera: Camera3D

func _ready():
	# Assign the camera (assumes a Camera3D node named "MainCamera" exists as a child).
	camera = $CameraPivot/MainCamera
	if camera == null:
		push_error("Camera is null! Ensure there is a Camera3D node named 'MainCamera'.")
	print("Instructions:")
	print("  • Left click on the ground to create a node or grab an existing node to move it.")
	print("  • Right click on a node to select it for connecting edges; then right click another node to connect them.")
	print("  • Hold a number key (0–9) while clicking to create nodes/edges of that type (color).")
	print("  • Drag with the left mouse button; if you hold Shift while dragging, the node moves vertically (y-axis).")

func _process(delta: float) -> void:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	update_hovered_node(mouse_pos)
	update_hovered_edge(mouse_pos)

func _input(event: InputEvent) -> void:
	# Handle key presses to set current type.
	if event is InputEventKey and event.pressed:
		var key_str = OS.get_keycode_string(event.key_label)
		current_type = int(key_str)
		print("Current type set to: ", current_type)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var node_hit: String = get_node_at_mouse_position(event.position)
				if node_hit != "":
					dragged_node_id = node_hit
					dragged_node_offset = node_positions[node_hit] - get_ground_intersection(event.position)
				else:
					add_node_at_mouse(event.position)
			else:
				if dragged_node_id != "":
					dragged_node_id = ""
					update_all_edges()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			handle_right_click(event.position)
	elif event is InputEventMouseMotion:
		if dragged_node_id != "":
			# If Shift is held, update vertical (y) position only.
			if Input.is_key_pressed(KEY_SHIFT):
				var vertical_delta = -event.relative.y * 0.05  # Adjust sensitivity as desired.
				var current_pos: Vector3 = node_positions[dragged_node_id]
				var new_pos: Vector3 = Vector3(current_pos.x, current_pos.y + vertical_delta, current_pos.z)
				node_positions[dragged_node_id] = new_pos
				node_visuals[dragged_node_id].position = new_pos
			else:
				var new_pos = get_ground_intersection(event.position) + dragged_node_offset
				node_positions[dragged_node_id] = new_pos
				node_visuals[dragged_node_id].position = new_pos
			update_all_edges()

# --- Helper: Get Intersection with Ground (y = 0) ---
func get_ground_intersection(mouse_pos: Vector2) -> Vector3:
	if camera == null:
		return Vector3.ZERO
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	if ray_direction.y == 0:
		return Vector3.ZERO
	var t = -ray_origin.y / ray_direction.y
	return ray_origin + ray_direction * t

# --- Create a New Node ---
func add_node_at_mouse(mouse_pos: Vector2) -> void:
	var world_pos = get_ground_intersection(mouse_pos)
	node_counter += 1
	var node_id: String = "N%d" % node_counter
	graph.add_node(node_id, {"label": node_id, "type": current_type})
	node_positions[node_id] = world_pos

	var node_visual = NodeVisual.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.5
	var material = StandardMaterial3D.new()
	material.albedo_color = type_colors[current_type]
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.depth_draw_mode = DEPTH_DRAW_MODE_ALWAYS
	sphere_mesh.material = material
	node_visual.mesh = sphere_mesh
	node_visual.position = world_pos
	node_visual.node_id = node_id
	node_visual.set_type(current_type, type_colors[current_type])
	add_child(node_visual)
	node_visuals[node_id] = node_visual

	update_all_edges()
	print("Added node ", node_id, " of type ", current_type, " at ", world_pos)

# --- Handle Right Click for Edge Creation ---
func handle_right_click(mouse_pos: Vector2) -> void:
	var clicked_node = get_node_at_mouse_position(mouse_pos)
	if clicked_node == "":
		selected_node_id = ""
		return
	if selected_node_id == "":
		selected_node_id = clicked_node
		print("Selected node for edge: ", selected_node_id)
	else:
		if selected_node_id == clicked_node:
			print("Deselected node: ", clicked_node)
			selected_node_id = ""
		else:
			graph.add_edge(selected_node_id, clicked_node, {"relation": "connects", "type": current_type})
			create_edge_visualization(selected_node_id, clicked_node, current_type)
			print("Created edge from ", selected_node_id, " to ", clicked_node, " of type ", current_type)
			selected_node_id = ""

# --- Get Node Under Mouse (by projecting world positions to screen) ---
func get_node_at_mouse_position(mouse_pos: Vector2) -> String:
	var threshold = 20.0
	var closest_node = ""
	var closest_distance = INF
	for node_id in node_positions.keys():
		var screen_pos = world_to_screen(node_positions[node_id])
		var d = screen_pos.distance_to(mouse_pos)
		if d < threshold and d < closest_distance:
			closest_distance = d
			closest_node = node_id
	return closest_node

# --- World-to-Screen Conversion ---
func world_to_screen(world_point: Vector3) -> Vector2:
	var vp = get_viewport()
	var vp_size = vp.get_visible_rect().size
	var view_transform = camera.global_transform.affine_inverse()
	var camera_space = view_transform * world_point
	if camera_space.z >= 0:
		return Vector2(-1000, -1000)
	var fov_rad = deg_to_rad(camera.fov)
	var tan_fov = tan(fov_rad / 2.0)
	var aspect = vp_size.x / vp_size.y
	var ndc_x = (camera_space.x / -camera_space.z) / (tan_fov * aspect)
	var ndc_y = (camera_space.y / -camera_space.z) / tan_fov
	var screen_x = (ndc_x + 1.0) * 0.5 * vp_size.x
	var screen_y = (1.0 - (ndc_y + 1.0) * 0.5) * vp_size.y
	return Vector2(screen_x, screen_y)

# --- Create an Edge Visualization ---
func create_edge_visualization(source_id: String, target_id: String, edge_type: int) -> void:
	if not (source_id in node_positions and target_id in node_positions):
		return
	var start = node_positions[source_id]
	var end = node_positions[target_id]
	var mid = (start + end) * 0.5
	var direction = (end - start)
	var distance = direction.length()
	direction = direction.normalized()
	
	var edge_visual = EdgeVisual.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.1
	cylinder.bottom_radius = 0.1
	cylinder.height = distance
	cylinder.radial_segments = 16
	var material = StandardMaterial3D.new()
	material.albedo_color = type_colors[edge_type]
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.depth_draw_mode = DEPTH_DRAW_MODE_ALWAYS
	cylinder.material = material
	edge_visual.mesh = cylinder
	edge_visual.source_node = source_id
	edge_visual.target_node = target_id
	edge_visual.set_type(edge_type, type_colors[edge_type])
	
	var rot_axis = Vector3.UP.cross(direction)
	var angle = Vector3.UP.angle_to(direction)
	var rot: Basis = Basis(rot_axis.normalized(), angle) if rot_axis.length() > 0.001 else Basis()
	edge_visual.transform = Transform3D(rot, mid)
	add_child(edge_visual)
	edge_visuals.append(edge_visual)

# --- Update All Edges (Recreate all edge visuals) ---
func update_all_edges() -> void:
	for edge_inst in edge_visuals:
		if edge_inst and edge_inst.is_inside_tree():
			edge_inst.queue_free()
	edge_visuals.clear()
	for edge in graph.edges:
		var e_type = 0
		if "type" in edge["data"]:
			e_type = edge["data"]["type"]
		create_edge_visualization(edge["source"], edge["target"], e_type)

# --- Hover Mechanism for Nodes ---
func update_hovered_node(mouse_pos: Vector2) -> void:
	var new_hovered = get_node_at_mouse_position(mouse_pos)
	if new_hovered != hovered_node_id:
		if hovered_node_id != "":
			var old_node = node_visuals[hovered_node_id]
			var old_type = graph.nodes[hovered_node_id]["type"]
			old_node.mesh.material.albedo_color = type_colors[old_type]
		hovered_node_id = new_hovered
		if hovered_node_id != "":
			var new_node = node_visuals[hovered_node_id]
			new_node.mesh.material.albedo_color = Color(1, 1, 1, 0.8)  # White highlight.

# --- Hover Mechanism for Edges ---
func distance_point_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var ab_len_sq = ab.length_squared()
	if ab_len_sq == 0:
		return (p - a).length()
	var t = (p - a).dot(ab) / ab_len_sq
	if t < 0:
		return (p - a).length()
	elif t > 1:
		return (p - b).length()
	else:
		var proj = a + ab * t
		return (p - proj).length()

func get_edge_at_mouse_position(mouse_pos: Vector2) -> int:
	var threshold = 10.0
	var best_index = -1
	var best_distance = INF
	for i in range(edge_visuals.size()):
		var edge = edge_visuals[i]
		var start = node_positions[edge.source_node]
		var end = node_positions[edge.target_node]
		var start_screen = world_to_screen(start)
		var end_screen = world_to_screen(end)
		var d = distance_point_to_segment(mouse_pos, start_screen, end_screen)
		if d < threshold and d < best_distance:
			best_distance = d
			best_index = i
	return best_index

func update_hovered_edge(mouse_pos: Vector2) -> void:
	var new_index = get_edge_at_mouse_position(mouse_pos)
	if new_index != hovered_edge_index:
		if hovered_edge_index != -1 and hovered_edge_index < edge_visuals.size():
			var old_edge = edge_visuals[hovered_edge_index]
			var e_type = old_edge.type
			old_edge.mesh.material.albedo_color = type_colors[e_type]
		hovered_edge_index = new_index
		if hovered_edge_index != -1:
			var new_edge = edge_visuals[hovered_edge_index]
			new_edge.mesh.material.albedo_color = Color(1, 1, 1, 0.8)  # White highlight.
