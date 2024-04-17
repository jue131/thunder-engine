extends Area2D

const coin_effect: PackedScene = preload("res://engine/objects/effects/coin_effect/coin_effect.tscn")

@export var sound: AudioStream = preload("res://engine/objects/items/coin/coin.wav")

@onready var vision: ActivationArea = $Activation

func _from_bumping_block() -> void:
	Audio.play_sound(sound, self)
	NodeCreator.prepare_2d(coin_effect, self).create_2d().bind_global_transform()
	if multiplayer.is_server():
		Data.add_coin()
	visible = false


func _physics_process(delta):
	if !vision.is_on_screen():
		return
	for i in get_tree().get_nodes_in_group(&"Player"):
		if !is_instance_valid(i): continue
		if overlaps_body(i) && visible && is_multiplayer_authority():
			collect.rpc()#_id(i.get_multiplayer_authority())


@rpc("call_local")#, "reliable")
func collect() -> void:
	if !is_inside_tree(): return
	Data.add_coin()
	Data.values.score += 100
	
	NodeCreator.prepare_2d(coin_effect, self).call_method( func(eff: Node2D) -> void:
		eff.explode()
	).create_2d().bind_global_transform()
	
	Audio.play_sound(sound, self, false)
	Multiplayer.host_free(get_path())
	#queue_free.call_deferred()
