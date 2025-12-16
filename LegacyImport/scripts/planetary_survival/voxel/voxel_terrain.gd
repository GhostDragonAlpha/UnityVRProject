class_name StubVoxelTerrain
extends Node3D

## Voxel terrain system stub (renamed to avoid conflict with Zylann's VoxelTerrain)
## TODO: Implement full voxel terrain generation and modification
## This stub allows resource_system.gd to compile without errors
## NOTE: The native VoxelTerrain class from godot_voxel addon is now available

## Get voxel density at a world position
func get_voxel_density(pos: Vector3) -> float:
	# TODO: Implement voxel terrain density queries
	# For now, return 0.0 (empty space)
	return 0.0

## Set voxel density at a world position
func set_voxel_density(pos: Vector3, density: float) -> void:
	# TODO: Implement voxel terrain modification
	# For now, this is a no-op
	pass

## Get voxel type/material at a world position
func get_voxel_type(pos: Vector3) -> int:
	# TODO: Implement voxel type queries
	return 0

## Set voxel type/material at a world position
func set_voxel_type(pos: Vector3, type: int) -> void:
	# TODO: Implement voxel type modification
	pass
