class_name TacticsLevelSetup
extends Node
## Setup Script für Procedural + Static Levels

static func setup_participants_on_procedural_terrain(
	arena: TacticsArena,
	participant: TacticsParticipant,
	terrain: Node3D  # WorldGeneration Node
) -> void:
	"""Positioniert Spieler/Gegner auf Procedural Terrain"""
	
	# Finde passende Terrain-Höhe
	var player_start = Vector3(-5, 0, -5)
	var opponent_start = Vector3(5, 0, 5)
	
	# Snap to Terrain
	player_start.y = get_terrain_height_at(terrain, player_start.x, player_start.z) + 1.0
	opponent_start.y = get_terrain_height_at(terrain, opponent_start.x, opponent_start.z) + 1.0
	
	# Position Participant Children
	if participant.has_node("TacticsPlayer"):
		participant.get_node("TacticsPlayer").position = player_start
	if participant.has_node("TacticsOpponent"):
		participant.get_node("TacticsOpponent").position = opponent_start

static func get_terrain_height_at(terrain: Node3D, x: float, z: float) -> float:
	"""Findet Terrain-Höhe an Position (x, z)"""
	# Nutze RayCast nach unten
	var space = terrain.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		Vector3(x, 50, z),  # Von oben
		Vector3(x, -50, z)  # Nach unten
	)
	var result = space.intersect_ray(query)
	
	if result:
		return result.position.y
	else:
		return 0.0  # Default fallback
