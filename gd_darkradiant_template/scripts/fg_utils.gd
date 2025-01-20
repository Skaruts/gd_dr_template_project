class_name FGUtils

const EMPTY_NAMES = ["", "-"]


static func reparent_entity(node:Node3D, parent_name:String, map:FuncGodotMap) -> void:
	if parent_name in EMPTY_NAMES: return

	var parent:Node3D = map.get_node_or_null(NodePath(parent_name))

	node.reparent(parent)
	node.owner = parent.owner

	for c in node.get_children():
		c.owner = node.owner










