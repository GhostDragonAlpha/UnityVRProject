class_name CreatureData
extends Resource
## Defines creature stats, behavior types, and spawn conditions
##
## This resource class holds all static data for a creature type including
## health, movement, attack stats, and which biomes it can spawn in.

enum CreatureType {
	PASSIVE,     ## Flees from player
	NEUTRAL,     ## Ignores unless attacked
	AGGRESSIVE,  ## Attacks on sight
	TAMEABLE     ## Can be tamed
}

## Display name of the creature
@export var creature_name: String = "Unknown"

## Behavioral classification
@export var creature_type: CreatureType = CreatureType.NEUTRAL

## Maximum health points
@export var max_health: float = 100.0

## Movement speed in meters per second
@export var movement_speed: float = 3.0

## Damage dealt per attack
@export var attack_damage: float = 10.0

## Distance at which creature detects targets
@export var detection_range: float = 15.0

## Distance at which creature can attack
@export var attack_range: float = 2.0

## Attack cooldown in seconds
@export var attack_cooldown: float = 1.0

## List of biome names where this creature can spawn
@export var spawn_biomes: Array[String] = []

## Visual model scale
@export var model_scale: float = 1.0

## Experience points awarded on death
@export var xp_reward: int = 10

## Loot table (not implemented in foundation)
@export var loot_items: Array[String] = []

func can_spawn_in_biome(biome: String) -> bool:
	"""Check if creature can spawn in given biome"""
	return biome in spawn_biomes

func get_stats_dict() -> Dictionary:
	"""Return stats as dictionary for serialization"""
	return {
		"name": creature_name,
		"type": CreatureType.keys()[creature_type],
		"max_health": max_health,
		"movement_speed": movement_speed,
		"attack_damage": attack_damage,
		"detection_range": detection_range,
		"attack_range": attack_range,
		"attack_cooldown": attack_cooldown,
		"spawn_biomes": spawn_biomes,
		"xp_reward": xp_reward
	}
