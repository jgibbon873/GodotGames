class_name WalkPathfinder
extends RefCounted

const PASSABLE_DATA: String = "passable"
const SOLID_DATA: String = "solid"
# Godot y-down: the support cell is +1 on y
const BELOW: Vector2i = Vector2i(0, 1) 

const _ORTHO: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]
const _DIAGONAL: Array[Vector2i] = [
	Vector2i(1, 1),
	Vector2i(1, -1),
	Vector2i(-1, 1),
	Vector2i(-1, -1),
]

var astar: EqualStepAStar2D = EqualStepAStar2D.new()
var occupancy: OccupancyGrid = OccupancyGrid.new()

var _cell_to_id: Dictionary[Vector2i, int] = {}
var _id_to_cell: Dictionary[int, Vector2i] = {}
var _next_id: int = 1

static func cell_distance(a: Vector2i, b: Vector2i) -> int:
	var dx: int = abs(b.x - a.x)
	var dy: int = abs(b.y - a.y)
	return max(dx, dy)

func build_from_tile_map_layer(layer: TileMapLayer) -> void:
	clear_graph()
	if layer == null:
		return
	var walkable_cells: Array[Vector2i] = []
	for cell: Vector2i in layer.get_used_cells():
		if _is_tile_passable(layer, cell) and _is_tile_solid(layer, cell + BELOW):
			walkable_cells.append(cell)
			_add_cell(cell)
	for cell: Vector2i in walkable_cells:
		_connect_walk_edges(cell)
	if walkable_cells.is_empty() and not layer.get_used_cells().is_empty():
		push_error("WalkPathfinder: no legal standing cells — check the passable/solid data layers")

func clear_graph() -> void:
	astar.clear()
	_cell_to_id.clear()
	_id_to_cell.clear()
	_next_id = 1

func has_cell(cell: Vector2i) -> bool:
	return _cell_to_id.has(cell)

func find_cell_path(from_cell: Vector2i, to_cell: Vector2i, mover_team: EnumService.Team) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not _cell_to_id.has(from_cell) or not _cell_to_id.has(to_cell):
		return result

	var from_id: int = _cell_to_id[from_cell]
	var to_id: int = _cell_to_id[to_cell]
	var disabled: Array[int] = _disable_blocked_points(mover_team, from_id)

	var id_path: PackedInt64Array = astar.get_id_path(from_id, to_id)
	_restore_points(disabled)

	for id: int in id_path:
		result.append(_id_to_cell[int(id)])
	return result

func is_reachable(from_cell: Vector2i, to_cell: Vector2i, mover_team: EnumService.Team) -> bool:
	return not find_cell_path(from_cell, to_cell, mover_team).is_empty()

func _is_tile_passable(layer: TileMapLayer, cell: Vector2i) -> bool:
	var tile_data: TileData = layer.get_cell_tile_data(cell)
	if tile_data == null:
		return false
	return tile_data.get_custom_data(PASSABLE_DATA) == true

func _is_tile_solid(layer: TileMapLayer, cell: Vector2i) -> bool:
	var tile_data: TileData = layer.get_cell_tile_data(cell)
	if tile_data == null:
		return false
	return tile_data.get_custom_data(SOLID_DATA) == true

func _add_cell(cell: Vector2i) -> int:
	if _cell_to_id.has(cell):
		return _cell_to_id[cell]
	var id:int = _next_id
	_next_id += 1
	_cell_to_id[cell] = id
	_id_to_cell[id] = cell
	astar.add_point(id, Vector2(cell))
	return id

func _connect_walk_edges(cell: Vector2i) -> void:
	var from_id: int = _cell_to_id[cell]

	for offset: Vector2i in _ORTHO:
		var neighbor: Vector2i = cell + offset
		if not _cell_to_id.has(neighbor):
			continue
		if neighbor.x > cell.x or (neighbor.x == cell.x and neighbor.y > cell.y):
			astar.connect_points(from_id, _cell_to_id[neighbor] as int, true)

	for offset: Vector2i in _DIAGONAL:
		var neighbor: Vector2i = cell + offset
		if not _cell_to_id.has(neighbor):
			continue
		if not (neighbor.x > cell.x or (neighbor.x == cell.x and neighbor.y > cell.y)):
			continue
		if _can_use_diagonal(cell, offset):
			astar.connect_points(from_id, _cell_to_id[neighbor] as int, true)

func _can_use_diagonal(cell: Vector2i, offset: Vector2i) -> bool:
	var flank_a: Vector2i = Vector2i(cell.x + offset.x, cell.y)
	var flank_b: Vector2i = Vector2i(cell.x, cell.y + offset.y)
	var blocked_a: bool = not _cell_to_id.has(flank_a)
	var blocked_b: bool = not _cell_to_id.has(flank_b)
	return not (blocked_a and blocked_b)

func _disable_blocked_points(mover_team: EnumService.Team, from_id: int) -> Array[int]:
	var disabled: Array[int] = []
	if occupancy == null:
		return disabled
	for cell: Vector2i in occupancy.get_occupied_cells():
		if not _cell_to_id.has(cell):
			continue
		if not occupancy.is_blocked_for_team(cell, mover_team):
			continue
		var id: int = _cell_to_id[cell]
		if id == from_id:
			continue
		if astar.is_point_disabled(id):
			continue
		astar.set_point_disabled(id, true)
		disabled.append(id)
	return disabled

func _restore_points(disabled: Array[int]) -> void:
	for id: int in disabled:
		astar.set_point_disabled(id, false)

func get_reachable_cells(from_cell: Vector2i, max_steps: int, mover_team: EnumService.Team) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not _cell_to_id.has(from_cell):
		return result
	var visited: Dictionary[Vector2i, int] = {from_cell: 0}   # cell -> steps used
	var frontier: Array[Vector2i] = [from_cell]
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_front()   # FIFO = breadth-first
		if visited[cell] >= max_steps:
			continue
		for id: int in astar.get_point_connections(_cell_to_id[cell] as int):
			var neighbor: Vector2i = _id_to_cell[id]
			if visited.has(neighbor):
				continue
			if occupancy.is_blocked_for_team(neighbor, mover_team):
				continue
			visited[neighbor] = visited[cell] + 1
			result.append(neighbor)
			frontier.append(neighbor)
	return result
