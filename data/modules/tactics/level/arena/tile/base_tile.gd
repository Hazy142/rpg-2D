class_name BaseTile
extends Node3D
## Base class for all tile types (TacticsTile or ProceduralTile)


func get_neighbors(height: float = 0) -> Array:
	return []

func is_walkable() -> bool:
	return true

func is_taken() -> bool:
	return false

func get_tile_occupier() -> Node:
	return null

func reset_markers() -> void:
	pass

var hover: bool = false
var reachable: bool = false
var attackable: bool = false
var pf_root: BaseTile = null
var pf_distance: int = 0
