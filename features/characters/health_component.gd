class_name HealthComponent
extends Node

#Listeners: Character
signal died()
#Listeners: Character
signal health_changed(current: int, maximum: int)

var max_health: int = 100:
	set(value):
		max_health = max(1, value)
		current_health = min(current_health, max_health)
var current_health: int = max_health

func _ready() -> void:
	current_health = max_health 

func adjust_health(result: ActionResult) -> void:
	current_health -= result.health_adjust
	current_health = clampi(current_health, 0, max_health)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		died.emit()
