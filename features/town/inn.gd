class_name Inn
extends TextureRect

const CHARACTER: PackedScene = preload("uid://kt4n7l7k8qxh")

#Listeners: Town
signal enter_town_square()

@onready var recruit_button: Button = %RecruitButton
@onready var town_square_button: Button = %TownSquareButton

func _ready() -> void:
	recruit_button.pressed.connect(func() -> void: spawn_hero())
	town_square_button.pressed.connect(enter_town_square.emit)
	spawn_hero()
	spawn_hero()

##Spawns a new hero and adds it to the pool.
func spawn_hero(character_type: CharacterResource = null) -> Character:
	var hero: Character = CHARACTER.instantiate() as Character
	var character: CharacterResource = character_type if character_type != null else preload("res://resources/character_resources/archer.tres")
	hero.character_resource = character
	hero.team = EnumService.Team.HEROES
	hero.visible = false
	add_child(hero)
	return hero
