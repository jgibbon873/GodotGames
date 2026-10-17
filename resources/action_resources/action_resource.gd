class_name ActionResource
extends Resource

enum DamageFlag {
	NONE     = 0,
	BLUNT    = 1,      # 1 << 0
	PIERCING = 2,      # 1 << 1
	SLASHING = 4,      # 1 << 2
	ACID     = 8,      # 1 << 3
	BURNING  = 16,     # 1 << 4
	}

@export var action_name: String
@export var action_type: EnumService.ActionType
@export_flags("BLUNT", "PIERCING", "SLASHING", "ACID", "BURNING") var damage_flags: int = 0
@export var skill_check: EnumService.SkillCheck
@export var strength: int = 0
@export var cell_range: int = 0
