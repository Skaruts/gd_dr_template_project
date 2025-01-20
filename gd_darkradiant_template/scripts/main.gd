extends Node3D


func _ready() -> void:
	#print(OS.get_user_data_dir(), "\n\n\n")
	if $map.get_child_count() == 0:
		OS.alert("Need a map scene as child of 'main/map'")
		get_tree().quit()

	var map: GameMap = $map.get_child(0)
	$player.align_with_transform( map.get_player_start().transform )
