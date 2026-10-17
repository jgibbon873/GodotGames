class_name CameraFocus
extends Marker2D

const EDGE_SIZE: float = 10.0
const PAN_SPEED: float = 800.0

var _follow_node: Vector2 = Vector2.INF
var map_pixel_size: Vector2 = Vector2.ZERO
var half_viewport: Vector2 = Vector2.ZERO
var viewport_size: Vector2 = Vector2.ZERO

func update_focus(focus_size: Vector2) -> void:
	position = Vector2(focus_size) / 2
	viewport_size = focus_size #Need size of subviewport, not viewport, for correct sizing.
	half_viewport = focus_size / 2

# Called by Adventure's acting_character and selected_node setters.
func follow_node(node: Node) -> void:
	if is_instance_valid(node) and node is CanvasItem and node.visible:
		_follow_node = (node as CanvasItem).position

func _process(delta: float) -> void:
	if map_pixel_size == Vector2.ZERO:
		return
	if _follow_node != Vector2.INF:
		_follow_node.x = clamp(_follow_node.x, half_viewport.x, map_pixel_size.x - half_viewport.x)
		_follow_node.y = clamp(_follow_node.y, half_viewport.y, map_pixel_size.y - half_viewport.y)
		position = position.lerp(_follow_node, 5.0 * delta)
		if position.distance_to(_follow_node) < 2.0:
			_follow_node = Vector2.INF
		_clamp_position()
		return
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var movement: Vector2 = Vector2.ZERO
	# Top / left / right — SubViewport edges
	if mouse_pos.x <= EDGE_SIZE:
		movement.x -= 1
	if mouse_pos.x >= viewport_size.x - EDGE_SIZE:
		movement.x += 1
	if mouse_pos.y <= EDGE_SIZE:
		movement.y -= 1
	# Bottom — actual screen edge, using raw pixel coordinates
	var window_size: Vector2i = DisplayServer.window_get_size()
	var mouse_screen: Vector2i = DisplayServer.mouse_get_position()
	var window_screen: Vector2i = DisplayServer.window_get_position()
	var local_mouse_y: int = mouse_screen.y - window_screen.y
	if local_mouse_y >= window_size.y - int(EDGE_SIZE):
		movement.y += 1
	if movement != Vector2.ZERO:
		position += movement.normalized() * PAN_SPEED * delta
		_clamp_position()

func _clamp_position() -> void:
	position.x = clamp(position.x, half_viewport.x, map_pixel_size.x - half_viewport.x)
	position.y = clamp(position.y, half_viewport.y, map_pixel_size.y - half_viewport.y)
