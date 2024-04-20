extends Node

@export var motion: Vector2i
@export var jumping: int
@export var jumped: bool
@export var running: bool
@export var attacked: bool
@export var attacking: bool
@export var is_crouching: bool
@export var slided: bool
var _attacked: bool

func update(player: Player) -> void:
	var control = player.control
	
	var left_right = int(Input.get_axis(control.left, control.right))
	var up_down = int(Input.get_axis(control.up, control.down))
	jumping = int(Input.is_action_pressed(control.jump)) \
		+ int(Input.is_action_just_pressed(control.jump))
	jumped = Input.is_action_just_pressed(control.jump)
	running = Input.is_action_pressed(control.run)
	_attacked = Input.is_action_just_pressed(control.attack)
	attacking = Input.is_action_pressed(control.attack)
	
	is_crouching = Input.is_action_pressed(control.down) \
		&& player.is_on_floor() && player.player_suit && player.player_suit.physics_data.crouchable && !player.is_sliding
	slided = Input.is_action_pressed(control.down) \
		&& player.is_on_floor() && abs(rad_to_deg(player.get_floor_normal().x)) > 39
	
	motion = Vector2i(left_right, up_down)
	
	if _attacked: Multiplayer.call_to_server.rpc_id(get_multiplayer_authority(), get_path(), "_on_attacked", null)

@rpc("authority", "call_local", "reliable")
func _on_attacked(_a: Variant = null) -> void:
	#print("ON ATTACKED!")
	attacked = true
	await get_tree().physics_frame
	set_deferred(&"attacked", false)

