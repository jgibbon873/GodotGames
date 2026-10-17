class_name InputHandler
extends Node

const CELL_MARKER_NAME: String = "cell_marker"
const MAX_PENDING_MS: int = 500

var cell_marker: Node2D = null #Used as cell stand-in in _physics_process().
var _hovered_nodes: Array[Node] = []
var _last_hover_cell: Vector2i = TileMapService.INVALID_CELL
var _pending_event: InputEventMouseButton = null
var _pending_mouse_pos: Vector2 = Vector2.INF
var _pending_time_ms: int = 0
var shape: RectangleShape2D = RectangleShape2D.new() #Used in get_nodes_at_position
var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()

func _ready() -> void:
	cell_marker = Node2D.new()
	cell_marker.name = CELL_MARKER_NAME
	add_child(cell_marker)
	query.shape = shape

func _input(event: InputEvent) -> void:
	# --- Hover detection (runs first, for all motion events) ---
	if event is InputEventMouseMotion:
		if _mouse_outside_viewport():
			_clear_hover()
			return
		var world_pos: Vector2 = CameraService.get_world_mouse_position()
		if TileMapService.has_tile_map():
			var hovered_cell: Vector2i = TileMapService.cell_at(world_pos)
			if hovered_cell != _last_hover_cell:
				_last_hover_cell = hovered_cell
				_hovered_nodes = get_nodes_at_position(world_pos)
				EventBus.hover_changed.emit(_hovered_nodes, hovered_cell)
		else:
			_clear_hover()
		return
	# --- Click handling (button events only) ---
	if not event is InputEventMouseButton or not event.pressed:
		return
	if _mouse_outside_viewport():
		return
	if _pending_event != null:
		if Time.get_ticks_msec() - _pending_time_ms < MAX_PENDING_MS:
			get_viewport().set_input_as_handled()
			return
	if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
		_pending_event = event.duplicate() as InputEventMouseButton
		_pending_mouse_pos = CameraService.get_world_mouse_position()
		_pending_time_ms = Time.get_ticks_msec()

func _physics_process(_delta: float) -> void:
	if _pending_event == null:
		return
	if not TileMapService.has_tile_map():
		_pending_event = null
		_pending_mouse_pos = Vector2.INF
		return
	var clicked_cell: Vector2i = TileMapService.cell_at(_pending_mouse_pos)
	var clicked_nodes: Array[Node] = get_nodes_at_position(_pending_mouse_pos)
	var event: InputEventMouseButton = _pending_event
	cell_marker.position = TileMapService.position_to_cell_center(_pending_mouse_pos)
	_pending_event = null
	_pending_mouse_pos = Vector2.INF
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			clicked_nodes.append(cell_marker)
			EventBus.select_clicked.emit(clicked_nodes, clicked_cell)
		MOUSE_BUTTON_RIGHT:
			EventBus.action_clicked.emit(clicked_nodes, clicked_cell)

func get_nodes_at_position(world_pos: Vector2) -> Array[Node]:
	if not TileMapService.has_tile_map():
		return []
	var cell_center: Vector2 = TileMapService.position_to_cell_center(world_pos)
	query.transform = Transform2D(0, cell_center)
	var space: PhysicsDirectSpaceState2D = get_parent().get_world_2d().direct_space_state
	var results: Array[Dictionary] = space.intersect_shape(query)
	var nodes: Array[Node] = []
	for result: Dictionary in results:
		if result.collider is Node:
			nodes.append(result.collider)
	nodes.sort_custom(func(a: Node, b: Node) -> bool:
		# Primary: team priority (heroes=0, enemies=1, other=2)
		var pri_a: int = _node_priority(a)
		var pri_b: int = _node_priority(b)
		if pri_a != pri_b:
			return pri_a < pri_b
		# Secondary: instance ID (guarantees total ordering)
		return a.get_instance_id() < b.get_instance_id())
	return nodes

func _node_priority(node: Node) -> int:
	var character: Character = node as Character
	if character == null:
		return 2
	if character.team == EnumService.Team.HEROES:
		return 0
	if character.team == EnumService.Team.ENEMIES:
		return 1
	return 2

func _clear_hover() -> void:
	_last_hover_cell = TileMapService.INVALID_CELL
	if not _hovered_nodes.is_empty():
		_hovered_nodes.clear()
		EventBus.hover_changed.emit(_hovered_nodes, TileMapService.INVALID_CELL)

func _mouse_outside_viewport() -> bool:
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var vp_size: Vector2 = (get_viewport() as SubViewport).size
	return mouse.x < 0.0 or mouse.x >= vp_size.x or mouse.y < 0.0 or mouse.y >= vp_size.y
