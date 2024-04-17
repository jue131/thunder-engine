extends Powerup

@rpc("any_peer", "call_local", "reliable")
func collect() -> void:
	Thunder.add_lives(1)
	Audio.play_sound(preload("res://engine/objects/players/prefabs/sounds/1up.wav"), self)
	if Multiplayer.is_host():
		Multiplayer.host_free(get_path())
