## SolarSystemLandingController - Main Scene Controller
## Manages the solar system landing scene, including terrain generation,
## player tracking, and VR initialization.
##
## Requirements: Planetary Landing System Phase 1
## - Initialize solar system and terrain manager
## - Track player position and state
## - Provide debug information and commands
extends Node3D
class_name SolarSystemLandingController

## References to key nodes
@onready var solar_system: SolarSystemInitializer = $SolarSystemInitializer
@onready var player_origin: Node3D = $XROrigin3D
@onready var spacecraft: Node3D = $PlayerSpacecraft

## Terrain manager instance
var terrain_manager: PlanetaryTerrainManager = null

## VR initialized flag
var vr_initialized: bool = false

## Debug display enabled
var debug_display_enabled: bool = true


func _ready() -> void:
	print("[SolarSystemLandingController] Initializing scene...")

	# Initialize VR
	_initialize_vr()

	# Wait for solar system to initialize
	if not solar_system.is_initialized():
		await solar_system.solar_system_initialized

	# Create and configure terrain manager
	_create_terrain_manager()

	print("[SolarSystemLandingController] Scene ready")


## Initialize VR if available
func _initialize_vr() -> void:
	"""Initialize OpenXR VR interface."""
	var xr_interface := XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("[SolarSystemLandingController] OpenXR already initialized")
		vr_initialized = true
		return

	if xr_interface:
		if xr_interface.initialize():
			print("[SolarSystemLandingController] OpenXR initialized successfully")
			var viewport := get_viewport()
			viewport.use_xr = true
			vr_initialized = true

			# Switch to XR camera
			var xr_camera := player_origin.get_node_or_null("XRCamera3D")
			var fallback_camera := player_origin.get_node_or_null("FallbackCamera")
			if xr_camera:
				xr_camera.current = true
			if fallback_camera:
				fallback_camera.current = false
		else:
			push_warning("[SolarSystemLandingController] Failed to initialize OpenXR - using desktop mode")
	else:
		print("[SolarSystemLandingController] OpenXR not available - using desktop mode")


## Create and initialize terrain manager
func _create_terrain_manager() -> void:
	"""Create PlanetaryTerrainManager and attach to scene."""
	terrain_manager = PlanetaryTerrainManager.new()
	terrain_manager.name = "PlanetaryTerrainManager"

	# Add as child first so paths can be resolved
	add_child(terrain_manager)

	# Configure node paths (now that terrain_manager is in the tree)
	terrain_manager.solar_system_initializer = terrain_manager.get_path_to(solar_system)
	terrain_manager.player_node = terrain_manager.get_path_to(player_origin)

	# Configure settings
	terrain_manager.enable_terrain_unloading = false  # Keep terrain loaded for Phase 1
	terrain_manager.enable_performance_monitoring = true

	# Connect signals
	terrain_manager.terrain_generation_started.connect(_on_terrain_generation_started)
	terrain_manager.terrain_generation_completed.connect(_on_terrain_generation_completed)
	terrain_manager.terrain_unloaded.connect(_on_terrain_unloaded)

	print("[SolarSystemLandingController] Terrain manager initialized")


## Signal handlers
func _on_terrain_generation_started(planet: CelestialBody) -> void:
	print("[SolarSystemLandingController] Terrain generation started for %s" % planet.body_name)


func _on_terrain_generation_completed(planet: CelestialBody, terrain: Node3D) -> void:
	print("[SolarSystemLandingController] Terrain generation completed for %s" % planet.body_name)
	if terrain:
		print("  Terrain node: %s" % terrain.get_path())


func _on_terrain_unloaded(planet: CelestialBody) -> void:
	print("[SolarSystemLandingController] Terrain unloaded for %s" % planet.body_name)


## Process loop for debug display
func _process(_delta: float) -> void:
	if not debug_display_enabled:
		return

	# Print debug info periodically (every 2 seconds)
	if Engine.get_frames_drawn() % 120 == 0:  # Assuming 60 FPS
		_print_debug_info()


## Print debug information
func _print_debug_info() -> void:
	"""Print current state for debugging."""
	if terrain_manager == null:
		return

	var status := terrain_manager.get_status_report()

	print("\n[DEBUG] Solar System Status:")
	print("  Total planets: %d" % status["total_planets"])
	print("  Terrain generated: %d" % status["generated_count"])
	print("  Player position: %s" % str(player_origin.global_position))

	# Find closest planet
	var closest_planet: CelestialBody = null
	var closest_distance := INF

	for planet_name in status["planets"]:
		var planet_data: Dictionary = status["planets"][planet_name]
		var distance: float = planet_data["distance"]

		if distance < closest_distance:
			closest_distance = distance
			# Get planet object
			closest_planet = solar_system.get_body(planet_name)

	if closest_planet:
		var planet_data: Dictionary = status["planets"][closest_planet.name.to_lower()]
		print("  Closest planet: %s (%.1f units, threshold: %.1f, generated: %s)"
			% [closest_planet.body_name, closest_distance, planet_data["threshold"], planet_data["generated"]])


## Input handling for debug commands
func _input(event: InputEvent) -> void:
	# F1: Toggle debug display
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		debug_display_enabled = not debug_display_enabled
		print("[SolarSystemLandingController] Debug display: %s" % ("enabled" if debug_display_enabled else "disabled"))

	# F2: Print full status report
	if event is InputEventKey and event.pressed and event.keycode == KEY_F2:
		_print_full_status_report()

	# F3: Force generate terrain for Earth
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		if terrain_manager:
			print("[SolarSystemLandingController] Force generating terrain for Earth...")
			terrain_manager.force_generate_terrain("earth")

	# F4: Force generate terrain for Mars
	if event is InputEventKey and event.pressed and event.keycode == KEY_F4:
		if terrain_manager:
			print("[SolarSystemLandingController] Force generating terrain for Mars...")
			terrain_manager.force_generate_terrain("mars")


## Print full status report
func _print_full_status_report() -> void:
	"""Print detailed status of all systems."""
	if terrain_manager == null:
		print("[SolarSystemLandingController] Terrain manager not initialized")
		return

	print("\n========== SOLAR SYSTEM LANDING STATUS ==========")

	# VR status
	print("\n[VR Status]")
	print("  VR Initialized: %s" % vr_initialized)

	# Solar system status
	print("\n[Solar System]")
	print("  Bodies: %d" % solar_system.get_body_count())
	print("  Planets: %d" % solar_system.get_planets().size())
	print("  Initialized: %s" % solar_system.is_initialized())

	# Terrain status
	print("\n[Terrain Manager]")
	var status := terrain_manager.get_status_report()
	print("  Total planets: %d" % status["total_planets"])
	print("  Generated terrains: %d" % status["generated_count"])

	# Planet details
	print("\n[Planet Details]")
	for planet_name in status["planets"]:
		var planet_data: Dictionary = status["planets"][planet_name]
		print("  %s:" % planet_data["name"])
		print("    Distance: %.1f units" % planet_data["distance"])
		print("    Threshold: %.1f units" % planet_data["threshold"])
		print("    Within threshold: %s" % planet_data["within_threshold"])
		print("    Generated: %s" % planet_data["generated"])

	# Player status
	print("\n[Player]")
	print("  Position: %s" % str(player_origin.global_position))

	# Performance monitor
	if has_node("/root/VoxelPerformanceMonitor"):
		var perf_monitor = get_node("/root/VoxelPerformanceMonitor")
		if perf_monitor.has_method("get_statistics"):
			var stats = perf_monitor.get_statistics()
			print("\n[Voxel Performance]")
			print("  Active chunks: %d" % stats.get("active_chunks", 0))
			print("  Avg generation time: %.2fms" % (stats.get("avg_generation_time", 0.0) * 1000.0))

	print("\n================================================\n")


## Public API for testing
func get_terrain_manager() -> PlanetaryTerrainManager:
	"""Get the terrain manager instance."""
	return terrain_manager


func get_player_position() -> Vector3:
	"""Get current player position."""
	return player_origin.global_position


func set_player_position(position: Vector3) -> void:
	"""Set player position (for testing)."""
	player_origin.global_position = position


func teleport_to_planet(planet_name: String, distance: float = 1000.0) -> bool:
	"""Teleport player near a planet."""
	var planet := solar_system.get_body(planet_name)
	if planet == null:
		push_error("[SolarSystemLandingController] Planet not found: %s" % planet_name)
		return false

	# Position player at specified distance from planet
	var direction := Vector3.FORWARD  # Arbitrary direction
	var target_pos := planet.global_position + (direction * distance)

	player_origin.global_position = target_pos
	print("[SolarSystemLandingController] Teleported to %s (distance: %.1f)" % [planet_name, distance])

	return true
