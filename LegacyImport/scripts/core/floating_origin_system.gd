extends Node
## FloatingOriginSystem
##
## Manages floating origin for large-scale universe without floating-point precision loss.
##
## Problem: At large distances (>10km), floating-point precision causes jitter and artifacts.
## Solution: When player moves far from origin, shift entire universe back toward origin.
##
## Integration: Notifies AstronomicalCoordinateSystem of universe shifts to maintain
## accurate astronomical positioning across local and system-scale coordinates.
##
## Usage:
##   FloatingOriginSystem.register_object(node)
##   FloatingOriginSystem.unregister_object(node)

## Threshold distance before universe shift (meters)
const SHIFT_THRESHOLD := 10000.0  # 10km

## Tracked objects that will be shifted
var _registered_objects: Array[Node3D] = []

## Current universe offset (total distance shifted)
var _universe_offset := Vector3.ZERO

## Player reference (main tracked object)
var _player: Node3D = null


func _ready() -> void:
	print("[FloatingOriginSystem] Initialized")
	print("[FloatingOriginSystem] Shift threshold: %.1f km" % (SHIFT_THRESHOLD / 1000.0))
	set_process(true)


func _process(_delta: float) -> void:
	# Check if universe shift is needed
	if _player and _should_shift():
		_perform_shift()


## Register an object to be shifted during universe shifts
func register_object(obj: Node3D) -> void:
	if not obj:
		push_error("[FloatingOriginSystem] Cannot register null object")
		return

	if obj in _registered_objects:
		push_warning("[FloatingOriginSystem] Object already registered: %s" % obj.name)
		return

	_registered_objects.append(obj)
	print("[FloatingOriginSystem] Registered: %s (total: %d)" % [obj.name, _registered_objects.size()])


## Unregister an object (usually on free)
func unregister_object(obj: Node3D) -> void:
	if not obj:
		return

	var index := _registered_objects.find(obj)
	if index >= 0:
		_registered_objects.remove_at(index)
		print("[FloatingOriginSystem] Unregistered: %s (total: %d)" % [obj.name, _registered_objects.size()])
	else:
		push_warning("[FloatingOriginSystem] Object not registered: %s" % obj.name)


## Set the player as the primary tracked object
func set_player(player: Node3D) -> void:
	if not player:
		push_error("[FloatingOriginSystem] Cannot set null player")
		return

	_player = player
	print("[FloatingOriginSystem] Player set: %s" % player.name)

	# Automatically register player
	if player not in _registered_objects:
		register_object(player)


## Get the current universe offset
func get_universe_offset() -> Vector3:
	return _universe_offset


## Get the player's true global position (including universe offset)
func get_true_global_position(obj: Node3D) -> Vector3:
	if not obj:
		return Vector3.ZERO
	return obj.global_position + _universe_offset


## Get distance from origin (for debugging)
func get_distance_from_origin() -> float:
	if not _player:
		return 0.0
	return _player.global_position.length()


## Check if universe shift should occur
func _should_shift() -> bool:
	if not _player:
		return false

	var distance := _player.global_position.length()
	return distance >= SHIFT_THRESHOLD


## Perform universe shift
func _perform_shift() -> void:
	if not _player:
		return

	# Calculate shift vector (move universe back toward origin)
	var shift_vector := -_player.global_position

	print("[FloatingOriginSystem] Performing universe shift")
	print("  Player position before: %s" % _player.global_position)
	print("  Shift vector: %s" % shift_vector)
	print("  Registered objects: %d" % _registered_objects.size())

	# Track universe offset
	_universe_offset -= shift_vector

	# Shift all registered objects
	var shifted_count := 0
	for obj in _registered_objects:
		if is_instance_valid(obj):
			obj.global_position += shift_vector
			shifted_count += 1

	print("  Player position after: %s" % _player.global_position)
	print("  Objects shifted: %d" % shifted_count)
	print("  Total universe offset: %s" % _universe_offset)
	print("  True player position: %s" % get_true_global_position(_player))

	# Notify AstronomicalCoordinateSystem of universe shift
	# This integration allows the astronomical coordinate system to update
	# all celestial object positions to maintain accurate AU/light-year tracking
	if has_node("/root/AstronomicalCoordinateSystem"):
		var astro_coords = get_node("/root/AstronomicalCoordinateSystem")
		if astro_coords.has_method("on_universe_shift"):
			astro_coords.on_universe_shift(shift_vector)
			print("  [FloatingOriginSystem] Notified AstronomicalCoordinateSystem of shift")


## Get statistics for debugging
func get_stats() -> Dictionary:
	return {
		"registered_objects": _registered_objects.size(),
		"player_set": _player != null,
		"distance_from_origin": get_distance_from_origin(),
		"universe_offset": _universe_offset,
		"shift_threshold": SHIFT_THRESHOLD,
		"will_shift_soon": _should_shift()
	}


## Print current status (for debugging)
func print_status() -> void:
	var stats := get_stats()
	print("[FloatingOriginSystem] Status:")
	print("  Registered objects: %d" % stats.registered_objects)
	print("  Player set: %s" % stats.player_set)
	print("  Distance from origin: %.2f m" % stats.distance_from_origin)
	print("  Universe offset: %s" % stats.universe_offset)
	print("  Will shift soon: %s" % stats.will_shift_soon)
