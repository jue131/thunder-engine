extends GravityBody2D
class_name GeneralMovementBody2D

@export_category("GeneralMovement")
@export var look_at_player: bool
## -1 is Left, 1 is Right.
@export_enum("Disabled: 0", "Left: -1", "Right: 1") var force_direction: int = 0
@export var turn_sprite: bool = true
@export var slide: bool
@export_category("References")
@export var sprite: NodePath
@export_category("OnScreenDetection")
## Set to [code]false[/code] for compatibility. Leave [code]true[/code] to improve performance.
@export var can_toggle_visibility: bool = true

var dir: int
var is_activated: bool = false

@onready var sprite_node: Node2D = get_node_or_null(sprite)


func _ready() -> void:
	if Engine.is_editor_hint(): return
	super()
	
	# Fix misdetection of being on wall when sloping down
	floor_max_angle += PI/180
	
	if force_direction:
		dir = force_direction
		speed_to_dir()
		return
	
	if look_at_player && Thunder._current_player:
		update_dir.call_deferred()
		speed_to_dir.call_deferred()


func _physics_process(delta: float) -> void:
	if !is_activated:
		return
	if Multiplayer.is_host():
		motion_process(delta, slide)
		if !Thunder.view.screen_dir(global_position, get_global_gravity_dir(), 800):
			print("Erasing out of screen: " + name)
			Multiplayer.host_free(get_path())
		
	if turn_sprite && sprite_node && is_instance_valid(sprite_node):
		sprite_node.flip_h = speed.x < 0


func _on_screen_entered() -> void:
	if is_activated: return
	if !Multiplayer.is_host():
		
		return
	
	set_rpc_activated.rpc(true)
	if look_at_player && !force_direction:
		update_dir.call_deferred()
		speed_to_dir.call_deferred()


func update_dir() -> void:
	var player: Player = Thunder.get_closest_player(global_position)
	if !player: return
	dir = Thunder.Math.look_at(global_position, player.global_position, global_transform)

func speed_to_dir() -> void:
	speed.x = abs(speed.x) * dir

func set_activated(activate: bool = true) -> void:
	is_activated = activate

@rpc("authority", "call_local", "reliable")
func set_rpc_activated(activate: bool = true) -> void:
	is_activated = activate
	if can_toggle_visibility: visible = activate

func queue_free_server() -> void:
	if Multiplayer.is_host():
		Multiplayer.host_free.rpc(get_path())
