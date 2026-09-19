extends Resource
class_name Graph

var nodes: Dictionary = {}  # Map node ID → data dictionary.
var edges: Array = []       # Array of edge dictionaries.

func add_node(node_id: String, data: Dictionary = {}):
	if node_id in nodes:
		push_warning("Node '%s' already exists." % node_id)
		return
	nodes[node_id] = data

func add_edge(source: String, target: String, data: Dictionary = {}):
	if not (source in nodes and target in nodes):
		push_error("Both nodes must exist to create an edge.")
		return
	edges.append({ "source": source, "target": target, "data": data })
