class_name EnemyManager
extends Node

const CHARACTER: PackedScene = preload("uid://kt4n7l7k8qxh")

## Spawns a new enemy and adds it to the pool
func spawn_enemy(character_type: CharacterResource = null) -> Character:
	var enemy: Character = CHARACTER.instantiate() as Character
	var character: CharacterResource = character_type if character_type != null else preload("res://resources/character_resources/archer.tres")
	enemy.character_resource = character
	enemy.team = EnumService.Team.ENEMIES
	enemy.visible = false
	add_child(enemy)
	return enemy

## Spawn multiple enemies from composition dictionary
func spawn_enemies_from_composition(composition: Dictionary[EnumService.CharacterType, int]) -> Array[Node]:
	var spawned: Array[Node] = []
	for monster_type: EnumService.CharacterType in composition:
		var monster_name: String = EnumService.CharacterType.find_key(monster_type).to_lower()
		var character_path: String = "res://resources/character_resources/%s.tres" % monster_name
		if not ResourceLoader.exists(character_path):
			push_error("EnemyManager: no CharacterResource at %s" % character_path)
			continue
		var character: CharacterResource = load(character_path)
		var count: int = composition[monster_type]
		for i: int in count:
			var enemy: Character = spawn_enemy(character)
			if enemy:
				spawned.append(enemy)
	return spawned
