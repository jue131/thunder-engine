extends Player

@export var synced_position: Vector2

@onready var inputs_sync: MultiplayerSynchronizer = $Inputs/InputsSync

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())


func _ready() -> void:
	_initiate_transition()
	
	if str(multiplayer.get_unique_id()) == str(name):
		Thunder._current_player = self
		$Label.queue_free()
		
		if !Thunder._current_player_state:
			player_suit = load(_suit).instantiate()
			Thunder._current_player_state = player_suit
	
		#change_suit.rpc_id(multiplayer.get_unique_id(), Thunder._current_player_state)
	
		if Data.values.lives == -1 && death_check_for_lives:
			Data.values.lives = ProjectSettings.get_setting("application/thunder_settings/player/default_lives", 4)
	
		change_suit(Thunder._current_player_state, false, true, true)
	else:
		(func():
			var p_data = Multiplayer.game.get_player_data(str(name).to_int())
			var data_suit
			if p_data && p_data.get_suit():
				data_suit = p_data.get_suit()
			else:
				data_suit = _suit
			
			player_suit = load(data_suit).instantiate()
			change_suit(player_suit, false, true, true)
		).call_deferred()
	
	if synced_position:
		global_position = synced_position
	if str(name).is_valid_int():
		inputs_sync.set_multiplayer_authority(str(name).to_int())
	
	if !is_starman():
		sprite.material.set_shader_parameter(&"mixing", false)
	

func _physics_process(delta: float) -> void:
	# Control
	if !completed && (multiplayer.multiplayer_peer == null || str(multiplayer.get_unique_id()) == str(name)):
		# The client which this player represent will update the controls state, and notify it to everyone.
		inputs.update(self)
		if !Thunder._current_player_state:
			Thunder._current_player_state = player_suit
	if !completed:
		control_process()
	
	if multiplayer.multiplayer_peer == null || is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		synced_position = position
	else:
		# The client simply updates the position to the last known one.
		position = synced_position
	
	if is_starman && (
		timer_starman.time_left > 0.0 &&
		timer_starman.time_left < 1.5 &&
		!_starman_faded
	):
		_starman_faded = true
		Audio.stop_music_channel(98, true)


func set_player_name(value: String) -> void:
	$Label.text = value
	nickname = value


func die(tags: Dictionary = {}) -> void:
	if !is_multiplayer_authority():
		return
	
	Multiplayer.game.player_died.rpc(str(name).to_int())
	Multiplayer.game.chat_message.emit("You died!")
	super(tags)


@rpc("any_peer", "call_local", "reliable")
func change_suit(to: Variant, appear: bool = true, forced: bool = false, send_signal: bool = true, extra_flags: Dictionary = {}) -> void:
	if !("rpc" in extra_flags && extra_flags.rpc == true):
		#Multiplayer.game.player_changed_suit.rpc_id(multiplayer.get_unique_id(), to.resource_path, appear, forced, send_signal)
		if to is PlayerSuitScene:
			var suit_path: String = to.scene_file_path
			Multiplayer.game.set_player_data.rpc("suit", suit_path)
			change_suit.rpc(suit_path, appear, forced, send_signal, {"rpc": true})
		return
	print(multiplayer.is_server(), ", suit changed for " + str(multiplayer.get_unique_id()) + "!")
	
	if !to || !to is String: return
	var new_suit = load(to).instantiate()
	super(new_suit, appear, forced, send_signal)
