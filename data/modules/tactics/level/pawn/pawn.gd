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
var expertise: String:
	get:
		return stats.expertise
	set(value):
		stats.expertise = value # Allow setting if needed, or remove setter if read-only
## Reference to the TacticsPawnSprite node, handling visual representation
@onready var character: TacticsPawnSprite = $Character
## RayCast3D to detect the tile the pawn is currently on
@onready var tile_detector: RayCast3D = $Tile


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
	if DebugLog.debug_enabled:
		print("Pawn Position: ", position, " | Tile: ", tile)
	serv.process(self, delta)


## Centers the pawn on its current tile
##
## @return: Whether the centering operation was successful
func center() -> bool: # This method is called by TacticsOpponentService.is_pawn_configured
	return character.adjust_to_center(self)


## Shows or hides the pawn's stats UI
##
## @param v: Whether to show (true) or hide (false) the stats
func show_pawn_stats(v: bool) -> void: # This method is called by TacticsPawnService.setup
	$Character/CharacterUI.visible = v


## Gets the tile the pawn is currently on
##
## @return: The BaseTile the pawn is on
func get_tile() -> BaseTile: # This method is called by TacticsOpponentService.chase_nearest_enemy, TacticsOpponentService.choose_pawn_to_attack
	var collider = tile_detector.get_collider()
	var collision_point = tile_detector.get_collision_point()
	
	if DebugLog.debug_enabled:
		print("\n--- GET_TILE DEBUG ---")
		print("Pawn raw position: ", position)
		print("RayCast collision point: ", collision_point)
	
	if collider is TacticsTile:
		if DebugLog.debug_enabled: print("Found TacticsTile!")
		return collider as TacticsTile
	elif collider is StaticBody3D:
		if not WorldGeneration.instance:
			if DebugLog.debug_enabled: print("ERROR: WorldGeneration instance not found!")
			return null
		
		var world_gen = WorldGeneration.instance
		if DebugLog.debug_enabled: print("WorldGeneration found! Dictionary has ", world_gen.procedural_tiles.size(), " tiles")
		
		# Use the collision point's coordinates for a more accurate lookup, especially for Y-level
		var x = int(round(position.x))
		var y = int(round(collision_point.y)) # Use collision point's Y for multi-level maps
		var z = int(round(position.z)) 
		var search_key = Vector3(x, y, z)
		
		if DebugLog.debug_enabled: print("Searching for key: ", search_key)
		
		var proc_tile = world_gen.procedural_tiles.get(search_key)
		
		if proc_tile:
			if DebugLog.debug_enabled: print("✓ FOUND ProceduralTile!")
			return proc_tile as ProceduralTile
		else:
			if DebugLog.debug_enabled: print("✗ NOT found!")
			return null
	
	if DebugLog.debug_enabled: print("No collider found!")
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
