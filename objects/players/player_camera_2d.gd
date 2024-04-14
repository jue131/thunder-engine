extends Camera2D
class_name PlayerCamera2D

var stop_blocking_edges: bool

@onready var par: Node2D = get_parent()


func _ready():
	Thunder._current_camera = self
	process_callback = CAMERA2D_PROCESS_IDLE #CAMERA2D_PROCESS_PHYSICS
	make_current()
	teleport()


func _physics_process(_delta):
	teleport()


func teleport() -> void:
	if !is_current(): return
	var player: Player = Thunder._current_player
	if !par is PathFollow2D:
		if player:
			global_position = Vector2(player.global_position)
		elif Multiplayer.online_play:
			for i in get_tree().get_nodes_in_group(&"Player"):
				if Multiplayer.game.currently_spectating == str(i.name).to_int():
					global_position = Vector2(i.global_position)
	
	if par is PathFollow2D:
		if player && !stop_blocking_edges:
			var rot: float = get_viewport_transform().affine_inverse().get_rotation()
			var kc: KinematicCollision2D 
			while !kc && player.get_global_transform_with_canvas().get_origin().x < 16:
				kc = player.move_and_collide(Vector2.RIGHT.rotated(rot))
				if player.velocity.dot(Vector2.LEFT.rotated(rot)) > 0:
					player.vel_set_x(0)
			while !kc && player.get_global_transform_with_canvas().get_origin().x > get_viewport_rect().size.x - 16:
				kc = player.move_and_collide(Vector2.LEFT.rotated(rot))
				if player.velocity.dot(Vector2.RIGHT.rotated(rot)) > 0:
					player.vel_set_x(0)
			if kc && kc.get_collider():
				player.die()
	
	if Multiplayer.online_play:
		var p_id = multiplayer.get_unique_id()
		var pl_data = Multiplayer.game.get_player_data(p_id)
		if pl_data:
			pl_data.player_cam_pos = get_screen_center_position()
	
	Thunder.view.cam_border.call_deferred()


func shock(duration: float, amplitude: Vector2, interval: float = 0.01) -> void:
	var ofs: Vector2 = offset
	var tw: Tween = create_tween().set_loops(ceili(duration / interval)).set_trans(Tween.TRANS_ELASTIC)
	tw.tween_callback(
		func() -> void:
			offset = Vector2(
				randf_range(-amplitude.x, amplitude.x),
				randf_range(-amplitude.y, amplitude.y)
			)
	).set_delay(interval)
	tw.finished.connect(
		func() -> void:
			offset = ofs
	)
