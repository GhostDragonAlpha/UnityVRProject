## CelestialBody - Astronomical Object Representation
## Represents a star, planet, moon, or other astronomical object with
## physical properties, gravity calculations, and visual representation.
##
## Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 9.1, 9.2
## - 6.1: Calculate Lorentz factor for relativistic effects
## - 6.2: Scale world time by Lorentz factor
## - 6.3: Clamp Lorentz factor to prevent division by zero
## - 6.4: Slow down celestial body movements proportionally
## - 6.5: Smoothly restore normal time flow
## - 9.1: Calculate gravitational force using Newton's law F = G·m₁·m₂/r²
## - 9.2: Apply force vector to spacecraft velocity
extends Node3D
class_name CelestialBody

## Emitted when the celestial body's position changes significantly
signal position_changed(new_position: Vector3)
## Emitted when the celestial body's velocity changes
signal velocity_changed(new_velocity: Vector3)
## Emitted when an object enters this body's sphere of influence
signal entered_sphere_of_influence(object: Node3D)
## Emitted when an object exits this body's sphere of influence
signal exited_sphere_of_influence(object: Node3D)

## Body type enumeration
enum BodyType {
	STAR,
	PLANET,
	MOON,
	ASTEROID,
	COMET,
	DWARF_PLANET
}

## Gravitational constant (scaled for game units)
## Derivation: G_real = 6.674e-11 m³/(kg·s²)
## With distance in millions of meters and mass in kg: G_scaled = 6.674e-23
const G: float = 6.674e-23

## Minimum distance for gravity calculations to prevent division by zero
const MIN_GRAVITY_DISTANCE: float = 1.0

## Epsilon for floating-point comparisons
const EPSILON: float = 0.0001

#region Exported Properties

## Name of the celestial body
@export var body_name: String = "Unknown Body"

## Type of celestial body
@export var body_type: BodyType = BodyType.PLANET

## Mass of the body in game mass units
## Requirement 9.1: Used in gravitational force calculation F = G·m₁·m₂/r²
@export var mass: float = 1000.0:
	set(value):
		mass = maxf(value, EPSILON)
		_update_derived_properties()

## Radius of the body in game units
@export var radius: float = 100.0:
	set(value):
		radius = maxf(value, EPSILON)
		_update_derived_properties()

## Current velocity vector of the body
@export var velocity: Vector3 = Vector3.ZERO:
	set(value):
		velocity = value
		velocity_changed.emit(velocity)

## Rotation period in seconds (time for one full rotation)
@export var rotation_period: float = 86400.0  # Default: 24 hours in seconds

## Axial tilt in radians (angle between rotation axis and orbital plane normal)
@export var axial_tilt: float = 0.0:
	set(value):
		axial_tilt = value
		_update_rotation_axis()

## Current rotation angle in radians
@export var current_rotation: float = 0.0

## Optional parent body for orbital calculations (e.g., planet orbiting a star)
@export var parent_body: CelestialBody = null

## Visual model scene to instantiate
@export var model_scene: PackedScene = null

## Albedo color for the body (used if no model is provided)
@export var albedo_color: Color = Color.WHITE

## Whether this body emits light (for stars)
@export var is_emissive: bool = false

## Emission color and intensity (for stars)
@export var emission_color: Color = Color.WHITE
@export var emission_intensity: float = 1.0

#endregion

#region Runtime Properties

## Reference to the visual model MeshInstance3D
var model: MeshInstance3D = null

## Sphere of influence radius (calculated from mass and parent body)
var sphere_of_influence: float = 0.0

## Surface gravity (calculated from mass and radius)
var surface_gravity: float = 0.0

## Escape velocity at surface (calculated from mass and radius)
var escape_velocity_surface: float = 0.0

## Rotation axis (derived from axial tilt)
var rotation_axis: Vector3 = Vector3.UP

## Objects currently within sphere of influence
var _objects_in_soi: Array[Node3D] = []

## Previous position for change detection
var _previous_position: Vector3 = Vector3.ZERO

#endregion


func _ready() -> void:
	_update_derived_properties()
	_update_rotation_axis()
	_setup_model()
	_previous_position = global_position


func _process(delta: float) -> void:
	_update_rotation(delta)
	_check_position_change()


## Update method called by external systems (e.g., OrbitCalculator)
func update(dt: float) -> void:
	"""Update the celestial body's state."""
	# Update position based on velocity
	if velocity.length_squared() > EPSILON:
		global_position += velocity * dt
	
	# Update rotation
	_update_rotation(dt)


#region Gravity Calculations

## Calculate gravitational acceleration at a given point
## Requirement 9.1: Uses Newton's law F = G·m/r² (acceleration = F/m_test = G·M/r²)
## Returns the acceleration vector pointing toward this body
func calculate_gravity_at_point(point: Vector3) -> Vector3:
	"""Calculate gravitational acceleration at a point due to this body."""
	var direction = global_position - point
	var distance = direction.length()
	
	# Prevent division by zero
	if distance < MIN_GRAVITY_DISTANCE:
		distance = MIN_GRAVITY_DISTANCE
	
	# Gravitational acceleration: a = G * M / r²
	var acceleration_magnitude = G * mass / (distance * distance)
	
	# Return acceleration vector pointing toward this body
	return direction.normalized() * acceleration_magnitude


## Calculate gravitational force on an object at a given point with given mass
## Requirement 9.1: F = G·m₁·m₂/r²
func calculate_gravitational_force(point: Vector3, object_mass: float) -> Vector3:
	"""Calculate gravitational force on an object due to this body."""
	var acceleration = calculate_gravity_at_point(point)
	return acceleration * object_mass


## Calculate gravitational potential energy at a point
## U = -G * M * m / r
func calculate_gravitational_potential(point: Vector3, object_mass: float) -> float:
	"""Calculate gravitational potential energy at a point."""
	var distance = (global_position - point).length()
	
	if distance < MIN_GRAVITY_DISTANCE:
		distance = MIN_GRAVITY_DISTANCE
	
	return -G * mass * object_mass / distance


## Get the surface gravity of this body
## g = G * M / r²
func get_surface_gravity() -> float:
	"""Get the surface gravity of this celestial body."""
	return surface_gravity


#endregion

#region Escape Velocity and Sphere of Influence

## Calculate escape velocity at a given distance from the body's center
## v_escape = sqrt(2 * G * M / r)
func calculate_escape_velocity(distance: float) -> float:
	"""Calculate escape velocity at a given distance from the body."""
	if distance < radius:
		distance = radius
	
	if distance < MIN_GRAVITY_DISTANCE:
		distance = MIN_GRAVITY_DISTANCE
	
	return sqrt(2.0 * G * mass / distance)


## Get escape velocity at the surface
func get_escape_velocity() -> float:
	"""Get escape velocity at the surface of this body."""
	return escape_velocity_surface


## Calculate escape velocity at a specific point
func get_escape_velocity_at_point(point: Vector3) -> float:
	"""Get escape velocity at a specific point relative to this body."""
	var distance = (point - global_position).length()
	return calculate_escape_velocity(distance)


## Get the sphere of influence radius
## SOI = a * (m / M)^(2/5) where a is semi-major axis, m is body mass, M is parent mass
## Simplified version when no parent: SOI = radius * (mass / 1000)^0.4 * 10
func get_sphere_of_influence() -> float:
	"""Get the sphere of influence radius."""
	return sphere_of_influence


## Check if a point is within the sphere of influence
func is_point_in_soi(point: Vector3) -> bool:
	"""Check if a point is within this body's sphere of influence."""
	var distance = (point - global_position).length()
	return distance <= sphere_of_influence


## Check if an object is within the sphere of influence
func is_object_in_soi(object: Node3D) -> bool:
	"""Check if an object is within this body's sphere of influence."""
	if not is_instance_valid(object):
		return false
	return is_point_in_soi(object.global_position)


#endregion

#region Orbital Calculations

## Calculate orbital velocity for a circular orbit at a given distance
## v_circular = sqrt(G * M / r)
func calculate_circular_orbit_velocity(distance: float) -> float:
	"""Calculate the velocity needed for a circular orbit at a given distance."""
	if distance < radius:
		distance = radius
	
	if distance < MIN_GRAVITY_DISTANCE:
		distance = MIN_GRAVITY_DISTANCE
	
	return sqrt(G * mass / distance)


## Calculate orbital period for a circular orbit at a given distance
## T = 2 * PI * sqrt(r³ / (G * M))
func calculate_orbital_period(distance: float) -> float:
	"""Calculate the orbital period for a circular orbit at a given distance."""
	if distance < radius:
		distance = radius
	
	if distance < MIN_GRAVITY_DISTANCE:
		distance = MIN_GRAVITY_DISTANCE
	
	return 2.0 * PI * sqrt(pow(distance, 3) / (G * mass))


## Get the Hill sphere radius (approximate SOI for orbiting bodies)
## r_Hill = a * (m / (3 * M))^(1/3)
func calculate_hill_sphere(semi_major_axis: float, parent_mass: float) -> float:
	"""Calculate the Hill sphere radius for this body orbiting a parent."""
	if parent_mass < EPSILON:
		return sphere_of_influence
	
	return semi_major_axis * pow(mass / (3.0 * parent_mass), 1.0 / 3.0)


#endregion

#region Rotation

## Get the current rotation rate in radians per second
func get_rotation_rate() -> float:
	"""Get the rotation rate in radians per second."""
	if rotation_period < EPSILON:
		return 0.0
	return TAU / rotation_period


## Get the rotation axis (accounting for axial tilt)
func get_rotation_axis() -> Vector3:
	"""Get the rotation axis vector."""
	return rotation_axis


## Set the axial tilt and update the rotation axis
func set_axial_tilt(tilt_radians: float) -> void:
	"""Set the axial tilt in radians."""
	axial_tilt = tilt_radians
	_update_rotation_axis()


## Get the current rotation angle
func get_current_rotation() -> float:
	"""Get the current rotation angle in radians."""
	return current_rotation


#endregion

#region Model and Visualization

## Attach a model to this celestial body
func attach_model(mesh_instance: MeshInstance3D) -> void:
	"""Attach a MeshInstance3D as the visual model."""
	# NULL GUARD 1: Clean up existing model safely
	if is_instance_valid(model):
		if is_instance_valid(model.get_parent()) and model.get_parent() == self:
			model.queue_free()
	
	model = mesh_instance
	# NULL GUARD 2: Validate new model before use
	if is_instance_valid(model):
		add_child(model)
		model.position = Vector3.ZERO


## Create a default sphere model if no model is provided
func create_default_model() -> void:
	"""Create a default sphere model for visualization."""
	# NULL GUARD 3: Check if model already exists
	if is_instance_valid(model):
		return
	
	model = MeshInstance3D.new()
	# NULL GUARD 4: Validate created instance
	if not is_instance_valid(model):
		push_error("Failed to create MeshInstance3D for celestial body: " + body_name)
		return
	
	var sphere_mesh = SphereMesh.new()
	# NULL GUARD 5: Validate mesh creation
	if not is_instance_valid(sphere_mesh):
		push_error("Failed to create SphereMesh for celestial body: " + body_name)
		model.queue_free()
		model = null
		return
	
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	sphere_mesh.radial_segments = 32
	sphere_mesh.rings = 16
	model.mesh = sphere_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	# NULL GUARD 6: Validate material creation
	if not is_instance_valid(material):
		push_error("Failed to create material for celestial body: " + body_name)
		model.queue_free()
		model = null
		return
	
	material.albedo_color = albedo_color
	
	if is_emissive:
		material.emission_enabled = true
		material.emission = emission_color
		material.emission_energy_multiplier = emission_intensity
	
	model.material_override = material
	
	add_child(model)
	model.position = Vector3.ZERO


## Update the model scale to match the radius
func update_model_scale() -> void:
	"""Update the model scale to match the body's radius."""
	# NULL GUARD 7: Validate model before accessing
	if not is_instance_valid(model):
		return

	# NULL GUARD 8: Validate mesh before accessing
	if not is_instance_valid(model.mesh):
		return

	if model.mesh is SphereMesh:
		var sphere_mesh = model.mesh as SphereMesh
		sphere_mesh.radius = radius
		sphere_mesh.height = radius * 2.0


## Get the model MeshInstance3D
func get_model() -> MeshInstance3D:
	"""Get the visual model."""
	return model


#endregion

#region Utility Methods

## Get the distance to another celestial body
func get_distance_to(other: CelestialBody) -> float:
	"""Get the distance to another celestial body."""
	if not is_instance_valid(other):
		return INF
	return (other.global_position - global_position).length()


## Get the direction to another celestial body
func get_direction_to(other: CelestialBody) -> Vector3:
	"""Get the normalized direction vector to another celestial body."""
	if not is_instance_valid(other):
		return Vector3.ZERO
	return (other.global_position - global_position).normalized()


## Check if this body is a star
func is_star() -> bool:
	"""Check if this body is a star."""
	return body_type == BodyType.STAR


## Check if this body is a planet
func is_planet() -> bool:
	"""Check if this body is a planet."""
	return body_type == BodyType.PLANET


## Check if this body is a moon
func is_moon() -> bool:
	"""Check if this body is a moon."""
	return body_type == BodyType.MOON


## Get a dictionary of all properties for serialization
func get_properties() -> Dictionary:
	"""Get all properties as a dictionary for serialization."""
	return {
		"body_name": body_name,
		"body_type": body_type,
		"mass": mass,
		"radius": radius,
		"position": global_position,
		"velocity": velocity,
		"rotation_period": rotation_period,
		"axial_tilt": axial_tilt,
		"current_rotation": current_rotation,
		"surface_gravity": surface_gravity,
		"escape_velocity": escape_velocity_surface,
		"sphere_of_influence": sphere_of_influence
	}


## Set properties from a dictionary (for deserialization)
func set_properties(props: Dictionary) -> void:
	"""Set properties from a dictionary."""
	if props.has("body_name"):
		body_name = props.body_name
	if props.has("body_type"):
		body_type = props.body_type
	if props.has("mass"):
		mass = props.mass
	if props.has("radius"):
		radius = props.radius
	if props.has("position"):
		global_position = props.position
	if props.has("velocity"):
		velocity = props.velocity
	if props.has("rotation_period"):
		rotation_period = props.rotation_period
	if props.has("axial_tilt"):
		axial_tilt = props.axial_tilt
	if props.has("current_rotation"):
		current_rotation = props.current_rotation


#endregion

#region Private Methods

## Update derived properties (surface gravity, escape velocity, SOI)
func _update_derived_properties() -> void:
	"""Recalculate derived properties when mass or radius changes."""
	# Surface gravity: g = G * M / r²
	if radius > EPSILON:
		surface_gravity = G * mass / (radius * radius)
	else:
		surface_gravity = 0.0
	
	# Escape velocity at surface: v_escape = sqrt(2 * G * M / r)
	escape_velocity_surface = calculate_escape_velocity(radius)
	
	# Sphere of influence (simplified calculation)
	# When we have a parent body, use Hill sphere approximation
	# Otherwise, use a simplified formula based on mass
	# NULL GUARD 9: Validate parent_body before accessing its properties
	if is_instance_valid(parent_body):
		var distance_to_parent = get_distance_to(parent_body)
		# NULL GUARD 10: Ensure distance calculation succeeded
		if distance_to_parent > EPSILON and distance_to_parent < INF:
			# Safe to access parent_body.mass after validation
			sphere_of_influence = calculate_hill_sphere(distance_to_parent, parent_body.mass)
		else:
			# Fallback if distance calculation fails
			sphere_of_influence = radius * pow(mass / 1000.0, 0.4) * 10.0
	else:
		# Simplified SOI: proportional to mass^(2/5) * radius
		sphere_of_influence = radius * pow(mass / 1000.0, 0.4) * 10.0


## Update the rotation axis based on axial tilt
func _update_rotation_axis() -> void:
	"""Update the rotation axis based on axial tilt."""
	# Rotate the up vector by the axial tilt around the X axis
	rotation_axis = Vector3.UP.rotated(Vector3.RIGHT, axial_tilt).normalized()


## Update the body's rotation
func _update_rotation(delta: float) -> void:
	"""Update the body's rotation based on rotation period."""
	if rotation_period < EPSILON:
		return
	
	var rotation_rate = TAU / rotation_period
	current_rotation += rotation_rate * delta
	
	# Keep rotation angle in [0, TAU) range
	current_rotation = fmod(current_rotation, TAU)
	if current_rotation < 0:
		current_rotation += TAU
	
	# NULL GUARD 11: Apply rotation to the model if it exists and is valid
	if is_instance_valid(model):
		model.rotation = rotation_axis * current_rotation


## Setup the visual model
func _setup_model() -> void:
	"""Setup the visual model from the model_scene or create a default."""
	# NULL GUARD 12: Validate model_scene before instantiation
	if is_instance_valid(model_scene):
		var instance = model_scene.instantiate()
		# NULL GUARD 13: Validate instantiated instance
		if not is_instance_valid(instance):
			push_error("Failed to instantiate model_scene for celestial body: " + body_name)
			create_default_model()
			return

		if instance is MeshInstance3D:
			attach_model(instance)
		else:
			# If the scene root isn't a MeshInstance3D, find one
			var mesh_instance = instance.find_child("*", true, false)
			# NULL GUARD 14: Validate found mesh_instance
			if is_instance_valid(mesh_instance) and mesh_instance is MeshInstance3D:
				attach_model(mesh_instance)
			elif is_instance_valid(instance):
				add_child(instance)
			else:
				push_error("Invalid scene instance for celestial body: " + body_name)
				create_default_model()
	else:
		create_default_model()


## Check if position has changed significantly
func _check_position_change() -> void:
	"""Check if position has changed and emit signal if so."""
	var current_pos = global_position
	if (current_pos - _previous_position).length_squared() > EPSILON:
		position_changed.emit(current_pos)
		_previous_position = current_pos


#endregion
