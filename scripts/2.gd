extends Node3D

const GENERATION_BOUND_DISTANCE = 16
const VERTICAL_AMPLITUDE = 10

var noise = FastNoiseLite.new()
var player_position: Vector3
var player: Node
var generated_cubes



func _ready():
	generated_cubes = {}
	print("DEBUG: Generating cubes around (0, 0, 0)...")
	generate_new_cubes_from_position(Vector3(0, 0, 0))
	print("DEBUG: Generated %d cubes" % get_child_count())
	
	await get_tree().process_frame
	convert_to_tactics_tiles()
	
func generate_new_cubes_from_position(center_position):
	var start_x = int(center_position.x - GENERATION_BOUND_DISTANCE)
	var end_x = int(center_position.x + GENERATION_BOUND_DISTANCE)
	var start_z = int(center_position.z - GENERATION_BOUND_DISTANCE)
	var end_z = int(center_position.z + GENERATION_BOUND_DISTANCE)
	
	for x in range(start_x, end_x):
		for z in range(start_z, end_z):
			generate_cube_if_new(x, z)

func generate_cube_if_new(x,z):
	if !has_cube_been_generated(x,z):
		var generated_noise = noise.get_noise_2d(x,z)
		create_cube(Vector3(x,generated_noise*VERTICAL_AMPLITUDE,z), get_color_from_noise(generated_noise))
		register_cube_generation_at_coordinate(x,z)

func has_cube_been_generated(x,z):
	if x in generated_cubes and z in generated_cubes[x] and generated_cubes[x][z] == true:
		return true
	else:
		return false
			
func register_cube_generation_at_coordinate(x,z):
	if x in generated_cubes:
		generated_cubes[x][z] = true
	else:
		generated_cubes[x] = {z: true}
			

func _process(_delta):
	# Spieler-folgendes Terrain generieren deaktivieren für jetzt
	pass

func create_cube(position, color):
	var box_size = Vector3(2, 2, 2)  # ← 2x größer!
	
	var static_body = StaticBody3D.new()
	static_body.position = position  # ← KEIN +10! Direkt!
	static_body.name = "StaticTile"
	
	var collision_shape_3d = CollisionShape3D.new()
	collision_shape_3d.shape = BoxShape3D.new()
	collision_shape_3d.shape.size = box_size

	var mesh = MeshInstance3D.new()
	mesh.name = "Tile"
	
	var boxmesh = BoxMesh.new()
	boxmesh.size = box_size
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission = color  # ← GLOW!
	material.emission_energy_multiplier = 2.0
	
	boxmesh.material = material
	
	mesh.set_mesh(boxmesh)  
	static_body.add_child(mesh)
	static_body.add_child(collision_shape_3d)
	
	add_child(static_body)



func get_color_from_noise(noise_value):
	if noise_value <= -.4:
		return Color(1,0,0,1)
	elif noise_value <= -.2:
		return Color(0,1,0,1)
	elif noise_value <= 0:
		return Color(0,0,1,1)
	elif noise_value <= .2:
		return Color(.5,.5,.5,1)
	elif noise_value > .2:
		return Color(.3,.8,.5,1)
	
func convert_to_tactics_tiles() -> void:
	print("Converting %d cubes to tactics tiles..." % get_child_count())
	# Wende TacticsTile Script direkt auf unsere StaticBody3D an
	for _static_body: StaticBody3D in get_children():
		_static_body.set_script(load("res://data/modules/tactics/level/arena/tile/tactics_tile.gd"))
		_static_body.configure_tile()
		_static_body.set_process(true)
	print("✓ Procedural tiles configured!")
