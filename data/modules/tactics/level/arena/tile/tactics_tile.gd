class_name TacticsTile
extends BaseTile

var tile_raycast: Resource = load("res://data/modules/tactics/level/arena/tile/raycast/tile_raycasting.tscn")

# Materialien werden nur einmal geladen
var hover_mat: StandardMaterial3D = TacticsConfig.mat_color.hover
var reachable_mat: StandardMaterial3D = TacticsConfig.mat_color.reachable
var hover_reachable_mat: StandardMaterial3D = TacticsConfig.mat_color.reachable_hover
var attackable_mat: StandardMaterial3D = TacticsConfig.mat_color.attackable
var hover_attackable_mat: StandardMaterial3D = TacticsConfig.mat_color.hover_attackable

# FIX: Überschreibe die Setter der geerbten Variablen, ohne sie neu zu deklarieren.
hover:
	set(value):
		if super.hover != value:
			super.hover = value
			_update_material()

reachable:
	set(value):
		if super.reachable != value:
			super.reachable = value
			_update_material()

attackable:
	set(value):
		if super.attackable != value:
			super.attackable = value
			_update_material()

# Die _process-Funktion wird komplett entfernt.
func _update_material():
	var tile_mesh: MeshInstance3D = get_node_or_null("Tile")
	if not tile_mesh:
		return

	tile_mesh.visible = attackable or reachable or hover

	if hover:
		if reachable:
			tile_mesh.material_override = hover_reachable_mat
		elif attackable:
			tile_mesh.material_override = hover_attackable_mat
		else:
			tile_mesh.material_override = hover_mat
	else:
		if reachable:
			tile_mesh.material_override = reachable_mat
		elif attackable:
			tile_mesh.material_override = attackable_mat
		else:
			# Wenn kein Zustand aktiv ist, Material entfernen, um das Original zu zeigen
			tile_mesh.material_override = null

# ... Restliche Funktionen (get_neighbors, get_tile_occupier, etc.) bleiben gleich ...
func get_neighbors(_height: float = 0.0) -> Array:
	return $RayCasting.get_all_neighbors(_height)

func get_tile_occupier() -> Node:
	return $RayCasting.get_object_above()

func is_taken() -> bool:
	return get_tile_occupier() != null

func reset_markers() -> void:
	pf_root = null
	pf_distance = 0
	# Setze die Member-Variablen direkt, um den Setter zu triggern
	self.reachable = false
	self.attackable = false
	self.hover = false

func configure_tile() -> void:
	var instance: Node = tile_raycast.instantiate()
	add_child(instance)
	reset_markers()
