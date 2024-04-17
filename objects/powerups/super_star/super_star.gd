extends Powerup

@export var starman_duration: float = 10
@export var starman_music: Resource = preload("res://engine/objects/powerups/super_star/music-starman.it")

func _physics_process(delta: float) -> void:
	super(delta)
	if is_on_floor():
		jump(250)
	if !appear_distance:
		$Sprite.speed_scale = 5

@rpc("any_peer", "call_local", "reliable")
func collect() -> void:
	if appear_distance: return
	var player = Multiplayer.game.get_player(multiplayer.get_remote_sender_id())
	if !player: return
	
	if score > 0:
		ScoreText.new(str(score), self)
		Data.values.score += score
	
	queue_free()
	
	Audio.play_sound(pickup_powerup_sound, self, false, {pitch = sound_pitch})
	player.starman(starman_duration)
	var mus_loader = Scenes.current_scene.get_node_or_null("MusicLoader")
	if !mus_loader: return
	mus_loader.play_immediately = false
	mus_loader.pause_music()
	Audio.play_music(starman_music, 98)
