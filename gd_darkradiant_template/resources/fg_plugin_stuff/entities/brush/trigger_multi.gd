@tool
class_name TriggerMulti
extends BaseTrigger



#@export var reset_delay := 1.0
#var timer := 0.0

#func update_properties() -> void:
	#super()
	#if "reset_delay" in func_godot_properties:
		#reset_delay = func_godot_properties.reset_delay



#func _process(delta: float) -> void:
##	var old_timer = timer
	#timer -= delta
	#if timer <= 0:
		#_on_timer_timeout()
	##printt(timer, reset_delay, delta)

func _on_timer_timeout() -> void:
	#set_process(false)
	enable()
	#timer = 0


func _start_timer() -> void:
	#timer = reset_delay
	#set_process(true)

	if reset_delay <= 0: return
	disable()

	await get_tree().create_timer(reset_delay).timeout

	enable()



#func _on_body_entered(body: Node3D) -> void:
	#if disabled: return
	#super(body)
#
#func _on_body_exited(body: Node3D) -> void:
	#if disabled: return
	#super(body)

#func trigger_outputs(event:String) -> bool:
func trigger() -> void:
	#printt(trigger, reset_delay)
	_start_timer()
	super()
	#if not super(event): return false
	#return true
