## QuantumRender - Quantum Observation Mechanics System
## Implements quantum-inspired rendering where unobserved objects appear as probability clouds
## and collapse to solid meshes when observed by the player.
##
## Requirements: 28.1 - Detect objects outside view frustum using VisibleOnScreenNotifier3D
## Requirements: 28.2 - Render unobserved objects as probability clouds using GPUParticles3D
## Requirements: 28.3 - Collapse to solid mesh when observed
## Requirements: 28.4 - Use particle systems for clouds
## Requirements: 28.5 - Simplify collision for unobserved objects
extends Node
class_name QuantumRender

## Emitted when the quantum render system is initialized
signal quantum_initialized
## Emitted when an object transitions from observed to unobserved
signal object_decoherence(object_id: String)
## Emitted when an object transitions from unobserved to observed
signal object_collapse(object_id: String)
## Emitted when an object is registered
signal object_registered(object_id: String)
## Emitted when an object is unregistered
signal object_unregistered(object_id: String)

## Collapse transition duration (seconds)
const COLLAPSE_DURATION: float = 0.1

## Minimum distance for collision simplification
const MIN_COLLISION_DISTANCE: float = 0.1

## Particle count for probability clouds
const CLOUD_PARTICLE_COUNT: int = 1000

## Particle lifetime for clouds
const CLOUD_PARTICLE_LIFETIME: float = 2.0

## Registered quantum objects: {object_id: QuantumObjectData}
var _objects: Dictionary = {}

## Camera reference for frustum culling
var _camera: Camera3D = null

## Whether the system is initialized
var _initialized: bool = false

## Update frequency (updates per second, 0 = every frame)
var _update_frequency: float = 60.0

## Time since last update
var _time_since_update: float = 0.0

## Performance tracking
var _collapses_this_frame: int = 0
var _decoherences_this_frame: int = 0
var _total_collapses: int = 0
var _total_decoherences: int = 0


## Quantum state enum
enum QuantumState {
	OBSERVED,        # Solid mesh, full collision
	UNOBSERVED,      # Probability cloud, simplified collision
	COLLAPSING,      # Transitioning from unobserved to observed
	DECOHERING       # Transitioning from observed to unobserved
}


## Data class for tracking quantum objects
class QuantumObjectData:
	var object_id: String
	var root_node: Node3D
	var solid_mesh: Node3D  # The actual mesh when observed
	var particle_cloud: GPUParticles3D  # Probability cloud when unobserved
	var visibility_notifier: VisibleOnScreenNotifier3D
	var collision_shape: CollisionShape3D  # Original collision shape
	var simplified_collision: CollisionShape3D  # Simplified collision for unobserved state
	var current_state: QuantumState = QuantumState.OBSERVED
	var transition_progress: float = 0.0  # 0.0 to 1.0 for transitions
	var is_on_screen: bool = true
	
	func _init(id: String, root: Node3D) -> void:
		object_id = id
		root_node = root


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
	
	_collapses_this_frame = 0
	_decoherences_this_frame = 0
	
	update_all_quantum_states(delta)


## Initialize the quantum render system
## Requirements: 28.1 - Detect objects outside view frustum
## @param camera: The camera to use for frustum culling (typically XRCamera3D)
func initialize(camera: Camera3D = null) -> bool:
	_camera = camera
	
	if _camera == null:
		# Try to find the active camera
		_camera = get_viewport().get_camera_3d()
	
	if _camera == null:
		push_warning("QuantumRender: No camera found, quantum state detection will be deferred")
	
	_initialized = true
	quantum_initialized.emit()
	print("QuantumRender: Initialized quantum observation mechanics")
	return true


## Set the camera reference
func set_camera(camera: Camera3D) -> void:
	_camera = camera


## Get the current camera
func get_camera() -> Camera3D:
	return _camera


## Register an object for quantum rendering
## Requirements: 28.2 - Render unobserved objects as probability clouds
## Requirements: 28.4 - Use particle systems for clouds
## @param object_id: Unique identifier for this object
## @param root_node: The root Node3D containing the object
## @param solid_mesh: The mesh to show when observed
## @param collision_shape: Optional collision shape to simplify when unobserved
func register_object(
	object_id: String,
	root_node: Node3D,
	solid_mesh: Node3D,
	collision_shape: CollisionShape3D = null
) -> bool:
	if object_id.is_empty():
		push_error("QuantumRender: Cannot register object with empty ID")
		return false
	
	if root_node == null:
		push_error("QuantumRender: Cannot register object with null root node")
		return false
	
	if solid_mesh == null:
		push_error("QuantumRender: Cannot register object with null solid mesh")
		return false
	
	# Check if already registered
	if _objects.has(object_id):
		push_warning("QuantumRender: Object '%s' already registered, updating" % object_id)
		unregister_object(object_id)
	
	# Create quantum object data
	var quantum_data := QuantumObjectData.new(object_id, root_node)
	quantum_data.solid_mesh = solid_mesh
	quantum_data.collision_shape = collision_shape
	
	# Set up visibility notifier
	quantum_data.visibility_notifier = _setup_visibility_notifier(root_node)
	
	# Create probability cloud
	quantum_data.particle_cloud = _create_probability_cloud(root_node, solid_mesh)
	
	# Create simplified collision if original collision exists
	if collision_shape != null:
		quantum_data.simplified_collision = _create_simplified_collision(collision_shape)
	
	# Initialize in observed state (solid mesh visible)
	quantum_data.current_state = QuantumState.OBSERVED
	quantum_data.solid_mesh.visible = true
	quantum_data.particle_cloud.visible = false
	quantum_data.particle_cloud.emitting = false
	
	_objects[object_id] = quantum_data
	object_registered.emit(object_id)
	
	print("QuantumRender: Registered object '%s' for quantum rendering" % object_id)
	return true


## Set up a VisibleOnScreenNotifier3D for an object
## Requirements: 28.1 - Detect objects outside view frustum using VisibleOnScreenNotifier3D
func _setup_visibility_notifier(root_node: Node3D) -> VisibleOnScreenNotifier3D:
	# Check if one already exists
	var existing := root_node.find_child("QuantumVisibilityNotifier", false, false)
	if existing is VisibleOnScreenNotifier3D:
		return existing
	
	# Create new notifier
	var notifier := VisibleOnScreenNotifier3D.new()
	notifier.name = "QuantumVisibilityNotifier"
	
	# Set a reasonable AABB for the notifier
	# This should ideally be set based on the object's actual bounds
	notifier.aabb = AABB(Vector3(-10, -10, -10), Vector3(20, 20, 20))
	
	root_node.add_child(notifier)
	
	# Connect signals
	notifier.screen_entered.connect(_on_object_screen_entered.bind(root_node))
	notifier.screen_exited.connect(_on_object_screen_exited.bind(root_node))
	
	return notifier


## Create a probability cloud particle system for an object
## Requirements: 28.2 - Render unobserved objects as probability clouds using GPUParticles3D
## Requirements: 28.4 - Use particle systems for clouds
func _create_probability_cloud(root_node: Node3D, solid_mesh: Node3D) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = "ProbabilityCloud"
	particles.amount = CLOUD_PARTICLE_COUNT
	particles.lifetime = CLOUD_PARTICLE_LIFETIME
	particles.explosiveness = 0.0
	particles.randomness = 0.5
	particles.fixed_fps = 30
	particles.visibility_aabb = AABB(Vector3(-20, -20, -20), Vector3(40, 40, 40))
	
	# Create particle material
	var particle_material := ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	
	# Get mesh bounds for emission volume
	var mesh_bounds := _get_mesh_bounds(solid_mesh)
	particle_material.emission_box_extents = mesh_bounds.size * 0.5
	
	# Particle behavior
	particle_material.direction = Vector3(0, 0, 0)
	particle_material.spread = 180.0
	particle_material.initial_velocity_min = 0.1
	particle_material.initial_velocity_max = 0.5
	particle_material.gravity = Vector3.ZERO
	particle_material.damping_min = 0.5
	particle_material.damping_max = 1.0
	
	# Particle appearance
	particle_material.scale_min = 0.05
	particle_material.scale_max = 0.15
	
	particles.process_material = particle_material
	
	# Create draw pass material (glowing particles)
	var draw_material := StandardMaterial3D.new()
	draw_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_material.vertex_color_use_as_albedo = true
	draw_material.albedo_color = Color(0.5, 0.8, 1.0, 0.6)  # Cyan/blue quantum color
	draw_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	
	# Create simple sphere mesh for particles
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radial_segments = 8
	sphere_mesh.rings = 4
	sphere_mesh.radius = 0.1
	sphere_mesh.height = 0.2
	sphere_mesh.material = draw_material
	
	particles.draw_pass_1 = sphere_mesh
	
	# Initially not visible
	particles.visible = false
	particles.emitting = false
	
	root_node.add_child(particles)
	
	return particles


## Get the bounding box of a mesh
func _get_mesh_bounds(mesh_node: Node3D) -> AABB:
	if mesh_node is MeshInstance3D:
		var mesh_instance := mesh_node as MeshInstance3D
		if mesh_instance.mesh != null:
			return mesh_instance.mesh.get_aabb()
	
	# Default bounds if we can't get mesh AABB
	return AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))


## Create a simplified collision shape for unobserved state
## Requirements: 28.5 - Simplify collision for unobserved objects
func _create_simplified_collision(original_collision: CollisionShape3D) -> CollisionShape3D:
	var simplified := CollisionShape3D.new()
	simplified.name = "SimplifiedCollision"
	
	# Create a simple sphere collision based on the original shape
	var sphere_shape := SphereShape3D.new()
	
	# Estimate radius from original shape
	if original_collision.shape is BoxShape3D:
		var box := original_collision.shape as BoxShape3D
		sphere_shape.radius = box.size.length() * 0.5
	elif original_collision.shape is SphereShape3D:
		var sphere := original_collision.shape as SphereShape3D
		sphere_shape.radius = sphere.radius
	elif original_collision.shape is CapsuleShape3D:
		var capsule := original_collision.shape as CapsuleShape3D
		sphere_shape.radius = maxf(capsule.radius, capsule.height * 0.5)
	else:
		# Default radius
		sphere_shape.radius = 1.0
	
	simplified.shape = sphere_shape
	simplified.disabled = true  # Start disabled
	
	# Add to the same parent as original
	if original_collision.get_parent() != null:
		original_collision.get_parent().add_child(simplified)
	
	return simplified


## Unregister an object from quantum rendering
func unregister_object(object_id: String) -> bool:
	if not _objects.has(object_id):
		push_warning("QuantumRender: Object '%s' not found for unregistration" % object_id)
		return false
	
	var quantum_data: QuantumObjectData = _objects[object_id]
	
	# Clean up created nodes
	if quantum_data.visibility_notifier != null and is_instance_valid(quantum_data.visibility_notifier):
		if quantum_data.visibility_notifier.name == "QuantumVisibilityNotifier":
			quantum_data.visibility_notifier.queue_free()
	
	if quantum_data.particle_cloud != null and is_instance_valid(quantum_data.particle_cloud):
		quantum_data.particle_cloud.queue_free()
	
	if quantum_data.simplified_collision != null and is_instance_valid(quantum_data.simplified_collision):
		quantum_data.simplified_collision.queue_free()
	
	_objects.erase(object_id)
	object_unregistered.emit(object_id)
	
	return true


## Update quantum states for all registered objects
func update_all_quantum_states(delta: float) -> void:
	for object_id in _objects.keys():
		var quantum_data: QuantumObjectData = _objects[object_id]
		_update_object_quantum_state(quantum_data, delta)


## Update quantum state for a single object
## Requirements: 28.3 - Collapse to solid mesh when observed
func _update_object_quantum_state(quantum_data: QuantumObjectData, delta: float) -> void:
	if not is_instance_valid(quantum_data.root_node):
		# Object was deleted, remove from tracking
		_objects.erase(quantum_data.object_id)
		return
	
	# Check visibility
	if quantum_data.visibility_notifier != null and is_instance_valid(quantum_data.visibility_notifier):
		quantum_data.is_on_screen = quantum_data.visibility_notifier.is_on_screen()
	
	# Update state based on visibility
	match quantum_data.current_state:
		QuantumState.OBSERVED:
			if not quantum_data.is_on_screen:
				# Start decoherence (observed -> unobserved)
				_start_decoherence(quantum_data)
		
		QuantumState.UNOBSERVED:
			if quantum_data.is_on_screen:
				# Start collapse (unobserved -> observed)
				_start_collapse(quantum_data)
		
		QuantumState.COLLAPSING:
			_update_collapse_transition(quantum_data, delta)
		
		QuantumState.DECOHERING:
			_update_decoherence_transition(quantum_data, delta)


## Start the collapse transition (unobserved -> observed)
## Requirements: 28.3 - Collapse to solid mesh when observed within 0.1 seconds
func _start_collapse(quantum_data: QuantumObjectData) -> void:
	quantum_data.current_state = QuantumState.COLLAPSING
	quantum_data.transition_progress = 0.0
	
	# Start showing solid mesh
	quantum_data.solid_mesh.visible = true
	
	_collapses_this_frame += 1
	_total_collapses += 1
	
	print("QuantumRender: Object '%s' collapsing to observed state" % quantum_data.object_id)


## Update the collapse transition
func _update_collapse_transition(quantum_data: QuantumObjectData, delta: float) -> void:
	quantum_data.transition_progress += delta / COLLAPSE_DURATION
	
	if quantum_data.transition_progress >= 1.0:
		# Transition complete
		quantum_data.current_state = QuantumState.OBSERVED
		quantum_data.transition_progress = 1.0
		
		# Ensure solid mesh is visible, cloud is hidden
		quantum_data.solid_mesh.visible = true
		quantum_data.particle_cloud.visible = false
		quantum_data.particle_cloud.emitting = false
		
		# Restore full collision
		if quantum_data.collision_shape != null and is_instance_valid(quantum_data.collision_shape):
			quantum_data.collision_shape.disabled = false
		if quantum_data.simplified_collision != null and is_instance_valid(quantum_data.simplified_collision):
			quantum_data.simplified_collision.disabled = true
		
		object_collapse.emit(quantum_data.object_id)
		print("QuantumRender: Object '%s' collapsed to observed state" % quantum_data.object_id)
	else:
		# Interpolate between states
		var alpha := quantum_data.transition_progress
		
		# Fade in solid mesh
		if quantum_data.solid_mesh is MeshInstance3D:
			var mesh_instance := quantum_data.solid_mesh as MeshInstance3D
			if mesh_instance.get_surface_override_material_count() > 0:
				var mat := mesh_instance.get_surface_override_material(0)
				if mat is StandardMaterial3D:
					var std_mat := mat as StandardMaterial3D
					std_mat.albedo_color.a = alpha
		
		# Fade out particle cloud
		quantum_data.particle_cloud.amount_ratio = 1.0 - alpha


## Start the decoherence transition (observed -> unobserved)
func _start_decoherence(quantum_data: QuantumObjectData) -> void:
	quantum_data.current_state = QuantumState.DECOHERING
	quantum_data.transition_progress = 0.0
	
	# Start showing particle cloud
	quantum_data.particle_cloud.visible = true
	quantum_data.particle_cloud.emitting = true
	
	_decoherences_this_frame += 1
	_total_decoherences += 1
	
	print("QuantumRender: Object '%s' decohering to unobserved state" % quantum_data.object_id)


## Update the decoherence transition
func _update_decoherence_transition(quantum_data: QuantumObjectData, delta: float) -> void:
	quantum_data.transition_progress += delta / COLLAPSE_DURATION
	
	if quantum_data.transition_progress >= 1.0:
		# Transition complete
		quantum_data.current_state = QuantumState.UNOBSERVED
		quantum_data.transition_progress = 1.0
		
		# Ensure cloud is visible, solid mesh is hidden
		quantum_data.solid_mesh.visible = false
		quantum_data.particle_cloud.visible = true
		quantum_data.particle_cloud.emitting = true
		
		# Switch to simplified collision
		if quantum_data.collision_shape != null and is_instance_valid(quantum_data.collision_shape):
			quantum_data.collision_shape.disabled = true
		if quantum_data.simplified_collision != null and is_instance_valid(quantum_data.simplified_collision):
			quantum_data.simplified_collision.disabled = false
		
		object_decoherence.emit(quantum_data.object_id)
		print("QuantumRender: Object '%s' decohered to unobserved state" % quantum_data.object_id)
	else:
		# Interpolate between states
		var alpha := quantum_data.transition_progress
		
		# Fade out solid mesh
		if quantum_data.solid_mesh is MeshInstance3D:
			var mesh_instance := quantum_data.solid_mesh as MeshInstance3D
			if mesh_instance.get_surface_override_material_count() > 0:
				var mat := mesh_instance.get_surface_override_material(0)
				if mat is StandardMaterial3D:
					var std_mat := mat as StandardMaterial3D
					std_mat.albedo_color.a = 1.0 - alpha
		
		# Fade in particle cloud
		quantum_data.particle_cloud.amount_ratio = alpha


## Signal handler for object entering screen
func _on_object_screen_entered(root_node: Node3D) -> void:
	# Find the object by root node
	for object_id in _objects.keys():
		var quantum_data: QuantumObjectData = _objects[object_id]
		if quantum_data.root_node == root_node:
			quantum_data.is_on_screen = true
			break


## Signal handler for object exiting screen
func _on_object_screen_exited(root_node: Node3D) -> void:
	# Find the object by root node
	for object_id in _objects.keys():
		var quantum_data: QuantumObjectData = _objects[object_id]
		if quantum_data.root_node == root_node:
			quantum_data.is_on_screen = false
			break


## Set the update frequency (updates per second)
## @param frequency: Updates per second (0 = every frame)
func set_update_frequency(frequency: float) -> void:
	_update_frequency = maxf(frequency, 0.0)


## Get the update frequency
func get_update_frequency() -> float:
	return _update_frequency


## Force an object to observed state
func force_observe(object_id: String) -> void:
	if not _objects.has(object_id):
		push_warning("QuantumRender: Object '%s' not found" % object_id)
		return
	
	var quantum_data: QuantumObjectData = _objects[object_id]
	quantum_data.current_state = QuantumState.OBSERVED
	quantum_data.solid_mesh.visible = true
	quantum_data.particle_cloud.visible = false
	quantum_data.particle_cloud.emitting = false


## Force an object to unobserved state
func force_unobserve(object_id: String) -> void:
	if not _objects.has(object_id):
		push_warning("QuantumRender: Object '%s' not found" % object_id)
		return
	
	var quantum_data: QuantumObjectData = _objects[object_id]
	quantum_data.current_state = QuantumState.UNOBSERVED
	quantum_data.solid_mesh.visible = false
	quantum_data.particle_cloud.visible = true
	quantum_data.particle_cloud.emitting = true


## Get the current quantum state of an object
func get_object_state(object_id: String) -> QuantumState:
	if not _objects.has(object_id):
		return QuantumState.OBSERVED  # Default
	
	var quantum_data: QuantumObjectData = _objects[object_id]
	return quantum_data.current_state


## Check if an object is currently observed
func is_object_observed(object_id: String) -> bool:
	if not _objects.has(object_id):
		return true  # Default to observed
	
	var quantum_data: QuantumObjectData = _objects[object_id]
	return quantum_data.current_state == QuantumState.OBSERVED or quantum_data.current_state == QuantumState.COLLAPSING


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


## Update the visibility notifier AABB for an object
func set_object_bounds(object_id: String, aabb: AABB) -> void:
	if not _objects.has(object_id):
		push_warning("QuantumRender: Object '%s' not found" % object_id)
		return
	
	var quantum_data: QuantumObjectData = _objects[object_id]
	if quantum_data.visibility_notifier != null and is_instance_valid(quantum_data.visibility_notifier):
		quantum_data.visibility_notifier.aabb = aabb
	if quantum_data.particle_cloud != null and is_instance_valid(quantum_data.particle_cloud):
		quantum_data.particle_cloud.visibility_aabb = aabb


## Get statistics about quantum rendering
func get_statistics() -> Dictionary:
	var state_distribution := {}
	var observed_count := 0
	var unobserved_count := 0
	
	for object_id in _objects.keys():
		var quantum_data: QuantumObjectData = _objects[object_id]
		var state_name = QuantumState.keys()[quantum_data.current_state]
		state_distribution[state_name] = state_distribution.get(state_name, 0) + 1
		
		if quantum_data.current_state == QuantumState.OBSERVED or quantum_data.current_state == QuantumState.COLLAPSING:
			observed_count += 1
		else:
			unobserved_count += 1
	
	return {
		"initialized": _initialized,
		"total_objects": _objects.size(),
		"observed_objects": observed_count,
		"unobserved_objects": unobserved_count,
		"update_frequency": _update_frequency,
		"state_distribution": state_distribution,
		"collapses_this_frame": _collapses_this_frame,
		"decoherences_this_frame": _decoherences_this_frame,
		"total_collapses": _total_collapses,
		"total_decoherences": _total_decoherences
	}


## Check if the system is initialized
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
	
	print("QuantumRender: Shutdown complete")
