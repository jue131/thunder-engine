extends AnimatableBody2D

@export_category("Spikeball Launcher")
@export var interval: float = 3
@export var spikeball: InstanceNode2D
@export var explosion: PackedScene = preload("res://engine/objects/effects/explosion/explosion.tscn")
@export var spikeball_velocity_min: Vector2 = Vector2(-300, -500)
@export var spikeball_velocity_max: Vector2 = Vector2(300, -400)
@export var sound: AudioStream = preload("res://engine/objects/enemies/spikeball_launcher/spikeball.ogg")

@onready var timer_interval: Timer = $Interval



func _on_visible_on_screen_enabler_2d_screen_entered() -> void:
	timer_interval.start(interval)


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	timer_interval.stop()


func _on_shooting() -> void:
	Audio.play_sound(sound, self)
	
	if spikeball: 
		NodeCreator.prepare_ins_2d(spikeball, self).call_method(
			func(spk: Node2D) -> void:
				if spk is Projectile:
					spk.rotation = 0
					spk.vel_set(Vector2(randf_range(spikeball_velocity_min.x, spikeball_velocity_max.x), randf_range(spikeball_velocity_min.y, spikeball_velocity_max.y)).rotated(global_rotation))
					spk.belongs_to = Data.PROJECTILE_BELONGS.ENEMY
		).create_2d()
	
	if !explosion: return
	NodeCreator.prepare_2d(explosion, self).bind_global_transform(Vector2.UP * 24).create_2d()
