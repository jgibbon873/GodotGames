class_name GameCamera
extends Camera2D

@onready var camera_focus: CameraFocus = %CameraFocus

func _ready() -> void:
	CameraService.set_camera(self)

func _process(_delta: float) -> void:
	if camera_focus:
		global_position = global_position.lerp(camera_focus.global_position, 0.15)

func update_camera(viewport_size: Vector2) -> void:
		position = Vector2(viewport_size) / 2
		zoom = Vector2.ONE
