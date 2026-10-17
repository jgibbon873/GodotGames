extends Node

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var seed_set: bool = false

func _ready() -> void:
	if not seed_set:
		rng.randomize()

func randf_range(minimum: float, maximum: float) -> float:
	return rng.randf_range(minimum, maximum)

func randi_range(minimum: int, maximum: int) -> int:
	return rng.randi_range(minimum, maximum)

func roll(sides: int) -> int:
	return rng.randi_range(1, sides)

func set_seed(global_seed: int) -> void:
	rng.seed = global_seed
	seed_set = true
