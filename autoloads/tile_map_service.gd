#Grid vocabulary conventions:
#
#Three distinct concepts, three terms — never interchange them:
#1.cell — a grid coordinate (Vector2i). An abstract square position; may be empty. Used by pathfinding, occupancy, and every coordinate-typed parameter and local.
#         Examples: cell_at(), target_cell, origin_cell, hovered_cell, cell_range.
#2.tile — the thing placed in a cell: a TileSet source, atlas coords, custom data, rendering. Belongs to the TileMapLayer/TileSet layer.
#         Examples: set_cell(), get_cell_tile_data(), default_tile_source_id, default_tile_atlas_coords, _is_tile_passable(), _is_tile_solid().
#3.position — a world-space Vector2 (pixels). Examples: node.position, position_to_cell_center().
#
#Rule of thumb: a Vector2i is a cell; a Vector2 is a position; a tile is the art/data placed in a cell — never a coordinate. A cell can be empty, so "cell" and "tile" are not interchangeable.
#
#Boundaries in this project: TileMapService is the canonical converter between positions and cells (cell_at, position_to_cell_center).
#                            WalkPathfinder, OccupancyGrid, and EqualStepAStar2D operate purely in cells. Measurements expressed in grid units (e.g. cell_range) count cells.
#
#Deliberate exceptions: Godot API names (set_cell, get_used_cells, TileMapLayer) and genuine tile concerns (default_tile_source_id, atlas coords) keep their terms.
#                       Renaming an @export (like cell_range) requires updating the stored value in every .tres that uses it — property names are serialized.
extends Node

const INVALID_CELL: Vector2i = Vector2i(-999, -999)

var _tile_map: TileMapLayer = null

func set_tile_map(tile_map: TileMapLayer) -> void:
	_tile_map = tile_map

func clear_tile_map() -> void:
	_tile_map = null

func has_tile_map() -> bool:
	return is_instance_valid(_tile_map) and _tile_map.tile_set != null

func position_to_cell_center(world_pos: Vector2) -> Vector2:
	if not has_tile_map():
		push_warning("TileMapService: No valid TileMapLayer set")
		return Vector2.INF
	var cell: Vector2i = _tile_map.local_to_map(_tile_map.to_local(world_pos))
	return _tile_map.to_global(_tile_map.map_to_local(cell))

func cell_at(world_pos: Vector2) -> Vector2i:
	if not has_tile_map():
		push_warning("TileMapService: No valid TileMapLayer set")
		return INVALID_CELL
	return _tile_map.local_to_map(_tile_map.to_local(world_pos))
