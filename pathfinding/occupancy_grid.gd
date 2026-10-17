class_name OccupancyGrid
extends RefCounted

#_cells: key-Vector2i, value-Array[Dictionary {"unit": Object, "team": EnumService.Team}]. 
var _cells: Dictionary[Vector2i, Array] = {}

func clear() -> void:
	_cells.clear()

func enter(cell: Vector2i, unit: Object, team: EnumService.Team) -> void:
	if not _cells.has(cell):
		_cells[cell] = []
	var occupants: Array = _cells[cell]
	for occupant: Dictionary in occupants:
		if occupant.unit == unit:
			occupant.team = team
			return
	occupants.append({ "unit": unit, "team": team })

func leave(cell: Vector2i, unit: Object) -> void:
	if not _cells.has(cell):
		return
	var occupants: Array = _cells[cell]
	for i: int in range(occupants.size() - 1, -1, -1):
		if occupants[i].unit == unit:
			occupants.remove_at(i)
	if occupants.is_empty():
		_cells.erase(cell)

func move(from_cell: Vector2i, to_cell: Vector2i, unit: Object, team: EnumService.Team) -> void:
	if from_cell != to_cell:
		leave(from_cell, unit)
	enter(to_cell, unit, team)

func get_occupants(cell: Vector2i) -> Array[Dictionary]:
	if not _cells.has(cell):
		return []
	return _cells[cell]

func is_blocked_for_team(cell: Vector2i, mover_team: EnumService.Team) -> bool:
	if not _cells.has(cell):
		return false
	for occupant: Dictionary in _cells[cell]:
		if occupant.team != mover_team:
			return true
	return false

func get_occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for key: Vector2i in _cells:
		cells.append(key)
	return cells
