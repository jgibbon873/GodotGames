class_name MapGenerator
extends RefCounted

func build_layout() -> MapResource:
	var map: MapResource = MapResource.new()
	map.map_size = Vector2i(18, 10)
	layout_floor(map)
	return map

func layout_floor(map: MapResource) -> void:
	for y: int in map.map_size.y:
		if y < 5:
			for x: int in map.map_size.x:
				map.map_specification[Vector2i(x, y)] = EnumService.Terrain.WALL
		
		if y == 5:
			for x: int in map.map_size.x:
				map.map_specification[Vector2i(x, y)] = EnumService.Terrain.FLOOR
