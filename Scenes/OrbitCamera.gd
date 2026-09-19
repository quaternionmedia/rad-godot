# OrbitCamera.gd
extends Node3D

@export var rotation_speed: float = 0.005  # How quickly the camera orbits.
@export var zoom_speed: float = 1.0        # How fast zooming occurs.
@export var min_distance: float = 2.0      # Closest the camera can get.
@export var max_distance: float = 100.0     # Farthest the camera can get.

var distance: float = 10.0  # Initial distance from the pivot.
var camera: Camera3D      # Reference to the child Camera3D.

func _ready() -> void:
	# Get the camera node (assumed to be a direct child).
	camera = $MainCamera
	update_camera_transform()

func _unhandled_input(event: InputEvent) -> void:
	# Use middle mouse button dragging for orbiting.
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			orbit(event.relative)
	# Use the mouse wheel for zooming in/out.
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom(-zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom(zoom_speed)

func orbit(relative: Vector2) -> void:
	# Rotate around the Y axis (horizontal) and X axis (vertical).
	rotate_y(-relative.x * rotation_speed)
	
	# Calculate and clamp the new vertical (X-axis) rotation.
	var new_x: float = rotation.x - relative.y * rotation_speed
	new_x = clamp(new_x, deg_to_rad(-80), deg_to_rad(80))
	rotation.x = new_x
	
	update_camera_transform()

func zoom(amount: float) -> void:
	distance = clamp(distance + amount, min_distance, max_distance)
	update_camera_transform()

func update_camera_transform() -> void:
	# Position the camera relative to the pivot.
	# We position it along the local Z axis.
	camera.position = Vector3(0, 0, distance)
	# Make sure the camera is always looking at the pivot's origin.
	camera.look_at(Vector3.ZERO, Vector3.UP)
