@tool
class_name MoverRotate
extends BaseMover




@warning_ignore("shadowed_variable_base_class")
@export var rotate := Vector3()
var default_rot:Vector3


func _ready() -> void:
	if Engine.is_editor_hint(): return
	super()
	default_rot = rotation_degrees


func _func_godot_apply_properties(properties:Dictionary) -> void:
	super(properties)
	if "rotate" in properties:
		rotate = properties.rotate

func _start_rotating(dest_value:Vector3, callback:Callable) -> void:
	_move("rotation_degrees", dest_value, callback)


func open():
	super()
	_start_rotating(rotate, _on_fully_opened)


func close():
	super()
	_start_rotating(default_rot, _on_fully_closed)
