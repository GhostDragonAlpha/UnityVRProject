## CaptureEventSystem - Gravity Well Capture Event Handler
## Detects when spacecraft velocity falls below escape velocity in a gravity well,
## locks controls, animates spiral trajectory, and triggers fractal zoom transition.
##
## Requirements: 29.1, 29.2, 29.3, 29.4, 29.5
## - 29.1: Detect velocity below escape velocity within gravity well
## - 29.2: Lock player controls temporarily during capture
## - 29.3: Animate spiral trajectory toward gravity source
## - 29.4: Trigger fractal zoom transition loading interior system
## - 29.5: Scale star node up to become skybox of new level
extends Node
class_name CaptureEventSystem

## Emitted when a capture event is detected
signal capture_detected(body: RigidBody3D, source: Node3D)
## Emitted when spiral animation starts
signal spiral_started(body: RigidBody3D, source: Node3D)
## Emitted when spiral animation completes
signal spiral_completed(body: RigidBody3D, source: Node3D)
## Emitted when fractal zoom transition starts
signal zoom_transition_started(source: Node3D)
## Emitted when level transition completes
signal level_transition_completed(new_level: String)
## Emitted when capture is cancelled
signal capture_cancelled()

## Duration of spiral animation in seconds
const SPIRAL_DURATION: float = 3.0

## Number of spiral rotations during capture
const SPIRAL_ROTATIONS: float = 2.5

## Minimum distance from gravity source before triggering zoom
const ZOOM_TRIGGER_DISTANCE: float = 50.0

## Reference to physics engine for capture detection
var physics_engine: PhysicsEngine = null

## Reference to fractal zoom system for transitions
var fractal_zoom: FractalZoomSystem = null

## Reference to pilot controller for locking controls
var pilot_controller: Node = null

## Reference to spacecraft
var spacecraft: RigidBody3D = null

## Is a capture event currently in progress?
var _is_capturing: bool = false

## Current capture target (celestial body)
var _capture_target: Node3D = null

## Animation player for spiral trajectory
var _animation_player: AnimationPlayer = null

## Tween for spiral animation
var _spiral_tween: Tween = null

## Original spacecraft velocity before capture
var _original_velocity: Vector3 = Vector3.ZERO

## Original spacecraft angular velocity before capture
var _original_angular_velocity: Vector3 = Vector3.ZERO

## Spiral animation progress (0.0 to 1.0)
var _spiral_progress: float = 0.0

## Spiral start position
var _spiral_start_pos: Vector3 = Vector3.ZERO

## Spiral target position (gravity source)
var _spiral_target_pos: Vector3 = Vector3.ZERO

## Spiral radius at start
var _spiral_start_radius: float = 0.0


func _ready() -> void:
	# Create animation player for spiral trajectory
	_animation_player = AnimationPlayer.new()
	_animation_player.name = "CaptureAnimationPlayer"
	add_child(_animation_player)
	
	# Find engine references
	_find_engine_references()


func _find_engine_references() -> void:
	"""Find references to engine systems."""
	var engine_node = get_node_or_null("/root/ResonanceEngine")
	if engine_node:
		if engine_node.has_method("get_physics_engine"):
			physics_engine = engine_node.physics_engine
		if engine_node.has_method("get_fractal_zoom"):
			fractal_zoom = engine_node.fractal_zoom


## Initialize the capture event system
func initialize(craft: RigidBody3D, pilot: Node = null) -> bool:
	if craft == null:
		push_error("CaptureEventSystem: Cannot initialize with null spacecraft")
		return false
	
	spacecraft = craft
	pilot_controller = pilot
	
	# Connect to physics engine capture events
	if physics_engine != null:
		if not physics_engine.capture_event_triggered.is_connected(_on_capture_event_triggered):
			physics_engine.capture_event_triggered.connect(_on_capture_event_triggered)
		print("CaptureEventSystem: Connected to PhysicsEngine capture events")
	else:
		push_warning("CaptureEventSystem: PhysicsEngine not found - capture detection may not work")
	
	print("CaptureEventSystem initialized")
	return true


## Called when physics engine detects a capture event
## Requirement 29.1: Detect velocity below escape velocity
func _on_capture_event_triggered(body: RigidBody3D, source: Node3D) -> void:
	"""Handle capture event from physics engine."""
	# Only handle captures for our spacecraft
	if body != spacecraft:
		return
	
	# Ignore if already capturing
	if _is_capturing:
		return
	
	print("CaptureEventSystem: Capture event detected for spacecraft")
	capture_detected.emit(body, source)
	
	# Start capture sequence
	_start_capture_sequence(body, source)


## Start the capture sequence
func _start_capture_sequence(body: RigidBody3D, source: Node3D) -> void:
	"""Begin the capture sequence: lock controls, animate spiral, trigger zoom."""
	_is_capturing = true
	_capture_target = source
	
	# Store original velocities
	_original_velocity = body.linear_velocity
	_original_angular_velocity = body.angular_velocity
	
	# Requirement 29.2: Lock player controls temporarily
	_lock_player_controls()
	
	# Requirement 29.3: Animate spiral trajectory toward gravity source
	_start_spiral_animation(body, source)


## Lock player controls during capture
## Requirement 29.2: Lock player controls temporarily
func _lock_player_controls() -> void:
	"""Lock player controls during capture event."""
	if pilot_controller != null and pilot_controller.has_method("set_controls_locked"):
		pilot_controller.set_controls_locked(true)
		print("CaptureEventSystem: Player controls locked")
	else:
		# If no pilot controller, directly disable spacecraft input
		if spacecraft != null and spacecraft.has_method("set_throttle"):
			spacecraft.set_throttle(0.0)
		if spacecraft != null and spacecraft.has_method("set_rotation_input"):
			spacecraft.set_rotation_input(Vector3.ZERO)


## Unlock player controls after capture
func _unlock_player_controls() -> void:
	"""Unlock player controls after capture event."""
	if pilot_controller != null and pilot_controller.has_method("set_controls_locked"):
		pilot_controller.set_controls_locked(false)
		print("CaptureEventSystem: Player controls unlocked")


## Start spiral trajectory animation
## Requirement 29.3: Animate spiral trajectory toward gravity source
func _start_spiral_animation(body: RigidBody3D, source: Node3D) -> void:
	"""Animate a spiral trajectory toward the gravity source."""
	spiral_started.emit(body, source)
	
	# Calculate spiral parameters
	_spiral_start_pos = body.global_position
	_spiral_target_pos = source.global_position
	_spiral_start_radius = (_spiral_start_pos - _spiral_target_pos).length()
	_spiral_progress = 0.0
	
	print("CaptureEventSystem: Starting spiral animation from distance %.1f" % _spiral_start_radius)
	
	# Cancel any existing tween
	if _spiral_tween != null and _spiral_tween.is_valid():
		_spiral_tween.kill()
	
	# Create spiral animation using tween
	_spiral_tween = create_tween()
	_spiral_tween.set_trans(Tween.TRANS_CUBIC)
	_spiral_tween.set_ease(Tween.EASE_IN)
	
	# Animate spiral progress from 0 to 1
	_spiral_tween.tween_method(_update_spiral_position, 0.0, 1.0, SPIRAL_DURATION)
	
	# When spiral completes, trigger zoom transition
	_spiral_tween.finished.connect(_on_spiral_complete)


## Update spacecraft position during spiral animation
func _update_spiral_position(progress: float) -> void:
	"""Update spacecraft position along spiral trajectory."""
	if spacecraft == null or _capture_target == null:
		return
	
	_spiral_progress = progress
	
	# Calculate spiral position
	# Radius decreases linearly from start to near-zero
	var current_radius = _spiral_start_radius * (1.0 - progress)
	
	# Angle increases with rotations
	var angle = progress * SPIRAL_ROTATIONS * TAU  # TAU = 2*PI
	
	# Calculate position in spiral
	# Use a plane perpendicular to the direction from target to start
	var to_start = (_spiral_start_pos - _spiral_target_pos).normalized()
	var right = to_start.cross(Vector3.UP).normalized()
	if right.length_squared() < 0.01:  # Handle case where to_start is parallel to UP
		right = to_start.cross(Vector3.RIGHT).normalized()
	var up = to_start.cross(right).normalized()
	
	# Spiral position
	var offset = right * cos(angle) * current_radius + up * sin(angle) * current_radius
	var new_position = _spiral_target_pos + to_start * current_radius + offset
	
	# Update spacecraft position
	spacecraft.global_position = new_position
	
	# Make spacecraft face toward the gravity source
	var look_direction = (_spiral_target_pos - new_position).normalized()
	if look_direction.length_squared() > 0.01:
		spacecraft.look_at(_spiral_target_pos, Vector3.UP)
	
	# Slow down spacecraft velocity during spiral
	spacecraft.linear_velocity = look_direction * _original_velocity.length() * (1.0 - progress * 0.8)
	
	# Check if close enough to trigger zoom
	var distance_to_target = (spacecraft.global_position - _spiral_target_pos).length()
	if distance_to_target < ZOOM_TRIGGER_DISTANCE and progress > 0.8:
		# Close enough - trigger zoom early
		if _spiral_tween != null and _spiral_tween.is_valid():
			_spiral_tween.kill()
		_on_spiral_complete()


## Called when spiral animation completes
func _on_spiral_complete() -> void:
	"""Handle spiral animation completion."""
	print("CaptureEventSystem: Spiral animation complete")
	spiral_completed.emit(spacecraft, _capture_target)
	
	# Requirement 29.4: Trigger fractal zoom transition
	_trigger_fractal_zoom_transition()


## Trigger fractal zoom transition to interior system
## Requirement 29.4: Trigger fractal zoom transition loading interior system
## Requirement 29.5: Scale star node up to become skybox of new level
func _trigger_fractal_zoom_transition() -> void:
	"""Trigger fractal zoom transition to load interior system."""
	if fractal_zoom == null:
		push_error("CaptureEventSystem: FractalZoomSystem not available")
		_complete_capture_sequence()
		return
	
	print("CaptureEventSystem: Triggering fractal zoom transition")
	zoom_transition_started.emit(_capture_target)
	
	# Trigger zoom IN (toward smaller scales / interior of system)
	# This will scale the player down relative to the environment
	var zoom_direction = 0  # FractalZoomSystem.ZoomDirection.IN
	
	if fractal_zoom.has_method("zoom"):
		var success = fractal_zoom.zoom(zoom_direction)
		if success:
			# Connect to zoom completion
			if not fractal_zoom.zoom_completed.is_connected(_on_zoom_transition_complete):
				fractal_zoom.zoom_completed.connect(_on_zoom_transition_complete)
		else:
			push_warning("CaptureEventSystem: Fractal zoom failed to start")
			_complete_capture_sequence()
	else:
		push_error("CaptureEventSystem: FractalZoomSystem does not have zoom method")
		_complete_capture_sequence()


## Called when fractal zoom transition completes
func _on_zoom_transition_complete(new_scale: float) -> void:
	"""Handle fractal zoom transition completion."""
	print("CaptureEventSystem: Zoom transition complete at scale %.3f" % new_scale)
	
	# Requirement 29.5: Load interior system as new level
	# For now, we'll just complete the capture sequence
	# In a full implementation, this would load a new scene with the interior system
	_load_interior_system()


## Load the interior system as a new level
## Requirement 29.5: Scale star node up to become skybox of new level
func _load_interior_system() -> void:
	"""Load the interior system as a new level."""
	# In a full implementation, this would:
	# 1. Generate or load the interior system (planets, moons, etc.)
	# 2. Scale the captured star node to become the skybox
	# 3. Position the player at the edge of the system
	# 4. Update the floating origin to the new reference frame
	
	# For now, just emit completion signal
	print("CaptureEventSystem: Interior system loaded (placeholder)")
	
	var level_name = "interior_system"
	if _capture_target != null:
		level_name = "interior_" + _capture_target.name
	
	level_transition_completed.emit(level_name)
	
	# Complete the capture sequence
	_complete_capture_sequence()


## Complete the capture sequence and restore control
func _complete_capture_sequence() -> void:
	"""Complete the capture sequence and restore player control."""
	print("CaptureEventSystem: Capture sequence complete")
	
	# Unlock player controls
	_unlock_player_controls()
	
	# Reset state
	_is_capturing = false
	_capture_target = null
	_spiral_progress = 0.0


## Cancel an in-progress capture
func cancel_capture() -> void:
	"""Cancel an in-progress capture event."""
	if not _is_capturing:
		return
	
	print("CaptureEventSystem: Capture cancelled")
	
	# Stop spiral animation
	if _spiral_tween != null and _spiral_tween.is_valid():
		_spiral_tween.kill()
	
	# Restore original velocities
	if spacecraft != null:
		spacecraft.linear_velocity = _original_velocity
		spacecraft.angular_velocity = _original_angular_velocity
	
	# Unlock controls
	_unlock_player_controls()
	
	# Reset state
	_is_capturing = false
	_capture_target = null
	_spiral_progress = 0.0
	
	capture_cancelled.emit()


## Check if a capture is currently in progress
func is_capturing() -> bool:
	"""Check if a capture event is currently in progress."""
	return _is_capturing


## Get the current capture target
func get_capture_target() -> Node3D:
	"""Get the current capture target (gravity source)."""
	return _capture_target


## Get the spiral animation progress (0.0 to 1.0)
func get_spiral_progress() -> float:
	"""Get the current spiral animation progress."""
	return _spiral_progress


## Enable or disable capture events
func set_capture_enabled(enabled: bool) -> void:
	"""Enable or disable capture event detection."""
	if physics_engine != null and physics_engine.has_method("set_capture_events_enabled"):
		physics_engine.set_capture_events_enabled(enabled)


## Cleanup
func shutdown() -> void:
	"""Shutdown and clean up the capture event system."""
	# Cancel any in-progress capture
	if _is_capturing:
		cancel_capture()
	
	# Disconnect signals
	if physics_engine != null and physics_engine.capture_event_triggered.is_connected(_on_capture_event_triggered):
		physics_engine.capture_event_triggered.disconnect(_on_capture_event_triggered)
	
	if fractal_zoom != null and fractal_zoom.zoom_completed.is_connected(_on_zoom_transition_complete):
		fractal_zoom.zoom_completed.disconnect(_on_zoom_transition_complete)
	
	# Clean up animation player
	if _animation_player != null:
		_animation_player.queue_free()
		_animation_player = null
	
	# Clean up tween
	if _spiral_tween != null and _spiral_tween.is_valid():
		_spiral_tween.kill()
		_spiral_tween = null
	
	spacecraft = null
	pilot_controller = null
	physics_engine = null
	fractal_zoom = null
	_capture_target = null
	
	print("CaptureEventSystem shutdown")
