extends Area2D
class_name ActivationArea

signal screen_entered
signal screen_exited
signal screen_entered_player(player: Player)
signal screen_exited_player(player: Player)

@export var connect_default_signals_to_parent: bool = true
var players: Array

func _ready() -> void:
	collision_layer = 4096
	collision_mask = 0
	monitoring = false
	if connect_default_signals_to_parent:
		var par: Node = get_parent()
		Thunder._connect(screen_entered, Callable(par, &"_on_screen_entered"))
		Thunder._connect(screen_exited, Callable(par, &"_on_screen_exited"))
		Thunder._connect(screen_entered_player, Callable(par, &"_on_screen_entered_player"))
		Thunder._connect(screen_exited_player, Callable(par, &"_on_screen_exited_player"))


func is_on_screen() -> bool:
	return !players.is_empty()
