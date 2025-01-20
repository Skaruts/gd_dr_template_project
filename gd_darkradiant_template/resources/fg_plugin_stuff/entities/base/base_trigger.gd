@tool
class_name BaseTrigger
extends Area3D

signal triggered

#@export var map:FuncQodotMap
# can be triggered
#    on enter / exit
#    on fully inside / outside

enum { # who can trigger it?
	NONE = 0,
	PLAYER = 1,
	FRIENDLES = 2,
	HOSTILES = 4,
	NPCS = 6,  # FRIENDLES | HOSTILES
	PHYSICS_OBJECTS,
	ALL,
}

#var body:Node3D

var disabled:bool
@export var unique_user := ""
@export var target:Node3D
@export var reset_delay := 1.0
@export var func_godot_properties: Dictionary#:
	#get:
		#return func_godot_properties
	#set(new_properties):
		#if(func_godot_properties != new_properties):
			#func_godot_properties = new_properties
			#update_properties()


func _init() -> void:
	monitorable = false
	##trigger_on = "start_touch"
	#if Engine.is_editor_hint(): return
	##add_to_group("brush_entities")


func _ready() -> void:
	set_process(false)
	set_physics_process(false)

	#if Engine.is_editor_hint():
		#get_parent().build_complete.connect(_build_complete)

	if Engine.is_editor_hint(): return

	#if "target" in func_godot_properties:
		#printt("target", func_godot_properties.target)
		#var node: Node3D = get_parent().get_node_or_null(NodePath(func_godot_properties.target))
		#if node:
			#print(node)
			#target = node
		#else:
			#print(NodePath(func_godot_properties.target))
	#printt("target", target)

	#if not disabled:
		#flags = Entity.EntityFlags.PLAYER
	connect_signal(body_entered, _on_body_entered)
	connect_signal(body_exited, _on_body_exited)


#func _get_default_output() -> Dictionary:
	#var o := super()
	#o.event = "start_touch"
	#return o.duplicate()


#func do_action(action:="", param:="") -> void:
	#match action:
		#"toggle": toggle()
		#"enable": enable()
		#"disable": disable()

func toggle():
	disabled = not disabled

func disable():
	disabled = true

func enable():
	disabled = false



func connect_signal(s:Signal, f:Callable) -> void:
	if s.is_connected(f): return
	s.connect(f)

func disconnect_signal(s:Signal, f:Callable) -> void:
	if not s.is_connected(f): return
	s.disconnect(f)



func _func_godot_apply_properties(properties:Dictionary) -> void:
	if "start_disabled" in properties :
		disabled = bool(properties .start_disabled)
		#"trigger_on":
			#trigger_on = [
				#"start_touch", "end_touch",
			#][val.to_int()]
			#printerr("trigger_on: %s\t%s " % [trigger_on, val.to_int()])
	if "unique_user" in properties :
		unique_user = properties .unique_user

	if "reset_delay" in properties :
		reset_delay = properties .reset_delay

	#if "target" in properties :
		#printt("target", properties .target)
		#var node: Node3D = get_parent().get_node_or_null(NodePath(properties .target))
		#if node:
			##print(node)
			##target = node
			#node.connect("triggered", Callable(node,"test_trigger"), CONNECT_PERSIST)
		#else:
			#print(NodePath(properties .target))



func _func_godot_build_complete() -> void:
	var map:FuncGodotMap = get_parent()
	if "target"  in func_godot_properties:
		#printt("target", func_godot_properties.target)
		var node: Node3D = map.get_node_or_null(NodePath(func_godot_properties.target))
		if node:
			#print(node)
			#target = node
			connect("triggered", Callable(node, "trigger"), CONNECT_PERSIST)
			#node.connect()
		else:
			print(NodePath(func_godot_properties.target))

	if "parent" in func_godot_properties:
		FGUtils.reparent_entity(self, func_godot_properties.parent, map)
		#var parent := map.get_node_or_null(NodePath(func_godot_properties.parent))
		#if parent:
			#var old_owner = owner
			#reparent(parent)
			#owner = old_owner





func _start_timer() -> void:
	if reset_delay <= 0: return
	disable()
	await get_tree().create_timer(reset_delay).timeout
	enable()


func trigger() -> void:
	triggered.emit()
	_start_timer()


func _on_body_entered(new_body: Node3D) -> void:
	#printt(_on_body_entered, disabled)
	if disabled: return
	if not unique_user in ["", "-", new_body.name]: return
	trigger()

func _on_body_exited(new_body: Node3D) -> void:
	#printt(_on_body_exited, disabled)
	if disabled: return
	if not unique_user in ["", "-", new_body.name]: return
	#trigger()
