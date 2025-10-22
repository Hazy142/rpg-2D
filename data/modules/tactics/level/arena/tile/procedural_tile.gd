class_name ProceduralTile
extends BaseTile
## Wrapper für Procedural Terrain Tiles (StaticBody3D)

var terrain_node: StaticBody3D
var grid_position: Vector3

func _init(node: StaticBody3D, pos: Vector3) -> void:
	terrain_node = node
	grid_position = pos
	# Wichtig: Setze dich selbst auf die Position des Terrain-Nodes!
	global_position = terrain_node.global_position


## Procedural tiles are always considered walkable.
func is_walkable() -> bool:
	return true
