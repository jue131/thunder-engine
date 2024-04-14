extends Node

@export var lives: int
@export var player_cam_pos: Vector2 = Vector2.ZERO
@export var suit: String

#func _ready() -> void:
#	if str(name).is_valid_int():
#		inputs_sync.set_multiplayer_authority(str(name).to_int())

func get_suit() -> String:
	return suit
