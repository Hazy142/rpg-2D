class_name ProceduralTile
extends BaseTile
## Wrapper für Procedural Terrain Tiles (StaticBody3D)

var terrain_node: StaticBody3D
var grid_position: Vector3
var _static_body: StaticBody3D  # ← HINZUFÜGEN!
var _initial_position: Vector3  # ← HINZUFÜGEN!
var tile_resource: TacticsTile  # ← DIESES PROPERTY FEHLT!

func _init(static_body: StaticBody3D = null, position: Vector3 = Vector3.ZERO):
	_static_body = static_body
	_initial_position = position  # Speichere ab

func _ready():
	# Setze Position erst wenn im Tree
	if _initial_position != Vector3.ZERO:
		global_position = _initial_position

## Procedural tiles are always considered walkable.
func is_walkable() -> bool:
	return true
