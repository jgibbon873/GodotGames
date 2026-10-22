class_name Item
extends Area2D

const CATALOG: ItemCatalog = preload("uid://dm5e1gi4aylnk")
const ITEM: PackedScene = preload("uid://cvihwam8u3bx7")

var item_resource: ItemResource = null:
	set(new_resource):
		if item_resource:
			push_error("Item %s: item_resource already set (%s); ignored %s" % [name, item_resource, new_resource])
			return
		item_resource = new_resource

@onready var sprite_2d: Sprite2D = %Sprite2D

func _ready() -> void:
	if not item_resource:
		push_warning("%s: ItemResource not ready in _ready()" % name)
		return
	sprite_2d.texture = item_resource.sprite
	collision_mask = 0

func cell() -> Vector2i:
	return TileMapService.cell_at(global_position)

static func create_item(item_type: EnumService.ItemType) -> Item:
	var resource: ItemResource = CATALOG.items.get(item_type)
	if resource == null:
		push_error("Item.create_item(): no catalog entry for %s" % EnumService.ItemType.find_key(item_type))
		return null
	var item: Item = ITEM.instantiate()
	item.item_resource = resource
	return item
