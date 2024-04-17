extends MultiplayerSpawner

func _enter_tree():
	spawn_function = spawn_area

func _ready() -> void:
	Multiplayer.game.player_area_spawner = self

func add_area(id: int) -> Player:
	return spawn(id)

func spawn_area(id):
	var area = Multiplayer.game.SCREEN_AREA.instantiate()
	
	area.name = str(id)
	area.set_meta(&"mp_spawn", true)
	if multiplayer.get_unique_id() == id:
		area.set_meta(&"area_for_self", true)
	return area
