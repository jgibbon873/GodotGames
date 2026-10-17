class_name MapPartition
extends SubViewportContainer

#Listeners: Adventure
signal adventure_ended()

var adventure: AdventureResource = null
var inn: Inn = null

@onready var game_view: GameView = %GameView

func _ready() -> void:
	game_view.encounter_ended.connect(end_encounter)

# Called by Town to begin a new adventure
func start_adventure(adventure_resource: AdventureResource, heroes: Array[Node]) -> void:
	if not adventure_resource:
		push_error("MapPartition: No AdventureResource provided")
		return
	adventure = adventure_resource
	_move_heroes(heroes, game_view)
	start_encounter()

func start_encounter() -> void:
	var encounter: EncounterResource = EncounterResource.new()
	encounter.enemy_composition = adventure.enemy_composition
	encounter.map_layout = MapGenerator.new().build_layout()
	if not encounter.map_layout:
		push_error("MapPartition: No EncounterResource.map_layout provided")
		return
	game_view.start_encounter(encounter)

# Called when an encounter ends. Encounter decides if another encounter or to emit encounters finished for Adventure.
func end_encounter(victory: bool) -> void:
	if victory:
		adventure.depth -= 1
		if adventure.depth:
			start_encounter()
		else:
			var retiring_heroes: Array[Node] = game_view.get_children().filter(func(c: Node) -> bool: return c is Character and (c as Character).team == EnumService.Team.HEROES)
			_move_heroes(retiring_heroes, inn)
			adventure_ended.emit()
	else:
		adventure_ended.emit()

func inn_setup(inn_node: Inn) -> void:
	inn = inn_node

func _move_heroes(heroes: Array[Node], destination: Node) -> void:
	for hero: Character in heroes:
		hero.visible = destination != inn
		if hero.get_parent() != destination:
			if hero.get_parent():
				hero.reparent(destination)
			else:
				destination.add_child(hero)
