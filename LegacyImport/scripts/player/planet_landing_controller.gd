extends Node
class_name PlanetLandingController
## Detects when spacecraft lands on planet surfaces and triggers walking mode transition
##
## Requirements:
## - Monitors spacecraft collision with planets
## - Detects landing events based on safe velocity threshold
## - Triggers transition from spacecraft to walking mode
## - Integrates with existing TransitionSystem

## Emitted when landing on a planet is detected
signal landing_detected(planet: CelestialBody, contact_point: Vector3, surface_normal: Vector3)

## Emitted when transitioning to walking mode
signal transition_to_walking(planet: CelestialBody)

## Emitted when landing is too fast (crash)
signal landing_too_fast(planet: CelestialBody, impact_speed: float)

## Maximum safe landing velocity (game units/sec)
## Above this speed, landing is considered a crash
@export var max_landing_velocity: float = 5.0

## Minimum time between landing checks (prevents rapid re-triggers)
@export var landing_cooldown: float = 2.0

## Auto-transition to walking mode on safe landing
@export var auto_enable_walking: bool = true

## Reference to spacecraft RigidBody3D
var spacecraft: Spacecraft = null

## Reference to transition system
var transition_system: TransitionSystem = null

## Whether we're currently in spacecraft mode
var in_spacecraft_mode: bool = true

## Cooldown timer for landing detection
var cooldown_timer: float = 0.0

## Last collision time
var last_collision_time: float = 0.0


func _ready() -> void:
	# Start inactive
	set_process(false)


func _process(delta: float) -> void:
	# Update cooldown timer
	if cooldown_timer > 0.0:
		cooldown_timer -= delta


## Initialize the landing controller
## @param craft: Reference to the spacecraft node
## @param trans_system: Reference to the transition system
func initialize(craft: Spacecraft, trans_system: TransitionSystem) -> void:
	spacecraft = craft
	transition_system = trans_system

	if not spacecraft:
		push_error("[PlanetLandingController] Spacecraft reference is null")
		return

	if not transition_system:
		push_error("[PlanetLandingController] TransitionSystem reference is null")
		return

	# Connect to spacecraft collision signal
	if not spacecraft.body_entered.is_connected(_on_spacecraft_body_entered):
		spacecraft.body_entered.connect(_on_spacecraft_body_entered)
		print("[PlanetLandingController] Connected to spacecraft body_entered signal")

	# Start processing
	set_process(true)

	print("[PlanetLandingController] Initialized successfully")


## Handle spacecraft collision - check if landing on planet
## @param body: The Node that the spacecraft collided with
func _on_spacecraft_body_entered(body: Node) -> void:
	# Check cooldown
	if cooldown_timer > 0.0:
		return

	# Only process if in spacecraft mode
	if not in_spacecraft_mode:
		return

	# Check if collided with a celestial body (planet)
	var celestial_body: CelestialBody = null

	if body is CelestialBody:
		celestial_body = body
	elif body.get_parent() is CelestialBody:
		celestial_body = body.get_parent()

	if not celestial_body:
		return  # Not a planet

	# Only process planets and moons (not stars)
	if celestial_body.body_type == CelestialBody.BodyType.STAR:
		print("[PlanetLandingController] Ignoring collision with star: ", celestial_body.body_name)
		return

	# Get current velocity
	var velocity: Vector3 = Vector3.ZERO
	if spacecraft is RigidBody3D:
		velocity = spacecraft.linear_velocity
	elif spacecraft.has_method("get_velocity"):
		velocity = spacecraft.get_velocity()

	# Calculate impact speed
	var impact_speed := velocity.length()

	print("[PlanetLandingController] Collision with %s detected - Impact speed: %.2f" % [celestial_body.body_name, impact_speed])

	# Check landing velocity
	if impact_speed > max_landing_velocity:
		print("[PlanetLandingController] Impact too fast: %.2f > %.2f (crash)" % [impact_speed, max_landing_velocity])
		landing_too_fast.emit(celestial_body, impact_speed)
		# Set cooldown to prevent spam
		cooldown_timer = landing_cooldown
		return

	# Safe landing detected!
	print("[PlanetLandingController] Safe landing detected on %s" % celestial_body.body_name)

	# Calculate contact point and surface normal
	var contact_point = spacecraft.global_position
	var surface_normal = (spacecraft.global_position - celestial_body.global_position).normalized()

	print("[PlanetLandingController] Contact point: %s" % contact_point)
	print("[PlanetLandingController] Surface normal: %s" % surface_normal)

	landing_detected.emit(celestial_body, contact_point, surface_normal)

	# Trigger transition to walking mode
	if auto_enable_walking:
		_transition_to_walking_mode(celestial_body, contact_point, surface_normal)

	# Set cooldown
	cooldown_timer = landing_cooldown


## Transition from spacecraft to walking mode
## Uses the existing TransitionSystem to handle the actual transition
## @param planet: The planet being landed on
## @param spawn_point: Position to spawn the player
## @param surface_normal: Normal vector of the surface
func _transition_to_walking_mode(planet: CelestialBody, spawn_point: Vector3, surface_normal: Vector3) -> void:
	if not transition_system:
		push_error("[PlanetLandingController] Cannot transition - TransitionSystem is null")
		return

	print("[PlanetLandingController] Transitioning to walking mode on %s" % planet.body_name)

	# Calculate planet gravity for logging
	var gravity_magnitude := calculate_surface_gravity(planet.mass, planet.radius)
	print("[PlanetLandingController] Planet gravity: %.2f m/s²" % gravity_magnitude)

	# Disable spacecraft physics temporarily to prevent drift
	if spacecraft is RigidBody3D:
		spacecraft.linear_velocity = Vector3.ZERO
		spacecraft.angular_velocity = Vector3.ZERO
		spacecraft.freeze = true

	# Use TransitionSystem to enable walking mode
	# The TransitionSystem will handle:
	# - Creating/initializing WalkingController
	# - Setting gravity
	# - Managing VR camera
	# - Disabling spacecraft controls
	transition_system.on_spacecraft_landed()
	transition_system.enable_walking_mode()

	in_spacecraft_mode = false
	transition_to_walking.emit(planet)

	print("[PlanetLandingController] Transition complete")


## Calculate surface gravity for a planet
## Returns gravity in game units/s²
## Formula: g = G * M / r²
## @param planet_mass: Mass of the planet in kg
## @param planet_radius: Radius of the planet in game units (1 unit = 1 million meters)
func calculate_surface_gravity(planet_mass: float, planet_radius: float) -> float:
	if planet_radius <= 0:
		return 0.0

	# Gravitational constant (scaled for game units: 1 unit = 1 million meters)
	const G_SCALED := 6.674e-23

	# g = G * M / r²
	var gravity := G_SCALED * planet_mass / (planet_radius * planet_radius)

	return gravity


## Re-enable spacecraft mode (called when returning from walking mode)
func enable_spacecraft_mode() -> void:
	in_spacecraft_mode = true

	# Re-enable spacecraft physics
	if spacecraft is RigidBody3D:
		spacecraft.freeze = false

	print("[PlanetLandingController] Spacecraft mode re-enabled")


## Disable spacecraft mode (called when entering walking mode)
func disable_spacecraft_mode() -> void:
	in_spacecraft_mode = false
	print("[PlanetLandingController] Spacecraft mode disabled")


## Get current mode state
func is_in_spacecraft_mode() -> bool:
	return in_spacecraft_mode


## Get landing cooldown remaining
func get_cooldown_remaining() -> float:
	return cooldown_timer


## Set max landing velocity threshold
func set_max_landing_velocity(velocity: float) -> void:
	max_landing_velocity = max(velocity, 0.1)
	print("[PlanetLandingController] Max landing velocity set to: %.2f" % max_landing_velocity)


## Get max landing velocity threshold
func get_max_landing_velocity() -> float:
	return max_landing_velocity
