extends Node

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 14210

# Max number of players.
const MAX_PEERS = 4

const PLAYER = preload("res://engine/objects/players/mario/mp_mario.tscn")
const MP_LAYER = preload("res://engine/scenes/multiplayer/mp_layer.tscn")
var chat: Array[String] = ["\n","\n","\n","\n","\n"]
var entering_message: bool = false

var mp_layer: CanvasLayer: # Reference to the current player
	set(node):
		assert(is_instance_valid(node) && (node is CanvasLayer), "mp_layer node is invalid")
		mp_layer = node
	get:
		if !is_instance_valid(mp_layer): return null
		return mp_layer

var peer = null
var open_for_connections: bool = true
var online_play: bool = false

# Name for my player.
var player_name = "Mario"

# Names for remote players in id:name format.
var players = {}
var players_ready = []
var spectators: Array

var pending_scene: String = "res://engine/scenes/multiplayer/test.tscn"
#var pending_scene: String = "res://engine/scenes/save_game_room/save_game_room_template.tscn"
var fallback_scene: String = "res://engine/scenes/multiplayer/empty.tscn"

var spawn_pos: Vector2

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)
signal chat_message(text: String)


func _ready():
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connected_ok)
	multiplayer.connection_failed.connect(_connected_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)
	chat_message.connect(_print_system_message)


# Callback from SceneTree.
func _player_connected(id):
	if !open_for_connections: return
	# Registration of a client beings here, tell the connected player that we are here.
	register_player.rpc_id(id, player_name)


# Callback from SceneTree.
func _player_disconnected(id):
	if spectators.has(id):
		spectators.remove_at(spectators.find(id))
	if Scenes.current_scene is Level || Scenes.current_scene is Map2D: # Game is in progress.
		if multiplayer.is_server():
			#game_error.emit("Player " + players[id] + " disconnected")
			print("Player " + players[id] + " disconnected")
			chat_message.emit("Player " + players[id] + " disconnected")
			# Unregister this player.
			unregister_player(id)
			if Scenes.current_scene.get_node("Players").has_node(str(id)):
				Scenes.current_scene.get_node("Players").get_node(str(id)).queue_free()
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
	online_play = true
	# Change scene.
	Scenes.goto_scene(pending_scene)
	MpLobby.hide()
	
	(func():
		# Set up multiplayer chat.
		if !mp_layer:
			var mp_layer_node = MP_LAYER.instantiate()
			GlobalViewport.vp.add_child(mp_layer_node)
			mp_layer = mp_layer_node
			mp_layer._update_chat.call_deferred()
		
		# Get spawn position.
		var first_player = get_tree().get_first_node_in_group(&"Player")
		#print(first_player)
		spawn_pos = first_player.global_position
		if is_instance_valid(first_player): first_player.queue_free()
		
		var hud_name = Thunder._current_hud.get_node("Control/MarioLives")
		hud_name.value_template = player_name.to_upper() + " ~ %s"
		hud_name._update_text()
	).call_deferred()
	get_tree().set_pause(false) # Unpause and unleash the game!


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


func add_player(peer_id, parent) -> void:
	var pl_name = player_name.to_upper() if peer_id == multiplayer.get_unique_id() else players[peer_id]
	var player = PLAYER.instantiate()
	player.synced_position = spawn_pos
	player.position = spawn_pos
	print(str(peer_id))
	player.name = str(peer_id)
	player.set_player_name(pl_name)
	parent.add_child.call_deferred(player)

@rpc("any_peer", "call_local", "reliable", 1)
func respawn_player() -> void:
	var id = multiplayer.get_remote_sender_id()
	var pl_node = Scenes.current_scene.get_node("Players")
	for i in pl_node.get_children():
		if i.name == str(id):
			print("User already exists! Skipped respawning.")
			return
		
	add_player(id, Scenes.current_scene.get_node("Players"))
	

func get_player_list():
	return players.values()


func get_player_name() -> String:
	return player_name


func begin_game():
	assert(multiplayer.is_server())
	load_world.rpc()
	
	(func():
		#spawn_pos: Vector2 = Scenes.current_scene.get_node("PlayerSpawn").global_position
		Thunder._current_player.queue_free()
		
		# Set up players.
		var play_node = Scenes.current_scene.get_node("Players")
		#add_player(multiplayer.get_unique_id(), player_name, play_node)
		#for pn in players:
		#	add_player(pn, players[pn], play_node)

		# Create a dictionary with peer id and respective spawn points, could be improved by randomizing.
		var spawn_points = {}
		spawn_points[1] = 0 # Server in spawn point 0.
		var spawn_point_idx = 1
		for p in players:
			spawn_points[p] = spawn_point_idx
			spawn_point_idx += 1


		for p_id in spawn_points:
			var pl_name = player_name.to_upper() if p_id == multiplayer.get_unique_id() else players[p_id]
			var player = PLAYER.instantiate()
			player.synced_position = spawn_pos
			player.position = spawn_pos
			push_warning(p_id)
			player.name = str(p_id)
			player.set_player_name(pl_name)
			play_node.add_child.call_deferred(player)
			
	).call_deferred()


func end_game() -> void:
	if Scenes.current_scene is Level || Scenes.current_scene is Map2D: # Game is in progress.
		# End it
		Scenes.goto_scene(fallback_scene)

	game_ended.emit()
	players.clear()
	online_play = false


func _print_system_message(text) -> void:
	chat.remove_at(0)
	chat.append(text)
	if mp_layer:
		mp_layer._update_chat()

@rpc("any_peer", "call_local", "reliable", 2)
func _print_message(text: String) -> void:
	text = text.strip_escapes().strip_edges()
	var p_id = multiplayer.get_remote_sender_id()
	var sender_name: String = player_name if p_id == multiplayer.get_unique_id() else players[p_id]
	text = "[%s] " % [sender_name] + text
	chat.remove_at(0)
	chat.append(text)
	if mp_layer:
		mp_layer._update_chat()


func _input(event: InputEvent) -> void:
	if event is InputEventKey && event.keycode == KEY_ENTER && event.is_pressed():
		if !mp_layer:
			entering_message = false
			return
		
		entering_message = !entering_message
		
		if entering_message:
			mp_layer.input_set_focus()
		else:
			var entered_text: String = mp_layer.enter_msg.text
			if entered_text.length() > 0:
				if entered_text.length() > 64:
					entered_text = entered_text.left(64)
				_print_message.rpc(
					entered_text
				)
			mp_layer.input_set_unfocus()
			mp_layer.enter_msg.text = ""
