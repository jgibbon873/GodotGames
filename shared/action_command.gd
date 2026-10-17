class_name ActionCommand
extends Resource

var action_resource: ActionResource = null
var actor: Node = null
var distance: int = 0
var nodes: Array[Node] = []
var target_cell: Vector2i = TileMapService.INVALID_CELL
var target_node: Node = null
