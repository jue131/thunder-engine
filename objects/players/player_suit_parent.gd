extends Node

#const default_script: GDScript = preload("res://engine/objects/players/suit_data/player_suit_data.gd")
#@export var player_suit: PlayerSuit = preload("res://engine/objects/players/prefabs/suits/mario/suit_mario_small.tres")
@onready var player: Player = $".."

var physics_data: SuitPhysicsData
var animation_data: SuitAnimationData
var behavior_script: SuitBehaviorData
var extra_data: SuitExtraData

var _appear: bool

# References from player_suit
var suit_name: StringName

func _ready() -> void:
	Thunder._connect(player.suit_changed, _suit_changed)


func _suit_changed(to: PlayerSuitScene):
	suit_name = to.suit_name
	print(to.suit_name)
	
	#physics_data = to.physics_data
	#animation_data = to.animation_data
	#behavior_script = to.behavior_script
	#extra_data = to.extra_data
	
	(func():
		if _appear:
			player.suit_appeared.emit()
			_appear = false
	).call_deferred()
	
