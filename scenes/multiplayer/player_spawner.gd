extends MultiplayerSpawner

func _enter_tree() -> void:
	if !spawned.is_connected(_on_spawn):
		spawned.connect(_on_spawn)

func _on_spawn(node: Node) -> void:
	if !node is Player: return
	if node.name == "1": return
	node.set_player_name(Multiplayer.player_name)
	node.synced_position = Multiplayer.spawn_pos
	node.position = Multiplayer.spawn_pos
	print(Multiplayer.spawn_pos)
