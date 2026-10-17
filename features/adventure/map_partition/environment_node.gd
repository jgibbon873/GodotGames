class_name EnvironmentNode
extends Node

var combat_map: CombatMap = null
var turn_manager: TurnManager = null

func initialize(tm: TurnManager, cm: CombatMap) -> void:
	turn_manager = tm
	combat_map = cm
	combat_map.move_completed.connect(_on_move_completed)

func _on_move_completed(character: Character) -> void:
	if not is_instance_valid(turn_manager):
		return
	var origin_cell: Vector2i = character.cell()
	var opponents: Array[Character] = []
	var hero: bool = character.team == EnumService.Team.HEROES
	if hero:
		opponents.append_array(turn_manager.get_team_characters(EnumService.Team.ENEMIES))
	else:
		opponents.append_array(turn_manager.get_team_characters(EnumService.Team.HEROES))
	for opponent: Character in opponents:
		var distance: int = WalkPathfinder.cell_distance(origin_cell, opponent.cell())
		if hero:
			if distance <= character.character_type.vision_range:
				opponent.visible = true
			if distance <= opponent.character_type.vision_range:
				opponent.alerted.append(character)
		else:
			if distance <= character.character_type.vision_range:
				character.alerted.append(opponent)
			if distance <= opponent.character_type.vision_range:
				character.visible = true
	_check_combat_start(character)

func _check_combat_start(character: Character) -> void:
	if turn_manager.current_mode != EnumService.Mode.EXPLORATION or !character.visible:
		return
	var character_cell: Vector2i = character.cell()
	var opponents: Array[Character] = turn_manager.get_team_characters(EnumService.Team.HEROES) if character.team == EnumService.Team.ENEMIES else\
									  turn_manager.get_team_characters(EnumService.Team.ENEMIES).filter(func(c: Character) -> bool: return c.alerted.has(character))
	for opponent: Character in opponents:
		var opponent_cell: Vector2i = opponent.cell()
		var distance: int = WalkPathfinder.cell_distance(character_cell, opponent_cell)
		if distance <= opponent.character_type.vision_range and distance <= character.character_type.vision_range:
			turn_manager.change_mode(EnumService.Mode.COMBAT)

#Deadcode, kept for later development.
#func scan_environment(character: Character) -> ScanResult:
	#var result: ScanResult = ScanResult.new()
	#var origin_cell: Vector2i = character.cell()
	#var vision: int = character.character_type.vision_range
	#for other: Character in turn_manager.get_characters().filter(func(c: Node) -> bool: return c != character):
		#if WalkPathfinder.cell_distance(origin_cell, other.cell()) <= vision:
			#result.characters.append(other)
	#for entity: Node in combat_map.get_children():
		#if entity is Node2D:
			#var entity_cell: Vector2i = TileMapService.cell_at(entity.global_position as Vector2) #Editor throws need Vector2/Variant provided if no cast to Vector2?
			#if WalkPathfinder.cell_distance(origin_cell, entity_cell) <= vision:
					#result.entities.append(entity)
	#return result
