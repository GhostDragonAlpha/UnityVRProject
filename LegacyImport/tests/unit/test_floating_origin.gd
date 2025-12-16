extends GdUnitTestSuite
## Unit tests for FloatingOriginSystem
##
## Tests the floating origin system that prevents floating-point precision errors
## at large distances by shifting the universe back toward the origin.

# Reference to the autoload singleton
var floating_origin: Node

# Test objects
var test_player: Node3D
var test_object1: Node3D
var test_object2: Node3D


func before_test() -> void:
	# Get reference to autoload
	floating_origin = get_node("/root/FloatingOriginSystem")

	# Create test objects
	test_player = Node3D.new()
	test_player.name = "TestPlayer"
	add_child(test_player)

	test_object1 = Node3D.new()
	test_object1.name = "TestObject1"
	add_child(test_object1)

	test_object2 = Node3D.new()
	test_object2.name = "TestObject2"
	add_child(test_object2)


func after_test() -> void:
	# Clean up test objects
	if is_instance_valid(test_player):
		floating_origin.unregister_object(test_player)
		test_player.queue_free()

	if is_instance_valid(test_object1):
		floating_origin.unregister_object(test_object1)
		test_object1.queue_free()

	if is_instance_valid(test_object2):
		floating_origin.unregister_object(test_object2)
		test_object2.queue_free()

	# Reset player reference
	floating_origin._player = null


## Test: Object registration
func test_object_registration() -> void:
	# Initially should have 0 registered objects (cleanup from previous tests)
	var initial_count = floating_origin._registered_objects.size()

	# Register test object
	floating_origin.register_object(test_object1)

	# Should have 1 more object
	assert_int(floating_origin._registered_objects.size()).is_equal(initial_count + 1)
	assert_bool(test_object1 in floating_origin._registered_objects).is_true()


## Test: Object unregistration
func test_object_unregistration() -> void:
	# Register and then unregister
	floating_origin.register_object(test_object1)
	var count_after_register = floating_origin._registered_objects.size()

	floating_origin.unregister_object(test_object1)

	# Should have 1 less object
	assert_int(floating_origin._registered_objects.size()).is_equal(count_after_register - 1)
	assert_bool(test_object1 in floating_origin._registered_objects).is_false()


## Test: Cannot register null object
func test_cannot_register_null() -> void:
	var initial_count = floating_origin._registered_objects.size()

	# Try to register null (should fail silently or log error)
	floating_origin.register_object(null)

	# Count should not change
	assert_int(floating_origin._registered_objects.size()).is_equal(initial_count)


## Test: Cannot register same object twice
func test_cannot_register_twice() -> void:
	floating_origin.register_object(test_object1)
	var count_after_first = floating_origin._registered_objects.size()

	# Try to register again
	floating_origin.register_object(test_object1)

	# Count should not change
	assert_int(floating_origin._registered_objects.size()).is_equal(count_after_first)


## Test: Set player
func test_set_player() -> void:
	floating_origin.set_player(test_player)

	# Player should be set
	assert_object(floating_origin._player).is_equal(test_player)

	# Player should be automatically registered
	assert_bool(test_player in floating_origin._registered_objects).is_true()


## Test: Cannot set null player
func test_cannot_set_null_player() -> void:
	# Set valid player first
	floating_origin.set_player(test_player)

	# Try to set null
	floating_origin.set_player(null)

	# Should still have original player
	assert_object(floating_origin._player).is_equal(test_player)


## Test: Distance from origin calculation
func test_distance_from_origin() -> void:
	floating_origin.set_player(test_player)

	# Move player to known position
	test_player.global_position = Vector3(3000, 4000, 0)

	# Distance should be sqrt(3000^2 + 4000^2) = 5000
	var distance = floating_origin.get_distance_from_origin()
	assert_float(distance).is_equal_approx(5000.0, 0.01)


## Test: Universe offset tracking
func test_universe_offset_initial() -> void:
	# Initially should be zero
	var offset = floating_origin.get_universe_offset()
	assert_vector(offset).is_equal(Vector3.ZERO)


## Test: True global position calculation
func test_true_global_position() -> void:
	floating_origin.register_object(test_object1)

	# Set positions
	test_object1.global_position = Vector3(100, 200, 300)
	floating_origin._universe_offset = Vector3(1000, 2000, 3000)

	# True position should be local + offset
	var true_pos = floating_origin.get_true_global_position(test_object1)
	assert_vector(true_pos).is_equal(Vector3(1100, 2200, 3300))


## Test: Should shift when threshold exceeded
func test_should_shift_at_threshold() -> void:
	floating_origin.set_player(test_player)

	# Move player just under threshold
	test_player.global_position = Vector3(9999, 0, 0)
	assert_bool(floating_origin._should_shift()).is_false()

	# Move player to threshold
	test_player.global_position = Vector3(10000, 0, 0)
	assert_bool(floating_origin._should_shift()).is_true()

	# Move player past threshold
	test_player.global_position = Vector3(15000, 0, 0)
	assert_bool(floating_origin._should_shift()).is_true()


## Test: Universe shift moves all objects
func test_universe_shift_moves_all_objects() -> void:
	# Setup: Player and two objects
	floating_origin.set_player(test_player)
	floating_origin.register_object(test_object1)
	floating_origin.register_object(test_object2)

	# Set initial positions
	test_player.global_position = Vector3(15000, 0, 0)
	test_object1.global_position = Vector3(14000, 0, 0)
	test_object2.global_position = Vector3(16000, 0, 0)

	# Perform shift
	floating_origin._perform_shift()

	# Player should be back near origin
	assert_float(test_player.global_position.length()).is_less(100.0)

	# All objects should have shifted by the same amount
	# Object 1 was 1000m behind player, should still be 1000m behind
	var relative_pos1 = test_object1.global_position - test_player.global_position
	assert_vector(relative_pos1).is_equal_approx(Vector3(-1000, 0, 0), Vector3(0.01, 0.01, 0.01))

	# Object 2 was 1000m ahead of player, should still be 1000m ahead
	var relative_pos2 = test_object2.global_position - test_player.global_position
	assert_vector(relative_pos2).is_equal_approx(Vector3(1000, 0, 0), Vector3(0.01, 0.01, 0.01))


## Test: Universe offset updated after shift
func test_universe_offset_updated_after_shift() -> void:
	floating_origin.set_player(test_player)

	# Move player far from origin
	var initial_player_pos = Vector3(15000, 5000, -8000)
	test_player.global_position = initial_player_pos

	# Perform shift
	floating_origin._perform_shift()

	# Universe offset should equal the original player position
	var offset = floating_origin.get_universe_offset()
	assert_vector(offset).is_equal_approx(initial_player_pos, Vector3(0.01, 0.01, 0.01))


## Test: True position preserved after shift
func test_true_position_preserved_after_shift() -> void:
	floating_origin.set_player(test_player)
	floating_origin.register_object(test_object1)

	# Set initial positions
	test_player.global_position = Vector3(15000, 0, 0)
	test_object1.global_position = Vector3(14000, 5000, -3000)

	# Get true positions before shift
	var true_pos_player_before = floating_origin.get_true_global_position(test_player)
	var true_pos_object_before = floating_origin.get_true_global_position(test_object1)

	# Perform shift
	floating_origin._perform_shift()

	# Get true positions after shift
	var true_pos_player_after = floating_origin.get_true_global_position(test_player)
	var true_pos_object_after = floating_origin.get_true_global_position(test_object1)

	# True positions should be unchanged
	assert_vector(true_pos_player_after).is_equal_approx(true_pos_player_before, Vector3(0.01, 0.01, 0.01))
	assert_vector(true_pos_object_after).is_equal_approx(true_pos_object_before, Vector3(0.01, 0.01, 0.01))


## Test: No jitter after shift (player near origin)
func test_no_jitter_after_shift() -> void:
	floating_origin.set_player(test_player)

	# Move player past threshold
	test_player.global_position = Vector3(12000, 0, 0)

	# Perform shift
	floating_origin._perform_shift()

	# Player should be very close to origin (within floating point precision)
	var distance_from_origin = test_player.global_position.length()
	assert_float(distance_from_origin).is_less(1.0)  # Less than 1 meter from origin


## Test: Multiple shifts accumulate offset correctly
func test_multiple_shifts_accumulate_offset() -> void:
	floating_origin.set_player(test_player)

	# First shift
	test_player.global_position = Vector3(12000, 0, 0)
	floating_origin._perform_shift()
	var offset_after_first = floating_origin.get_universe_offset()

	# Second shift (move player again)
	test_player.global_position = Vector3(0, 15000, 0)
	floating_origin._perform_shift()
	var offset_after_second = floating_origin.get_universe_offset()

	# Offsets should have accumulated
	assert_float(offset_after_second.length()).is_greater(offset_after_first.length())


## Test: Stats dictionary
func test_get_stats() -> void:
	floating_origin.set_player(test_player)
	floating_origin.register_object(test_object1)

	test_player.global_position = Vector3(5000, 0, 0)

	var stats = floating_origin.get_stats()

	# Check all expected keys exist
	assert_bool(stats.has("registered_objects")).is_true()
	assert_bool(stats.has("player_set")).is_true()
	assert_bool(stats.has("distance_from_origin")).is_true()
	assert_bool(stats.has("universe_offset")).is_true()
	assert_bool(stats.has("shift_threshold")).is_true()
	assert_bool(stats.has("will_shift_soon")).is_true()

	# Check values
	assert_int(stats.registered_objects).is_equal(2)  # Player + test_object1
	assert_bool(stats.player_set).is_true()
	assert_float(stats.distance_from_origin).is_equal_approx(5000.0, 0.01)
	assert_float(stats.shift_threshold).is_equal(10000.0)
