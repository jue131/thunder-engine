extends Node
class_name PlayerSuitScene

enum Type {
	SMALL,
	SUPER,
	POWERED
}

#@export var player_suit: PlayerSuit = preload("res://engine/objects/players/prefabs/suits/mario/suit_mario_small.tres")
@onready var suit = $".."
@onready var player = suit.player

@onready var physics_data: SuitData = $PhysicsData
@onready var animation_data: SuitData = $AnimationData
@onready var behavior_script: SuitData = $BehaviorData
@onready var extra_data: SuitData = $ExtraData


var _appear: bool

# References from player_suit
@export var suit_name: StringName
@export var type: Type = Type.SMALL
@export var gets_hurt_to: PackedScene
#@export_file("*.tscn", "*.scn") var gets_hurt_to: String
@export_group("Sound", "sound_")
@export var sound_hurt: AudioStream = preload("res://engine/objects/players/prefabs/sounds/pipe.wav")
@export var sound_death: AudioStream = preload("res://engine/objects/players/prefabs/sounds/music-die.ogg")
@export var sound_pitch: float = 1

func _ready() -> void:
	if !player:
		print("No player")
		return
	Thunder._connect(player.suit_changed, _suit_changed)
	Thunder._connect(player.died, _died)
	#suit.physics_data = physics_data
	#suit.animation_data = animation_data
	#suit.behavior_script = behavior_script
	#suit.extra_data = extra_data


func _suit_changed(to: PlayerSuitScene):
	suit_name = to.suit_name
	print(to.name)
	suit.physics_data = to.physics_data
	suit.animation_data = to.animation_data
	suit.behavior_script = to.behavior_script
	suit.extra_data = to.extra_data
	
	if !player:
		print("No player on suit change")
		return
	if !is_inside_tree():
		return
	for i in get_children():
		if i is SuitData:
			i._ready_mixin(player)
	
	(func():
		if _appear:
			player.suit_appeared.emit()
			_appear = false
	).call_deferred()


func _died() -> void:
	set_physics_process(false)
