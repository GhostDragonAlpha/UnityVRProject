extends GdUnitTestSuite

## Integration test for layer systems in main scene
## Tests that all 4 layers (Life Support, Inventory, Resources, Power) are present
## and working together in the solar_system_landing scene

const SCENE_PATH = "res://scenes/celestial/solar_system_landing.tscn"

## Test that all layers are present in the main scene
func test_all_layers_present_in_main_scene() -> void:
	var scene = load(SCENE_PATH).instantiate()
	add_child(scene)

	# Verify Layer 1: Life Support
	var life_support = scene.get_node_or_null("LifeSupportSystem")
	assert_object(life_support).is_not_null()
	assert_that(life_support.get_script()).is_not_null()

	# Verify Layer 2: Inventory
	var inventory = scene.get_node_or_null("InventorySystem")
	assert_object(inventory).is_not_null()
	assert_that(inventory.get_script()).is_not_null()

	# Verify Layer 3: Resources
	var resources = scene.get_node_or_null("ResourceSystem")
	assert_object(resources).is_not_null()
	assert_that(resources.get_script()).is_not_null()

	# Verify Layer 4: Power
	var power = scene.get_node_or_null("PowerGridSystem")
	assert_object(power).is_not_null()
	assert_that(power.get_script()).is_not_null()

	scene.queue_free()


## Test that Life Support system signals work correctly
func test_life_support_signals_work() -> void:
	var scene = load(SCENE_PATH).instantiate()
	add_child(scene)

	var life_support = scene.get_node("LifeSupportSystem")
	var signal_received = false
	var received_current: float = 0.0
	var received_max: float = 0.0

	# Connect to the oxygen_level_changed signal
	life_support.oxygen_level_changed.connect(func(current: float, max: float):
		signal_received = true
		received_current = current
		received_max = max
	)

	# Consume oxygen and verify signal was emitted
	life_support.consume_oxygen(10.0)

	assert_bool(signal_received).is_true()
	assert_float(received_current).is_equal(90.0)
	assert_float(received_max).is_equal(100.0)

	scene.queue_free()


## Test that Inventory system signals work correctly
func test_inventory_signals_work() -> void:
	var scene = load(SCENE_PATH).instantiate()
	add_child(scene)

	var inventory = scene.get_node("InventorySystem")
	var signal_received = false
	var received_item_id: String = ""
	var received_amount: int = 0

	# Connect to the item_added signal
	inventory.item_added.connect(func(item_id: String, amount: int, new_total: int):
		signal_received = true
		received_item_id = item_id
		received_amount = amount
	)

	# Add an item and verify signal was emitted
	var added = inventory.add_item("iron_ore", 50)

	assert_bool(signal_received).is_true()
	assert_int(added).is_equal(50)
	assert_str(received_item_id).is_equal("iron_ore")
	assert_int(received_amount).is_equal(50)

	scene.queue_free()


## Test that Power Grid system signals work correctly
func test_power_grid_signals_work() -> void:
	var scene = load(SCENE_PATH).instantiate()
	add_child(scene)

	var power_grid = scene.get_node("PowerGridSystem")
	var signal_received = false
	var received_current: float = 0.0
	var received_max: float = 0.0

	# Connect to the power_changed signal
	power_grid.power_changed.connect(func(current: float, max: float):
		signal_received = true
		received_current = current
		received_max = max
	)

	# Register a generator and verify signal was emitted
	power_grid.register_generator(100.0)

	assert_bool(signal_received).is_true()
	assert_float(received_current).is_equal(100.0)
	assert_float(received_max).is_equal(1000.0)

	scene.queue_free()


## Test that all systems can be accessed from the scene root
func test_systems_accessible_from_root() -> void:
	var scene = load(SCENE_PATH).instantiate()
	add_child(scene)

	# Test accessing systems via get_node
	var life_support = scene.get_node("LifeSupportSystem")
	var inventory = scene.get_node("InventorySystem")
	var resources = scene.get_node("ResourceSystem")
	var power = scene.get_node("PowerGridSystem")

	# Verify all nodes are valid
	assert_that(life_support).is_not_null()
	assert_that(inventory).is_not_null()
	assert_that(resources).is_not_null()
	assert_that(power).is_not_null()

	# Verify they are children of the scene root
	assert_that(life_support.get_parent()).is_equal(scene)
	assert_that(inventory.get_parent()).is_equal(scene)
	assert_that(resources.get_parent()).is_equal(scene)
	assert_that(power.get_parent()).is_equal(scene)

	scene.queue_free()


## Test basic functionality of each layer system
func test_layer_systems_basic_functionality() -> void:
	var scene = load(SCENE_PATH).instantiate()
	add_child(scene)

	# Test Life Support
	var life_support = scene.get_node("LifeSupportSystem")
	var initial_oxygen = life_support.oxygen_level
	life_support.consume_oxygen(5.0)
	assert_float(life_support.oxygen_level).is_equal(initial_oxygen - 5.0)

	# Test Inventory
	var inventory = scene.get_node("InventorySystem")
	var added = inventory.add_item("test_item", 25)
	assert_int(added).is_equal(25)
	assert_int(inventory.get_item_count("test_item")).is_equal(25)

	# Test Power Grid
	var power = scene.get_node("PowerGridSystem")
	power.register_generator(50.0)
	assert_float(power.total_generation).is_equal(50.0)

	# Test Resource System (verify it's initialized)
	var resources = scene.get_node("ResourceSystem")
	assert_that(resources.resource_types).is_not_null()

	scene.queue_free()
