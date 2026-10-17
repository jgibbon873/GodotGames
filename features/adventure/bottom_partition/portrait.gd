# game_view.gd:67 emits portraits_setup() → 
# adventure.gd:28 relay → bottom_partition.gd:25 portraits_setup() → 
# containers' set_up_portrait() (party_container.gd:6 / enemies_container.gd:6) instantiate the Portrait.

class_name Portrait
extends TextureRect

var character: Character = null
var turn_manager: TurnManager = null

@onready var character_activate_button: Button = %CharacterActivateButton

func _ready() -> void:
	if character:
		character_activate_button.pressed.connect(func() -> void: turn_manager.change_acting_character(character))
		character.health_changed.connect(func(_c: int, _m: int) -> void: pass) #Placeholder
		EventBus.character_died.connect(func(c: Character) -> void: if c == character: queue_free())
		EventBus.mode_changed.connect(func(n: EnumService.Mode) -> void: character_activate_button.visible = EnumService.Mode.EXPLORATION == n)
	else:
		push_warning("Portrait: character is null — signals not connected")

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			EventBus.portrait_selected.emit(character)
			accept_event() #Optional – stops the event from continuing
		MOUSE_BUTTON_RIGHT:
			accept_event()
