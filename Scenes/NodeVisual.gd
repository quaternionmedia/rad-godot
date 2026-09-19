extends MeshInstance3D
class_name NodeVisual

var node_id: String = ""
var type: int = 0   # Node “type” (0-9).

func set_type(new_type: int, color: Color) -> void:
	type = new_type
	if mesh and mesh.material:
		mesh.material.albedo_color = color
