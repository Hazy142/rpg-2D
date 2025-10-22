class_name TacticsPawnService
extends RefCounted

# --- Animation ---
func setup_animation(pawn: TacticsPawn) -> void:
	pawn.get_node("Character").setup(pawn.stats, pawn.expertise)

func start_animator(pawn: TacticsPawn) -> void:
	pawn.get_node("Character").start_animator(pawn.res.move_direction, pawn.res.is_jumping)

# --- Combat ---
func attack_target_pawn(pawn: TacticsPawn, target_pawn: TacticsPawn, delta: float) -> bool:
	look_at_direction(pawn, target_pawn.global_position - pawn.global_position)

	if pawn.res.can_attack and pawn.res.wait_delay > TacticsPawnResource.MIN_TIME_FOR_ATTACK / 4.0:
		target_pawn.stats.apply_to_curr_health(-pawn.stats.attack_power)

		if DebugLog.debug_enabled:
			print_rich("[color=pink]Attacked ", target_pawn, " for ", pawn.stats.attack_power, " damage.[/color]")

		pawn.res.set_attacking(false)

	if pawn.res.wait_delay < TacticsPawnResource.MIN_TIME_FOR_ATTACK:
		pawn.res.wait_delay += delta
		return false

	pawn.res.wait_delay = 0.0
	return true

# --- HUD ---
func update_character_health(pawn: TacticsPawn) -> void:
	var _health_label: Label3D = pawn.get_node("Character/CharacterUI/HealthLabel")
	_health_label.text = str(pawn.stats.curr_health) + "/" + str(pawn.stats.max_health)

func tint_when_unable_to_act(pawn: TacticsPawn) -> void:
	var _char_node: TacticsPawnSprite = pawn.get_node("Character")
	_char_node.modulate = Color(0.5, 0.5, 0.5) if not pawn.can_act() else Color(1, 1, 1)

# --- Movement ---
func look_at_direction(pawn: TacticsPawn, dir: Vector3) -> void:
	var _fixed_dir: Vector3 = dir * (Vector3(1, 0, 0) if abs(dir.x) > abs(dir.z) else Vector3(0, 0, 1))
	var _angle: float = Vector3.FORWARD.signed_angle_to(_fixed_dir.normalized(), Vector3.UP) + PI
	var _new_rot: Vector3 = Vector3.UP * _angle
	pawn.set_rotation(_new_rot)

func move_along_path(pawn: TacticsPawn, delta: float) -> void:
	if pawn.res.pathfinding_tilestack.is_empty() or not pawn.res.can_move:
		return
	
	start_movement(pawn)
	
	if pawn.res.move_direction.length() > 0.5:
		perform_movement(pawn, delta)
		
		var _first_tile_in_stack: Vector3 = pawn.res.pathfinding_tilestack.front()
		if pawn.global_position.distance_to(_first_tile_in_stack) >= 0.15:
			return
	
	pawn.res.pathfinding_tilestack.pop_front()
	reset_movement_state(pawn)
	check_movement_completion(pawn)

func start_movement(pawn: TacticsPawn) -> void:
	pawn.res.set_moving(true)
	if pawn.res.move_direction == Vector3.ZERO:
		pawn.res.move_direction = pawn.res.pathfinding_tilestack.front() - pawn.global_position

func perform_movement(pawn: TacticsPawn, delta: float) -> void:
	look_at_direction(pawn, pawn.res.move_direction)
	var _p_velocity: Vector3 = calculate_velocity(pawn, delta)
	var _curr_speed: float = calculate_speed(pawn)
	
	pawn.set_velocity(_p_velocity * _curr_speed)
	pawn.set_up_direction(Vector3.UP)
	pawn.move_and_slide()

func calculate_velocity(pawn: TacticsPawn, delta: float) -> Vector3:
	var _p_velocity: Vector3 = pawn.res.move_direction.normalized()
	
	if pawn.res.move_direction.y < -TacticsPawnResource.MIN_HEIGHT_TO_JUMP:
		var _first_tile_in_stack : Vector3 = pawn.res.pathfinding_tilestack.front()
		if CalcVector.distance_without_y(_first_tile_in_stack, pawn.global_position) <= 0.2:
			pawn.res.gravity += Vector3.DOWN * delta * TacticsPawnResource.GRAVITY_STRENGTH
			_p_velocity = (pawn.res.pathfinding_tilestack.front() - pawn.global_position).normalized() + pawn.res.gravity
		else:
			_p_velocity = CalcVector.remove_y(pawn.res.move_direction).normalized()
	
	return _p_velocity

func calculate_speed(pawn: TacticsPawn) -> float:
	var _curr_speed: float = pawn.res.walk_speed
	
	if pawn.res.move_direction.y > TacticsPawnResource.MIN_HEIGHT_TO_JUMP:
		_curr_speed = clamp(abs(pawn.res.move_direction.y) * 2.3, 3, INF)
		pawn.res.is_jumping = true
	
	return _curr_speed

func reset_movement_state(pawn: TacticsPawn) -> void:
	pawn.res.move_direction = Vector3.ZERO
	pawn.res.is_jumping = false
	pawn.res.gravity = Vector3.ZERO
	pawn.res.can_move = pawn.res.pathfinding_tilestack.size() > 0

func check_movement_completion(pawn: TacticsPawn) -> void:
	if not pawn.res.can_move:
		pawn.res.set_moving(false)
		pawn.character.adjust_to_center(pawn)
