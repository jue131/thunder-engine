extends Node

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 14210

# Max number of players.
const MAX_PEERS = 4

const MP_LAYER = preload("res://engine/scenes/multiplayer/mp_layer.tscn")

var mp_layer: CanvasLayer: # Reference to the current player
	set(node):
		assert(is_instance_valid(node) && (node is CanvasLayer), "mp_layer node is invalid")
		mp_layer = node
	get:
		if !is_instance_valid(mp_layer): return null
		return mp_layer

var peer = null
var online_play: bool = false

# Name for my player.
var player_name = "Mario"

# Names for remote players in id:name format.
var players = {}
var players_ready = []

@export_file("*.tscn", "*.scn") var initial_scene: String = "res://engine/scenes/multiplayer/test.tscn"
#var pending_scene: String = "res://engine/scenes/save_game_room/save_game_room_template.tscn"
var fallback_scene: String = "res://engine/scenes/multiplayer/empty.tscn"

@onready var game: Node = $MPGame
@onready var net: Node = $Net

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
	# Receiving a packet with textures from peers
	multiplayer.peer_packet.connect(UserSkin.get_texture_bytes)


# Callback from SceneTree.
func _player_connected(id):
	# Registration of a client beings here, tell the connected player that we are here.
	register_player.rpc_id(id, player_name, game.default_lives, Thunder._current_player_state)


# Callback from SceneTree.
func _player_disconnected(id):
	if game.spectators.has(id):
		game.spectators.remove_at(game.spectators.find(id))
	if Scenes.current_scene is Level || Scenes.current_scene is Map2D: # Game is in progress.
		if multiplayer.is_server():
			#game_error.emit("Player " + players[id] + " disconnected")
			print("Player " + players[id] + " disconnected")
			game.chat_message.emit("Player " + players[id] + " disconnected")
			# Unregister this player.
			unregister_player(id)
			var pls = get_tree().get_nodes_in_group(&"Player")
			for i in pls:
				if str(i.name) == str(id):
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
@rpc("any_peer", "call_local")
func register_player(new_player_name, new_lives, new_state):
	var id = multiplayer.get_remote_sender_id()
	if UserSkin.custom_textures.is_empty():
		print("Using standard textures for ", id)
	else:
		multiplayer.send_bytes(UserSkin.send_texture_bytes(id))
	players[id] = new_player_name
	player_list_changed.emit()


func unregister_player(id):
	if players.has(id):
		players.erase(id)
		if game.has_player_data(id):
			game.get_player_data(id).queue_free()
		player_list_changed.emit()


@rpc("call_local")
func load_world():
	online_play = true
	game.spectators = []
	print("[Multiplayer] Game started!")
	# Change scene.
	if !Scenes.scene_changed.is_connected(_scene_changed):
		Scenes.scene_changed.connect(_scene_changed)
	if multiplayer.is_server():
		Scenes.goto_scene(initial_scene)
		multiplayer.refuse_new_connections = true
	MpLobby.hide()
	
	get_tree().set_pause(false) # Unpause and unleash the game!


func _scene_changed(scene: Node) -> void:
	# Set up multiplayer chat.
	if !mp_layer:
		var mp_layer_node = MP_LAYER.instantiate()
		GlobalViewport.vp.add_child(mp_layer_node)
		print("[Multiplayer] Multiplayer Chat added.")
		mp_layer = mp_layer_node
		mp_layer._update_chat.call_deferred()
		mp_layer._update_lives_count()
	
	if multiplayer.multiplayer_peer && multiplayer.is_server():
		# All peers will go to the same scene as the server
		print("[Multiplayer] [SERVER] Attempting to move all peers to the current scene.")
		_peers_goto_scene.rpc(scene.scene_file_path)
		_player_connected(1)
	
	game.level_completed = false
	if !scene is Level: return
	
	# Get spawn position.
	var first_player = get_tree().get_first_node_in_group(&"Player")
	#print(first_player)
	game.spawn_pos = first_player.global_position
	if is_instance_valid(first_player): first_player.queue_free()
	
	if multiplayer.is_server():
		# Add players to Level
		var plrs = players.keys()
		#plrs.append(1)
		for i in plrs:
			game.player_spawner.spawn.call_deferred(i)
	
	var hud_name = Thunder._current_hud.get_node("Control/MarioLives")
	hud_name.value_template = player_name.to_upper() + " ~ %s"
	hud_name._update_text()


@rpc("authority", "call_remote", "reliable", 1)
func _peers_goto_scene(scene: String) -> void:
	print("[Multiplayer] [CLIENT] Got a request to move to a different scene. Changing scenes...")
	Scenes.goto_scene(scene)
	MpLobby.hide()


func host_game(new_player_name) -> bool:
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(DEFAULT_PORT, MAX_PEERS)
	if err:
		game_error.emit("Could not create the game")
		return false
	
	multiplayer.set_multiplayer_peer(peer)
	return true


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


func get_player_name(peer_id: int) -> String:
	return player_name if peer_id == multiplayer.get_unique_id() else players[peer_id]


func begin_game():
	if !multiplayer.is_server():
		return
	load_world.rpc()
	
	#(func():
		#spawn_pos: Vector2 = Scenes.current_scene.get_node("PlayerSpawn").global_position
	#	Thunder._current_player.queue_free()
		
		# Set up players.
		#var play_node = Scenes.current_scene.get_node("Players")
		#add_player(multiplayer.get_unique_id(), player_name, play_node)
		#for pn in players:
		#	add_player(pn, players[pn], play_node)

		# Create a dictionary with peer id and respective spawn points, could be improved by randomizing.
		#var spawn_points = {}
		#spawn_points[1] = 0 # Server in spawn point 0.
		#var spawn_point_idx = 1
		#for p in players:
		#	spawn_points[p] = spawn_point_idx
		#	spawn_point_idx += 1


		#for p_id in spawn_points:
		#	add_player(p_id, play_node)
			#var pl_name = player_name.to_upper() if p_id == multiplayer.get_unique_id() else players[p_id]
			#var player = PLAYER.instantiate()
			#player.synced_position = spawn_pos
			#player.position = spawn_pos
			#push_warning(p_id)
			#player.name = str(p_id)
			#player.set_player_name(pl_name)
			#play_node.add_child.call_deferred(player)
			
	#).call_deferred()


func end_game() -> void:
	if Scenes.current_scene is Level || Scenes.current_scene is Map2D: # Game is in progress.
		# End it
		Scenes.goto_scene(fallback_scene)

	print("[Multiplayer] Game ended! Turning Singleplayer Mode back on.")
	game_ended.emit()
	players.clear()
	online_play = false
	if is_instance_valid(mp_layer):
		mp_layer.queue_free()


func is_host() -> bool:
	return (multiplayer && multiplayer.is_server()) || !Multiplayer.online_play


@rpc("authority", "call_local", "reliable")
func host_free(node_path: NodePath) -> void:
	if !node_path: return
	var node = get_node_or_null(node_path)
	if is_instance_valid(node):
		node.queue_free()


@rpc("any_peer", "call_local", "reliable")
func call_to_server(node_path: NodePath, method_name: StringName, argument: Variant) -> void:
	if !node_path: return
	assert(!argument is Object, "Passing objects in arguments is not supported")
	#if multiplayer.get_unique_id() != get_multiplayer_authority(): return
	var node = get_node_or_null(node_path)
	if is_instance_valid(node):
		node.rpc(method_name, argument)
