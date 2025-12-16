class_name RailStation
extends Node3D

## Rail station for cargo loading/unloading
## Manages resource storage and train operations

var station_id: String = ""
var connected_tracks: Array = []
var stored_resources: Dictionary = {} # {resource_type: quantity}
var loading_speed: float = 5.0 # units per second

func _ready():
	station_id = str(get_instance_id())

func connect_track(track: RailTrack) -> void:
	if not connected_tracks.has(track):
		connected_tracks.append(track)

func get_available_resources() -> Dictionary:
	return stored_resources.duplicate()

func withdraw_resource(resource_type: String, amount: float) -> float:
	if not stored_resources.has(resource_type):
		return 0.0

	var available = stored_resources[resource_type]
	var withdrawn = min(available, amount)
	stored_resources[resource_type] -= withdrawn

	if stored_resources[resource_type] <= 0.0:
		stored_resources.erase(resource_type)

	return withdrawn

func deposit_resource(resource_type: String, amount: float) -> void:
	if stored_resources.has(resource_type):
		stored_resources[resource_type] += amount
	else:
		stored_resources[resource_type] = amount
