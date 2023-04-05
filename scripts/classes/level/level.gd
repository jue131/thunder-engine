@tool
@icon("./icon.svg")
extends Stage2D
class_name Level

## Base level node[br]
## Once you selected this node via [b]Create Node Pannel[/b] it will automatically deploy the basic template
## of a level, which is more convenient to structure a level from zero.

## Rest time of the level. If going to [color=red]0[/color], the player alive will be killed in force.
@export var time: int = 360

@export_group("Player's Falling Below")
## Enum to decide the bahavior when a player falls from the bottom of the screen[br]
## 0 = Nothing[br]
## 1 = Death[br]
## 2 = Wrap from top of the screen
@export_enum("Nothing", "Death", "Wrap") var falling_below_screen_action: int = 1

## Modifies the bottom line that detect player as "falling below the screen"
@export var falling_below_y_offset: float = 64.0


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		if get_child_count() == 0:
			_prepare_template()
		
		return
	
	Data.values.time = time

# Adding neccessary nodes to our level scene
func _prepare_template() -> void:
	var player = load("res://engine/objects/core/player/player.tscn").instantiate()
	add_child(player)
	player.position = Vector2(80, 416)
	player.set_owner(self)
	
	var camera = Camera2D.new()
	camera.set_script(load("res://engine/objects/core/player/scripts/player_camera_2d.gd"))
	camera.limit_left = 0
	camera.limit_bottom = 480
	camera.limit_top = 0
	add_child(camera)
	camera.set_name('PlayerCamera2D')
	camera.set_owner(self)
	
	var tilemap = TileMap.new()
	tilemap.tile_set = load("res://engine/tilesets/placeholder/placeholder_tileset.tres")
	add_child(tilemap, true)
	tilemap.set_cell(0, Vector2i(2, 13), 1, Vector2i.ZERO)
	tilemap.set_owner(self)
	
	var hud = load("res://engine/components/hud/hud.tscn").instantiate()
	add_child(hud)
	hud.set_owner(self)


func _physics_process(delta):
	if Engine.is_editor_hint():
		return
	
	if !Thunder.view.screen_bottom(Thunder._current_player.global_position, falling_below_y_offset): # TEMP
		match falling_below_screen_action:
			1: Thunder._current_player.kill()
			2: Thunder._current_player.position.y -= 608

