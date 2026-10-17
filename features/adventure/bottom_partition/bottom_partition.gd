class_name BottomPartition
extends MarginContainer

@onready var action_over_button: Button = %ActionOverButton
@onready var enemies_container: EnemiesContainer = %EnemiesContainer
@onready var mode_label: Label = %ModeLabel
@onready var party_container: PartyContainer = %PartyContainer
@onready var phase_label: Label = %PhaseLabel
@onready var turn_over_button: Button = %TurnOverButton
@onready var turn_label: Label = %TurnLabel

func _ready() -> void:
	EventBus.mode_changed.connect(_on_mode_changed)
	EventBus.phase_changed.connect(func(phase: int) -> void: phase_label.text = "PHASE " + str(phase))
	EventBus.turn_changed.connect(func(turn: int) -> void: turn_label.text = "TURN " + str(turn))
	action_over_button.pressed.connect(func() -> void: EventBus.action_ended.emit())
	turn_over_button.pressed.connect(func() -> void: EventBus.turn_ended.emit())
	
func _on_mode_changed(new_mode: EnumService.Mode) -> void:
	mode_label.text = EnumService.Mode.find_key(new_mode)
	phase_label.visible = (new_mode == EnumService.Mode.COMBAT)
	action_over_button.visible = (new_mode == EnumService.Mode.COMBAT)
	turn_over_button.visible = (new_mode == EnumService.Mode.EXPLORATION)

func portraits_setup(characters: Array[Node], turn_manager: TurnManager) -> void:
	for child: Node in enemies_container.get_children():
		enemies_container.remove_child(child)
		child.queue_free()
	for child: Node in party_container.get_children():
		party_container.remove_child(child)
		child.queue_free()
	for character: Character in characters:
		if character.team == EnumService.Team.HEROES:
			party_container.set_up_portrait(character, turn_manager)
		elif character.team == EnumService.Team.ENEMIES:
			enemies_container.set_up_portrait(character)
