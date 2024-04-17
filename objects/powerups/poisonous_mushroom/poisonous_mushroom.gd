extends Powerup

const explosion_effect = preload("res://engine/objects/effects/explosion/explosion.tscn")

@rpc("any_peer", "call_local", "reliable")
func collect() -> void:
	if appear_distance: return
	var player = Multiplayer.game.get_player(multiplayer.get_remote_sender_id())
	if !player: return
	
	if player.is_invincible(): return
	player.die()
	
	NodeCreator.prepare_2d(explosion_effect, self).create_2d().bind_global_transform()
	if Multiplayer.is_host():
		Multiplayer.host_free(get_path())

