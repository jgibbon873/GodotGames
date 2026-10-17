class_name EqualStepAStar2D
extends AStar2D

func _compute_cost(_from_id: int, _to_id: int) -> float:
	return 1.0

func _estimate_cost(from_id: int, to_id: int) -> float:
	var from_pos: Vector2 = get_point_position(from_id)
	var to_pos: Vector2 = get_point_position(to_id)
	return maxf(absf(from_pos.x - to_pos.x), absf(from_pos.y - to_pos.y))
