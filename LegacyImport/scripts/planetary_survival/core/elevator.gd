## Elevator - Vertical transport system for deep mining operations
## Transports players between depth levels in vertical shafts
##
## Requirements: 28.1, 28.2, 28.3, 28.4, 28.5
extends Node3D
class_name Elevator

## Signals
signal floor_reached(floor_index: int, depth: float)
signal movement_started(from_floor: int, to_floor: int)
signal movement_stopped()
signal power_state_changed(is_powered: bool)

## Elevator state
enum State {
	IDLE,
	MOVING_UP,
	MOVING_DOWN,
	EMERGENCY_STOP
}

var current_state: State = State.IDLE
var current_floor: int = 0
var target_floor: int = 0
var current_depth: float = 0.0

## Configuration
@export var elevator_id: int = 0
@export var shaft_id: int = 0
@export var move_speed_normal: float = 5.0  # m/s when powered
@export var move_speed_unpowered: float = 1.0  # m/s when unpowered
@export var power_consumption: float = 10.0  # Power units per second
@export var max_passengers: int = 4

## Floors
var floors: Array[Dictionary] = []  # {depth: float, name: String, has_stop: bool}

## Power state
var is_powered: bool = false
var power_grid: Node

## Passengers
var passengers: Array[Node] = []

## Platform
var platform: Node3D
var platform_collision: CollisionShape3D

## UI
var floor_display: Label3D

func _ready() -> void:
	_setup_platform()
	_setup_ui()

func _setup_platform() -> void:
	"""Set up the elevator platform."""
	platform = Node3D.new()
	platform.name = "Platform"
	add_child(platform)
	
	# Add visual mesh (placeholder)
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(3.0, 0.2, 3.0)
	mesh_instance.mesh = box_mesh
	platform.add_child(mesh_instance)
	
	# Add collision for standing on platform
	var static_body = StaticBody3D.new()
	platform.add_child(static_body)
	
	platform_collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(3.0, 0.2, 3.0)
	platform_collision.shape = box_shape
	static_body.add_child(platform_collision)

func _setup_ui() -> void:
	"""Set up the floor display UI."""
	floor_display = Label3D.new()
	floor_display.name = "FloorDisplay"
	floor_display.text = "Floor 0"
	floor_display.font_size = 32
	floor_display.position = Vector3(0, 2.0, 1.6)
	platform.add_child(floor_display)

func _process(delta: float) -> void:
	match current_state:
		State.MOVING_UP:
			_move_elevator(delta, -1.0)  # Negative Y is up
		State.MOVING_DOWN:
			_move_elevator(delta, 1.0)  # Positive Y is down

func _move_elevator(delta: float, direction: float) -> void:
	"""Move the elevator in the specified direction."""
	# Determine speed based on power state
	var speed = move_speed_normal if is_powered else move_speed_unpowered
	
	# Calculate movement
	var movement = speed * delta * direction
	var new_depth = current_depth + movement
	
	# Check if we've reached target floor
	var target_depth = floors[target_floor]["depth"]
	var reached_target = false
	
	if direction < 0.0:  # Moving up
		if new_depth <= target_depth:
			new_depth = target_depth
			reached_target = true
	else:  # Moving down
		if new_depth >= target_depth:
			new_depth = target_depth
			reached_target = true
	
	# Update position
	current_depth = new_depth
	platform.position.y = -current_depth  # Negative because Y-up
	
	# Check if reached target
	if reached_target:
		_arrive_at_floor()

func _arrive_at_floor() -> void:
	"""Handle arrival at target floor."""
	current_floor = target_floor
	current_state = State.IDLE

	floor_reached.emit(current_floor, current_depth)
	movement_stopped.emit()

	_update_floor_display()

	var engine = get_node_or_null("/root/ResonanceEngine")
	if engine and engine.has_method("log_debug"):
		engine.log_debug("Elevator %d arrived at floor %d (depth: %.1fm)" % [
			elevator_id,
			current_floor,
			current_depth
		])

func _update_floor_display() -> void:
	"""Update the floor display UI."""
	if floor_display:
		var floor_name = floors[current_floor].get("name", "Floor %d" % current_floor)
		floor_display.text = "%s\n%.1fm" % [floor_name, current_depth]

## Public API

func add_floor(depth: float, floor_name: String = "", has_stop: bool = true) -> int:
	"""Add a floor to the elevator system."""
	var floor_index = floors.size()
	floors.append({
		"depth": depth,
		"name": floor_name if not floor_name.is_empty() else "Floor %d" % floor_index,
		"has_stop": has_stop
	})
	
	# Sort floors by depth
	floors.sort_custom(func(a, b): return a["depth"] < b["depth"])
	
	# Update current floor index after sorting
	_find_current_floor()
	
	return floor_index

func _find_current_floor() -> void:
	"""Find the current floor based on current depth."""
	for i in range(floors.size()):
		if abs(floors[i]["depth"] - current_depth) < 0.5:
			current_floor = i
			break

func call_elevator_to_floor(floor_index: int) -> bool:
	"""Call the elevator to a specific floor."""
	var engine = get_node_or_null("/root/ResonanceEngine")

	if floor_index < 0 or floor_index >= floors.size():
		if engine and engine.has_method("log_warning"):
			engine.log_warning("Invalid floor index: %d" % floor_index)
		return false

	if not floors[floor_index]["has_stop"]:
		if engine and engine.has_method("log_warning"):
			engine.log_warning("Floor %d has no stop" % floor_index)
		return false

	if current_state != State.IDLE:
		if engine and engine.has_method("log_warning"):
			engine.log_warning("Elevator is already moving")
		return false

	if floor_index == current_floor:
		if engine and engine.has_method("log_debug"):
			engine.log_debug("Elevator already at floor %d" % floor_index)
		return true

	# Start movement
	target_floor = floor_index

	if target_floor < current_floor:
		current_state = State.MOVING_UP
	else:
		current_state = State.MOVING_DOWN

	movement_started.emit(current_floor, target_floor)

	if engine and engine.has_method("log_debug"):
		engine.log_debug("Elevator %d moving from floor %d to floor %d" % [
			elevator_id,
			current_floor,
			target_floor
		])

	return true

func get_current_floor() -> int:
	"""Get the current floor index."""
	return current_floor

func get_current_depth() -> float:
	"""Get the current depth in meters."""
	return current_depth

func get_floor_count() -> int:
	"""Get the number of floors."""
	return floors.size()

func get_floor_info(floor_index: int) -> Dictionary:
	"""Get information about a specific floor."""
	if floor_index >= 0 and floor_index < floors.size():
		return floors[floor_index].duplicate()
	return {}

func get_available_floors() -> Array[Dictionary]:
	"""Get list of all floors with stops."""
	var available: Array[Dictionary] = []
	for i in range(floors.size()):
		if floors[i]["has_stop"]:
			var info = floors[i].duplicate()
			info["index"] = i
			available.append(info)
	return available

func is_moving() -> bool:
	"""Check if the elevator is currently moving."""
	return current_state == State.MOVING_UP or current_state == State.MOVING_DOWN

func emergency_stop() -> void:
	"""Perform an emergency stop."""
	if is_moving():
		current_state = State.EMERGENCY_STOP
		movement_stopped.emit()
		var engine = get_node_or_null("/root/ResonanceEngine")
		if engine and engine.has_method("log_warning"):
			engine.log_warning("Elevator %d emergency stop at depth %.1fm" % [
				elevator_id,
				current_depth
			])

func resume_from_emergency() -> void:
	"""Resume operation after emergency stop."""
	if current_state == State.EMERGENCY_STOP:
		current_state = State.IDLE
		_find_current_floor()
		_update_floor_display()

func set_powered(powered: bool) -> void:
	"""Set the power state of the elevator."""
	if is_powered != powered:
		is_powered = powered
		power_state_changed.emit(is_powered)

		if not is_powered and is_moving():
			var engine = get_node_or_null("/root/ResonanceEngine")
			if engine and engine.has_method("log_warning"):
				engine.log_warning("Elevator %d lost power, moving at reduced speed" % elevator_id)

func add_passenger(passenger: Node) -> bool:
	"""Add a passenger to the elevator."""
	if passengers.size() >= max_passengers:
		return false
	
	if passenger not in passengers:
		passengers.append(passenger)
	
	return true

func remove_passenger(passenger: Node) -> void:
	"""Remove a passenger from the elevator."""
	passengers.erase(passenger)

func get_passenger_count() -> int:
	"""Get the number of passengers."""
	return passengers.size()

func is_at_floor(floor_index: int) -> bool:
	"""Check if elevator is at a specific floor."""
	return current_floor == floor_index and current_state == State.IDLE

func get_time_to_floor(floor_index: int) -> float:
	"""Estimate time to reach a floor in seconds."""
	if floor_index < 0 or floor_index >= floors.size():
		return -1.0
	
	var target_depth = floors[floor_index]["depth"]
	var distance = abs(target_depth - current_depth)
	var speed = move_speed_normal if is_powered else move_speed_unpowered
	
	return distance / speed if speed > 0.0 else -1.0

func connect_to_power_grid(grid: Node) -> void:
	"""Connect the elevator to a power grid."""
	power_grid = grid
	
	if power_grid and power_grid.has_method("register_consumer"):
		power_grid.register_consumer(self, power_consumption)

func get_power_consumption() -> float:
	"""Get current power consumption."""
	if is_moving():
		return power_consumption
	return power_consumption * 0.1  # Idle consumption

func shutdown() -> void:
	"""Clean up elevator."""
	passengers.clear()
	if platform:
		platform.queue_free()
	var engine = get_node_or_null("/root/ResonanceEngine")
	if engine and engine.has_method("log_info"):
		engine.log_info("Elevator %d shutdown" % elevator_id)
