extends Node
class_name TransitionSystem
## Manages seamless transitions between space flight and planetary surface
## Handles LOD progression, atmospheric effects, and navigation mode switching

signal transition_started(planet: CelestialBody)
signal transition_completed(planet: CelestialBody)
signal atmosphere_entered(planet: CelestialBody)
signal atmosphere_exited(planet: CelestialBody)
signal surface_approached(altitude: float)
signal walking_mode_enabled
signal walking_mode_disabled

enum TransitionState {
	SPACE,           # In space, far from planets
	APPROACHING,     # Approaching a planet
	ATMOSPHERE,      # In planetary atmosphere
	SURFACE,         # Near or on surface
	LANDING,         # Landing sequence active
	WALKING          # Walking on planetary surface
}

@export var transition_altitude: float = 100000.0  # Altitude to start transition (m)
@export var atmosphere_altitude: float = 50000.0   # Altitude where atmosphere begins
@export var surface_altitude: float = 1000.0       # Altitude considered "near surface"
@export var transition_speed: float = 2.0          # Speed of LOD transitions

var current_state: TransitionState = TransitionState.SPACE
var target_planet: CelestialBody = null
var spacecraft: Node3D = null
var lod_manager: Node = null
var floating_origin: Node = null
var atmosphere_system: Node = null
var walking_controller: WalkingController = null
var vr_manager: VRManager = null

var current_altitude: float = 0.0
var transition_progress: float = 0.0
var is_landed: bool = false
var landing_controller: PlanetLandingController = null
var surface_spawner: PlanetSurfaceSpawner = null

func _ready() -> void:
	set_process(false)

func initialize(craft: Node3D, lod_mgr: Node, float_origin: Node, atmos: Node, vr_mgr: VRManager = null) -> void:
	spacecraft = craft
	lod_manager = lod_mgr
	floating_origin = float_origin
	atmosphere_system = atmos
	vr_manager = vr_mgr
	set_process(true)
	
	# Create walking controller
	create_walking_controller()
	# Create landing controller
	create_landing_controller()

	# Create surface spawner
	create_surface_spawner()

func _process(delta: float) -> void:
	if not spacecraft:
		return
	
	update_transition_state(delta)

func update_transition_state(delta: float) -> void:
	# Find nearest planet
	var nearest_planet = find_nearest_planet()
	
	if nearest_planet:
		current_altitude = calculate_altitude(nearest_planet)
		
		# State machine for transitions
		match current_state:
			TransitionState.SPACE:
				if current_altitude < transition_altitude:
					start_approach(nearest_planet)
			
			TransitionState.APPROACHING:
				if current_altitude < atmosphere_altitude:
					enter_atmosphere(nearest_planet)
				elif current_altitude > transition_altitude:
					return_to_space()
				else:
					update_approach_lod(delta)
			
			TransitionState.ATMOSPHERE:
				if current_altitude < surface_altitude:
					approach_surface()
				elif current_altitude > atmosphere_altitude:
					exit_atmosphere()
				else:
					update_atmospheric_effects(delta)
			
			TransitionState.SURFACE:
				if current_altitude > surface_altitude:
					leave_surface()
				else:
					update_surface_mode(delta)
	else:
		# No nearby planet, ensure we're in space mode
		if current_state != TransitionState.SPACE:
			return_to_space()

func find_nearest_planet() -> CelestialBody:
	# Get all celestial bodies from the scene
	var celestial_bodies = get_tree().get_nodes_in_group("celestial_bodies")
	var nearest: CelestialBody = null
	var min_distance: float = INF
	
	for body in celestial_bodies:
		if body is CelestialBody and body.body_type in ["planet", "moon"]:
			var distance = spacecraft.global_position.distance_to(body.global_position)
			if distance < min_distance:
				min_distance = distance
				nearest = body
	
	return nearest

func calculate_altitude(planet: CelestialBody) -> float:
	var distance = spacecraft.global_position.distance_to(planet.global_position)
	return distance - planet.radius

func start_approach(planet: CelestialBody) -> void:
	print("Starting approach to ", planet.body_name)
	current_state = TransitionState.APPROACHING
	target_planet = planet
	transition_progress = 0.0
	transition_started.emit(planet)
	
	# Begin progressive LOD increase
	if lod_manager:
		lod_manager.set_target_detail_level(planet, 1)

func update_approach_lod(delta: float) -> void:
	if not target_planet or not lod_manager:
		return
	
	# Calculate LOD level based on altitude
	var altitude_ratio = current_altitude / transition_altitude
	var detail_level = 1.0 + (1.0 - altitude_ratio) * 2.0  # 1.0 to 3.0
	
	# Smoothly increase terrain detail
	lod_manager.set_target_detail_level(target_planet, detail_level)
	
	# Maintain floating origin during transition
	if floating_origin:
		floating_origin.update(spacecraft.global_position)

func enter_atmosphere(planet: CelestialBody) -> void:
	print("Entering atmosphere of ", planet.body_name)
	current_state = TransitionState.ATMOSPHERE
	atmosphere_entered.emit(planet)
	
	# Activate atmospheric effects with spacecraft reference
	if atmosphere_system:
		atmosphere_system.activate(planet, spacecraft)
	
	# Increase LOD further
	if lod_manager:
		lod_manager.set_target_detail_level(planet, 3)

func update_atmospheric_effects(delta: float) -> void:
	if not atmosphere_system or not target_planet or not spacecraft:
		return
	
	# Update atmospheric effects based on altitude
	var atmosphere_depth = atmosphere_altitude - current_altitude
	var atmosphere_ratio = clamp(atmosphere_depth / atmosphere_altitude, 0.0, 1.0)
	
	# Get spacecraft velocity
	var velocity = Vector3.ZERO
	if spacecraft is RigidBody3D:
		velocity = spacecraft.linear_velocity
	elif spacecraft.has_method("get_velocity"):
		velocity = spacecraft.get_velocity()
	
	atmosphere_system.update_effects(atmosphere_ratio, velocity)

func approach_surface() -> void:
	print("Approaching surface")
	current_state = TransitionState.SURFACE
	surface_approached.emit(current_altitude)
	
	# Switch to surface LOD mode
	if lod_manager:
		lod_manager.switch_to_surface_mode(target_planet)
	
	# Enable surface navigation mode
	enable_surface_navigation()

func update_surface_mode(delta: float) -> void:
	# Update high-detail terrain streaming
	if lod_manager:
		lod_manager.update_surface_streaming(spacecraft.global_position)
	
	# Maintain floating origin
	if floating_origin:
		floating_origin.update(spacecraft.global_position)

func enable_surface_navigation() -> void:
	# Switch spacecraft to surface navigation mode
	if spacecraft.has_method("set_navigation_mode"):
		spacecraft.set_navigation_mode("surface")
	
	print("Surface navigation enabled")

func exit_atmosphere() -> void:
	print("Exiting atmosphere")
	current_state = TransitionState.APPROACHING
	atmosphere_exited.emit(target_planet)
	
	# Deactivate atmospheric effects
	if atmosphere_system:
		atmosphere_system.deactivate()
	
	# Reduce LOD
	if lod_manager:
		lod_manager.set_target_detail_level(target_planet, 2)

func leave_surface() -> void:
	print("Leaving surface")
	current_state = TransitionState.ATMOSPHERE
	
	# Switch back to orbital LOD mode
	if lod_manager:
		lod_manager.switch_to_orbital_mode(target_planet)
	
	# Disable surface navigation mode
	disable_surface_navigation()

func disable_surface_navigation() -> void:
	# Switch spacecraft back to space navigation mode
	if spacecraft.has_method("set_navigation_mode"):
		spacecraft.set_navigation_mode("space")
	
	print("Space navigation enabled")

func return_to_space() -> void:
	print("Returning to space")
	current_state = TransitionState.SPACE
	
	if target_planet:
		transition_completed.emit(target_planet)
	
	target_planet = null
	transition_progress = 0.0
	
	# Reset LOD to space mode
	if lod_manager:
		lod_manager.reset_to_space_mode()
	
	# Deactivate atmospheric effects
	if atmosphere_system:
		atmosphere_system.deactivate()

func get_transition_state() -> TransitionState:
	return current_state

func get_current_altitude() -> float:
	return current_altitude

func get_target_planet() -> CelestialBody:
	return target_planet

func is_in_transition() -> bool:
	return current_state != TransitionState.SPACE

## Create the walking controller instance
func create_walking_controller() -> void:
	# Create landing controller
	if walking_controller:
		return
	
	# Load the walking controller scene
	var walking_scene = load("res://scenes/player/walking_controller.tscn")
	if walking_scene:
		walking_controller = walking_scene.instantiate()
		add_child(walking_controller)
		
		# Connect signals
		walking_controller.returned_to_spacecraft.connect(_on_returned_to_spacecraft)
		
		print("[TransitionSystem] Walking controller created")
	else:
		print("[TransitionSystem] ERROR: Could not load walking controller scene")

## Enable walking mode on planetary surface
## Requirements: 52.1, 52.5
func enable_walking_mode() -> void:
	if not walking_controller or not target_planet or not spacecraft:
		print("[TransitionSystem] Cannot enable walking mode - missing components")
		return
	
	if current_state == TransitionState.WALKING:
		print("[TransitionSystem] Already in walking mode")
		return
	

	# Use surface spawner to calculate proper spawn position
	if surface_spawner:
		var spawn_result = surface_spawner.calculate_spawn_near_spacecraft(
			target_planet,
			spacecraft,
			Vector3(0, 0, 3),  # 3m in front of spacecraft
			walking_controller
		)
		if not spawn_result.success:
			push_error("[TransitionSystem] Failed to calculate spawn position: " + spawn_result.get("error", "Unknown error"))
			return
		print("[TransitionSystem] Using calculated spawn position: ", spawn_result.position)
	else:
		# Fallback if no spawner available
		var spawn_position = spacecraft.global_position + Vector3(0, 2, 3)
		walking_controller.initialize(vr_manager, target_planet, spawn_position, spacecraft)




	walking_controller.activate()
	
	# Hide/disable spacecraft controls
	if spacecraft.has_method("disable_flight_controls"):
		spacecraft.disable_flight_controls()
	
	# Update state
	current_state = TransitionState.WALKING
	is_landed = true
	
	walking_mode_enabled.emit()
	print("[TransitionSystem] Walking mode enabled")

## Disable walking mode and return to spacecraft
## Requirements: 52.5
func disable_walking_mode() -> void:
	if not walking_controller:
		return
	
	if current_state != TransitionState.WALKING:
		return
	
	# Deactivate walking controller
	walking_controller.deactivate()
	
	# Re-enable spacecraft controls
	if spacecraft.has_method("enable_flight_controls"):
		spacecraft.enable_flight_controls()
	
	# Return to surface state
	current_state = TransitionState.SURFACE
	
	walking_mode_disabled.emit()
	print("[TransitionSystem] Walking mode disabled")

## Handle return to spacecraft signal
func _on_returned_to_spacecraft() -> void:
	disable_walking_mode()
	# Re-enable spacecraft mode in landing controller
	if landing_controller:
		landing_controller.enable_spacecraft_mode()

## Check if walking mode is active
func is_walking_mode_active() -> bool:
	return current_state == TransitionState.WALKING

## Get the walking controller
func get_walking_controller() -> WalkingController:
	return walking_controller

## Handle landing on surface
func on_spacecraft_landed() -> void:
	is_landed = true
	print("[TransitionSystem] Spacecraft landed - walking mode available")


## Create the landing controller instance
func create_landing_controller() -> void:
	if landing_controller:
		return

	# Create landing controller node
	landing_controller = PlanetLandingController.new()
	landing_controller.name = "PlanetLandingController"
	add_child(landing_controller)

	# Initialize with spacecraft and this transition system
	if spacecraft is Spacecraft:
		landing_controller.initialize(spacecraft, self)

		# Connect signals
		landing_controller.landing_detected.connect(_on_landing_detected)
		landing_controller.landing_too_fast.connect(_on_landing_too_fast)

		print("[TransitionSystem] Landing controller created and initialized")
	else:
		print("[TransitionSystem] WARNING: Spacecraft is not of type Spacecraft, landing controller not initialized")


## Handle landing detected signal
func _on_landing_detected(planet: CelestialBody, contact_point: Vector3, surface_normal: Vector3) -> void:
	print("[TransitionSystem] Landing detected on %s at %s" % [planet.body_name, contact_point])
	target_planet = planet


## Handle landing too fast signal (crash)
func _on_landing_too_fast(planet: CelestialBody, impact_speed: float) -> void:
	if landing_controller:
		print("[TransitionSystem] WARNING: Landing too fast on %s (%.2f > %.2f)" % [planet.body_name, impact_speed, landing_controller.max_landing_velocity])
	# Could trigger crash effects, damage, etc.


## Get the landing controller
func get_landing_controller() -> PlanetLandingController:
	return landing_controller

## Create the surface spawner instance
func create_surface_spawner() -> void:
	if surface_spawner:
		return

	# Create surface spawner node
	surface_spawner = PlanetSurfaceSpawner.new()
	surface_spawner.name = "PlanetSurfaceSpawner"
	add_child(surface_spawner)

	# Connect signals
	surface_spawner.spawn_point_calculated.connect(_on_spawn_point_calculated)
	surface_spawner.spawn_failed.connect(_on_spawn_failed)

	print("[TransitionSystem] Surface spawner created")


## Handle spawn point calculated signal
func _on_spawn_point_calculated(position: Vector3, orientation: Basis, gravity: Vector3) -> void:
	print("[TransitionSystem] Spawn point calculated at ", position)


## Handle spawn failed signal
func _on_spawn_failed(reason: String) -> void:
	push_error("[TransitionSystem] Spawn failed: " + reason)


## Get the surface spawner
func get_surface_spawner() -> PlanetSurfaceSpawner:
	return surface_spawner
