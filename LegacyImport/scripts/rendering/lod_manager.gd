## LODManager - Level of Detail Management System
## Manages LOD switching for objects based on camera distance to maintain VR performance.
## Uses VisibleOnScreenNotifier3D for visibility detection and distance-based LOD switching.
##
## Requirements: 2.3 - Reduce visual complexity through automatic LOD adjustments
## Requirements: 8.1, 8.2 - Support LOD for gravity well visualization
## Requirements: 24.1 - Apply LOD reduction to maintain 90 FPS
## Requirements: 24.2 - Progressively increase surface detail on approach
## Requirements: 24.3 - Prioritize rendering resources based on angular size and distance
extends Node
class_name LODManager

## Emitted when the LOD manager is initialized
signal lod_initialized
## Emitted when an object's LOD level changes
signal lod_changed(object_id: String, old_level: int, new_level: int)
## Emitted when an object is registered
signal object_registered(object_id: String)
## Emitted when an object is unregistered
signal object_unregistered(object_id: String)
## Emitted when LOD bias changes
signal lod_bias_changed(new_bias: float)

## LOD distance thresholds (in game units)
## Objects closer than threshold[i] use LOD level i
var lod_distances: Array[float] = [100.0, 500.0, 2000.0, 10000.0]

## LOD bias multiplier (higher = higher quality at distance, lower = better performance)
var lod_bias: float = 1.0

## Registered LOD objects: {object_id: LODObjectData}
var _objects: Dictionary = {}

## Camera reference for distance calculations
var _camera: Camera3D = null

## Whether the manager is initialized
var _initialized: bool = false

## Update frequency (updates per second, 0 = every frame)
var _update_frequency: float = 30.0

## Time since last LOD update
var _time_since_update: float = 0.0

## Performance tracking
var _lod_switches_this_frame: int = 0
var _total_lod_switches: int = 0

## Maximum LOD level (0 = highest detail, higher = lower detail)
const MAX_LOD_LEVEL: int = 4

## Minimum distance to prevent division issues
const MIN_DISTANCE: float = 0.1


## Data class for tracking LOD objects
class LODObjectData:
	var object_id: String
	var root_node: Node3D
	var lod_levels: Array[Node3D]  # Array of mesh nodes for each LOD level
	var current_lod: int = 0
	var visibility_notifier: VisibleOnScreenNotifier3D = null
	var is_visible: bool = true
	var priority: float = 1.0  # Higher priority = more important to render at high detail
	var custom_distances: Array[float] = []  # Optional per-object distance overrides
	
	func _init(id: String, root: Node3D) -> void:
		object_id = id
		root_node = root
		lod_levels = []
		custom_distances = []


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if not _initialized:
		return
	
	# Throttle updates based on frequency
	if _update_frequency > 0:
		_time_since_update += delta
		if _time_since_update < 1.0 / _update_frequency:
			return
		_time_since_update = 0.0
	
	_lod_switches_this_frame = 0
	update_all_lods()


## Initialize the LOD manager
## @param camera: The camera to use for distance calculations (typically XRCamera3D)
func initialize(camera: Camera3D = null) -> bool:
	_camera = camera
	
	if _camera == null:
		# Try to find the active camera
		_camera = get_viewport().get_camera_3d()
	
	if _camera == null:
		push_warning("LODManager: No camera found, LOD calculations will be deferred")
	
	_initialized = true
	lod_initialized.emit()
	print("LODManager: Initialized with %d LOD levels" % (lod_distances.size() + 1))
	return true


## Set the camera reference
func set_camera(camera: Camera3D) -> void:
	_camera = camera


## Get the current camera
func get_camera() -> Camera3D:
	return _camera



## Register an object with multiple LOD levels
## Requirements: 24.2 - Progressively increase surface detail on approach
## @param object_id: Unique identifier for this object
## @param root_node: The root Node3D containing the object
## @param lod_levels: Array of Node3D meshes for each LOD level (index 0 = highest detail)
## @param priority: Optional priority multiplier (higher = prefer higher detail)
## @param custom_distances: Optional per-object distance thresholds
func register_object(
	object_id: String,
	root_node: Node3D,
	lod_levels: Array[Node3D],
	priority: float = 1.0,
	custom_distances: Array[float] = []
) -> bool:
	if object_id.is_empty():
		push_error("LODManager: Cannot register object with empty ID")
		return false
	
	if root_node == null:
		push_error("LODManager: Cannot register object with null root node")
		return false
	
	if lod_levels.is_empty():
		push_error("LODManager: Cannot register object with no LOD levels")
		return false
	
	# Check if already registered
	if _objects.has(object_id):
		push_warning("LODManager: Object '%s' already registered, updating" % object_id)
		unregister_object(object_id)
	
	# Create LOD object data
	var lod_data := LODObjectData.new(object_id, root_node)
	lod_data.lod_levels = lod_levels
	lod_data.priority = priority
	lod_data.custom_distances = custom_distances
	
	# Set up visibility notifier if the root node doesn't have one
	lod_data.visibility_notifier = _setup_visibility_notifier(root_node)
	
	# Initialize with highest detail (LOD 0)
	lod_data.current_lod = 0
	_apply_lod_level(lod_data, 0)
	
	_objects[object_id] = lod_data
	object_registered.emit(object_id)
	
	return true


## Set up a VisibleOnScreenNotifier3D for an object
## Requirements: 2.3 - Use VisibleOnScreenNotifier3D for LOD distance thresholds
func _setup_visibility_notifier(root_node: Node3D) -> VisibleOnScreenNotifier3D:
	# Check if one already exists
	var existing := root_node.find_child("LODVisibilityNotifier", false, false)
	if existing is VisibleOnScreenNotifier3D:
		return existing
	
	# Create new notifier
	var notifier := VisibleOnScreenNotifier3D.new()
	notifier.name = "LODVisibilityNotifier"
	
	# Set a reasonable AABB for the notifier
	# This should ideally be set based on the object's actual bounds
	notifier.aabb = AABB(Vector3(-10, -10, -10), Vector3(20, 20, 20))
	
	root_node.add_child(notifier)
	
	return notifier


## Unregister an object from LOD management
func unregister_object(object_id: String) -> bool:
	if not _objects.has(object_id):
		push_warning("LODManager: Object '%s' not found for unregistration" % object_id)
		return false
	
	var lod_data: LODObjectData = _objects[object_id]
	
	# Clean up visibility notifier if we created it
	if lod_data.visibility_notifier != null and is_instance_valid(lod_data.visibility_notifier):
		if lod_data.visibility_notifier.name == "LODVisibilityNotifier":
			lod_data.visibility_notifier.queue_free()
	
	_objects.erase(object_id)
	object_unregistered.emit(object_id)
	
	return true


## Update LOD levels for all registered objects
func update_all_lods() -> void:
	if _camera == null:
		_camera = get_viewport().get_camera_3d()
		if _camera == null:
			return
	
	# Validate camera is valid and correct type before accessing
	if not (is_instance_valid(_camera) and _camera is Camera3D):
		_camera = null
		return

	var camera_pos := _camera.global_position
	
	for object_id in _objects.keys():
		var lod_data: LODObjectData = _objects[object_id]
		_update_object_lod(lod_data, camera_pos)


## Update LOD for a single object
func _update_object_lod(lod_data: LODObjectData, camera_pos: Vector3) -> void:
	if not is_instance_valid(lod_data.root_node):
		# Object was deleted, remove from tracking
		_objects.erase(lod_data.object_id)
		return
	
	# Check visibility
	if lod_data.visibility_notifier != null and is_instance_valid(lod_data.visibility_notifier):
		lod_data.is_visible = lod_data.visibility_notifier.is_on_screen()
		
		# If not visible, use lowest LOD to save resources
		if not lod_data.is_visible:
			var lowest_lod := lod_data.lod_levels.size() - 1
			if lod_data.current_lod != lowest_lod:
				_set_lod_level(lod_data, lowest_lod)
			return
	
	# Calculate distance to camera
	var object_pos := lod_data.root_node.global_position
	var distance := camera_pos.distance_to(object_pos)
	
	# Calculate appropriate LOD level
	var new_lod := _calculate_lod_level(distance, lod_data)
	
	# Apply LOD change if needed
	if new_lod != lod_data.current_lod:
		_set_lod_level(lod_data, new_lod)


## Calculate the appropriate LOD level based on distance
## Requirements: 24.1 - Apply LOD reduction to maintain 90 FPS
## Requirements: 24.3 - Prioritize based on angular size and distance
func _calculate_lod_level(distance: float, lod_data: LODObjectData) -> int:
	# Use custom distances if provided, otherwise use global distances
	var distances := lod_data.custom_distances if not lod_data.custom_distances.is_empty() else lod_distances
	
	# Apply LOD bias and priority
	# Higher bias = use higher detail at greater distances
	# Higher priority = use higher detail for this object
	var effective_distance := distance / (lod_bias * lod_data.priority)
	effective_distance = maxf(effective_distance, MIN_DISTANCE)
	
	# Find the appropriate LOD level
	var max_lod := mini(lod_data.lod_levels.size() - 1, MAX_LOD_LEVEL)
	
	for i in range(distances.size()):
		if effective_distance < distances[i]:
			return mini(i, max_lod)
	
	# Beyond all thresholds, use lowest detail
	return max_lod


## Set the LOD level for an object
func _set_lod_level(lod_data: LODObjectData, new_level: int) -> void:
	var old_level := lod_data.current_lod
	var clamped_level := clampi(new_level, 0, lod_data.lod_levels.size() - 1)
	
	if clamped_level == old_level:
		return
	
	lod_data.current_lod = clamped_level
	_apply_lod_level(lod_data, clamped_level)
	
	_lod_switches_this_frame += 1
	_total_lod_switches += 1
	
	lod_changed.emit(lod_data.object_id, old_level, clamped_level)


## Apply the LOD level by showing/hiding appropriate meshes
func _apply_lod_level(lod_data: LODObjectData, level: int) -> void:
	for i in range(lod_data.lod_levels.size()):
		var lod_node := lod_data.lod_levels[i]
		if is_instance_valid(lod_node):
			lod_node.visible = (i == level)



## Set LOD distance thresholds
## @param distances: Array of distance thresholds (must be in ascending order)
func set_lod_distances(distances: Array[float]) -> void:
	if distances.is_empty():
		push_error("LODManager: Cannot set empty distance array")
		return
	
	# Validate ascending order
	for i in range(1, distances.size()):
		if distances[i] <= distances[i - 1]:
			push_error("LODManager: LOD distances must be in ascending order")
			return
	
	lod_distances = distances
	print("LODManager: LOD distances updated to %s" % str(distances))


## Get the current LOD distance thresholds
func get_lod_distances() -> Array[float]:
	return lod_distances


## Set LOD bias for quality vs performance tradeoff
## Requirements: 2.3 - Add LOD bias controls for quality settings
## @param bias: Multiplier for LOD distances (>1 = higher quality, <1 = better performance)
func set_lod_bias(bias: float) -> void:
	var old_bias := lod_bias
	lod_bias = clampf(bias, 0.1, 10.0)
	
	if lod_bias != old_bias:
		lod_bias_changed.emit(lod_bias)
		print("LODManager: LOD bias changed from %.2f to %.2f" % [old_bias, lod_bias])


## Get the current LOD bias
func get_lod_bias() -> float:
	return lod_bias


## Set the update frequency (updates per second)
## @param frequency: Updates per second (0 = every frame)
func set_update_frequency(frequency: float) -> void:
	_update_frequency = maxf(frequency, 0.0)


## Get the update frequency
func get_update_frequency() -> float:
	return _update_frequency


## Force update LOD for a specific object
func update_object_lod(object_id: String) -> void:
	if not _objects.has(object_id):
		push_warning("LODManager: Object '%s' not found" % object_id)
		return
	
	if _camera == null:
		_camera = get_viewport().get_camera_3d()
		if _camera == null:
			return
	
	
	# Validate camera is valid and correct type before accessing
	if not (is_instance_valid(_camera) and _camera is Camera3D):
		_camera = null
		return
	var lod_data: LODObjectData = _objects[object_id]
	_update_object_lod(lod_data, _camera.global_position)


## Get the current LOD level for an object
func get_object_lod(object_id: String) -> int:
	if not _objects.has(object_id):
		return -1
	
	var lod_data: LODObjectData = _objects[object_id]
	return lod_data.current_lod


## Get the number of LOD levels for an object
func get_object_lod_count(object_id: String) -> int:
	if not _objects.has(object_id):
		return 0
	
	var lod_data: LODObjectData = _objects[object_id]
	return lod_data.lod_levels.size()


## Check if an object is registered
func has_object(object_id: String) -> bool:
	return _objects.has(object_id)


## Get the number of registered objects
func get_object_count() -> int:
	return _objects.size()


## Get all registered object IDs
func get_registered_objects() -> Array[String]:
	var ids: Array[String] = []
	for key in _objects.keys():
		ids.append(key)
	return ids


## Set priority for an object (affects LOD selection)
## Requirements: 24.3 - Prioritize rendering resources based on angular size and distance
func set_object_priority(object_id: String, priority: float) -> void:
	if not _objects.has(object_id):
		push_warning("LODManager: Object '%s' not found" % object_id)
		return
	
	var lod_data: LODObjectData = _objects[object_id]
	lod_data.priority = maxf(priority, 0.1)


## Get priority for an object
func get_object_priority(object_id: String) -> float:
	if not _objects.has(object_id):
		return 1.0
	
	var lod_data: LODObjectData = _objects[object_id]
	return lod_data.priority


## Set custom distance thresholds for a specific object
func set_object_distances(object_id: String, distances: Array[float]) -> void:
	if not _objects.has(object_id):
		push_warning("LODManager: Object '%s' not found" % object_id)
		return
	
	var lod_data: LODObjectData = _objects[object_id]
	lod_data.custom_distances = distances


## Clear custom distances for an object (use global distances)
func clear_object_distances(object_id: String) -> void:
	if not _objects.has(object_id):
		return
	
	var lod_data: LODObjectData = _objects[object_id]
	lod_data.custom_distances = []


## Update the visibility notifier AABB for an object
func set_object_bounds(object_id: String, aabb: AABB) -> void:
	if not _objects.has(object_id):
		push_warning("LODManager: Object '%s' not found" % object_id)
		return
	
	var lod_data: LODObjectData = _objects[object_id]
	if lod_data.visibility_notifier != null and is_instance_valid(lod_data.visibility_notifier):
		lod_data.visibility_notifier.aabb = aabb


## Check if an object is currently visible on screen
func is_object_visible(object_id: String) -> bool:
	if not _objects.has(object_id):
		return false
	
	var lod_data: LODObjectData = _objects[object_id]
	return lod_data.is_visible


## Force all objects to a specific LOD level (useful for debugging or screenshots)
func force_all_lod(level: int) -> void:
	for object_id in _objects.keys():
		var lod_data: LODObjectData = _objects[object_id]
		var clamped_level := clampi(level, 0, lod_data.lod_levels.size() - 1)
		_apply_lod_level(lod_data, clamped_level)
		lod_data.current_lod = clamped_level


## Reset all objects to automatic LOD management
func reset_all_lod() -> void:
	update_all_lods()


## Get statistics about LOD management
func get_statistics() -> Dictionary:
	var lod_distribution := {}
	var visible_count := 0
	
	for object_id in _objects.keys():
		var lod_data: LODObjectData = _objects[object_id]
		var lod_key := "lod_%d" % lod_data.current_lod
		lod_distribution[lod_key] = lod_distribution.get(lod_key, 0) + 1
		if lod_data.is_visible:
			visible_count += 1
	
	return {
		"initialized": _initialized,
		"total_objects": _objects.size(),
		"visible_objects": visible_count,
		"lod_distances": lod_distances,
		"lod_bias": lod_bias,
		"update_frequency": _update_frequency,
		"lod_distribution": lod_distribution,
		"switches_this_frame": _lod_switches_this_frame,
		"total_switches": _total_lod_switches
	}


## Check if the manager is initialized
func is_initialized() -> bool:
	return _initialized


## Shutdown and cleanup
func shutdown() -> void:
	# Unregister all objects
	var object_ids := get_registered_objects()
	for object_id in object_ids:
		unregister_object(object_id)
	
	_objects.clear()
	_camera = null
	_initialized = false
	
	print("LODManager: Shutdown complete")


## Helper function to create LOD levels from a single mesh with different detail levels
## This is a convenience function for procedurally generating LOD meshes
## @param base_mesh: The high-detail mesh to create LODs from
## @param reduction_factors: Array of vertex reduction factors for each LOD level
## @return: Array of MeshInstance3D nodes with reduced detail
static func create_lod_meshes_from_base(
	base_mesh: Mesh,
	reduction_factors: Array[float] = [1.0, 0.5, 0.25, 0.1]
) -> Array[MeshInstance3D]:
	var lod_meshes: Array[MeshInstance3D] = []
	
	for i in range(reduction_factors.size()):
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "LOD_%d" % i
		
		if i == 0:
			# LOD 0 uses the original mesh
			mesh_instance.mesh = base_mesh
		else:
			# For other LODs, we would ideally use mesh simplification
			# Since Godot doesn't have built-in mesh simplification,
			# we use the same mesh but could apply different materials
			# or use pre-generated LOD meshes
			mesh_instance.mesh = base_mesh
		
		lod_meshes.append(mesh_instance)
	
	return lod_meshes


## Helper function to register a node that has child nodes named LOD_0, LOD_1, etc.
## @param object_id: Unique identifier for this object
## @param root_node: The root Node3D containing LOD child nodes
## @param priority: Optional priority multiplier
## @return: true if registration was successful
func register_object_auto(object_id: String, root_node: Node3D, priority: float = 1.0) -> bool:
	if root_node == null:
		push_error("LODManager: Cannot register null root node")
		return false
	
	# Find LOD child nodes
	var lod_levels: Array[Node3D] = []
	var lod_index := 0
	
	while true:
		var lod_name := "LOD_%d" % lod_index
		var lod_node := root_node.find_child(lod_name, false, false)
		
		if lod_node == null:
			# Also try without underscore
			lod_name = "LOD%d" % lod_index
			lod_node = root_node.find_child(lod_name, false, false)
		
		if lod_node is Node3D:
			lod_levels.append(lod_node)
			lod_index += 1
		else:
			break
	
	if lod_levels.is_empty():
		push_error("LODManager: No LOD child nodes found in '%s'" % root_node.name)
		return false
	
	return register_object(object_id, root_node, lod_levels, priority)
