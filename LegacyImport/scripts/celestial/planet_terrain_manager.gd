## PlanetTerrainManager - Distance-Based Voxel Terrain Generation
## Monitors player distance to planets and generates walkable voxel terrain
## when the player approaches within a threshold distance.
##
## This system connects PlanetGenerator with the solar system to create
## procedurally generated voxel terrain on demand, improving performance
## by only generating terrain when needed.
extends Node
class_name PlanetTerrainManager

## Distance threshold for terrain generation (game units)
## Default: 500 game units (500,000 km)
@export var generation_distance: float = 500.0

## Whether to show debug messages
@export var debug_mode: bool = true

## Reference to PlanetGenerator for terrain creation
var planet_generator: PlanetGenerator = null

## Dictionary tracking which planets have terrain: {planet_name: bool}
var planets_with_terrain: Dictionary = {}

## Reference to player (spacecraft or walking controller)
var player: Node3D = null

## Reference to solar system initializer
var solar_system: SolarSystemInitializer = null

## Last time we checked distances (for throttling)
var _last_check_time: float = 0.0

## Check interval in seconds (don't check every frame)
const CHECK_INTERVAL: float = 0.5


func _ready() -> void:
	# Create planet generator
	planet_generator = PlanetGenerator.new()
	add_child(planet_generator)

	if debug_mode:
		print("[PlanetTerrainManager] Initialized with generation distance: %.1f game units" % generation_distance)

	# Find solar system initializer (try parent first, then search)
	solar_system = get_parent() as SolarSystemInitializer
	if not solar_system:
		# Search for it in the scene tree
		var root = get_tree().root
		solar_system = _find_node_of_type(root, SolarSystemInitializer)

	if not solar_system:
		push_error("[PlanetTerrainManager] Could not find SolarSystemInitializer in scene tree")
		return

	# Wait for solar system to initialize
	if not solar_system.is_initialized():
		if debug_mode:
			print("[PlanetTerrainManager] Waiting for solar system initialization...")
		await solar_system.solar_system_initialized

	if debug_mode:
		print("[PlanetTerrainManager] Solar system initialized with %d bodies" % solar_system.get_body_count())


func _process(delta: float) -> void:
	"""Check distance to planets periodically and generate terrain if needed."""

	# Throttle checks to avoid performance impact
	_last_check_time += delta
	if _last_check_time < CHECK_INTERVAL:
		return
	_last_check_time = 0.0

	if not solar_system or not solar_system.is_initialized():
		return

	# Find player if we don't have a reference
	if not is_instance_valid(player):
		_find_player()
		if not is_instance_valid(player):
			return

	# Get all planets from solar system
	var planets := solar_system.get_planets()

	for planet in planets:
		if not is_instance_valid(planet):
			continue

		var planet_name := planet.body_name

		# Skip if terrain already generated
		if planets_with_terrain.has(planet_name):
			continue

		# Calculate distance from player to planet surface
		var distance := player.global_position.distance_to(planet.global_position)
		var surface_distance := distance - planet.radius

		# Calculate threshold (either fixed distance or based on planet size)
		var threshold := maxf(generation_distance, planet.radius * 10.0)

		# Check if player is within generation range
		if surface_distance < threshold:
			if debug_mode:
				print("[PlanetTerrainManager] Player within range of %s (%.1f < %.1f)" % [planet_name, surface_distance, threshold])
			_generate_terrain_for_planet(planet)


func _generate_terrain_for_planet(planet: CelestialBody) -> void:
	"""Generate voxel terrain for a planet."""

	var planet_name := planet.body_name

	if debug_mode:
		print("[PlanetTerrainManager] Generating terrain for %s..." % planet_name)

	# Mark as in-progress to prevent multiple generation attempts
	planets_with_terrain[planet_name] = true

	# Generate planet seed from name (deterministic)
	var planet_seed := _generate_planet_seed(planet_name)

	# Determine planet type based on planet properties
	var planet_type := _determine_planet_type(planet)

	# Get planet radius in meters (for voxel generation)
	# Note: CelestialBody.radius is in game units (1 unit = 1,000 km)
	# PlanetGenerator expects meters, so convert: 1 unit = 1,000,000 meters
	var radius_meters := planet.radius * 1000000.0

	if debug_mode:
		print("[PlanetTerrainManager]   Seed: %d, Type: %s, Radius: %.1f m" % [planet_seed, planet_type, radius_meters])

	# Create voxel terrain using PlanetGenerator
	var terrain_node := planet_generator.create_voxel_terrain(planet_seed, planet_type, radius_meters)

	if not is_instance_valid(terrain_node):
		push_error("[PlanetTerrainManager] Failed to create voxel terrain for %s" % planet_name)
		planets_with_terrain.erase(planet_name)
		return

	# Name the terrain node
	terrain_node.name = "VoxelTerrain"

	# Add as child of planet
	planet.add_child(terrain_node)

	if debug_mode:
		print("[PlanetTerrainManager] Terrain generated for %s" % planet_name)


func _generate_planet_seed(planet_name: String) -> int:
	"""Generate a deterministic seed from planet name."""
	var seed_value := 0
	for i in range(planet_name.length()):
		seed_value += planet_name.unicode_at(i) * (i + 1)
	return abs(seed_value)


func _determine_planet_type(planet: CelestialBody) -> String:
	"""Determine planet type for terrain generation based on properties."""

	var planet_name := planet.body_name.to_lower()

	# Use simple heuristics based on planet name
	# In a real implementation, this would use actual planet data
	if "mercury" in planet_name:
		return "rocky"
	elif "venus" in planet_name:
		return "volcanic"
	elif "earth" in planet_name:
		return "rocky"  # Could use a special "earth" type if available
	elif "mars" in planet_name:
		return "desert"
	elif "jupiter" in planet_name or "saturn" in planet_name or "uranus" in planet_name or "neptune" in planet_name:
		return "gas"
	else:
		# Use density-based classification for unknown bodies
		# Density = mass / volume, volume = (4/3) * π * r³
		if planet.radius > 0.001:  # Avoid division by zero
			var volume := (4.0 / 3.0) * PI * pow(planet.radius, 3)
			var density := planet.mass / volume

			# Rough density thresholds (in game units)
			# Gas giants: < 2000, Rocky planets: > 2000
			if density < 2000.0:
				return "gas"
			else:
				return "rocky"

	return "rocky"  # Default fallback


func _find_player() -> void:
	"""Find the player node in the scene tree."""
	# Try to find player group first
	var player_nodes = get_tree().get_nodes_in_group("player")
	if player_nodes.size() > 0:
		player = player_nodes[0] as Node3D
		if debug_mode and is_instance_valid(player):
			print("[PlanetTerrainManager] Found player in group: %s" % player.name)
		return

	# Try to find spacecraft
	var root = get_tree().root
	player = _find_node_by_name(root, "Spacecraft")
	if is_instance_valid(player):
		if debug_mode:
			print("[PlanetTerrainManager] Found spacecraft: %s" % player.name)
		return

	# Try to find walking controller
	player = _find_node_of_type(root, WalkingController)
	if is_instance_valid(player):
		if debug_mode:
			print("[PlanetTerrainManager] Found walking controller: %s" % player.name)
		return

	# Try to find XROrigin3D (VR mode)
	player = _find_node_by_class(root, "XROrigin3D")
	if is_instance_valid(player):
		if debug_mode:
			print("[PlanetTerrainManager] Found XR origin: %s" % player.name)


func _find_node_by_name(node: Node, node_name: String) -> Node3D:
	"""Recursively search for a node by name."""
	if node.name == node_name and node is Node3D:
		return node as Node3D

	for child in node.get_children():
		var result = _find_node_by_name(child, node_name)
		if is_instance_valid(result):
			return result

	return null


func _find_node_of_type(node: Node, type: Variant) -> Node:
	"""Recursively search for a node of a specific type."""
	if is_instance_of(node, type):
		return node

	for child in node.get_children():
		var result = _find_node_of_type(child, type)
		if is_instance_valid(result):
			return result

	return null


func _find_node_by_class(node: Node, node_class_name: String) -> Node3D:
	"""Recursively search for a node by class name."""
	if node.get_class() == node_class_name and node is Node3D:
		return node as Node3D

	for child in node.get_children():
		var result = _find_node_by_class(child, node_class_name)
		if is_instance_valid(result):
			return result

	return null


## Public API: Check if a planet has terrain generated
func has_terrain(planet_name: String) -> bool:
	"""Check if a planet has terrain generated."""
	return planets_with_terrain.has(planet_name)


## Public API: Force terrain generation for a specific planet
func generate_terrain(planet: CelestialBody) -> void:
	"""Force terrain generation for a specific planet."""
	if not is_instance_valid(planet):
		push_error("[PlanetTerrainManager] Invalid planet reference")
		return

	if planets_with_terrain.has(planet.body_name):
		if debug_mode:
			print("[PlanetTerrainManager] Terrain already exists for %s" % planet.body_name)
		return

	_generate_terrain_for_planet(planet)


## Public API: Clear terrain from a planet (for cleanup/testing)
func clear_terrain(planet: CelestialBody) -> void:
	"""Remove terrain from a planet."""
	if not is_instance_valid(planet):
		return

	var terrain_node = planet.get_node_or_null("VoxelTerrain")
	if is_instance_valid(terrain_node):
		terrain_node.queue_free()
		planets_with_terrain.erase(planet.body_name)
		if debug_mode:
			print("[PlanetTerrainManager] Cleared terrain for %s" % planet.body_name)
