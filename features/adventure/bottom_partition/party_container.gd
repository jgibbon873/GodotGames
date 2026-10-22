class_name PartyContainer
extends HBoxContainer

const HERO_PORTRAIT: PackedScene  = preload("uid://bsc4prmqm6yht")

func set_up_portrait(character: Character, turn_manager: TurnManager) -> void:
	var portrait: HeroPortrait = HERO_PORTRAIT.instantiate()
	portrait.character = character
	portrait.texture = character.character_resource.portrait
	portrait.turn_manager = turn_manager
	add_child(portrait)
