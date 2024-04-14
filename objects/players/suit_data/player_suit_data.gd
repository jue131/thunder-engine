extends Node
class_name SuitData

var player: Player
var suit: PlayerSuitScene
var sprite: AnimatedSprite2D


func _ready_mixin(pl: Player) -> void:
	player = pl
	suit = player.player_suit
	sprite = player.sprite as AnimatedSprite2D


func _exit_tree_mixin() -> void:
	pass


func _physics_process(delta: float) -> void:
	pass
	#suit = player.player_suit
	#config = suit.physics_config

