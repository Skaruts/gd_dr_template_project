@tool
class_name FuncStatic
extends StaticBody3D

@export var model_node: Node3D
@export var properties: Dictionary#:
	#get:
		#return func_godot_properties # TODOConverter40 Non existent get function
	#set(new_properties):
		#if(func_godot_properties != new_properties):
			#func_godot_properties = new_properties
			#update_properties()


func _ready() -> void:
	if Engine.is_editor_hint():
		get_parent().build_complete.connect(_build_complete)




func _translate_vec(v: Vector3) -> Vector3:
	return Vector3(v.y, v.z, v.x)

func _translate_basis(b: Basis) -> Basis:
	return Basis(_translate_vec(b.y), _translate_vec(b.z), _translate_vec(b.x))

func _get_translated_basis(string:String) -> Basis:
	var c: Array = string.split(' ', false)

	if c.size() < 9:
		push_error("Invalid matrix format for 'rotation' in entity 'func_static'")
		return transform.basis

	for i in c.size():
		c[i] = c[i].to_float()

	return _translate_basis(Basis(
		Vector3(c[0],  c[1], c[2]),
		Vector3(c[3],  c[4], c[5]),
		Vector3(c[6],  c[7], c[8]),
	))



func _func_godot_apply_properties(props:Dictionary) -> void:
	if not Engine.is_editor_hint():
		return
	properties = props

func _build_complete() -> void:
	#printerr("_build_complete  |  ", "nodes_without_owner" in properties)
	#if "nodes_without_owner" in properties:
		#for c in properties.nodes_without_owner:
			#if c.owner != owner:
				#c.owner = owner
		#properties.erase("nodes_without_owner")
	#pass

	print(_build_complete)
	# if "nodes_without_owner" in properties:
	#	for c in properties.nodes_without_owner:
	#		if c.owner != owner:
	#			c.owner = owner
	#	properties.erase("nodes_without_owner")

	# if using DR exclusively, then model is always in properties
	var is_brush_based: bool = properties.name == "" \
			or ("model" in properties and properties.model == properties.name)

	# var is_brush_based: bool = "model" in properties \
						   #and properties.model == properties.name

	if not is_brush_based:
		_load_model()

		if "rotation" in properties:
			#print(properties.rotation)
			transform.basis = _get_translated_basis(properties.rotation)


	if "solid" in properties and not properties.solid:
		if is_brush_based:
			set_collision_layer_value(1, false)
		elif "enable_collision" in model_node:
			model_node.disable_collision()




# lookup table for converting editor-model paths to game-model paths
const GAME_MODELS_LUT = {
	"models/car5.obj"              = "game_models/car5.tscn",
	"models/info_player_start.obj" = "game_models/info_player_start.obj"
}

func _load_model() -> void:
	var ext:String = GAME_MODELS_LUT[properties.model].get_extension()
	var model_path:String
	var is_scene := false

	if ext == "obj":
		model_path = "res://assets/" + GAME_MODELS_LUT[properties.model]
	elif ext in ["tscn", "scn"]:
		is_scene = true
		model_path = "res://assets/" + GAME_MODELS_LUT[properties.model]

	#printt(model_path, is_scene, GAME_MODELS_LUT[properties.model])
	var model := load(model_path)
	if model:
		if is_scene:
			model_node = model.instantiate()
			add_child(model_node)
			model_node.name = "model"
			model_node.owner = owner
		else:
			model_node = Node3D.new()
			add_child(model_node)

			var mi := MeshInstance3D.new()
			mi.mesh = model
			model_node.add_child(mi, false)
			mi.owner = owner

			#TODO: generate collision

			model_node.owner = owner
