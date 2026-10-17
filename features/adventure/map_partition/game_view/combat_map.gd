class_name CombatMap
extends TileMapLayer

#Listeners: EnvironmentNode - connected on GameView in environment_node.initialize
signal move_completed(character: Character)

var pathfinder: WalkPathfinder = WalkPathfinder.new()
var terrain_key: Dictionary[EnumService.Terrain, Vector2i] = {
	EnumService.Terrain.WALL: Vector2i(0, 0),
	EnumService.Terrain.FLOOR: Vector2i(0, 1),
	EnumService.Terrain.LADDER: Vector2i(0, 2)
}

func _ready() -> void:
	EventBus.character_died.connect(_on_character_died)
	EventBus.command_routed.connect(_on_command_routed)

func place_node(node: Node, cell: Vector2i) -> void:
	if node is Character:
		if not pathfinder.has_cell(cell):
			push_error("CombatMap: %s → %s — no legal standing cell" % [(node as Character).display_name, cell])
			return
		var from_cell: Vector2i = node.cell()
		pathfinder.occupancy.move(from_cell, cell, node, (node as Character).team)
	node.position = map_to_local(cell)

func reachable_cells(character: Character) -> Array[Vector2i]:
	return pathfinder.get_reachable_cells(character.cell(), character.movement_remaining, character.team)

#region Set-Up Functions
func apply_layout(layout: MapResource) -> void:
	if not get_used_cells().is_empty():
		push_error("CombatMap: scene contains baked cells — a fresh map must be empty")
		return
	if not layout or layout.map_specification.is_empty():
		push_error("CombatMap: received a null or empty map layout")
		return
	for cell: Vector2i in layout.map_specification:
		var terrain: EnumService.Terrain = layout.map_specification[cell]
		set_cell(cell, 0, terrain_key[terrain], 0)
	pathfinder.build_from_tile_map_layer(self)

func place_starting_characters(characters: Array[Node], width: int, left: bool = true) -> void:
	for i: int in range(characters.size()):
		var x_size: int = width
		var character: Character = characters[i]
		var cell: Vector2i = Vector2i(0, 4) if left else Vector2i(x_size - 1 - (i * 1), 4)
		place_node(character, cell)
#endregion

#region ActionCommand Functions
func _on_command_routed(command: ActionCommand) -> void:
	if not command.actor:
		push_warning("CombatMap: command with null actor")
		return
	if command.target_cell == TileMapService.INVALID_CELL:
		push_warning("CombatMap: %s passed command with INVALID_CELL" % command.actor.display_name)
		return
	#CellMarker name is set as a constant on InputHandler script.
	if not is_instance_valid(command.target_node) or command.target_node.name == InputHandler.CELL_MARKER_NAME:
		_handle_move_command(command as ActionCommand)
	else:
		_handle_action_command(command as ActionCommand)

func _handle_move_command(command: ActionCommand) -> void:
	var actor: Character = command.actor
	var actor_cell: Vector2i = actor.cell()
	var target_cell: Vector2i = command.target_cell
	var path: Array[Vector2i] = pathfinder.find_cell_path(actor_cell, target_cell, actor.team)
	if path.is_empty() or not actor.spend_movement_points(path.size() - 1):
		return
	place_node(actor, target_cell)
	move_completed.emit(actor)
	
func _handle_action_command(command: ActionCommand) -> void:
	if command.action_resource == null:
		push_warning("CombatMap: command with null command.action_resource")
		return
	var actor: Character = command.actor
	var target_node: Character = command.target_node as Character
	if not target_node:
		return
	command.distance = WalkPathfinder.cell_distance(actor.cell(), target_node.cell())
	if command.distance > command.action_resource.cell_range:
		return
	var result: ActionResult = ActionResult.new()
	actor.execute_action(command, result)
	target_node.health_component.adjust_health(result)
#endregion

func _on_character_died(character: Character) -> void:
	var cell: Vector2i = character.cell()
	pathfinder.occupancy.leave(cell, character)
