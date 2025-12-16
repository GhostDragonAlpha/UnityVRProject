## Spacecraft - Player Spacecraft Physics and Controls
## Extends RigidBody3D for physics simulation with thrust, rotation, and upgrade systems.
## Integrates with PhysicsEngine for gravitational forces and VRManager for controls.
##
## Requirements:
## - 2.1-2.5: VR rendering and performance
## - 7.3: Lorentz contraction for rendering
## - 31.1: Apply force to spacecraft RigidBody3D through Godot Physics
## - 31.2: Maintain current velocity vector when no input (Newton's first law)
## - 31.3: Apply angular momentum with realistic damping
## - 31.4: Compute net force as vector sum
## - 31.5: Apply impulse forces through Godot Physics on collision
extends RigidBody3D
class_name Spacecraft

## Emitted when thrust is applied
signal thrust_applied(force: Vector3)
## Emitted when rotation is applied
signal rotation_applied(torque: Vector3)
## Emitted when velocity changes significantly
signal velocity_changed(velocity: Vector3, speed: float)
## Emitted when an upgrade is applied
signal upgrade_applied(upgrade_type: String, new_value: float)
## Emitted when spacecraft collides with something
signal collision_occurred(collision_info: Dictionary)

## Base thrust power in Newtons
@export var base_thrust_power: float = 50000.0
## Maximum thrust power (with upgrades)
@export var max_thrust_power: float = 500000.0
## Current thrust power (affected by upgrades)
var thrust_power: float = 50000.0

## Base rotation power (torque)
@export var base_rotation_power: float = 50.0
## Maximum rotation power (with upgrades)
@export var max_rotation_power: float = 200.0
## Current rotation power (affected by upgrades)
var rotation_power: float = 50.0
## Rotation speed in degrees per second
@export var rotation_speed_deg: float = 45.0

## Angular damping factor for realistic rotation decay
## Requirement 31.3: Apply angular momentum with realistic damping
@export var angular_damping_factor: float = 0.5

## Current throttle value (-1.0 to 1.0, negative for reverse)
var throttle: float = 0.0

## Current rotation input (pitch, yaw, roll)
var rotation_input: Vector3 = Vector3.ZERO

## Current vertical thrust input (-1.0 to 1.0)
var vertical_thrust: float = 0.0
## Upgrade multipliers
var engine_upgrade_multiplier: float = 1.0
var rotation_upgrade_multiplier: float = 1.0
var mass_reduction_multiplier: float = 1.0

## Upgrade levels (for persistence)
var upgrade_levels: Dictionary = {
	"engine": 0,
	"rotation": 0,
	"mass": 0,
	"shields": 0
}

## Speed of light constant (for relativistic calculations)
const SPEED_OF_LIGHT: float = 1000.0

## Minimum velocity threshold for "stopped" state
const VELOCITY_EPSILON: float = 0.001

## Reference to physics engine (optional, for gravity integration)
var physics_engine: PhysicsEngine = null

## Reference to relativity manager (optional, for time dilation)
var relativity_manager = null

## Track last velocity for change detection
var _last_velocity: Vector3 = Vector3.ZERO
var _velocity_change_threshold: float = 0.1

## Multiplayer state sync tracking
var _last_network_sync_time: float = 0.0
var _network_sync_interval: float = 0.05  # 20Hz sync rate for unreliable updates


func _ready() -> void:
	# Configure RigidBody3D properties
	_configure_rigid_body()
	
	# Initialize thrust power
	thrust_power = base_thrust_power
	rotation_power = base_rotation_power
	
	# Connect to body_entered signal for collision handling
	body_entered.connect(_on_body_entered)
	
	# Try to find physics engine and relativity manager
	_find_engine_references()


func _configure_rigid_body() -> void:
	"""Configure RigidBody3D properties for spacecraft physics."""
	# Set physics properties
	gravity_scale = 0.0  # We handle gravity through PhysicsEngine
	
	# Set angular damp for realistic rotation decay
	# Requirement 31.3: Apply angular momentum with realistic damping
	angular_damp = angular_damping_factor
	
	# Enable continuous collision detection for fast-moving spacecraft
	continuous_cd = true
	
	# Set contact monitoring for collision detection
	contact_monitor = true
	max_contacts_reported = 4


func _find_engine_references() -> void:
	"""Find references to engine systems."""
	# Try to find PhysicsEngine
	var engine_node = get_node_or_null("/root/ResonanceEngine")
	if engine_node and engine_node.has_method("get_physics_engine"):
		physics_engine = engine_node.get_physics_engine()
	
	# Try to find RelativityManager
	if engine_node and engine_node.has_method("get_relativity_manager"):
		relativity_manager = engine_node.get_relativity_manager()


func _physics_process(delta: float) -> void:
	"""Physics process - handle keyboard input and apply forces."""
	# Handle keyboard input for thrust and rotation
	_process_keyboard_input()

	# Requirement 31.1: Apply force to spacecraft RigidBody3D through Godot Physics
	if abs(throttle) > VELOCITY_EPSILON or abs(vertical_thrust) > VELOCITY_EPSILON:
		_apply_thrust(delta)
	
	# Apply rotation if input is active
	# Requirement 31.3: Apply angular momentum with realistic damping
	if rotation_input.length_squared() > VELOCITY_EPSILON:
		_apply_rotation(delta)
	
	# Requirement 31.2: Maintain current velocity vector when no input (Newton's first law)
	# This is handled automatically by RigidBody3D - no forces means constant velocity
	
	# Check for significant velocity changes
	_check_velocity_change()
	
	# Multiplayer: Sync state at regular intervals if we are authority
	if is_multiplayer_authority() and multiplayer.has_multiplayer_peer():
		_last_network_sync_time += delta
		if _last_network_sync_time >= _network_sync_interval:
			_last_network_sync_time = 0.0
			# Sync transform and velocities (unreliable for frequent updates)
			_network_sync_transform.rpc(global_position, global_rotation, linear_velocity, angular_velocity)
			# Sync input state (unreliable for frequent updates)
			_network_sync_input.rpc(throttle, rotation_input, vertical_thrust)


## Process keyboard input for spacecraft controls
func _process_keyboard_input() -> void:
	"""Handle keyboard input for thrust and rotation controls."""
	# Forward/Backward thrust (W/S keys)
	var forward_input: float = 0.0
	if Input.is_key_pressed(KEY_W):
		forward_input += 1.0
	if Input.is_key_pressed(KEY_S):
		forward_input -= 1.0
	throttle = forward_input
	
	# Vertical thrust (Space/Ctrl)
	var vertical_input: float = 0.0
	if Input.is_key_pressed(KEY_SPACE):
		vertical_input += 1.0
	if Input.is_key_pressed(KEY_CTRL):
		vertical_input -= 1.0
	vertical_thrust = vertical_input
	
	# Rotation controls
	var yaw_input: float = 0.0  # A/D for yaw (left/right turn)
	var roll_input: float = 0.0  # Q/E for roll (barrel roll)
	
	# Yaw (A/D keys)
	if Input.is_key_pressed(KEY_A):
		yaw_input += 1.0
	if Input.is_key_pressed(KEY_D):
		yaw_input -= 1.0
	
	# Roll (Q/E keys)
	if Input.is_key_pressed(KEY_Q):
		roll_input -= 1.0
	if Input.is_key_pressed(KEY_E):
		roll_input += 1.0
	
	# Set rotation input (pitch, yaw, roll)
	# Pitch is 0 for keyboard (could add arrow keys later)
	rotation_input = Vector3(0.0, yaw_input, roll_input)

## Apply thrust force in the forward direction
## Requirement 31.1: Apply force to spacecraft RigidBody3D through Godot Physics
## Requirement 31.4: Compute net force as vector sum
func _apply_thrust(delta: float) -> void:
	"""Apply thrust force based on throttle, vertical thrust, and orientation."""
	var total_force: Vector3 = Vector3.ZERO
	var force_magnitude = thrust_power * engine_upgrade_multiplier
	
	# Forward/backward thrust
	if abs(throttle) > VELOCITY_EPSILON:
		var forward = get_forward_vector()
		total_force += forward * force_magnitude * throttle
	
	# Vertical thrust (relative to spacecraft's up direction)
	if abs(vertical_thrust) > VELOCITY_EPSILON:
		var up = get_up_vector()
		total_force += up * force_magnitude * vertical_thrust
	
	# Apply the combined force through Godot Physics
	apply_central_force(total_force)
	
	if total_force.length_squared() > VELOCITY_EPSILON:
		thrust_applied.emit(total_force)


## Apply rotation torque based on input
## Requirement 31.3: Apply angular momentum with realistic damping
func _apply_rotation(delta: float) -> void:
	"""Apply rotation torque based on pitch, yaw, roll input."""
	# Convert rotation speed from degrees/sec to radians/sec for torque calculation
	var rotation_speed_rad = deg_to_rad(rotation_speed_deg)
	var torque_magnitude = rotation_power * rotation_upgrade_multiplier * rotation_speed_rad
	
	# Convert rotation input to local torque
	# rotation_input.x = pitch (rotate around local X axis)
	# rotation_input.y = yaw (rotate around local Y axis)
	# rotation_input.z = roll (rotate around local Z axis)
	var local_torque = rotation_input * torque_magnitude
	
	# Transform to global torque based on current orientation
	var global_torque = global_transform.basis * local_torque
	
	# Apply torque through Godot Physics
	apply_torque(global_torque)
	
	rotation_applied.emit(global_torque)


## Check for significant velocity changes and emit signal
func _check_velocity_change() -> void:
	"""Check if velocity has changed significantly and emit signal."""
	var current_velocity = linear_velocity
	var velocity_diff = (current_velocity - _last_velocity).length()
	
	if velocity_diff > _velocity_change_threshold:
		_last_velocity = current_velocity
		velocity_changed.emit(current_velocity, current_velocity.length())


## Handle collision with another body
## Requirement 31.5: Apply impulse forces through Godot Physics on collision
func _on_body_entered(body: Node) -> void:
	"""Handle collision with another physics body."""
	var collision_info = {
		"body": body,
		"body_name": body.name,
		"velocity": linear_velocity,
		"position": global_position
	}
	
	# Impulse is handled automatically by Godot Physics
	# Requirement 31.5 is satisfied by RigidBody3D's built-in collision response
	
	collision_occurred.emit(collision_info)
	
	# Multiplayer: Sync collision event to other peers
	if is_multiplayer_authority() and multiplayer.has_multiplayer_peer():
		_network_sync_collision.rpc(collision_info["body_name"], collision_info["velocity"], collision_info["position"])


## Set throttle value (0.0 to 1.0)
func set_throttle(value: float) -> void:
	"""Set the throttle value for thrust control (-1.0 to 1.0)."""
	throttle = clampf(value, -1.0, 1.0)


## Get current throttle value
func get_throttle() -> float:
	"""Get the current throttle value."""
	return throttle


## Apply thrust with a specific throttle value
func apply_thrust(throttle_value: float) -> void:
	"""Apply thrust with a specific throttle value (0.0 to 1.0)."""
	set_throttle(throttle_value)


## Apply rotation controls (pitch, yaw, roll)
## Each value should be in range -1.0 to 1.0
func apply_rotation(pitch: float, yaw: float, roll: float) -> void:
	"""Apply rotation controls for pitch, yaw, and roll."""
	rotation_input = Vector3(
		clampf(pitch, -1.0, 1.0),
		clampf(yaw, -1.0, 1.0),
		clampf(roll, -1.0, 1.0)
	)


## Set rotation input directly
func set_rotation_input(input: Vector3) -> void:
	"""Set rotation input vector directly."""
	rotation_input = Vector3(
		clampf(input.x, -1.0, 1.0),
		clampf(input.y, -1.0, 1.0),
		clampf(input.z, -1.0, 1.0)
	)


## Get the forward direction vector (local -Z in Godot)
func get_forward_vector() -> Vector3:
	"""Get the spacecraft's forward direction vector."""
	# In Godot, forward is -Z axis
	return -global_transform.basis.z.normalized()


## Get the up direction vector (local Y)
func get_up_vector() -> Vector3:
	"""Get the spacecraft's up direction vector."""
	return global_transform.basis.y.normalized()


## Get the right direction vector (local X)
func get_right_vector() -> Vector3:
	"""Get the spacecraft's right direction vector."""
	return global_transform.basis.x.normalized()


## Get current velocity vector
func get_velocity() -> Vector3:
	"""Get the current velocity vector."""
	return linear_velocity


## Get velocity magnitude (speed)
func get_velocity_magnitude() -> float:
	"""Get the current speed (velocity magnitude)."""
	return linear_velocity.length()


## Get velocity as a fraction of the speed of light
func get_velocity_fraction_of_c() -> float:
	"""Get velocity as a fraction of the speed of light (0.0 to 1.0)."""
	return minf(linear_velocity.length() / SPEED_OF_LIGHT, 1.0)


## Get angular velocity
func get_angular_velocity_vector() -> Vector3:
	"""Get the current angular velocity vector."""
	return angular_velocity


## Upgrade engine power
func upgrade_engine(multiplier: float) -> void:
	"""Upgrade engine thrust power by a multiplier."""
	engine_upgrade_multiplier = clampf(multiplier, 1.0, max_thrust_power / base_thrust_power)
	thrust_power = base_thrust_power * engine_upgrade_multiplier
	
	# Clamp to max
	thrust_power = minf(thrust_power, max_thrust_power)
	
	upgrade_applied.emit("engine", thrust_power)


## Upgrade rotation power
func upgrade_rotation(multiplier: float) -> void:
	"""Upgrade rotation power by a multiplier."""
	rotation_upgrade_multiplier = clampf(multiplier, 1.0, max_rotation_power / base_rotation_power)
	rotation_power = base_rotation_power * rotation_upgrade_multiplier
	
	# Clamp to max
	rotation_power = minf(rotation_power, max_rotation_power)
	
	upgrade_applied.emit("rotation", rotation_power)


## Apply an upgrade by type and level
func apply_upgrade(upgrade_type: String, level: int) -> void:
	"""Apply an upgrade of a specific type and level."""
	upgrade_levels[upgrade_type] = level
	
	# Calculate multiplier based on level (each level adds 25%)
	var multiplier = 1.0 + (level * 0.25)
	
	match upgrade_type:
		"engine":
			upgrade_engine(multiplier)
		"rotation":
			upgrade_rotation(multiplier)
		"mass":
			# Reduce mass for better acceleration
			mass_reduction_multiplier = 1.0 / multiplier
			mass = mass * mass_reduction_multiplier
			upgrade_applied.emit("mass", mass)
		"shields":
			# Shields don't affect physics directly
			upgrade_applied.emit("shields", float(level))
	
	# Multiplayer: Sync upgrade to other peers
	if is_multiplayer_authority() and multiplayer.has_multiplayer_peer():
		_network_sync_upgrade.rpc(upgrade_type, level)


## Get current upgrade level for a type
func get_upgrade_level(upgrade_type: String) -> int:
	"""Get the current upgrade level for a specific type."""
	return upgrade_levels.get(upgrade_type, 0)


## Get all upgrade levels
func get_all_upgrades() -> Dictionary:
	"""Get all upgrade levels."""
	return upgrade_levels.duplicate()


## Set all upgrades from a dictionary (for loading saves)
func set_all_upgrades(upgrades: Dictionary) -> void:
	"""Set all upgrades from a dictionary."""
	for upgrade_type in upgrades:
		apply_upgrade(upgrade_type, upgrades[upgrade_type])


## Apply an impulse force (for collisions, explosions, etc.)
## Requirement 31.5: Apply impulse forces through Godot Physics
func apply_impulse_force(impulse: Vector3, position: Vector3 = Vector3.ZERO) -> void:
	"""Apply an impulse force at a specific position."""
	if position == Vector3.ZERO:
		apply_central_impulse(impulse)
	else:
		apply_impulse(impulse, position - global_position)


## Apply a continuous force (for external effects like gravity)
## Requirement 31.4: Compute net force as vector sum
func apply_external_force(force: Vector3) -> void:
	"""Apply an external force (like gravity from PhysicsEngine)."""
	apply_central_force(force)


## Stop all movement (for debugging or special events)
func stop() -> void:
	"""Stop all linear and angular movement."""
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	# Multiplayer: Sync stop command to other peers
	if is_multiplayer_authority() and multiplayer.has_multiplayer_peer():
		_network_sync_stop.rpc()


## Reset spacecraft to initial state
func reset_state() -> void:
	"""Reset spacecraft to initial state."""
	stop()
	throttle = 0.0
	rotation_input = Vector3.ZERO
	vertical_thrust = 0.0
	
	# Reset upgrades
	engine_upgrade_multiplier = 1.0
	rotation_upgrade_multiplier = 1.0
	mass_reduction_multiplier = 1.0
	thrust_power = base_thrust_power
	rotation_power = base_rotation_power
	
	upgrade_levels = {
		"engine": 0,
		"rotation": 0,
		"mass": 0,
		"shields": 0
	}
	
	# Multiplayer: Sync reset command to other peers
	if is_multiplayer_authority() and multiplayer.has_multiplayer_peer():
		_network_sync_reset.rpc()


## Get spacecraft state for saving
func get_state() -> Dictionary:
	"""Get spacecraft state for saving."""
	return {
		"position": global_position,
		"rotation": global_rotation,
		"velocity": linear_velocity,
		"angular_velocity": angular_velocity,
		"throttle": throttle,
		"upgrades": upgrade_levels.duplicate(),
		"thrust_power": thrust_power,
		"rotation_power": rotation_power
	}


## Set spacecraft state from loaded data
func set_state(state: Dictionary) -> void:
	"""Set spacecraft state from loaded data."""
	if state.has("position"):
		global_position = state.position
	if state.has("rotation"):
		global_rotation = state.rotation
	if state.has("velocity"):
		linear_velocity = state.velocity
	if state.has("angular_velocity"):
		angular_velocity = state.angular_velocity
	if state.has("throttle"):
		throttle = state.throttle
	if state.has("upgrades"):
		set_all_upgrades(state.upgrades)
	
	# Multiplayer: Sync full state to other peers
	if is_multiplayer_authority() and multiplayer.has_multiplayer_peer():
		_network_sync_full_state.rpc(state)


## Register with physics engine for gravity calculations
func register_with_physics_engine(engine: PhysicsEngine) -> void:
	"""Register this spacecraft with the physics engine."""
	physics_engine = engine
	if physics_engine:
		physics_engine.set_spacecraft(self)


## Get statistics for debugging/HUD
func get_statistics() -> Dictionary:
	"""Get spacecraft statistics for debugging or HUD display."""
	return {
		"position": global_position,
		"velocity": linear_velocity,
		"speed": get_velocity_magnitude(),
		"speed_fraction_c": get_velocity_fraction_of_c(),
		"angular_velocity": angular_velocity,
		"throttle": throttle,
		"thrust_power": thrust_power,
		"rotation_power": rotation_power,
		"mass": mass,
		"forward": get_forward_vector(),
		"upgrades": upgrade_levels
	}


# ============================================================================
# MULTIPLAYER RPC FUNCTIONS
# ============================================================================

## Network sync position, rotation, and velocities (unreliable - frequent updates)
@rpc("any_peer", "unreliable")
func _network_sync_transform(pos: Vector3, rot: Vector3, lin_vel: Vector3, ang_vel: Vector3) -> void:
	"""Synchronize transform and physics state across network (unreliable, high frequency)."""
	if not is_multiplayer_authority():
		global_position = pos
		global_rotation = rot
		linear_velocity = lin_vel
		angular_velocity = ang_vel


## Network sync input state (unreliable - frequent updates)
@rpc("any_peer", "unreliable")
func _network_sync_input(throttle_val: float, rot_input: Vector3, vert_thrust: float) -> void:
	"""Synchronize input state across network (unreliable, high frequency)."""
	if not is_multiplayer_authority():
		throttle = throttle_val
		rotation_input = rot_input
		vertical_thrust = vert_thrust


## Network sync upgrade state (reliable - important state changes)
@rpc("any_peer", "reliable")
func _network_sync_upgrade(upgrade_type: String, level: int) -> void:
	"""Synchronize upgrade application across network (reliable)."""
	if not is_multiplayer_authority():
		apply_upgrade(upgrade_type, level)


## Network sync collision event (reliable - important gameplay event)
@rpc("any_peer", "reliable")
func _network_sync_collision(body_name: String, vel: Vector3, pos: Vector3) -> void:
	"""Synchronize collision events across network (reliable)."""
	if not is_multiplayer_authority():
		var collision_info = {
			"body_name": body_name,
			"velocity": vel,
			"position": pos
		}
		collision_occurred.emit(collision_info)


## Network sync stop command (reliable - important state change)
@rpc("any_peer", "reliable")
func _network_sync_stop() -> void:
	"""Synchronize stop command across network (reliable)."""
	if not is_multiplayer_authority():
		stop()


## Network sync reset command (reliable - important state change)
@rpc("any_peer", "reliable")
func _network_sync_reset() -> void:
	"""Synchronize reset command across network (reliable)."""
	if not is_multiplayer_authority():
		reset_state()


## Network sync full state (reliable - complete state transfer)
@rpc("any_peer", "reliable")
func _network_sync_full_state(state: Dictionary) -> void:
	"""Synchronize complete spacecraft state across network (reliable)."""
	if not is_multiplayer_authority():
		set_state(state)
