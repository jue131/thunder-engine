extends Player

@export var synced_position: Vector2

@onready var inputs_sync: MultiplayerSynchronizer = $Inputs/InputsSync

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())



func _ready() -> void:
	if !suit_changed.is_connected(_suit_changed):
		suit_changed.connect(_suit_changed)
	#if !died.is_connected(Multiplayer.player_died.bind(self)):
	#	died.connect(Multiplayer.player_died.bind(self))
	
	_initiate_transition()
	
	if !Thunder._current_player_state:
		Thunder._current_player_state = suit
	else:
		suit = Thunder._current_player_state
	
	change_suit.rpc_id(multiplayer.get_unique_id(), suit, false, true)
	
	if Data.values.lives == -1 && death_check_for_lives:
		Data.values.lives = ProjectSettings.get_setting("application/thunder_settings/player/default_lives", 4)
	
	if str(multiplayer.get_unique_id()) == str(name):
		Thunder._current_player = self
		$Label.queue_free()
	
	if !is_starman():
		sprite.material.set_shader_parameter(&"mixing", false)
	
	if synced_position:
		global_position = synced_position
	if str(name).is_valid_int():
		inputs_sync.set_multiplayer_authority(str(name).to_int())
	

func _physics_process(delta: float) -> void:
	# Control
	if !completed && multiplayer.multiplayer_peer == null || str(multiplayer.get_unique_id()) == str(name):
		# The client which this player represent will update the controls state, and notify it to everyone.
		inputs.update(self)
		control_process()
		if !Thunder._current_player_state:
			Thunder._current_player_state = suit
	
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
	
	Multiplayer.player_died.rpc(str(name).to_int())
	Multiplayer.chat_message.emit("You died!")
	super(tags)
	

func _suit_changed(_suit: PlayerSuit) -> void:
	mp_change_suit.rpc_id(multiplayer.get_unique_id(), _suit) #rpc_id(multiplayer.get_unique_id(), _suit)

@rpc("any_peer", "call_local", "reliable")
func mp_change_suit(_suit: PlayerSuit) -> void:
	push_warning('bro changed suit')
	#if str(multiplayer.get_remote_sender_id()) == str(name): return
	if _suit == null: return
	change_suit(suit, false, false, false)
