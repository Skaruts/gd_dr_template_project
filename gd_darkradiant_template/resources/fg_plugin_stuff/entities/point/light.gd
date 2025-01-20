@tool
class_name Light
extends OmniLight3D


@export var func_godot_properties: Dictionary#:
	#get:
		#return func_godot_properties # TODOConverter40 Non existent get function
	#set(new_properties):
		#if(func_godot_properties != new_properties):
			#func_godot_properties = new_properties
			#update_properties()


func _func_godot_apply_properties(properties:Dictionary) -> void:
	if not Engine.is_editor_hint():
		return

	if '_color' in properties:
		light_color = properties['_color']

	shadow_enabled = true
	shadow_bias = 0.03
	if "noshadows" in properties:
		shadow_enabled = not bool(properties.noshadows)

	if "light_radius" in properties:
		var rad:float = properties.light_radius.x
		omni_range = rad / get_parent().map_settings.inverse_scale_factor

	if "attenuation" in properties:
		omni_attenuation = properties.attenuation #.to_float()
