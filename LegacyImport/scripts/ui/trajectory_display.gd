## TrajectoryDisplay - Trajectory Prediction Visualization
## Calculates and displays predicted spacecraft trajectory paths accounting for
## gravitational influences, with real-time updates and gravity well intersection highlighting.
##
## Requirements: 40.1, 40.2, 40.3, 40.4, 40.5
## - 40.1: Calculate and display projected path when activated
## - 40.2: Account for all gravitational influences along the path
## - 40.3: Render trajectory as colored line with time markers
## - 40.4: Highlight gravity well intersections
## - 40.5: Update trajectory prediction in real-time with input changes
extends Node3D
class_name TrajectoryDisplay

# Preload custom classes for type references
const Spacecraft = preload("res://scripts/player/spacecraft.gd")
const CelestialBody = preload("res://scripts/celestial/celestial_body.gd")
## Emitted when trajectory calculation completes
signal trajectory_calculated(points: Array[Vector3])
## Emitted when gravity well intersection is detected
signal gravity_well_intersection_detected(body: CelestialBody, position: Vector3)

#region Exported Properties

## Enable trajectory display
@export var enabled: bool = false

## Prediction duration (seconds of simulated time)
@export var prediction_duration: float = 3600.0  # 1 hour default

## Number of trajectory points to calculate
@export var trajectory_steps: int = 100

## Update frequency (Hz) for real-time updates
@export var update_frequency: float = 10.0

## Line width for trajectory rendering
@export var line_width: float = 0.05

## Base trajectory color
@export var trajectory_color: Color = Color(0.3, 0.8, 1.0, 0.8)

## Gravity well intersection color
@export var intersection_color: Color = Color(1.0, 0.3, 0.2, 1.0)

## Time marker interval (seconds)
@export var time_marker_interval: float = 600.0  # 10 minutes

## Time marker size
@export var time_marker_size: float = 0.1

## Gravity well detection radius multiplier
@export var gravity_well_threshold: float = 2.0  # Detect within 2x body radius

## Enable emissive trajectory line
@export var enable_emissive: bool = true

## Emission intensity
@export var emission_intensity: float = 1.5

#endregion

#region Runtime Properties

## Spacecraft reference
var _spacecraft: Node = null

## Orbit calculator for trajectory prediction
var _orbit_calculator: OrbitCalculator = null

## Physics engine reference for celestial bodies
var _physics_engine: Node = null

## Time manager reference
var _time_manager: Node = null

## Current trajectory points
var _trajectory_points: Array[Vector3] = []

## Gravity well intersections
var _intersections: Array[Dictionary] = []

## Trajectory mesh instance
var _trajectory_mesh: MeshInstance3D = null

## Time marker meshes
var _time_markers: Array[MeshInstance3D] = []

## Update timer
var _update_timer: float = 0.0

## Whether trajectory needs recalculation
var _needs_update: bool = true

## Last spacecraft velocity (for change detection)
var _last_velocity: Vector3 = Vector3.ZERO

## Last spacecraft position (for change detection)
var _last_position: Vector3 = Vector3.ZERO

## Whether the display is initialized
var _is_initialized: bool = false

#endregion


func _ready() -> void:
	_orbit_calculator = OrbitCalculator.new()
	call_deferred("initialize")


func _process(delta: float) -> void:
	if not _is_initialized or not enabled:
		return
	
	# Requirement 40.5: Update trajectory prediction in real-time with input changes
	_update_timer += delta
	
	if _update_timer >= 1.0 / update_frequency:
		_check_for_changes()
		
		if _needs_update:
			_calculate_trajectory()
			_needs_update = false
		
		_update_timer = 0.0


#region Initialization

## Initialize the trajectory display system
func initialize() -> bool:
	"""Initialize the trajectory display."""
	if _is_initialized:
		return true
	
	# Find system references
	_find_system_references()
	
	# Create trajectory visualization
	_create_trajectory_mesh()
	
	_is_initialized = true
	print("TrajectoryDisplay: Initialized successfully")
	return true


## Find references to game systems
func _find_system_references() -> void:
	"""Find references to spacecraft, physics engine, and time manager."""
	var engine_node = get_node_or_null("/root/ResonanceEngine")
	
	if engine_node:
		# Get spacecraft
		if engine_node.has_method("get_spacecraft"):
			_spacecraft = engine_node.get_spacecraft()
		
		# Get physics engine
		if engine_node.has_method("get_physics_engine"):
			_physics_engine = engine_node.get_physics_engine()
		
		# Get time manager
		if engine_node.has_method("get_time_manager"):
			_time_manager = engine_node.get_time_manager()
	
	if _spacecraft:
		print("TrajectoryDisplay: Found spacecraft")
	if _physics_engine:
		print("TrajectoryDisplay: Found physics engine")
	if _time_manager:
		print("TrajectoryDisplay: Found time manager")


## Create trajectory mesh for rendering
## Requirement 40.3: Render trajectory as colored line
func _create_trajectory_mesh() -> void:
	"""Create the mesh instance for trajectory rendering."""
	_trajectory_mesh = MeshInstance3D.new()
	_trajectory_mesh.name = "TrajectoryMesh"
	add_child(_trajectory_mesh)
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = trajectory_color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = true
	
	if enable_emissive:
		material.emission_enabled = true
		material.emission = trajectory_color
		material.emission_energy_multiplier = emission_intensity
	
	_trajectory_mesh.material_override = material
	_trajectory_mesh.visible = false

#endregion


#region Trajectory Calculation

## Check if spacecraft state has changed
## Requirement 40.5: Update in real-time with input changes
func _check_for_changes() -> void:
	"""Check if spacecraft velocity or position has changed significantly."""
	if not _spacecraft:
		return
	
	var current_position = _spacecraft.global_position if _spacecraft.has_method("get_global_position") else Vector3.ZERO
	var current_velocity = _spacecraft.get_velocity() if _spacecraft.has_method("get_velocity") else Vector3.ZERO
	
	# Check for significant changes
	var position_changed = current_position.distance_to(_last_position) > 1.0
	var velocity_changed = current_velocity.distance_to(_last_velocity) > 0.1
	
	if position_changed or velocity_changed:
		_needs_update = true
		_last_position = current_position
		_last_velocity = current_velocity


## Calculate trajectory prediction
## Requirement 40.1: Calculate and display projected path
## Requirement 40.2: Account for all gravitational influences
func _calculate_trajectory() -> void:
	"""Calculate the predicted trajectory path."""
	if not _spacecraft or not _orbit_calculator:
		return
	
	# Get current spacecraft state
	var current_position = _spacecraft.global_position if _spacecraft.has_method("get_global_position") else Vector3.ZERO
	var current_velocity = _spacecraft.get_velocity() if _spacecraft.has_method("get_velocity") else Vector3.ZERO
	var current_time = _get_current_simulation_time()
	
	# Clear previous trajectory
	_trajectory_points.clear()
	_intersections.clear()
	
	# Get all celestial bodies for gravitational calculations
	var celestial_bodies = _get_celestial_bodies()
	
	if celestial_bodies.is_empty():
		# No gravitational influences - simple linear prediction
		_calculate_linear_trajectory(current_position, current_velocity)
	else:
		# Calculate trajectory with gravitational influences
		_calculate_gravitational_trajectory(current_position, current_velocity, current_time, celestial_bodies)
	
	# Detect gravity well intersections
	## Requirement 40.4: Highlight gravity well intersections
	_detect_gravity_well_intersections(celestial_bodies)
	
	# Update visualization
	_update_trajectory_visualization()
	
	# Emit signal
	trajectory_calculated.emit(_trajectory_points)


## Calculate simple linear trajectory (no gravity)
func _calculate_linear_trajectory(start_pos: Vector3, velocity: Vector3) -> void:
	"""Calculate trajectory without gravitational influences."""
	var dt = prediction_duration / float(trajectory_steps - 1)
	
	for i in range(trajectory_steps):
		var t = dt * i
		var pos = start_pos + velocity * t
		_trajectory_points.append(pos)


## Calculate trajectory with gravitational influences
## Requirement 40.2: Account for all gravitational influences along the path
func _calculate_gravitational_trajectory(start_pos: Vector3, start_vel: Vector3, start_time: float, bodies: Array) -> void:
	"""Calculate trajectory accounting for gravitational forces."""
	# Use numerical integration (Euler method for simplicity, could upgrade to RK4)
	var dt = prediction_duration / float(trajectory_steps - 1)
	
	var pos = start_pos
	var vel = start_vel
	
	for i in range(trajectory_steps):
		_trajectory_points.append(pos)
		
		# Calculate gravitational acceleration from all bodies
		var accel = Vector3.ZERO
		
		for body in bodies:
			if not body or not body.has_method("calculate_gravity_at_point"):
				continue
			
			var gravity = body.calculate_gravity_at_point(pos)
			accel += gravity
		
		# Update velocity and position (Euler integration)
		vel += accel * dt
		pos += vel * dt


## Get all celestial bodies from physics engine
func _get_celestial_bodies() -> Array:
	"""Get all celestial bodies for gravitational calculations."""
	var bodies: Array = []
	
	if _physics_engine and _physics_engine.has_method("get_celestial_bodies"):
		bodies = _physics_engine.get_celestial_bodies()
	
	return bodies


## Get current simulation time
func _get_current_simulation_time() -> float:
	"""Get the current simulation time."""
	if _time_manager and _time_manager.has_method("get_simulation_time"):
		return _time_manager.get_simulation_time()
	return 0.0


## Detect gravity well intersections along trajectory
## Requirement 40.4: Highlight gravity well intersections
func _detect_gravity_well_intersections(bodies: Array) -> void:
	"""Detect where trajectory intersects gravity wells."""
	_intersections.clear()
	
	for body in bodies:
		if not body or not body.has_method("get_radius"):
			continue
		
		var body_pos = body.global_position if body.has_method("get_global_position") else Vector3.ZERO
		var body_radius = body.get_radius()
		var detection_radius = body_radius * gravity_well_threshold
		
		# Check each trajectory point
		for i in range(_trajectory_points.size()):
			var point = _trajectory_points[i]
			var distance = point.distance_to(body_pos)
			
			if distance < detection_radius:
				# Found intersection
				var intersection = {
					"body": body,
					"position": point,
					"index": i,
					"distance": distance
				}
				_intersections.append(intersection)
				
				# Emit signal for first intersection with this body
				gravity_well_intersection_detected.emit(body, point)
				break  # Only record first intersection per body

#endregion


#region Visualization

## Update trajectory visualization
## Requirement 40.3: Render trajectory as colored line with time markers
func _update_trajectory_visualization() -> void:
	"""Update the visual representation of the trajectory."""
	if _trajectory_points.is_empty():
		_trajectory_mesh.visible = false
		_clear_time_markers()
		return
	
	# Create line mesh from trajectory points
	_create_line_mesh()
	
	# Create time markers
	_create_time_markers()
	
	_trajectory_mesh.visible = true


## Create line mesh from trajectory points
func _create_line_mesh() -> void:
	"""Create a mesh representing the trajectory line."""
	if _trajectory_points.size() < 2:
		return
	
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for i in range(_trajectory_points.size()):
		var point = _trajectory_points[i]
		
		# Determine color based on intersections
		var color = trajectory_color
		var is_intersection = false
		
		for intersection in _intersections:
			if i >= intersection["index"]:
				color = intersection_color
				is_intersection = true
				break
		
		immediate_mesh.surface_set_color(color)
		immediate_mesh.surface_add_vertex(point)
	
	immediate_mesh.surface_end()
	
	_trajectory_mesh.mesh = immediate_mesh


## Create time markers along trajectory
## Requirement 40.3: Render with time markers
func _create_time_markers() -> void:
	"""Create visual markers at time intervals along the trajectory."""
	_clear_time_markers()
	
	if time_marker_interval <= 0:
		return
	
	var dt = prediction_duration / float(trajectory_steps - 1)
	var marker_step = int(time_marker_interval / dt)
	
	if marker_step < 1:
		marker_step = 1
	
	for i in range(0, _trajectory_points.size(), marker_step):
		if i == 0:
			continue  # Skip first point
		
		var marker = _create_time_marker(_trajectory_points[i], i * dt)
		_time_markers.append(marker)


## Create a single time marker
func _create_time_marker(position: Vector3, time: float) -> MeshInstance3D:
	"""Create a visual marker at a specific position."""
	var marker = MeshInstance3D.new()
	marker.name = "TimeMarker_%.0f" % time
	add_child(marker)
	marker.global_position = position
	
	# Create sphere mesh
	var sphere = SphereMesh.new()
	sphere.radius = time_marker_size
	sphere.height = time_marker_size * 2
	marker.mesh = sphere
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = trajectory_color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	if enable_emissive:
		material.emission_enabled = true
		material.emission = trajectory_color
		material.emission_energy_multiplier = emission_intensity
	
	marker.material_override = material
	
	return marker


## Clear all time markers
func _clear_time_markers() -> void:
	"""Remove all time marker meshes."""
	for marker in _time_markers:
		if marker and is_instance_valid(marker):
			marker.queue_free()
	_time_markers.clear()

#endregion


#region Public Interface

## Enable trajectory display
func enable_display() -> void:
	"""Enable the trajectory display."""
	enabled = true
	_needs_update = true


## Disable trajectory display
func disable_display() -> void:
	"""Disable the trajectory display."""
	enabled = false
	if _trajectory_mesh:
		_trajectory_mesh.visible = false
	_clear_time_markers()


## Toggle trajectory display
func toggle_display() -> void:
	"""Toggle trajectory display on/off."""
	if enabled:
		disable_display()
	else:
		enable_display()


## Force trajectory recalculation
func force_update() -> void:
	"""Force immediate trajectory recalculation."""
	_needs_update = true
	if enabled:
		_calculate_trajectory()


## Set prediction duration
func set_prediction_duration(duration: float) -> void:
	"""Set the prediction duration in seconds."""
	prediction_duration = max(1.0, duration)
	_needs_update = true


## Set trajectory steps
func set_trajectory_steps(steps: int) -> void:
	"""Set the number of trajectory calculation steps."""
	trajectory_steps = max(10, steps)
	_needs_update = true


## Set spacecraft reference
func set_spacecraft(spacecraft: Node) -> void:
	"""Set the spacecraft reference."""
	_spacecraft = spacecraft
	_needs_update = true


## Set physics engine reference
func set_physics_engine(physics_engine: Node) -> void:
	"""Set the physics engine reference."""
	_physics_engine = physics_engine
	_needs_update = true


## Set time manager reference
func set_time_manager(time_manager: Node) -> void:
	"""Set the time manager reference."""
	_time_manager = time_manager


## Get current trajectory points
func get_trajectory_points() -> Array[Vector3]:
	"""Get the current trajectory points."""
	return _trajectory_points.duplicate()


## Get gravity well intersections
func get_intersections() -> Array[Dictionary]:
	"""Get detected gravity well intersections."""
	return _intersections.duplicate()


## Check if trajectory is currently displayed
func is_displayed() -> bool:
	"""Check if trajectory is currently visible."""
	return enabled and _trajectory_mesh != null and _trajectory_mesh.visible


## Get statistics
func get_statistics() -> Dictionary:
	"""Get trajectory display statistics."""
	return {
		"enabled": enabled,
		"initialized": _is_initialized,
		"trajectory_points": _trajectory_points.size(),
		"intersections": _intersections.size(),
		"time_markers": _time_markers.size(),
		"prediction_duration": prediction_duration,
		"trajectory_steps": trajectory_steps,
		"has_spacecraft": _spacecraft != null,
		"has_physics_engine": _physics_engine != null,
		"has_time_manager": _time_manager != null
	}

#endregion


#region Cleanup

## Cleanup resources
func shutdown() -> void:
	"""Clean up trajectory display resources."""
	_clear_time_markers()
	
	if _trajectory_mesh and is_instance_valid(_trajectory_mesh):
		_trajectory_mesh.queue_free()
		_trajectory_mesh = null
	
	_trajectory_points.clear()
	_intersections.clear()
	
	_is_initialized = false
	print("TrajectoryDisplay: Shutdown complete")

#endregion
