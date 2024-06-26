extends Projectile

const explosion_effect = preload("res://engine/objects/effects/explosion/explosion.tscn")

@onready var vision: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var activation: ActivationArea = $Activation
@export var jumping_speed: float = -250.0


func _ready() -> void:
	add_to_group(&"end_level_sequence")
	await get_tree().physics_frame
	if (
		belongs_to == Data.PROJECTILE_BELONGS.ENEMY &&
		!activation.is_on_screen()
	):
		queue_free()


func _physics_process(delta: float) -> void:
	super(delta)
	if !sprite_node: return
	sprite_node.rotation_degrees += 12 * (-1 if speed.x < 0 else 1) * Thunder.get_delta(delta)
	if speed.x == 0: explode()


func jump(jspeed:float = jumping_speed) -> void:
	super(jspeed)


func explode():
	NodeCreator.prepare_2d(explosion_effect, self).create_2d().bind_global_transform()
	queue_free()


func expand_vision(_scale: Vector2) -> void:
	await ready
	if vision: vision.scale = _scale
	is_activated = true


func _on_level_end() -> void:
	if !Thunder.view.is_getting_closer(self, 32):
		if Thunder.view.is_getting_closer(self, 320):
			queue_free()
		return
	Data.values.score += 100
	ScoreText.new(str(100), self)
	queue_free()
