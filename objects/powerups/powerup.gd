extends GravityBody2D
class_name Powerup

@export_group("Powerup Settings")
@export var slide: bool = true
@export var to_suit: Dictionary = {
	Mario = preload("res://engine/objects/players/prefabs/suits/mario/small_mario_suit.tscn")
}
@export var force_powerup_state: bool = false
@export var appear_distance: float = 32
@export var appear_speed: float = 0.5
@export var appear_visible: float = 28
@export var score: int = 1000


@export_group("Supply Behavior")
@export var supply_behavior: bool = false
@export var supply_modify_lives: int = 0


@export_group("SFX")
@export_subgroup("Sounds")
@export var appearing_sound: AudioStream = preload("res://engine/objects/bumping_blocks/_sounds/appear.wav")
@export var pickup_powerup_sound: AudioStream = preload("res://engine/objects/players/prefabs/sounds/powerup.wav")
@export var pickup_neutral_sound: AudioStream = preload("res://engine/objects/players/prefabs/sounds/powerup.wav")
@export_subgroup("Sound Settings")
@export var sound_pitch: float = 1.0

@onready var body: Area2D = $Body

var one_overlap: bool = false


func _from_bumping_block() -> void:
	Audio.play_sound(appearing_sound, self)

func _physics_process(delta: float) -> void:
	if !supply_behavior && multiplayer.is_server():
		if !appear_distance:
			motion_process(delta, slide)
			modulate.a = 1
			z_index = 0
		else:
			appear_process(Thunder.get_delta(delta))
			z_index = -1
	
	if !visible: return
	#for player in get_tree().get_nodes_in_group(&"Player"):
	#	if !is_instance_valid(player): continue
	var player = Thunder._current_player
	if !player: return
	var overlaps: bool = body.overlaps_body(player)
	if overlaps && !one_overlap:
		collect.rpc()
	if !overlaps && one_overlap:
		one_overlap = false


func appear_process(delta: float) -> void:
	appear_distance = max(appear_distance - appear_speed * delta, 0)
	modulate.a = 0.01 if (appear_distance > appear_visible) else 1.0
	position -= Vector2(0, appear_speed).rotated(global_rotation) * delta


@rpc("any_peer", "call_local", "reliable")
func collect() -> void:
	var player = Multiplayer.game.get_player(multiplayer.get_remote_sender_id())
	if !player: return
	if player.is_multiplayer_authority():
		_change_state_logic(force_powerup_state, player)
	
	if supply_behavior:
		if multiplayer.get_remote_sender_id() == str(player.name).to_int():
			Data.values.lives = ProjectSettings.get("application/thunder_settings/player/default_lives") + supply_modify_lives
		one_overlap = true
		return
	
	if score > 0:
		ScoreText.new(str(score), self)
		Data.values.score += score
	
	#set_physics_process(false)
	visible = false
	if Multiplayer.is_host():
		Multiplayer.host_free.rpc(get_path())


func _change_state_logic(force_powerup: bool, player: Player) -> void:
	var to: PackedScene = to_suit[player.character]
	var to_state: SceneState = to.get_state()
	var to_suit_name
	var to_type
	var to_gets_hurt_to
	for i in to_state.get_node_count():
		for j in to_state.get_node_property_count(i):
			var node_property_name = to_state.get_node_property_name(i, j)
			if node_property_name == "suit_name":
				to_suit_name = to_state.get_node_property_value(i, j)
			elif node_property_name == "type":
				to_type = to_state.get_node_property_value(i, j)
			elif node_property_name == "gets_hurt_to":
				to_gets_hurt_to = to_state.get_node_property_value(i, j)
				
	if force_powerup:
		if to_suit_name != player.suit.suit_name:
			player.change_suit(to.instantiate())
			Audio.play_sound(pickup_powerup_sound, self, false, {pitch = sound_pitch})
		else:
			Audio.play_sound(pickup_neutral_sound, self, false, {pitch = sound_pitch})
		return
	
	var current_suit: PlayerSuitScene = player.player_suit
	if !current_suit: return
	if (
		to_type > current_suit.type || (
			to_suit_name != player.suit.suit_name && 
			to_type == current_suit.type
		)
	):
		if current_suit.type < to_type - 1:
			player.change_suit(to_gets_hurt_to.instantiate())
			
		else:
			player.change_suit(to.instantiate())
		Audio.play_sound(pickup_powerup_sound, self, false, {pitch = sound_pitch})
	else:
		Audio.play_sound(pickup_neutral_sound, self, false, {pitch = sound_pitch})
