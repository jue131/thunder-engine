extends MultiplayerSpawner

func _enter_tree():
	spawn_function = spawn_player

func _ready() -> void:
	Multiplayer.game.player_spawner = self

func add_player(data: Dictionary) -> Player:
	return spawn(data)

func spawn_player(data):
	var id
	var respawned: bool = false
	if data is Dictionary:
		if !"id" in data: return
		id = data.id
		if "respawned" in data && data.respawned == true:
			respawned = true
	elif data is int:
		id = data
	var player = Multiplayer.game.PLAYER.instantiate()
	Multiplayer.game.add_player_data(id)
	#if !had_data:
	#	p_data.lives = 4
	
	player.name = str(id)
	player.synced_position = Multiplayer.game.spawn_pos
	player.position = Multiplayer.game.spawn_pos
	player.set_player_name(Multiplayer.get_player_name(id).to_upper())
	if respawned:
		player.invincible.call_deferred(0.6)
	
	if is_multiplayer_authority():# && id != multiplayer.get_unique_id():
		Multiplayer.game.player_area_spawner.add_area(id)
	return player
