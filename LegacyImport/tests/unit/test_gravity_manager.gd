extends GdUnitTestSuite
## Unit tests for GravityManager
##
## Tests spherical gravity system that allows walking on planets.

# Reference to the autoload singleton
var gravity_manager: Node

# Test objects
var test_planet: Node3D
var test_moon: Node3D
var test_player: Node3D


func before_test() -> void:
	# Get reference to autoload
	gravity_manager = get_node("/root/GravityManager")

	# Create test objects
	test_planet = Node3D.new()
	test_planet.name = "TestPlanet"
	test_planet.global_position = Vector3.ZERO
	add_child(test_planet)

	test_moon = Node3D.new()
	test_moon.name = "TestMoon"
	test_moon.global_position = Vector3(5000, 0, 0)
	add_child(test_moon)

	test_player = Node3D.new()
	test_player.name = "TestPlayer"
	add_child(test_player)


func after_test() -> void:
	# Clean up test objects
	if is_instance_valid(test_planet):
		gravity_manager.unregister_gravity_source(test_planet)
		test_planet.queue_free()

	if is_instance_valid(test_moon):
		gravity_manager.unregister_gravity_source(test_moon)
		test_moon.queue_free()

	if is_instance_valid(test_player):
		test_player.queue_free()

	# Clear all sources to prevent interference between tests
	gravity_manager.clear_all_sources()


## Test: Register gravity source
func test_register_gravity_source() -> void:
	var initial_count = gravity_manager.get_stats().total_sources

	gravity_manager.register_gravity_source(test_planet, 1e24, 100.0)

	var new_count = gravity_manager.get_stats().total_sources
	assert_int(new_count).is_equal(initial_count + 1)


## Test: Cannot register null source
func test_cannot_register_null() -> void:
	var initial_count = gravity_manager.get_stats().total_sources

	gravity_manager.register_gravity_source(null, 1e24, 100.0)

	var new_count = gravity_manager.get_stats().total_sources
	assert_int(new_count).is_equal(initial_count)


## Test: Cannot register same source twice
func test_cannot_register_twice() -> void:
	gravity_manager.register_gravity_source(test_planet, 1e24, 100.0)
	var count_after_first = gravity_manager.get_stats().total_sources

	gravity_manager.register_gravity_source(test_planet, 1e24, 100.0)

	var count_after_second = gravity_manager.get_stats().total_sources
	assert_int(count_after_second).is_equal(count_after_first)


## Test: Unregister gravity source
func test_unregister_gravity_source() -> void:
	gravity_manager.register_gravity_source(test_planet, 1e24, 100.0)
	var count_after_register = gravity_manager.get_stats().total_sources

	gravity_manager.unregister_gravity_source(test_planet)

	var count_after_unregister = gravity_manager.get_stats().total_sources
	assert_int(count_after_unregister).is_equal(count_after_register - 1)


## Test: Gravity points toward center
func test_gravity_direction_points_to_center() -> void:
	# Register planet at origin
	gravity_manager.register_gravity_source(test_planet, 1e24, 100.0)

	# Test position above planet
	var test_position = Vector3(0, 200, 0)
	var gravity = gravity_manager.get_gravity_at_position(test_position)

	# Gravity should point downward (toward origin)
	var direction = gravity.normalized()
	assert_vector(direction).is_equal_approx(Vector3(0, -1, 0), Vector3(0.01, 0.01, 0.01))


## Test: Gravity points toward center from any position
func test_gravity_direction_from_side() -> void:
	gravity_manager.register_gravity_source(test_planet, 1e24, 100.0)

	# Test position to the right of planet
	var test_position = Vector3(300, 0, 0)
	var gravity = gravity_manager.get_gravity_at_position(test_position)

	# Gravity should point toward origin (left)
	var direction = gravity.normalized()
	assert_vector(direction).is_equal_approx(Vector3(-1, 0, 0), Vector3(0.01, 0.01, 0.01))


## Test: Gravity strength decreases with distance (inverse square)
func test_gravity_inverse_square_law() -> void:
	gravity_manager.register_gravity_source(test_planet, 1e24, 100.0)

	# Gravity at distance 100m
	var gravity_100 = gravity_manager.get_gravity_at_position(Vector3(0, 100, 0))
	var strength_100 = gravity_100.length()

	# Gravity at distance 200m (2x farther)
	var gravity_200 = gravity_manager.get_gravity_at_position(Vector3(0, 200, 0))
	var strength_200 = gravity_200.length()

	# At 2x distance, gravity should be 1/4 as strong (inverse square law)
	var expected_ratio = 0.25
	var actual_ratio = strength_200 / strength_100

	assert_float(actual_ratio).is_equal_approx(expected_ratio, 0.05)


## Test: Multiple gravity sources combine
func test_multiple_gravity_sources() -> void:
	# Register two sources
	test_planet.global_position = Vector3(0, 0, 0)
	test_moon.global_position = Vector3(1000, 0, 0)

	gravity_manager.register_gravity_source(test_planet, 1e24, 100.0)
	gravity_manager.register_gravity_source(test_moon, 1e23, 50.0)

	# Test position between them
	var test_position = Vector3(500, 0, 0)
	var total_gravity = gravity_manager.get_gravity_at_position(test_position)

	# Gravity should not be zero (combination of both sources)
	assert_float(total_gravity.length()).is_greater(0.0)


## Test: Get nearest gravity source
func test_get_nearest_source() -> void:
	test_planet.global_position = Vector3(0, 0, 0)
	test_moon.global_position = Vector3(5000, 0, 0)

	gravity_manager.register_gravity_source(test_planet, 1e24, 100.0)
	gravity_manager.register_gravity_source(test_moon, 1e23, 50.0)

	# Position closer to planet
	var position_near_planet = Vector3(100, 0, 0)
	var nearest_to_planet = gravity_manager.get_nearest_gravity_source(position_near_planet)
	assert_object(nearest_to_planet.node).is_equal(test_planet)

	# Position closer to moon
	var position_near_moon = Vector3(4900, 0, 0)
	var nearest_to_moon = gravity_manager.get_nearest_gravity_source(position_near_moon)
	assert_object(nearest_to_moon.node).is_equal(test_moon)


## Test: Distance to surface calculation
func test_distance_to_surface() -> void:
	test_planet.global_position = Vector3.ZERO
	gravity_manager.register_gravity_source(test_planet, 1e24, 100.0)

	# Position 200m from center = 100m from surface
	var test_position = Vector3(0, 200, 0)
	var distance = gravity_manager.get_distance_to_surface(test_position)

	assert_float(distance).is_equal_approx(100.0, 0.1)


## Test: Surface gravity calculation
func test_surface_gravity() -> void:
	test_planet.global_position = Vector3.ZERO
	var mass = 1e24
	var radius = 100.0

	gravity_manager.register_gravity_source(test_planet, mass, radius)

	var source = gravity_manager.get_nearest_gravity_source(test_planet.global_position)
	var surface_g = gravity_manager.get_surface_gravity(source)

	# Surface gravity = G * M / R^2
	# With G = 10.0, M = 1e24, R = 100
	# g = 10.0 * 1e24 / (100 * 100) = 10.0 * 1e24 / 10000 = 1e21
	var expected_g = (10.0 * mass) / (radius * radius)

	assert_float(surface_g).is_equal_approx(expected_g, 1.0)


## Test: Get up direction (opposite of gravity)
func test_get_up_direction() -> void:
	test_planet.global_position = Vector3.ZERO
	gravity_manager.register_gravity_source(test_planet, 1e24, 100.0)

	# Position above planet
	var test_position = Vector3(0, 200, 0)
	var up = gravity_manager.get_up_direction(test_position)

	# Up should point away from planet (upward)
	assert_vector(up).is_equal_approx(Vector3(0, 1, 0), Vector3(0.01, 0.01, 0.01))


## Test: Get up direction from side
func test_get_up_direction_from_side() -> void:
	test_planet.global_position = Vector3.ZERO
	gravity_manager.register_gravity_source(test_planet, 1e24, 100.0)

	# Position to the right of planet
	var test_position = Vector3(300, 0, 0)
	var up = gravity_manager.get_up_direction(test_position)

	# Up should point away from planet (to the right)
	assert_vector(up).is_equal_approx(Vector3(1, 0, 0), Vector3(0.01, 0.01, 0.01))


## Test: Is in gravity well
func test_is_in_gravity_well() -> void:
	test_planet.global_position = Vector3.ZERO
	gravity_manager.register_gravity_source(test_planet, 1e24, 100.0)

	# Position close to planet (within 2x radius = 200m)
	var close_position = Vector3(0, 150, 0)
	assert_bool(gravity_manager.is_in_gravity_well(close_position)).is_true()

	# Position far from planet (beyond 2x radius)
	var far_position = Vector3(0, 300, 0)
	assert_bool(gravity_manager.is_in_gravity_well(far_position)).is_false()


## Test: Set source active/inactive
func test_set_source_active() -> void:
	test_planet.global_position = Vector3.ZERO
	gravity_manager.register_gravity_source(test_planet, 1e24, 100.0)

	# Get gravity when active
	var test_position = Vector3(0, 200, 0)
	var gravity_active = gravity_manager.get_gravity_at_position(test_position)

	# Deactivate source
	gravity_manager.set_source_active(test_planet, false)

	# Get gravity when inactive (should be zero)
	var gravity_inactive = gravity_manager.get_gravity_at_position(test_position)

	assert_float(gravity_active.length()).is_greater(0.0)
	assert_float(gravity_inactive.length()).is_equal(0.0)


## Test: Clear all sources
func test_clear_all_sources() -> void:
	gravity_manager.register_gravity_source(test_planet, 1e24, 100.0)
	gravity_manager.register_gravity_source(test_moon, 1e23, 50.0)

	var count_before = gravity_manager.get_stats().total_sources

	gravity_manager.clear_all_sources()

	var count_after = gravity_manager.get_stats().total_sources

	assert_int(count_before).is_greater(0)
	assert_int(count_after).is_equal(0)


## Test: No gravity when no sources registered
func test_no_gravity_without_sources() -> void:
	gravity_manager.clear_all_sources()

	var test_position = Vector3(0, 100, 0)
	var gravity = gravity_manager.get_gravity_at_position(test_position)

	assert_vector(gravity).is_equal(Vector3.ZERO)


## Test: Gravity at minimum distance
func test_gravity_at_minimum_distance() -> void:
	test_planet.global_position = Vector3.ZERO
	gravity_manager.register_gravity_source(test_planet, 1e24, 100.0)

	# Position very close to center (should use MIN_DISTANCE)
	var test_position = Vector3(0, 0.1, 0)
	var gravity = gravity_manager.get_gravity_at_position(test_position)

	# Should not be infinite or NaN
	assert_float(gravity.length()).is_not_nan()
	assert_float(gravity.length()).is_not_inf()
