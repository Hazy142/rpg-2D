class_name TacticsArenaService
extends RefCounted

const TILE_SERVICE = preload("res://data/models/world/combat/arena/tile_service/service.gd")

var res: TacticsArenaResource

func _init(_res: TacticsArenaResource) -> void:
	res = _res

func setup(arena: TacticsArena) -> void:
	if not res:
		push_error("TacticsArena needs an ArenaResource from /data/models/world/combat/arena/")
	else:
		res.connect("called_reset_all_tile_markers", arena.reset_all_tile_markers)
		res.connect("called_get_pathfinding_tilestack", arena.get_pathfinding_tilestack)
		res.connect("called_mark_hover_tile", arena.mark_hover_tile)

## Reset markers for all tiles in the arena
func reset_all_tile_markers(arena: TacticsArena) -> void:
	var tiles_node = arena.get_node("Tiles")
	if tiles_node:
		for _t in tiles_node.get_children():
			# ===== Erlaubt TacticsTile ODER ProceduralTile =====
			if _t is TacticsTile:
				_t.reset_markers()
			elif _t is ProceduralTile:
				# ProceduralTiles haben keine Marker
				pass

## Configure tiles in the arena
func configure_tiles(arena: TacticsArena) -> void:
	var _tiles: Node3D = arena.get_node_or_null("Tiles") as Node3D
	if _tiles:
		_tiles.visible = false
		TILE_SERVICE.tiles_into_staticbodies(_tiles)

func process_surrounding_tiles(root_tile: Node, height: float, allies_on_map: Array = []) -> void:
	# FIX: Behandle alle BaseTile-Typen polymorphisch und entferne die explizite Exklusion.
	if not root_tile:
		return

	var _tiles_process_q: Array = [root_tile]

	while not _tiles_process_q.is_empty():
		var _curr_tile = _tiles_process_q.pop_front()

		# ProceduralTiles haben keine vordefinierten Nachbarn, daher wird die Schleife für sie leer sein.
		# Das ist korrektes polymorphes Verhalten.
		if not _curr_tile.has_method("get_neighbors"):
			continue

		var _add_to_tiles_list: Callable = func(_neighbor: TacticsTile) -> void:
			_neighbor.pf_root = _curr_tile
			_neighbor.pf_distance = _curr_tile.pf_distance + 1
			_tiles_process_q.push_back(_neighbor)

		for _neighbor in _curr_tile.get_neighbors(height):
			if not _neighbor.pf_root and _neighbor != root_tile:
				if not _neighbor.is_taken():
					_add_to_tiles_list.call(_neighbor)
				elif allies_on_map.size() > 0:
					if not (_neighbor.get_tile_occupier() in allies_on_map):
						_add_to_tiles_list.call(_neighbor)

## Get the pathfinding tilestack to a target tile
func get_pathfinding_tilestack(to: Node) -> Array:
	var _path_tiles_stack: Array = []
	
	while to:
		if to is TacticsTile:
			to.hover = true
		_path_tiles_stack.push_front(to.global_position)
		to = to.pf_root if to.has_method("pf_root") else null
		
	res.path_tiles_stack = _path_tiles_stack
	return _path_tiles_stack

## Get the nearest tile adjacent to a target pawn
func get_nearest_target_adjacent_tile(pawn: TacticsPawn, target_pawns: Array) -> Node:
	var _nearest_target: Node = null
	
	for _p: TacticsPawn in target_pawns:
		if _p.stats.curr_health <= 0: continue
		var pawn_tile = _p.get_tile()
		if pawn_tile and pawn_tile.has_method("get_neighbors"):
			for _n in pawn_tile.get_neighbors(pawn.stats.jump):
				if _n is TacticsTile:
					if not _nearest_target or _n.pf_distance < _nearest_target.pf_distance:
						if _n.pf_distance > 0 and not _n.is_taken():
							_nearest_target = _n
	
	while _nearest_target and _nearest_target.has_method("reachable") and not _nearest_target.reachable: 
		_nearest_target = _nearest_target.pf_root if _nearest_target.has_method("pf_root") else null
	
	if _nearest_target:
		return _nearest_target 
	else:
		DebugLog.debug_nospam("nearest_target", pawn)
		return pawn.get_tile()

## Get the weakest attackable pawn from an array of pawns
func get_weakest_attackable_pawn(pawn_arr: Array) -> TacticsPawn:
	var _weakest: TacticsPawn = null
	
	for _p: TacticsPawn in pawn_arr:
		var pawn_tile = _p.get_tile()
		if pawn_tile and pawn_tile.has_method("attackable"):
			if not _weakest or _p.stats.curr_health < _weakest.stats.curr_health:
				if _p.stats.curr_health > 0 and pawn_tile.attackable:
					_weakest = _p
	
	return _weakest

## Mark a tile as hovered and unmark others
func mark_hover_tile(arena: TacticsArena, tile: Node) -> void:
	var tiles_node = arena.get_node("Tiles")
	if tiles_node:
		for _t in tiles_node.get_children():
			if _t is TacticsTile:
				_t.hover = false
	
	if tile and tile is TacticsTile:
		tile.hover = true

## Mark reachable tiles within a certain distance from a root tile
func mark_reachable_tiles(arena: TacticsArena, root: Node, distance: float) -> void:
	var tiles_node = arena.get_node("Tiles")
	if tiles_node:
		for _t in tiles_node.get_children():
			if _t is TacticsTile:
				var _has_dist: bool = _t.pf_distance > 0
				var _reachable: bool = _t.pf_distance <= distance
				var _not_taken: bool = not _t.is_taken()
				var _is_root: bool = _t == root
				
				_t.reachable = (_has_dist and _reachable and _not_taken) or _is_root

## Mark attackable tiles within a certain distance from a root tile
func mark_attackable_tiles(arena: TacticsArena, root: Node, distance: float) -> void:
	var tiles_node = arena.get_node("Tiles")
	if tiles_node:
		for _t in tiles_node.get_children():
			if _t is TacticsTile:
				var _has_dist: bool = _t.pf_distance > 0
				var _reachable: bool = _t.pf_distance <= distance
				var _is_root: bool = _t == root
				
				_t.attackable = _has_dist and _reachable or _is_root
