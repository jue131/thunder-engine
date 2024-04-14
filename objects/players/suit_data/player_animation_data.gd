extends SuitData
class_name SuitAnimationData

const _default_animation_sprites: SpriteFrames = preload("res://engine/objects/players/prefabs/animations/mario/animation_mario_small.tres")
@export var sprites: SpriteFrames = _default_animation_sprites

#var sprite: AnimatedSprite2D
var config: PlayerConfig
var only_once: bool
var _climb_progress: float

func _ready_mixin(pl: Player) -> void:
	super(pl)
	config = pl.suit.physics_data.config
	
	# Connect animation signals for the current powerup
	Thunder._connect(player.suit_appeared, _suit_appeared)
	Thunder._connect(player.swam, _swam)
	Thunder._connect(player.shot, _shot)
	Thunder._connect(player.invinciblized, _invincible)
	
	Thunder._connect(sprite.animation_looped, _sprite_loop)
	Thunder._connect(sprite.animation_finished, _sprite_finish)


#func _exit_tree_mixin() -> void:
#	# Disconnect animation signals from the current powerup
#	Thunder._disconnect(player.suit_appeared, _suit_appeared)
#	Thunder._disconnect(player.swam, _swam)
#	Thunder._disconnect(player.shot, _shot)
#	Thunder._disconnect(player.invinciblized, _invincible)
#	
#	Thunder._disconnect(sprite.animation_looped, _sprite_loop)
#	Thunder._disconnect(sprite.animation_finished, _sprite_finish)


func _physics_process(delta: float) -> void:
	super(delta)
	#if player.get_tree().paused: return
	
	#delta = player.get_physics_process_delta_time()
	if !is_instance_valid(player): return
	_animation_process(delta)


#= Connected
func _suit_appeared() -> void:
	if !sprite: return
	sprite.play(&"appear")
	await get_tree().create_timer(1, false, true).timeout
	if sprite.animation == &"appear": sprite.play(&"default")


func _swam() -> void:
	if !sprite: return
	if sprite.animation == &"swim" && sprite.frame > 2: sprite.frame = 0


func _shot() -> void:
	if !sprite: return
	if sprite.animation == &"swim":
		sprite.frame = 3
		return
	sprite.play(&"attack")


func _invincible(duration: float) -> void:
	if !sprite: return
	sprite.modulate.a = 1
	if !player.is_starman():
		Effect.flash(sprite, duration)


func _sprite_loop() -> void:
	if !sprite: return
	match sprite.animation:
		&"swim": sprite.frame = sprite.sprite_frames.get_frame_count(sprite.animation) - 2


func _sprite_finish() -> void:
	if !sprite: return
	if sprite.animation == &"attack": sprite.play(&"default")


#= Main
func _animation_process(delta: float) -> void:
	if !sprite: return
	
	if player.direction != 0 && !player.is_climbing:
		sprite.flip_h = (player.direction < 0)
	sprite.speed_scale = 1
	# Non-warping
	if player.warp == Player.Warp.NONE:
		if sprite.animation in [&"appear", &"attack"]: return
		# Climbing
		if player.is_climbing:
			sprite.play(&"climb")
			if player.speed != Vector2.ZERO:
				_climb_progress += abs(player.speed.length() * delta)
				if _climb_progress > 20:
					_climb_progress = 0
					sprite.flip_h = !sprite.flip_h
			return
		if player.is_sliding:
			sprite.play(&"slide")
			sprite.speed_scale = clampf(abs(player.speed.x) * 0.01 * 1.5, 1, 5)
			return
		# Non-climbing
		if player.is_on_floor():
			if player.speed.x != 0:
				sprite.play(&"walk")
				sprite.speed_scale = (
					clampf(abs(player.speed.x) * 0.008 * config.animation_walking_speed,
					config.animation_min_walking_speed,
					config.animation_max_walking_speed)
				)
			else:
				sprite.play(&"default")
			if player.is_crouching:
				sprite.play(&"crouch")
		elif player.is_underwater:
			sprite.play(&"swim")
		else:
			sprite.play(&"jump")
	# Warping
	else:
		match player.warp_dir:
			Player.WarpDir.UP, Player.WarpDir.DOWN:
				sprite.play(&"warp")
			Player.WarpDir.LEFT, Player.WarpDir.RIGHT:
				player.direction = -1 if player.warp_dir == Player.WarpDir.LEFT else 1
				sprite.play(&"walk")
				sprite.speed_scale = 2
