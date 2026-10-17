class_name EnemyAI
extends Node

#Listeners: Adventure
signal enemy_command(nodes: Array[Node], cell: Vector2i, actor: Character, target: Node)

var combat_map: CombatMap = null
var turn_manager: TurnManager = null

func _ready() -> void:
	EventBus.acting_character_changed.connect(_handle_enemy_turn, CONNECT_DEFERRED)

func initialize(tm: TurnManager, cm: CombatMap) -> void:
	turn_manager = tm
	combat_map = cm

func _handle_enemy_turn(enemy: Character) -> void:
	if not is_instance_valid(enemy) or not is_instance_valid(turn_manager):
		return
	if enemy.team == EnumService.Team.ENEMIES:
		match turn_manager.get_mode():
			EnumService.Mode.COMBAT:
				_execute_combat_turn(enemy)
			EnumService.Mode.EXPLORATION:
				_execute_exploration_turn(enemy)

func _execute_exploration_turn(enemy: Character) -> void:
	_move_enemy(enemy)
	turn_manager.process_next_exploration_enemy()

func _move_enemy(enemy: Character) -> void:
	var cells: Array[Vector2i] = _get_legal_movement_cells(enemy)
	if cells.is_empty():
		return
	var target_cell: Vector2i = cells[0]
	for cell: Vector2i in cells:
		if cell.x < target_cell.x:
			target_cell = cell
	enemy_command.emit([] as Array[Node], target_cell, enemy, null)

func _get_legal_movement_cells(enemy: Character) -> Array[Vector2i]:
	if not is_instance_valid(combat_map):
		return []
	return combat_map.reachable_cells(enemy)

#region CombatTurn Functions
func _execute_combat_turn(enemy: Character) -> void:
	var target: Character = _pick_target(enemy)
	if target == null:
		EventBus.action_ended.emit()
		return
	if not _try_attack(enemy, target):
		_move_toward(enemy, target)
		_try_attack(enemy, target)
	# Always terminate the turn. Emit LAST: this synchronously re-enters
	# TurnManager, which may end the encounter (freeing turn_manager).
	EventBus.action_ended.emit()

## Attack if enemy has an action usable at current distance. Returns true if
## an attack command was dispatched.
func _try_attack(enemy: Character, target: Character) -> bool:
	var action: ActionResource = _pick_action(enemy, target)
	if action == null:
		return false
	enemy.action_set = action   # AI's "button click" — mirrors ActionBar
	enemy_command.emit([] as Array[Node], target.cell(), enemy, target)
	return true

## Nearest living hero by cell distance. Returns null if no heroes remain.
func _pick_target(enemy: Character) -> Character:
	var heroes: Array[Character] = turn_manager.get_team_characters(EnumService.Team.HEROES)
	var nearest: Character = null
	var nearest_distance: int = 0
	for hero: Character in heroes:
		var distance: int = WalkPathfinder.cell_distance(enemy.cell(), hero.cell())
		if nearest == null or distance < nearest_distance:
			nearest = hero
			nearest_distance = distance
	return nearest

## Strongest attack whose cell_range covers the current distance to target.
func _pick_action(enemy: Character, target: Character) -> ActionResource:
	var distance: int = WalkPathfinder.cell_distance(enemy.cell(), target.cell())
	var best: ActionResource = null
	var best_strength: int = -1
	for action: ActionResource in enemy.actions:
		if not _is_attack(action.action_type):
			continue
		if action.cell_range < distance:
			continue
		if action.strength > best_strength:
			best = action
			best_strength = action.strength
	return best

func _is_attack(action_type: EnumService.ActionType) -> bool:
	return action_type == EnumService.ActionType.ARCANE_ATTACK \
		or action_type == EnumService.ActionType.MELEE_ATTACK \
		or action_type == EnumService.ActionType.RANGE_ATTACK

## Move to the reachable cell minimizing distance to target.
func _move_toward(enemy: Character, target: Character) -> void:
	var cells: Array[Vector2i] = _get_legal_movement_cells(enemy)
	if cells.is_empty():
		return
	var best_cell: Vector2i = cells[0]
	var best_distance: int = WalkPathfinder.cell_distance(best_cell, target.cell())
	for cell: Vector2i in cells:
		var distance: int = WalkPathfinder.cell_distance(cell, target.cell())
		if distance < best_distance:
			best_cell = cell
			best_distance = distance
	enemy_command.emit([] as Array[Node], best_cell, enemy, null)
#endregion
