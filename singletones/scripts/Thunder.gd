# This class provides helper and utility functions

extends Node

## Main singleton of Thunder Engine[br]
## Most information is stored in the signleton, like current player and its state,
## default gravity speed and some other functions you can use for your game

## Discarded, please see [signal "engine/singletones/scripts/Scenes.gd".scene_changed]
signal stage_changed

## Used to get access to [Thunder.View] subsingleton
var view: View = View.new() # View subsingleton
## Default gravity speed
var gravity_speed: float = 50
var _target_speed: int = 50

# TO GET CURRENT CAMERA, USE Viewport.get_camera_2d()

## Current player you are playing
var _current_player: Player: # Reference to the current player
	set(node):
		assert(is_instance_valid(node) && (node is Player), "Player node is invalid")
		_current_player = node
	get:
		if !is_instance_valid(_current_player): return null
		return _current_player

var _current_player_state: PlayerSuitScene: # Current state of the player
	set(node):
		assert((is_instance_valid(node) && (node is PlayerSuitScene) || node == null), "Player suit node is invalid")
		_current_player_state = node
	get:
		if !is_instance_valid(_current_player_state): return null
		return _current_player_state

var _current_hud: CanvasLayer: # Reference to level HUD
	set(node):
		assert(is_instance_valid(node) && (node is CanvasLayer), "HUD node is invalid")
		_current_hud = node
	get:
		assert(is_instance_valid(_current_hud) && (_current_hud is CanvasLayer), "HUD node is invalid or not set")
		return _current_hud

@warning_ignore("unused_private_class_variable")
var _current_camera: Camera2D

var _current_screen_area: Area2D:
	get:
		if !is_instance_valid(_current_screen_area): return null
		return _current_screen_area


## Gets an [param key] from [param obj], and this won't send any errors if there is no such key in the object
func get_or_null(obj: Variant, key: String) -> Variant:
	if !is_instance_valid(obj) || !obj.get(key): return null
	return obj[key]


## Finds a child of [param ref] by [param classname] of its class and return it or null
func get_child_by_class_name(ref: Node, classname: String) -> Node:
	for child in ref.get_children():
		if child.is_class(classname): return child
	return null


func get_node_or_not(path: NodePath) -> Node:
	if has_node(path):
		return get_node(path)
	return null


## Connects a signal to a callable without throwing errors if it's already connected
@warning_ignore("int_as_enum_without_match", "int_as_enum_without_cast")
func _connect(sig: Signal, callable: Callable, flags: ConnectFlags = 0) -> bool:
	if callable.is_null() || !callable.is_valid(): return true
	if sig.is_connected(callable): return true
	sig.connect(callable, flags)
	return false


## Disconnects a signal from a callable without throwing errors if it's already disconnected
func _disconnect(sig: Signal, callable: Callable) -> bool:
	if callable.is_null() || !callable.is_valid(): return true
	if !sig.is_connected(callable): return true
	sig.disconnect(callable)
	return false


## Gets relative FPS by inputting delta in [method Node._process] or [method Node._physics_process]
func get_delta(delta: float) -> float:
	return _target_speed * delta


func _init() -> void:
	var rate: int = ceili(DisplayServer.screen_get_refresh_rate())
	if rate < 119:
		Engine.physics_ticks_per_second = rate * 2
		print(&"Using double fps for physics")
	else:
		Engine.physics_ticks_per_second = rate
	
	Engine.max_fps = ceili(DisplayServer.screen_get_refresh_rate())
	
	# Setting minimum window dimensions
	DisplayServer.window_set_min_size(Vector2i(640, 480))
	
	# Set default background in-game from solid gray to solid black
	RenderingServer.set_default_clear_color(Color.BLACK)


## Discarded, see [method "engine/singletones/scripts/Scenes.gd".switch_to_scene]
func goto_scene(path) -> void:
	call_deferred(&"_deferred_goto_scene", path)


func _deferred_goto_scene(path) -> void:
	Scenes.current_scene.free()
	
	var s = load(path)
	Scenes.current_scene = s.instantiate()
	stage_changed.emit()
	
	if !Scenes.current_scene.is_inside_tree():
		get_tree().root.add_child(Scenes.current_scene)


## Add lives for [member _current_player][br]
## [color=orange][b]Note:[/b][/color] The [code]count[/code] you input must be between 1 and 10, or an error will be sent to console. 
## So if you want to cut down the lives, please code:[br]
## [code]Data.values.lives -= some_count[/code]
func add_lives(count: int):
	if count <= 0 or count > 10:
		push_error("[Thunder Engine] add_lives: Invalid life count. Must be between 1 and 10")
		return
	
	Data.values.lives += count
	if _current_player:
		ScoreTextLife.new("%sUP" % count, _current_player)


## Add scores for [member _current_player][br]
## [color=orange][b]Note:[/b][/color] The [code]count[/code] you input must be greater than 0, or an error will be sent to console.
## So if you want to cut down the scores, please code:[br]
## [code]Data.values.score -= some_count[/code]
func add_score(count: int):
	if count <= 0:
		push_error("[Thunder Engine] add_score: Invalid score count. Must be greater than 0")
		return
	
	Data.values.score += count
	ScoreText.new(str(count), _current_player)


## Pauses game
func set_pause_game(pause: bool) -> void:
	get_tree().paused = pause


func get_closest_player(to: Vector2) -> Player:
	return get_closest_node_in_group(to, &"Player", "is_dying")

func get_closest_node_in_group(to: Vector2, group: StringName, exception_prop: String = "") -> Node:
	var node_array: Array[Node] = get_tree().get_nodes_in_group(group)
	if node_array.is_empty(): return null
	
	var closest_node = null
	var closest_node_distance: float = 0.0
	for node: Node in node_array:
		if exception_prop && node.get(exception_prop) && node[exception_prop] == true:
			continue
		var this_node_distance = to.distance_to(node.global_position)
		if closest_node == null || this_node_distance < closest_node_distance: 
			closest_node = node
			closest_node_distance = this_node_distance
		
	return closest_node


## Subsingleton of ["engine/singletones/scripts/Thunder.gd"] to majorly manage functions related to screen borders and the detection of them
class View:
	## Current screen border, used [Rect2i] because the size and position of screen border don't support [float]
	var border: Rect2i
	## Current transformation of viewport
	var trans: Transform2D
	
	
	## Update [member border] and [member trans] for detectional functions, you need to call this method
	## in [method Node._process] or [method Node._physics_process] to get better use of it
	func cam_border() -> void:
		var cam: Camera2D = Thunder._current_camera
		if !cam:
			printerr("[Thunder Engine] Failed to retrieve current camera, is the current viewport correct?")
			return
		trans = cam.get_viewport_transform()
		border.size = Vector2i(cam.get_viewport_rect().size)
		border.position = Vector2i(cam.get_screen_center_position() - border.size/2.0)
	
	
	## Returns [code]true[/code] if given [code]pos[/code] is NOT out of left edge of screen
	func screen_left(pos: Vector2, offset: float) -> bool:
		return (trans * pos).x > -offset
	
	
	## Returns [code]true[/code] if given [code]pos[/code] is NOT out of right edge of screen
	func screen_right(pos: Vector2, offset: float) -> bool:
		return (trans * pos).x < border.size.x + offset
	
	
	## Returns [code]true[/code] if given [code]pos[/code] is NOT out of top edge of screen
	func screen_top(pos: Vector2, offset: float) -> bool:
		return (trans * pos).y > -offset
	
	
	## Returns [code]true[/code] if given [code]pos[/code] is NOT out of bottom edge of screen
	func screen_bottom(pos: Vector2, offset: float) -> bool:
		return (trans * pos).y < border.size.y + offset
	
	
	## Returns [code]true[/code] if given [code]pos[/code] is out of the edge of screen, which is decided by
	## [code]dir[/code] given
	func screen_dir(pos: Vector2, dir: Vector2, offset: float) -> bool:
		var ang: float = dir.angle()
		if ang > 3*PI/4 || ang < -3*PI/4:
			return screen_left(pos, offset)
		elif ang >= -3*PI/4 && ang <= -PI/4:
			return screen_top(pos, offset)
		elif ang > -PI/4 && ang < PI/4:
			return screen_right(pos, offset)
		else:
			return screen_bottom(pos, offset)
	
	
	## crutch
	func is_getting_closer(canvas_item: CanvasItem, margin: float) -> bool:
		var pos := canvas_item.get_global_transform_with_canvas().get_origin()
		var rect := canvas_item.get_viewport_rect()
		
		return rect.grow(margin).has_point(pos)
	
	
	## Used for scripts with @tool to limit its process functions running out of screen
	static func shows_tool(tool: Node2D) -> bool:
		var viewport := tool.get_viewport_transform()
		var size := tool.get_viewport_rect().size
		var vscale := viewport.get_scale()
		var pos := -viewport.get_origin() / vscale
		
		return Rect2(pos, size / vscale).has_point(tool.global_position)
	
	
	## Easier way to get position, relative to the screen, of node2d
	func get_pos_in_screen(node2d: Node2D) -> Vector2:
		if !node2d: 
			return Vector2.ZERO
		
		return node2d.get_global_transform_with_canvas().get_origin()
	
	
	## Easier way to get position ratio, relative to the screen, of node2d
	func get_pos_ratio_in_screen(node2d: Node2D) -> Vector2:
		if !node2d: 
			return Vector2.ZERO
		
		var pos := node2d.get_global_transform_with_canvas().get_origin()
		var size := node2d.get_viewport_rect().size
		
		return pos / size
	
	## Easier way to get position ratio, relative to the screen, of [param global_position]. A [param vp_transform] and a [param vp_size] should be provided.
	func get_pos_ratio_in_screen_by_pos(vp_trans: Transform2D, vp_size: Vector2, global_position: Vector2) -> Vector2:
		return (vp_trans * global_position) / vp_size



class Math:
	## Return a point on a oval by given [param center], [param amplitude], [param phase], and [param rot(optional)]
	static func oval(center: Vector2, amplitude: Vector2, phase: float, rot: float = 0) -> Vector2:
		return center + Vector2(amplitude.x * cos(phase), amplitude.y * sin(phase)).rotated(rot)
	
	
	## Return a direction from one point ot another
	static func look_at(from: Vector2, to: Vector2, trans: Transform2D) -> int:
		return int((trans.affine_inverse().basis_xform(from.direction_to(to))).sign().x)
