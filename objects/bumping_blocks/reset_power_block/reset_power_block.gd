extends StaticBumpingBlock

@export_file("*.tscn", "*.scn") var change_to_suit: String = "res://engine/objects/players/prefabs/suits/mario/small_mario_suit.tscn"
@onready var new_suit: Resource = load(change_to_suit)

func _ready() -> void:
	if Engine.is_editor_hint(): return
	super()


func _physics_process(delta):
	super(delta)
	if active && Thunder._current_player.suit.type == PlayerSuitScene.Type.SMALL:
		active = false
		_animated_sprite_2d.animation = &"empty"
	elif !active && Thunder._current_player.suit.type > PlayerSuitScene.Type.SMALL:
		active = true
		_animated_sprite_2d.animation = &"default"


@rpc("any_peer", "call_local", "reliable")
func got_bumped(is_small: bool) -> void:
	if _triggered: return
	call_bump(is_small)


@rpc("any_peer", "call_local", "reliable")
func call_bump(is_small: bool) -> void:
	bump.rpc(false, 0, is_small)
	_animated_sprite_2d.animation = &"empty"
	if multiplayer.get_remote_sender_id() == multiplayer.get_unique_id():
		var suit_scene: PlayerSuitScene = new_suit.instantiate()
		Thunder._current_player.change_suit(suit_scene)
	Data.values.lives = ProjectSettings.get_setting(&"application/thunder_settings/player/default_lives", 4)
