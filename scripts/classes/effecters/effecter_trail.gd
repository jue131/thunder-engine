extends RefCounted
class_name Trail

const TRAIL: PackedScene = preload("res://engine/objects/effects/trail/trail.tscn")


static func trail(on: Node2D, texture: Texture2D = null, offset: Vector2 = Vector2.ZERO, flip_h: bool = false, flip_v: bool = false, centered: bool = true, fade_out_strength: float = 0.05) -> Sprite2D:
	if !on:
		return null
	
	return NodeCreator.prepare_2d(TRAIL, on).bind_global_transform().call_method(
		func(tra: Sprite2D) -> void:
			tra.offset = offset
			tra.texture = texture
			tra.flip_h = flip_h
			tra.flip_v = flip_v
			tra.centered = centered
			tra.fade_out_strength = fade_out_strength
			tra.z_index = on.z_index - 1
	).create_2d().get_node() as Sprite2D
