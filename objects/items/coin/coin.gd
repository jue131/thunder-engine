extends Area2D

const coin_effect: PackedScene = preload("res://engine/objects/effects/coin_effect/coin_effect.tscn")

@export var sound: AudioStream = preload("res://engine/objects/items/coin/coin.wav")
var has_collected: bool = false


func _from_bumping_block() -> void:
	Audio.play_sound(sound, self)
	NodeCreator.prepare_2d(coin_effect, self).create_2d().bind_global_transform()
	Data.add_coin()
	queue_free()


func _physics_process(delta):
	for i in get_tree().get_nodes_in_group(&"Player"):
		if !is_instance_valid(i): continue
		if overlaps_body(i) && !has_collected && is_multiplayer_authority():
			collect.rpc()#_id(i.get_multiplayer_authority())


@rpc("call_local")#, "reliable")
func collect() -> void:
	if !is_inside_tree(): return
	has_collected = true
	Data.add_coin()
	Data.values.score += 100
	
	NodeCreator.prepare_2d(coin_effect, self).call_method( func(eff: Node2D) -> void:
		eff.explode()
	).create_2d().bind_global_transform()
	
	Audio.play_sound(sound, self, false)
	visible = false
	#queue_free.call_deferred()
