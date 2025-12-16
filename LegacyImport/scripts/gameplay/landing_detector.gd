extends Node3D
class_name LandingDetector
## Detects when spacecraft has landed on a surface and enables walking mode
##
## Requirements:
## - Detect low altitude (< 10m above surface)
## - Detect low velocity (< 5 m/s)
## - Show prompt to exit spacecraft
## - Transition from flight to walking mode

signal landing_detected(spacecraft: Node3D, planet: CelestialBody)
signal walking_mode_requested
signal spacecraft_takeoff

## Detection parameters
@export var landing_altitude_threshold: float = 10.0  # meters above surface
@export var landing_velocity_threshold: float = 5.0   # m/s
@export var check_interval: float = 0.5  # seconds between checks

## References
var spacecraft: Node3D = null
var planet: CelestialBody = null
var transition_system: TransitionSystem = null
var vr_controller: Node = null  # MoonLandingVRController reference

## State
var is_landed: bool = false
var can_exit_spacecraft: bool = false
var check_timer: float = 0.0

## Ground detection
var ground_raycast: RayCast3D = null


func _ready() -> void:
	# Create ground detection raycast
	ground_raycast = RayCast3D.new()
	ground_raycast.name = "GroundRaycast"
	ground_raycast.target_position = Vector3(0, -landing_altitude_threshold * 2, 0)
	ground_raycast.enabled = true
	ground_raycast.collide_with_areas = false
	ground_raycast.collide_with_bodies = true
	add_child(ground_raycast)

	set_process(false)


## Initialize the landing detector
func initialize(craft: Node3D, target_planet: CelestialBody, trans_sys: TransitionSystem = null) -> void:
	spacecraft = craft
	planet = target_planet
	transition_system = trans_sys

	# Position at spacecraft location
	if spacecraft:
		global_position = spacecraft.global_position

	set_process(true)
	print("[LandingDetector] Initialized for planet: ", planet.body_name if planet else "Unknown")


func _process(delta: float) -> void:
	if not spacecraft:
		return

	# Update position to follow spacecraft
	global_position = spacecraft.global_position

	# Orient raycast toward planet center if we have a planet
	if planet:
		var to_planet = (planet.global_position - global_position).normalized()
		ground_raycast.target_position = to_planet * landing_altitude_threshold * 2

	# Check for landing periodically
	check_timer += delta
	if check_timer >= check_interval:
		check_timer = 0.0
		check_landing_conditions()

	# Check for takeoff if currently landed
	if is_landed:
		check_takeoff_conditions()

	# Check VR input for exiting spacecraft
	_process_vr_input()


func _input(event: InputEvent) -> void:
	# Handle SPACE key to exit spacecraft (desktop mode)
	if event is InputEventKey:
		if event.keycode == KEY_SPACE and event.pressed and not event.echo:
			if can_exit_spacecraft:
				request_walking_mode()


func _process_vr_input() -> void:
	"""Check VR controller input for exiting spacecraft."""
	if not vr_controller or not can_exit_spacecraft:
		return

	# Get VR manager from VR controller
	var vr_manager = vr_controller.get_vr_manager() if vr_controller.has_method("get_vr_manager") else null
	if not vr_manager or not vr_manager.is_vr_active():
		return

	# Check if A/X button is pressed on right controller (exit spacecraft)
	var right_state = vr_manager.get_controller_state("right")
	if right_state.get("button_ax", false):
		request_walking_mode()


## Check if spacecraft has landed
func check_landing_conditions() -> void:
	if is_landed:
		return

	# Check if we're close to the ground
	if not ground_raycast.is_colliding():
		can_exit_spacecraft = false
		return

	var collision_point = ground_raycast.get_collision_point()
	var altitude = global_position.distance_to(collision_point)

	# Check altitude
	if altitude > landing_altitude_threshold:
		can_exit_spacecraft = false
		return

	# Check velocity
	var velocity = Vector3.ZERO
	if spacecraft is RigidBody3D:
		velocity = spacecraft.linear_velocity
	elif spacecraft.has_method("get_velocity"):
		velocity = spacecraft.get_velocity()

	var speed = velocity.length()

	# Check if velocity is low enough
	if speed > landing_velocity_threshold:
		can_exit_spacecraft = false
		return

	# All conditions met - we're landed!
	if not can_exit_spacecraft:
		can_exit_spacecraft = true
		is_landed = true
		on_landing_detected()


## Handle landing detection
func on_landing_detected() -> void:
	print("[LandingDetector] Landing detected! Altitude: ", get_altitude(), "m, Speed: ", get_speed(), " m/s")
	landing_detected.emit(spacecraft, planet)

	# Notify transition system if available
	if transition_system:
		transition_system.on_spacecraft_landed()


## Check if spacecraft has taken off
func check_takeoff_conditions() -> void:
	if not is_landed:
		return

	# Check if we've moved away from the ground
	var altitude = get_altitude()
	var speed = get_speed()

	# If we're high or fast, we've taken off
	if altitude > landing_altitude_threshold * 1.5 or speed > landing_velocity_threshold * 1.5:
		on_takeoff()


## Handle takeoff
func on_takeoff() -> void:
	print("[LandingDetector] Spacecraft taking off")
	is_landed = false
	can_exit_spacecraft = false
	spacecraft_takeoff.emit()


## Get current altitude above ground
func get_altitude() -> float:
	if ground_raycast.is_colliding():
		var collision_point = ground_raycast.get_collision_point()
		return global_position.distance_to(collision_point)
	return 999999.0  # Very high if no collision


## Get current spacecraft speed
func get_speed() -> float:
	var velocity = Vector3.ZERO
	if spacecraft is RigidBody3D:
		velocity = spacecraft.linear_velocity
	elif spacecraft.has_method("get_velocity"):
		velocity = spacecraft.get_velocity()
	return velocity.length()


## Check if we're currently landed
func is_spacecraft_landed() -> bool:
	return is_landed


## Check if player can exit spacecraft
func can_exit() -> bool:
	return can_exit_spacecraft


## Request walking mode (called by input handler)
func request_walking_mode() -> void:
	if can_exit_spacecraft:
		print("[LandingDetector] Walking mode requested")
		walking_mode_requested.emit()

		# Trigger transition system if available
		if transition_system:
			transition_system.enable_walking_mode()


## Get landing status info
func get_landing_status() -> Dictionary:
	return {
		"is_landed": is_landed,
		"can_exit": can_exit_spacecraft,
		"altitude": get_altitude(),
		"speed": get_speed(),
		"altitude_threshold": landing_altitude_threshold,
		"velocity_threshold": landing_velocity_threshold
	}
