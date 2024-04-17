extends Area2D

@onready var player: Player = Thunder._current_player
@onready var collision: CollisionShape2D = $CollisionShape2D

## INFO ABOUT META:
## - "mp_spawn" means this area has been spawned from AreaSpawner.
##   If not present, it's a local area.
## - "area_for_self" is granted to areas that are spawned for you.
##   Such area's purpose is only for synchronization with peers.


func _ready() -> void:
	if has_meta(&"area_for_self"):
		#if !Multiplayer.is_host():
		set_process(false)
		set_physics_process(false)
		collision.shape = collision.shape.duplicate()
		collision.shape.size = Vector2.ONE
		return
	if str(multiplayer.get_unique_id()) == str(name) || !Multiplayer.online_play:
		Thunder._current_screen_area = self
		player = Thunder._current_player
	Thunder._connect(area_entered, _on_screen_area_entered)
	Thunder._connect(area_exited, _on_screen_area_exited)
	collision.shape = collision.shape.duplicate()
	collision.shape.size = get_viewport_rect().size

# Sync area position with camera
func _process(delta: float) -> void:
	if has_meta(&"mp_spawn"): return
	var cam = Thunder._current_camera
	if !cam: return
	global_position = cam.get_screen_center_position()
	player = Thunder._current_player
	return


func _physics_process(delta: float) -> void:
	if !Multiplayer.online_play:
		player = Thunder._current_player
		return
	if !has_meta(&"mp_spawn"):
		return
	
	var players = get_tree().get_nodes_in_group(&"Player")
	for i in players:
		var p_id = str(i.name).to_int()
		if (
			p_id == str(name).to_int() && 
			Multiplayer.game.has_player_data(p_id)
		):
			global_position = Multiplayer.game.get_player_data(p_id).get_cam_pos()
			player = i


func _on_screen_area_entered(area: Area2D) -> void:
	if !area is ActivationArea: return
	if !Multiplayer.is_host(): return
	
	if area.players.is_empty():
		area.screen_entered.emit()
	
	if !player: return
	if !player in area.players:
		area.screen_entered_player.emit(player)
		area.players.append(player)


func _on_screen_area_exited(area: Area2D) -> void:
	if !area is ActivationArea: return
	if !Multiplayer.is_host(): return
	
	if player in area.players:
		if player:
			area.screen_exited_player.emit(player)
		area.players.erase(player)
	
	if area.players.is_empty():
		area.screen_exited.emit()
