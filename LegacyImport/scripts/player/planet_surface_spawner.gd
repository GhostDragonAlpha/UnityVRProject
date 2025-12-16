extends Node
class_name PlanetSurfaceSpawner
## Calculates spawn positions on planet surfaces with correct orientation and gravity
##
## This class handles:
## - Surface spawn point calculation using raycasts
## - Orientation alignment to surface normal
## - Gravity vector calculation based on planet properties
## - Terrain collision detection to prevent spawning inside geometry
##
## Requirements:
## - Calculate correct surface position above terrain
## - Orient player "up" vector to match planet surface normal
## - Apply planet-specific gravity to walking controller
## - Use raycast/sphere cast to find exact surface point

signal spawn_point_calculated(position: Vector3, orientation: Basis, gravity: Vector3)
signal spawn_failed(reason: String)

## Distance to offset spawn point above surface (prevents clipping)
@export var spawn_height_offset: float = 0.1

## Maximum raycast distance to search for surface
@export var max_raycast_distance: float = 100.0

## Raycast collision layers (what to consider as "surface")
@export var surface_collision_mask: int = 1

## Reference to the physics world
var space_state: PhysicsDirectSpaceState3D = null


func _ready() -> void:
	# Get the physics space state
	if not Engine.is_editor_hint():
		await get_tree().process_frame  # Wait one frame for physics to initialize
		space_state = get_viewport().get_world_3d().direct_space_state


## Calculate spawn position on planet surface
## @param planet: The planet to spawn on
## @param approximate_position: Approximate position (e.g., spacecraft position)
## @param walking_controller: WalkingController to configure
## @returns Dictionary with keys: success (bool), position (Vector3), orientation (Basis), gravity (Vector3)
func calculate_spawn_point(
	planet: CelestialBody,
	approximate_position: Vector3,
	walking_controller: WalkingController = null
) -> Dictionary:
	if not planet:
		var error = "Planet reference is null"
		push_error("[PlanetSurfaceSpawner] " + error)
		spawn_failed.emit(error)
		return {"success": false, "error": error}

	# Ensure we have physics space state
	if not space_state:
		space_state = get_viewport().get_world_3d().direct_space_state

	if not space_state:
		var error = "Physics space state not available"
		push_error("[PlanetSurfaceSpawner] " + error)
		spawn_failed.emit(error)
		return {"success": false, "error": error}

	# Step 1: Calculate direction from planet center to approximate position
	var to_surface = approximate_position - planet.global_position
	var distance_from_center = to_surface.length()

	if distance_from_center < 0.001:
		var error = "Approximate position too close to planet center"
		push_error("[PlanetSurfaceSpawner] " + error)
		spawn_failed.emit(error)
		return {"success": false, "error": error}

	var direction_to_surface = to_surface.normalized()

	# Step 2: Calculate raycast start and end points
	# Start from above the approximate position (away from planet center)
	var raycast_start = approximate_position + direction_to_surface * 10.0
	# End at or below the surface
	var raycast_end = planet.global_position + direction_to_surface * (planet.radius - 10.0)

	# Step 3: Perform raycast to find exact surface point
	var query = PhysicsRayQueryParameters3D.create(raycast_start, raycast_end)
	query.collision_mask = surface_collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result = space_state.intersect_ray(query)

	var surface_position: Vector3
	var surface_normal: Vector3

	if result.is_empty():
		# No collision detected - use calculated position on sphere surface
		print("[PlanetSurfaceSpawner] No terrain collision detected, using spherical surface")
		surface_position = planet.global_position + direction_to_surface * planet.radius
		surface_normal = direction_to_surface
	else:
		# Collision detected - use exact hit point and normal
		surface_position = result.position
		surface_normal = result.normal
		print("[PlanetSurfaceSpawner] Terrain collision detected at ", surface_position)

	# Step 4: Apply spawn height offset to prevent clipping
	var spawn_position = surface_position + surface_normal * spawn_height_offset

	# Step 5: Calculate orientation (align "up" to surface normal)
	var spawn_orientation = calculate_surface_orientation(surface_normal)

	# Step 6: Calculate gravity vector (points toward planet center)
	var gravity_vector = calculate_gravity_vector(planet, spawn_position)

	# Step 7: Configure walking controller if provided
	if walking_controller:
		configure_walking_controller(walking_controller, planet, spawn_position, spawn_orientation, gravity_vector)

	# Emit signal
	spawn_point_calculated.emit(spawn_position, spawn_orientation, gravity_vector)

	print("[PlanetSurfaceSpawner] Spawn point calculated:")
	print("  Position: ", spawn_position)
	print("  Surface Normal: ", surface_normal)
	print("  Gravity: ", gravity_vector)

	return {
		"success": true,
		"position": spawn_position,
		"orientation": spawn_orientation,
		"gravity_vector": gravity_vector,
		"gravity_magnitude": gravity_vector.length(),
		"surface_normal": surface_normal
	}


## Calculate orientation basis aligned to surface normal
## Makes the "up" direction point away from the planet center
## @param surface_normal: Normal vector of the surface (pointing away from planet)
## @returns Basis representing the orientation
func calculate_surface_orientation(surface_normal: Vector3) -> Basis:
	# The "up" direction should be the surface normal
	var up = surface_normal.normalized()

	# Choose a forward direction perpendicular to up
	# Use global forward (north) as reference
	var reference_forward = Vector3.FORWARD

	# If up is parallel to reference forward, use a different reference
	if abs(up.dot(reference_forward)) > 0.99:
		reference_forward = Vector3.RIGHT

	# Calculate right vector (perpendicular to both up and forward)
	var right = reference_forward.cross(up).normalized()

	# Recalculate forward to ensure orthogonality
	var forward = up.cross(right).normalized()

	# Construct basis: (right, up, -forward) for Godot's coordinate system
	# Note: Godot uses -Z as forward
	return Basis(right, up, -forward)


## Calculate gravity vector for a position on the planet
## @param planet: The planet
## @param position: Position to calculate gravity at
## @returns Gravity vector (direction and magnitude)
func calculate_gravity_vector(planet: CelestialBody, position: Vector3) -> Vector3:
	# Use the planet's gravity calculation method
	var gravity_acceleration = planet.calculate_gravity_at_point(position)

	# Gravity points toward planet center (opposite of surface normal)
	# The magnitude is already calculated by the planet

	print("[PlanetSurfaceSpawner] Calculated gravity magnitude: %.6f m/s²" % gravity_acceleration.length())

	return gravity_acceleration


## Configure walking controller with spawn parameters
## @param walking_controller: The WalkingController to configure
## @param planet: The planet
## @param spawn_position: Calculated spawn position
## @param spawn_orientation: Calculated orientation basis
## @param gravity_vector: Calculated gravity vector
func configure_walking_controller(
	walking_controller: WalkingController,
	planet: CelestialBody,
	spawn_position: Vector3,
	spawn_orientation: Basis,
	gravity_vector: Vector3
) -> void:
	if not walking_controller:
		return

	# Set position
	walking_controller.global_position = spawn_position

	# Set orientation
	walking_controller.global_transform.basis = spawn_orientation

	# Set gravity (WalkingController expects magnitude and direction separately)
	walking_controller.current_gravity = gravity_vector.length()
	walking_controller.gravity_direction = gravity_vector.normalized()

	# Set planet reference
	walking_controller.current_planet = planet

	print("[PlanetSurfaceSpawner] Walking controller configured:")
	print("  Gravity magnitude: %.6f m/s²" % walking_controller.current_gravity)
	print("  Gravity direction: ", walking_controller.gravity_direction)


## Find surface point using sphere cast (more robust than raycast)
## @param planet: The planet
## @param approximate_position: Approximate position
## @param sphere_radius: Radius of the sphere for casting
## @returns Dictionary with success, position, and normal
func find_surface_with_sphere_cast(
	planet: CelestialBody,
	approximate_position: Vector3,
	sphere_radius: float = 0.5
) -> Dictionary:
	if not space_state:
		space_state = get_viewport().get_world_3d().direct_space_state

	if not space_state:
		return {"success": false, "error": "Physics space state not available"}

	# Calculate direction from planet center
	var to_surface = approximate_position - planet.global_position
	var direction = to_surface.normalized()

	# Start sphere cast from above
	var cast_start = approximate_position + direction * 10.0
	var cast_end = planet.global_position + direction * planet.radius

	# Create sphere cast query
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = sphere_radius
	query.shape = sphere_shape
	query.transform = Transform3D(Basis(), cast_start)
	query.motion = cast_end - cast_start
	query.collision_mask = surface_collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var results = space_state.cast_motion(query)

	if results.is_empty() or results.size() < 2:
		# No hit - use sphere surface
		return {
			"success": false,
			"position": planet.global_position + direction * planet.radius,
			"normal": direction
		}

	# Calculate hit position
	var safe_fraction = results[0]  # First contact
	var hit_position = cast_start + (cast_end - cast_start) * safe_fraction
	var hit_normal = (hit_position - planet.global_position).normalized()

	return {
		"success": true,
		"position": hit_position,
		"normal": hit_normal
	}


## Calculate spawn point near spacecraft with terrain detection
## This is a convenience method for the common case of spawning near a landed spacecraft
## @param planet: The planet to spawn on
## @param spacecraft: The spacecraft node
## @param offset_from_craft: Offset from spacecraft (in local spacecraft space)
## @param walking_controller: Optional WalkingController to configure
## @returns Dictionary with spawn information
func calculate_spawn_near_spacecraft(
	planet: CelestialBody,
	spacecraft: Node3D,
	offset_from_craft: Vector3 = Vector3(0, 0, 3),  # 3 meters in front
	walking_controller: WalkingController = null
) -> Dictionary:
	if not spacecraft:
		var error = "Spacecraft reference is null"
		spawn_failed.emit(error)
		return {"success": false, "error": error}

	# Calculate approximate position near spacecraft
	# Use spacecraft's local coordinate system for the offset
	var approximate_position = spacecraft.global_position + spacecraft.global_transform.basis * offset_from_craft

	# Use the standard spawn point calculation
	return calculate_spawn_point(planet, approximate_position, walking_controller)


## Validate spawn point (ensure it's on the planet surface and not inside terrain)
## @param planet: The planet
## @param position: Position to validate
## @param tolerance: Distance tolerance for "on surface"
## @returns true if valid, false otherwise
func validate_spawn_point(planet: CelestialBody, position: Vector3, tolerance: float = 1.0) -> bool:
	if not planet:
		return false

	# Check distance from planet center
	var distance_from_center = (position - planet.global_position).length()
	var expected_distance = planet.radius

	# Position should be at or slightly above the surface
	if distance_from_center < expected_distance - tolerance:
		print("[PlanetSurfaceSpawner] Spawn point too close to planet center (inside terrain)")
		return false

	if distance_from_center > expected_distance + max_raycast_distance:
		print("[PlanetSurfaceSpawner] Spawn point too far from planet surface")
		return false

	return true
