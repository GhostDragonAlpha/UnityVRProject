class_name RailTrack
extends Path3D

## Rail track for cargo train system
## Defines track path and signal states

enum SignalState {
	GREEN,
	YELLOW,
	RED
}

var signal_state: SignalState = SignalState.GREEN
var speed_limit: float = 10.0 # m/s
var start_station: Node = null
var end_station: Node = null
var occupied_trains: Array = []

func find_route_to(destination: Node) -> Array:
	# Stub - actual implementation would pathfind
	return []

func get_track_length() -> float:
	if curve:
		return curve.get_baked_length()
	return 0.0

func get_position_at_distance(distance: float) -> Vector3:
	if curve:
		return curve.sample_baked(distance)
	return Vector3.ZERO

func get_direction_at_distance(distance: float) -> Vector3:
	if curve and distance < get_track_length() - 0.1:
		var pos1 = curve.sample_baked(distance)
		var pos2 = curve.sample_baked(distance + 0.1)
		return (pos2 - pos1).normalized()
	return Vector3.FORWARD

func train_enter(train: Node) -> void:
	if not occupied_trains.has(train):
		occupied_trains.append(train)
	signal_state = SignalState.RED

func train_exit(train: Node) -> void:
	occupied_trains.erase(train)
	if occupied_trains.is_empty():
		signal_state = SignalState.GREEN
