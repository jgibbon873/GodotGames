class_name Character
extends CharacterBody2D

#Listeners: Portrait, EnemyPortrait
signal health_changed(current: int, maximum: int)

var actions: Array[ActionResource] = []
var action_set: ActionResource = null
var alerted: Array[Character] = []
var can_act: bool = true
var character_type: CharacterTypeResource
var display_name: String = "Character"
var is_dead: bool = false
var movement_remaining: int = 0
var speed: int = 3 #Speed sets active phases in a turn
var team: EnumService.Team = EnumService.Team.NONE

var skills: Dictionary[EnumService.SkillCheck, int] = {
	EnumService.SkillCheck.ARCHERY: 10,
	EnumService.SkillCheck.ATHLETICS: 0,
	EnumService.SkillCheck.FIRST_AID: 0,
	EnumService.SkillCheck.MELEE: 10,
	EnumService.SkillCheck.SORCERY: 0}

var arcane_strength: int = 20
var physical_strength: int = 20

@onready var item_component: ItemComponent = %ItemComponent
@onready var health_component: HealthComponent = %HealthComponent
@onready var sprite_2d: Sprite2D = %Sprite2D

func _ready() -> void:
	if team == EnumService.Team.NONE:
		push_warning("%s: Spawned without a team" % display_name)
	if item_component == null:
		push_warning("%s: ItemComponent not ready in _ready()" % display_name)
	if health_component == null:
		push_warning("%s: HealthComponent not ready in _ready()" % display_name)
	for action: ActionResource in character_type.actions:
		actions.append(action.duplicate())
	collision_mask = 0
	sprite_2d.texture = character_type.appearance
	movement_remaining = character_type.movement
	health_component.died.connect(die)
	health_component.health_changed.connect(func(c: int, m: int) -> void: health_changed.emit(c, m))
	EventBus.acting_character_changed.connect(_on_acting_character_changed)

func get_action_set() -> ActionResource:
	return action_set

func cell() -> Vector2i:
	return TileMapService.cell_at(global_position)

##Called when phasing character changes
func _on_acting_character_changed(new_character: Character) -> void:
	if new_character == self:
		sprite_2d.modulate = Color.BLUE * 1.5  #Brighten
	else:
		sprite_2d.modulate = Color.WHITE

func refresh() -> void:
	action_set = null
	can_act = true
	movement_remaining = character_type.movement
	
func spend_movement_points(distance: int) -> bool:
	if distance >= 0 and distance <= movement_remaining:
		movement_remaining -= distance
		return true
	return false

func die() -> void:
	if is_dead:
		return        # latch — also closes the double-die/re-emit hazard from the audit
	is_dead = true
	EventBus.character_died.emit(self)
	if EventBus.acting_character_changed.is_connected(_on_acting_character_changed):
		EventBus.acting_character_changed.disconnect(_on_acting_character_changed)
	queue_free()

#region Action Functions
func execute_action(command: ActionCommand, result: ActionResult) -> void:
	if not can_act:
		return
	can_act = false
	result.roll_margin = _skill_check(skills[command.action_resource.skill_check])
	if result.roll_margin > 0:
		return
	match command.action_resource.action_type:
		EnumService.ActionType.ARCANE_ATTACK:
			_execute_arcane_attack(command, result)
		EnumService.ActionType.HEAL:
			_execute_heal_action(result)
		EnumService.ActionType.MELEE_ATTACK:
			_execute_melee_attack(command, result)
		EnumService.ActionType.RANGE_ATTACK:
			_execute_range_attack(command, result)
		_:
			can_act = true

func _skill_check(skill: int) -> int:
	return GlobalRng.roll(20) - skill

func _execute_arcane_attack(command: ActionCommand, result: ActionResult) -> void:
	result.health_adjust = command.action_resource.strength + arcane_strength

func _execute_heal_action(result: ActionResult) -> void:
	result.health_adjust = -50
	
func _execute_melee_attack(command: ActionCommand, result: ActionResult) -> void:
	result.health_adjust = command.action_resource.strength + physical_strength

func _execute_range_attack(command: ActionCommand, result: ActionResult) -> void:
	result.health_adjust = command.action_resource.strength
#endregion
