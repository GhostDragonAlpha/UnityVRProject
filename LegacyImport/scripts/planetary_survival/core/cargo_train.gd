## CargoTrain - Automated train for bulk resource transport
## Travels along rail tracks between stations, loading and unloading cargo.
##
## Requirements: 34.1, 34.2, 34.3, 34.4, 34.5
## - 34.1: Travel on rail tracks
## - 34.2: Route automatically between stations
## - 34.3: Load/unload cargo at stations
## - 34.4: Respect signaling to prevent collisions
## - 34.5: Display position and cargo status
extends Node3D
class_name CargoTrain

## Emitted when train arrives at a station
signal arrived_at_station(station: RailStation)
## Emitted when train departs from a station
signal departed_from_station(station: RailStation)
## Emitted when cargo is loaded
signal cargo_loaded(resource_type: String, amount: int)
## Emitted when cargo is unloaded
signal cargo_unloaded(resource_type: String, amount: int)

enum TrainState {
	IDLE,
	TRAVELING,
	LOADING,
	UNLOADING,
	WAITING_FOR_SIGNAL
}

## Maximum speed (m/s)
@export var max_speed: float = 15.0
## Acceleration (m/s²)
@export var acceleration: float = 2.0
## Braking deceleration (m/s²)
@export var braking_deceleration: float = 4.0
## Cargo capacity (number of items)
@export var cargo_capacity: int = 100
## Loading/unloading rate (items per second)
@export var transfer_rate: float = 10.0

## Current train state
var current_state: TrainState = TrainState.IDLE
## Current track
var current_track: RailTrack = null
## Distance along current track
var track_distance: float = 0.0
## Current speed
var current_speed: float = 0.0
## Cargo inventory
var cargo: Dictionary = {}  # String -> int
## Route to destination
var route: Array[RailTrack] = []
## Current route index
var route_index: int = 0
## Destination station
var destination_station: RailStation = null
## Loading/unloading timer
var transfer_timer: float = 0.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	match current_state:
		TrainState.IDLE:
			_update_idle(delta)
		TrainState.TRAVELING:
			_update_traveling(delta)
		TrainState.LOADING:
			_update_loading(delta)
		TrainState.UNLOADING:
			_update_unloading(delta)
		TrainState.WAITING_FOR_SIGNAL:
			_update_waiting(delta)

## Set route to destination station (Requirement 34.2)
func set_route_to_station(station: RailStation) -> bool:
	if not current_track:
		return false
	
	# Find station's track
	var station_track: RailTrack = null
	for track in station.connected_tracks:
		if track:
			station_track = track
			break
	
	if not station_track:
		return false
	
	# Calculate route
	route = current_track.find_route_to(station_track)
	
	if route.is_empty():
		return false
	
	route_index = 0
	destination_station = station
	current_state = TrainState.TRAVELING
	
	return true

## Load cargo from station (Requirement 34.3)
func load_cargo_from_station(station: RailStation) -> void:
	current_state = TrainState.LOADING
	transfer_timer = 0.0

## Unload cargo to station (Requirement 34.3)
func unload_cargo_to_station(station: RailStation) -> void:
	current_state = TrainState.UNLOADING
	transfer_timer = 0.0

## Add cargo to train
func add_cargo(resource_type: String, amount: int) -> int:
	var current_total = get_total_cargo()
	var space_available = cargo_capacity - current_total
	var amount_to_add = min(amount, space_available)
	
	if amount_to_add <= 0:
		return 0
	
	if not cargo.has(resource_type):
		cargo[resource_type] = 0
	
	cargo[resource_type] += amount_to_add
	cargo_loaded.emit(resource_type, amount_to_add)
	
	return amount_to_add

## Remove cargo from train
func remove_cargo(resource_type: String, amount: int) -> int:
	if not cargo.has(resource_type):
		return 0
	
	var available = cargo[resource_type]
	var amount_to_remove = min(amount, available)
	
	cargo[resource_type] -= amount_to_remove
	
	if cargo[resource_type] <= 0:
		cargo.erase(resource_type)
	
	cargo_unloaded.emit(resource_type, amount_to_remove)
	
	return amount_to_remove

## Get total cargo count
func get_total_cargo() -> int:
	var total = 0
	for amount in cargo.values():
		total += amount
	return total

## Get cargo of specific type
func get_cargo_amount(resource_type: String) -> int:
	return cargo.get(resource_type, 0)

## Check if train has cargo space
func has_cargo_space() -> bool:
	return get_total_cargo() < cargo_capacity

## Get cargo fill percentage
func get_cargo_fill_percentage() -> float:
	return float(get_total_cargo()) / float(cargo_capacity)

## Internal: Update idle state
func _update_idle(delta: float) -> void:
	current_speed = 0.0

## Internal: Update traveling state
func _update_traveling(delta: float) -> void:
	if not current_track or route.is_empty():
		current_state = TrainState.IDLE
		return
	
	# Check signal state (Requirement 34.4)
	if current_track.signal_state == RailTrack.SignalState.RED:
		# Stop for red signal
		_brake(delta)
		if current_speed <= 0.1:
			current_state = TrainState.WAITING_FOR_SIGNAL
		return
	
	# Get speed limit
	var speed_limit = current_track.speed_limit
	
	# Accelerate or maintain speed
	if current_speed < speed_limit:
		current_speed = min(current_speed + acceleration * delta, speed_limit)
	elif current_speed > speed_limit:
		current_speed = max(current_speed - braking_deceleration * delta, speed_limit)
	
	# Move along track
	track_distance += current_speed * delta
	
	# Check if reached end of track
	var track_length = current_track.get_track_length()
	if track_distance >= track_length:
		_advance_to_next_track()
	
	# Update position
	_update_position()

## Internal: Update loading state
func _update_loading(delta: float) -> void:
	transfer_timer += delta
	
	# Check if at a station
	var station = _get_current_station()
	if not station:
		current_state = TrainState.IDLE
		return
	
	# Load cargo from station
	var items_to_load = int(transfer_rate * transfer_timer)
	if items_to_load > 0:
		transfer_timer = 0.0
		
		# Get available resources from station
		var available_resources = station.get_available_resources()
		
		for resource_type in available_resources:
			if not has_cargo_space():
				break
			
			var available = available_resources[resource_type]
			var space = cargo_capacity - get_total_cargo()
			var amount = min(items_to_load, min(available, space))
			
			if amount > 0:
				var withdrawn = station.withdraw_resource(resource_type, amount)
				add_cargo(resource_type, withdrawn)
	
	# Check if loading complete
	if not has_cargo_space() or station.get_available_resources().is_empty():
		current_state = TrainState.IDLE
		departed_from_station.emit(station)

## Internal: Update unloading state
func _update_unloading(delta: float) -> void:
	transfer_timer += delta
	
	# Check if at a station
	var station = _get_current_station()
	if not station:
		current_state = TrainState.IDLE
		return
	
	# Unload cargo to station
	var items_to_unload = int(transfer_rate * transfer_timer)
	if items_to_unload > 0:
		transfer_timer = 0.0
		
		for resource_type in cargo.keys():
			var amount = min(items_to_unload, cargo[resource_type])
			if amount > 0:
				var removed = remove_cargo(resource_type, amount)
				station.deposit_resource(resource_type, removed)
	
	# Check if unloading complete
	if cargo.is_empty():
		current_state = TrainState.IDLE
		departed_from_station.emit(station)

## Internal: Update waiting for signal state
func _update_waiting(delta: float) -> void:
	if not current_track:
		current_state = TrainState.IDLE
		return
	
	# Check if signal cleared (Requirement 34.4)
	if current_track.signal_state != RailTrack.SignalState.RED:
		current_state = TrainState.TRAVELING

## Internal: Brake
func _brake(delta: float) -> void:
	current_speed = max(0.0, current_speed - braking_deceleration * delta)

## Internal: Advance to next track in route
func _advance_to_next_track() -> void:
	# Exit current track
	if current_track:
		current_track.train_exit(self)
	
	# Move to next track
	route_index += 1
	
	if route_index >= route.size():
		# Reached destination
		_arrive_at_destination()
		return
	
	current_track = route[route_index]
	track_distance = 0.0
	
	# Enter new track
	if current_track:
		current_track.train_enter(self)

## Internal: Arrive at destination
func _arrive_at_destination() -> void:
	current_state = TrainState.IDLE
	route.clear()
	route_index = 0
	
	if destination_station:
		arrived_at_station.emit(destination_station)
		destination_station = null

## Internal: Update train position
func _update_position() -> void:
	if not current_track:
		return
	
	global_position = current_track.get_position_at_distance(track_distance)
	
	# Orient train along track
	var direction = current_track.get_direction_at_distance(track_distance)
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

## Internal: Get current station (if at one)
func _get_current_station() -> RailStation:
	if not current_track:
		return null
	
	# Check if at start or end station
	if track_distance < 2.0 and current_track.start_station:
		return current_track.start_station
	
	var track_length = current_track.get_track_length()
	if track_distance > track_length - 2.0 and current_track.end_station:
		return current_track.end_station
	
	return null

## Shutdown and cleanup
func shutdown() -> void:
	if current_track:
		current_track.train_exit(self)
	
	current_state = TrainState.IDLE
	current_track = null
	route.clear()
	cargo.clear()
	destination_station = null
