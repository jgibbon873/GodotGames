class_name ActionBar
extends MarginContainer

const ACTION_BUTTON: PackedScene = preload("uid://blxk28ybkwrhk")

@onready var h_box_container: HBoxContainer = %HBoxContainer

func _ready() -> void:
	EventBus.acting_character_changed.connect(_action_button_set_up)

func _action_button_set_up(c: Character) -> void:
	for box: Button in h_box_container.get_children():
		box.queue_free()
	if not is_instance_valid(c) or not (c.team == EnumService.Team.HEROES):
		return
	var hero: Character = c

	for action: ActionResource in hero.actions:
		var button: Button = ACTION_BUTTON.instantiate()
		button.text = action.action_name
		button.pressed.connect(func() -> void:
			if is_instance_valid(hero):
				hero.action_set = action
				)
		h_box_container.add_child(button)
