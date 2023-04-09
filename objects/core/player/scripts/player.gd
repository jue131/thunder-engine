extends CorrectedCharacterBody2D
class_name Player

## Class extended from [CorrectedCharacterBody2D] that defines a player[br]
## All players belong to this class

## Emitted when the [member default_player_state] gets changed
signal powerup_state_changed
## Emitted when the [member collision] gets changed
signal collision_shape_changed

## Used to define the configuration of the player. See [PlayerConfiguration]
@export var config: PlayerConfiguration = PlayerConfiguration.new()
## An extra [GDScript] extended from [ByNodeScript]
@export var custom_script: Script
## Used to define the suit state of the player. See [PlayerStateData]
@export var default_player_state: PlayerStateData = PlayerStateData.new()

## A state machine to control the state of the player. See [PlayerStatesManager]
var states: PlayerStatesManager = PlayerStatesManager.new(self)
## Instanced [member custom_script]
var extra_script: Script
## Instanced [member PlayerStateData.player_script]
var powerup_script: Script
## Local velocity of the player
var velocity_local: Vector2
## [code]True[/code] if the player is dead and doing movement of death
var death_movement: bool

## [AnimatedSprite2D] used for the player
@onready var sprite: Node2D = $Sprite
## [Sprite2D] used for the player if in debug mode
@onready var sprite_no_img: Node2D = $SpriteNoImg
## [CollisionShape2D] used for the player
@onready var collision: CollisionShape2D = $Collision
## [ShapeCast2D] used for the player to detect stomping
@onready var stomping_cast: ShapeCast2D = $StompingCast

## [Callable]s called according to the [member state]
var movements = {
	"default": _movement_default,
	"jump": _movement_default,
	"crouch": _movement_default,
	"stuck": _movement_stuck
}

## If [code]true[/code], the debug will display
var debug_expanded: bool


func _ready() -> void:
	super()
	
	if Engine.is_editor_hint(): return
	
	extra_script = ByNodeScript.activate_script(custom_script, self)
	
	Thunder._current_player = self
	
	if !Thunder._current_player_state:
		Thunder._current_player_state = default_player_state
	else:
		_on_power_state_change(Thunder._current_player_state)
	
	if Data.values.lives == -1:
		Data.values.lives = config.default_life_count
	
	if OS.is_debug_build():
		_debug_setup_label()
		

func _physics_process(delta: float) -> void:
	if OS.is_debug_build():
		var label: Label = $Label # Label
		if Input.is_action_just_pressed(&"a_player_label"):
			label.visible = !label.visible
			debug_expanded = Input.is_action_pressed(&"a_player_label_expanded")
		
		if label.visible:
			label.text = _debug_info() + (_debug_info_more() if debug_expanded else "")
			label.position.y = -label.size.y - 32
	
	if states.current_state == "dead":
		_movement_death(delta)
		states.update_states(delta)
		return
	
	_player_process(Thunder.get_delta(delta))
	


func _player_process(delta: float) -> void:
	if states.current_state != "warp":
		if movements.has(states.current_state):
			movements[states.current_state].call(delta)
		
		velocity = velocity_local.rotated(global_rotation)
		move_and_slide_corrected()
		velocity_local = velocity.rotated(-global_rotation)
		_stomping()
	
	states.update_states(delta)


func _movement_generic_fall(delta: float) -> void:
	# Fall
	velocity_local.y = move_toward(velocity_local.y, config.max_fall_speed, config.fall_speed * delta)
	
func _movement_generic(delta: float) -> void:
	# Decceleration
	if velocity_local.x > 0:
		velocity_local.x = max(velocity_local.x - config.deceleration_speed * delta, 0)
	if velocity_local.x < 0:
		velocity_local.x = min(velocity_local.x + config.deceleration_speed * delta, 0)
	
	# Controls
	if states.current_state != "crouch":
		states.left_or_right = int(_get_axis(config.control_left, config.control_right))
	else:
		states.left_or_right = 0
	var walk: int = states.left_or_right
	
	# Acceleration
	
	# Moving left and right
	if walk != 0 && states.current_state != "crouch":
		var speed_x: float = abs(velocity_local.x)
		var mark_x: float = velocity_local.x * sign(walk)
		if speed_x < config.initial_accel_trigger / 2:
			velocity_local.x = config.initial_accel_trigger * walk
		elif mark_x <= -config.initial_accel_trigger:
			velocity_local.x += config.initial_accel_trigger * delta * walk
		elif speed_x < config.max_walk_speed && !_is_action_pressed(config.control_run):
			velocity_local.x += config.acceleration_speed * delta * walk
		elif speed_x < config.max_run_speed && _is_action_pressed(config.control_run):
			velocity_local.x += config.acceleration_speed * delta * walk


func _movement_default(delta: float) -> void:
	# Hold jump
	if !is_on_floor() && _is_action_pressed(config.control_jump) && velocity_local.y < 0:
		states.set_state("jump")
		if abs(velocity_local.x) < 1:
			velocity_local.y -= config.jump_speed_stopped * delta
		else:
			velocity_local.y -= config.jump_speed_moving * delta
	
	# Applying initial acceleration
	if abs(velocity_local.x) < config.initial_accel_trigger && states.left_or_right != 0:
		velocity_local.x = config.initial_acceleration * states.left_or_right
	
	# Direction
	if velocity_local.x > config.initial_acceleration:
		states.dir = 1
	elif velocity_local.x < config.initial_acceleration:
		states.dir = -1
	
	if _is_action_pressed(config.control_down) && Thunder._current_player_state.player_power != Data.PLAYER_POWER.SMALL:
		states.set_state("crouch")
	
	if !_is_action_pressed(config.control_down) && states.current_state == "crouch":
		states.set_state("default")
	
	if _is_action_just_pressed(config.control_jump) && !is_on_floor() && velocity_local.y > 0:
		states.jump_buffer = true
	
	if _is_action_just_released(config.control_jump):
		states.jump_buffer = false
	
	if (_is_action_just_pressed(config.control_jump) || states.jump_buffer) && is_on_floor() && states.current_state != "crouch":
		velocity_local.y = -config.jump_velocity
		states.jump_buffer = false
		Audio.play_sound(config.jump_sound, self, true, {pitch = config.sound_pitch})
	
	# Generic fall velocity, acceleration and deceleration
	_movement_generic(delta)
	_movement_generic_fall(delta)


func _movement_stuck(delta: float) -> void:	
	var vertical_pos: Vector2 = Vector2(0, -config.collision_shape_big.size.y / 2).rotated(rotation)
	var horizontal_pos: Vector2 = Vector2(0, 0).rotated(rotation)

	horizontal_pos = Vector2(config.collision_shape_big.size.x, 0).rotated(rotation)

	var left_collide: bool = test_move(
		Transform2D(
			global_rotation, global_position - horizontal_pos + vertical_pos
		),
		velocity
	)
	var right_collide: bool = test_move(
		Transform2D(
			global_rotation, global_position + horizontal_pos + vertical_pos
		),
		velocity
	)
	
	if left_collide && right_collide:
		velocity_local.x = 50 if sprite.flip_h else -50

	if left_collide && !right_collide:
		velocity_local.x = 50

	if right_collide && !left_collide:
		velocity_local.x = -50
		
	if (!right_collide && !left_collide) || !test_move(global_transform, Vector2(0, -6).rotated(global_rotation)):
		velocity_local.x = 0
		if !update_collisions(Thunder._current_player_state, false):
			states.set_state("default")
	


func _movement_death(delta: float) -> void:
	if !death_movement: return
	
	velocity_local.y = move_toward(velocity_local.y, 500, 8)
	
	velocity = velocity_local.rotated(global_rotation)
	global_position += velocity * delta


func _stomping() -> void:
	if !stomping_cast.shape:
		stomping_cast.shape = config.collision_shape_big
	stomping_cast.target_position = velocity_local.normalized() * 4
	
	var count: int = stomping_cast.get_collision_count()
	var result: Dictionary
	
	if count <= 0: return
	
	for i in count:
		var casted: Area2D = stomping_cast.get_collider(i) as Area2D
		if !casted: continue
		
		var enemy_attacked: Node = casted.get_node_or_null(^"EnemyAttacked")
		if !enemy_attacked: continue
		
		result = enemy_attacked.got_stomped(self)
	
	if result.is_empty(): return
	
	if result.result == true:
		if _is_action_pressed(config.control_jump):
			velocity_local.y = -result.jumping_max * config.stomp_multiplicator
		else:
			velocity_local.y = -result.jumping_min * config.stomp_multiplicator
	else:
		powerdown()


func _on_power_state_change(data: PlayerStateData) -> void:
	config.sound_pitch = 1.0
	
	assert(data, "PlayerStateData is empty.")
	# If there's no valid animation in new player state, enable fallback sprite
	if !data.player_prefab:
		sprite.visible = false
		sprite_no_img.visible = true
		powerup_state_changed.emit(data)
		return
	
	# Assigning new player state animations
	sprite.sprite_frames = data.player_prefab
	sprite.visible = true
	sprite_no_img.visible = false
	
	sprite.play()
	
	# If Super Mario is crouching and gets hit, prevent Small Mario from crouching
	if states.current_state == "crouch" && data.player_power == Data.PLAYER_POWER.SMALL:
		states.set_state("default")
	
	# Update Small/Big/Crouching collision shapes
	if update_collisions(data, states.current_state == "crouch"):
		states.set_state("stuck")
	
	#stomping_cast.shape = collision.shape
	
	# Call _exit_tree() in old powerup script before right before changing the state
	if powerup_script && powerup_script.has_method("_exit_tree"):
		powerup_script._exit_tree()
	
	powerup_state_changed.emit(data)
	
	powerup_script = null
	if data.player_script:
		powerup_script = ByNodeScript.activate_script(data.player_script, self, data.player_state_vars)


## Update [member collision] according to the given [code]state[/code]
## If [code]crouching[/code] is [code]true[/code], the [memeber collision] will always be the one in small state
func update_collisions(state: PlayerStateData, crouching: bool) -> bool:
	var power = state.player_power

	if power == Data.PLAYER_POWER.SMALL:
		if collision.shape.get_instance_id() == config.collision_shape_small.get_instance_id():
			return false
		collision.shape = config.collision_shape_small
	else:
		if crouching:
			if collision.shape.get_instance_id() == config.collision_shape_crouch.get_instance_id():
				return false
			collision.shape = config.collision_shape_crouch
		else:
			if collision.shape.get_instance_id() == config.collision_shape_big.get_instance_id():
				return false
			if (
				states.current_state == "crouch" ||
				Thunder._current_player_state.player_power == Data.PLAYER_POWER.SMALL
			) && test_move(
				Transform2D(
					global_rotation,
					global_position + Vector2(0, -config.collision_shape_big.size.y / 2)
				),
				Vector2.ZERO
			):
				return true
			collision.shape = config.collision_shape_big

	collision.position.y = -collision.shape.size.y / 2 - 1
	collision_shape_changed.emit()
	return false


## If called, make the player get hurt
func powerdown() -> void:
	if states.invincible: return
	if states.invincible_timer > 0: return
	
	if Thunder._current_player_state.powerdown_state:
		states.appear_timer = config.powerdown_animation_time
		states.invincible_timer = config.powerdown_invincible_time
		Thunder._current_player_state = Thunder._current_player_state.powerdown_state
		Audio.play_sound(config.powerdown_sound, self)
	else:
		kill()


## If called, make the player get the powerup related to given [code]state[/code]
func powerup(state: PlayerStateData) -> void:
	states.appear_timer = config.powerup_animation_time
	if config.powerup_animation_time > states.invincible_timer:
		states.invincible_timer = config.powerup_animation_time
	Thunder._current_player_state = state


## If called, the player dies
func kill() -> void:
	if states.invincible: return
	if states.current_state == "dead": return
	
	Data.values.onetime_blocks = false
	
	states.set_state("dead")
	collision_layer = 0
	collision_mask = 0
	z_index = 30
	
	if is_instance_valid(Thunder._current_hud):
		Thunder._current_hud.timer.paused = true
	
	get_tree().create_timer(0.5, false).timeout.connect(
		func() -> void:
			death_movement = true
			velocity_local = Vector2(0, -500)
	)
	
	get_tree().create_timer(4.0, false).timeout.connect(
		func() -> void:
			if Data.values.lives == 0:
				if is_instance_valid(Thunder._current_hud):
					Thunder._current_hud.game_over()
					Audio.play_music(config.gameover_music, 1)
				return
			Thunder._current_player_state = default_player_state
			Scenes.reload_current_scene()
			Data.values.lives -= 1
	)
	
	Audio.play_music(config.die_music, 1, {pitch = config.sound_pitch})


## Modified [method Input.is_action_pressed]
func _is_action_pressed(action: StringName, exact_match: bool = false) -> bool:
	return states.controls_enabled && Input.is_action_pressed(action, exact_match)


## Modified [method Input.is_action_just_pressed]
func _is_action_just_pressed(action: StringName, exact_match: bool = false) -> bool:
	return states.controls_enabled && Input.is_action_just_pressed(action, exact_match)


## Modified [method Input.is_action_just_released]
func _is_action_just_released(action: StringName, exact_match: bool = false) -> bool:
	return states.controls_enabled && Input.is_action_just_released(action, exact_match)


## Modified [method Input.get_axis]
func _get_axis(negative_action: StringName, positive_action: StringName) -> float:
	return Input.get_axis(negative_action, positive_action) if states.controls_enabled else 0


func _debug_info() -> String:
	return (
"""x: %f
y: %f 
x vel: %f 
y vel: %f 
st: %s""" % [
		position.x, position.y,
		velocity_local.x, velocity_local.y,
		states.current_state
	])


func _debug_info_more() -> String:
	var str: String = (
""", pw: %s
i: %.2f,
a: %.2f, l: %.2f, fc: %.0f
""" % [
		Thunder._current_player_state.state_name,
		states.invincible_timer, states.appear_timer,
		states.launch_timer, states.projectiles_count
	])
	str += "fl " if is_on_floor() else char(32).repeat(5)
	str += "wa " if is_on_wall() else char(32).repeat(5)
	str += "ceiling\n" if is_on_ceiling() else "\n"
	return str


func _debug_setup_label() -> void:
	var label: Label = Label.new()
	label.visible = false
	label.uppercase = true
	label.label_settings = LabelSettings.new()
	label.label_settings.font = preload("res://engine/components/hud/hud_font.fnt")
	label.scale = Vector2(0.75, 0.75)
	label.position = Vector2(-80, 0)
	label.custom_minimum_size = Vector2(96, 0)
	label.z_as_relative = false
	label.z_index = 10
	add_child(label, true)
