## UniverseGenerator - Procedural Star System Generation
## Generates star systems using deterministic procedural generation with
## Golden Ratio spacing to prevent overlapping systems.
##
## Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 32.1, 32.2, 32.3, 32.4, 32.5
## - 11.1: Use deterministic hash function based on sector coordinates
## - 11.2: Apply Golden Ratio spacing to prevent overlapping systems
## - 11.3: Return identical results on subsequent calls for same coordinates
## - 11.4: Derive mass, radius, and type from coordinate hash
## - 11.5: Generate system data on-demand without pre-storing arrays
## - 32.1: Use hash function seeded by coordinates
## - 32.2: Return identical system properties on multiple queries
## - 32.3: Apply Golden Ratio offsets to prevent clustering
## - 32.4: Derive all attributes from coordinate hash
## - 32.5: Calculate all properties on-demand
extends Node
class_name UniverseGenerator

## Emitted when a new star system is generated
signal system_generated(system: StarSystem)
## Emitted when filaments are generated between systems
signal filaments_generated(filaments: Array[Filament])

## Golden Ratio constant for spacing calculations
## Requirement 11.2, 32.3: Apply Golden Ratio spacing/offsets
const GOLDEN_RATIO: float = 1.618033988749

## Inverse Golden Ratio for distribution
const GOLDEN_RATIO_INVERSE: float = 0.618033988749

## Minimum separation distance between star systems (in game units)
const MIN_SYSTEM_SEPARATION: float = 100.0

## Sector size in game units
const SECTOR_SIZE: float = 1000.0

## Maximum stars per sector
const MAX_STARS_PER_SECTOR: int = 5

## Prime numbers for hash function
const HASH_PRIME_1: int = 73856093
const HASH_PRIME_2: int = 19349663
const HASH_PRIME_3: int = 83492791
const HASH_PRIME_4: int = 15485863

## Star type distribution thresholds (cumulative probability)
## O: 0.00003%, B: 0.13%, A: 0.6%, F: 3%, G: 7.6%, K: 12.1%, M: 76.45%
const STAR_TYPE_THRESHOLDS: Array[float] = [
	0.0000003,  # O-type (very rare)
	0.0013,     # B-type
	0.006,      # A-type
	0.03,       # F-type
	0.076,      # G-type (Sun-like)
	0.121,      # K-type
	1.0         # M-type (most common)
]

## Star type names
const STAR_TYPES: Array[String] = ["O", "B", "A", "F", "G", "K", "M"]

## Star type properties: [min_mass, max_mass, min_radius, max_radius, min_temp, max_temp]
## Mass in solar masses, radius in solar radii, temperature in Kelvin
const STAR_TYPE_PROPERTIES: Dictionary = {
	"O": [16.0, 150.0, 6.6, 20.0, 30000.0, 52000.0],
	"B": [2.1, 16.0, 1.8, 6.6, 10000.0, 30000.0],
	"A": [1.4, 2.1, 1.4, 1.8, 7500.0, 10000.0],
	"F": [1.04, 1.4, 1.15, 1.4, 6000.0, 7500.0],
	"G": [0.8, 1.04, 0.96, 1.15, 5200.0, 6000.0],
	"K": [0.45, 0.8, 0.7, 0.96, 3700.0, 5200.0],
	"M": [0.08, 0.45, 0.1, 0.7, 2400.0, 3700.0]
}

## Planet type enumeration
enum PlanetType {
	TERRESTRIAL,
	GAS_GIANT,
	ICE_GIANT,
	DWARF
}

#region Runtime Properties

## Master seed for the universe
var universe_seed: int = 0

## Cache for generated systems (optional, for performance)
var _system_cache: Dictionary = {}

## Maximum cache size
var _max_cache_size: int = 1000

## Whether to use caching
var use_cache: bool = true

#endregion


func _init(seed_value: int = 0) -> void:
	universe_seed = seed_value


func _ready() -> void:
	if universe_seed == 0:
		universe_seed = randi()


#region Hash Functions

## Deterministic hash function for coordinates
## Requirement 11.1, 32.1: Use deterministic hash function based on sector coordinates
## This function always returns the same value for the same input coordinates
func hash_coordinates(x: int, y: int, z: int) -> int:
	"""Generate a deterministic hash from 3D coordinates."""
	# Combine coordinates with prime numbers for good distribution
	var hash_value: int = universe_seed
	hash_value ^= x * HASH_PRIME_1
	hash_value ^= y * HASH_PRIME_2
	hash_value ^= z * HASH_PRIME_3
	
	# Mix the bits using XOR shift
	hash_value ^= (hash_value >> 13)
	hash_value ^= (hash_value << 7)
	hash_value ^= (hash_value >> 17)
	
	# Ensure positive value
	return absi(hash_value)


## Generate a float in [0, 1) from a hash value
func hash_to_float(hash_value: int) -> float:
	"""Convert a hash value to a float in [0, 1) range."""
	# Use modulo with a large prime to get good distribution
	return float(hash_value % 1000000) / 1000000.0


## Generate a float in [min_val, max_val) from a hash value
func hash_to_range(hash_value: int, min_val: float, max_val: float) -> float:
	"""Convert a hash value to a float in [min_val, max_val) range."""
	return min_val + hash_to_float(hash_value) * (max_val - min_val)


## Generate a secondary hash from a primary hash (for multiple properties)
func secondary_hash(primary_hash: int, index: int) -> int:
	"""Generate a secondary hash for deriving multiple properties."""
	var secondary: int = primary_hash ^ (index * HASH_PRIME_4)
	secondary ^= (secondary >> 11)
	secondary ^= (secondary << 5)
	secondary ^= (secondary >> 3)
	return absi(secondary)

#endregion

#region Star System Generation

## Get or generate a star system at the given sector coordinates
## Requirement 11.3, 32.2: Return identical results on subsequent calls
func get_star_system(sector_x: int, sector_y: int, sector_z: int) -> StarSystem:
	"""Get the star system at the given sector coordinates."""
	var cache_key = _make_cache_key(sector_x, sector_y, sector_z)
	
	# Check cache first
	if use_cache and _system_cache.has(cache_key):
		return _system_cache[cache_key]
	
	# Generate the system
	var system = _generate_star_system(sector_x, sector_y, sector_z)
	
	# Cache the result
	if use_cache:
		_cache_system(cache_key, system)
	
	system_generated.emit(system)
	return system


## Internal method to generate a star system
## Requirement 11.4, 32.4: Derive mass, radius, type from coordinate hash
func _generate_star_system(sector_x: int, sector_y: int, sector_z: int) -> StarSystem:
	"""Generate a star system from sector coordinates."""
	var system = StarSystem.new()
	system.coordinates = Vector3i(sector_x, sector_y, sector_z)
	
	# Get the primary hash for this sector
	var primary_hash = hash_coordinates(sector_x, sector_y, sector_z)
	
	# Determine if this sector has a star system
	var existence_hash = secondary_hash(primary_hash, 0)
	var existence_chance = hash_to_float(existence_hash)
	
	# About 30% of sectors have star systems
	if existence_chance > 0.3:
		system.has_star = false
		return system
	
	system.has_star = true
	
	# Generate star type
	var type_hash = secondary_hash(primary_hash, 1)
	system.star_type = _determine_star_type(type_hash)
	
	# Generate star properties based on type
	var props = STAR_TYPE_PROPERTIES[system.star_type]
	
	var mass_hash = secondary_hash(primary_hash, 2)
	system.star_mass = hash_to_range(mass_hash, props[0], props[1])
	
	var radius_hash = secondary_hash(primary_hash, 3)
	system.star_radius = hash_to_range(radius_hash, props[2], props[3])
	
	var temp_hash = secondary_hash(primary_hash, 4)
	system.star_temperature = hash_to_range(temp_hash, props[4], props[5])
	
	# Calculate star position within sector using Golden Ratio spacing
	# Requirement 11.2, 32.3: Apply Golden Ratio spacing
	system.local_position = _calculate_star_position(primary_hash, sector_x, sector_y, sector_z)
	
	# Generate planets
	var planet_count_hash = secondary_hash(primary_hash, 5)
	var planet_count = int(hash_to_range(planet_count_hash, 0.0, 9.0))
	
	for i in range(planet_count):
		var planet = _generate_planet(primary_hash, i, system.star_mass)
		system.planets.append(planet)
	
	# Generate system name
	system.system_name = _generate_system_name(primary_hash)
	
	return system


## Determine star type from hash value
func _determine_star_type(hash_value: int) -> String:
	"""Determine star spectral type from hash value."""
	var type_value = hash_to_float(hash_value)
	
	for i in range(STAR_TYPE_THRESHOLDS.size()):
		if type_value < STAR_TYPE_THRESHOLDS[i]:
			return STAR_TYPES[i]
	
	return "M"  # Default to M-type (most common)


## Calculate star position within sector using Golden Ratio spacing
## Requirement 11.2, 32.3: Apply Golden Ratio spacing to prevent overlapping
func _calculate_star_position(hash_value: int, sector_x: int, sector_y: int, sector_z: int) -> Vector3:
	"""Calculate the star's position within its sector using Golden Ratio distribution."""
	# Use Golden Ratio for quasi-random but deterministic distribution
	var x_hash = secondary_hash(hash_value, 10)
	var y_hash = secondary_hash(hash_value, 11)
	var z_hash = secondary_hash(hash_value, 12)
	
	# Apply Golden Ratio modulation for better spacing
	var x_offset = fmod(float(x_hash) * GOLDEN_RATIO_INVERSE, 1.0)
	var y_offset = fmod(float(y_hash) * GOLDEN_RATIO_INVERSE, 1.0)
	var z_offset = fmod(float(z_hash) * GOLDEN_RATIO_INVERSE, 1.0)
	
	# Scale to sector size with margin to prevent edge clustering
	var margin = MIN_SYSTEM_SEPARATION / SECTOR_SIZE
	var usable_range = 1.0 - 2.0 * margin
	
	var local_x = margin + x_offset * usable_range
	var local_y = margin + y_offset * usable_range
	var local_z = margin + z_offset * usable_range
	
	return Vector3(local_x, local_y, local_z) * SECTOR_SIZE


## Get the world position of a star system
func get_system_world_position(system: StarSystem) -> Vector3:
	"""Get the world position of a star system."""
	var sector_origin = Vector3(
		system.coordinates.x * SECTOR_SIZE,
		system.coordinates.y * SECTOR_SIZE,
		system.coordinates.z * SECTOR_SIZE
	)
	return sector_origin + system.local_position

#endregion


#region Planet Generation

## Generate a planet for a star system
func _generate_planet(system_hash: int, planet_index: int, star_mass: float) -> PlanetData:
	"""Generate planet data for a star system."""
	var planet = PlanetData.new()
	
	# Create unique hash for this planet
	var planet_hash = secondary_hash(system_hash, 100 + planet_index * 10)
	
	# Generate planet name
	planet.planet_name = _generate_planet_name(planet_hash, planet_index)
	
	# Determine planet type based on distance from star
	var type_hash = secondary_hash(planet_hash, 0)
	var distance_factor = float(planet_index + 1) / 8.0  # Normalize to 0-1 range
	planet.planet_type = _determine_planet_type(type_hash, distance_factor)
	
	# Generate orbital distance (semi-major axis) using Titius-Bode-like progression
	var base_distance = 0.4 + 0.3 * pow(2.0, planet_index)
	var distance_variation = hash_to_range(secondary_hash(planet_hash, 1), 0.8, 1.2)
	planet.orbital_distance = base_distance * distance_variation
	
	# Generate mass based on planet type
	var mass_hash = secondary_hash(planet_hash, 2)
	match planet.planet_type:
		PlanetType.TERRESTRIAL:
			planet.mass = hash_to_range(mass_hash, 0.1, 2.0)  # Earth masses
			planet.radius = hash_to_range(secondary_hash(planet_hash, 3), 0.5, 1.5)
		PlanetType.GAS_GIANT:
			planet.mass = hash_to_range(mass_hash, 50.0, 500.0)
			planet.radius = hash_to_range(secondary_hash(planet_hash, 3), 5.0, 15.0)
		PlanetType.ICE_GIANT:
			planet.mass = hash_to_range(mass_hash, 10.0, 50.0)
			planet.radius = hash_to_range(secondary_hash(planet_hash, 3), 3.0, 6.0)
		PlanetType.DWARF:
			planet.mass = hash_to_range(mass_hash, 0.001, 0.1)
			planet.radius = hash_to_range(secondary_hash(planet_hash, 3), 0.1, 0.5)
	
	# Generate orbital elements
	planet.eccentricity = hash_to_range(secondary_hash(planet_hash, 4), 0.0, 0.3)
	planet.inclination = hash_to_range(secondary_hash(planet_hash, 5), 0.0, 0.1)  # radians
	planet.rotation_period = hash_to_range(secondary_hash(planet_hash, 6), 10.0, 1000.0)  # hours
	planet.axial_tilt = hash_to_range(secondary_hash(planet_hash, 7), 0.0, 0.5)  # radians
	
	# Determine if planet has rings (gas giants more likely)
	var ring_hash = secondary_hash(planet_hash, 8)
	var ring_chance = 0.1 if planet.planet_type == PlanetType.TERRESTRIAL else 0.4
	planet.has_rings = hash_to_float(ring_hash) < ring_chance
	
	# Generate moons
	var moon_count_hash = secondary_hash(planet_hash, 9)
	var max_moons = 2 if planet.planet_type == PlanetType.TERRESTRIAL else 10
	var moon_count = int(hash_to_range(moon_count_hash, 0.0, float(max_moons)))
	planet.moon_count = moon_count
	
	return planet


## Determine planet type based on hash and distance from star
func _determine_planet_type(hash_value: int, distance_factor: float) -> PlanetType:
	"""Determine planet type based on distance from star."""
	var type_value = hash_to_float(hash_value)
	
	# Inner planets more likely to be terrestrial
	# Outer planets more likely to be gas/ice giants
	if distance_factor < 0.3:
		# Inner zone: mostly terrestrial
		if type_value < 0.7:
			return PlanetType.TERRESTRIAL
		elif type_value < 0.9:
			return PlanetType.DWARF
		else:
			return PlanetType.GAS_GIANT
	elif distance_factor < 0.6:
		# Middle zone: mix of types
		if type_value < 0.3:
			return PlanetType.TERRESTRIAL
		elif type_value < 0.7:
			return PlanetType.GAS_GIANT
		else:
			return PlanetType.ICE_GIANT
	else:
		# Outer zone: mostly ice giants and dwarfs
		if type_value < 0.2:
			return PlanetType.GAS_GIANT
		elif type_value < 0.6:
			return PlanetType.ICE_GIANT
		else:
			return PlanetType.DWARF

#endregion

#region Filament Generation

## Generate filaments connecting star systems
## Requirement 10.1: Generate filament pathways connecting star systems
func generate_filaments(systems: Array[StarSystem]) -> Array[Filament]:
	"""Generate filament connections between star systems."""
	var filaments: Array[Filament] = []
	
	if systems.size() < 2:
		return filaments
	
	# Create a minimum spanning tree-like structure with some extra connections
	var connected: Array[int] = [0]
	var unconnected: Array[int] = []
	
	for i in range(1, systems.size()):
		unconnected.append(i)
	
	# Connect all systems using nearest neighbor approach
	while unconnected.size() > 0:
		var best_distance = INF
		var best_connected_idx = -1
		var best_unconnected_idx = -1
		
		for c_idx in connected:
			for u_idx in unconnected:
				var pos1 = get_system_world_position(systems[c_idx])
				var pos2 = get_system_world_position(systems[u_idx])
				var distance = pos1.distance_to(pos2)
				
				if distance < best_distance:
					best_distance = distance
					best_connected_idx = c_idx
					best_unconnected_idx = u_idx
		
		if best_unconnected_idx >= 0:
			# Create filament
			var filament = Filament.new()
			filament.start_system = systems[best_connected_idx]
			filament.end_system = systems[best_unconnected_idx]
			filament.length = best_distance
			filament.density = _calculate_filament_density(best_distance)
			filaments.append(filament)
			
			connected.append(best_unconnected_idx)
			unconnected.erase(best_unconnected_idx)
	
	# Add some extra connections for redundancy (about 20% more)
	var extra_connections = int(systems.size() * 0.2)
	for _i in range(extra_connections):
		var idx1 = randi() % systems.size()
		var idx2 = randi() % systems.size()
		
		if idx1 != idx2:
			var pos1 = get_system_world_position(systems[idx1])
			var pos2 = get_system_world_position(systems[idx2])
			var distance = pos1.distance_to(pos2)
			
			# Only add if not too long
			if distance < SECTOR_SIZE * 3:
				var filament = Filament.new()
				filament.start_system = systems[idx1]
				filament.end_system = systems[idx2]
				filament.length = distance
				filament.density = _calculate_filament_density(distance)
				filaments.append(filament)
	
	filaments_generated.emit(filaments)
	return filaments


## Calculate filament density based on length
func _calculate_filament_density(length: float) -> float:
	"""Calculate filament density (shorter = denser)."""
	# Inverse relationship: shorter filaments are denser
	var max_length = SECTOR_SIZE * 5
	return clampf(1.0 - (length / max_length), 0.1, 1.0)

#endregion

#region Name Generation

## Generate a system name from hash
func _generate_system_name(hash_value: int) -> String:
	"""Generate a procedural system name."""
	var prefixes = ["Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Eta", "Theta",
					"Iota", "Kappa", "Lambda", "Mu", "Nu", "Xi", "Omicron", "Pi",
					"Rho", "Sigma", "Tau", "Upsilon", "Phi", "Chi", "Psi", "Omega"]
	
	var suffixes = ["Centauri", "Cygni", "Draconis", "Eridani", "Lyrae", "Orionis",
					"Pegasi", "Persei", "Tauri", "Ursae", "Virginis", "Aquarii",
					"Bootis", "Carinae", "Cassiopeiae", "Geminorum", "Herculis"]
	
	var prefix_idx = hash_value % prefixes.size()
	var suffix_idx = secondary_hash(hash_value, 20) % suffixes.size()
	var number = (secondary_hash(hash_value, 21) % 999) + 1
	
	return "%s %s %d" % [prefixes[prefix_idx], suffixes[suffix_idx], number]


## Generate a planet name
func _generate_planet_name(hash_value: int, planet_index: int) -> String:
	"""Generate a planet designation."""
	var letters = ["b", "c", "d", "e", "f", "g", "h", "i"]
	if planet_index < letters.size():
		return letters[planet_index]
	return "p%d" % (planet_index + 1)

#endregion


#region Sector Queries

## Get all star systems in a region
## Requirement 11.5, 32.5: Generate system data on-demand without pre-storing
func get_systems_in_region(min_sector: Vector3i, max_sector: Vector3i) -> Array[StarSystem]:
	"""Get all star systems in a region of sectors."""
	var systems: Array[StarSystem] = []
	
	for x in range(min_sector.x, max_sector.x + 1):
		for y in range(min_sector.y, max_sector.y + 1):
			for z in range(min_sector.z, max_sector.z + 1):
				var system = get_star_system(x, y, z)
				if system.has_star:
					systems.append(system)
	
	return systems


## Get the sector coordinates for a world position
func get_sector_for_position(world_pos: Vector3) -> Vector3i:
	"""Get the sector coordinates containing a world position."""
	return Vector3i(
		int(floor(world_pos.x / SECTOR_SIZE)),
		int(floor(world_pos.y / SECTOR_SIZE)),
		int(floor(world_pos.z / SECTOR_SIZE))
	)


## Get nearby star systems around a world position
func get_nearby_systems(world_pos: Vector3, radius_sectors: int = 1) -> Array[StarSystem]:
	"""Get star systems within a radius of sectors around a position."""
	var center_sector = get_sector_for_position(world_pos)
	
	var min_sector = Vector3i(
		center_sector.x - radius_sectors,
		center_sector.y - radius_sectors,
		center_sector.z - radius_sectors
	)
	var max_sector = Vector3i(
		center_sector.x + radius_sectors,
		center_sector.y + radius_sectors,
		center_sector.z + radius_sectors
	)
	
	return get_systems_in_region(min_sector, max_sector)


## Find the nearest star system to a world position
func find_nearest_system(world_pos: Vector3, search_radius: int = 3) -> StarSystem:
	"""Find the nearest star system to a world position."""
	var systems = get_nearby_systems(world_pos, search_radius)
	
	var nearest: StarSystem = null
	var nearest_distance = INF
	
	for system in systems:
		if system.has_star:
			var system_pos = get_system_world_position(system)
			var distance = world_pos.distance_to(system_pos)
			
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = system
	
	return nearest


## Check if two systems would overlap (for validation)
## Requirement 11.2: Ensure no overlapping systems
func check_system_overlap(system1: StarSystem, system2: StarSystem) -> bool:
	"""Check if two star systems are too close together."""
	if not system1.has_star or not system2.has_star:
		return false
	
	var pos1 = get_system_world_position(system1)
	var pos2 = get_system_world_position(system2)
	var distance = pos1.distance_to(pos2)
	
	return distance < MIN_SYSTEM_SEPARATION


## Validate that no systems in a region overlap
func validate_no_overlaps(min_sector: Vector3i, max_sector: Vector3i) -> bool:
	"""Validate that no star systems in a region overlap."""
	var systems = get_systems_in_region(min_sector, max_sector)
	
	for i in range(systems.size()):
		for j in range(i + 1, systems.size()):
			if check_system_overlap(systems[i], systems[j]):
				return false
	
	return true

#endregion

#region Cache Management

## Create a cache key from sector coordinates
func _make_cache_key(x: int, y: int, z: int) -> String:
	"""Create a unique cache key for sector coordinates."""
	return "%d_%d_%d" % [x, y, z]


## Cache a star system
func _cache_system(key: String, system: StarSystem) -> void:
	"""Cache a star system, evicting old entries if necessary."""
	if _system_cache.size() >= _max_cache_size:
		# Simple eviction: remove first entry
		var first_key = _system_cache.keys()[0]
		_system_cache.erase(first_key)
	
	_system_cache[key] = system


## Clear the system cache
func clear_cache() -> void:
	"""Clear the star system cache."""
	_system_cache.clear()


## Set the maximum cache size
func set_max_cache_size(size: int) -> void:
	"""Set the maximum number of cached systems."""
	_max_cache_size = maxi(size, 10)

#endregion

#region Utility Methods

## Get the universe seed
func get_seed() -> int:
	"""Get the universe seed."""
	return universe_seed


## Set the universe seed (clears cache)
func set_seed(new_seed: int) -> void:
	"""Set the universe seed and clear the cache."""
	universe_seed = new_seed
	clear_cache()


## Get statistics about the generator
func get_statistics() -> Dictionary:
	"""Get statistics about the universe generator."""
	return {
		"seed": universe_seed,
		"cached_systems": _system_cache.size(),
		"max_cache_size": _max_cache_size,
		"sector_size": SECTOR_SIZE,
		"min_separation": MIN_SYSTEM_SEPARATION,
		"golden_ratio": GOLDEN_RATIO
	}

#endregion


#region Data Classes

## Star System data class
class StarSystem:
	var coordinates: Vector3i = Vector3i.ZERO
	var local_position: Vector3 = Vector3.ZERO
	var has_star: bool = false
	var system_name: String = ""
	var star_type: String = "M"
	var star_mass: float = 1.0  # Solar masses
	var star_radius: float = 1.0  # Solar radii
	var star_temperature: float = 5778.0  # Kelvin
	var planets: Array[PlanetData] = []
	var discovered: bool = false
	
	func get_star_color() -> Color:
		"""Get the star's color based on temperature."""
		# Simplified blackbody color approximation
		var t = star_temperature
		if t < 3500:
			return Color(1.0, 0.5, 0.3)  # Red
		elif t < 5000:
			return Color(1.0, 0.8, 0.6)  # Orange
		elif t < 6000:
			return Color(1.0, 1.0, 0.9)  # Yellow-white
		elif t < 7500:
			return Color(1.0, 1.0, 1.0)  # White
		elif t < 10000:
			return Color(0.9, 0.95, 1.0)  # Blue-white
		else:
			return Color(0.7, 0.8, 1.0)  # Blue


## Planet data class
class PlanetData:
	var planet_name: String = ""
	var planet_type: PlanetType = PlanetType.TERRESTRIAL
	var mass: float = 1.0  # Earth masses
	var radius: float = 1.0  # Earth radii
	var orbital_distance: float = 1.0  # AU
	var eccentricity: float = 0.0
	var inclination: float = 0.0  # radians
	var rotation_period: float = 24.0  # hours
	var axial_tilt: float = 0.0  # radians
	var has_rings: bool = false
	var moon_count: int = 0
	
	func get_type_name() -> String:
		"""Get the planet type as a string."""
		match planet_type:
			PlanetType.TERRESTRIAL:
				return "Terrestrial"
			PlanetType.GAS_GIANT:
				return "Gas Giant"
			PlanetType.ICE_GIANT:
				return "Ice Giant"
			PlanetType.DWARF:
				return "Dwarf Planet"
		return "Unknown"


## Filament data class
class Filament:
	var start_system: StarSystem = null
	var end_system: StarSystem = null
	var length: float = 0.0
	var density: float = 1.0  # Higher = more dense lattice
	
	func get_midpoint() -> Vector3:
		"""Get the midpoint of the filament."""
		if start_system == null or end_system == null:
			return Vector3.ZERO
		# Note: This requires access to the generator for world positions
		return Vector3.ZERO  # Placeholder

#endregion
