extends Node

var _custom_textures_raw: Dictionary
var custom_textures: Dictionary

var base_dir: String = OS.get_executable_path().get_base_dir() + "/custom"


func _init() -> void:
	var tex: Array[Dictionary] = load_external_textures()
	if tex.is_empty() || tex[0].is_empty(): return
	_custom_textures_raw = tex[0]
	custom_textures = tex[1]


func load_external_textures() -> Array[Dictionary]:
	print(base_dir)
	if !DirAccess.dir_exists_absolute(base_dir):
		print("Skipped loading custom textures")
		return []
	
	var loaded: Array[Dictionary] = [{}, {}]
	var dir_access = DirAccess.open(base_dir)
	if dir_access:
		dir_access.list_dir_begin()
		var file_name: String = dir_access.get_next()
		while file_name != "":
			var file_ext: String = file_name.get_extension().to_lower()
			if !dir_access.current_is_dir() && file_ext == "png":
				var texture_name: String = file_name.trim_suffix("." + file_ext)
				
				var file: Image = Image.load_from_file(base_dir + "/" + file_name)
				loaded[0][texture_name] = file
				var file_texture: ImageTexture = ImageTexture.create_from_image(file)
				loaded[1][texture_name] = file_texture
			
			file_name = dir_access.get_next()
		return loaded
	return []


func _input(event: InputEvent) -> void:
	if event is InputEventKey && event.is_pressed() && event.keycode == KEY_HOME:
		GlobalViewport.size.x = 8000
		GlobalViewport.vp.size.x = 8000
		await RenderingServer.frame_post_draw
		GlobalViewport.vp.get_texture().get_image().save_png("user://Screenshot.png")
		GlobalViewport.vp.size.x = 640
		GlobalViewport.size.x = 640
		GlobalViewport._update_view()
