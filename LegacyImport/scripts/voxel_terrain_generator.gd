extends Node
class_name VoxelTerrainGenerator

## Simple voxel terrain generator for creating a flat landable surface
## Generates a basic flat terrain with slight noise for testing player collision

## Generate a simple flat terrain
## This creates a flat surface at y=0 with slight variation
static func generate_flat_terrain(buffer, channel: int = 0) -> void:
	var min_pos = buffer.get_voxel_tool().get_voxel_f_interpolated(Vector3(0, 0, 0))
	var size = buffer.get_size()

	# Create a simple flat surface at y = 0
	# Set all voxels above y=0 to air (negative SDF)
	# Set all voxels below y=0 to solid (positive SDF)

	for x in range(size.x):
		for z in range(size.z):
			for y in range(size.y):
				var world_pos = Vector3(x, y, z) + buffer.get_origin()

				# Simple flat terrain: solid below y=0, air above
				var sdf_value = -world_pos.y  # Negative = air, Positive = solid

				# Add slight noise for variation
				var noise_offset = (sin(world_pos.x * 0.1) + cos(world_pos.z * 0.1)) * 2.0
				sdf_value += noise_offset

				buffer.set_voxel_f(sdf_value, x, y, z, channel)

## Generate terrain with hills using noise
static func generate_hilly_terrain(buffer, channel: int = 0) -> void:
	var size = buffer.get_size()

	for x in range(size.x):
		for z in range(size.z):
			for y in range(size.y):
				var world_pos = Vector3(x, y, z) + buffer.get_origin()

				# Create hills using sine waves
				var height = sin(world_pos.x * 0.05) * 10.0 + cos(world_pos.z * 0.05) * 10.0
				var sdf_value = height - world_pos.y

				buffer.set_voxel_f(sdf_value, x, y, z, channel)
