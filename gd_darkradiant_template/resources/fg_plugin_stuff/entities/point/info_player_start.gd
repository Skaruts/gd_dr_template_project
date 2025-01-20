@tool
class_name InfoPlayerStart
extends Node3D


# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#$MeshInstance3D.scale = 1.0/get_parent().inverse_scale_factor
	#if not Engine.is_editor_hint():
		#visible = false

func _ready() -> void:
	add_to_group("info_player_start")
	if not Engine.is_editor_hint():
		visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
