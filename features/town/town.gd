class_name Town
extends Control

const ADVENTURE: PackedScene = preload("uid://bmhmy7lmjk6gg")

var test_adventure_resource: AdventureResource = preload("res://resources/adventures/test_adventure.tres")
var current_adventure: Adventure = null

@onready var adventure_button: Button = %AdventureButton
@onready var inn: Inn = %Inn
@onready var inn_button: Button = %InnButton
@onready var town_square: TextureRect = %TownSquare

func _ready() -> void:
	adventure_button.pressed.connect(start_adventure)
	inn.enter_town_square.connect(_on_enter_or_leave_inn)
	inn_button.pressed.connect(_on_enter_or_leave_inn)

func start_adventure(adventure_resource: AdventureResource = test_adventure_resource) -> void:
	town_square.visible = false
	if current_adventure:
		current_adventure.queue_free()
		current_adventure = null
	current_adventure = ADVENTURE.instantiate() as Adventure
	if not current_adventure:
		push_error("Town: Failed to instantiate Adventure")
		return
	
	add_child(current_adventure)
	var heroes: Array[Node] = inn.get_children().filter(func(c: Node) -> bool: return c is Character and (c as Character).team == EnumService.Team.HEROES)
	current_adventure.map_partition.inn_setup(inn)
	current_adventure.adventure_ended.connect(end_adventure)
	current_adventure.map_partition.start_adventure(adventure_resource, heroes)

# freeing of scene is reserved for scene root, no premature freeing from children!
func end_adventure() -> void:
	current_adventure.queue_free()
	current_adventure = null
	town_square.visible = true

func _on_enter_or_leave_inn() -> void:
	town_square.visible = !town_square.visible
	inn.visible = !town_square.visible
