@tool
class_name BaseMover
extends StaticBody3D

signal start_opening
signal start_closing
signal start_moving
signal stop_moving
signal fully_opened
signal fully_closed
signal damage_taken
signal lock_changed

enum MoverState {
	OPENED,
	CLOSED,
	OPENING,
	CLOSING
}
var state := MoverState.CLOSED
var tween:Tween

@export var move_time:float = -1

@export var func_godot_properties : Dictionary#:
	#get:
		#return func_godot_properties
	#set(new_properties):
		#if(func_godot_properties  != new_properties):
			#func_godot_properties  = new_properties
			##update_properties()



func _ready() -> void:
	pass


func _func_godot_apply_properties(properties:Dictionary) -> void:
	#print(update_properties)
	if not Engine.is_editor_hint(): return

	if 'move_time' in properties :
		move_time = properties .move_time

	if 'name' in properties :
		name = properties .name







func _switch_state(st:MoverState, force:=false) -> void:
	if st == state and not force: return
	state = st


func _move(property:String, dest_value:Vector3, callback:Callable) -> void:
	#printt(_move, property, position, dest_value)
	tween = create_tween() #Tween.new()
	tween.connect("step_finished", callback)
	tween.set_parallel(true)
	tween.tween_property(self, property, dest_value, move_time)
	tween.play()


func trigger():
	toggle()


func _stop_moving():
	#print(_stop_moving)
	if not tween: return
	tween.stop()
	tween.kill()
	tween = null
	stop_moving.emit()


func open():
	#printt(open)
	if state == MoverState.CLOSED:
		start_opening.emit()
	start_moving.emit()
	_switch_state(MoverState.OPENING)


func close():
	#printt(close)
	if state == MoverState.OPENED:
		start_closing.emit()
	start_moving.emit()
	_switch_state(MoverState.CLOSING)


func toggle():
	#printt(toggle)
	match state:
		MoverState.OPENING:
			if tween: _stop_moving()
			else:     close()
		MoverState.CLOSING:
			if tween: _stop_moving()
			else:     open()
		MoverState.OPENED: close()
		MoverState.CLOSED: open()


func _on_fully_opened(_idx:int) -> void:
	#print(_on_fully_opened)
	_switch_state(MoverState.OPENED)
	fully_opened.emit()
	stop_moving.emit()

#	print(parent.entity.func_godot_properties .has("reset_delay"))
	if not "reset_delay" in func_godot_properties : return

	var reset_delay:float = func_godot_properties .reset_delay
	if reset_delay < 0: return

	if reset_delay > 0:
		await get_tree().create_timer(reset_delay).timeout

	close()


func _on_fully_closed(_idx:int) -> void:
	#print(_on_fully_closed)
	_switch_state(MoverState.CLOSED)
	fully_closed.emit()
	stop_moving.emit()




#func do_action(action:="", param:="") -> void:
	#if action == "": action = parent.entity.default_action
##	printt("Mover.do_action", action)
	#match action:
		#"toggle": toggle()
		#"open":   open()
		#"close":  close()

#func make_material_unique() -> void:
#	for i in mesh.get_surface_count():
#		mesh.surface_set_material(i, mesh.surface_get_material(i).duplicate())


#func highlight(enable:bool) -> void:
##	for i in mesh.get_surface_count():
##		mesh.surface_get_material(i).shading_mode = \
##			BaseMaterial3D.SHADING_MODE_UNSHADED \
##			if enable \
##			else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	#pass
