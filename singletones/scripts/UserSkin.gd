extends Node

var _custom_textures_raw: Dictionary
var custom_textures: Dictionary
var custom_sprite_frames: Dictionary
var peer_custom_textures: Dictionary
var peer_custom_sprite_frames: Dictionary

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


func get_custom_sprite_frames(old_sprites: SpriteFrames, skin_name: String, p_id: int = 0) -> SpriteFrames:
	var custom_tex
	if p_id == 0 || p_id == multiplayer.get_unique_id():
		if custom_sprite_frames.has(skin_name):
			return custom_sprite_frames[skin_name]
		
		custom_tex = custom_textures[skin_name]
		var new_sprites: SpriteFrames = new_custom_sprite_frames(old_sprites, custom_tex)
		custom_sprite_frames[skin_name] = new_sprites
		return new_sprites

	if peer_custom_sprite_frames.has(p_id) && peer_custom_sprite_frames[p_id].has(skin_name):
		return peer_custom_sprite_frames[p_id][skin_name]
	
	custom_tex = peer_custom_textures[p_id][skin_name]
	var new_sprites: SpriteFrames = new_custom_sprite_frames(old_sprites, custom_tex)
	if peer_custom_sprite_frames.is_empty():
		peer_custom_sprite_frames[p_id] = {}
	peer_custom_sprite_frames[p_id][skin_name] = new_sprites
	return new_sprites


func new_custom_sprite_frames(old_sprites: SpriteFrames, custom_texture: ImageTexture) -> SpriteFrames:
	if !old_sprites: return null
	if !custom_texture: return old_sprites
	
	var new_sprites := SpriteFrames.new()
	for anim in old_sprites.get_animation_names():
		if anim != "default":
			new_sprites.add_animation(anim)
		new_sprites.set_animation_speed(anim, old_sprites.get_animation_speed(anim))
		new_sprites.set_animation_loop(anim, old_sprites.get_animation_loop(anim))
		for frame in old_sprites.get_frame_count(anim):
			var tex = old_sprites.get_frame_texture(anim, frame)
			var new_tex := AtlasTexture.new()
			if tex is AtlasTexture:
				new_tex.atlas = custom_texture
				new_tex.margin = tex.margin
				new_tex.region = tex.region
			else:
				new_tex.atlas = new_tex
			new_sprites.add_frame(anim, new_tex)
	return new_sprites


func send_texture_bytes(p_id: int) -> PackedByteArray:
	var encoded := PackedByteArray("skin_texture".to_ascii_buffer()) # 12 bytes
	var texture_array := Array()
	var raw_textures = _custom_textures_raw
	var counter: int = 0
	for i in raw_textures.keys():
		if counter > 32:
			printerr("[SKINLAYER ERROR] Uploader: Too many images (32 is the limit)! Breaking the loop.")
			break
		counter += 1
		
		if i.length() > 32:
			printerr("[SKINLAYER ERROR] Uploader: Name of the texture is larger than a limit of 32 chars. Skipped.")
			continue
		var texture_name: PackedByteArray = i.to_utf8_buffer()
		var buffer_image: PackedByteArray = raw_textures[i].save_png_to_buffer()
		if buffer_image.size() > 65536:
			printerr("[SKINLAYER ERROR] Uploader: The loaded texture size (%s) is larger than a limit of 64 KB. Skipped." % [i])
			continue
		var name_and_image := Array([texture_name, buffer_image])
		texture_array.append(name_and_image)
		#texture_array.append(737958238)
		
	encoded.append_array(var_to_bytes(texture_array))
	return encoded


func get_texture_bytes(p_id: int, packet: PackedByteArray):
	var texture_array: Array = bytes_to_var(packet.slice(12))
	var texture_dict: Dictionary
	
	var counter: int = 0
	for i in texture_array:
		if counter > 32:
			printerr("[SKINLAYER ERROR] Receiver: Too many images (32 is the limit)! Breaking the loop.")
			break
		counter += 1
		
		var texture_name: String = i[0].get_string_from_utf8()
		if texture_name.length() > 32:
			printerr("[SKINLAYER ERROR] Receiver: Name of the texture is larger than a limit of 32 chars. Skipped.")
			continue
		
		print("[SKINLAYER] ", texture_name, ", loading to cache.")
		if i[1].size() > 65536:
			printerr("[SKINLAYER ERROR] Uploader: The loaded texture size (%s) is larger than a limit of 64 KB. Skipped." % [i])
			continue
		var buffer_image: Image = Image.new()
		var err: Error = buffer_image.load_png_from_buffer(i[1])
		if err != OK:
			printerr("[SKINLAYER ERROR] Receiver: Error loading image: ", err)
			continue
		var image = ImageTexture.create_from_image(buffer_image)
		texture_dict[texture_name] = image
		
		print("[SKINLAYER] ", texture_name, ", Successfully loaded.")
	
	peer_custom_textures[p_id] = texture_dict


func _input(event: InputEvent) -> void:
	if event is InputEventKey && event.is_pressed() && event.keycode == KEY_HOME:
		GlobalViewport.size.x = 8000
		GlobalViewport.vp.size.x = 8000
		await RenderingServer.frame_post_draw
		GlobalViewport.vp.get_texture().get_image().save_png("user://Screenshot.png")
		GlobalViewport.vp.size.x = 640
		GlobalViewport.size.x = 640
		GlobalViewport._update_view()
