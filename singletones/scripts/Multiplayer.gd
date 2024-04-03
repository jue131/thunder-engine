extends Node

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 14210

# Max number of players.
const MAX_PEERS = 4

var peer = null
var open_for_connections: bool = true

# Name for my player.
var player_name = "Mario"

# Names for remote players in id:name format.
var players = {}
var players_ready = []

var pending_scene: String = "res://engine/scenes/multiplayer/test.tscn"
var fallback_scene: String = "res://engine/scenes/multiplayer/empty.tscn"

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)


func _ready():
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connected_ok)
	multiplayer.connection_failed.connect(_connected_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)


# Callback from SceneTree.
func _player_connected(id):
	if !open_for_connections: return
	# Registration of a client beings here, tell the connected player that we are here.
	register_player.rpc_id(id, player_name)


# Callback from SceneTree.
func _player_disconnected(id):
	if Scenes.current_scene is Level || Scenes.current_scene is Map2D: # Game is in progress.
		if multiplayer.is_server():
			#game_error.emit("Player " + players[id] + " disconnected")
			print("Player " + players[id] + " disconnected")
			# Unregister this player.
			unregister_player(id)
			for i in Scenes.current_scene.get_node("Players").get_children():
				if str(i.name).to_int() == str(id).to_int():
					i.queue_free()
			#end_game()
	else: # Game is not in progress.
		unregister_player(id)


# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	# We just connected to a server
	connection_succeeded.emit()


# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	game_error.emit("Server disconnected")
	end_game()


# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	if multiplayer: multiplayer.set_network_peer(null) # Remove peer
	connection_failed.emit()


# Lobby management functions.
@rpc("any_peer")
func register_player(new_player_name):
	var id = multiplayer.get_remote_sender_id()
	players[id] = new_player_name
	player_list_changed.emit()


func unregister_player(id):
	if players.has(id):
		players.erase(id)
		player_list_changed.emit()


@rpc("call_local")
func load_world():
	# Change scene.
	Scenes.goto_scene(pending_scene)
	MpLobby.hide()

	# Set up score.
	#world.get_node("Score").add_player(multiplayer.get_unique_id(), player_name)
	#for pn in players:
	#	world.get_node("Score").add_player(pn, players[pn])
	
	(func():
		var hud_name = Thunder._current_hud.get_node("Control/MarioLives")
		hud_name.value_template = player_name.to_upper() + " ~ %s"
		hud_name._update_text()
	).call_deferred()
	get_tree().set_pause(false) # Unpause and unleash the game!


func host_game(new_player_name):
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(DEFAULT_PORT, MAX_PEERS)
	if err:
		game_error.emit("Could not create the game")
		return
	multiplayer.set_multiplayer_peer(peer)


func join_game(ip, new_player_name):
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, DEFAULT_PORT)
	if err:
		game_error.emit("Could not join the game")
		return
	multiplayer.set_multiplayer_peer(peer)


func get_player_list():
	return players.values()


func get_player_name():
	return player_name


func begin_game():
	assert(multiplayer.is_server())
	load_world.rpc()
	
	(func():
		var spawn_pos: Vector2 = Thunder._current_player.global_position
		Thunder._current_player.queue_free()
		var player_scene = load("res://engine/objects/players/mario/mp_mario.tscn")

		# Create a dictionary with peer id and respective spawn points, could be improved by randomizing.
		var spawn_points = {}
		spawn_points[1] = 0 # Server in spawn point 0.
		var spawn_point_idx = 1
		for p in players:
			spawn_points[p] = spawn_point_idx
			spawn_point_idx += 1


		for p_id in spawn_points:
			var pl_name = player_name.to_upper() if p_id == multiplayer.get_unique_id() else players[p_id]
			var player = player_scene.instantiate()
			player.synced_position = spawn_pos
			player.position = spawn_pos
			push_warning(p_id)
			player.name = str(p_id)
			player.set_player_name(pl_name)
			Scenes.current_scene.get_node("Players").add_child.call_deferred(player)
			
	).call_deferred()


func end_game():
	if Scenes.current_scene is Level || Scenes.current_scene is Map2D: # Game is in progress.
		# End it
		Scenes.goto_scene(fallback_scene)

	game_ended.emit()
	players.clear()
