extends GravityBody2D

@export var wait_time: float = 3.5
@export var check_for_lives: bool = true

var circle_closing_speed: float = 0.05
var circle_opening_speed: float = 0.1

var movement: bool
var animation_only: bool = false
var p_id: int

@onready var game_over_music: AudioStream = load(ProjectSettings.get_setting("application/thunder_settings/player/gameover_music"))


func _ready() -> void:
	await get_tree().create_timer(0.5, false, true).timeout
	
	movement = true
	vel_set_y(-550)
	
	if animation_only && !multiplayer.is_server():
		return
	
	if wait_time > 0.0:
		await get_tree().create_timer(wait_time, false, true).timeout
	
	#if !p_id:
	#	return
	
	# After death
	if check_for_lives:
		if Data.values.lives == 0:
			if !Multiplayer.online_play:
				if is_instance_valid(Thunder._current_hud):
					Thunder._current_hud.game_over()
					Audio.play_music(game_over_music, 1, { "ignore_pause": true }, false, false)
			else:
				
				Multiplayer.spectators.append(p_id)
			return
	
	if multiplayer.is_server():
		Multiplayer.respawn_player.rpc(p_id)
	
	if animation_only: return
	
	Thunder._current_player_state = null
	Data.values.lives -= 1
	Data.values.onetime_blocks = false
	
	if !Multiplayer.online_play:
		# Transition
		TransitionManager.accept_transition(
		load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
			.instantiate()
			.with_speeds(circle_closing_speed, -circle_opening_speed)
		)
		
		var cam: Camera2D = Thunder._current_camera
		var marker: Marker2D
		if cam:
			var cam_pos = cam.get_screen_center_position()
			marker = Marker2D.new()
			marker.position = Vector2(
				global_position.x,
				clamp(global_position.y, cam_pos.y - 248, cam_pos.y + 248)
			)
			Scenes.current_scene.add_child(marker)
		
		TransitionManager.current_transition.on(marker) # Supports a Node2D or a Vector2
		TransitionManager.transition_middle.connect(func():
			TransitionManager.current_transition.paused = true
			Scenes.reload_current_scene()
		, CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	else:
		Multiplayer.make_player_visible.rpc(multiplayer.get_unique_id())


func _physics_process(delta: float) -> void:
	if !movement:
		return
	motion_process(delta)
