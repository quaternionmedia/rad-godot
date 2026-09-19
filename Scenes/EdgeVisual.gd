extends MeshInstance3D
class_name EdgeVisual

var source_node: String = ""
var target_node: String = ""
var type: int = 0

func set_type(new_type: int, color: Color) -> void:
	type = new_type
	if mesh and mesh.material:
		mesh.material.albedo_color = color
