## Inventory3DUI - VR-Friendly 3D Inventory Management System
## Displays inventory in a 3D grid with gesture-based controls for VR.
## Supports drag-and-drop, sorting, stacking, and controller interaction.
##
## Requirements: Task 6.5
## - 3D grid layout positioned in front of player
## - VR controller interaction (hover, grab, release)
## - Gesture controls (sort, transfer, stack)
## - HTTP API integration

class_name Inventory3DUI
extends Node3D

## Signals
signal inventory_opened
signal inventory_closed
signal item_selected(item_data: Dictionary)
signal item_moved(from_slot: int, to_slot: int)
signal item_dropped(item_data: Dictionary)
signal gesture_recognized(gesture_type: String)

## Grid configuration
@export var grid_size: Vector2i = Vector2i(10, 5)  # 10x5 grid (50 slots)
@export var slot_size: float = 0.1  # 10cm per slot
@export var slot_spacing: float = 0.01  # 1cm spacing between slots
@export var distance_from_player: float = 1.0  # 1m in front of player

## Visual settings
@export var panel_color: Color = Color(0.1, 0.1, 0.15, 0.9)
@export var enabled: bool = false  # Start closed

## VR controller references
var vr_manager: VRManager = null
var left_controller: XRController3D = null
var right_controller: XRController3D = null

## Inventory system reference
var inventory: Inventory = null

## Grid and slots
var slot_grid: Array[InventoryItemSlot] = []
var background_panel: MeshInstance3D = null

## Player reference for positioning
var player: Node3D = null

## Interaction state
var hovered_slot: InventoryItemSlot = null
var grabbed_item_data: Dictionary = {}
var grabbed_from_slot: int = -1
var grabbing_hand: String = ""  # "left" or "right"

## Gesture recognition
var gesture_tracker: GestureTracker = null

## Controller raycast for interaction
var left_raycast: RayCast3D = null
var right_raycast: RayCast3D = null

## UI state
var is_open: bool = false


func _ready() -> void:
	# Get VRManager from ResonanceEngine
	var engine = get_node_or_null("/root/ResonanceEngine")
	if engine and engine.vr_manager:
		vr_manager = engine.vr_manager
		_connect_vr_controllers()

	# Create UI elements
	_create_background_panel()
	_create_slot_grid()
	_create_gesture_tracker()

	# Start hidden
	visible = false
	set_process(false)
	set_physics_process(false)


func _connect_vr_controllers() -> void:
	"""Connect to VR controllers for interaction."""
	if not vr_manager:
		return

	# Get controller references
	left_controller = vr_manager.left_controller
	right_controller = vr_manager.right_controller

	if left_controller:
		_setup_controller_raycast(left_controller, true)

	if right_controller:
		_setup_controller_raycast(right_controller, false)


func _setup_controller_raycast(controller: XRController3D, is_left: bool) -> void:
	"""Set up raycast for controller interaction."""
	var raycast = RayCast3D.new()
	raycast.name = "InventoryRaycast"
	raycast.target_position = Vector3(0, 0, -10)  # 10m forward
	raycast.enabled = false
	raycast.collision_mask = 0x01  # Layer 1 for inventory UI
	controller.add_child(raycast)

	if is_left:
		left_raycast = raycast
	else:
		right_raycast = raycast

	# Connect button signals
	controller.button_pressed.connect(_on_controller_button_pressed.bind(controller))
	controller.button_released.connect(_on_controller_button_released.bind(controller))


func _create_background_panel() -> void:
	"""Create the background panel for the inventory."""
	background_panel = MeshInstance3D.new()
	background_panel.name = "BackgroundPanel"

	# Calculate panel size
	var panel_width = grid_size.x * (slot_size + slot_spacing)
	var panel_height = grid_size.y * (slot_size + slot_spacing)

	# Create panel mesh
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(panel_width, panel_height, 0.02)
	background_panel.mesh = box_mesh

	# Create panel material
	var panel_material = StandardMaterial3D.new()
	panel_material.albedo_color = panel_color
	panel_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	panel_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	background_panel.material_override = panel_material

	# Set collision layer for raycasting
	background_panel.set_layer_mask_value(1, true)

	add_child(background_panel)


func _create_slot_grid() -> void:
	"""Create the grid of inventory slots."""
	var total_slots = grid_size.x * grid_size.y
	slot_grid.resize(total_slots)

	# Calculate starting position (centered)
	var grid_width = grid_size.x * (slot_size + slot_spacing)
	var grid_height = grid_size.y * (slot_size + slot_spacing)
	var start_x = -grid_width / 2.0 + (slot_size / 2.0)
	var start_y = grid_height / 2.0 - (slot_size / 2.0)

	# Create slots
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var slot_index = y * grid_size.x + x
			var slot = InventoryItemSlot.new()
			slot.name = "Slot_%d" % slot_index
			slot.slot_index = slot_index
			slot.slot_size = slot_size

			# Position slot
			var pos_x = start_x + x * (slot_size + slot_spacing)
			var pos_y = start_y - y * (slot_size + slot_spacing)
			slot.position = Vector3(pos_x, pos_y, 0.01)

			# Connect slot signals
			slot.slot_hovered.connect(_on_slot_hovered)
			slot.slot_unhovered.connect(_on_slot_unhovered)
			slot.slot_grabbed.connect(_on_slot_grabbed)
			slot.slot_released.connect(_on_slot_released)

			add_child(slot)
			slot_grid[slot_index] = slot


func _create_gesture_tracker() -> void:
	"""Create gesture recognition system."""
	gesture_tracker = GestureTracker.new()
	gesture_tracker.name = "GestureTracker"
	gesture_tracker.gesture_recognized.connect(_on_gesture_recognized)
	add_child(gesture_tracker)


func initialize(player_node: Node3D, inventory_system: Inventory) -> bool:
	"""Initialize the inventory UI with player and inventory references."""
	if not player_node or not inventory_system:
		push_error("Inventory3DUI: Cannot initialize without player and inventory")
		return false

	player = player_node
	inventory = inventory_system

	# Connect inventory signals
	inventory.inventory_changed.connect(_on_inventory_changed)

	# Update all slots with current inventory
	_refresh_all_slots()

	return true


func open_inventory() -> void:
	"""Open the inventory UI."""
	if is_open:
		return

	is_open = true
	visible = true
	enabled = true
	set_process(true)
	set_physics_process(true)

	# Enable raycasts
	if left_raycast:
		left_raycast.enabled = true
	if right_raycast:
		right_raycast.enabled = true

	# Position in front of player
	_position_in_front_of_player()

	# Refresh inventory display
	_refresh_all_slots()

	inventory_opened.emit()
	_log_info("Inventory opened")


func close_inventory() -> void:
	"""Close the inventory UI."""
	if not is_open:
		return

	# Drop any grabbed item back to original slot
	if grabbed_from_slot >= 0:
		_cancel_grab()

	is_open = false
	visible = false
	enabled = false
	set_process(false)
	set_physics_process(false)

	# Disable raycasts
	if left_raycast:
		left_raycast.enabled = false
	if right_raycast:
		right_raycast.enabled = false

	inventory_closed.emit()
	_log_info("Inventory closed")


func toggle_inventory() -> void:
	"""Toggle inventory open/closed."""
	if is_open:
		close_inventory()
	else:
		open_inventory()


func _position_in_front_of_player() -> void:
	"""Position the inventory panel in front of the player."""
	if not player:
		return

	# Get player forward direction
	var player_transform = player.global_transform
	var forward = -player_transform.basis.z  # -Z is forward in Godot
	var up = Vector3.UP

	# Position at distance from player
	var target_position = player.global_position + forward * distance_from_player

	# Look at player
	global_position = target_position
	look_at(player.global_position, up)


func _process(delta: float) -> void:
	"""Update inventory UI each frame."""
	if not enabled or not is_open:
		return

	# Update raycast interactions
	_update_raycast_interaction(left_raycast, "left")
	_update_raycast_interaction(right_raycast, "right")

	# Track gestures if grabbing
	if grabbed_from_slot >= 0 and gesture_tracker:
		var controller = left_controller if grabbing_hand == "left" else right_controller
		if controller:
			gesture_tracker.track_controller(controller, delta)


func _update_raycast_interaction(raycast: RayCast3D, hand: String) -> void:
	"""Update interaction for a controller raycast."""
	if not raycast or not raycast.enabled:
		return

	raycast.force_raycast_update()

	if raycast.is_colliding():
		var collider = raycast.get_collider()

		# Check if colliding with a slot
		if collider is StaticBody3D and collider.has_meta("inventory_slot"):
			var slot = collider.get_meta("inventory_slot") as InventoryItemSlot
			if slot and slot != hovered_slot:
				# Unhover previous slot
				if hovered_slot:
					hovered_slot.set_hovered(false)

				# Hover new slot
				slot.set_hovered(true)
				hovered_slot = slot
		else:
			# Not hovering a slot
			if hovered_slot:
				hovered_slot.set_hovered(false)
				hovered_slot = null
	else:
		# Raycast not hitting anything
		if hovered_slot:
			hovered_slot.set_hovered(false)
			hovered_slot = null


func _on_controller_button_pressed(button: String, controller: XRController3D) -> void:
	"""Handle controller button press."""
	if not enabled or not is_open:
		return

	var hand = "left" if controller == left_controller else "right"

	# Trigger button (index trigger) - grab/release
	if button == "trigger_click" or button == "grip_click":
		if grabbed_from_slot < 0:
			# Try to grab hovered item
			if hovered_slot and not hovered_slot.is_empty():
				_grab_item_from_slot(hovered_slot, hand)
		else:
			# Release grabbed item to hovered slot
			if hovered_slot:
				_release_item_to_slot(hovered_slot)
			else:
				_cancel_grab()


func _on_controller_button_released(button: String, controller: XRController3D) -> void:
	"""Handle controller button release."""
	pass  # Currently handled on press for better responsiveness


func _grab_item_from_slot(slot: InventoryItemSlot, hand: String) -> void:
	"""Grab an item from a slot."""
	if grabbed_from_slot >= 0:
		return  # Already grabbing something

	grabbed_item_data = slot.get_item_data()
	grabbed_from_slot = slot.get_slot_index()
	grabbing_hand = hand

	# Visual feedback
	slot.set_grabbed(true)

	# Start gesture tracking
	if gesture_tracker:
		gesture_tracker.start_tracking()

	_log_debug("Grabbed item from slot %d" % grabbed_from_slot)


func _release_item_to_slot(target_slot: InventoryItemSlot) -> void:
	"""Release grabbed item to a target slot."""
	if grabbed_from_slot < 0:
		return  # Not grabbing anything

	var target_index = target_slot.get_slot_index()

	# Check if target slot is the same as source
	if target_index == grabbed_from_slot:
		_cancel_grab()
		return

	# Handle item swap/merge
	if target_slot.is_empty():
		# Simple move
		_move_item(grabbed_from_slot, target_index)
	else:
		# Try to stack if same item type
		var target_data = target_slot.get_item_data()
		if target_data.get("item_id") == grabbed_item_data.get("item_id"):
			_stack_items(grabbed_from_slot, target_index)
		else:
			# Swap items
			_swap_items(grabbed_from_slot, target_index)

	# Clear grab state
	_clear_grab_state()

	item_moved.emit(grabbed_from_slot, target_index)


func _cancel_grab() -> void:
	"""Cancel the current grab operation."""
	if grabbed_from_slot >= 0:
		var slot = slot_grid[grabbed_from_slot]
		if slot:
			slot.set_grabbed(false)

	_clear_grab_state()


func _clear_grab_state() -> void:
	"""Clear grab state variables."""
	if grabbed_from_slot >= 0:
		var slot = slot_grid[grabbed_from_slot]
		if slot:
			slot.set_grabbed(false)

	grabbed_item_data = {}
	grabbed_from_slot = -1
	grabbing_hand = ""

	if gesture_tracker:
		gesture_tracker.stop_tracking()


func _move_item(from_index: int, to_index: int) -> void:
	"""Move an item from one slot to another."""
	if not inventory:
		return

	var from_slot = slot_grid[from_index]
	var to_slot = slot_grid[to_index]

	if not from_slot or not to_slot:
		return

	# Get item data
	var item_data = from_slot.get_item_data()

	# Update slots
	to_slot.set_item(item_data)
	from_slot.clear()

	_log_debug("Moved item from slot %d to %d" % [from_index, to_index])


func _swap_items(slot_a_index: int, slot_b_index: int) -> void:
	"""Swap items between two slots."""
	var slot_a = slot_grid[slot_a_index]
	var slot_b = slot_grid[slot_b_index]

	if not slot_a or not slot_b:
		return

	var item_a = slot_a.get_item_data()
	var item_b = slot_b.get_item_data()

	slot_a.set_item(item_b)
	slot_b.set_item(item_a)

	_log_debug("Swapped items between slots %d and %d" % [slot_a_index, slot_b_index])


func _stack_items(from_index: int, to_index: int) -> void:
	"""Stack items from one slot to another."""
	var from_slot = slot_grid[from_index]
	var to_slot = slot_grid[to_index]

	if not from_slot or not to_slot:
		return

	var from_data = from_slot.get_item_data()
	var to_data = to_slot.get_item_data()

	# Add quantities
	var from_qty = from_data.get("quantity", 1)
	var to_qty = to_data.get("quantity", 1)
	var new_qty = from_qty + to_qty

	# Update target slot
	var stacked_data = to_data.duplicate()
	stacked_data["quantity"] = new_qty
	to_slot.set_item(stacked_data)

	# Clear source slot
	from_slot.clear()

	_log_debug("Stacked %d items from slot %d to %d (total: %d)" % [from_qty, from_index, to_index, new_qty])


func _on_slot_hovered(slot: InventoryItemSlot) -> void:
	"""Handle slot hover event."""
	pass  # Visual feedback already handled by slot


func _on_slot_unhovered(slot: InventoryItemSlot) -> void:
	"""Handle slot unhover event."""
	pass  # Visual feedback already handled by slot


func _on_slot_grabbed(slot: InventoryItemSlot) -> void:
	"""Handle slot grab event."""
	pass  # Handled by controller button press


func _on_slot_released(slot: InventoryItemSlot) -> void:
	"""Handle slot release event."""
	pass  # Handled by controller button press


func _on_inventory_changed() -> void:
	"""Handle inventory contents changing."""
	if is_open:
		_refresh_all_slots()


func _refresh_all_slots() -> void:
	"""Refresh all slots with current inventory data."""
	if not inventory:
		return

	# Get all items from inventory
	var items = inventory.get_all_items()

	# Clear all slots first
	for slot in slot_grid:
		if slot:
			slot.clear()

	# Populate slots with items
	var slot_index = 0
	for item_id in items.keys():
		if slot_index >= slot_grid.size():
			break

		var quantity = items[item_id]
		var item_data = {
			"item_id": item_id,
			"quantity": quantity
		}

		slot_grid[slot_index].set_item(item_data)
		slot_index += 1


func _on_gesture_recognized(gesture_type: String) -> void:
	"""Handle recognized gesture."""
	_log_info("Gesture recognized: %s" % gesture_type)

	match gesture_type:
		"sort":
			sort_inventory()
		"quick_stack":
			quick_stack()
		"quick_transfer":
			if grabbed_from_slot >= 0:
				# Transfer to external container (not implemented yet)
				pass

	gesture_recognized.emit(gesture_type)


## Public API Methods

func sort_inventory() -> void:
	"""Sort inventory items alphabetically."""
	if not inventory:
		return

	# Get all items
	var items = inventory.get_all_items()
	var item_list = []

	for item_id in items.keys():
		item_list.append({
			"item_id": item_id,
			"quantity": items[item_id]
		})

	# Sort alphabetically by item_id
	item_list.sort_custom(func(a, b): return a.item_id < b.item_id)

	# Clear and repopulate slots
	for slot in slot_grid:
		if slot:
			slot.clear()

	for i in range(min(item_list.size(), slot_grid.size())):
		slot_grid[i].set_item(item_list[i])

	_log_info("Inventory sorted")


func quick_stack() -> void:
	"""Stack all matching items together."""
	if not inventory:
		return

	# Group items by ID
	var grouped_items = {}
	for slot in slot_grid:
		if slot and not slot.is_empty():
			var data = slot.get_item_data()
			var item_id = data.get("item_id", "")
			if item_id:
				if not grouped_items.has(item_id):
					grouped_items[item_id] = 0
				grouped_items[item_id] += data.get("quantity", 1)

	# Clear all slots
	for slot in slot_grid:
		if slot:
			slot.clear()

	# Repopulate with stacked items
	var slot_index = 0
	for item_id in grouped_items.keys():
		if slot_index >= slot_grid.size():
			break

		var item_data = {
			"item_id": item_id,
			"quantity": grouped_items[item_id]
		}
		slot_grid[slot_index].set_item(item_data)
		slot_index += 1

	_log_info("Items quick-stacked")


func get_inventory_state() -> Dictionary:
	"""Get current state of inventory UI for HTTP API."""
	var state = {
		"is_open": is_open,
		"grid_size": {"x": grid_size.x, "y": grid_size.y},
		"total_slots": slot_grid.size(),
		"items": []
	}

	for i in range(slot_grid.size()):
		var slot = slot_grid[i]
		if slot and not slot.is_empty():
			var data = slot.get_item_data()
			data["slot_index"] = i
			state.items.append(data)

	return state


## Logging helpers

func _log_info(message: String) -> void:
	var engine = get_node_or_null("/root/ResonanceEngine")
	if engine and engine.has_method("log_info"):
		engine.log_info("[Inventory3DUI] " + message)
	else:
		print("[INFO] [Inventory3DUI] " + message)


func _log_debug(message: String) -> void:
	var engine = get_node_or_null("/root/ResonanceEngine")
	if engine and engine.has_method("log_debug"):
		engine.log_debug("[Inventory3DUI] " + message)
	else:
		print("[DEBUG] [Inventory3DUI] " + message)


func _log_warning(message: String) -> void:
	var engine = get_node_or_null("/root/ResonanceEngine")
	if engine and engine.has_method("log_warning"):
		engine.log_warning("[Inventory3DUI] " + message)
	else:
		push_warning("[Inventory3DUI] " + message)


## GestureTracker - Simple gesture recognition for inventory
class GestureTracker:
	extends Node

	signal gesture_recognized(gesture_type: String)

	var is_tracking: bool = false
	var positions: Array[Vector3] = []
	var max_positions: int = 30  # Track last 30 positions (0.5 sec at 60fps)

	func start_tracking() -> void:
		is_tracking = true
		positions.clear()

	func stop_tracking() -> void:
		is_tracking = false
		_analyze_gesture()
		positions.clear()

	func track_controller(controller: XRController3D, delta: float) -> void:
		if not is_tracking or not controller:
			return

		positions.append(controller.global_position)

		# Keep only recent positions
		if positions.size() > max_positions:
			positions.pop_front()

	func _analyze_gesture() -> void:
		"""Analyze tracked positions to recognize gestures."""
		if positions.size() < 10:
			return  # Not enough data

		# Calculate total movement
		var total_distance = 0.0
		for i in range(1, positions.size()):
			total_distance += positions[i].distance_to(positions[i-1])

		# Check for circular motion (sort gesture)
		if _is_circular_motion():
			gesture_recognized.emit("sort")
			return

		# Check for quick horizontal swipe (transfer gesture)
		if _is_horizontal_swipe():
			gesture_recognized.emit("quick_transfer")
			return

		# Check for pinch motion (stack gesture)
		if _is_pinch_motion():
			gesture_recognized.emit("quick_stack")
			return

	func _is_circular_motion() -> bool:
		"""Detect circular motion pattern."""
		if positions.size() < 20:
			return false

		# Calculate approximate center
		var center = Vector3.ZERO
		for pos in positions:
			center += pos
		center /= positions.size()

		# Check if positions form a circular path
		var avg_radius = 0.0
		for pos in positions:
			avg_radius += center.distance_to(pos)
		avg_radius /= positions.size()

		# Check radius variance (should be low for circle)
		var radius_variance = 0.0
		for pos in positions:
			var radius = center.distance_to(pos)
			radius_variance += abs(radius - avg_radius)
		radius_variance /= positions.size()

		# Low variance = circular motion
		return radius_variance < 0.05 and avg_radius > 0.1

	func _is_horizontal_swipe() -> bool:
		"""Detect horizontal swipe motion."""
		if positions.size() < 10:
			return false

		var start_pos = positions[0]
		var end_pos = positions[positions.size() - 1]
		var delta = end_pos - start_pos

		# Check if movement is primarily horizontal
		var horizontal_dist = abs(delta.x)
		var vertical_dist = abs(delta.y)

		return horizontal_dist > 0.3 and horizontal_dist > vertical_dist * 2.0

	func _is_pinch_motion() -> bool:
		"""Detect pinch/compression motion."""
		if positions.size() < 10:
			return false

		# Check if movement gets progressively smaller (compression)
		var early_range = _get_position_range(0, positions.size() / 2)
		var late_range = _get_position_range(positions.size() / 2, positions.size())

		# Late range should be smaller (pinching inward)
		return late_range < early_range * 0.5

	func _get_position_range(start_idx: int, end_idx: int) -> float:
		"""Get the spatial range of positions in an index range."""
		if end_idx <= start_idx:
			return 0.0

		var min_pos = positions[start_idx]
		var max_pos = positions[start_idx]

		for i in range(start_idx + 1, end_idx):
			var pos = positions[i]
			min_pos.x = min(min_pos.x, pos.x)
			min_pos.y = min(min_pos.y, pos.y)
			min_pos.z = min(min_pos.z, pos.z)
			max_pos.x = max(max_pos.x, pos.x)
			max_pos.y = max(max_pos.y, pos.y)
			max_pos.z = max(max_pos.z, pos.z)

		return min_pos.distance_to(max_pos)
