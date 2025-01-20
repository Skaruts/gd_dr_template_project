@tool
class_name GameMap
extends FuncGodotMap

#const Player := preload("res://scenes/player.tscn")


var player_starts:Array
#var player:CharacterBody3D

func _ready() -> void:
	#super()

	if not Engine.is_editor_hint():
		player_starts = get_tree().get_nodes_in_group("info_player_start")


func get_player_start() -> Node3D:
	# this could be randomized, if more than one start exists
	return player_starts[0]
#
#
#func get_map():
	#return $FuncGodotMap
