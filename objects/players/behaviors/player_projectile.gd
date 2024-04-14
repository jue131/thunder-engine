extends SuitBehaviorData


func _physics_process(_delta: float) -> void:
	super(_delta)
	if !player || !behavior_resource || player.is_crouching || \
	player.warp > Player.Warp.NONE || player.is_climbing || \
	player.completed: return
	
	var bulls: StringName = StringName("bul" + behavior_resource.resource_name)
	var bull_count: int = player.get_tree().get_nodes_in_group(bulls).size()
	if player.attacked && bull_count < behavior_resource.amount:
		Audio.play_sound(behavior_resource.sound_attack, player, false)
		player.shot.emit()
		behavior_resource.create_projectile(player).add_to_group(bulls)
