extends Area2D

const coin_effect: PackedScene = preload("res://engine/objects/effects/coin_effect/coin_effect.tscn")

@export var sound: AudioStream = preload("res://engine/objects/items/coin/coin.wav")


func _from_bumping_block() -> void:
	Audio.play_sound(sound, self)
	NodeCreator.prepare_2d(coin_effect, self).create_2d().bind_global_transform()
	Data.add_coin()
	queue_free()


func _physics_process(delta):
	for i in get_tree().get_nodes_in_group(&"Player"):
		if !is_instance_valid(i): continue
		if overlaps_body(i):
			collect.rpc()


@rpc("any_peer", "call_local")#, "reliable")
func collect() -> void:
	Data.add_coin()
	Data.values.score += 100
	
	NodeCreator.prepare_2d(coin_effect, self).call_method( func(eff: Node2D) -> void:
		eff.explode()
	).create_2d().bind_global_transform()
	
	Audio.play_sound(sound, self, false)
	queue_free()
