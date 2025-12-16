## PlanetaryTerrainManager - Distance-Based Voxel Terrain Generation
## Monitors player distance to planets and generates voxel terrain when approaching.
## Integrates PlanetGenerator with SolarSystemInitializer for seamless planet landing.
##
## Requirements: Planetary Landing System Phase 1
## - Monitor player distance to each planet
## - Generate voxel terrain when distance < threshold
## - Use planet-specific seeds for deterministic generation
## - Cache generated state (only generate once per planet)
## - Cleanup terrain when moving far away (optional)
extends Node
class_name PlanetaryTerrainManager

## Emitted when terrain generation starts for a planet
signal terrain_generation_started(planet: CelestialBody)
## Emitted when terrain generation completes for a planet
signal terrain_generation_completed(planet: CelestialBody, terrain: Node3D)
## Emitted when terrain is unloaded for a planet
signal terrain_unloaded(planet: CelestialBody)

## Threshold multiplier: Generate terrain when distance < (radius * RADIUS_MULTIPLIER)
const RADIUS_MULTIPLIER := 10.0

## Minimum generation threshold in game units (1 unit = 1 million meters)
const MIN_GENERATION_THRESHOLD := 500.0

## Unload multiplier: Unload terrain when distance > (generation_threshold * UNLOAD_MULTIPLIER)
const UNLOAD_MULTIPLIER := 2.0

## Performance target: Max generation time in ms
const MAX_GENERATION_TIME_MS := 100.0

#region Exported Properties

## Reference to SolarSystemInitializer
@export var solar_system_initializer: NodePath

## Reference to player node (XROrigin3D or Camera3D)
@export var player_node: NodePath

## Whether to enable automatic terrain unloading when far away
@export var enable_terrain_unloading: bool = false

## Whether to enable performance monitoring
@export var enable_performance_monitoring: bool = true

#endregion

#region Runtime Properties

## Reference to SolarSystemInitializer instance
var _solar_system: SolarSystemInitializer = null

## Reference to player node
var _player: Node3D = null

## PlanetGenerator instance for terrain creation
var _planet_generator: PlanetGenerator = null

## Dictionary tracking generated terrain: planet_name -> {terrain: Node3D, generated: bool, threshold: float}
var _planet_terrain_cache: Dictionary = {}

## Performance monitor reference
var _performance_monitor: Node = null

## Planet type classification map
var _planet_type_map: Dictionary = {
	"earth": "rocky",
	"mars": "desert",
	"venus": "volcanic",
	"mercury": "rocky",
	"jupiter": "gas",
	"saturn": "gas",
	"uranus": "ice",
	"neptune": "ice",
	"moon": "rocky"  # Earth's moon
}

#endregion


func _ready() -> void:
	# Defer initialization to ensure autoloads are ready
	call_deferred("_initialize")


## Initialize the terrain manager
func _initialize() -> void:
	# Get references
	if solar_system_initializer != NodePath(""):
		_solar_system = get_node_or_null(solar_system_initializer)

	if player_node != NodePath(""):
		_player = get_node_or_null(player_node)

	# Create PlanetGenerator instance
	_planet_generator = PlanetGenerator.new()
	add_child(_planet_generator)

	# Get performance monitor if available
	if enable_performance_monitoring:
		_performance_monitor = get_node_or_null("/root/VoxelPerformanceMonitor")

	# Validate references
	if _solar_system == null:
		push_error("[PlanetaryTerrainManager] SolarSystemInitializer not found at: %s" % solar_system_initializer)
		return

	if _player == null:
		push_error("[PlanetaryTerrainManager] Player node not found at: %s" % player_node)
		return

	# Wait for solar system to initialize
	if not _solar_system.is_initialized():
		await _solar_system.solar_system_initialized

	# Initialize terrain cache for all planets
	_initialize_terrain_cache()

	print("[PlanetaryTerrainManager] Initialized - monitoring %d planets" % _planet_terrain_cache.size())


## Initialize terrain cache for all planets
func _initialize_terrain_cache() -> void:
	"""Setup tracking data for each planet."""
	var planets := _solar_system.get_planets()

	for planet in planets:
		var planet_name := planet.name.to_lower()
		var threshold := _calculate_generation_threshold(planet)

		_planet_terrain_cache[planet_name] = {
			"terrain": null,
			"generated": false,
			"threshold": threshold,
			"unload_threshold": threshold * UNLOAD_MULTIPLIER,
			"planet": planet
		}

		print("[PlanetaryTerrainManager] Setup tracking for %s: threshold=%.1f game units (%.1f million km)"
			% [planet.body_name, threshold, threshold])


## Calculate generation threshold for a planet
func _calculate_generation_threshold(planet: CelestialBody) -> float:
	"""Calculate when to start generating terrain based on planet radius."""
	# Use the larger of: MIN_GENERATION_THRESHOLD or (radius * RADIUS_MULTIPLIER)
	var radius_threshold := planet.radius * RADIUS_MULTIPLIER
	return maxf(MIN_GENERATION_THRESHOLD, radius_threshold)


## Get planet type from name
func _get_planet_type(planet_name: String) -> String:
	"""Classify planet type for terrain generation."""
	var name_lower := planet_name.to_lower()
	return _planet_type_map.get(name_lower, "rocky")  # Default to rocky


## Generate planet seed from name for deterministic generation
func _generate_planet_seed(planet: CelestialBody) -> int:
	"""Generate a deterministic seed from planet name."""
	# Use hash of planet name for deterministic seed
	var seed_base := planet.body_name.hash()
	# Ensure positive seed
	return abs(seed_base) if seed_base != 0 else 12345


func _process(_delta: float) -> void:
	if _solar_system == null or _player == null:
		return

	# Check distance to each planet
	var player_pos := _player.global_position

	for planet_name in _planet_terrain_cache:
		var cache_entry: Dictionary = _planet_terrain_cache[planet_name]
		var planet: CelestialBody = cache_entry["planet"]
		var distance := (planet.global_position - player_pos).length()

		# Check if we should generate terrain
		if not cache_entry["generated"] and distance < cache_entry["threshold"]:
			_generate_terrain_for_planet(planet, cache_entry)

		# Check if we should unload terrain
		elif enable_terrain_unloading and cache_entry["generated"] and distance > cache_entry["unload_threshold"]:
			_unload_terrain_for_planet(planet, cache_entry)


## Generate voxel terrain for a planet
func _generate_terrain_for_planet(planet: CelestialBody, cache_entry: Dictionary) -> void:
	"""Generate voxel terrain using PlanetGenerator."""
	print("[PlanetaryTerrainManager] Generating terrain for %s..." % planet.body_name)

	terrain_generation_started.emit(planet)

	# Track generation time
	var start_time := Time.get_ticks_msec()

	# Get planet parameters
	var planet_seed := _generate_planet_seed(planet)
	var planet_type := _get_planet_type(planet.name)
	var planet_radius_m := planet.radius * 1000000.0  # Convert game units to meters

	print("[PlanetaryTerrainManager] Planet params: seed=%d, type=%s, radius_m=%.1f"
		% [planet_seed, planet_type, planet_radius_m])

	# Create voxel terrain
	var terrain := _planet_generator.create_voxel_terrain(planet_seed, planet_type, planet_radius_m)

	if terrain == null:
		push_error("[PlanetaryTerrainManager] Failed to create voxel terrain for %s" % planet.body_name)
		return

	# Attach terrain to planet
	terrain.name = "VoxelTerrain"
	planet.add_child(terrain)

	# Update cache
	cache_entry["terrain"] = terrain
	cache_entry["generated"] = true

	# Calculate generation time
	var generation_time_ms := Time.get_ticks_msec() - start_time

	# Log performance
	print("[PlanetaryTerrainManager] Terrain generated for %s in %.1fms"
		% [planet.body_name, generation_time_ms])

	if generation_time_ms > MAX_GENERATION_TIME_MS:
		push_warning("[PlanetaryTerrainManager] Generation time exceeded target: %.1fms > %.1fms"
			% [generation_time_ms, MAX_GENERATION_TIME_MS])

	# Report to performance monitor if available
	if _performance_monitor != null and _performance_monitor.has_method("report_chunk_generated"):
		_performance_monitor.report_chunk_generated(generation_time_ms / 1000.0)

	terrain_generation_completed.emit(planet, terrain)


## Unload terrain for a planet
func _unload_terrain_for_planet(planet: CelestialBody, cache_entry: Dictionary) -> void:
	"""Remove voxel terrain to save memory."""
	print("[PlanetaryTerrainManager] Unloading terrain for %s..." % planet.body_name)

	var terrain: Node3D = cache_entry["terrain"]
	if terrain != null:
		terrain.queue_free()

	cache_entry["terrain"] = null
	cache_entry["generated"] = false

	terrain_unloaded.emit(planet)


#region Public API

## Get terrain for a specific planet
func get_terrain(planet_name: String) -> Node3D:
	"""Get the generated terrain for a planet (null if not generated)."""
	var name_lower := planet_name.to_lower()
	if _planet_terrain_cache.has(name_lower):
		return _planet_terrain_cache[name_lower].get("terrain", null)
	return null


## Check if terrain is generated for a planet
func is_terrain_generated(planet_name: String) -> bool:
	"""Check if terrain has been generated for a planet."""
	var name_lower := planet_name.to_lower()
	if _planet_terrain_cache.has(name_lower):
		return _planet_terrain_cache[name_lower].get("generated", false)
	return false


## Get distance to nearest planet with terrain
func get_nearest_planet_with_terrain() -> CelestialBody:
	"""Get the closest planet that has generated terrain."""
	if _player == null:
		return null

	var player_pos := _player.global_position
	var nearest: CelestialBody = null
	var nearest_distance := INF

	for planet_name in _planet_terrain_cache:
		var cache_entry: Dictionary = _planet_terrain_cache[planet_name]
		if cache_entry["generated"]:
			var planet: CelestialBody = cache_entry["planet"]
			var distance := (planet.global_position - player_pos).length()
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = planet

	return nearest


## Force generation of terrain for a specific planet
func force_generate_terrain(planet_name: String) -> bool:
	"""Force immediate terrain generation for a planet."""
	var name_lower := planet_name.to_lower()
	if not _planet_terrain_cache.has(name_lower):
		push_error("[PlanetaryTerrainManager] Planet not found: %s" % planet_name)
		return false

	var cache_entry: Dictionary = _planet_terrain_cache[name_lower]
	if cache_entry["generated"]:
		push_warning("[PlanetaryTerrainManager] Terrain already generated for %s" % planet_name)
		return true

	var planet: CelestialBody = cache_entry["planet"]
	_generate_terrain_for_planet(planet, cache_entry)
	return true


## Force unload terrain for a specific planet
func force_unload_terrain(planet_name: String) -> bool:
	"""Force immediate terrain unload for a planet."""
	var name_lower := planet_name.to_lower()
	if not _planet_terrain_cache.has(name_lower):
		push_error("[PlanetaryTerrainManager] Planet not found: %s" % planet_name)
		return false

	var cache_entry: Dictionary = _planet_terrain_cache[name_lower]
	if not cache_entry["generated"]:
		push_warning("[PlanetaryTerrainManager] No terrain to unload for %s" % planet_name)
		return false

	var planet: CelestialBody = cache_entry["planet"]
	_unload_terrain_for_planet(planet, cache_entry)
	return true


## Get status report for all planets
func get_status_report() -> Dictionary:
	"""Get detailed status of all tracked planets."""
	var report := {
		"total_planets": _planet_terrain_cache.size(),
		"generated_count": 0,
		"planets": {}
	}

	if _player == null:
		return report

	var player_pos := _player.global_position

	for planet_name in _planet_terrain_cache:
		var cache_entry: Dictionary = _planet_terrain_cache[planet_name]
		var planet: CelestialBody = cache_entry["planet"]
		var distance := (planet.global_position - player_pos).length()

		if cache_entry["generated"]:
			report["generated_count"] += 1

		report["planets"][planet_name] = {
			"name": planet.body_name,
			"generated": cache_entry["generated"],
			"distance": distance,
			"threshold": cache_entry["threshold"],
			"within_threshold": distance < cache_entry["threshold"]
		}

	return report

#endregion
