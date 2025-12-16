## Example: How to add Inventory3DUI to your VR scene
## This script demonstrates the complete setup process.
##
## Usage:
## 1. Attach this script to your main VR scene root node
## 2. Assign the player_node and inventory references in the inspector
## 3. Configure the toggle_inventory_action in your input map
## 4. Run the scene

extends Node3D

## Reference to the player (XROrigin3D)
@export var player_node: Node3D

## Reference to the inventory system (or create one)
@export var inventory: Inventory

## Input action for toggling inventory
@export var toggle_inventory_action: String = "toggle_inventory"

## The inventory UI instance
var inventory_ui: Inventory3DUI = null


func _ready() -> void:
	# Create inventory system if not provided
	if not inventory:
		inventory = Inventory.new()
		inventory.name = "PlayerInventory"
		inventory.max_total_capacity = 1000
		inventory.max_per_item_capacity = 100
		add_child(inventory)
		print("Created new Inventory system")

	# Get player node if not assigned
	if not player_node:
		# Try to find XROrigin3D in scene
		player_node = find_child("XROrigin3D", true, false)
		if not player_node:
			push_error("Player node not found! Please assign player_node in inspector.")
			return

	# Load and instantiate the inventory UI scene
	var inventory_scene = preload("res://scenes/ui/inventory_panel.tscn")
	inventory_ui = inventory_scene.instantiate()
	add_child(inventory_ui)
	print("Inventory UI added to scene")

	# Initialize with player and inventory
	if inventory_ui.initialize(player_node, inventory):
		print("Inventory UI initialized successfully")

		# Connect to signals for debugging
		_connect_inventory_signals()

		# Add some test items
		_add_test_items()
	else:
		push_error("Failed to initialize Inventory UI")


func _process(_delta: float) -> void:
	# Check for toggle input
	if Input.is_action_just_pressed(toggle_inventory_action):
		if inventory_ui:
			inventory_ui.toggle_inventory()


func _connect_inventory_signals() -> void:
	"""Connect to inventory signals for debugging and feedback."""
	if not inventory_ui:
		return

	inventory_ui.inventory_opened.connect(_on_inventory_opened)
	inventory_ui.inventory_closed.connect(_on_inventory_closed)
	inventory_ui.item_moved.connect(_on_item_moved)
	inventory_ui.item_dropped.connect(_on_item_dropped)
	inventory_ui.gesture_recognized.connect(_on_gesture_recognized)

	# Also connect to inventory system signals
	if inventory:
		inventory.item_added.connect(_on_item_added)
		inventory.item_removed.connect(_on_item_removed)
		inventory.inventory_full.connect(_on_inventory_full)


func _add_test_items() -> void:
	"""Add some test items to demonstrate the system."""
	if not inventory:
		return

	# Add various resources
	inventory.add_item("iron_ore", 25)
	inventory.add_item("copper_ore", 18)
	inventory.add_item("silicon", 10)
	inventory.add_item("ice", 30)
	inventory.add_item("helium3", 5)

	print("Added test items to inventory")


## Signal Handlers

func _on_inventory_opened() -> void:
	print("Inventory opened")
	# You could trigger haptic feedback here
	var engine = get_node_or_null("/root/ResonanceEngine")
	if engine:
		engine.trigger_haptic_feedback("both", 0.3, 0.1)


func _on_inventory_closed() -> void:
	print("Inventory closed")


func _on_item_moved(from_slot: int, to_slot: int) -> void:
	print("Item moved from slot %d to slot %d" % [from_slot, to_slot])
	# Trigger subtle haptic feedback
	var engine = get_node_or_null("/root/ResonanceEngine")
	if engine:
		engine.trigger_haptic_feedback("both", 0.2, 0.05)


func _on_item_dropped(item_data: Dictionary) -> void:
	print("Item dropped: %s" % item_data.get("item_id", "unknown"))


func _on_gesture_recognized(gesture_type: String) -> void:
	print("Gesture recognized: %s" % gesture_type)

	# Stronger haptic feedback for gestures
	var engine = get_node_or_null("/root/ResonanceEngine")
	if engine:
		engine.trigger_haptic_feedback("both", 0.5, 0.15)

	# Optional: Show notification or play sound
	match gesture_type:
		"sort":
			print("  → Inventory sorted alphabetically")
		"quick_stack":
			print("  → Matching items stacked together")
		"quick_transfer":
			print("  → Quick transfer initiated")


func _on_item_added(item_id: String, amount: int, new_total: int) -> void:
	print("Added %d %s (total: %d)" % [amount, item_id, new_total])


func _on_item_removed(item_id: String, amount: int, new_total: int) -> void:
	print("Removed %d %s (remaining: %d)" % [amount, item_id, new_total])


func _on_inventory_full(item_id: String, attempted_amount: int) -> void:
	print("WARNING: Inventory full! Cannot add %d %s" % [attempted_amount, item_id])
	# Could show a UI warning or play a sound


## Public API for external systems

func open_inventory() -> void:
	"""Open the inventory UI."""
	if inventory_ui:
		inventory_ui.open_inventory()


func close_inventory() -> void:
	"""Close the inventory UI."""
	if inventory_ui:
		inventory_ui.close_inventory()


func get_inventory_ui() -> Inventory3DUI:
	"""Get the inventory UI instance."""
	return inventory_ui


func get_inventory() -> Inventory:
	"""Get the inventory system instance."""
	return inventory


## Input Map Setup Instructions
##
## To use the toggle_inventory_action, add it to your input map:
##
## 1. Open Project > Project Settings > Input Map
## 2. Add a new action: "toggle_inventory"
## 3. Assign key/button:
##    - Desktop: Tab or I key
##    - VR: Menu button on controller
##
## Or add via code in project settings:
## InputMap.add_action("toggle_inventory")
## var key_event = InputEventKey.new()
## key_event.keycode = KEY_I
## InputMap.action_add_event("toggle_inventory", key_event)
