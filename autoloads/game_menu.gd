extends CanvasLayer

@onready var exit_game_button: Button = %ExitGameButton

func _ready() -> void:
	exit_game_button.pressed.connect(func() -> void: get_tree().quit())
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		visible = !visible
		get_tree().paused = visible
		get_viewport().set_input_as_handled()
