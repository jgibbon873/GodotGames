class_name EnemiesContainer
extends HBoxContainer

const ENEMY_PORTRAIT: PackedScene = preload("uid://g2o126jq2tp0")

func set_up_portrait(character: Character) -> void:
	var portrait: EnemyPortrait = ENEMY_PORTRAIT.instantiate()
	portrait.character = character
	portrait.texture = character.character_type.portrait
	add_child(portrait)
