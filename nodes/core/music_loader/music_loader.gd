extends Node

@export var music: Array[AudioStream]
@export var index: int = 0:
	set(i):
		index = i
		_change_music(i, channel_id)

@export var channel_id: int = 1

func _ready() -> void:
	_change_music(index, channel_id)

func _change_music(index: int, channel_id: int) -> void:
	if len(music) <= index: return
	Audio.play_music(music[index], channel_id)
