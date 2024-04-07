extends CanvasLayer

@onready var chat_labels: Node = $ChatLabels
@onready var spectator: Label = $Spectator
@onready var enter_msg: LineEdit = $EnterMsg
@onready var lives: Label = $Lives

@onready var default_spectator_text: String = spectator.text
var force_highlight_chat: bool = false

func _ready() -> void:
	Multiplayer.player_data_changed.connect(_update_lives_count)


func _on_enter_msg_focus_entered() -> void:
	Multiplayer.entering_message = true
	input_set_focus(true)


func _on_enter_msg_focus_exited() -> void:
	Multiplayer.entering_message = false
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
		chats[i].text = Multiplayer.chat[i]
		if i > 0:
			chats[i - 1].modulation = chats[i].modulation
	chats.back().highlight()


func _update_lives_count() -> void:
	lives.text = ""
	var pl_data: Dictionary = Multiplayer.player_data
	for i in pl_data:
		lives.text += str(pl_data[i][0]) + "\n"
