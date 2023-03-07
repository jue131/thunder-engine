# Base for blocks that can be bumped from below like bricks and question blocks
@icon("res://engine/scripts/classes/bumping_block/icon.png")
extends StaticBody2D
class_name StaticBumpingBlock

## Base class for blocks that can be bumped by players and enemies[br]
## Generally, bricks, question blocks, message blocks, etc. all belong to the class

const _HITTER: PackedScene = preload("res://modules/base/objects/bumping_blocks/_hitter/hit.tscn")

## The item you want to let the block spawn when the block gets bumped
@export var result: PowerupCreation:
	get:
		if Engine.is_editor_hint(): return result
		return result.prepare()
## If [code]true[/code], the result added will be a sibling node of the block
@export var result_as_sibling_node: bool = true
## If [code]false[/code], the block won't react to any kind of bumping
@export var active: bool = true
var _triggered: bool = false

@export_group("Sounds")
## The sound when the block spawns an item
@export var appear_sound: AudioStream = null
## The sound when the block gets bumped
@export var bump_sound: AudioStream = preload("res://modules/base/objects/bumping_blocks/_sounds/bump.wav")
## The sound when the block breaks (if possible)
@export var break_sound: AudioStream = preload("res://modules/base/objects/bumping_blocks/_sounds/break.wav")

@export_group("Bump Detection")
## Bottom detector of bumping
@export var cast_below: ShapeCast2D #if cast_below: cast_below.body_entered.connect()
## Top detector of bumping
@export var cast_above: ShapeCast2D
## Left-side detector of bumping
@export var cast_left: ShapeCast2D
## Right-side detector of bumping
@export var cast_right: ShapeCast2D

var _no_result_appearing_animation: bool = false

@onready var _collision_shape_2d: CollisionShape2D = $CollisionShape2D

## Emitted when getting bumped
signal bumped
## Emitted when the item gets spawned
signal result_appeared


func _ready() -> void:
	if !Engine.is_editor_hint():
		visible = true
		#Engine.time_scale = 0.5
		return

func _physics_process(delta) -> void:
	if Engine.is_editor_hint():
		_editor_process()
		return

func _editor_process() -> void:
	return


## Make the block bumped. If the block was just now got or is being bumped, then nothing will happen[br]
## If [code]disable[/code] is [code]true[/code], then all cast detectors will be disabled[br]
## [code]bump_rotation[/code] is the direction angle that the block moves when it is being bumped[br]
## [code]interrupy[/code] no usge currently
func bump(disable: bool, bump_rotation: float = 0, interrupt: bool = false):
	if _triggered: return
	if !active: return
	
	_triggered = true
	
	var init_position = position
	var tw = get_tree().create_tween()#.set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "position", init_position + Vector2(0, -6).rotated(deg_to_rad(bump_rotation)), 0.12)#.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", init_position, 0.12)#.set_ease(Tween.EASE_IN)
	tw.tween_callback(_lt.bind(disable))
	
	if result:
		call_deferred(&"_creation", result)
		result_appeared.emit()
	else:
		Audio.play_sound(bump_sound, self)
	
	if disable:
		if cast_below: cast_below.enabled = false
		if cast_above: cast_above.enabled = false
		if cast_left: cast_left.enabled = false
		if cast_right: cast_right.enabled = false
	
	bumped.emit()
	
	var hitter: float = -_collision_shape_2d.shape.size.y / 2  if _collision_shape_2d.shape is RectangleShape2D else -16
	NodeCreator.prepare_2d(_HITTER, self).create_2d().bind_global_transform(Vector2(0, hitter - 1))

func _lt(disable):
	if !disable:
		_triggered = false

func _creation(creation: InstanceNode2D) -> void:
	if !creation: return
	
	var created:Node2D = NodeCreator.prepare_ins_2d(creation, self).execute_instance_script({},&"_pre_ready").create_2d().execute_instance_script({},&"_after_ready").get_node()
	if created && created.has_method(&"_from_bumping_block"): created._from_bumping_block()
	
	creation.set_meta(&"no_appearing", _no_result_appearing_animation)
	
	Audio.play_sound(appear_sound, self)

## Returns [code]true[/code] if [code]body[/code] collides with [code]shape_cast[/code]
func is_body_colliding(body: CollisionObject2D, shape_cast: ShapeCast2D) -> bool:
	if !shape_cast: push_error("Shape Cast is not valid."); return false
	if !shape_cast.enabled: return false
	
	if shape_cast.is_colliding():
		for i in shape_cast.get_collision_count():
			var collider = shape_cast.get_collider(i)
			
			return is_instance_of(collider, body)
	return false

## Returns [code]true[/code] if [member Thunder._current_player] collides with [code]shape_cast[/code]
func is_player_colliding(shape_cast: ShapeCast2D) -> bool:
	if !shape_cast: push_error("Shape Cast is not valid."); return false
	if !shape_cast.enabled: return false
	
	if shape_cast.is_colliding():
		for i in shape_cast.get_collision_count():
			var collider = shape_cast.get_collider(i)
			
			return collider is Player
	return false
