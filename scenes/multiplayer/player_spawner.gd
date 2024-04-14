extends MultiplayerSpawner

func _enter_tree():
	spawn_function = spawn_player

func _ready() -> void:
	Multiplayer.game.player_spawner = self

func add_player(id):
	spawn(id)

func spawn_player(id):
	var player = Multiplayer.game.PLAYER.instantiate()
	var had_data: bool = Multiplayer.game.has_player_data(id)
	var p_data = Multiplayer.game.add_player_data(id)
	#if !had_data:
	#	p_data.lives = 4
	
	player.name = str(id)
	player.synced_position = Multiplayer.game.spawn_pos
	player.position = Multiplayer.game.spawn_pos
	player.set_player_name(Multiplayer.get_player_name(id).to_upper())
	return player
