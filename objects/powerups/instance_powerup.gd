extends InstanceNode2D
class_name InstancePowerup

@export_category("InstanceNode2D")
@export_group("Creation","creation_")
@export var creation_fallback_node: PackedScene


func prepare(is_small: bool) -> Variant:
	# Duplicate self to avoid overwriting bugs
	var d_self = self.duplicate()
	
	if !creation_nodepack: return d_self
	#var is_small: bool = node is Player && node.suit && node.is_player_power(Data.PLAYER_POWER.SMALL)
	
	if (
		d_self.creation_fallback_node &&
		d_self.creation_nodepack.resource_path != d_self.creation_fallback_node.resource_path &&
		is_small
	):
		d_self.creation_nodepack = d_self.creation_fallback_node
	
	return d_self
