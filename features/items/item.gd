class_name Item
extends Area2D

var item_resource: ItemResource

@onready var sprite_2d: Sprite2D = %Sprite2D

func _ready() -> void:
	# Auto-setup for items placed in editor
	if item_resource and not has_meta("item_resource"):
		setup(item_resource)
	collision_mask = 0

## Call this after instantiating the item in code
func setup(resource: ItemResource) -> void:
	if not resource:
		push_error("Item: No ItemResource provided")
		return
	item_resource = resource
	set_meta("item_resource", resource)
	_apply_visuals()

func _apply_visuals() -> void:
	if sprite_2d and item_resource.sprite:
		sprite_2d.texture = item_resource.sprite
