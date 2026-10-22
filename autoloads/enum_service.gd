#DamageFlag enum found on action_resource script
extends Node

enum ActionType{
	ARCANE_ATTACK,
	HEAL,
	MELEE_ATTACK,
	MOVE,
	RANGE_ATTACK
	}

enum CharacterType{
	ARCHER,
	SKELETON,
	SORCERESS,
	}

enum ItemType{
	CHEST,
}

enum Mode {
	DEFAULT = -1,
	COMBAT,
	EXPLORATION,
	}

enum SkillCheck{
	ARCHERY,
	ATHLETICS,
	FIRST_AID,
	MELEE,
	SORCERY,
	}

enum Team {
	NONE = -1,
	HEROES,
	ENEMIES,
	}

enum Terrain{
	FLOOR,
	WALL,
	LADDER
	}
