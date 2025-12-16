## VoxelGeneratorProcedural - Custom procedural terrain generator
## Extends VoxelGeneratorScript to provide noise-based terrain generation
## compatible with the existing PlanetGenerator system.
##
## This generator uses FastNoiseLite for deterministic terrain generation
## with support for multiple biomes and planetary features.
##
## Requirements:
## - Phase 1, Task 1.1: Basic VoxelGeneratorScript with SDF approach
## - Phase 1, Task 1.2: 3D noise features (caves, overhangs)
## - Integration with existing PlanetGenerator noise configuration
## - Deterministic generation (same seed = same terrain)
## - VR performance target: < 5ms per 32³ chunk
extends VoxelGeneratorScript
class_name VoxelGeneratorProcedural

## Emitted when terrain generation completes for a chunk
signal chunk_generated(origin: Vector3i, lod: int)

#region Export Properties

## Height scale multiplier for terrain elevation
@export var height_scale: float = 50.0:
	set(value):
		height_scale = maxf(value, 0.1)

## Base height offset (y-coordinate of "sea level")
@export var base_height: float = 0.0

## Seed for deterministic generation
@export var terrain_seed: int = 0:
	set(value):
		terrain_seed = value
		_update_noise_seeds()

## Number of noise octaves for terrain
@export var noise_octaves: int = 8:
	set(value):
		noise_octaves = clampi(value, 1, 16)
		if terrain_noise:
			terrain_noise.fractal_octaves = noise_octaves

## Noise persistence (amplitude reduction per octave)
@export var noise_persistence: float = 0.5:
	set(value):
		noise_persistence = clampf(value, 0.1, 1.0)
		if terrain_noise:
			terrain_noise.fractal_gain = noise_persistence

## Noise lacunarity (frequency increase per octave)
@export var noise_lacunarity: float = 2.0:
	set(value):
		noise_lacunarity = clampf(value, 1.0, 4.0)
		if terrain_noise:
			terrain_noise.fractal_lacunarity = noise_lacunarity

## Base noise frequency
@export var base_frequency: float = 0.005:
	set(value):
		base_frequency = clampf(value, 0.0001, 1.0)
		if terrain_noise:
			terrain_noise.frequency = base_frequency

## Enable 3D terrain features (caves, overhangs)
@export var enable_3d_features: bool = false

## Cave density threshold (0.0-1.0)
## Higher values = fewer caves
@export var cave_threshold: float = 0.6:
	set(value):
		cave_threshold = clampf(value, 0.0, 1.0)

## Cave frequency multiplier
@export var cave_frequency: float = 0.02:
	set(value):
		cave_frequency = maxf(value, 0.001)
		if cave_noise:
			cave_noise.frequency = cave_frequency

#endregion

#region Noise Generators

## Reference to noise generator for terrain base
var terrain_noise: FastNoiseLite = null

## Reference to noise generator for terrain detail
var detail_noise: FastNoiseLite = null

## 3D cave noise generator
var cave_noise: FastNoiseLite = null

#endregion

#region Constants

## Prime numbers for hash functions (deterministic generation)
const HASH_PRIME_1: int = 73856093
const HASH_PRIME_2: int = 19349663
const HASH_PRIME_3: int = 83492791

#endregion


func _init() -> void:
	_initialize_noise_generators()


## Initialize noise generators with default settings
func _initialize_noise_generators() -> void:
	"""Initialize FastNoiseLite instances for terrain generation."""

	# Terrain base noise - primary heightmap
	terrain_noise = FastNoiseLite.new()
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	terrain_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	terrain_noise.fractal_octaves = noise_octaves
	terrain_noise.fractal_gain = noise_persistence
	terrain_noise.fractal_lacunarity = noise_lacunarity
	terrain_noise.frequency = base_frequency

	# Detail noise for surface variation
	detail_noise = FastNoiseLite.new()
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	detail_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	detail_noise.fractal_octaves = 4
	detail_noise.frequency = 0.02

	# Cave noise for 3D features
	cave_noise = FastNoiseLite.new()
	cave_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	cave_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	cave_noise.fractal_octaves = 3
	cave_noise.frequency = cave_frequency

	_update_noise_seeds()


## Update noise generator seeds
func _update_noise_seeds() -> void:
	"""Set seeds for all noise generators to ensure deterministic generation."""
	if terrain_noise:
		terrain_noise.seed = terrain_seed
	if detail_noise:
		detail_noise.seed = terrain_seed + HASH_PRIME_1
	if cave_noise:
		cave_noise.seed = terrain_seed + HASH_PRIME_2


#region VoxelGeneratorScript Interface

## Main generation function called by VoxelTerrain
## Implements the VoxelGeneratorScript interface
## This is called for each chunk that needs to be generated
func _generate_block(buffer: VoxelBuffer, origin: Vector3i, lod: int) -> void:
	"""Generate voxel data for a chunk using SDF approach."""
	var size: Vector3i = buffer.get_size()
	var channel: int = VoxelBuffer.CHANNEL_SDF

	# Generate voxel data using SDF approach
	# We iterate in y-x-z order for better cache coherency
	for z in range(size.z):
		for x in range(size.x):
			for y in range(size.y):
				# Calculate world position
				var world_pos := Vector3(
					origin.x + x,
					origin.y + y,
					origin.z + z
				)

				# Generate SDF value for this position
				var sdf_value := _calculate_sdf(world_pos)

				# Write to voxel buffer
				# SDF convention: negative = air, positive = solid
				buffer.set_voxel_f(sdf_value, x, y, z, channel)

	chunk_generated.emit(origin, lod)

#endregion

#region Terrain Generation

## Calculate Signed Distance Field value at a world position
## Returns negative for air (above surface), positive for solid (below surface)
func _calculate_sdf(world_pos: Vector3) -> float:
	"""Calculate SDF value at a world position."""
	# Sample base terrain height at this XZ position
	var terrain_height := _sample_terrain_height(world_pos.x, world_pos.z)

	# SDF = distance from surface
	# Negative values = air (above surface)
	# Positive values = solid (below surface)
	var sdf := terrain_height - world_pos.y

	# Add 3D features if enabled
	if enable_3d_features:
		# Sample cave noise in 3D
		var cave_value := cave_noise.get_noise_3d(world_pos.x, world_pos.y, world_pos.z)
		cave_value = (cave_value + 1.0) * 0.5  # Normalize to [0, 1]

		# If cave_value exceeds threshold, carve out cave
		if cave_value > cave_threshold:
			# Make this area air by forcing SDF negative
			# The strength increases as we exceed the threshold more
			var cave_strength := (cave_value - cave_threshold) / (1.0 - cave_threshold)
			# Blend with existing SDF to create cave
			sdf = minf(sdf, -2.0 * cave_strength)

	return sdf


## Sample terrain height at a given XZ position
func _sample_terrain_height(x: float, z: float) -> float:
	"""Sample terrain height using 2D noise at XZ coordinates."""
	# Get base terrain height from noise
	var base := terrain_noise.get_noise_2d(x, z)

	# Normalize from [-1, 1] to [0, 1], then scale
	base = (base + 1.0) * 0.5 * height_scale

	# Add detail noise for surface variation
	var detail := detail_noise.get_noise_2d(x, z) * (height_scale * 0.1)

	# Combine and offset by base height
	var final_height := base + detail + base_height

	return final_height

#endregion

#region Configuration Methods

## Configure noise parameters (called from PlanetGenerator)
func configure_noise(octaves: int, persistence: float, lacunarity: float, frequency: float) -> void:
	"""Configure the noise generator parameters."""
	noise_octaves = octaves
	noise_persistence = persistence
	noise_lacunarity = lacunarity
	base_frequency = frequency

	if terrain_noise:
		terrain_noise.fractal_octaves = octaves
		terrain_noise.fractal_gain = persistence
		terrain_noise.fractal_lacunarity = lacunarity
		terrain_noise.frequency = frequency


## Configure 3D features (caves, overhangs)
func configure_3d_features(enabled: bool, threshold: float, frequency: float) -> void:
	"""Configure 3D terrain features like caves."""
	enable_3d_features = enabled
	cave_threshold = clampf(threshold, 0.0, 1.0)
	cave_frequency = frequency

	if cave_noise:
		cave_noise.frequency = frequency


## Get current configuration as dictionary
func get_configuration() -> Dictionary:
	"""Get the current generator configuration."""
	return {
		"terrain_seed": terrain_seed,
		"height_scale": height_scale,
		"base_height": base_height,
		"noise_octaves": noise_octaves,
		"noise_persistence": noise_persistence,
		"noise_lacunarity": noise_lacunarity,
		"base_frequency": base_frequency,
		"enable_3d_features": enable_3d_features,
		"cave_threshold": cave_threshold,
		"cave_frequency": cave_frequency
	}


## Apply configuration from dictionary
func apply_configuration(config: Dictionary) -> void:
	"""Apply configuration from a dictionary."""
	if config.has("terrain_seed"):
		terrain_seed = config["terrain_seed"]
	if config.has("height_scale"):
		height_scale = config["height_scale"]
	if config.has("base_height"):
		base_height = config["base_height"]
	if config.has("noise_octaves"):
		noise_octaves = config["noise_octaves"]
	if config.has("noise_persistence"):
		noise_persistence = config["noise_persistence"]
	if config.has("noise_lacunarity"):
		noise_lacunarity = config["noise_lacunarity"]
	if config.has("base_frequency"):
		base_frequency = config["base_frequency"]
	if config.has("enable_3d_features"):
		enable_3d_features = config["enable_3d_features"]
	if config.has("cave_threshold"):
		cave_threshold = config["cave_threshold"]
	if config.has("cave_frequency"):
		cave_frequency = config["cave_frequency"]

#endregion

#region Utility Methods

## Copy configuration from PlanetGenerator
func copy_from_planet_generator(planet_generator: Node) -> void:
	"""Copy noise configuration from an existing PlanetGenerator instance."""
	if planet_generator.has_method("get_configuration"):
		var config = planet_generator.get_configuration()

		# Copy compatible parameters
		if config.has("noise_octaves"):
			noise_octaves = config["noise_octaves"]
		if config.has("noise_persistence"):
			noise_persistence = config["noise_persistence"]
		if config.has("noise_lacunarity"):
			noise_lacunarity = config["noise_lacunarity"]
		if config.has("base_frequency"):
			base_frequency = config["base_frequency"]
		if config.has("height_scale"):
			height_scale = config["height_scale"]


## Get statistics about the generator
func get_statistics() -> Dictionary:
	"""Get statistics about the generator configuration."""
	return {
		"generator_type": "VoxelGeneratorProcedural",
		"version": "1.0",
		"seed": terrain_seed,
		"3d_features_enabled": enable_3d_features,
		"noise_generators": {
			"terrain": {
				"type": FastNoiseLite.TYPE_SIMPLEX_SMOOTH,
				"fractal": FastNoiseLite.FRACTAL_FBM,
				"octaves": noise_octaves,
				"frequency": base_frequency
			},
			"detail": {
				"type": FastNoiseLite.TYPE_SIMPLEX_SMOOTH,
				"fractal": FastNoiseLite.FRACTAL_RIDGED,
				"octaves": 4,
				"frequency": 0.02
			},
			"cave": {
				"type": FastNoiseLite.TYPE_CELLULAR,
				"fractal": FastNoiseLite.FRACTAL_FBM,
				"octaves": 3,
				"frequency": cave_frequency,
				"enabled": enable_3d_features
			}
		}
	}

#endregion
