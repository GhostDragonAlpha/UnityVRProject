extends Node3D

## VR main scene with realistic N-body gravity
## Implements 1:1 scale physics simulation

## Reference to XROrigin3D for applying gravity
@onready var xr_origin: XROrigin3D = $XROrigin3D

## Reference to player collision body
@onready var player_body: CharacterBody3D = $XROrigin3D/PlayerCollision

## Reference to solar system for celestial bodies (optional)
## If not present in scene, gravity simulation will be disabled
@onready var solar_system: Node3D = get_node_or_null("SolarSystem")

## Player velocity (for N-body physics)
var velocity: Vector3 = Vector3.ZERO

## Whether player is on ground
var is_grounded: bool = false

## Player mass in kg (average human mass)
const PLAYER_MASS: float = 70.0

## Gravitational constant (matching celestial body system)
## For "1 unit = 1 million meters" with masses in kg
const G: float = 6.674e-23

## Minimum distance for gravity calculations
const MIN_GRAVITY_DISTANCE: float = 0.1

## Maximum distance for gravity calculations (1000 units = 1 billion km)
## Bodies beyond this distance have negligible gravitational effect
const MAX_GRAVITY_RADIUS: float = 1000.0

## Enable/disable gravity simulation
var gravity_enabled: bool = false

## Enable/disable physics movement (for VR tracking testing)
## Set to false to test pure VR tracking without physics interference
@export var physics_movement_enabled: bool = true

func _ready():
	print("[VRMain] Scene loaded successfully")

	# Initialize OpenXR if available
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface:
		print("[VRMain] Found OpenXR interface")
		if xr_interface.initialize():
			print("[VRMain] OpenXR initialized successfully")
			get_viewport().use_xr = true
			print("[VRMain] Viewport marked for XR rendering")

			# Disable fallback camera FIRST
			$XROrigin3D/FallbackCamera.current = false
			print("[VRMain] Fallback camera disabled")

			# Switch to XR Camera safely
			print("[VRMain] CAMERA FIX START: About to switch cameras...")
			$XROrigin3D/XRCamera3D.current = true
			print("[VRMain] XRCamera3D is now active")
		else:
			print("[VRMain] OpenXR initialization failed")
	else:
		print("[VRMain] OpenXR not available - running in desktop mode")
		# Keep Fallback Camera active


	# Initialize player at a safe starting position
	# Place player in orbit around Earth (if available)
	call_deferred("_initialize_player_position")


func _initialize_player_position() -> void:
	"""Initialize player position for Solar System exploration."""
	# NOTE: Voxel terrain testing spawn disabled
	# var spawn_position = Vector3(0, 0.9, 0)
	# xr_origin.global_position = spawn_position
	# velocity = Vector3.ZERO

	# If physics movement is disabled, skip position initialization
	# This allows pure VR tracking without physics interference
	if not physics_movement_enabled:
		print("[VRMain] Physics movement disabled - VR tracking only mode")
		return

	print("[VRMain] Initializing player in Earth Orbit...")

	# Check if solar system is available
	if not is_instance_valid(solar_system):
		push_warning("[VRMain] Solar System not found - using default spawn position")
		print("[VRMain] Initializing player at origin (VR test mode)")
		xr_origin.global_position = Vector3(0, 1.7, 0)
		velocity = Vector3.ZERO
		return
		
	# Wait for solar system to initialize if needed
	if solar_system.has_method("is_initialized") and not solar_system.is_initialized():
		print("[VRMain] Waiting for Solar System initialization...")
		await solar_system.solar_system_initialized
		
	if solar_system.has_method("get_body"):
		var earth = solar_system.get_body("earth")
		if is_instance_valid(earth):
			# Spawn in orbit (Earth Radius + 400km ISS height)
			# 1 unit = 1000km, so 400km = 0.4 units
			# Earth Radius is approx 6.371 units
			var orbit_altitude = 0.4 
			var orbit_radius = earth.radius + orbit_altitude
			
			var start_position = Vector3(orbit_radius, 0, 0) + earth.global_position
			xr_origin.global_position = start_position
			
			# Calculate orbital velocity for circular orbit: v = sqrt(G*M/r)
			var orbit_speed = sqrt(G * earth.mass / orbit_radius)
			
			# Velocity perpendicular to position (tangent)
			velocity = Vector3(0, 0, orbit_speed)
			
			print("[VRMain] Player spawned in Earth Orbit")
			print("[VRMain] Altitude: ", orbit_altitude * 1000, " km")
			print("[VRMain] Velocity: ", orbit_speed, " km/s")
			
			# Enable gravity now that we are safe
			gravity_enabled = true
			print("[VRMain] Gravity Simulation ENABLED")
		else:
			push_error("[VRMain] Earth not found in Solar System!")


func _physics_process(delta: float) -> void:
	"""Handle physics - different behavior for VR Player vs AI Training modes."""

	if not is_instance_valid(xr_origin) or not is_instance_valid(player_body):
		return

	# VR PLAYER MODE: VR tracking controls position, physics provides collision feedback
	if not physics_movement_enabled:
		_vr_player_mode_physics(delta)
		return

	# AI TRAINING MODE: AI/physics controls position, VR follows for observation
	if gravity_enabled:
		_ai_training_mode_physics(delta)


## VR Player Mode Physics: CharacterBody3D FOLLOWS XROrigin3D
func _vr_player_mode_physics(delta: float) -> void:
	# DON'T manually set position - CharacterBody3D is child of XROrigin3D
	# It automatically follows parent transform
	# Manual position setting was breaking XR tracking!

	# Apply local gravity for ground detection
	if not player_body.is_on_floor():
		velocity.y -= 9.8 * delta  # Standard Earth gravity
	else:
		velocity.y = 0
		is_grounded = true

	# Move with collision detection (but position is set by VR tracking)
	player_body.velocity = Vector3(0, velocity.y, 0)
	player_body.move_and_slide()

	# Sync grounded state
	is_grounded = player_body.is_on_floor()

	# Debug output every 60 frames
	if Engine.get_physics_frames() % 60 == 0:
		var xr_camera = $XROrigin3D/XRCamera3D
		print("[VRMain] VR PLAYER MODE | XROrigin pos: ", xr_origin.global_position,
		      " | XRCamera pos: ", xr_camera.global_position if xr_camera else "NULL",
		      " | CharBody pos: ", player_body.global_position)


## AI Training Mode Physics: XROrigin3D FOLLOWS CharacterBody3D
func _ai_training_mode_physics(delta: float) -> void:
	# Calculate total gravitational acceleration from all celestial bodies
	var total_acceleration = _calculate_total_gravity()

	# Update velocity using acceleration
	velocity += total_acceleration * delta

	# Apply velocity to CharacterBody3D
	player_body.velocity = velocity

	# Move and handle collisions (AI controls position)
	player_body.move_and_slide()

	# Sync XROrigin3D to follow physics body (for VR observation)
	xr_origin.global_position = player_body.global_position

	# Check if on ground
	is_grounded = player_body.is_on_floor()

	# If grounded, prevent bouncing by dampening downward velocity
	if is_grounded:
		var floor_normal = player_body.get_floor_normal()
		var velocity_along_normal = velocity.dot(floor_normal)
		if velocity_along_normal < 0:
			velocity -= floor_normal * velocity_along_normal
			velocity *= 0.95

	# Sync the actual velocity back (move_and_slide modifies it)
	velocity = player_body.velocity

	# Debug output (every 60 frames ~= 1 second at 60fps)
	if Engine.get_physics_frames() % 60 == 0:
		var closest_body = _get_closest_body()
		if is_instance_valid(closest_body):
			var distance = (closest_body.global_position - xr_origin.global_position).length()
			var ground_status = "GROUNDED" if is_grounded else "FALLING"
			print("[VRMain] ", ground_status, " | Closest: ", closest_body.body_name,
				  " | Distance: ", "%.2f" % distance, " units",
				  " | Velocity: ", "%.4f" % velocity.length(), " units/s")


func _calculate_total_gravity() -> Vector3:
	"""Calculate total gravitational acceleration from all celestial bodies."""
	if not is_instance_valid(solar_system):
		return Vector3.ZERO

	var total_acceleration = Vector3.ZERO
	var player_pos = xr_origin.global_position

	# Get all celestial bodies
	if solar_system.has_method("get_all_bodies"):
		var bodies = solar_system.get_all_bodies()

		for body in bodies:
			if not is_instance_valid(body):
				continue

			# Calculate distance once
			var direction = body.global_position - player_pos
			var distance = direction.length()

			# DISTANCE CULLING OPTIMIZATION: Skip distant bodies
			# Bodies beyond MAX_GRAVITY_RADIUS have negligible gravitational effect
			if distance > MAX_GRAVITY_RADIUS:
				continue


			# Prevent division by zero
			if distance < MIN_GRAVITY_DISTANCE:
				distance = MIN_GRAVITY_DISTANCE

			# Gravitational acceleration: a = G * M / r²
			var acceleration_magnitude = G * body.mass / (distance * distance)
			var acceleration = direction.normalized() * acceleration_magnitude

			total_acceleration += acceleration

	return total_acceleration


func _get_closest_body() -> Node:
	"""Get the closest celestial body to the player."""
	if not is_instance_valid(solar_system):
		return null

	if not solar_system.has_method("get_all_bodies"):
		return null

	var bodies = solar_system.get_all_bodies()
	var player_pos = xr_origin.global_position
	var closest_body = null
	var closest_distance = INF

	for body in bodies:
		if not is_instance_valid(body):
			continue

		var distance = (body.global_position - player_pos).length()
		if distance < closest_distance:
			closest_distance = distance
			closest_body = body

	return closest_body
