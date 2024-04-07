extends MultiplayerSpawner

func _enter_tree() -> void:
	if !spawned.is_connected(_on_spawn):
		spawned.connect(_on_spawn)

func _on_spawn(node: Node) -> void:
	if !node is Player: return
	if node.name == "1": return
	if node.name == str(multiplayer.get_unique_id()):
		node.set_player_name(Multiplayer.player_name)
	else:
		node.set_player_name(Multiplayer.players[str(node.name).to_int()])
	node.synced_position = Multiplayer.spawn_pos
	node.position = Multiplayer.spawn_pos
