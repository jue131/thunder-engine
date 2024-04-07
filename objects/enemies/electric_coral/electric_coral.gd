extends AnimatableBody2D

@onready var area_2d: Area2D = $Area2D


func _ready() -> void:
	area_2d.body_entered.connect(func(body: Node2D) -> void:
		if body is Player:
			body.hurt()
	)
