extends Node

enum QUALITY {
	MIN,
	MID,
	MAX,
}

const settings_path = "user://settings.thss"

var default_settings = {
	"sound": 1,
	"music": 1,
	"quality": QUALITY.MAX,
	"game_speed": 1,
	"autopause": true,
	"vsync": true,
	"controls": {
		"m_up": _get_current_key(&"m_up"),
		"m_down": _get_current_key(&"m_down"),
		"m_left": _get_current_key(&"m_left"),
		"m_right": _get_current_key(&"m_right"),
		"m_jump": _get_current_key(&"m_jump"),
		"m_run": _get_current_key(&"m_run"),
		"m_attack": _get_current_key(&"m_attack"),
		"pause_toggle": _get_current_key(&"pause_toggle"),
	},
}

var settings = default_settings.duplicate(true)

func _ready() -> void:
	load_settings()

## Returns the key label of specified action
func _get_current_key(action: StringName) :
	var keys = InputMap.action_get_events(action)
	for key in keys:
		if key is InputEventKey:
			return key.as_text().split(' (')[0]

## Loads controls settings to InputMap
func _load_keys() -> void:
	var controls = settings.controls
	for action in controls:
		if controls[action] and controls[action] is String:
			var scancode = OS.find_keycode_from_string(controls[action])
			var key = InputEventKey.new()
			key.keycode = scancode
			if key is InputEventKey:
				var oldKeys = InputMap.action_get_events(action)
				for toRemove in oldKeys:
					if toRemove is InputEventKey:
						InputMap.action_erase_event(action, toRemove)
				InputMap.action_add_event(action, key)
	
	print("[Settings Manager] Loaded input maps from settings.")

## Saves the settings variable to file
func save_settings() -> void:
	var json: JSON = JSON.new()
	var data = json.stringify(settings)
	
	var file: FileAccess = FileAccess.open(settings_path, FileAccess.WRITE)
	file.store_string(data)
	file.close()
	
	print("[Settings Manager] Settings saved!")

## Loads the settings variable from file
func load_settings() -> void:
	var path: String = settings_path
	if !FileAccess.file_exists(path):
		print("[Settings Manager] Using the default settings, no saved ones.")
		return
	
	var data: String = FileAccess.get_file_as_string(path)
	var dict = JSON.parse_string(data)
	
	if dict == null:
		OS.alert("Failed to load saved settings " + name, "Can't load save file!")
		return
	
	settings = dict
	_process_settings()
	print("[Settings Manager] Loaded settings from file.")

## Processes certain settings and applies their effects
func _process_settings() -> void:
	# Game Speed
	Engine.time_scale = settings.game_speed
	
	# Vsync
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.vsync else DisplayServer.VSYNC_DISABLED)
	
	# Music Volume
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(settings.music)
	)
	
	# Sound Volume
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Sound"),
		linear_to_db(settings.sound)
	)