## Inventory - Player Resource Inventory System
## Stores collected resources in a Dictionary with capacity limits.
## Supports serialization for save files using JSON.
##
## Requirements:
## - 57.1: Store collected resources in Dictionary
## - 57.2: Implement add/remove operations
## - 57.3: Check capacity limits
## - 57.4: Serialize for save files using JSON
## - 57.5: Provide query methods
extends Node
class_name Inventory

## Emitted when an item is added to the inventory
signal item_added(item_id: String, amount: int, new_total: int)
## Emitted when an item is removed from the inventory
signal item_removed(item_id: String, amount: int, new_total: int)
## Emitted when inventory is full and cannot add more items
signal inventory_full(item_id: String, attempted_amount: int)
## Emitted when inventory contents change
signal inventory_changed()
## Emitted when capacity limit is reached for a specific item
signal item_capacity_reached(item_id: String, current_amount: int, max_amount: int)

## Maximum total capacity (total items across all types)
## Requirement 57.3: Check capacity limits
@export var max_total_capacity: int = 1000

## Maximum capacity per item type (0 = unlimited per type)
@export var max_per_item_capacity: int = 100

## The inventory storage - Dictionary mapping item_id to amount
## Requirement 57.1: Store collected resources in Dictionary
var _items: Dictionary = {}

## Track total item count for capacity checking
var _total_count: int = 0


func _ready() -> void:
	_items = {}
	_total_count = 0


## Add items to the inventory
## Requirement 57.2: Implement add/remove operations
## Requirement 57.3: Check capacity limits
## Returns the actual amount added (may be less if capacity is reached)
func add_item(item_id: String, amount: int) -> int:
	"""Add items to the inventory. Returns the actual amount added."""
	if amount <= 0:
		return 0
	
	if item_id.is_empty():
		return 0
	
	# Calculate how much we can actually add
	var actual_amount := _calculate_addable_amount(item_id, amount)
	
	if actual_amount <= 0:
		inventory_full.emit(item_id, amount)
		return 0
	
	# Add to inventory
	var current_amount := get_item_count(item_id)
	var new_total := current_amount + actual_amount
	_items[item_id] = new_total
	_total_count += actual_amount
	
	item_added.emit(item_id, actual_amount, new_total)
	inventory_changed.emit()
	
	# Check if we hit capacity
	if actual_amount < amount:
		if new_total >= max_per_item_capacity and max_per_item_capacity > 0:
			item_capacity_reached.emit(item_id, new_total, max_per_item_capacity)
		elif _total_count >= max_total_capacity:
			inventory_full.emit(item_id, amount - actual_amount)
	
	return actual_amount


## Calculate how much of an item can actually be added
## Requirement 57.3: Check capacity limits
func _calculate_addable_amount(item_id: String, requested_amount: int) -> int:
	"""Calculate how much of an item can be added given capacity limits."""
	var addable := requested_amount
	
	# Check total capacity limit
	var remaining_total_capacity := max_total_capacity - _total_count
	if remaining_total_capacity <= 0:
		return 0
	addable = mini(addable, remaining_total_capacity)
	
	# Check per-item capacity limit (if set)
	if max_per_item_capacity > 0:
		var current_amount := get_item_count(item_id)
		var remaining_item_capacity := max_per_item_capacity - current_amount
		if remaining_item_capacity <= 0:
			return 0
		addable = mini(addable, remaining_item_capacity)
	
	return addable


## Remove items from the inventory
## Requirement 57.2: Implement add/remove operations
## Returns the actual amount removed (may be less if not enough items)
func remove_item(item_id: String, amount: int) -> int:
	"""Remove items from the inventory. Returns the actual amount removed."""
	if amount <= 0:
		return 0
	
	if item_id.is_empty():
		return 0
	
	var current_amount := get_item_count(item_id)
	if current_amount <= 0:
		return 0
	
	# Calculate actual amount to remove
	var actual_amount := mini(amount, current_amount)
	var new_total := current_amount - actual_amount
	
	# Update inventory
	if new_total <= 0:
		_items.erase(item_id)
		new_total = 0
	else:
		_items[item_id] = new_total
	
	_total_count -= actual_amount
	_total_count = maxi(_total_count, 0)  # Safety clamp
	
	item_removed.emit(item_id, actual_amount, new_total)
	inventory_changed.emit()
	
	return actual_amount


## Get the count of a specific item
## Requirement 57.5: Provide query methods
func get_item_count(item_id: String) -> int:
	"""Get the count of a specific item in the inventory."""
	if item_id.is_empty():
		return 0
	return _items.get(item_id, 0)


## Check if the inventory contains at least a certain amount of an item
## Requirement 57.5: Provide query methods
func has_item(item_id: String, amount: int = 1) -> bool:
	"""Check if the inventory contains at least the specified amount of an item."""
	return get_item_count(item_id) >= amount


## Get all items in the inventory
## Requirement 57.5: Provide query methods
func get_all_items() -> Dictionary:
	"""Get a copy of all items in the inventory."""
	return _items.duplicate()


## Get list of all item IDs in the inventory
## Requirement 57.5: Provide query methods
func get_item_ids() -> Array:
	"""Get a list of all item IDs in the inventory."""
	return _items.keys()


## Get total number of items (sum of all amounts)
## Requirement 57.5: Provide query methods
func get_total_count() -> int:
	"""Get the total count of all items in the inventory."""
	return _total_count


## Get number of unique item types
## Requirement 57.5: Provide query methods
func get_unique_item_count() -> int:
	"""Get the number of unique item types in the inventory."""
	return _items.size()


## Check if inventory is empty
## Requirement 57.5: Provide query methods
func is_empty() -> bool:
	"""Check if the inventory is empty."""
	return _items.is_empty()


## Check if inventory is full (total capacity)
## Requirement 57.5: Provide query methods
func is_full() -> bool:
	"""Check if the inventory has reached total capacity."""
	return _total_count >= max_total_capacity


## Get remaining total capacity
## Requirement 57.5: Provide query methods
func get_remaining_capacity() -> int:
	"""Get the remaining total capacity."""
	return maxi(max_total_capacity - _total_count, 0)


## Get remaining capacity for a specific item
## Requirement 57.5: Provide query methods
func get_remaining_item_capacity(item_id: String) -> int:
	"""Get the remaining capacity for a specific item type."""
	if max_per_item_capacity <= 0:
		# No per-item limit, return total remaining
		return get_remaining_capacity()
	
	var current := get_item_count(item_id)
	var item_remaining := max_per_item_capacity - current
	var total_remaining := get_remaining_capacity()
	
	return mini(item_remaining, total_remaining)


## Clear all items from the inventory
func clear() -> void:
	"""Clear all items from the inventory."""
	_items.clear()
	_total_count = 0
	inventory_changed.emit()


## Set an item count directly (for loading saves)
func set_item_count(item_id: String, amount: int) -> void:
	"""Set the count of a specific item directly (bypasses capacity checks)."""
	if item_id.is_empty():
		return
	
	var old_amount := get_item_count(item_id)
	
	if amount <= 0:
		_items.erase(item_id)
		_total_count -= old_amount
	else:
		_items[item_id] = amount
		_total_count += (amount - old_amount)
	
	_total_count = maxi(_total_count, 0)
	inventory_changed.emit()


## Serialize inventory to JSON string
## Requirement 57.4: Serialize for save files using JSON
func to_json() -> String:
	"""Serialize the inventory to a JSON string."""
	var data := {
		"items": _items.duplicate(),
		"max_total_capacity": max_total_capacity,
		"max_per_item_capacity": max_per_item_capacity
	}
	return JSON.stringify(data)


## Deserialize inventory from JSON string
## Requirement 57.4: Serialize for save files using JSON
func from_json(json_string: String) -> bool:
	"""Deserialize the inventory from a JSON string. Returns true on success."""
	if json_string.is_empty():
		return false
	
	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_error("Inventory: Failed to parse JSON: " + json.get_error_message())
		return false
	
	var data = json.get_data()
	if not data is Dictionary:
		push_error("Inventory: JSON data is not a Dictionary")
		return false
	
	return _load_from_dict(data)


## Get inventory state as a Dictionary (for saving)
## Requirement 57.4: Serialize for save files using JSON
func get_state() -> Dictionary:
	"""Get the inventory state as a Dictionary for saving."""
	return {
		"items": _items.duplicate(),
		"max_total_capacity": max_total_capacity,
		"max_per_item_capacity": max_per_item_capacity
	}


## Set inventory state from a Dictionary (for loading)
## Requirement 57.4: Serialize for save files using JSON
func set_state(state: Dictionary) -> bool:
	"""Set the inventory state from a Dictionary. Returns true on success."""
	return _load_from_dict(state)


## Internal method to load inventory from a dictionary
func _load_from_dict(data: Dictionary) -> bool:
	"""Load inventory data from a dictionary."""
	# Load capacity settings if present
	if data.has("max_total_capacity"):
		max_total_capacity = int(data.max_total_capacity)
	if data.has("max_per_item_capacity"):
		max_per_item_capacity = int(data.max_per_item_capacity)
	
	# Load items
	if data.has("items") and data.items is Dictionary:
		_items.clear()
		_total_count = 0
		
		for item_id in data.items:
			var amount = data.items[item_id]
			if amount is int or amount is float:
				var int_amount := int(amount)
				if int_amount > 0:
					_items[str(item_id)] = int_amount
					_total_count += int_amount
		
		inventory_changed.emit()
		return true
	
	return false


## Transfer items to another inventory
func transfer_to(other_inventory: Inventory, item_id: String, amount: int) -> int:
	"""Transfer items to another inventory. Returns the actual amount transferred."""
	if other_inventory == null or other_inventory == self:
		return 0
	
	# Check how much we have
	var available := get_item_count(item_id)
	if available <= 0:
		return 0
	
	# Calculate how much to transfer
	var to_transfer := mini(amount, available)
	
	# Check how much the other inventory can accept
	var other_can_accept := other_inventory.get_remaining_item_capacity(item_id)
	to_transfer = mini(to_transfer, other_can_accept)
	
	if to_transfer <= 0:
		return 0
	
	# Perform the transfer
	var removed := remove_item(item_id, to_transfer)
	var added := other_inventory.add_item(item_id, removed)
	
	# If we couldn't add all, return the difference
	if added < removed:
		add_item(item_id, removed - added)
	
	return added


## Get statistics for debugging/HUD
func get_statistics() -> Dictionary:
	"""Get inventory statistics for debugging or HUD display."""
	return {
		"total_count": _total_count,
		"unique_items": _items.size(),
		"max_total_capacity": max_total_capacity,
		"max_per_item_capacity": max_per_item_capacity,
		"remaining_capacity": get_remaining_capacity(),
		"is_full": is_full(),
		"is_empty": is_empty(),
		"items": _items.duplicate()
	}


## Logging helpers

func _log_info(message: String) -> void:
	var engine := get_node_or_null("/root/ResonanceEngine")
	if engine != null and engine.has_method("log_info"):
		engine.log_info("[Inventory] " + message)
	else:
		print("[INFO] [Inventory] " + message)


func _log_debug(message: String) -> void:
	var engine := get_node_or_null("/root/ResonanceEngine")
	if engine != null and engine.has_method("log_debug"):
		engine.log_debug("[Inventory] " + message)
	else:
		print("[DEBUG] [Inventory] " + message)
