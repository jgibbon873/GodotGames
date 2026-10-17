class_name TurnManager
extends Node

#Listeners: GameView connected on turn_manager_set_up().
signal heroes_won(victory: bool)

var acting_phases_lookup: Dictionary[int, Array] = {}
var characters_this_phase: Array[Node] = []
# Default differs from any real mode, so the first change_mode() triggers initial set-up.
var current_mode: EnumService.Mode = EnumService.Mode.DEFAULT
var _exploration_queue: Array[Character] = []
var phase: int = 0:
	set(new_value):
		if new_value > phase_iterations:
			phase = 1
			turn += 1
		else:
			phase = new_value
		if phase != 0:
			EventBus.phase_changed.emit(phase)
var phase_iterations: int = 6
var turn: int = 0:
	set(new_value):
		turn = new_value
		EventBus.turn_changed.emit(turn)

func _ready() -> void:
	EventBus.action_ended.connect(_character_action_over)
	EventBus.turn_ended.connect(_on_turn_ended)
	_build_acting_phases_lookup()
	turn = 1

func change_mode(new_mode: EnumService.Mode) -> void:
	if current_mode == new_mode:
		return
	match current_mode:
		EnumService.Mode.EXPLORATION:
			exit_exploration()
		EnumService.Mode.COMBAT:
			exit_combat()
	current_mode = new_mode
	EventBus.mode_changed.emit(new_mode)
	match new_mode:
		EnumService.Mode.EXPLORATION:
			enter_exploration()
		EnumService.Mode.COMBAT:
			enter_combat()

#region Combat Mode
func enter_combat() -> void:
	# clear queue for returns to process_next_exploration_enemy().
	_exploration_queue.clear()
	for character: Character in get_characters():
		character.refresh()
	start_new_combat_phase()

func exit_combat() -> void:
	phase = 0
	characters_this_phase.clear()

# next_phase signal triggers "on_next_phase" on BottomPartition.
# character_action_over signal triggers acting_character_changed signal.
func start_new_combat_phase() -> void:
	if _check_for_victory():
		return
	if !get_team_characters(EnumService.Team.ENEMIES).any(func(c: Character) -> bool: return c.visible):
		change_mode(EnumService.Mode.EXPLORATION)
		return
	phase += 1
	characters_this_phase = filter_characters_for_phase(get_characters())
	_character_action_over()
	
func _character_action_over() -> void:
	while not characters_this_phase.is_empty():
		if is_instance_valid(characters_this_phase[0]) and not (characters_this_phase[0] as Character).is_dead:
			var next: Character = characters_this_phase.pop_front()
			next.refresh()
			change_acting_character(next as Character)
			return
		else:
			characters_this_phase.pop_at(0)
	start_new_combat_phase()
	
func filter_characters_for_phase(characters: Array[Node]) -> Array[Node]:
	return characters.filter(func(c: Node) -> bool:
		var character: Character= c as Character
		return character != null and phase in acting_phases_lookup.get(character.speed, []))
#endregion

#region Exploration Mode
func enter_exploration() -> void:
	if _check_for_victory():
		return
	for character: Character in get_characters():
		character.refresh()

func exit_exploration() -> void:
	pass

func _on_turn_ended() -> void:
	for character: Character in get_characters():
			character.refresh()
	_exploration_queue = get_team_characters(EnumService.Team.ENEMIES)
	process_next_exploration_enemy()

func process_next_exploration_enemy() -> void:
	while not _exploration_queue.is_empty():
		if is_instance_valid(_exploration_queue[0]) and not _exploration_queue[0].is_dead:
			change_acting_character(_exploration_queue.pop_front() as Node)
			return
		else:
			_exploration_queue.pop_at(0)
	turn += 1
#endregion

func get_mode() -> EnumService.Mode:
	return current_mode
func change_acting_character(character: Node) -> void:
	EventBus.acting_character_changed.emit(character)

func get_characters() -> Array[Node]:
	return get_children().filter(func(c: Node) -> bool: return c is Character and _is_alive(c as Character))
func get_team_characters(team: EnumService.Team) -> Array[Character]:
	var result: Array[Character] = []
	for c: Node in get_children():
		if c is Character and _is_alive(c as Character) and c.team == team:
			result.append(c as Character)
	return result

# Game-state liveness ONLY. Callers must guarantee the reference is a valid
# instance (is_instance_valid checked at the call site) — a freed reference
# fails argument binding before this body runs.
func _is_alive(character: Character) -> bool:
	return character != null and not character.is_dead
func _check_for_victory() -> bool:
	if get_team_characters(EnumService.Team.HEROES).is_empty():
		heroes_won.emit(false)
	if get_team_characters(EnumService.Team.ENEMIES).is_empty():
		heroes_won.emit(true)
	return get_team_characters(EnumService.Team.HEROES).is_empty() or get_team_characters(EnumService.Team.ENEMIES).is_empty()

# Called from _build_acting_phases_lookup()
func _get_acting_phases(speed: int, _phase_iterations: int) -> Array[int]:
	var phases: Array[int] = []
	if speed <= 0 or _phase_iterations <= 0:
		return phases
	speed = mini(speed, _phase_iterations)
	# Calculate step size
	var step: float = float(_phase_iterations) / speed
	# Center the entire sequence
	var offset: float = (step - 1.0) / 2.0
	for i: int in speed:
		var _phase: int = (round(i * step + offset)) + 1
		_phase = clampi(_phase, 1, _phase_iterations)
		if _phase not in phases:
			phases.append(_phase)
	phases.sort()
	return phases
func _build_acting_phases_lookup() -> void:
	acting_phases_lookup.clear()
	for speed: int in range(1, phase_iterations + 1):
		acting_phases_lookup[speed] = _get_acting_phases(speed, phase_iterations)
