extends Powerup

const explosion_effect = preload("res://engine/objects/effects/explosion/explosion.tscn")

func collect(player: Player) -> void:
	if appear_distance: return
	
	if player.is_invincible(): return
	player.die()
	
	NodeCreator.prepare_2d(explosion_effect, self).create_2d().bind_global_transform()
	queue_free()

