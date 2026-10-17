class_name GameView
extends SubViewport

const COMBAT_MAP: PackedScene = preload("uid://d3cfxjt8r661d")
const ENEMY_MANAGER: PackedScene = preload("uid://ckl86c7p1ccxy")
const TURN_MANAGER: PackedScene = preload("uid://dh4lc3g8lqevq")

#Listeners: Adventure, MapPartition
signal encounter_ended(victory: bool)
#Listeners: Adventure
signal portraits_setup(characters: Array[Character], turn_manager: TurnManager)

var combat_map: CombatMap = null
var enemy_manager: EnemyManager = null
var turn_manager: TurnManager = null
var _is_transitioning: bool = false

@onready var camera_focus: CameraFocus = %CameraFocus
@onready var enemy_ai: EnemyAI = %EnemyAI
@onready var game_camera: GameCamera = %GameCamera
@onready var input_handler: InputHandler = %InputHandler
@onready var environment_node: EnvironmentNode = %EnvironmentNode

func start_encounter(encounter: EncounterResource) -> void:
	if _is_transitioning:
		push_warning("GameView: start_encounter ignored – transition in progress")
		return
	_is_transitioning = true
	var heroes: Array[Node] = get_children().filter(func(c: Node) -> bool: return c is Character and (c as Character).team == EnumService.Team.HEROES)
	var enemies: Array[Node] = enemy_set_up(encounter.enemy_composition)
	
	combat_map_set_up(encounter.map_layout, heroes, enemies)
	
	turn_manager_set_up(heroes, enemies)
	await sizing_set_up()
	enemy_ai.initialize(turn_manager, combat_map)
	environment_node.initialize(turn_manager, combat_map)
	_is_transitioning = false
	turn_manager.change_mode(EnumService.Mode.EXPLORATION)

func enemy_set_up(enemy_composition: Dictionary) -> Array[Node]:
	enemy_manager = _clean_up(enemy_manager)
	enemy_manager = ENEMY_MANAGER.instantiate()
	add_child(enemy_manager)
	return enemy_manager.spawn_enemies_from_composition(enemy_composition)

func combat_map_set_up(map_layout: MapResource, heroes: Array[Node], enemies: Array[Node]) -> void:
	combat_map = _clean_up(combat_map)
	combat_map = COMBAT_MAP.instantiate()
	TileMapService.set_tile_map(combat_map)
	add_child(combat_map)
	input_handler.shape.size = Vector2(combat_map.tile_set.tile_size.x * 0.95, combat_map.tile_set.tile_size.y * 0.95)
	
	combat_map.apply_layout(map_layout)
	
	camera_focus.map_pixel_size = map_layout.map_size * combat_map.tile_set.tile_size
	combat_map.place_starting_characters(heroes, map_layout.map_size.x)
	combat_map.place_starting_characters(enemies, map_layout.map_size.x, false)

func turn_manager_set_up(heroes: Array[Node], enemies: Array[Node]) -> void:
	turn_manager = _clean_up(turn_manager)
	turn_manager = TURN_MANAGER.instantiate()
	add_child(turn_manager)
	turn_manager.heroes_won.connect(end_encounter)
	for character: Character in heroes + enemies:
		character.reparent(turn_manager)
	portraits_setup.emit(heroes + enemies, turn_manager)

func sizing_set_up() -> void:
	await get_tree().process_frame
	handle_input_locally = true
	size = get_parent().size
	game_camera.update_camera(size)
	camera_focus.update_focus(size)

func end_encounter(victory: bool) -> void:
	if _is_transitioning:
		push_warning("end_encounter ignored – transition in progress")
		return
	_is_transitioning = true 
	for hero: Character in turn_manager.get_children().filter(func(c: Node) -> bool: return c is Character and (c as Character).team == EnumService.Team.HEROES):
			if hero.get_parent() != self:
					if hero.get_parent():
						hero.reparent(self)
					else:
						self.add_child(hero)
	TileMapService.clear_tile_map()
	enemy_manager = _clean_up(enemy_manager)
	combat_map = _clean_up(combat_map)
	var guard_turn_manager: TurnManager = turn_manager
	turn_manager = _clean_up(turn_manager)
	await guard_turn_manager.tree_exited 
	_is_transitioning = false
	EventBus.acting_character_changed.emit(null)
	encounter_ended.emit(victory)

func _clean_up(stale_node: Node) -> Node:
	if is_instance_valid(stale_node):
		stale_node.queue_free()
	return null
