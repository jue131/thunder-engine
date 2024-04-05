extends VisibleOnScreenNotifier2D

@export var new_rect: Rect2 = Rect2(Vector2(-128, -128), Vector2(256, 256))
@onready var parent: Node2D = $".."

func _ready() -> void:
	screen_entered.connect(
		func() -> void:
			if !is_inside_tree() || !multiplayer.has_multiplayer_peer() || !is_multiplayer_authority():
				return
			rect = new_rect
			if "is_activated" in parent:
				parent.is_activated = true
	)
