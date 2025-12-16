## Inventory - Simple inventory management for trading
## Manages item storage with add/remove/check operations.
##
## Requirements: 30.3
extends RefCounted
class_name SurvivalInventory

## Items stored in inventory (item_type -> amount)
var items: Dictionary = {}

## Maximum number of unique item types
var max_slots: int = 100

func _init() -> void:
	pass

## Check if inventory has an item
func has_item(item_type: String, amount: int) -> bool:
	return items.get(item_type, 0) >= amount

## Add item to inventory
func add_item(item_type: String, amount: int) -> bool:
	if not items.has(item_type):
		if items.size() >= max_slots:
			return false
		items[item_type] = 0
	items[item_type] += amount
	return true

## Remove item from inventory
func remove_item(item_type: String, amount: int) -> bool:
	if not has_item(item_type, amount):
		return false
	items[item_type] -= amount
	if items[item_type] <= 0:
		items.erase(item_type)
	return true

## Get item count
func get_item_count(item_type: String) -> int:
	return items.get(item_type, 0)

## Clear all items
func clear() -> void:
	items.clear()

## Serialize inventory to dictionary
func to_dict() -> Dictionary:
	return {
		"items": items,
		"max_slots": max_slots
	}

## Deserialize inventory from dictionary
static func from_dict(data: Dictionary) -> SurvivalInventory:
	var inv := SurvivalInventory.new()
	inv.items = data.get("items", {})
	inv.max_slots = data.get("max_slots", 100)
	return inv
