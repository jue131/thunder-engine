extends CanvasLayer

@onready var chat_labels: Node = $ChatLabels
@onready var spectator: Label = $Spectator
@onready var enter_msg: LineEdit = $EnterMsg
@onready var lives: Label = $Lives

@onready var default_spectator_text: String = spectator.text
var force_highlight_chat: bool = false

## Chat message history (6 lines)
var chat: Array[String] = ["","","","","",""]
var entering_message: bool = false

func _ready() -> void:
	Thunder._connect(Multiplayer.game.chat_message, _print_system_message)

func _physics_process(delta) -> void:
	_update_lives_count()


func _on_enter_msg_focus_entered() -> void:
	entering_message = true
	input_set_focus(true)


func _on_enter_msg_focus_exited() -> void:
	entering_message = false
	input_set_unfocus(true)


func input_set_focus(loop: bool = false) -> void:
	force_highlight_chat = true
	enter_msg.self_modulate.a = 1.0
	
	if !loop: enter_msg.grab_focus.call_deferred()
	enter_msg.placeholder_text = ""
	
	
func input_set_unfocus(loop: bool = false) -> void:
	enter_msg.self_modulate.a = 0.5
	
	if !loop: enter_msg.release_focus.call_deferred()
	enter_msg.placeholder_text = ""
	force_highlight_chat = false


var tw: Tween
func _update_chat() -> void:
	var chats: Array = chat_labels.get_children()
	for i in chats.size():
		chats[i].text = chat[i]
		if i > 0:
			chats[i - 1].modulation = chats[i].modulation
	chats.back().highlight()


func _update_lives_count() -> void:
	lives.text = ""
	for i in Multiplayer.game.data_nodes.get_children():
		lives.text += str(i.lives) + "\n"


func _print_system_message(text) -> void:
	chat.remove_at(0)
	chat.append(text)
	_update_chat()


@rpc("any_peer", "call_local", "reliable", 2)
func _print_message(text: String) -> void:
	text = text.strip_escapes().strip_edges()
	var p_id = multiplayer.get_remote_sender_id()
	var sender_name: String = Multiplayer.get_player_name(p_id)
	text = "[%s] " % [sender_name] + text
	chat.remove_at(0)
	chat.append(text)
	_update_chat()


func _input(event: InputEvent) -> void:
	if !event is InputEventKey || !event.is_pressed():
		return
	match event.keycode:
		KEY_ENTER:
			#if !mp_layer:
			#	entering_message = false
			#	return
			
			entering_message = !entering_message
			
			if entering_message:
				input_set_focus()
			else:
				var entered_text: String = enter_msg.text
				if entered_text.length() > 0:
					if entered_text.length() > 64:
						entered_text = entered_text.left(64)
					_print_message.rpc(
						entered_text
					)
				input_set_unfocus()
				enter_msg.text = ""
		KEY_TAB:
			if multiplayer.get_unique_id() in Multiplayer.game.spectators:
				Multiplayer.game.switch_spectating_player()
