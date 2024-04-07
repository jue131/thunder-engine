extends Label

@export var index: int
@onready var mp_layer: CanvasLayer = $"../.."

var modulation: float

func highlight() -> void:
	modulation = 4.0

func _process(delta: float) -> void:
	modulation -= delta
	if mp_layer.force_highlight_chat:
		self_modulate.a = 1.0
		return
	self_modulate.a = clampf(modulation, 0.0 if index < 5 else 0.5, 1.0)
