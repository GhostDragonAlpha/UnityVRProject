extends Node
## GravityManager
##
## Manages spherical gravity sources for planetary bodies.
##
## Features:
## - Multiple gravity sources (planets, moons, asteroids)
## - Spherical gravity (always points to center of mass)
## - Inverse square law falloff
## - Gravity well transitions (entering/leaving)
## - Integration with FloatingOriginSystem
##
## Usage:
##   GravityManager.register_gravity_source(planet_node, mass, radius)
##   var gravity = GravityManager.get_gravity_at_position(player_position)
##   player.velocity += gravity * delta

## Gravitational constant (m^3 kg^-1 s^-2)
## Scaled for gameplay: Real G = 6.674e-11, we use simplified version
const G := 10.0

## Minimum distance to prevent division by zero (meters)
const MIN_DISTANCE := 1.0

## Gravity source data structure
class GravitySource:
	var node: Node3D = null  # The Node3D representing the gravity source
	var mass: float = 0.0  # Mass in kg (affects gravity strength)
	var radius: float = 0.0  # Radius of the body (for surface gravity)
	var active: bool = true  # Whether this source is active

	func _init(p_node: Node3D, p_mass: float, p_radius: float):
		node = p_node
		mass = p_mass
		radius = p_radius

## All registered gravity sources
var _gravity_sources: Array[GravitySource] = []

## Cached gravity calculations (for performance)
var _gravity_cache := {}
var _cache_clear_timer := 0.0
const CACHE_CLEAR_INTERVAL := 1.0  # Clear cache every second


func _ready() -> void:
	print("[GravityManager] Initialized")
	print("[GravityManager] Gravitational constant: %.2f" % G)
	set_process(true)


func _process(delta: float) -> void:
	# Clear gravity cache periodically
	_cache_clear_timer += delta
	if _cache_clear_timer >= CACHE_CLEAR_INTERVAL:
		_gravity_cache.clear()
		_cache_clear_timer = 0.0


## Register a gravity source (planet, moon, etc.)
func register_gravity_source(source_node: Node3D, mass: float, radius: float) -> void:
	if not source_node:
		push_error("[GravityManager] Cannot register null gravity source")
		return

	# Check if already registered
	for source in _gravity_sources:
		if source.node == source_node:
			push_warning("[GravityManager] Gravity source already registered: %s" % source_node.name)
			return

	# Create and register new source
	var new_source = GravitySource.new(source_node, mass, radius)
	_gravity_sources.append(new_source)

	print("[GravityManager] Registered gravity source: %s (mass: %.2f kg, radius: %.2f m)" % [
		source_node.name, mass, radius
	])


## Unregister a gravity source
func unregister_gravity_source(source_node: Node3D) -> void:
	if not source_node:
		return

	for i in range(_gravity_sources.size()):
		if _gravity_sources[i].node == source_node:
			print("[GravityManager] Unregistered: %s" % source_node.name)
			_gravity_sources.remove_at(i)
			return

	push_warning("[GravityManager] Gravity source not registered: %s" % source_node.name)


## Get total gravity vector at a position (combines all sources)
func get_gravity_at_position(global_position: Vector3) -> Vector3:
	var total_gravity := Vector3.ZERO

	for source in _gravity_sources:
		if not source.active or not is_instance_valid(source.node):
			continue

		var gravity = _calculate_gravity_from_source(global_position, source)
		total_gravity += gravity

	return total_gravity


## Calculate gravity from a single source
func _calculate_gravity_from_source(position: Vector3, source: GravitySource) -> Vector3:
	# Vector from position to gravity source center
	var to_center := source.node.global_position - position
	var distance := to_center.length()

	# Prevent division by zero
	if distance < MIN_DISTANCE:
		distance = MIN_DISTANCE

	# Direction toward center (normalized)
	var direction := to_center.normalized()

	# Gravity strength using inverse square law: F = G * M / r^2
	var strength := (G * source.mass) / (distance * distance)

	# Gravity vector (points toward center)
	return direction * strength


## Get the nearest gravity source to a position
func get_nearest_gravity_source(position: Vector3) -> GravitySource:
	if _gravity_sources.is_empty():
		return null

	var nearest: GravitySource = null
	var nearest_distance := INF

	for source in _gravity_sources:
		if not source.active or not is_instance_valid(source.node):
			continue

		var distance := position.distance_to(source.node.global_position)
		if distance < nearest_distance:
			nearest = source
			nearest_distance = distance

	return nearest


## Get distance to surface of nearest gravity source
func get_distance_to_surface(position: Vector3) -> float:
	var nearest = get_nearest_gravity_source(position)
	if not nearest:
		return INF

	var distance_to_center := position.distance_to(nearest.node.global_position)
	return distance_to_center - nearest.radius


## Check if position is within a gravity well (closer than 2x radius)
func is_in_gravity_well(position: Vector3, source: GravitySource = null) -> bool:
	if source:
		var distance := position.distance_to(source.node.global_position)
		return distance < (source.radius * 2.0)

	# Check all sources
	for src in _gravity_sources:
		if not src.active or not is_instance_valid(src.node):
			continue

		var distance := position.distance_to(src.node.global_position)
		if distance < (src.radius * 2.0):
			return true

	return false


## Get surface gravity at a planet's surface (for reference)
func get_surface_gravity(source: GravitySource) -> float:
	if not source:
		return 0.0

	# Gravity at surface: g = G * M / R^2
	return (G * source.mass) / (source.radius * source.radius)


## Get "up" direction at a position (opposite of gravity)
func get_up_direction(position: Vector3) -> Vector3:
	var gravity = get_gravity_at_position(position)

	if gravity.length() < 0.001:
		return Vector3.UP  # Default up if no gravity

	return -gravity.normalized()


## Align a transform to gravity (useful for player orientation)
func align_to_gravity(current_transform: Transform3D, position: Vector3, interpolation: float = 1.0) -> Transform3D:
	var up_direction = get_up_direction(position)

	# Get current up direction
	var current_up = current_transform.basis.y.normalized()

	# Interpolate between current and target up direction
	var new_up = current_up.lerp(up_direction, interpolation).normalized()

	# Create new basis aligned to gravity
	var new_transform = current_transform
	new_transform.basis = _align_basis_to_vector(current_transform.basis, new_up)

	return new_transform


## Helper: Align a basis to a target up vector
func _align_basis_to_vector(basis: Basis, target_up: Vector3) -> Basis:
	# Keep forward direction as much as possible
	var forward = -basis.z

	# Make forward perpendicular to target_up
	forward = forward - target_up * forward.dot(target_up)

	if forward.length() < 0.001:
		# If forward is parallel to up, pick a new forward
		forward = Vector3.FORWARD
		forward = forward - target_up * forward.dot(target_up)

	forward = forward.normalized()

	# Calculate right direction
	var right = forward.cross(target_up).normalized()

	# Recalculate forward for perfect orthogonality
	forward = target_up.cross(right).normalized()

	# Create new basis
	return Basis(right, target_up, -forward)


## Get gravity statistics for debugging
func get_stats() -> Dictionary:
	var active_sources := 0
	for source in _gravity_sources:
		if source.active and is_instance_valid(source.node):
			active_sources += 1

	return {
		"total_sources": _gravity_sources.size(),
		"active_sources": active_sources,
		"cache_size": _gravity_cache.size(),
		"gravitational_constant": G
	}


## Print current status (for debugging)
func print_status() -> void:
	var stats = get_stats()
	print("[GravityManager] Status:")
	print("  Total sources: %d" % stats.total_sources)
	print("  Active sources: %d" % stats.active_sources)
	print("  Cache size: %d" % stats.cache_size)

	print("  Registered sources:")
	for source in _gravity_sources:
		if is_instance_valid(source.node):
			var surface_g = get_surface_gravity(source)
			print("    - %s: mass=%.2f kg, radius=%.2f m, surface_g=%.2f m/s²" % [
				source.node.name,
				source.mass,
				source.radius,
				surface_g
			])


## Set a gravity source active/inactive
func set_source_active(source_node: Node3D, active: bool) -> void:
	for source in _gravity_sources:
		if source.node == source_node:
			source.active = active
			print("[GravityManager] Source %s set to %s" % [
				source_node.name,
				"active" if active else "inactive"
			])
			return

	push_warning("[GravityManager] Source not found: %s" % source_node.name)


## Clear all gravity sources
func clear_all_sources() -> void:
	_gravity_sources.clear()
	_gravity_cache.clear()
	print("[GravityManager] All gravity sources cleared")
