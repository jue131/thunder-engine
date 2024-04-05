extends CanvasLayer

@onready var chat: Label = $Chat
@onready var spectator: Label = $Spectator
@onready var enter_msg: LineEdit = $EnterMsg


func _on_enter_msg_focus_entered() -> void:
	Multiplayer.entering_message = true
	input_set_focus(true)


func _on_enter_msg_focus_exited() -> void:
	Multiplayer.entering_message = false
	input_set_unfocus(true)


func input_set_focus(loop: bool = false) -> void:
	if tw: tw.kill()
	chat.self_modulate.a = 1.0
	enter_msg.self_modulate.a = 1.0
	
	if !loop: enter_msg.grab_focus.call_deferred()
	enter_msg.placeholder_text = ""
	
	
func input_set_unfocus(loop: bool = false) -> void:
	enter_msg.self_modulate.a = 0.5
	
	if !loop: enter_msg.release_focus.call_deferred()
	enter_msg.placeholder_text = "Press Enter..."
	if tw: tw.kill()
	tw = create_tween()
	tw.tween_property(chat, "self_modulate:a", 0.5, 2.0)


var tw: Tween
func _update_chat() -> void:
	chat.text = "\n".join(Multiplayer.chat)
	if Multiplayer.entering_message: return
	if tw: tw.kill()
	tw = create_tween()
	tw.tween_property(chat, "self_modulate:a", 1.0, 0.15)
	tw.tween_interval(2.0)
	tw.tween_property(chat, "self_modulate:a", 0.5, 2.0)
