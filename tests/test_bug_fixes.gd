extends Node3D

const WorldGeneration = preload("res://scripts/WorldGeneration.gd")
const TacticsPawn = preload("res://data/modules/tactics/level/pawn/pawn.tscn")

func _ready():
	# 1. Setup the scene
	var world_gen = WorldGeneration.new()
	add_child(world_gen)

	var pawn = TacticsPawn.instantiate()
	add_child(pawn)

	# 2. Wait for the world to generate
	await get_tree().create_timer(1.0).timeout

	# 3. Position the pawn
	var spawn_pos = Vector3(5, 0, 5)
	var terrain_height = get_terrain_height_at(world_gen, spawn_pos.x, spawn_pos.z)
	pawn.position = Vector3(spawn_pos.x, terrain_height + 1.0, spawn_pos.z)

	# 4. Wait for the pawn to settle
	await get_tree().create_timer(0.1).timeout

	# 5. Run the tests
	test_pawn_can_find_tile(pawn)
	test_pawn_spawn_height(pawn, terrain_height)

	# 6. Quit the test
	get_tree().quit()


func get_terrain_height_at(terrain: Node3D, x: float, z: float) -> float:
	var space = terrain.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		Vector3(x, 50, z),
		Vector3(x, -50, z)
	)
	var result = space.intersect_ray(query)

	if result:
		return result.position.y
	else:
		return 0.0


func test_pawn_can_find_tile(pawn: Node3D):
	var tile = pawn.get_tile()
	assert(tile != null, "Test Failed: Pawn should be able to find its tile.")
	print("Test Passed: Pawn can find its tile.")

func test_pawn_spawn_height(pawn: Node3D, expected_height: float):
	var pawn_height = pawn.position.y
	assert(abs(pawn_height - (expected_height + 1.0)) < 0.1, "Test Failed: Pawn is not at the correct height.")
	print("Test Passed: Pawn is at the correct height.")
