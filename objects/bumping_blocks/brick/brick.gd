@icon("res://engine/objects/bumping_blocks/question_block/textures/icon.png")
extends StaticBumpingBlock

const NULL_TEXTURE = preload("res://engine/scripts/classes/bumping_block/texture_null.png")
@export var DEBRIS_EFFECT = preload("res://engine/objects/effects/brick_debris/brick_debris.tscn")

## For coin bricks. Set to 1 for one-time output
@export var result_counter_value: float = 300
var counter_enabled: bool = false

var broken: bool

func _physics_process(_delta):
	if !is_multiplayer_authority():
		return
	super(_delta)
	
	var delta = Thunder.get_delta(_delta)
	
	if counter_enabled:
		result_counter_value = max(result_counter_value - delta, 1)


func bricks_break() -> void:
	Audio.play_sound(break_sound, self)
	var speeds = [Vector2(2, -8), Vector2(4, -7), Vector2(-2, -8), Vector2(-4, -7)]
	for i in speeds:
		NodeCreator.prepare_2d(DEBRIS_EFFECT, self).create_2d(true).call_method(func(eff: Node2D):
			eff.global_transform = global_transform
			eff.velocity = i
		)
			
	Data.values.score += 10
	if is_multiplayer_authority():
		Multiplayer.host_free.rpc(get_path())


@rpc("any_peer", "call_local", "reliable")
func got_bumped(is_small: bool) -> void:
	if _triggered: return
	#if by is Player:
	#	if (by.is_on_floor() && !by.is_crouching) || by.warp != Player.Warp.NONE:
	#		return
			
	# Brick with some result
	if result && result.creation_nodepack:
		brick_bump_logic.rpc(is_small)
		return
	
	# Standard brick
	if is_small:
		bump.rpc(false, 0, true)
	elif !broken:
		if Multiplayer.is_host():
			hit_attack()
		bricks_break()
		broken = true
	

@rpc("any_peer", "call_local", "reliable")
func brick_bump_logic(is_small) -> void:
	if result_counter_value < 1: return
	bump.rpc(false, 0, is_small)
	if result && !counter_enabled:
		counter_enabled = true
	
	if result_counter_value == 1 || result_counter_value == 0:
		_animated_sprite_2d.animation = &"empty"
		counter_enabled = false
		result_counter_value = 0
