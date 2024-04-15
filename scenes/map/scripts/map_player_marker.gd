@icon("../textures/icons/branch.svg")
@tool
class_name MapPlayerMarker extends Marker2D

@export_file("*.tscn", "*.scn") var level: String: 
	set = set_level_path, get = get_level_path

# DO NOT USE OUTSIDE THIS SCRIPT
var _level: String

@onready var marker_space: MarkerSpace = get_parent()
var player

signal changed

func _enter_tree() -> void:
	if !is_in_group("map_marker"):
		add_to_group("map_marker")
	
	if !Engine.is_editor_hint(): return
	set_notify_transform(true)


func _ready() -> void:
	if Engine.is_editor_hint(): return
	player = Scenes.current_scene.get_node(Scenes.current_scene.player)
	
	if (
		is_level_completed() && !Data.values.get('map_force_selected_marker') ||
		Data.values.get('map_force_selected_marker') == level
	):
		await get_tree().process_frame
		#Data.values.erase('map_force_selected_marker')
		player.current_marker = get_next_marker()
		#print(marker_space.get_next_marker_id())
		player.global_position = global_position
		
		if is_instance_valid(player.camera):
			player.camera.reset_smoothing.call_deferred()
		
		marker_space.make_dots_visible_before(global_position)
		marker_space.add_uncompleted_levels_after(level)
		Scenes.current_scene.next_level_ready.emit(
			marker_space.total_levels.size() - marker_space.uncompleted_levels.size()
		)
	elif is_level():
		await get_tree().process_frame
		if marker_space.uncompleted_levels.is_empty():
			marker_space.add_all_uncompleted_levels()


func get_next_marker() -> MapPlayerMarker:
	if marker_space.get_last_marker().get_index() != get_index():
		return marker_space.get_child(get_index() + 1)
	else:
		return Scenes.current_scene.get_child(marker_space.get_index() + 1).get_first_marker()


func _notification(what: int) -> void:
	if !Engine.is_editor_hint(): return
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		changed.emit()

func is_level() -> bool:
	return !_level.is_empty()

func is_level_completed() -> bool:
	return (
		ProfileManager.current_profile.data.has(&"completed_levels") &&
		ProfileManager.current_profile.data[&"completed_levels"].has(level)
	)

func set_level_path(value: String) -> void:
	changed.emit()
	_level = value
	level = value

func get_level_path() -> String:
	return _level
