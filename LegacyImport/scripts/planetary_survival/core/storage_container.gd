## StorageContainer - Bulk resource storage with automation support
## Requirements: 18.1, 18.2, 18.3, 18.4, 18.5
##
## Provides large-scale item storage with automation connections

class_name StorageContainer
extends Node3D

## Emitted when an item is added
signal item_added(item_type: String, amount: int)

## Emitted when an item is removed
signal item_removed(item_type: String, amount: int)

## Emitted when container is destroyed
signal container_destroyed()

## Container tier configuration
enum Tier {
	SMALL = 0,    # 20 slots
	MEDIUM = 1,   # 40 slots
	LARGE = 2,    # 80 slots
	MASSIVE = 3   # 160 slots
}

## Container properties
var container_id: int = -1
var tier: Tier = Tier.SMALL
var max_slots: int = 20
var container_position: Vector3 = Vector3.ZERO
var health: float = 100.0
var max_health: float = 100.0

## Storage
var inventory: Dictionary = {}  # {item_type: String -> amount: int}
var slot_count: int = 0

## Automation connections
var automation_enabled: bool = true
var allow_deposit: bool = true
var allow_withdrawal: bool = true
var filter_items: Array[String] = []  # Empty = accept all


func _ready() -> void:
	_update_max_slots()


## Update max slots based on tier
func _update_max_slots() -> void:
	match tier:
		Tier.SMALL:
			max_slots = 20
		Tier.MEDIUM:
			max_slots = 40
		Tier.LARGE:
			max_slots = 80
		Tier.MASSIVE:
			max_slots = 160


## Add items to the container
func add_item(item_type: String, amount: int) -> bool:
	if not allow_deposit:
		return false
	
	# Check filter
	if not filter_items.is_empty() and item_type not in filter_items:
		return false
	
	# Check if we have space
	if not inventory.has(item_type):
		if slot_count >= max_slots:
			return false  # No more slots available
		slot_count += 1
	
	# Add to inventory
	if inventory.has(item_type):
		inventory[item_type] += amount
	else:
		inventory[item_type] = amount
	
	item_added.emit(item_type, amount)
	return true


## Remove items from the container
func remove_item(item_type: String, amount: int) -> int:
	if not allow_withdrawal:
		return 0
	
	if not inventory.has(item_type):
		return 0
	
	var available: int = inventory[item_type]
	var removed: int = min(amount, available)
	
	inventory[item_type] -= removed
	
	# Remove empty stacks
	if inventory[item_type] <= 0:
		inventory.erase(item_type)
		slot_count -= 1
	
	item_removed.emit(item_type, removed)
	return removed


## Check if container has specific item
func has_item(item_type: String, amount: int = 1) -> bool:
	return inventory.get(item_type, 0) >= amount


## Get amount of specific item
func get_item_count(item_type: String) -> int:
	return inventory.get(item_type, 0)


## Get all items in container
func get_all_items() -> Dictionary:
	return inventory.duplicate()


## Check if container can accept item
func can_accept_item(item_type: String) -> bool:
	if not allow_deposit:
		return false
	
	# Check filter
	if not filter_items.is_empty() and item_type not in filter_items:
		return false
	
	# Check if we have space
	if inventory.has(item_type):
		return true  # Can stack
	
	return slot_count < max_slots


## Receive item from automation (conveyor belt)
func receive_item(item_type: String, item_data: Dictionary = {}) -> bool:
	if not automation_enabled:
		return false
	
	return add_item(item_type, 1)


## Take damage
func take_damage(damage: float) -> void:
	health -= damage
	
	if health <= 0.0:
		destroy_container()


## Destroy container and drop all items
func destroy_container() -> void:
	container_destroyed.emit()
	
	# In a full implementation, this would spawn item pickups
	# For now, we just clear the inventory
	inventory.clear()
	slot_count = 0
	
	queue_free()


## Get fill percentage
func get_fill_percentage() -> float:
	return float(slot_count) / float(max_slots) if max_slots > 0 else 0.0


## Set item filter for automation
func set_filter(items: Array[String]) -> void:
	filter_items = items.duplicate()


## Clear item filter
func clear_filter() -> void:
	filter_items.clear()


## Save container state
func save_state() -> Dictionary:
	return {
		"container_id": container_id,
		"tier": tier,
		"position": container_position,
		"health": health,
		"max_health": max_health,
		"inventory": inventory.duplicate(),
		"slot_count": slot_count,
		"automation_enabled": automation_enabled,
		"allow_deposit": allow_deposit,
		"allow_withdrawal": allow_withdrawal,
		"filter_items": filter_items.duplicate()
	}


## Load container state
func load_state(data: Dictionary) -> void:
	container_id = data.get("container_id", -1)
	tier = data.get("tier", Tier.SMALL)
	container_position = data.get("position", Vector3.ZERO)
	health = data.get("health", 100.0)
	max_health = data.get("max_health", 100.0)
	inventory = data.get("inventory", {})
	slot_count = data.get("slot_count", 0)
	automation_enabled = data.get("automation_enabled", true)
	allow_deposit = data.get("allow_deposit", true)
	allow_withdrawal = data.get("allow_withdrawal", true)
	filter_items = data.get("filter_items", [])
	
	_update_max_slots()
