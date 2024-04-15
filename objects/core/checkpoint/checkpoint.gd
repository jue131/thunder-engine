extends Area2D

@export var id: int = 0
@export var permanent_checked: bool
@export var sound = preload("res://engine/objects/core/checkpoint/sounds/switch.wav")
@export var voice_lines: Array[AudioStream] = [
	preload("res://engine/objects/core/checkpoint/sounds/voice1.ogg"),
	preload("res://engine/objects/core/checkpoint/sounds/voice2.ogg"),
	preload("res://engine/objects/core/checkpoint/sounds/voice3.ogg")
]

@onready var text = $Text
@onready var animation_player = $AnimationPlayer
@onready var animation_text_flying: AnimationPlayer = $TextFlying/AnimationTextFlying

@onready var alpha: float = text.modulate.a


func _ready() -> void:
	if Data.values.checkpoint == id:
		var player: Player = Thunder._current_player
		if player:
			player.global_position = global_position + Vector2.UP.rotated(global_rotation) * 16
		text.modulate.a = 1
		animation_player.play(&"checkpoint")


func _physics_process(delta) -> void:
	# Permanent checked
	if permanent_checked && id in Data.values.checked_cps:
		return
	# Activation
	var player: Player = Thunder._current_player
	if player && overlaps_body(player) && Data.values.checkpoint != id:
		activate.rpc()
	# Deactivation
	if Data.values.checkpoint != id && animation_player.current_animation == "checkpoint":
		animation_player.play(&"RESET")
		var tween = create_tween()
		tween.tween_property(text, ^"modulate:a", alpha, 0.2)


@rpc("any_peer", "call_local", "reliable")
func activate() -> void:
	Data.values.checkpoint = id
	Audio.play_1d_sound(sound, false)
	if Multiplayer.online_play:
		var pl: Player = Multiplayer.game.get_player(multiplayer.get_remote_sender_id())
		Multiplayer.game.spawn_pos = global_position + Vector2.UP.rotated(global_rotation) * 16
		Multiplayer.game.chat_message.emit(pl.get("nickname") + " got a checkpoint!")
	
	var tween = create_tween()
	tween.tween_property(text, ^"modulate:a", 1.0, 0.2)
	animation_player.play(&"checkpoint")
	animation_text_flying.play(&"triggered")
	
	get_tree().create_timer(0.5, false, true).timeout.connect(func() -> void:
		var pl: Player
		if Multiplayer.online_play:
			pl = Multiplayer.game.get_player(multiplayer.get_remote_sender_id())
		else:
			pl = Thunder._current_player
		if !pl: return
		Audio.play_sound(voice_lines[randi_range(0, len(voice_lines) - 1)], pl)
	)
	
	if permanent_checked && !id in Data.values.checked_cps:
		Data.values.checked_cps.append(id)
