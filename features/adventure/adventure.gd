class_name Adventure
extends VBoxContainer

#Listeners: Town
signal adventure_ended()

var acting_character: Character = null:
	set(new_node):
		camera_focus.follow_node(new_node)
		acting_character = new_node
		_raise_to_top(new_node)
var selected_node: Node = null:
	set(new_node):
		camera_focus.follow_node(new_node)
		selected_node = new_node
		_raise_to_top(new_node)

@onready var bottom_partition: BottomPartition = %BottomPartition
@onready var camera_focus: CameraFocus = %CameraFocus
@onready var enemy_ai: EnemyAI = %EnemyAI
@onready var game_view: GameView = %GameView
@onready var input_handler: InputHandler = %InputHandler
@onready var map_partition: MapPartition = %MapPartition

func _ready() -> void:
	enemy_ai.enemy_command.connect(action_clicked)
	game_view.encounter_ended.connect(func(_victory: bool) -> void: selected_node = null)
	game_view.portraits_setup.connect(func(a: Array[Node], t: TurnManager) -> void: bottom_partition.portraits_setup(a, t))
	map_partition.adventure_ended.connect(func() -> void: adventure_ended.emit())
	EventBus.action_clicked.connect(action_clicked)
	EventBus.acting_character_changed.connect(func(c: Character) -> void: acting_character = c)
	EventBus.character_died.connect(func(c: Character) -> void: if c == selected_node: selected_node = null)
	EventBus.hover_changed.connect(func(_n: Array[Node], _cell: Vector2i) -> void: selected_node = null)
	EventBus.portrait_selected.connect(func(c: Character) -> void: if is_instance_valid(c): selected_node = c)
	EventBus.select_clicked.connect(select_clicked)

#region Input Functionality
func select_clicked(nodes: Array[Node], _cell: Vector2i) -> void:
	if selected_node == null or selected_node not in nodes:
		selected_node = nodes[0]
		return
	var current_index: int = nodes.find(selected_node)
	selected_node = nodes[(current_index + 1) % nodes.size()]

func action_clicked(nodes: Array[Node], cell: Vector2i, actor: Character = acting_character, target: Node = selected_node) -> void:
	if not actor:
		return 
	var command: ActionCommand = ActionCommand.new()
	command.action_resource = actor.get_action_set()
	command.actor = actor
	command.nodes = nodes
	command.target_cell = cell
	command.target_node = target if is_instance_valid(target) else null
	EventBus.command_routed.emit(command)
#endregion

#Raise-on-assign: acting_character and selected_node setters both route through here, so a stack's
#top is last-writer-wins between them. Resets every unit sharing the node's cell to z = 0, then
#raises the node to z = 10. z memory lives on the nodes: null or freed assignments stop at the
#guard, so clearing a selection (hover, death, encounter end) never demotes a raised unit.
func _raise_to_top(node: Node) -> void:
	if is_instance_valid(node) and node is CanvasItem:
		for raisable_node: Node in input_handler.get_nodes_at_position(node.global_position as Vector2):
			(raisable_node as CanvasItem).z_index = 0
		(node as CanvasItem).z_index = 10
