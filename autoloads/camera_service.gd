extends Node

const FALLBACK_POSITION: Vector2 = Vector2.ZERO

var active_camera: Camera2D = null

func set_camera(cam: Camera2D) -> void:
	active_camera = cam

func get_world_mouse_position() -> Vector2:
	if active_camera == null or not is_instance_valid(active_camera):
		push_warning("CameraService: No active camera set")
		return FALLBACK_POSITION
	
	var pixel_pos: Vector2 = active_camera.get_viewport().get_mouse_position()
	var canvas_xform: Transform2D = active_camera.get_canvas_transform()
	return canvas_xform.affine_inverse() * pixel_pos
