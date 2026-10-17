class_name EnemyPortrait
extends Portrait

#Super() is not called to prevent unwanted signal connection.
func _ready() -> void:
	if character:
		character_activate_button.visible = false
		character.health_changed.connect(func(_c: int, _m: int) -> void: pass) #Placeholder
		EventBus.character_died.connect(func(c: Character) -> void: if c == character: queue_free())
	else:
		push_warning("Portrait: character is null — signals not connected")
