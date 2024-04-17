extends Node

const PLAYER = preload("res://engine/objects/players/mario/mp_mario.tscn")
const SCREEN_AREA = preload("res://engine/objects/players/screen_area.tscn")
const MP_DATA = preload("res://engine/singletones/nodes/multiplayer/mp_data.tscn")

var default_lives: int = ProjectSettings.get_setting("application/thunder_settings/player/default_lives", 4)

@onready var sync_node: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var data_nodes: Node = $DataNodes

var player_spawner: MultiplayerSpawner
var player_area_spawner: MultiplayerSpawner

var spawn_pos: Vector2

# Player spectators.
var spectators: Array:
	set(new_array):
		spectators = new_array
		if !Multiplayer.mp_layer: return
		if str(multiplayer.get_unique_id()) in spectators:
			if currently_spectating in spectators:
				switch_spectating_player()
			start_spectating()
			return
		if new_array.size() > 0:
			Multiplayer.mp_layer.spectator.text = str(new_array.size()) + " players spectating"
			Multiplayer.mp_layer.spectator.visible = true
		else:
			Multiplayer.mp_layer.spectator.text = ""
			Multiplayer.mp_layer.spectator.visible = false
var currently_spectating: int = 0

# Gameplay variables
@export var level_time: int:
	set(new_time):
		if !Scenes.current_scene is Level:
			return
		level_time = new_time
		if !multiplayer.is_server():
			Data.values.time = new_time
@export var coins: int:
	set(new):
		coins = new
		if !multiplayer.is_server():
			Data.values.coins = coins
@export var level_completed: bool


# Signals for gameplay
signal chat_message(text: String) # Prints a system message on emit


func get_player(p_id: int) -> Player:
	for i in get_tree().get_nodes_in_group(&"Player"):
		if str(i.name) == str(p_id) && i is Player:
			return i
	return null

func add_player_data(p_id: int) -> Node:
	if !has_player_data(p_id):
		var mp_data = MP_DATA.instantiate()
		data_nodes.add_child(mp_data, true)
		mp_data.name = str(p_id)
		mp_data.lives = default_lives
		
		for i in buffer.keys():
			if str(i).to_int() == str(p_id).to_int():
				var j: Array = buffer[i]
				mp_data.set(j[0], j[1])
				break
		return mp_data
	else:
		return get_player_data(p_id)

func get_player_data(p_id: int) -> Node:
	for i in data_nodes.get_children():
		if str(i.name) == str(p_id) && i is Node:
			return i
	return null

func has_player_data(p_id: int) -> bool:
	return data_nodes.has_node(str(p_id))

var buffer: Dictionary = {}
@rpc("any_peer", "call_local", "reliable")
func set_player_data(property: StringName, value: Variant) -> void:
	var p_id: int = multiplayer.get_remote_sender_id()
	if has_player_data(p_id):
		var pl_data = get_player_data(p_id)
		if str(pl_data.name).to_int() != p_id:
			return
		get_player_data(p_id).set(property, value)
		return
	buffer[p_id] = [property, value]

@rpc("any_peer", "call_remote", "unreliable")
func set_player_data_unreliable(property: StringName, value: Variant) -> void:
	var p_id: int = multiplayer.get_remote_sender_id()
	if has_player_data(p_id):
		var pl_data = get_player_data(p_id)
		if str(pl_data.name).to_int() != p_id:
			return
		pl_data.set(property, value)


@rpc("authority", "call_local", "reliable", 3)
func respawn_player(id: int) -> void:
	if !id:
		printerr("NO ID")
		return
		
	if has_player_data(id):
		get_player_data(id).lives -= 1
	
	if !multiplayer.is_server():
		return
	
	var players = get_tree().get_nodes_in_group(&"Player")
	for i in players:
		if i.name == str(id):
			i.queue_free()
			#print("[Multiplayer] User already exists! Skipped respawning.")
			#i.visible = true
			#return
	player_spawner.add_player.call_deferred(
		{
			"id": id,
			"respawned": true
		}
	)


@rpc("any_peer", "call_remote", "reliable", 3)
func player_died(p_id) -> void:
	var player: Player = get_player(p_id)
	if !player: return
	if player.warp != player.Warp.NONE: return
	chat_message.emit("Player " + Multiplayer.players[p_id] + " died!")
	
	if player.death_body:
		NodeCreator.prepare_2d(player.death_body, player).bind_global_transform().call_method(
			func(db: Node2D) -> void:
				db.animation_only = true
				db.p_id = p_id
				if player.death_sprite:
					var dsdup: Node2D = player.death_sprite.duplicate()
					db.add_child(dsdup)
					dsdup.visible = true
		).create_2d()
	player.visible = false
	player.is_dying = true
	player.set_physics_process(false)
	player.suit.process_mode = Node.PROCESS_MODE_DISABLED


@rpc("authority", "call_local", "reliable", 3)
func all_players_died() -> void:
	var pl: Player = Thunder._current_player
	if !pl: return
	pl.die({ "force_death": true })


@rpc("authority", "call_local", "reliable", 3)
func all_players_add_life(amount: int) -> void:
	Thunder.add_lives(1)


@rpc("any_peer", "call_remote", "reliable", 3)
func make_player_visible(p_id) -> void:
	for i in get_tree().get_nodes_in_group(&"Player"):
		if str(i.name) == str(p_id):
			i.visible = true
			i.is_dying = false
			if i.suit:
				i.suit.set_physics_process(true)
			break


@rpc("any_peer", "call_local", "reliable")
func player_changed_suit(suit_path: String, appear: bool, forced: bool, send_signal: bool) -> void:
	var p_id: int = multiplayer.get_remote_sender_id()
	var player: Player = get_player(p_id)
	if !player: return
	if !suit_path: return
	
	print_debug("test")
	#player_data[p_id][1] = suit_path
	player.mp_change_suit.rpc_id(p_id, suit_path, appear, forced, send_signal, {"rpc": true, "no_duplicate": true})


@rpc("authority", "call_local", "reliable")
func finish_level(p_id: int):
	level_completed = true
	chat_message.emit(str(p_id) + " finished the level!")
	
	if p_id == multiplayer.get_unique_id():
		return
	
	var pl = get_player(multiplayer.get_unique_id())
	if !pl || !pl.completed:
		pl.visible = false
		pl.warp = pl.Warp.IN
		pl.suit.set_physics_process(false)
		pl.set_physics_process(false)
	spectators.append(multiplayer.get_unique_id())
	start_spectating()


func start_spectating() -> void:
	if !multiplayer.get_unique_id() in spectators: return
	print("[Multiplayer] [CLIENT] No lives left! Switching to Spectator Mode.")
	switch_spectating_player()


func switch_spectating_player() -> void:
	var spectating_plr: Player = null
	for i in get_tree().get_nodes_in_group(&"Player"):
		if !i.is_inside_tree(): continue
		if !is_instance_valid(i): continue
		if i.is_dying && !i.completed: continue
		currently_spectating = str(i.name).to_int()
		if currently_spectating in spectators: continue
		if !has_player_data(currently_spectating): continue
		
		spectating_plr = i
	
	if spectating_plr:
		var pl_lives: int = get_player_data(currently_spectating).lives
		Multiplayer.mp_layer.spectator.text = Multiplayer.mp_layer.default_spectator_text % [
			Multiplayer.get_player_name(currently_spectating), # Player Name
			pl_lives # Lives
		]
		Multiplayer.mp_layer.spectator.visible = true
