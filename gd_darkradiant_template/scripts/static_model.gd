@tool
extends Node3D

var _body:StaticBody3D
@export var _solid:bool = true

func _ready() -> void:
	for c in get_children():
		if c is StaticBody3D:
			_body = c
			break
	if _body: _body.set_collision_layer_value(1, _solid)


func set_collision(enable:bool) -> void:
	_solid = enable
	if _body: _body.set_collision_layer_value(1, enable)


func enable_collision() -> void:
	#process_mode = Node.PROCESS_MODE_INHERIT
	_solid = true
	if _body: _body.set_collision_layer_value(1, true)


func disable_collision() -> void:
	#process_mode = Node.PROCESS_MODE_DISABLED
	_solid = false
	if _body: _body.set_collision_layer_value(1, false)
