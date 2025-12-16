extends CharacterBody3D
class_name WalkingController
## VR walking controller for planetary surface exploration
## Handles first-person locomotion with planet-specific gravity and terrain collision
##
## Requirements:
## - 52.1: Enable first-person walking controls with VR motion controllers
## - 52.2: Apply appropriate gravity based on celestial body's mass
## - 52.3: Use collision detection to prevent clipping through ground
## - 52.4: Render terrain with appropriate scale and detail for walking speed
## - 52.5: Allow returning to spacecraft and transitioning back to flight mode

signal walking_started
signal walking_stopped
signal returned_to_spacecraft

## Movement parameters
@export var walk_speed: float = 3.0  # m/s
@export var sprint_speed: float = 6.0  # m/s
@export var jump_velocity: float = 4.0  # m/s
@export var mouse_sensitivity: float = 0.002

## Jetpack parameters
@export var jetpack_enabled: bool = true  # Enable jetpack flight
@export var jetpack_thrust: float = 15.0  # Upward thrust force (m/s²)
@export var jetpack_fuel: float = 100.0  # Max jetpack fuel
@export var jetpack_fuel_consumption: float = 10.0  # Fuel per second (10% of max 100)
@export var jetpack_fuel_recharge: float = 5.0  # Recharge per second on ground (5% of max 100)
@export var low_gravity_threshold: float = 5.0  # Gravity below this = flight mode

## VR locomotion settings
@export var smooth_locomotion: bool = true  # If false, use teleport
@export var comfort_vignette: bool = true  # Reduce FOV during movement
@export var snap_turn_angle: float = 45.0  # Degrees for snap turning

## Jetpack state
var current_fuel: float = 100.0
var is_jetpack_active: bool = false
var is_in_flight_mode: bool = false

## References
var vr_manager: VRManager = null
var xr_camera: XRCamera3D = null
var xr_origin: XROrigin3D = null
var current_planet: CelestialBody = null
var spacecraft_position: Vector3 = Vector3.ZERO
var spacecraft_node: Node3D = null
var jetpack_effects: JetpackEffects = null

## State
var is_active: bool = false
var current_gravity: float = 9.8  # Default Earth gravity
var gravity_direction: Vector3 = Vector3.DOWN

## Desktop mode camera rotation
var camera_pitch: float = 0.0
var camera_yaw: float = 0.0

## Collision detection
var ground_raycast: RayCast3D = null
var is_on_ground: bool = false


func _ready() -> void:
	# Set up collision shape if not already present
	if not has_collision_shape():
		create_default_collision_shape()
	
	# Set up ground detection raycast
	setup_ground_raycast()
	
	# Set up jetpack effects
	setup_jetpack_effects()
	
	# Start inactive
	set_process(false)
	set_physics_process(false)


func has_collision_shape() -> bool:
	for child in get_children():
		if child is CollisionShape3D:
			return true
	return false


func create_default_collision_shape() -> void:
	var collision_shape = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.4  # 0.4m radius (human-sized)
	capsule.height = 1.8  # 1.8m height
	collision_shape.shape = capsule
	collision_shape.name = "CollisionShape3D"
	add_child(collision_shape)
	print("[WalkingController] Created default collision shape")


func setup_ground_raycast() -> void:
	ground_raycast = RayCast3D.new()
	ground_raycast.name = "GroundRaycast"
	ground_raycast.target_position = Vector3(0, -2.0, 0)  # Cast 2m down
	ground_raycast.enabled = true
	ground_raycast.collide_with_areas = false
	ground_raycast.collide_with_bodies = true
	add_child(ground_raycast)
	print("[WalkingController] Ground raycast created")


## Initialize the walking controller
func initialize(vr_mgr: VRManager, planet: CelestialBody, spawn_position: Vector3, craft: Node3D) -> void:
	vr_manager = vr_mgr
	current_planet = planet
	spacecraft_node = craft
	spacecraft_position = craft.global_position if craft else spawn_position
	
	# Get XR nodes
	if vr_manager:
		xr_origin = vr_manager.get_xr_origin()
		xr_camera = vr_manager.get_xr_camera()
	
	# Set initial position
	global_position = spawn_position
	
	# Calculate gravity for this planet
	if planet:
		calculate_planet_gravity(planet)
	
	print("[WalkingController] Initialized on planet: ", planet.body_name if planet else "Unknown")
	print("[WalkingController] Gravity: ", current_gravity, " m/s²")


## Calculate gravity based on planet mass and radius
## Requirements: 52.2
func calculate_planet_gravity(planet: CelestialBody) -> void:
	if not planet:
		current_gravity = 9.8  # Default
		return

	# G * M / R²
	const G = 6.67430e-11  # Real gravitational constant (SI units)
	const GAME_UNIT_TO_METERS = 1_000_000.0  # 1 game unit = 1 million meters
	var mass = planet.mass
	var radius = planet.radius

	if radius > 0:
		# Convert game unit radius to meters for correct gravity calculation
		var radius_meters = radius * GAME_UNIT_TO_METERS
		current_gravity = (G * mass) / (radius_meters * radius_meters)
		# Clamp to reasonable values for gameplay
		current_gravity = clamp(current_gravity, 0.1, 50.0)
	else:
		current_gravity = 9.8

	# Set gravity direction (toward planet center)
	var to_planet = planet.global_position - global_position
	if to_planet.length() > 0:
		gravity_direction = to_planet.normalized()
	else:
		gravity_direction = Vector3.DOWN


## Align player orientation to planet surface
## Makes "up" point away from planet center
func align_to_planet_surface(delta: float) -> void:
	# Target "up" direction (away from planet center)
	var target_up = -gravity_direction

	# Current up direction
	var current_up = -transform.basis.y

	# Smooth interpolation for rotation
	var rotation_speed = 5.0  # Radians per second
	var interpolation = min(rotation_speed * delta, 1.0)

	# Blend current up with target up
	var new_up = current_up.lerp(target_up, interpolation).normalized()

	# Build new basis aligned to surface
	# Use player's forward direction projected onto surface plane
	var current_forward = -transform.basis.z
	var new_right = current_forward.cross(new_up).normalized()
	if new_right.length_squared() < 0.01:
		# If forward is parallel to up, use right as reference
		new_right = transform.basis.x
	var new_forward = new_up.cross(new_right).normalized()

	# Construct new basis
	var new_basis = Basis(new_right, -new_up, -new_forward)
	transform.basis = new_basis


## Activate walking mode
func activate() -> void:
	if is_active:
		return
	
	is_active = true
	set_process(true)
	set_physics_process(true)
	
	# Attach XR origin to this character body if in VR mode
	if vr_manager and vr_manager.is_vr_active() and xr_origin:
		# Reparent XR origin to follow the character body
		if xr_origin.get_parent():
			xr_origin.get_parent().remove_child(xr_origin)
		add_child(xr_origin)
		xr_origin.position = Vector3(0, 0.9, 0)  # Eye height
	
	walking_started.emit()
	print("[WalkingController] Walking mode activated")


## Deactivate walking mode
func deactivate() -> void:
	if not is_active:
		return
	
	is_active = false
	set_process(false)
	set_physics_process(false)
	
	# Detach XR origin
	if xr_origin and xr_origin.get_parent() == self:
		remove_child(xr_origin)
		# Return to spacecraft or scene root
		if spacecraft_node:
			spacecraft_node.add_child(xr_origin)
			xr_origin.position = Vector3.ZERO
	
	walking_stopped.emit()
	print("[WalkingController] Walking mode deactivated")


func _process(delta: float) -> void:
	if not is_active:
		return
	
	# Check for return to spacecraft
	check_spacecraft_proximity()
	
	# Handle snap turning in VR
	if vr_manager and vr_manager.is_vr_active():
		handle_snap_turning()


func _physics_process(delta: float) -> void:
	if not is_active:
		return

	# Update gravity direction every frame (pulls toward planet center)
	if current_planet:
		var to_planet = current_planet.global_position - global_position
		if to_planet.length() > 0:
			gravity_direction = to_planet.normalized()
			# DISABLED: Surface alignment causing orientation issues
			# align_to_planet_surface(delta)

	# Determine if we're in low-gravity flight mode
	is_in_flight_mode = current_gravity < low_gravity_threshold

	# Apply gravity (reduced in flight mode)
	## Requirements: 52.2
	if not is_on_floor():
		var gravity_multiplier = 0.3 if is_in_flight_mode else 1.0  # Reduced gravity for flight
		velocity += gravity_direction * current_gravity * gravity_multiplier * delta

	# Handle jetpack thrust
	if jetpack_enabled and is_jetpack_thrust_pressed() and current_fuel > 0:
		is_jetpack_active = true
		# Apply upward thrust (opposite of gravity direction)
		velocity += -gravity_direction * jetpack_thrust * delta
		# Consume fuel - BUGFIX: Direct subtraction instead of max()
		current_fuel -= jetpack_fuel_consumption * delta
		if current_fuel < 0.0:
			current_fuel = 0.0
	else:
		is_jetpack_active = false
		# Recharge fuel when on ground
		if is_on_floor():
			# Recharge fuel - BUGFIX: Direct addition instead of min()
			current_fuel += jetpack_fuel_recharge * delta
			if current_fuel > jetpack_fuel:
				current_fuel = jetpack_fuel

	# Get movement input
	var input_dir = get_movement_input()

	# Calculate movement direction
	var direction = calculate_movement_direction(input_dir)

	# Apply movement
	if direction != Vector3.ZERO:
		var speed = sprint_speed if is_sprinting() else walk_speed
		# Faster movement in flight mode
		if is_in_flight_mode and not is_on_floor():
			speed *= 2.0
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		# Apply friction when not moving
		var friction = walk_speed * delta * 5.0
		# Less friction in flight mode
		if is_in_flight_mode and not is_on_floor():
			friction *= 0.3
		velocity.x = move_toward(velocity.x, 0, friction)
		velocity.z = move_toward(velocity.z, 0, friction)

	# Handle jumping (traditional jump on ground)
	if is_jump_pressed() and is_on_floor():
		velocity.y = jump_velocity

	# Move the character
	## Requirements: 52.3
	move_and_slide()

	# Update jetpack effects
	update_jetpack_effects()
	
	# Update ground detection
	update_ground_detection()


## Get movement input from VR controllers or keyboard
## Requirements: 52.1
func get_movement_input() -> Vector2:
	var input = Vector2.ZERO

	if vr_manager:
		if vr_manager.is_vr_active():
			# VR mode - use left controller thumbstick
			var left_state = vr_manager.get_controller_state("left")
			if left_state.has("thumbstick"):
				input = left_state["thumbstick"]
		else:
			# Desktop mode - use WASD
			if Input.is_key_pressed(KEY_W):
				input.y -= 1
			if Input.is_key_pressed(KEY_S):
				input.y += 1
			if Input.is_key_pressed(KEY_A):
				input.x -= 1
			if Input.is_key_pressed(KEY_D):
				input.x += 1
	
	# Fallback to desktop input if vr_manager is null (testing mode)
	if Input.is_key_pressed(KEY_W):
		input.y -= 1
	if Input.is_key_pressed(KEY_S):
		input.y += 1
	if Input.is_key_pressed(KEY_A):
		input.x -= 1
	if Input.is_key_pressed(KEY_D):
		input.x += 1
	return input


## Calculate movement direction based on camera orientation
func calculate_movement_direction(input: Vector2) -> Vector3:
	if input == Vector2.ZERO:
		return Vector3.ZERO

	var camera_transform: Transform3D

	if vr_manager:
		camera_transform = vr_manager.get_hmd_pose()
	else:
		camera_transform = global_transform

	# Get forward and right vectors from camera (ignoring vertical component)
	var forward = -camera_transform.basis.z
	forward.y = 0
	# BUGFIX: Check if forward vector is too small before normalizing
	# If looking straight up/down, the horizontal component would be near-zero
	if forward.length_squared() < 0.001:
		# Use a default forward direction if camera is pointing up/down
		forward = Vector3.FORWARD
	else:
		forward = forward.normalized()

	var right = camera_transform.basis.x
	right.y = 0
	# BUGFIX: Check if right vector is too small before normalizing
	if right.length_squared() < 0.001:
		# Use a default right direction
		right = Vector3.RIGHT
	else:
		right = right.normalized()

	# Combine input with camera orientation
	var direction = (forward * -input.y + right * input.x)
	# BUGFIX: Normalize only if the direction vector is non-zero
	if direction.length_squared() > 0.001:
		direction = direction.normalized()
	else:
		# Fallback to simple WASD directions if calculation fails
		direction = Vector3(input.x, 0, input.y).normalized()

	return direction

## Check if sprint is pressed
func is_sprinting() -> bool:
	if vr_manager:
		if vr_manager.is_vr_active():
			# VR mode - use left thumbstick click
			var left_state = vr_manager.get_controller_state("left")
			return left_state.get("thumbstick_click", false)
		else:
			# Desktop mode - use Shift
			return Input.is_key_pressed(KEY_SHIFT)
	# Fallback to desktop input if vr_manager is null (testing mode)
	return Input.is_key_pressed(KEY_SHIFT)


## Check if jump is pressed
func is_jump_pressed() -> bool:
	if vr_manager:
		if vr_manager.is_vr_active():
			# VR mode - use right controller A button
			var right_state = vr_manager.get_controller_state("right")
			return right_state.get("button_ax", false)
		else:
			# Desktop mode - use Space
			return Input.is_key_pressed(KEY_SPACE)
	# Fallback to desktop input if vr_manager is null (testing mode)
	return Input.is_key_pressed(KEY_SPACE)


## Check if jetpack thrust is pressed
func is_jetpack_thrust_pressed() -> bool:
	if vr_manager:
		if vr_manager.is_vr_active():
			# VR mode - use right controller grip button (easy to hold)
			var right_state = vr_manager.get_controller_state("right")
			var grip_value = right_state.get("grip", 0.0)
			return grip_value > 0.5  # Grip is analog, check if squeezed enough
		else:
			# Desktop mode - use Space key (hold to fly)
			return Input.is_key_pressed(KEY_SPACE)
	# Fallback to desktop input if vr_manager is null (testing mode)
	return Input.is_key_pressed(KEY_SPACE)


## Handle snap turning for VR comfort
func handle_snap_turning() -> void:
	if not vr_manager or not vr_manager.is_vr_active():
		return
	
	var right_state = vr_manager.get_controller_state("right")
	if not right_state.has("thumbstick"):
		return
	
	var thumbstick: Vector2 = right_state["thumbstick"]
	
	# Snap turn left
	if thumbstick.x < -0.7:
		rotate_y(deg_to_rad(-snap_turn_angle))
	# Snap turn right
	elif thumbstick.x > 0.7:
		rotate_y(deg_to_rad(snap_turn_angle))


## Update ground detection using raycast
func update_ground_detection() -> void:
	if ground_raycast:
		is_on_ground = ground_raycast.is_colliding()


## Check proximity to spacecraft for return option
## Requirements: 52.5
func check_spacecraft_proximity() -> void:
	if not spacecraft_node:
		return
	
	var distance = global_position.distance_to(spacecraft_position)
	
	# If within 3 meters and player presses interact button
	if distance < 3.0 and is_interact_pressed():
		return_to_spacecraft()


## Check if interact button is pressed
func is_interact_pressed() -> bool:
	if vr_manager:
		if vr_manager.is_vr_active():
			# VR mode - use right controller B button
			var right_state = vr_manager.get_controller_state("right")
			return right_state.get("button_by", false)
		else:
			# Desktop mode - use E key
			return Input.is_key_pressed(KEY_E)
	# Fallback to desktop input if vr_manager is null (testing mode)
	return Input.is_key_pressed(KEY_E)


## Return to spacecraft and transition back to flight mode
## Requirements: 52.5
func return_to_spacecraft() -> void:
	print("[WalkingController] Returning to spacecraft")
	returned_to_spacecraft.emit()
	deactivate()


## Handle mouse input for desktop mode camera
func _input(event: InputEvent) -> void:
	if not is_active:
		return
	
	if vr_manager and vr_manager.is_desktop_mode():
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			camera_yaw -= event.relative.x * mouse_sensitivity
			camera_pitch -= event.relative.y * mouse_sensitivity
			camera_pitch = clamp(camera_pitch, -PI/2, PI/2)
			
			rotation.y = camera_yaw
			# In desktop mode, we'd rotate a camera child node for pitch


## Get current walking speed
func get_current_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


## Check if currently walking
func is_walking() -> bool:
	return is_active and get_current_speed() > 0.1


## Get distance to spacecraft
func get_distance_to_spacecraft() -> float:
	if spacecraft_node:
		return global_position.distance_to(spacecraft_position)
	return INF


## Update spacecraft position (in case it moves)
func update_spacecraft_position(new_position: Vector3) -> void:
	spacecraft_position = new_position


## Get current planet
func get_current_planet() -> CelestialBody:
	return current_planet


## Get current gravity
func get_current_gravity() -> float:
	return current_gravity


## Check if walking mode is active
func is_walking_active() -> bool:
	return is_active


## Get current jetpack fuel level (0-100)
func get_jetpack_fuel() -> float:
	return current_fuel


## Get max jetpack fuel
func get_max_jetpack_fuel() -> float:
	return jetpack_fuel


## Get jetpack fuel percentage (0.0 to 1.0)
func get_jetpack_fuel_percent() -> float:
	return current_fuel / jetpack_fuel


## Check if jetpack is currently active
func is_jetpack_firing() -> bool:
	return is_jetpack_active


## Check if in low-gravity flight mode
func is_in_low_gravity_flight() -> bool:
	return is_in_flight_mode


## Enable/disable jetpack system
func set_jetpack_enabled(enabled: bool) -> void:
	jetpack_enabled = enabled

## Set up jetpack visual and audio effects
func setup_jetpack_effects() -> void:
	# Create jetpack effects node
	jetpack_effects = JetpackEffects.new()
	jetpack_effects.name = "JetpackEffects"
	# Position effects at feet (where thrust emanates from)
	jetpack_effects.position = Vector3(0, -0.9, 0)
	add_child(jetpack_effects)
	jetpack_effects.set_walking_controller(self)
	print("[WalkingController] Jetpack effects initialized")


## Update jetpack effects (call from physics_process)
func update_jetpack_effects() -> void:
	if not jetpack_effects:
		return

	# Calculate thrust amount (0.0 to 1.0)
	var thrust_amount = 1.0 if is_jetpack_active else 0.0

	# Get fuel percentage
	var fuel_percent = get_jetpack_fuel_percent() * 100.0

	# Start effects if jetpack activated
	if is_jetpack_active and not jetpack_effects.is_active:
		jetpack_effects.start_effects()

	# Update effects with current thrust and fuel
	if jetpack_effects.is_active:
		jetpack_effects.update_thrust_effects(thrust_amount, fuel_percent)

	# Stop effects if jetpack deactivated
	if not is_jetpack_active and jetpack_effects.is_active:
		jetpack_effects.stop_effects()

