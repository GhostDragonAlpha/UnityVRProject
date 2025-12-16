## BiomeSystem - Biome Distribution and Environmental Effects
## Manages biome assignment, blending, and environmental effects for planets.
##
## Requirements: 56.1, 56.2, 56.3, 56.4, 56.5
## - 56.1: Assign biome types based on distance from star and planet properties
## - 56.2: Display distinct visual characteristics (ice, desert, forest, ocean, volcanic)
## - 56.3: Blend terrain features and colors smoothly at biome transitions
## - 56.4: Apply appropriate environmental effects per biome (snow, rain, dust storms)
## - 56.5: Display a biome map showing the distribution of environments
extends Node
class_name BiomeSystem

## Emitted when a biome map is generated
signal biome_map_generated(biome_map: Image, planet_seed: int)
## Emitted when environmental effects change
signal environmental_effect_changed(biome: BiomeType, effect: EnvironmentalEffect)
## Emitted when biome is determined at a position
signal biome_determined(position: Vector2, biome: BiomeType)

## Biome type enumeration matching design document
## Requirement 56.2: Distinct visual characteristics
enum BiomeType {
	ICE,       # Frozen regions with snow and ice
	DESERT,    # Arid regions with sand and rock
	FOREST,    # Vegetated regions with trees
	OCEAN,     # Water bodies
	VOLCANIC,  # Active volcanic regions with lava
	BARREN,    # Rocky, lifeless terrain
	TOXIC      # Hazardous chemical environments
}

## Environmental effect types
## Requirement 56.4: Environmental effects per biome
enum EnvironmentalEffect {
	NONE,
	SNOW,
	RAIN,
	DUST_STORM,
	ASH_FALL,
	TOXIC_FOG,
	BLIZZARD,
	SANDSTORM
}

## Biome visual properties structure
const BIOME_PROPERTIES: Dictionary = {
	BiomeType.ICE: {
		"name": "Ice",
		"base_color": Color(0.9, 0.95, 1.0),
		"secondary_color": Color(0.7, 0.85, 0.95),
		"roughness": 0.3,
		"metallic": 0.1,
		"effects": [EnvironmentalEffect.SNOW, EnvironmentalEffect.BLIZZARD],
		"effect_probability": 0.4,
		"temperature_range": Vector2(-60.0, -10.0),
		"detail_types": ["ice_spike", "snow_mound", "glacier"]
	},
	BiomeType.DESERT: {
		"name": "Desert",
		"base_color": Color(0.9, 0.8, 0.5),
		"secondary_color": Color(0.85, 0.7, 0.4),
		"roughness": 0.9,
		"metallic": 0.0,
		"effects": [EnvironmentalEffect.DUST_STORM, EnvironmentalEffect.SANDSTORM],
		"effect_probability": 0.3,
		"temperature_range": Vector2(20.0, 55.0),
		"detail_types": ["rock", "cactus", "dune", "boulder"]
	},
	BiomeType.FOREST: {
		"name": "Forest",
		"base_color": Color(0.2, 0.5, 0.2),
		"secondary_color": Color(0.3, 0.6, 0.25),
		"roughness": 0.7,
		"metallic": 0.0,
		"effects": [EnvironmentalEffect.RAIN],
		"effect_probability": 0.5,
		"temperature_range": Vector2(5.0, 30.0),
		"detail_types": ["tree", "bush", "rock", "grass", "flower"]
	},
	BiomeType.OCEAN: {
		"name": "Ocean",
		"base_color": Color(0.1, 0.3, 0.6),
		"secondary_color": Color(0.15, 0.4, 0.7),
		"roughness": 0.1,
		"metallic": 0.2,
		"effects": [EnvironmentalEffect.RAIN],
		"effect_probability": 0.6,
		"temperature_range": Vector2(-5.0, 35.0),
		"detail_types": []
	},
	BiomeType.VOLCANIC: {
		"name": "Volcanic",
		"base_color": Color(0.3, 0.1, 0.05),
		"secondary_color": Color(0.8, 0.3, 0.1),
		"roughness": 0.8,
		"metallic": 0.3,
		"effects": [EnvironmentalEffect.ASH_FALL],
		"effect_probability": 0.7,
		"temperature_range": Vector2(40.0, 200.0),
		"detail_types": ["rock", "lava_rock", "vent", "crater"]
	},
	BiomeType.BARREN: {
		"name": "Barren",
		"base_color": Color(0.5, 0.45, 0.4),
		"secondary_color": Color(0.45, 0.4, 0.35),
		"roughness": 0.85,
		"metallic": 0.1,
		"effects": [EnvironmentalEffect.DUST_STORM],
		"effect_probability": 0.2,
		"temperature_range": Vector2(-30.0, 50.0),
		"detail_types": ["rock", "boulder", "pebbles", "crater"]
	},
	BiomeType.TOXIC: {
		"name": "Toxic",
		"base_color": Color(0.4, 0.5, 0.2),
		"secondary_color": Color(0.5, 0.6, 0.1),
		"roughness": 0.6,
		"metallic": 0.2,
		"effects": [EnvironmentalEffect.TOXIC_FOG],
		"effect_probability": 0.8,
		"temperature_range": Vector2(10.0, 80.0),
		"detail_types": ["crystal", "fungus", "rock", "pool"]
	}
}

## Prime numbers for hash functions (deterministic generation)
const HASH_PRIME_1: int = 73856093
const HASH_PRIME_2: int = 19349663
const HASH_PRIME_3: int = 83492791

## Blend distance for biome transitions (in normalized coordinates 0-1)
## Requirement 56.3: Smooth blending at boundaries
const BIOME_BLEND_DISTANCE: float = 0.05

## Default biome map resolution
const DEFAULT_BIOME_MAP_RESOLUTION: int = 256

#region Configuration Properties

## Distance from star in AU (affects temperature)
## Requirement 56.1: Assign biomes based on distance from star
@export var star_distance: float = 1.0:
	set(value):
		star_distance = maxf(value, 0.1)

## Planet base temperature modifier (-1 to 1)
@export var temperature_modifier: float = 0.0:
	set(value):
		temperature_modifier = clampf(value, -1.0, 1.0)

## Planet moisture level (0 to 1)
@export var moisture_level: float = 0.5:
	set(value):
		moisture_level = clampf(value, 0.0, 1.0)

## Planet atmosphere density (affects weather)
@export var atmosphere_density: float = 1.0:
	set(value):
		atmosphere_density = clampf(value, 0.0, 2.0)

## Whether environmental effects are enabled
@export var effects_enabled: bool = true

#endregion

#region Runtime Properties

## FastNoiseLite for biome distribution
var _biome_noise: FastNoiseLite = null

## FastNoiseLite for temperature variation
var _temperature_noise: FastNoiseLite = null

## FastNoiseLite for moisture variation
var _moisture_noise: FastNoiseLite = null

## Current planet seed
var _current_seed: int = 0

## Cache for biome maps
var _biome_map_cache: Dictionary = {}

## Maximum cache size
var _max_cache_size: int = 5

## Current active environmental effect
var _current_effect: EnvironmentalEffect = EnvironmentalEffect.NONE

## Random number generator for effects
var _effect_rng: RandomNumberGenerator = null

#endregion


func _ready() -> void:
	_initialize_noise_generators()
	_effect_rng = RandomNumberGenerator.new()


## Initialize noise generators for biome distribution
func _initialize_noise_generators() -> void:
	"""Initialize FastNoiseLite instances for biome generation."""
	_biome_noise = FastNoiseLite.new()
	_biome_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	_biome_noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	_biome_noise.frequency = 0.003
	
	_temperature_noise = FastNoiseLite.new()
	_temperature_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_temperature_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_temperature_noise.fractal_octaves = 4
	_temperature_noise.frequency = 0.002
	
	_moisture_noise = FastNoiseLite.new()
	_moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_moisture_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_moisture_noise.fractal_octaves = 3
	_moisture_noise.frequency = 0.004


#region Biome Assignment

## Determine biome type at a position based on planet properties
## Requirement 56.1: Assign biomes based on distance from star and planet properties
func determine_biome(planet_seed: int, x: float, y: float, height: float) -> BiomeType:
	"""Determine the biome type at a given position."""
	_set_seed(planet_seed)
	
	# Calculate local temperature based on star distance and position
	var base_temperature = _calculate_base_temperature()
	var local_temperature = _calculate_local_temperature(x, y, height, base_temperature)
	
	# Calculate local moisture
	var local_moisture = _calculate_local_moisture(x, y, height)
	
	# Determine biome from temperature, moisture, and height
	var biome = _select_biome(local_temperature, local_moisture, height)
	
	biome_determined.emit(Vector2(x, y), biome)
	return biome


## Calculate base temperature from star distance
## Requirement 56.1: Distance from star affects biome assignment
func _calculate_base_temperature() -> float:
	"""Calculate base planet temperature from star distance."""
	# Inverse square law for stellar radiation
	# Earth at 1 AU has average temp ~15°C
	var base_temp = 288.0 / (star_distance * star_distance)  # Kelvin approximation
	
	# Convert to normalized temperature (0-1 range)
	# 0 = very cold (-100°C), 1 = very hot (100°C)
	var celsius = base_temp - 273.15
	var normalized = (celsius + 100.0) / 200.0
	
	# Apply planet modifier
	normalized += temperature_modifier * 0.3
	
	return clampf(normalized, 0.0, 1.0)


## Calculate local temperature at a position
func _calculate_local_temperature(x: float, y: float, height: float, base_temp: float) -> float:
	"""Calculate temperature at a specific position."""
	# Temperature variation from noise
	var noise_variation = _temperature_noise.get_noise_2d(x, y)
	noise_variation = (noise_variation + 1.0) * 0.5  # Normalize to 0-1
	
	# Height affects temperature (higher = colder)
	var height_factor = 1.0 - (height * 0.4)
	
	# Combine factors
	var local_temp = base_temp * height_factor
	local_temp += (noise_variation - 0.5) * 0.2  # Add variation
	
	return clampf(local_temp, 0.0, 1.0)


## Calculate local moisture at a position
func _calculate_local_moisture(x: float, y: float, height: float) -> float:
	"""Calculate moisture level at a specific position."""
	# Base moisture from planet property
	var base_moisture = moisture_level
	
	# Moisture variation from noise
	var noise_variation = _moisture_noise.get_noise_2d(x, y)
	noise_variation = (noise_variation + 1.0) * 0.5  # Normalize to 0-1
	
	# Low areas tend to be wetter
	var height_factor = 1.0 - (height * 0.3)
	
	# Combine factors
	var local_moisture = base_moisture * height_factor
	local_moisture += (noise_variation - 0.5) * 0.3
	
	return clampf(local_moisture, 0.0, 1.0)


## Select biome based on temperature, moisture, and height
## Requirement 56.2: Distinct visual characteristics
func _select_biome(temperature: float, moisture: float, height: float) -> BiomeType:
	"""Select appropriate biome based on environmental factors."""
	# Ocean: low height and sufficient moisture
	if height < 0.25 and moisture > 0.4:
		return BiomeType.OCEAN
	
	# Ice: very cold temperatures
	if temperature < 0.2:
		return BiomeType.ICE
	
	# Volcanic: very high temperature and low moisture
	if temperature > 0.85 and moisture < 0.3:
		return BiomeType.VOLCANIC
	
	# High altitude: barren or ice
	if height > 0.8:
		if temperature < 0.4:
			return BiomeType.ICE
		else:
			return BiomeType.BARREN
	
	# Desert: hot and dry
	if temperature > 0.6 and moisture < 0.25:
		return BiomeType.DESERT
	
	# Forest: moderate temperature and good moisture
	if temperature > 0.3 and temperature < 0.7 and moisture > 0.5:
		return BiomeType.FOREST
	
	# Toxic: specific conditions (moderate temp, low-mid moisture, mid height)
	if temperature > 0.4 and temperature < 0.7 and moisture > 0.2 and moisture < 0.5:
		if height > 0.3 and height < 0.6:
			# Use biome noise for toxic distribution
			var toxic_chance = _biome_noise.get_noise_2d(temperature * 1000, moisture * 1000)
			if toxic_chance > 0.3:
				return BiomeType.TOXIC
	
	# Default: barren
	return BiomeType.BARREN

#endregion


#region Biome Blending

## Get blended biome color at a position
## Requirement 56.3: Blend terrain features and colors smoothly
func get_blended_color(planet_seed: int, x: float, y: float, height: float) -> Color:
	"""Get the blended biome color at a position, accounting for nearby biomes."""
	_set_seed(planet_seed)
	
	# Get the primary biome at this position
	var primary_biome = determine_biome(planet_seed, x, y, height)
	var primary_color = get_biome_color(primary_biome)
	
	# Sample nearby positions to find neighboring biomes
	var sample_offsets = [
		Vector2(-BIOME_BLEND_DISTANCE, 0),
		Vector2(BIOME_BLEND_DISTANCE, 0),
		Vector2(0, -BIOME_BLEND_DISTANCE),
		Vector2(0, BIOME_BLEND_DISTANCE)
	]
	
	var blend_color = primary_color
	var blend_count = 1.0
	
	for offset in sample_offsets:
		var sample_x = x + offset.x * 100.0  # Scale offset to world coordinates
		var sample_y = y + offset.y * 100.0
		var sample_biome = determine_biome(planet_seed, sample_x, sample_y, height)
		
		if sample_biome != primary_biome:
			# Calculate blend weight based on distance
			var neighbor_color = get_biome_color(sample_biome)
			var blend_weight = 0.3  # Blend factor for neighboring biomes
			blend_color = blend_color.lerp(neighbor_color, blend_weight / (blend_count + 1))
			blend_count += blend_weight
	
	return blend_color


## Calculate biome blend factor between two positions
## Requirement 56.3: Smooth blending at boundaries
func calculate_blend_factor(planet_seed: int, x1: float, y1: float, x2: float, y2: float, 
							height: float) -> float:
	"""Calculate the blend factor between two positions (0 = same biome, 1 = different)."""
	var biome1 = determine_biome(planet_seed, x1, y1, height)
	var biome2 = determine_biome(planet_seed, x2, y2, height)
	
	if biome1 == biome2:
		return 0.0
	
	# Calculate distance-based blend
	var distance = sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
	var blend_zone = BIOME_BLEND_DISTANCE * 100.0  # Convert to world units
	
	return clampf(distance / blend_zone, 0.0, 1.0)


## Get interpolated biome properties at a position
func get_interpolated_properties(planet_seed: int, x: float, y: float, height: float) -> Dictionary:
	"""Get interpolated biome properties for smooth transitions."""
	_set_seed(planet_seed)
	
	var primary_biome = determine_biome(planet_seed, x, y, height)
	var props = BIOME_PROPERTIES[primary_biome].duplicate()
	
	# Sample neighbors for blending
	var neighbors: Array[BiomeType] = []
	var sample_dist = BIOME_BLEND_DISTANCE * 50.0
	
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var nx = x + dx * sample_dist
			var ny = y + dy * sample_dist
			var neighbor_biome = determine_biome(planet_seed, nx, ny, height)
			if neighbor_biome != primary_biome and not neighbors.has(neighbor_biome):
				neighbors.append(neighbor_biome)
	
	# Blend properties with neighbors
	if neighbors.size() > 0:
		var blend_weight = 0.2 / neighbors.size()
		for neighbor in neighbors:
			var neighbor_props = BIOME_PROPERTIES[neighbor]
			props["base_color"] = props["base_color"].lerp(neighbor_props["base_color"], blend_weight)
			props["secondary_color"] = props["secondary_color"].lerp(neighbor_props["secondary_color"], blend_weight)
			props["roughness"] = lerpf(props["roughness"], neighbor_props["roughness"], blend_weight)
			props["metallic"] = lerpf(props["metallic"], neighbor_props["metallic"], blend_weight)
	
	return props

#endregion


#region Biome Map Generation

## Generate a biome map for a planet
## Requirement 56.5: Display a biome map showing distribution of environments
func generate_biome_map(planet_seed: int, heightmap: Image, 
						resolution: int = DEFAULT_BIOME_MAP_RESOLUTION) -> Image:
	"""Generate a biome distribution map for a planet."""
	# Check cache first
	var cache_key = _make_cache_key(planet_seed, resolution)
	if _biome_map_cache.has(cache_key):
		return _biome_map_cache[cache_key]
	
	_set_seed(planet_seed)
	
	# Resize heightmap if needed
	var working_heightmap = heightmap
	if heightmap.get_width() != resolution:
		working_heightmap = heightmap.duplicate()
		working_heightmap.resize(resolution, resolution, Image.INTERPOLATE_BILINEAR)
	
	# Create biome map image
	var biome_map = Image.create(resolution, resolution, false, Image.FORMAT_RGB8)
	
	for y in range(resolution):
		for x in range(resolution):
			var height = working_heightmap.get_pixel(x, y).r
			var biome = determine_biome(planet_seed, float(x), float(y), height)
			var color = get_biome_color(biome)
			biome_map.set_pixel(x, y, color)
	
	# Apply blending pass for smooth transitions
	biome_map = _apply_biome_blending(biome_map, working_heightmap, planet_seed)
	
	# Cache the result
	_cache_biome_map(cache_key, biome_map)
	
	biome_map_generated.emit(biome_map, planet_seed)
	return biome_map


## Apply blending pass to biome map
## Requirement 56.3: Smooth blending at boundaries
func _apply_biome_blending(biome_map: Image, heightmap: Image, planet_seed: int) -> Image:
	"""Apply a blending pass to smooth biome transitions."""
	var resolution = biome_map.get_width()
	var blended_map = Image.create(resolution, resolution, false, Image.FORMAT_RGB8)
	
	var kernel_size = int(BIOME_BLEND_DISTANCE * resolution)
	kernel_size = maxi(kernel_size, 1)
	
	for y in range(resolution):
		for x in range(resolution):
			var center_color = biome_map.get_pixel(x, y)
			var blended_color = center_color
			var weight_sum = 1.0
			
			# Sample neighboring pixels
			for ky in range(-kernel_size, kernel_size + 1):
				for kx in range(-kernel_size, kernel_size + 1):
					if kx == 0 and ky == 0:
						continue
					
					var nx = clampi(x + kx, 0, resolution - 1)
					var ny = clampi(y + ky, 0, resolution - 1)
					var neighbor_color = biome_map.get_pixel(nx, ny)
					
					# Distance-based weight
					var dist = sqrt(kx * kx + ky * ky)
					var weight = 1.0 / (1.0 + dist)
					
					blended_color = blended_color.lerp(neighbor_color, weight / (weight_sum + weight))
					weight_sum += weight
			
			blended_map.set_pixel(x, y, blended_color)
	
	return blended_map


## Generate a detailed biome map with legend
func generate_biome_map_with_legend(planet_seed: int, heightmap: Image,
									resolution: int = DEFAULT_BIOME_MAP_RESOLUTION) -> Dictionary:
	"""Generate a biome map with additional metadata."""
	var biome_map = generate_biome_map(planet_seed, heightmap, resolution)
	
	# Count biome distribution
	var biome_counts: Dictionary = {}
	for biome in BiomeType.values():
		biome_counts[biome] = 0
	
	for y in range(resolution):
		for x in range(resolution):
			var height = heightmap.get_pixel(x, y).r
			var biome = determine_biome(planet_seed, float(x), float(y), height)
			biome_counts[biome] += 1
	
	# Calculate percentages
	var total_pixels = resolution * resolution
	var biome_percentages: Dictionary = {}
	for biome in biome_counts:
		biome_percentages[biome] = float(biome_counts[biome]) / total_pixels * 100.0
	
	return {
		"biome_map": biome_map,
		"biome_counts": biome_counts,
		"biome_percentages": biome_percentages,
		"resolution": resolution,
		"planet_seed": planet_seed
	}

#endregion


#region Environmental Effects

## Get environmental effect for a biome
## Requirement 56.4: Apply appropriate environmental effects per biome
func get_environmental_effect(biome: BiomeType) -> EnvironmentalEffect:
	"""Get a random environmental effect appropriate for the biome."""
	if not effects_enabled:
		return EnvironmentalEffect.NONE
	
	var props = BIOME_PROPERTIES[biome]
	var effects: Array = props["effects"]
	var probability: float = props["effect_probability"]
	
	# Check if effect should occur based on atmosphere density
	var adjusted_probability = probability * atmosphere_density
	
	if _effect_rng.randf() > adjusted_probability:
		return EnvironmentalEffect.NONE
	
	if effects.is_empty():
		return EnvironmentalEffect.NONE
	
	# Select random effect from available effects
	var effect_index = _effect_rng.randi() % effects.size()
	return effects[effect_index]


## Update environmental effect for current position
func update_environmental_effect(planet_seed: int, x: float, y: float, height: float) -> EnvironmentalEffect:
	"""Update and return the current environmental effect."""
	_effect_rng.seed = planet_seed + int(x * 100) + int(y * 100)
	
	var biome = determine_biome(planet_seed, x, y, height)
	var new_effect = get_environmental_effect(biome)
	
	if new_effect != _current_effect:
		_current_effect = new_effect
		environmental_effect_changed.emit(biome, new_effect)
	
	return _current_effect


## Get effect properties for rendering
func get_effect_properties(effect: EnvironmentalEffect) -> Dictionary:
	"""Get rendering properties for an environmental effect."""
	match effect:
		EnvironmentalEffect.NONE:
			return {"intensity": 0.0, "particle_type": "", "visibility_reduction": 0.0}
		EnvironmentalEffect.SNOW:
			return {
				"intensity": 0.6,
				"particle_type": "snow",
				"visibility_reduction": 0.2,
				"particle_color": Color(1.0, 1.0, 1.0, 0.8),
				"particle_size": 0.02,
				"fall_speed": 2.0
			}
		EnvironmentalEffect.RAIN:
			return {
				"intensity": 0.7,
				"particle_type": "rain",
				"visibility_reduction": 0.3,
				"particle_color": Color(0.7, 0.8, 0.9, 0.6),
				"particle_size": 0.01,
				"fall_speed": 10.0
			}
		EnvironmentalEffect.DUST_STORM:
			return {
				"intensity": 0.8,
				"particle_type": "dust",
				"visibility_reduction": 0.6,
				"particle_color": Color(0.8, 0.7, 0.5, 0.5),
				"particle_size": 0.005,
				"fall_speed": 0.5
			}
		EnvironmentalEffect.ASH_FALL:
			return {
				"intensity": 0.5,
				"particle_type": "ash",
				"visibility_reduction": 0.4,
				"particle_color": Color(0.3, 0.3, 0.3, 0.7),
				"particle_size": 0.015,
				"fall_speed": 1.5
			}
		EnvironmentalEffect.TOXIC_FOG:
			return {
				"intensity": 0.9,
				"particle_type": "fog",
				"visibility_reduction": 0.7,
				"particle_color": Color(0.5, 0.6, 0.2, 0.4),
				"particle_size": 0.1,
				"fall_speed": 0.1
			}
		EnvironmentalEffect.BLIZZARD:
			return {
				"intensity": 1.0,
				"particle_type": "snow",
				"visibility_reduction": 0.8,
				"particle_color": Color(1.0, 1.0, 1.0, 0.9),
				"particle_size": 0.03,
				"fall_speed": 5.0
			}
		EnvironmentalEffect.SANDSTORM:
			return {
				"intensity": 1.0,
				"particle_type": "sand",
				"visibility_reduction": 0.9,
				"particle_color": Color(0.9, 0.8, 0.5, 0.7),
				"particle_size": 0.008,
				"fall_speed": 1.0
			}
	
	return {"intensity": 0.0, "particle_type": "", "visibility_reduction": 0.0}

#endregion


#region Biome Colors and Properties

## Get base color for a biome type
## Requirement 56.2: Distinct visual characteristics
func get_biome_color(biome: BiomeType) -> Color:
	"""Get the base color for a biome type."""
	if BIOME_PROPERTIES.has(biome):
		return BIOME_PROPERTIES[biome]["base_color"]
	return Color(0.5, 0.5, 0.5)


## Get secondary color for a biome type
func get_biome_secondary_color(biome: BiomeType) -> Color:
	"""Get the secondary color for a biome type."""
	if BIOME_PROPERTIES.has(biome):
		return BIOME_PROPERTIES[biome]["secondary_color"]
	return Color(0.4, 0.4, 0.4)


## Get biome name
func get_biome_name(biome: BiomeType) -> String:
	"""Get the display name for a biome type."""
	if BIOME_PROPERTIES.has(biome):
		return BIOME_PROPERTIES[biome]["name"]
	return "Unknown"


## Get material properties for a biome
func get_biome_material_properties(biome: BiomeType) -> Dictionary:
	"""Get PBR material properties for a biome."""
	if BIOME_PROPERTIES.has(biome):
		var props = BIOME_PROPERTIES[biome]
		return {
			"albedo": props["base_color"],
			"roughness": props["roughness"],
			"metallic": props["metallic"]
		}
	return {
		"albedo": Color(0.5, 0.5, 0.5),
		"roughness": 0.8,
		"metallic": 0.0
	}


## Get detail types for a biome
func get_biome_detail_types(biome: BiomeType) -> Array:
	"""Get the types of surface details appropriate for a biome."""
	if BIOME_PROPERTIES.has(biome):
		return BIOME_PROPERTIES[biome]["detail_types"]
	return []


## Create a StandardMaterial3D for a biome
func create_biome_material(biome: BiomeType) -> StandardMaterial3D:
	"""Create a PBR material configured for a biome."""
	var material = StandardMaterial3D.new()
	var props = get_biome_material_properties(biome)
	
	material.albedo_color = props["albedo"]
	material.roughness = props["roughness"]
	material.metallic = props["metallic"]
	
	# Add some variation
	material.vertex_color_use_as_albedo = true
	
	return material

#endregion


#region Seed and Cache Management

## Set the seed for noise generators
func _set_seed(seed_value: int) -> void:
	"""Set the seed for deterministic generation."""
	if _current_seed == seed_value:
		return
	
	_current_seed = seed_value
	
	if _biome_noise:
		_biome_noise.seed = seed_value
	if _temperature_noise:
		_temperature_noise.seed = seed_value + HASH_PRIME_1
	if _moisture_noise:
		_moisture_noise.seed = seed_value + HASH_PRIME_2


## Create a cache key
func _make_cache_key(planet_seed: int, resolution: int) -> String:
	"""Create a unique cache key."""
	return "%d_%d_%.2f_%.2f" % [planet_seed, resolution, star_distance, moisture_level]


## Cache a biome map
func _cache_biome_map(key: String, biome_map: Image) -> void:
	"""Cache a biome map, evicting old entries if necessary."""
	if _biome_map_cache.size() >= _max_cache_size:
		var first_key = _biome_map_cache.keys()[0]
		_biome_map_cache.erase(first_key)
	
	_biome_map_cache[key] = biome_map


## Clear the biome map cache
func clear_cache() -> void:
	"""Clear the biome map cache."""
	_biome_map_cache.clear()


## Set maximum cache size
func set_max_cache_size(size: int) -> void:
	"""Set the maximum cache size."""
	_max_cache_size = maxi(size, 1)

#endregion


#region Configuration Methods

## Configure planet properties
## Requirement 56.1: Assign biomes based on distance from star and planet properties
func configure_planet(distance_from_star: float, temp_modifier: float = 0.0,
					  moisture: float = 0.5, atmosphere: float = 1.0) -> void:
	"""Configure planet properties for biome generation."""
	star_distance = distance_from_star
	temperature_modifier = temp_modifier
	moisture_level = moisture
	atmosphere_density = atmosphere
	
	# Clear cache when configuration changes
	clear_cache()


## Get current configuration
func get_configuration() -> Dictionary:
	"""Get the current biome system configuration."""
	return {
		"star_distance": star_distance,
		"temperature_modifier": temperature_modifier,
		"moisture_level": moisture_level,
		"atmosphere_density": atmosphere_density,
		"effects_enabled": effects_enabled,
		"cache_size": _biome_map_cache.size(),
		"max_cache_size": _max_cache_size
	}

#endregion


#region Utility Methods

## Get all biome types
func get_all_biome_types() -> Array[BiomeType]:
	"""Get an array of all biome types."""
	var types: Array[BiomeType] = []
	for biome in BiomeType.values():
		types.append(biome)
	return types


## Get all environmental effect types
func get_all_effect_types() -> Array[EnvironmentalEffect]:
	"""Get an array of all environmental effect types."""
	var effects: Array[EnvironmentalEffect] = []
	for effect in EnvironmentalEffect.values():
		effects.append(effect)
	return effects


## Check if a biome is habitable
func is_biome_habitable(biome: BiomeType) -> bool:
	"""Check if a biome type is considered habitable."""
	match biome:
		BiomeType.FOREST, BiomeType.OCEAN:
			return true
		BiomeType.DESERT, BiomeType.ICE, BiomeType.BARREN:
			return false  # Survivable but not ideal
		BiomeType.VOLCANIC, BiomeType.TOXIC:
			return false  # Hazardous
	return false


## Get biome danger level (0-1)
func get_biome_danger_level(biome: BiomeType) -> float:
	"""Get the danger level of a biome (0 = safe, 1 = extremely dangerous)."""
	match biome:
		BiomeType.FOREST:
			return 0.1
		BiomeType.OCEAN:
			return 0.2
		BiomeType.DESERT:
			return 0.4
		BiomeType.ICE:
			return 0.5
		BiomeType.BARREN:
			return 0.3
		BiomeType.VOLCANIC:
			return 0.9
		BiomeType.TOXIC:
			return 0.8
	return 0.5


## Validate biome generation is deterministic
func validate_determinism(planet_seed: int, resolution: int = 64) -> bool:
	"""Validate that biome generation is deterministic."""
	# Create a simple heightmap for testing
	var heightmap = Image.create(resolution, resolution, false, Image.FORMAT_RF)
	for y in range(resolution):
		for x in range(resolution):
			var height = float(x + y) / (resolution * 2)
			heightmap.set_pixel(x, y, Color(height, height, height, 1.0))
	
	# Generate biome map twice
	clear_cache()
	var map1 = generate_biome_map(planet_seed, heightmap, resolution)
	
	clear_cache()
	var map2 = generate_biome_map(planet_seed, heightmap, resolution)
	
	# Compare maps
	for y in range(resolution):
		for x in range(resolution):
			var color1 = map1.get_pixel(x, y)
			var color2 = map2.get_pixel(x, y)
			if not color1.is_equal_approx(color2):
				return false
	
	return true


## Get biome statistics for a planet
func get_planet_biome_statistics(planet_seed: int, heightmap: Image) -> Dictionary:
	"""Get detailed biome statistics for a planet."""
	var resolution = heightmap.get_width()
	var stats = generate_biome_map_with_legend(planet_seed, heightmap, resolution)
	
	# Add additional statistics
	var dominant_biome: BiomeType = BiomeType.BARREN
	var max_percentage: float = 0.0
	
	for biome in stats["biome_percentages"]:
		if stats["biome_percentages"][biome] > max_percentage:
			max_percentage = stats["biome_percentages"][biome]
			dominant_biome = biome
	
	stats["dominant_biome"] = dominant_biome
	stats["dominant_biome_name"] = get_biome_name(dominant_biome)
	stats["habitability"] = _calculate_habitability(stats["biome_percentages"])
	
	return stats


## Calculate overall planet habitability
func _calculate_habitability(biome_percentages: Dictionary) -> float:
	"""Calculate overall planet habitability score (0-1)."""
	var habitability = 0.0
	
	# Weight each biome by its habitability
	var weights = {
		BiomeType.FOREST: 1.0,
		BiomeType.OCEAN: 0.8,
		BiomeType.DESERT: 0.2,
		BiomeType.ICE: 0.1,
		BiomeType.BARREN: 0.1,
		BiomeType.VOLCANIC: 0.0,
		BiomeType.TOXIC: 0.0
	}
	
	for biome in biome_percentages:
		var percentage = biome_percentages[biome] / 100.0
		var weight = weights.get(biome, 0.0)
		habitability += percentage * weight
	
	return clampf(habitability, 0.0, 1.0)

#endregion
