## FloatingOriginSystem - Coordinate Rebasing System
## Manages coordinate rebasing to prevent floating-point precision errors
## when simulating vast astronomical distances.
##
## Requirements: 5.1, 5.2, 5.3, 5.4, 5.5
## - 5.1: Trigger rebasing when player distance exceeds 5000 units
## - 5.2: Subtract player position from all object positions during rebasing
## - 5.3: Complete rebasing within a single frame
## - 5.4: Update all physics bodies with new positions
## - 5.5: Monitor position magnitude every frame
extends Node
# NOTE: No class_name to avoid conflict with FloatingOriginSystem autoload singleton

## Emitted when a rebasing operation occurs
signal rebasing_started(offset: Vector3)
## Emitted when rebasing completes
signal rebasing_completed(new_global_offset: Vector3)
## Emitted when an object is registered
signal object_registered(obj: Node3D)
## Emitted when an object is unregistered
signal object_unregistered(obj: Node3D)

## Distance threshold from world origin that triggers rebasing (in game units)
## Requirement 5.1: Trigger when distance exceeds 5000 units
@export var rebase_threshold: float = 5000.0

## Minimum distance to trigger rebasing (prevents unnecessary rebasing for small movements)
@export var min_rebase_distance: float = 100.0

## Convenience properties for accessing exported threshold values
var REBASE_THRESHOLD: float:
	get: return rebase_threshold
var MIN_REBASE_DISTANCE: float:
	get: return min_rebase_distance

## The root node that contains all objects to be rebased
var render_root: Node3D = null

## Cumulative global offset tracking for save data and coordinate conversion
## This tracks the total offset applied since simulation start
var global_offset: Vector3 = Vector3.ZERO

## Reference to the player node whose position is monitored
var player_node: Node3D = null

## Array of all registered Node3D objects that need coordinate rebasing
var registered_objects: Array[Node3D] = []

## Array of registered RigidBody3D objects for physics updates
var registered_physics_bodies: Array[RigidBody3D] = []

## Statistics for debugging and monitoring
var _rebase_count: int = 0
var _last_rebase_time: float = 0.0
var _last_player_distance: float = 0.0

## Flag to track if system is initialized
var _is_initialized: bool = false


func _ready() -> void:
	_is_initialized = true


## Initialize the floating origin system with a player node and optional render root
func initialize(player: Node3D, root: Node3D = null) -> bool:
	if player == null:
		push_error("FloatingOriginSystem: Cannot initialize with null player node")
		return false
	
	player_node = player
	render_root = root if root != null else get_tree().root
	
	# Auto-register the player
	register_object(player)
	
	_is_initialized = true
	return true


## Called every physics frame to check if rebasing is needed
## Requirement 5.5: Monitor position magnitude every frame
func _physics_process(delta: float) -> void:
	if player_node == null or not _is_initialized:
		return
	
	# Monitor player distance from origin
	_last_player_distance = player_node.global_position.length()
	
	# Check if rebasing is needed
	if should_rebase():
		var offset = player_node.global_position
		rebase_coordinates(offset)


## Update method called by the engine coordinator
## This is an alternative to _physics_process for manual control
func update(delta: float) -> void:
	# The actual update logic is in _physics_process
	# This method exists for compatibility with the engine coordinator
	pass


## Check if rebasing should occur based on player distance from origin
## Requirement 5.1: Trigger when distance exceeds 5000 units
func should_rebase() -> bool:
	if player_node == null:
		return false
	
	var distance = player_node.global_position.length()
	return distance > REBASE_THRESHOLD


## Get the current distance of the player from the world origin
func get_player_distance_from_origin() -> float:
	if player_node == null:
		return 0.0
	return player_node.global_position.length()


## Perform coordinate rebasing operation
## Requirement 5.2: Subtract player position from all object positions
## Requirement 5.3: Complete within a single frame
## Requirement 5.4: Update all physics bodies
func rebase_coordinates(offset: Vector3) -> void:
	if offset.length() < MIN_REBASE_DISTANCE:
		return  # Don't rebase for tiny offsets
	
	rebasing_started.emit(offset)
	
	# Update global offset tracking for save data
	global_offset += offset
	
	# Rebase all registered Node3D objects
	# Requirement 5.2: Subtract offset from all positions
	for obj in registered_objects:
		if is_instance_valid(obj):
			_rebase_node3d(obj, offset)
	
	# Update physics bodies with new positions
	# Requirement 5.4: Update all physics bodies
	for body in registered_physics_bodies:
		if is_instance_valid(body):
			_rebase_physics_body(body, offset)
	
	# Update statistics
	_rebase_count += 1
	_last_rebase_time = Time.get_ticks_msec() / 1000.0
	
	rebasing_completed.emit(global_offset)


## Rebase a single Node3D object
func _rebase_node3d(obj: Node3D, offset: Vector3) -> void:
	# Skip if object is a child of another registered object
	# (it will be moved automatically with its parent)
	if _is_child_of_registered(obj):
		return
	
	obj.global_position -= offset


## Rebase a RigidBody3D and ensure physics state is updated
func _rebase_physics_body(body: RigidBody3D, offset: Vector3) -> void:
	# For RigidBody3D, we need to handle the physics state carefully
	# The position change should not affect velocity
	
	# Store current velocity
	var linear_vel = body.linear_velocity
	var angular_vel = body.angular_velocity
	
	# Update position
	body.global_position -= offset
	
	# Restore velocity (should be unchanged by rebasing)
	body.linear_velocity = linear_vel
	body.angular_velocity = angular_vel
	
	# Force physics server to acknowledge the new position
	# This ensures collision detection works correctly after rebasing
	PhysicsServer3D.body_set_state(
		body.get_rid(),
		PhysicsServer3D.BODY_STATE_TRANSFORM,
		body.global_transform
	)


## Check if an object is a child of another registered object
func _is_child_of_registered(obj: Node3D) -> bool:
	var parent = obj.get_parent()
	while parent != null:
		if parent is Node3D and parent in registered_objects:
			return true
		parent = parent.get_parent()
	return false


## Register a Node3D object for coordinate rebasing
func register_object(obj: Node3D) -> void:
	if obj == null:
		push_warning("FloatingOriginSystem: Cannot register null object")
		return
	
	if obj in registered_objects:
		return  # Already registered
	
	registered_objects.append(obj)
	
	# Also register as physics body if applicable
	if obj is RigidBody3D:
		register_physics_body(obj as RigidBody3D)
	
	object_registered.emit(obj)


## Unregister a Node3D object from coordinate rebasing
func unregister_object(obj: Node3D) -> void:
	if obj == null:
		return
	
	var idx = registered_objects.find(obj)
	if idx >= 0:
		registered_objects.remove_at(idx)
		object_unregistered.emit(obj)
	
	# Also unregister from physics bodies if applicable
	if obj is RigidBody3D:
		unregister_physics_body(obj as RigidBody3D)


## Register a RigidBody3D for physics-aware rebasing
func register_physics_body(body: RigidBody3D) -> void:
	if body == null:
		return
	
	if body in registered_physics_bodies:
		return  # Already registered
	
	registered_physics_bodies.append(body)


## Unregister a RigidBody3D from physics-aware rebasing
func unregister_physics_body(body: RigidBody3D) -> void:
	if body == null:
		return
	
	var idx = registered_physics_bodies.find(body)
	if idx >= 0:
		registered_physics_bodies.remove_at(idx)


## Convert a local position (relative to current origin) to global position
## This accounts for all rebasing operations that have occurred
func get_global_position(local_pos: Vector3) -> Vector3:
	return local_pos + global_offset


## Convert a global position to local position (relative to current origin)
func get_local_position(global_pos: Vector3) -> Vector3:
	return global_pos - global_offset


## Get the current global offset (for save data)
func get_global_offset() -> Vector3:
	return global_offset


## Set the global offset (for loading save data)
func set_global_offset(offset: Vector3) -> void:
	global_offset = offset


## Set the player node to monitor
func set_player_node(player: Node3D) -> void:
	if player_node != null and player_node in registered_objects:
		unregister_object(player_node)
	
	player_node = player
	
	if player != null:
		register_object(player)


## Get the player node
func get_player_node() -> Node3D:
	return player_node


## Clear all registered objects (useful for scene changes)
func clear_registered_objects() -> void:
	registered_objects.clear()
	registered_physics_bodies.clear()
	
	# Re-register player if set
	if player_node != null:
		register_object(player_node)


## Get statistics about the floating origin system
func get_statistics() -> Dictionary:
	return {
		"rebase_count": _rebase_count,
		"last_rebase_time": _last_rebase_time,
		"last_player_distance": _last_player_distance,
		"global_offset": global_offset,
		"registered_objects_count": registered_objects.size(),
		"registered_physics_bodies_count": registered_physics_bodies.size(),
		"rebase_threshold": REBASE_THRESHOLD
	}


## Reset the system state (useful for new game)
func reset() -> void:
	global_offset = Vector3.ZERO
	_rebase_count = 0
	_last_rebase_time = 0.0
	_last_player_distance = 0.0
	clear_registered_objects()


## Shutdown the system and clean up
func shutdown() -> void:
	clear_registered_objects()
	player_node = null
	render_root = null
	_is_initialized = false
