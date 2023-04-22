@tool
extends Area2D

@export_enum("Up:0", "Down:1", "Up & Down:2") var koopa_bros_jumping_type: int


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	body_entered.connect(
		func(bro: GravityBody2D) -> void:
			if !bro.is_in_group(&"koopa_bro"):
				return
			match koopa_bros_jumping_type:
				0:
					bro._jump_up = true
				1:
					bro._jump_down = true
				2:
					bro._jump_up = true
					bro._jump_down = true
	)
	body_exited.connect(
		func(bro: GravityBody2D) -> void:
			if !bro.is_in_group(&"koopa_bro"):
				return
			bro._jump_up = false
			bro._jump_down = false
	)
	$Text.visible = false
	$Text.queue_free()


func _process(_delta: float) -> void:
	if !Engine.is_editor_hint(): return
	if !Thunder.View.shows_tool(self): return
	
	var str: String
	match koopa_bros_jumping_type:
		0:
			str = "UP"
		1:
			str = "DOWN"
		2:
			str = "UP & DOWN"
	$Text.text = str
