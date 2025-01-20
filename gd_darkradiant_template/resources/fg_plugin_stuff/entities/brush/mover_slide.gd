@tool
class_name MoverSlide
extends BaseMover


var default_pos:Vector3
@warning_ignore("shadowed_variable_base_class")
@export var translate := Vector3()

func _ready() -> void:
	if Engine.is_editor_hint(): return
	super()
	default_pos = position
	printt(default_pos, translate)


func _func_godot_apply_properties(properties:Dictionary) -> void:
	if not Engine.is_editor_hint(): return
	super(properties)
	if "translate" in properties:
		translate = properties.translate / get_parent().map_settings.inverse_scale_factor



func _start_sliding(dest_value:Vector3, callback:Callable) -> void:
	_move("position", dest_value, callback)


func open():
	super()
	_start_sliding(default_pos+translate, _on_fully_opened)

func close():
	super()
	_start_sliding(default_pos, _on_fully_closed)


