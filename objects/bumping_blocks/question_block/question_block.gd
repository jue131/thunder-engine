@icon("res://engine/objects/bumping_blocks/question_block/textures/icon.png")
@tool
extends StaticBumpingBlock

const NULL_TEXTURE = preload("res://engine/scripts/classes/bumping_block/texture_null.png")

var current_displaying_item: String = ""

@onready var item_displayer = $Sprites/ItemDisplayer


func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	item_displayer.queue_free()
	super()


func _physics_process(delta):
	super(delta)
	if Engine.is_editor_hint():
		_item_display()
		return


@rpc("any_peer", "call_local", "reliable")
func got_bumped(is_small: bool) -> void:
	if _triggered: return
	call_bump.rpc_id(multiplayer.get_remote_sender_id(), is_small)


@rpc("any_peer", "call_local", "reliable")
func call_bump(is_small: bool) -> void:
	bump.rpc_id(multiplayer.get_remote_sender_id(), true, 0, is_small)
	_animated_sprite_2d.animation = &"empty"


func _item_display() -> void:
	if !result || !result.creation_nodepack: return _item_display_reset()
	if result.creation_nodepack.resource_path == current_displaying_item: return
	
	var creation_scene = result.creation_nodepack.instantiate()
	var sprite = creation_scene.get_node_or_null("Sprite")
	if !sprite: sprite = creation_scene.get_node_or_null("Sprite2D")
	if !sprite: sprite = creation_scene.get_node_or_null("AnimatedSprite")
	if !sprite: sprite = creation_scene.get_node_or_null("AnimatedSprite2D")
	
	if !sprite:
		push_error("[QuestionBlock] Failed to retrieve the preview of result")
		item_displayer.scale = Vector2.ONE
	else:
		if is_instance_of(sprite, Sprite2D):
			item_displayer.texture = sprite.texture
		elif is_instance_of(sprite, AnimatedSprite2D):
			item_displayer.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
		item_displayer.scale = Vector2.ONE / 2
	
	current_displaying_item = result.creation_nodepack.resource_path

func _item_display_reset() -> void:
	if current_displaying_item == "": return
	
	item_displayer.texture = NULL_TEXTURE
	current_displaying_item = ""

