extends Node
## AstronomicalCoordinateSystem
##
## Manages universe-scale coordinate tracking across multiple scales:
## - Local space (meters, ±5km)
## - System space (AU, ±1000 AU)
## - Galactic space (light-years, unlimited)
##
## This system integrates with FloatingOriginSystem to handle large-scale coordinates
## while keeping the player at/near the origin for precision.
##
## Usage:
##   var astro_id = AstronomicalCoordinateSystem.register_object(node, astro_pos)
##   AstronomicalCoordinateSystem.update_position(astro_id, new_pos)
##   var local_pos = AstronomicalCoordinateSystem.au_to_local(au_pos)

## Constants for unit conversion
const METERS_PER_AU := 149_597_870_700.0
const METERS_PER_LY := 9.461e15
const AU_PER_LY := 63_241.0

## Layer thresholds (in local meters)
const LAYER_1_THRESHOLD := 5000.0       # 5km - full detail
const LAYER_2_THRESHOLD_AU := 1000.0    # 1000 AU - simplified rendering

## Layers for LOD management
enum Layer {
	LOCAL = 1,      # Full detail, full physics (< 5km)
	SYSTEM = 2,     # Simplified rendering, orbital mechanics (5km - 1000 AU)
	GALACTIC = 3    # Visual only, no physics (> 1000 AU)
}

## Registered objects with astronomical positions
## Format: { astro_id: { "node": Node3D, "astro_pos": AstroPos, "layer": Layer } }
var _objects: Dictionary = {}

## Next available astronomical ID
var _next_id: int = 1

## Player node reference
var _player: Node3D = null

## Player's astronomical position
var _player_astro_pos: AstroPos = null


func _ready() -> void:
	print("[AstronomicalCoordinateSystem] Initialized")
	print("[AstronomicalCoordinateSystem] Layer 1 threshold: %.1f km" % (LAYER_1_THRESHOLD / 1000.0))
	print("[AstronomicalCoordinateSystem] Layer 2 threshold: %.1f AU" % LAYER_2_THRESHOLD_AU)

	# Initialize player position at origin
	_player_astro_pos = AstroPos.new()
	_player_astro_pos.authoritative = AstroPos.CoordSystem.LOCAL
	_player_astro_pos.local_meters = Vector3.ZERO

	set_process(false)  # We don't need per-frame updates yet


## Set the player node
func set_player(player_node: Node3D) -> void:
	if not player_node:
		push_error("[AstronomicalCoordinateSystem] Cannot set null player")
		return

	_player = player_node
	print("[AstronomicalCoordinateSystem] Player set: %s" % player_node.name)


## Get player's astronomical position
func get_player_position() -> AstroPos:
	if not _player_astro_pos:
		_player_astro_pos = AstroPos.new()
	return _player_astro_pos


## Register a celestial object
func register_object(node: Node3D, astro_pos: AstroPos) -> int:
	if not node:
		push_error("[AstronomicalCoordinateSystem] Cannot register null node")
		return -1

	if not astro_pos:
		push_error("[AstronomicalCoordinateSystem] Cannot register with null AstroPos")
		return -1

	var astro_id := _next_id
	_next_id += 1

	# Determine initial layer
	var layer := _determine_layer(astro_pos)

	# Store object data
	_objects[astro_id] = {
		"node": node,
		"astro_pos": astro_pos.duplicate(),  # Store a copy
		"layer": layer
	}

	print("[AstronomicalCoordinateSystem] Registered object %d: %s (layer %d)" % [astro_id, node.name, layer])

	# Calculate initial local position
	_recalculate_local_position(astro_id)

	return astro_id


## Unregister an object
func unregister_object(astro_id: int) -> void:
	if not _objects.has(astro_id):
		push_warning("[AstronomicalCoordinateSystem] Cannot unregister unknown ID: %d" % astro_id)
		return

	var obj_data = _objects[astro_id]
	print("[AstronomicalCoordinateSystem] Unregistered object %d: %s" % [astro_id, obj_data.node.name])
	_objects.erase(astro_id)


## Update an object's astronomical position
func update_position(astro_id: int, new_pos: AstroPos) -> void:
	if not _objects.has(astro_id):
		push_warning("[AstronomicalCoordinateSystem] Cannot update unknown ID: %d" % astro_id)
		return

	if not new_pos:
		push_error("[AstronomicalCoordinateSystem] Cannot update with null AstroPos")
		return

	# Update stored position
	_objects[astro_id].astro_pos = new_pos.duplicate()

	# Recalculate layer
	var new_layer := _determine_layer(new_pos)
	if new_layer != _objects[astro_id].layer:
		print("[AstronomicalCoordinateSystem] Object %d changed layer: %d -> %d" % [astro_id, _objects[astro_id].layer, new_layer])
		_objects[astro_id].layer = new_layer

	# Recalculate local position
	_recalculate_local_position(astro_id)


## Convert AU position to local meters (relative to player)
func au_to_local(au_pos: Vector3) -> Vector3:
	if not _player_astro_pos:
		return au_pos * METERS_PER_AU

	# Calculate relative position in AU
	var relative_au := au_pos - _player_astro_pos.system_au

	# Convert to meters
	return relative_au * METERS_PER_AU


## Convert local meters to AU (relative to player)
func local_to_au(local_pos: Vector3) -> Vector3:
	if not _player_astro_pos:
		return local_pos / METERS_PER_AU

	# Convert to AU offset
	var au_offset := local_pos / METERS_PER_AU

	# Add to player's AU position
	return _player_astro_pos.system_au + au_offset


## Convert light-years to AU
func ly_to_au(ly_pos: Vector3) -> Vector3:
	return ly_pos * AU_PER_LY


## Convert AU to light-years
func au_to_ly(au_pos: Vector3) -> Vector3:
	return au_pos / AU_PER_LY


## Get distance between two objects in AU
func get_distance_au(astro_id_a: int, astro_id_b: int) -> float:
	if not _objects.has(astro_id_a) or not _objects.has(astro_id_b):
		push_warning("[AstronomicalCoordinateSystem] Cannot get distance for unknown IDs")
		return 0.0

	var pos_a: AstroPos = _objects[astro_id_a].astro_pos
	var pos_b: AstroPos = _objects[astro_id_b].astro_pos

	# Calculate in AU space
	var delta_au := pos_a.system_au - pos_b.system_au
	return delta_au.length()


## Get distance between two objects in light-years
func get_distance_ly(astro_id_a: int, astro_id_b: int) -> float:
	if not _objects.has(astro_id_a) or not _objects.has(astro_id_b):
		push_warning("[AstronomicalCoordinateSystem] Cannot get distance for unknown IDs")
		return 0.0

	var pos_a: AstroPos = _objects[astro_id_a].astro_pos
	var pos_b: AstroPos = _objects[astro_id_b].astro_pos

	# Calculate in light-year space
	var delta_ly := pos_a.galactic_ly - pos_b.galactic_ly
	return delta_ly.length()


## Get all objects in a specific layer
func get_objects_in_layer(layer: Layer) -> Array[int]:
	var result: Array[int] = []

	for astro_id in _objects:
		if _objects[astro_id].layer == layer:
			result.append(astro_id)

	return result


## Force update all object layers
func force_update_layers() -> void:
	print("[AstronomicalCoordinateSystem] Forcing layer update for %d objects" % _objects.size())

	for astro_id in _objects:
		var obj_data = _objects[astro_id]
		var new_layer := _determine_layer(obj_data.astro_pos)

		if new_layer != obj_data.layer:
			print("[AstronomicalCoordinateSystem] Object %d changed layer: %d -> %d" % [astro_id, obj_data.layer, new_layer])
			obj_data.layer = new_layer

		_recalculate_local_position(astro_id)


## Called by FloatingOriginSystem when universe shifts
func on_universe_shift(shift_offset: Vector3) -> void:
	print("[AstronomicalCoordinateSystem] Universe shift: %s" % shift_offset)

	# Update player's astronomical position
	_player_astro_pos.local_meters -= shift_offset

	# Convert local shift to AU shift
	var au_shift := shift_offset / METERS_PER_AU
	_player_astro_pos.system_au += au_shift

	print("[AstronomicalCoordinateSystem] Player AU position: %s" % _player_astro_pos.system_au)

	# Update all tracked objects' local positions
	var updated_count := 0
	for astro_id in _objects:
		_recalculate_local_position(astro_id)
		updated_count += 1

	print("[AstronomicalCoordinateSystem] Updated %d object positions" % updated_count)


## Get statistics for debugging
func get_stats() -> Dictionary:
	var layer_counts := {
		Layer.LOCAL: 0,
		Layer.SYSTEM: 0,
		Layer.GALACTIC: 0
	}

	for astro_id in _objects:
		var layer = _objects[astro_id].layer
		layer_counts[layer] += 1

	return {
		"total_objects": _objects.size(),
		"player_set": _player != null,
		"player_au_pos": _player_astro_pos.system_au if _player_astro_pos else Vector3.ZERO,
		"player_ly_pos": _player_astro_pos.galactic_ly if _player_astro_pos else Vector3.ZERO,
		"layer_1_count": layer_counts[Layer.LOCAL],
		"layer_2_count": layer_counts[Layer.SYSTEM],
		"layer_3_count": layer_counts[Layer.GALACTIC]
	}


## Print current status for debugging
func print_status() -> void:
	var stats := get_stats()
	print("[AstronomicalCoordinateSystem] Status:")
	print("  Total objects: %d" % stats.total_objects)
	print("  Player set: %s" % stats.player_set)
	print("  Player AU position: %s" % stats.player_au_pos)
	print("  Player LY position: %s" % stats.player_ly_pos)
	print("  Layer 1 (Local): %d objects" % stats.layer_1_count)
	print("  Layer 2 (System): %d objects" % stats.layer_2_count)
	print("  Layer 3 (Galactic): %d objects" % stats.layer_3_count)


## Determine which layer an object belongs to based on its position
func _determine_layer(astro_pos: AstroPos) -> Layer:
	# Calculate distance from player in different scales

	# First check local distance
	var local_delta := astro_pos.local_meters - _player_astro_pos.local_meters
	var local_distance := local_delta.length()

	if local_distance < LAYER_1_THRESHOLD:
		return Layer.LOCAL

	# Check AU distance
	var au_delta := astro_pos.system_au - _player_astro_pos.system_au
	var au_distance := au_delta.length()

	if au_distance < LAYER_2_THRESHOLD_AU:
		return Layer.SYSTEM

	# Otherwise, it's in galactic layer
	return Layer.GALACTIC


## Recalculate an object's local position based on its astronomical position
func _recalculate_local_position(astro_id: int) -> void:
	if not _objects.has(astro_id):
		return

	var obj_data = _objects[astro_id]
	var astro_pos: AstroPos = obj_data.astro_pos
	var node: Node3D = obj_data.node

	if not is_instance_valid(node):
		push_warning("[AstronomicalCoordinateSystem] Object %d has invalid node, skipping" % astro_id)
		return

	# Calculate local position based on authoritative coordinate system
	match astro_pos.authoritative:
		AstroPos.CoordSystem.LOCAL:
			# Local coordinates are already in local space
			# Just need to make relative to player
			var relative_local := astro_pos.local_meters - _player_astro_pos.local_meters
			node.global_position = relative_local

		AstroPos.CoordSystem.SYSTEM:
			# Convert AU to local meters relative to player
			var local_pos := au_to_local(astro_pos.system_au)
			node.global_position = local_pos

		AstroPos.CoordSystem.GALACTIC:
			# Galactic objects are typically too far for local rendering
			# They would use impostors or skybox rendering
			# For now, just mark their position symbolically
			var local_pos := au_to_local(astro_pos.system_au)
			node.global_position = local_pos
