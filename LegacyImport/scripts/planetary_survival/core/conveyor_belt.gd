## ConveyorBelt - Automated item transport system
## Requirements: 10.1, 10.2, 10.3, 10.4, 10.5
##
## Manages item transport along a belt path with capacity limits and backpressure

class_name ConveyorBelt
extends Node3D

## Emitted when an item reaches the end of the belt
signal item_delivered(item: Dictionary)

## Emitted when the belt reaches capacity
signal capacity_reached()

## Belt configuration
var start_position: Vector3 = Vector3.ZERO
var end_position: Vector3 = Vector3.ZERO
var speed: float = 2.0  # meters per second
var max_capacity: int = 10
var belt_id: int = -1

## Connected machines
var connected_input: Node = null  # Machine or belt feeding into this
var connected_output: Node = null  # Machine or belt receiving from this

## Items currently on the belt
var items_on_belt: Array[Dictionary] = []  # {item_type: String, position: float, data: Dictionary}

## Belt state
var is_active: bool = true
var is_full: bool = false


func _ready() -> void:
	_update_belt_length()


func _update_belt_length() -> float:
	return start_position.distance_to(end_position)


## Add an item to the start of the belt
## Returns true if item was added, false if belt is full
func add_item(item_type: String, item_data: Dictionary = {}) -> bool:
	if items_on_belt.size() >= max_capacity:
		is_full = true
		capacity_reached.emit()
		return false
	
	var new_item: Dictionary = {
		"item_type": item_type,
		"position": 0.0,  # Position along belt (0.0 = start, 1.0 = end)
		"data": item_data
	}
	
	items_on_belt.append(new_item)
	is_full = items_on_belt.size() >= max_capacity
	return true


## Update item positions along the belt
func update_transport(delta: float) -> void:
	if not is_active or items_on_belt.is_empty():
		return
	
	var belt_length: float = _update_belt_length()
	if belt_length <= 0.0:
		return
	
	var movement_per_second: float = speed / belt_length
	var movement: float = movement_per_second * delta
	
	# Update items from end to start to avoid collisions
	for i in range(items_on_belt.size() - 1, -1, -1):
		var item: Dictionary = items_on_belt[i]
		item.position += movement
		
		# Check if item reached the end
		if item.position >= 1.0:
			_deliver_item(item, i)


## Deliver an item that reached the end of the belt
func _deliver_item(item: Dictionary, index: int) -> void:
	# Try to deliver to connected output
	if connected_output != null:
		if connected_output.has_method("receive_item"):
			if connected_output.receive_item(item.item_type, item.data):
				items_on_belt.remove_at(index)
				is_full = false
				item_delivered.emit(item)
				return
		elif connected_output.has_method("add_item"):
			if connected_output.add_item(item.item_type, item.data):
				items_on_belt.remove_at(index)
				is_full = false
				item_delivered.emit(item)
				return
	
	# If can't deliver, keep item at end (backpressure)
	item.position = 1.0


## Connect this belt to an output (machine or another belt)
func connect_to_output(output_node: Node) -> bool:
	if output_node == null:
		return false
	
	connected_output = output_node
	return true


## Connect an input to this belt (machine or another belt)
func connect_from_input(input_node: Node) -> bool:
	if input_node == null:
		return false
	
	connected_input = input_node
	return true


## Check if belt can accept more items
func can_accept_item() -> bool:
	return items_on_belt.size() < max_capacity


## Get current item count
func get_item_count() -> int:
	return items_on_belt.size()


## Get fill percentage
func get_fill_percentage() -> float:
	return float(items_on_belt.size()) / float(max_capacity) if max_capacity > 0 else 0.0


## Clear all items from the belt
func clear_items() -> void:
	items_on_belt.clear()
	is_full = false


## Save belt state
func save_state() -> Dictionary:
	return {
		"belt_id": belt_id,
		"start_position": start_position,
		"end_position": end_position,
		"speed": speed,
		"max_capacity": max_capacity,
		"items_on_belt": items_on_belt.duplicate(true),
		"is_active": is_active
	}


## Load belt state
func load_state(data: Dictionary) -> void:
	belt_id = data.get("belt_id", -1)
	start_position = data.get("start_position", Vector3.ZERO)
	end_position = data.get("end_position", Vector3.ZERO)
	speed = data.get("speed", 2.0)
	max_capacity = data.get("max_capacity", 10)
	items_on_belt = data.get("items_on_belt", [])
	is_active = data.get("is_active", true)
	is_full = items_on_belt.size() >= max_capacity
