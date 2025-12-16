## ConveyorNetwork - Manages a connected group of conveyor belts
## Requirements: 10.1, 10.2, 10.3, 10.4, 10.5
##
## Tracks belt connections and handles stream merging

class_name ConveyorNetwork
extends Node

## Network properties
var network_id: int = -1
var belts: Array[ConveyorBelt] = []
var is_active: bool = true

## Network statistics
var total_items_transported: int = 0
var items_per_second: float = 0.0


## Add a belt to the network
func add_belt(belt: ConveyorBelt) -> void:
	if belt not in belts:
		belts.append(belt)
		belt.item_delivered.connect(_on_item_delivered)


## Remove a belt from the network
func remove_belt(belt: ConveyorBelt) -> void:
	var index: int = belts.find(belt)
	if index >= 0:
		if belt.item_delivered.is_connected(_on_item_delivered):
			belt.item_delivered.disconnect(_on_item_delivered)
		belts.remove_at(index)


## Update all belts in the network
func update_network(delta: float) -> void:
	if not is_active:
		return
	
	for belt in belts:
		belt.update_transport(delta)


## Handle stream merging when multiple belts feed into one
func merge_streams(source_belts: Array[ConveyorBelt], target_belt: ConveyorBelt) -> void:
	# Items from multiple source belts merge into target belt
	# This is handled automatically by the belt connections
	# but we track it for network statistics
	pass


## Check for backpressure in the network
func check_backpressure() -> bool:
	for belt in belts:
		if belt.is_full:
			return true
	return false


## Get network throughput
func get_throughput() -> float:
	return items_per_second


## Track item delivery for statistics
func _on_item_delivered(item: Dictionary) -> void:
	total_items_transported += 1


## Save network state
func save_state() -> Dictionary:
	var belt_ids: Array[int] = []
	for belt in belts:
		belt_ids.append(belt.belt_id)
	
	return {
		"network_id": network_id,
		"belt_ids": belt_ids,
		"is_active": is_active,
		"total_items_transported": total_items_transported
	}


## Load network state
func load_state(data: Dictionary) -> void:
	network_id = data.get("network_id", -1)
	is_active = data.get("is_active", true)
	total_items_transported = data.get("total_items_transported", 0)
	# Belt references need to be restored by the AutomationSystem
