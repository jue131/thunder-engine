extends Resource
class_name PlayerSuit

enum Type {
	SMALL,
	SUPER,
	POWERED
}

@export var name: StringName = &"small"
@export var type: Type = Type.SMALL
@export var gets_hurt_to: PlayerSuit
@export_group("Physics", "physics_")
@export var physics_config: PlayerConfig
@export var physics_behavior: GDScript
@export var physics_crouchable: bool = true
@export var physics_shaper: Shaper2D
@export var physics_shaper_crouch: Shaper2D
@export_group("Animation", "animation_")
@export var animation_sprites: SpriteFrames
@export var animation_behavior: GDScript
@export_group("Behavior", "behavior_")
@export var behavior_resource: Resource
@export var behavior_script: GDScript
@export var behavior_crouch_reflect_fireballs: bool = false
@export_group("Extra", "extra_")
@export var extra_vars: Dictionary
@export var extra_behavior: GDScript
@export_group("Sound", "sound_")
@export var sound_hurt: AudioStream
@export var sound_death: AudioStream
@export var sound_pitch: float = 1

