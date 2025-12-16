## TerrainNoiseGenerator - 3D Noise System for Procedural Terrain
## Generates 3D noise heightmaps for terrain using FastNoiseLite with
## multiple configurable noise layers for realistic terrain generation.
##
## Phase 1 Task 2: 3D Noise Heightmap Generation
## - Uses FastNoiseLite for base terrain noise
## - Supports multiple noise layers (base, detail, features)
## - Configurable parameters with sensible defaults
## - Deterministic generation from seed
## - Biome-based noise variations
extends Node
class_name TerrainNoiseGenerator

## Emitted when noise parameters are changed
signal noise_parameters_changed(layer: NoiseLayer)
## Emitted when a height value is sampled
signal height_sampled(position: Vector2, height: float)
## Emitted when noise layer is configured
signal layer_configured(layer_name: String, parameters: Dictionary)

## Noise layer types for different terrain features
enum NoiseLayer {
	BASE,      # Base terrain shape
	DETAIL,    # Fine surface detail
	FEATURES,  # Specific terrain features (ridges, valleys)
	EROSION,   # Erosion patterns
	CAVES      # Cave/overhang systems
}

## Noise type presets for different terrain characteristics
enum NoisePreset {
	SMOOTH_HILLS,       # Gentle rolling hills
	ROUGH_MOUNTAINS,    # Sharp mountainous terrain
	FLAT_PLAINS,        # Mostly flat with small variations
	ALIEN_BIZARRE,      # Unusual alien landscape
	CANYON_RIDGES,      # Ridge-based canyon systems
	VOLCANIC_ROUGH      # Rough volcanic surfaces
}

## Prime numbers for deterministic seed offsets
const HASH_PRIME_1: int = 73856093
const HASH_PRIME_2: int = 19349663
const HASH_PRIME_3: int = 83492791
const HASH_PRIME_4: int = 50331653
const HASH_PRIME_5: int = 32416189

## Default noise parameters
const DEFAULT_BASE_FREQUENCY: float = 0.005
const DEFAULT_DETAIL_FREQUENCY: float = 0.02
const DEFAULT_FEATURE_FREQUENCY: float = 0.01
const DEFAULT_OCTAVES: int = 4
const DEFAULT_AMPLITUDE: float = 50.0

#region Configuration Properties

## Base terrain frequency (how zoomed in the noise is)
@export var base_frequency: float = DEFAULT_BASE_FREQUENCY:
	set(value):
		base_frequency = clampf(value, 0.0001, 1.0)
		_update_noise_layer(NoiseLayer.BASE)

## Detail layer frequency (fine surface variations)
@export var detail_frequency: float = DEFAULT_DETAIL_FREQUENCY:
	set(value):
		detail_frequency = clampf(value, 0.001, 1.0)
		_update_noise_layer(NoiseLayer.DETAIL)

## Feature layer frequency (medium-scale terrain features)
@export var feature_frequency: float = DEFAULT_FEATURE_FREQUENCY:
	set(value):
		feature_frequency = clampf(value, 0.001, 1.0)
		_update_noise_layer(NoiseLayer.FEATURES)

## Number of noise octaves (detail levels)
@export var octaves: int = DEFAULT_OCTAVES:
	set(value):
		octaves = clampi(value, 1, 10)
		_update_all_noise_layers()

## Base amplitude (height scale multiplier)
@export var amplitude: float = DEFAULT_AMPLITUDE:
	set(value):
		amplitude = maxf(value, 0.1)

## Seed for deterministic generation
@export var noise_seed: int = 0:
	set(value):
		noise_seed = value
		_set_all_seeds()

## Whether to enable detail layer
@export var enable_detail: bool = true

## Whether to enable feature layer
@export var enable_features: bool = true

## Whether to enable erosion layer
@export var enable_erosion: bool = false

## Whether to enable cave layer
@export var enable_caves: bool = false

#endregion

#region Advanced Configuration

## Base noise type configuration
@export_group("Base Layer")
@export var base_noise_type: FastNoiseLite.NoiseType = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
@export var base_fractal_type: FastNoiseLite.FractalType = FastNoiseLite.FRACTAL_FBM
@export var base_persistence: float = 0.5
@export var base_lacunarity: float = 2.0

## Detail noise type configuration
@export_group("Detail Layer")
@export var detail_noise_type: FastNoiseLite.NoiseType = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
@export var detail_fractal_type: FastNoiseLite.FractalType = FastNoiseLite.FRACTAL_RIDGED
@export var detail_persistence: float = 0.4
@export var detail_lacunarity: float = 2.5

## Feature noise type configuration
@export_group("Feature Layer")
@export var feature_noise_type: FastNoiseLite.NoiseType = FastNoiseLite.TYPE_CELLULAR
@export var feature_cellular_return: FastNoiseLite.CellularReturnType = FastNoiseLite.RETURN_DISTANCE
@export var feature_persistence: float = 0.6
@export var feature_lacunarity: float = 2.0

#endregion

#region Runtime Properties

## Noise generators for each layer
var _base_noise: FastNoiseLite = null
var _detail_noise: FastNoiseLite = null
var _feature_noise: FastNoiseLite = null
var _erosion_noise: FastNoiseLite = null
var _cave_noise: FastNoiseLite = null

## Current seed value
var _current_seed: int = 0

## Biome-specific noise modifiers
var _biome_modifiers: Dictionary = {}

## Cache for frequently sampled positions
var _height_cache: Dictionary = {}
var _max_cache_size: int = 1000

## Layer weights for combining multiple noise sources
var _layer_weights: Dictionary = {
	NoiseLayer.BASE: 1.0,
	NoiseLayer.DETAIL: 0.3,
	NoiseLayer.FEATURES: 0.4,
	NoiseLayer.EROSION: 0.2,
	NoiseLayer.CAVES: -0.5  # Negative for carving
}

#endregion


func _ready() -> void:
	_initialize_noise_generators()
	_initialize_biome_modifiers()


## Initialize all noise generators with default settings
func _initialize_noise_generators() -> void:
	"""Initialize FastNoiseLite instances for all noise layers."""

	# Base terrain noise
	_base_noise = FastNoiseLite.new()
	_base_noise.noise_type = base_noise_type
	_base_noise.fractal_type = base_fractal_type
	_base_noise.fractal_octaves = octaves
	_base_noise.fractal_gain = base_persistence
	_base_noise.fractal_lacunarity = base_lacunarity
	_base_noise.frequency = base_frequency

	# Detail noise for surface variation
	_detail_noise = FastNoiseLite.new()
	_detail_noise.noise_type = detail_noise_type
	_detail_noise.fractal_type = detail_fractal_type
	_detail_noise.fractal_octaves = maxi(octaves - 2, 2)
	_detail_noise.fractal_gain = detail_persistence
	_detail_noise.fractal_lacunarity = detail_lacunarity
	_detail_noise.frequency = detail_frequency

	# Feature noise for specific terrain features
	_feature_noise = FastNoiseLite.new()
	_feature_noise.noise_type = feature_noise_type
	if feature_noise_type == FastNoiseLite.TYPE_CELLULAR:
		_feature_noise.cellular_return_type = feature_cellular_return
	_feature_noise.fractal_octaves = maxi(octaves - 1, 2)
	_feature_noise.fractal_gain = feature_persistence
	_feature_noise.fractal_lacunarity = feature_lacunarity
	_feature_noise.frequency = feature_frequency

	# Erosion noise for natural weathering patterns
	_erosion_noise = FastNoiseLite.new()
	_erosion_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_erosion_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_erosion_noise.fractal_octaves = 3
	_erosion_noise.frequency = 0.008

	# Cave noise for underground structures
	_cave_noise = FastNoiseLite.new()
	_cave_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	_cave_noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	_cave_noise.frequency = 0.015

	# Set initial seed
	_set_all_seeds()


## Initialize biome-specific noise modifiers
func _initialize_biome_modifiers() -> void:
	"""Initialize biome-specific noise modification parameters."""
	# Ice biome: smooth with some ridges
	_biome_modifiers["ice"] = {
		"base_multiplier": 0.7,
		"detail_multiplier": 0.2,
		"feature_multiplier": 0.5,
		"roughness_factor": 0.3
	}

	# Desert biome: dunes and smooth areas
	_biome_modifiers["desert"] = {
		"base_multiplier": 0.5,
		"detail_multiplier": 0.1,
		"feature_multiplier": 0.6,
		"roughness_factor": 0.4
	}

	# Forest biome: moderate variation
	_biome_modifiers["forest"] = {
		"base_multiplier": 0.8,
		"detail_multiplier": 0.4,
		"feature_multiplier": 0.3,
		"roughness_factor": 0.5
	}

	# Ocean biome: very smooth
	_biome_modifiers["ocean"] = {
		"base_multiplier": 0.3,
		"detail_multiplier": 0.1,
		"feature_multiplier": 0.1,
		"roughness_factor": 0.2
	}

	# Volcanic biome: very rough and jagged
	_biome_modifiers["volcanic"] = {
		"base_multiplier": 1.2,
		"detail_multiplier": 0.8,
		"feature_multiplier": 1.0,
		"roughness_factor": 0.9
	}

	# Barren biome: moderate roughness
	_biome_modifiers["barren"] = {
		"base_multiplier": 1.0,
		"detail_multiplier": 0.3,
		"feature_multiplier": 0.5,
		"roughness_factor": 0.6
	}

	# Toxic biome: bizarre formations
	_biome_modifiers["toxic"] = {
		"base_multiplier": 0.9,
		"detail_multiplier": 0.6,
		"feature_multiplier": 0.8,
		"roughness_factor": 0.7
	}


#region Height Sampling

## Generate height value for a given world position
## This is the main public interface for getting terrain height
func get_height(x: float, z: float, biome_name: String = "") -> float:
	"""
	Generate heightmap value from 2D coordinates (x, z).
	Returns height value scaled by amplitude.

	@param x: World X coordinate
	@param z: World Z coordinate (maps to Y in 2D noise space)
	@param biome_name: Optional biome name for biome-specific variations
	@return: Height value in world units
	"""
	# Check cache first
	var cache_key = _make_cache_key(x, z, biome_name)
	if _height_cache.has(cache_key):
		return _height_cache[cache_key]

	# Sample base noise
	var height = 0.0
	var base_value = _base_noise.get_noise_2d(x, z)
	base_value = (base_value + 1.0) * 0.5  # Normalize to [0, 1]
	height += base_value * _layer_weights[NoiseLayer.BASE]

	# Add detail layer
	if enable_detail:
		var detail_value = _detail_noise.get_noise_2d(x, z)
		detail_value = (detail_value + 1.0) * 0.5
		height += detail_value * _layer_weights[NoiseLayer.DETAIL]

	# Add feature layer
	if enable_features:
		var feature_value = _feature_noise.get_noise_2d(x, z)
		feature_value = (feature_value + 1.0) * 0.5
		height += feature_value * _layer_weights[NoiseLayer.FEATURES]

	# Add erosion layer
	if enable_erosion:
		var erosion_value = _erosion_noise.get_noise_2d(x, z)
		erosion_value = (erosion_value + 1.0) * 0.5
		height += erosion_value * _layer_weights[NoiseLayer.EROSION]

	# Add cave layer (subtractive)
	if enable_caves:
		var cave_value = _cave_noise.get_noise_2d(x, z)
		cave_value = (cave_value + 1.0) * 0.5
		# Only apply caves where value is above threshold
		if cave_value > 0.6:
			height += (cave_value - 0.6) * _layer_weights[NoiseLayer.CAVES]

	# Apply biome modifiers if specified
	if not biome_name.is_empty() and _biome_modifiers.has(biome_name):
		height = _apply_biome_modifier(height, x, z, biome_name)

	# Normalize and scale by amplitude
	height = clampf(height, 0.0, 1.0)
	var final_height = height * amplitude

	# Cache the result
	_cache_height(cache_key, final_height)

	height_sampled.emit(Vector2(x, z), final_height)
	return final_height


## Get normalized height (0-1 range) without amplitude scaling
func get_normalized_height(x: float, z: float, biome_name: String = "") -> float:
	"""
	Get height value normalized to [0, 1] range without amplitude scaling.
	Useful for blend calculations and material selection.
	"""
	return get_height(x, z, biome_name) / amplitude


## Sample 3D noise for caves and overhangs
func get_3d_noise(x: float, y: float, z: float) -> float:
	"""
	Sample 3D noise value for cave systems and overhangs.
	Returns value in [-1, 1] range.

	@param x: World X coordinate
	@param y: World Y coordinate (height)
	@param z: World Z coordinate
	@return: 3D noise value
	"""
	return _cave_noise.get_noise_3d(x, y, z)


## Apply biome-specific modifications to height
func _apply_biome_modifier(base_height: float, x: float, z: float, biome_name: String) -> float:
	"""Apply biome-specific height modifications."""
	var modifiers = _biome_modifiers[biome_name]

	var modified_height = base_height

	# Apply base multiplier
	modified_height *= modifiers["base_multiplier"]

	# Apply roughness factor by adding high-frequency variation
	var roughness = modifiers["roughness_factor"]
	if roughness > 0.0:
		var rough_noise = _detail_noise.get_noise_2d(x * 5.0, z * 5.0)
		rough_noise = (rough_noise + 1.0) * 0.5
		modified_height += rough_noise * roughness * 0.2

	return modified_height


#endregion


#region Heightmap Generation

## Generate a heightmap image for a region
func generate_heightmap(width: int, height: int, offset_x: float = 0.0,
						offset_z: float = 0.0, biome_name: String = "") -> Image:
	"""
	Generate a heightmap image for terrain rendering.

	@param width: Image width in pixels
	@param height: Image height in pixels
	@param offset_x: World X offset for the region
	@param offset_z: World Z offset for the region
	@param biome_name: Optional biome for specific characteristics
	@return: Heightmap image in FORMAT_RF (single-channel float)
	"""
	var heightmap = Image.create(width, height, false, Image.FORMAT_RF)

	for y in range(height):
		for x in range(width):
			var world_x = offset_x + float(x)
			var world_z = offset_z + float(y)

			var height_value = get_normalized_height(world_x, world_z, biome_name)
			heightmap.set_pixel(x, y, Color(height_value, height_value, height_value, 1.0))

	return heightmap


## Generate a heightmap with custom sampling scale
func generate_heightmap_scaled(width: int, height: int, scale: float,
							   offset_x: float = 0.0, offset_z: float = 0.0,
							   biome_name: String = "") -> Image:
	"""
	Generate a heightmap with custom sampling scale.
	Lower scale values = more zoomed out view.

	@param scale: Sampling scale (distance between samples)
	"""
	var heightmap = Image.create(width, height, false, Image.FORMAT_RF)

	for y in range(height):
		for x in range(width):
			var world_x = offset_x + float(x) * scale
			var world_z = offset_z + float(y) * scale

			var height_value = get_normalized_height(world_x, world_z, biome_name)
			heightmap.set_pixel(x, y, Color(height_value, height_value, height_value, 1.0))

	return heightmap

#endregion


#region Noise Layer Management

## Update a specific noise layer with current parameters
func _update_noise_layer(layer: NoiseLayer) -> void:
	"""Update a noise layer with current configuration parameters."""
	match layer:
		NoiseLayer.BASE:
			if _base_noise:
				_base_noise.frequency = base_frequency
				_base_noise.fractal_octaves = octaves
				_base_noise.fractal_gain = base_persistence
				_base_noise.fractal_lacunarity = base_lacunarity

		NoiseLayer.DETAIL:
			if _detail_noise:
				_detail_noise.frequency = detail_frequency
				_detail_noise.fractal_octaves = maxi(octaves - 2, 2)
				_detail_noise.fractal_gain = detail_persistence
				_detail_noise.fractal_lacunarity = detail_lacunarity

		NoiseLayer.FEATURES:
			if _feature_noise:
				_feature_noise.frequency = feature_frequency
				_feature_noise.fractal_octaves = maxi(octaves - 1, 2)
				_feature_noise.fractal_gain = feature_persistence
				_feature_noise.fractal_lacunarity = feature_lacunarity

	noise_parameters_changed.emit(layer)
	_clear_cache()  # Clear cache when parameters change


## Update all noise layers
func _update_all_noise_layers() -> void:
	"""Update all noise layers with current parameters."""
	for layer in NoiseLayer.values():
		_update_noise_layer(layer)


## Set layer weight for noise combination
func set_layer_weight(layer: NoiseLayer, weight: float) -> void:
	"""
	Set the weight of a specific noise layer in the final height calculation.
	Higher weight = more influence on final height.
	"""
	_layer_weights[layer] = weight
	_clear_cache()


## Get layer weight
func get_layer_weight(layer: NoiseLayer) -> float:
	"""Get the current weight of a noise layer."""
	return _layer_weights.get(layer, 0.0)

#endregion


#region Preset Management

## Apply a noise preset configuration
func apply_preset(preset: NoisePreset) -> void:
	"""
	Apply a noise preset for specific terrain characteristics.
	Configures all noise layers according to preset.
	"""
	match preset:
		NoisePreset.SMOOTH_HILLS:
			base_frequency = 0.003
			detail_frequency = 0.015
			feature_frequency = 0.008
			octaves = 4
			base_persistence = 0.5
			detail_persistence = 0.3
			_layer_weights[NoiseLayer.BASE] = 1.0
			_layer_weights[NoiseLayer.DETAIL] = 0.2
			_layer_weights[NoiseLayer.FEATURES] = 0.3
			enable_erosion = false
			enable_caves = false

		NoisePreset.ROUGH_MOUNTAINS:
			base_frequency = 0.004
			detail_frequency = 0.025
			feature_frequency = 0.012
			octaves = 6
			base_persistence = 0.6
			detail_persistence = 0.5
			_layer_weights[NoiseLayer.BASE] = 1.2
			_layer_weights[NoiseLayer.DETAIL] = 0.5
			_layer_weights[NoiseLayer.FEATURES] = 0.6
			enable_erosion = true
			enable_caves = false

		NoisePreset.FLAT_PLAINS:
			base_frequency = 0.002
			detail_frequency = 0.01
			feature_frequency = 0.005
			octaves = 3
			base_persistence = 0.4
			detail_persistence = 0.2
			_layer_weights[NoiseLayer.BASE] = 0.6
			_layer_weights[NoiseLayer.DETAIL] = 0.1
			_layer_weights[NoiseLayer.FEATURES] = 0.2
			enable_erosion = false
			enable_caves = false

		NoisePreset.ALIEN_BIZARRE:
			base_frequency = 0.008
			detail_frequency = 0.035
			feature_frequency = 0.018
			octaves = 5
			base_persistence = 0.7
			detail_persistence = 0.6
			_layer_weights[NoiseLayer.BASE] = 1.0
			_layer_weights[NoiseLayer.DETAIL] = 0.7
			_layer_weights[NoiseLayer.FEATURES] = 0.8
			enable_erosion = true
			enable_caves = true

		NoisePreset.CANYON_RIDGES:
			base_frequency = 0.005
			detail_frequency = 0.02
			feature_frequency = 0.01
			octaves = 5
			base_fractal_type = FastNoiseLite.FRACTAL_RIDGED
			detail_fractal_type = FastNoiseLite.FRACTAL_RIDGED
			_layer_weights[NoiseLayer.BASE] = 1.1
			_layer_weights[NoiseLayer.DETAIL] = 0.4
			_layer_weights[NoiseLayer.FEATURES] = 0.5
			enable_erosion = true
			enable_caves = false

		NoisePreset.VOLCANIC_ROUGH:
			base_frequency = 0.006
			detail_frequency = 0.03
			feature_frequency = 0.015
			octaves = 6
			base_persistence = 0.65
			detail_persistence = 0.55
			_layer_weights[NoiseLayer.BASE] = 1.15
			_layer_weights[NoiseLayer.DETAIL] = 0.6
			_layer_weights[NoiseLayer.FEATURES] = 0.7
			enable_erosion = true
			enable_caves = true

	_update_all_noise_layers()


#endregion


#region Seed Management

## Set seed for all noise generators
func _set_all_seeds() -> void:
	"""Set deterministic seeds for all noise generators."""
	_current_seed = noise_seed

	if _base_noise:
		_base_noise.seed = _current_seed
	if _detail_noise:
		_detail_noise.seed = _current_seed + HASH_PRIME_1
	if _feature_noise:
		_feature_noise.seed = _current_seed + HASH_PRIME_2
	if _erosion_noise:
		_erosion_noise.seed = _current_seed + HASH_PRIME_3
	if _cave_noise:
		_cave_noise.seed = _current_seed + HASH_PRIME_4

	_clear_cache()


## Set seed (public interface)
func set_seed(seed_value: int) -> void:
	"""Set the seed for deterministic terrain generation."""
	noise_seed = seed_value

#endregion


#region Cache Management

## Create cache key for height lookup
func _make_cache_key(x: float, z: float, biome_name: String) -> String:
	"""Create a cache key for height lookup."""
	return "%.2f_%.2f_%s" % [x, z, biome_name]


## Cache a height value
func _cache_height(key: String, height: float) -> void:
	"""Cache a height value with size limit."""
	if _height_cache.size() >= _max_cache_size:
		# Remove oldest entry (first key)
		var first_key = _height_cache.keys()[0]
		_height_cache.erase(first_key)

	_height_cache[key] = height


## Clear the height cache
func _clear_cache() -> void:
	"""Clear the height cache."""
	_height_cache.clear()


## Set maximum cache size
func set_cache_size(size: int) -> void:
	"""Set the maximum cache size."""
	_max_cache_size = maxi(size, 10)

#endregion


#region Configuration Methods

## Get current configuration as dictionary
func get_configuration() -> Dictionary:
	"""Get current noise generator configuration."""
	return {
		"base_frequency": base_frequency,
		"detail_frequency": detail_frequency,
		"feature_frequency": feature_frequency,
		"octaves": octaves,
		"amplitude": amplitude,
		"seed": noise_seed,
		"enable_detail": enable_detail,
		"enable_features": enable_features,
		"enable_erosion": enable_erosion,
		"enable_caves": enable_caves,
		"layer_weights": _layer_weights.duplicate(),
		"cache_size": _height_cache.size()
	}


## Configure from dictionary
func configure(config: Dictionary) -> void:
	"""Configure noise generator from a dictionary."""
	if config.has("base_frequency"):
		base_frequency = config["base_frequency"]
	if config.has("detail_frequency"):
		detail_frequency = config["detail_frequency"]
	if config.has("feature_frequency"):
		feature_frequency = config["feature_frequency"]
	if config.has("octaves"):
		octaves = config["octaves"]
	if config.has("amplitude"):
		amplitude = config["amplitude"]
	if config.has("seed"):
		noise_seed = config["seed"]
	if config.has("enable_detail"):
		enable_detail = config["enable_detail"]
	if config.has("enable_features"):
		enable_features = config["enable_features"]
	if config.has("enable_erosion"):
		enable_erosion = config["enable_erosion"]
	if config.has("enable_caves"):
		enable_caves = config["enable_caves"]

	_update_all_noise_layers()


## Configure biome modifier
func configure_biome(biome_name: String, modifiers: Dictionary) -> void:
	"""
	Configure or update biome-specific noise modifiers.

	@param biome_name: Name of the biome
	@param modifiers: Dictionary with keys: base_multiplier, detail_multiplier,
	                  feature_multiplier, roughness_factor
	"""
	_biome_modifiers[biome_name] = modifiers
	_clear_cache()
	layer_configured.emit(biome_name, modifiers)


## Get biome configuration
func get_biome_configuration(biome_name: String) -> Dictionary:
	"""Get the current configuration for a biome."""
	return _biome_modifiers.get(biome_name, {})

#endregion


#region Utility Methods

## Validate deterministic generation
func validate_determinism(test_positions: int = 100) -> bool:
	"""
	Validate that noise generation is deterministic.
	Generates height values twice and compares them.

	@param test_positions: Number of random positions to test
	@return: true if all values match
	"""
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345  # Fixed seed for test

	# Save current seed
	var original_seed = noise_seed

	# Generate first set
	noise_seed = 42
	var heights1: Array[float] = []

	for i in range(test_positions):
		var x = rng.randf_range(-1000.0, 1000.0)
		var z = rng.randf_range(-1000.0, 1000.0)
		heights1.append(get_height(x, z))

	# Clear cache and regenerate
	_clear_cache()
	noise_seed = 42

	var heights2: Array[float] = []
	rng.seed = 12345  # Reset RNG to same positions

	for i in range(test_positions):
		var x = rng.randf_range(-1000.0, 1000.0)
		var z = rng.randf_range(-1000.0, 1000.0)
		heights2.append(get_height(x, z))

	# Compare
	for i in range(test_positions):
		if absf(heights1[i] - heights2[i]) > 0.0001:
			noise_seed = original_seed  # Restore
			return false

	noise_seed = original_seed  # Restore
	return true


## Get noise statistics for a region
func get_region_statistics(width: int, height: int, offset_x: float = 0.0,
						   offset_z: float = 0.0) -> Dictionary:
	"""
	Calculate statistics for a region of terrain.

	@return: Dictionary with min, max, mean, and standard deviation
	"""
	var heights: Array[float] = []
	var min_height = INF
	var max_height = -INF
	var sum_height = 0.0

	for y in range(height):
		for x in range(width):
			var world_x = offset_x + float(x)
			var world_z = offset_z + float(y)
			var h = get_height(world_x, world_z)

			heights.append(h)
			min_height = minf(min_height, h)
			max_height = maxf(max_height, h)
			sum_height += h

	var count = heights.size()
	var mean = sum_height / count

	# Calculate standard deviation
	var variance_sum = 0.0
	for h in heights:
		variance_sum += (h - mean) * (h - mean)
	var std_dev = sqrt(variance_sum / count)

	return {
		"min_height": min_height,
		"max_height": max_height,
		"mean_height": mean,
		"std_deviation": std_dev,
		"range": max_height - min_height
	}

#endregion
