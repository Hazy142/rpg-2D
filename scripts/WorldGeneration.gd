class_name WorldGeneration 
extends Node3D

const GENERATION_BOUND_DISTANCE = 16
const VERTICAL_AMPLITUDE = 10

var noise = FastNoiseLite.new()
var generated_cubes = {}
var procedural_tiles = {}

func _ready():
	WorldGeneration.instance = self
	generated_cubes = {}
	generate_new_cubes_from_position(Vector3(0, 0, 0))
	print("✓ Procedural terrain created! (%d cubes)" % get_child_count())

func generate_new_cubes_from_position(center_position):
	var start_x = int(center_position.x - GENERATION_BOUND_DISTANCE)
	var end_x = int(center_position.x + GENERATION_BOUND_DISTANCE)
	var start_z = int(center_position.z - GENERATION_BOUND_DISTANCE)
	var end_z = int(center_position.z + GENERATION_BOUND_DISTANCE)
	
	for x in range(start_x, end_x): 
		for z in range(start_z, end_z):
			generate_cube_if_new(x, z)

func generate_cube_if_new(x, z):
	if not has_cube_been_generated(x, z):
		var noise_val = noise.get_noise_2d(x, z)
		var height = noise_val * VERTICAL_AMPLITUDE
		var static_body = create_cube(Vector3(x, height, z), get_color_from_noise(noise_val))
		register_cube_generation_at_coordinate(x, z)

		# FIX: Erstelle die logische Kachel, verknüpfe sie via Meta-Data und füge sie zum Szenenbaum hinzu.
		var proc_tile = ProceduralTile.new(static_body, Vector3(x, height, z))
		static_body.set_meta("tile_data", proc_tile)
		add_child(proc_tile) # Wichtig, damit is_inside_tree() funktioniert!

		# Das Dictionary ist jetzt optional, aber wir behalten es für mögliche andere Logiken.
		procedural_tiles[Vector3(x, 0, z)] = proc_tile

func has_cube_been_generated(x, z):
	return (x in generated_cubes and z in generated_cubes[x] and generated_cubes[x][z])

func register_cube_generation_at_coordinate(x, z):
	if x not in generated_cubes:
		generated_cubes[x] = {}
	generated_cubes[x][z] = true

# ===== GEÄNDERT: Return Type hinzugefügt =====
func create_cube(position, color) -> StaticBody3D:
	var static_body = StaticBody3D.new()
	static_body.position = position
	static_body.name = "TerrainTile"
	
	# ===== Physics Layer setzen (RICHTIG!) =====
	static_body.collision_layer = 1
	static_body.collision_mask = 1
	
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1, 1, 1)
	mesh.mesh = box
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	box.material = material
	
	static_body.add_child(mesh)
	
	var collision = CollisionShape3D.new()
	collision.shape = BoxShape3D.new()
	collision.shape.size = Vector3(1, 1, 1)
	
	static_body.add_child(collision)
	
	add_child(static_body)
	return static_body

func get_color_from_noise(noise_value):
	if noise_value <= -.4:
		return Color.RED
	elif noise_value <= -.2:
		return Color.GREEN
	elif noise_value <= 0:
		return Color.BLUE
	elif noise_value <= .2:
		return Color.GRAY
	else:
		return Color.CYAN
