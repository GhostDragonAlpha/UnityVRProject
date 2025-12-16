## PhysicsEngine - Godot Physics Integration with N-Body Gravity
## Integrates Godot's PhysicsServer3D with N-body gravitational simulation
## for realistic orbital mechanics and spacecraft physics.
##
## Requirements: 1.4, 7.1, 7.2, 7.3, 7.4, 7.5, 9.1, 9.2, 9.3, 9.4, 9.5
## - 1.4: Use Godot Physics (Godot Physics 3D) for collision detection and rigid body dynamics
## - 9.1: Calculate gravitational force using Newton's law F = G·m₁·m₂/r²
## - 9.2: Apply force vector to spacecraft velocity
## - 9.3: Increase pull strength when velocity is low within gravity well
## - 9.4: Allow high-velocity craft to skim over gravity wells
## - 9.5: Trigger capture event when entering critical radius
extends Node
class_name PhysicsEngine

## Emitted when gravitational forces are calculated
signal gravity_calculated(total_force: Vector3)
## Emitted when a body enters a gravity well's sphere of influence
signal entered_gravity_well(body: RigidBody3D, source: Node3D)
## Emitted when a body exits a gravity well's sphere of influence
signal exited_gravity_well(body: RigidBody3D, source: Node3D)
## Emitted when a capture event is triggered (velocity below escape velocity)
signal capture_event_triggered(body: RigidBody3D, source: Node3D)
## Emitted when a raycast hits something
signal raycast_hit(result: Dictionary)

## Gravitational constant (scaled for game units)
## For "1 unit = 1 million meters (1000 km)" system with masses in kg
## G_real = 6.674e-11 m³/(kg·s²) → G_scaled = 6.674e-23
const G: float = 6.674e-23

## Minimum distance for gravity calculations to prevent division by zero
const MIN_GRAVITY_DISTANCE: float = 1.0

## Epsilon for floating-point comparisons
const EPSILON: float = 0.0001

## Reference to the physics space state for raycasting
var physics_space: PhysicsDirectSpaceState3D = null

## Array of celestial bodies (gravity sources)
## Each entry is a Dictionary with: node, mass, radius, position
var celestial_bodies: Array[Dictionary] = []

## Array of registered RigidBody3D nodes affected by gravity
var registered_bodies: Array[RigidBody3D] = []

## Reference to the player's spacecraft (if any)
var spacecraft: RigidBody3D = null

## Track which bodies are in which gravity wells
var _bodies_in_wells: Dictionary = {}  # body_rid -> Array of source nodes

## Flag to enable/disable N-body gravity calculations
var gravity_enabled: bool = true

## Flag to enable/disable capture events
var capture_events_enabled: bool = true

## Flag to enable/disable spatial partitioning optimization
var use_spatial_partitioning: bool = true

## Maximum interaction radius for gravity calculations (in meters)
## Bodies beyond this distance are ignored for performance
@export var max_interaction_radius: float = 10000.0

## Spatial grid for optimization (simple grid-based partitioning)
## Uses Vector3i keys directly (no string conversion for performance)
var _spatial_grid: Dictionary = {}  # Vector3i -> Array of celestial bodies
@export var _grid_cell_size: float = 1000.0  # Size of each grid cell

## Statistics for debugging
var _last_calculation_time_ms: float = 0.0
var _total_forces_applied: int = 0
var _spatial_culled_calculations: int = 0


func _ready() -> void:
	# Get the physics space state for raycasting
	# This must be done after the node enters the tree
	call_deferred("_initialize_physics_space")


func _initialize_physics_space() -> void:
	"""Initialize the physics space reference."""
	var viewport = get_viewport()
	if viewport:
		var world = viewport.get_world_3d()
		if world:
			physics_space = world.direct_space_state


func _physics_process(delta: float) -> void:
	"""Physics process - calculate and apply gravitational forces."""
	if not gravity_enabled:
		return
	
	update(delta)


## Update method called by the engine coordinator or _physics_process
func update(dt: float) -> void:
	"""Main update loop for physics calculations."""
	var start_time = Time.get_ticks_usec()
	
	# Ensure physics space is available
	if physics_space == null:
		_initialize_physics_space()
	
	# Calculate and apply N-body gravity
	calculate_n_body_gravity(dt)
	
	# Check for capture events
	if capture_events_enabled:
		_check_capture_events()
	
	_last_calculation_time_ms = (Time.get_ticks_usec() - start_time) / 1000.0



## Calculate N-body gravitational forces between all bodies
## Requirement 9.1: Calculate gravitational force using Newton's law F = G·m₁·m₂/r²
## OPTIMIZED: Uses spatial partitioning to reduce O(n²) to O(n log n)
func calculate_n_body_gravity(dt: float) -> void:
	"""Calculate gravitational forces from all celestial bodies on all registered bodies."""
	_total_forces_applied = 0
	_spatial_culled_calculations = 0

	# Update spatial grid if spatial partitioning is enabled
	if use_spatial_partitioning:
		_rebuild_spatial_grid()

	for body in registered_bodies:
		if not is_instance_valid(body):
			continue

		var total_force = Vector3.ZERO
		var body_pos = body.global_position
		var body_mass = body.mass if body.mass > 0 else 1.0

		# Get nearby celestial bodies using spatial partitioning
		var nearby_celestials: Array[Dictionary] = []
		if use_spatial_partitioning:
			nearby_celestials = _get_nearby_celestial_bodies(body_pos)
		else:
			nearby_celestials = celestial_bodies

		# Calculate gravitational force from each nearby celestial body
		for celestial in nearby_celestials:
			# Distance culling: skip if beyond max interaction radius
			var distance_sq = (celestial.position - body_pos).length_squared()
			if use_spatial_partitioning and distance_sq > max_interaction_radius * max_interaction_radius:
				_spatial_culled_calculations += 1
				continue

			var force = calculate_gravitational_force(
				body_pos,
				body_mass,
				celestial.position,
				celestial.mass
			)

			# Requirement 9.3: Increase pull strength when velocity is low
			# Requirement 9.4: Allow high-velocity craft to skim over gravity wells
			force = _apply_velocity_modifier(body, force, celestial)

			total_force += force

		# Apply the total gravitational force to the body
		# Requirement 9.2: Apply force vector to spacecraft velocity
		if total_force.length_squared() > EPSILON:
			apply_force_to_body(body, total_force)
			_total_forces_applied += 1

		gravity_calculated.emit(total_force)


## Calculate gravitational force between two masses
## Requirement 9.1: F = G·m₁·m₂/r²
## Returns the force vector pointing from body1 toward body2
func calculate_gravitational_force(pos1: Vector3, mass1: float, pos2: Vector3, mass2: float) -> Vector3:
	"""Calculate Newtonian gravitational force between two masses."""
	var direction = pos2 - pos1
	var distance = direction.length()
	
	# Prevent division by zero
	if distance < MIN_GRAVITY_DISTANCE:
		distance = MIN_GRAVITY_DISTANCE
	
	# Newton's law of gravitation: F = G * m1 * m2 / r²
	var force_magnitude = G * mass1 * mass2 / (distance * distance)
	
	# Return force vector pointing toward the other mass
	return direction.normalized() * force_magnitude


## Apply gravitational force between two celestial bodies (for N-body simulation)
func apply_gravitational_force(body1_data: Dictionary, body2_data: Dictionary) -> Vector3:
	"""Calculate and return the force on body1 due to body2."""
	return calculate_gravitational_force(
		body1_data.position,
		body1_data.mass,
		body2_data.position,
		body2_data.mass
	)


## SPATIAL PARTITIONING OPTIMIZATION FUNCTIONS ##

## Convert a 3D position to a grid key for spatial partitioning
func _position_to_grid_key(pos: Vector3) -> Vector3i:
	"""Convert world position to grid cell coordinates."""
	return Vector3i(
		int(floor(pos.x / _grid_cell_size)),
		int(floor(pos.y / _grid_cell_size)),
		int(floor(pos.z / _grid_cell_size))
	)


## Rebuild the spatial grid with all celestial bodies
func _rebuild_spatial_grid() -> void:
	"""Rebuild the spatial partitioning grid for celestial bodies."""
	_spatial_grid.clear()

	for celestial in celestial_bodies:
		if not is_instance_valid(celestial.node):
			continue

		var grid_key = _position_to_grid_key(celestial.position)

		if not _spatial_grid.has(grid_key):
			_spatial_grid[grid_key] = []

		_spatial_grid[grid_key].append(celestial)


## Get nearby celestial bodies within interaction radius using spatial grid
func _get_nearby_celestial_bodies(pos: Vector3) -> Array[Dictionary]:
	"""Get celestial bodies in nearby grid cells."""
	var nearby: Array[Dictionary] = []
	var center_key = _position_to_grid_key(pos)

	# Calculate how many grid cells to check based on interaction radius
	var cells_to_check = int(ceil(max_interaction_radius / _grid_cell_size))

	# Check neighboring grid cells (including the current cell)
	for x in range(-cells_to_check, cells_to_check + 1):
		for y in range(-cells_to_check, cells_to_check + 1):
			for z in range(-cells_to_check, cells_to_check + 1):
				var check_key = Vector3i(
					center_key.x + x,
					center_key.y + y,
					center_key.z + z
				)

				if _spatial_grid.has(check_key):
					nearby.append_array(_spatial_grid[check_key])

	return nearby


## Apply velocity-based modifier to gravitational force
## Requirement 9.3: Increase pull when velocity is low
## Requirement 9.4: Allow high-velocity craft to skim over gravity wells
func _apply_velocity_modifier(body: RigidBody3D, force: Vector3, celestial: Dictionary) -> Vector3:
	"""Modify gravitational force based on body velocity relative to escape velocity."""
	if body == null or not is_instance_valid(body):
		return force

	var body_velocity = body.linear_velocity.length()
	var escape_velocity = calculate_escape_velocity(celestial.mass, celestial.radius, body.global_position, celestial.position)
	
	if escape_velocity < EPSILON:
		return force
	
	# Calculate velocity ratio (how fast relative to escape velocity)
	var velocity_ratio = body_velocity / escape_velocity
	
	# Requirement 9.3: When velocity is low (< 0.5 escape velocity), increase pull
	# Requirement 9.4: When velocity is high (> 1.5 escape velocity), reduce interaction
	var modifier = 1.0
	if velocity_ratio < 0.5:
		# Low velocity: increase pull (up to 1.5x)
		modifier = 1.0 + (0.5 - velocity_ratio)
	elif velocity_ratio > 1.5:
		# High velocity: reduce interaction (down to 0.5x)
		modifier = maxf(0.5, 1.0 - (velocity_ratio - 1.5) * 0.25)
	
	return force * modifier


## Calculate escape velocity at a given position from a celestial body
func calculate_escape_velocity(mass: float, radius: float, pos: Vector3, celestial_pos: Vector3) -> float:
	"""Calculate escape velocity: v_escape = sqrt(2 * G * M / r)"""
	var distance = (pos - celestial_pos).length()
	
	# Use radius as minimum distance
	if distance < radius:
		distance = radius
	
	if distance < MIN_GRAVITY_DISTANCE:
		distance = MIN_GRAVITY_DISTANCE
	
	# v_escape = sqrt(2 * G * M / r)
	return sqrt(2.0 * G * mass / distance)


## Apply a force to a RigidBody3D
## Requirement 9.2: Apply force vector to spacecraft velocity
func apply_force_to_body(body: RigidBody3D, force: Vector3) -> void:
	"""Apply a force to a rigid body using Godot Physics."""
	if body == null or not is_instance_valid(body):
		return
	
	# Use apply_central_force for continuous forces (like gravity)
	body.apply_central_force(force)


## Apply an impulse to a RigidBody3D (instantaneous force)
func apply_impulse_to_body(body: RigidBody3D, impulse: Vector3, position: Vector3 = Vector3.ZERO) -> void:
	"""Apply an impulse to a rigid body at a specific position."""
	if body == null or not is_instance_valid(body):
		return
	
	if position == Vector3.ZERO:
		body.apply_central_impulse(impulse)
	else:
		body.apply_impulse(impulse, position)


## Check for capture events (velocity below escape velocity)
## Requirement 9.5: Trigger capture event when entering critical radius
func _check_capture_events() -> void:
	"""Check if any bodies should trigger capture events."""
	for body in registered_bodies:
		if not is_instance_valid(body):
			continue
		
		var body_pos = body.global_position
		var body_velocity = body.linear_velocity.length()
		
		for celestial in celestial_bodies:
			var distance = (body_pos - celestial.position).length()
			var escape_vel = calculate_escape_velocity(celestial.mass, celestial.radius, body_pos, celestial.position)
			
			# Check if within sphere of influence and below escape velocity
			var soi = calculate_sphere_of_influence(celestial)
			if distance < soi and body_velocity < escape_vel:
				# Requirement 9.5: Trigger capture event
				capture_event_triggered.emit(body, celestial.node)
				
				# Track gravity well entry
				_track_gravity_well_entry(body, celestial.node)


## Calculate sphere of influence for a celestial body
func calculate_sphere_of_influence(celestial: Dictionary) -> float:
	"""Calculate the sphere of influence radius."""
	# Simplified SOI calculation: proportional to mass^(2/5) * radius
	# For a more accurate calculation, you'd need the parent body's mass
	return celestial.radius * pow(celestial.mass / 1000.0, 0.4) * 10.0


## Track when a body enters a gravity well
func _track_gravity_well_entry(body: RigidBody3D, source: Node3D) -> void:
	"""Track gravity well entry for a body."""
	if body == null or not is_instance_valid(body):
		return

	var body_rid = body.get_rid()
	
	if not _bodies_in_wells.has(body_rid):
		_bodies_in_wells[body_rid] = []
	
	if source not in _bodies_in_wells[body_rid]:
		_bodies_in_wells[body_rid].append(source)
		entered_gravity_well.emit(body, source)



## Register a RigidBody3D to be affected by gravity
func add_rigid_body(body: RigidBody3D) -> void:
	"""Register a rigid body with the physics engine for gravity calculations."""
	if body == null:
		push_warning("PhysicsEngine: Cannot register null body")
		return
	
	if body in registered_bodies:
		return  # Already registered
	
	registered_bodies.append(body)


## Unregister a RigidBody3D from gravity calculations
func remove_rigid_body(body: RigidBody3D) -> void:
	"""Unregister a rigid body from the physics engine."""
	if body == null or not is_instance_valid(body):
		return

	
	var idx = registered_bodies.find(body)
	if idx >= 0 and idx < registered_bodies.size():
		registered_bodies.remove_at(idx)
	
	# Clean up gravity well tracking
	var body_rid = body.get_rid()
	if _bodies_in_wells.has(body_rid):
		_bodies_in_wells.erase(body_rid)


## Register a celestial body as a gravity source
func add_celestial_body(node: Node3D, mass: float, radius: float) -> void:
	"""Register a celestial body as a gravity source."""
	if node == null:
		push_warning("PhysicsEngine: Cannot register null celestial body")
		return
	
	# Check if already registered
	for celestial in celestial_bodies:
		if celestial.node == node:
			# Update existing entry
			celestial.mass = mass
			celestial.radius = radius
			celestial.position = node.global_position
			return
	
	# Add new entry
	celestial_bodies.append({
		"node": node,
		"mass": mass,
		"radius": radius,
		"position": node.global_position
	})


## Unregister a celestial body from gravity calculations
func remove_celestial_body(node: Node3D) -> void:
	"""Unregister a celestial body from the physics engine."""
	if node == null:
		return
	
	for i in range(celestial_bodies.size() - 1, -1, -1):
		if i >= 0 and i < celestial_bodies.size() and celestial_bodies[i].node == node:
			celestial_bodies.remove_at(i)
			break


## Update celestial body positions (call this each frame if bodies move)
func update_celestial_positions() -> void:
	"""Update the cached positions of all celestial bodies."""
	for celestial in celestial_bodies:
		if is_instance_valid(celestial.node):
			celestial.position = celestial.node.global_position


## Set the player's spacecraft for special handling
func set_spacecraft(craft: RigidBody3D) -> void:
	"""Set the player's spacecraft."""
	spacecraft = craft
	if craft != null and craft not in registered_bodies:
		add_rigid_body(craft)


## Get the player's spacecraft
func get_spacecraft() -> RigidBody3D:
	"""Get the player's spacecraft."""
	return spacecraft


## Perform a raycast using PhysicsDirectSpaceState3D
## Returns a Dictionary with hit information or empty if no hit
func raycast(origin: Vector3, direction: Vector3, distance: float, collision_mask: int = 0xFFFFFFFF, exclude: Array[RID] = []) -> Dictionary:
	"""Perform a raycast and return hit information."""
	if physics_space == null:
		_initialize_physics_space()
		if physics_space == null:
			push_warning("PhysicsEngine: Physics space not available for raycast")
			return {}
	
	var query = PhysicsRayQueryParameters3D.create(
		origin,
		origin + direction.normalized() * distance,
		collision_mask,
		exclude
	)
	
	var result = physics_space.intersect_ray(query)
	
	if not result.is_empty():
		raycast_hit.emit(result)
	
	return result


## Perform a shape cast (sweep test)
func shape_cast(shape: Shape3D, from: Transform3D, motion: Vector3, collision_mask: int = 0xFFFFFFFF, exclude: Array[RID] = []) -> Array[Dictionary]:
	"""Perform a shape cast and return all intersections."""
	if physics_space == null:
		_initialize_physics_space()
		if physics_space == null:
			return []
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = from
	query.motion = motion
	query.collision_mask = collision_mask
	query.exclude = exclude
	
	return physics_space.intersect_shape(query)


## Check if a point is inside any collision shape
func point_in_collision(point: Vector3, collision_mask: int = 0xFFFFFFFF) -> Array[Dictionary]:
	"""Check if a point intersects with any collision shapes."""
	if physics_space == null:
		_initialize_physics_space()
		if physics_space == null:
			return []
	
	var query = PhysicsPointQueryParameters3D.new()
	query.position = point
	query.collision_mask = collision_mask
	
	return physics_space.intersect_point(query)


## Get the total gravitational force at a point
func get_gravity_at_point(point: Vector3) -> Vector3:
	"""Calculate the total gravitational force at a given point (assuming unit mass)."""
	var total_force = Vector3.ZERO
	
	for celestial in celestial_bodies:
		var force = calculate_gravitational_force(
			point,
			1.0,  # Unit mass
			celestial.position,
			celestial.mass
		)
		total_force += force
	
	return total_force


## Get the gravitational acceleration at a point
func get_gravity_acceleration_at_point(point: Vector3) -> Vector3:
	"""Calculate gravitational acceleration at a point (F/m = a)."""
	# Since we use unit mass, force equals acceleration
	return get_gravity_at_point(point)


## Calculate surface gravity for a celestial body
## g = G * M / r²
func calculate_surface_gravity(mass: float, radius: float) -> float:
	"""Calculate surface gravity for a celestial body."""
	if radius < MIN_GRAVITY_DISTANCE:
		radius = MIN_GRAVITY_DISTANCE
	
	return G * mass / (radius * radius)


## Get the dominant gravity source at a position
func get_dominant_gravity_source(point: Vector3) -> Dictionary:
	"""Get the celestial body with the strongest gravitational influence at a point."""
	var strongest_force = 0.0
	var dominant_source: Dictionary = {}
	
	for celestial in celestial_bodies:
		var force = calculate_gravitational_force(
			point,
			1.0,
			celestial.position,
			celestial.mass
		).length()
		
		if force > strongest_force:
			strongest_force = force
			dominant_source = celestial
	
	return dominant_source


## Check if a body is within a gravity well
func is_in_gravity_well(body: RigidBody3D) -> bool:
	"""Check if a body is within any gravity well's sphere of influence."""
	if body == null or not is_instance_valid(body):
		return false

	var body_rid = body.get_rid()
	return _bodies_in_wells.has(body_rid) and _bodies_in_wells[body_rid].size() > 0


## Get all gravity wells a body is currently in
func get_gravity_wells_for_body(body: RigidBody3D) -> Array:
	"""Get all gravity sources affecting a body."""
	if body == null or not is_instance_valid(body):
		return []

	var body_rid = body.get_rid()
	if _bodies_in_wells.has(body_rid):
		return _bodies_in_wells[body_rid]
	return []


## Enable or disable gravity calculations
func set_gravity_enabled(enabled: bool) -> void:
	"""Enable or disable gravity calculations."""
	gravity_enabled = enabled


## Enable or disable capture events
func set_capture_events_enabled(enabled: bool) -> void:
	"""Enable or disable capture event detection."""
	capture_events_enabled = enabled


## Set spatial partitioning enabled/disabled
func set_spatial_partitioning_enabled(enabled: bool) -> void:
	"""Enable or disable spatial partitioning optimization."""
	use_spatial_partitioning = enabled
	if not enabled:
		_spatial_grid.clear()


## Set maximum interaction radius for gravity calculations
func set_max_interaction_radius(radius: float) -> void:
	"""Set the maximum distance for gravity calculations."""
	max_interaction_radius = max(radius, 100.0)  # Minimum 100 meters


## Set spatial grid cell size
func set_grid_cell_size(size: float) -> void:
	"""Set the size of spatial grid cells."""
	_grid_cell_size = max(size, 10.0)  # Minimum 10 meters
	_spatial_grid.clear()  # Force rebuild on next update


## Get statistics about the physics engine
func get_statistics() -> Dictionary:
	"""Get statistics about the physics engine."""
	return {
		"celestial_bodies_count": celestial_bodies.size(),
		"registered_bodies_count": registered_bodies.size(),
		"last_calculation_time_ms": _last_calculation_time_ms,
		"total_forces_applied": _total_forces_applied,
		"spatial_culled_calculations": _spatial_culled_calculations,
		"use_spatial_partitioning": use_spatial_partitioning,
		"max_interaction_radius": max_interaction_radius,
		"grid_cell_size": _grid_cell_size,
		"spatial_grid_cells": _spatial_grid.size(),
		"gravity_enabled": gravity_enabled,
		"capture_events_enabled": capture_events_enabled,
		"gravitational_constant": G
	}


## Reset the physics engine state
func reset() -> void:
	"""Reset the physics engine to initial state."""
	celestial_bodies.clear()
	registered_bodies.clear()
	_bodies_in_wells.clear()
	_spatial_grid.clear()
	spacecraft = null
	_total_forces_applied = 0
	_spatial_culled_calculations = 0
	_last_calculation_time_ms = 0.0


## Shutdown the physics engine
func shutdown() -> void:
	"""Shutdown and clean up the physics engine."""
	reset()
	physics_space = null

