class_name TacticsPawn
extends CharacterBody3D
## Represents a pawn in the tactics game, handling movement, combat, and state management

## Resource containing control-related data and configurations
@export var controls: TacticsControlsResource = load("res://data/models/view/control/tactics/control.tres")

## Resource containing pawn-specific data and configurations
var res: TacticsPawnResource
## Service handling pawn-related logic and operations
var serv: TacticsPawnService

## Reference to the Stats node, handling pawn statistics
@onready var stats: Stats = $Expertise/Stats
## The expertise (class or type) of the pawn
@onready var expertise: String = $Expertise/Stats.expertise
## Reference to the TacticsPawnSprite node, handling visual representation
@onready var character: TacticsPawnSprite = $Character

@onready var tile_raycast: RayCast3D = $Tile


## Initializes the TacticsPawn node
func _ready() -> void:
	res = TacticsPawnResource.new()
	serv = TacticsPawnService.new()
	serv.setup(self)
	controls.set_actions_menu_visibility(false, self)
	show_pawn_stats(false)


## Processes pawn logic every physics frame
##
## @param delta: Time elapsed since the last frame
func _physics_process(delta: float) -> void:
	var tile = get_tile()
	print("Pawn Position: ", position, " | Tile: ", tile)
	serv.process(self, delta)


## Centers the pawn on its current tile
##
## @return: Whether the centering operation was successful
func center() -> bool:
	return character.adjust_to_center(self)


## Shows or hides the pawn's stats UI
##
## @param v: Whether to show (true) or hide (false) the stats
func show_pawn_stats(v: bool) -> void:
	$Character/CharacterUI.visible = v


## Gets the tile the pawn is currently on
##
## @return: The BaseTile the pawn is on
func get_tile() -> BaseTile:
	var collider = $Tile.get_collider()
	
	print("\n--- GET_TILE DEBUG ---")
	print("Pawn raw position: ", position)
	
	if collider is TacticsTile:
		print("Found TacticsTile!")
		return collider as TacticsTile
	elif collider is StaticBody3D:
		print("Found StaticBody3D - trying procedural lookup...")
		
		if not WorldGeneration.instance:
			print("ERROR: WorldGeneration instance not found!")
			return null
		
		var world_gen = WorldGeneration.instance
		print("WorldGeneration found! Dictionary has ", world_gen.procedural_tiles.size(), " tiles")
		
		var x = int(round(position.x))
		var z = int(round(position.z))
		var search_key = Vector3(x, 0, z)
		
		print("Searching for key: ", search_key)
		
		var proc_tile = world_gen.procedural_tiles.get(search_key)
		
		if proc_tile:
			print("✓ FOUND ProceduralTile!")
			return proc_tile as ProceduralTile
		else:
			print("✗ NOT found!")
			return null
	
	print("No collider found!")
	return null

## Checks if the pawn is alive
##
## @return: Whether the pawn's current health is above 0
func is_alive() -> bool:
	return stats.curr_health > 0


## Checks if the pawn can move
##
## @return: Whether the pawn can move and is alive
func can_pawn_move() -> bool:
	return res.can_move and is_alive()


## Checks if the pawn can attack
##
## @return: Whether the pawn can attack and is alive
func can_pawn_attack() -> bool:
	return res.can_attack and is_alive()


## Checks if the pawn can perform any action
##
## @return: Whether the pawn can move or attack, and is alive
func can_act() -> bool:
	return (res.can_move or res.can_attack) and is_alive()


## Resets the pawn's turn state
func reset_turn() -> void:
	res.reset_turn()


## Ends the pawn's turn
func end_pawn_turn() -> void:
	res.end_pawn_turn()


## Initiates an attack on a target pawn
##
## @param target_pawn: The TacticsPawn to attack
## @param delta: Time elapsed since the last frame
## @return: Whether the attack was successful
func attack_target_pawn(target_pawn: TacticsPawn, delta: float) -> bool:
	return serv.attack_target_pawn(self, target_pawn, delta)


## Moves the pawn along its designated path
##
## @param delta: Time elapsed since the last frame
func move_along_path(delta: float) -> void:
	serv.movement.move_along_path(self, delta)
