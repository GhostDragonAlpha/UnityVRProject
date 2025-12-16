## CoordinateSystem - Multi-Reference Frame Coordinate Transformations
## Supports heliocentric, barycentric, and planetocentric coordinate systems
## with accurate transformation matrices and unit formatting.
##
## Requirements: 18.1, 18.2, 18.3, 18.4, 18.5
## - 18.1: Support heliocentric, barycentric, and planetocentric coordinate systems
## - 18.2: Apply correct transformation matrices
## - 18.3: Format coordinates with appropriate units (km, AU, light-years)
## - 18.4: Correctly interpret coordinate system metadata
## - 18.5: Handle floating-point precision for vast distances
extends RefCounted
class_name CoordinateSystem

## Coordinate system types
enum SystemType {
	HELIOCENTRIC,      ## Origin at the Sun
	BARYCENTRIC,       ## Origin at the solar system barycenter
	PLANETOCENTRIC,    ## Origin at a specific planet
	GALACTIC,          ## Galactic coordinate system
	LOCAL              ## Local coordinate system (floating origin)
}

## Unit types for distance formatting
enum DistanceUnit {
	METERS,
	KILOMETERS,
	ASTRONOMICAL_UNITS,  ## AU
	LIGHT_YEARS,
	PARSECS,
	GAME_UNITS           ## Internal game units
}

## Conversion constants
const METERS_PER_GAME_UNIT: float = 1000.0  ## 1 game unit = 1 km
const METERS_PER_AU: float = 149597870700.0  ## Astronomical Unit in meters
const METERS_PER_LIGHT_YEAR: float = 9460730472580800.0  ## Light year in meters
const METERS_PER_PARSEC: float = 30856775814913673.0  ## Parsec in meters

## Epsilon for floating-point comparisons
const EPSILON: float = 1e-10

## Minimum distance for safe division
const MIN_DISTANCE: float = 1e-6


#region Coordinate Frame Definition

## Coordinate frame structure
class CoordinateFrame:
	## Type of coordinate system
	var system_type: SystemType = SystemType.LOCAL
	## Origin body (for planetocentric systems)
	var origin_body: CelestialBody = null
	## Origin position in absolute coordinates (for non-body-centered systems)
	var origin_position: Vector3 = Vector3.ZERO
	## Rotation of the coordinate frame (for oriented systems)
	var rotation: Basis = Basis.IDENTITY
	## Name of the coordinate frame
	var frame_name: String = "Local"
	## Metadata dictionary for additional information
	var metadata: Dictionary = {}
	
	func _init(type: SystemType = SystemType.LOCAL, name: String = "Local") -> void:
		system_type = type
		frame_name = name
	
	func duplicate() -> CoordinateFrame:
		var frame = CoordinateFrame.new(system_type, frame_name)
		frame.origin_body = origin_body
		frame.origin_position = origin_position
		frame.rotation = rotation
		frame.metadata = metadata.duplicate()
		return frame
	
	func to_dictionary() -> Dictionary:
		return {
			"system_type": system_type,
			"frame_name": frame_name,
			"origin_position": origin_position,
			"rotation": {
				"x": rotation.x,
				"y": rotation.y,
				"z": rotation.z
			},
			"metadata": metadata
		}
	
	static func from_dictionary(data: Dictionary) -> CoordinateFrame:
		var frame = CoordinateFrame.new(
			data.get("system_type", SystemType.LOCAL),
			data.get("frame_name", "Local")
		)
		frame.origin_position = data.get("origin_position", Vector3.ZERO)
		
		if data.has("rotation"):
			var rot_data = data.rotation
			frame.rotation = Basis(
				rot_data.get("x", Vector3.RIGHT),
				rot_data.get("y", Vector3.UP),
				rot_data.get("z", Vector3.BACK)
			)
		
		frame.metadata = data.get("metadata", {})
		return frame

#endregion


#region Coordinate Transformation

## Transform a position from one coordinate frame to another
## Requirement 18.2: Apply correct transformation matrices
## Property 14: Coordinate System Round Trip
static func transform_position(position: Vector3, from_frame: CoordinateFrame, to_frame: CoordinateFrame) -> Vector3:
	"""Transform a position vector from one coordinate frame to another."""
	if from_frame == null or to_frame == null:
		push_error("CoordinateSystem: Invalid coordinate frames")
		return position
	
	# If frames are the same, no transformation needed
	if from_frame == to_frame:
		return position
	
	# Step 1: Transform from source frame to absolute coordinates
	var absolute_pos = _to_absolute_coordinates(position, from_frame)
	
	# Step 2: Transform from absolute coordinates to target frame
	var result = _from_absolute_coordinates(absolute_pos, to_frame)
	
	return result


## Transform a velocity from one coordinate frame to another
## Requirement 18.2: Apply correct transformation matrices
static func transform_velocity(velocity: Vector3, position: Vector3, 
								from_frame: CoordinateFrame, to_frame: CoordinateFrame) -> Vector3:
	"""Transform a velocity vector from one coordinate frame to another."""
	if from_frame == null or to_frame == null:
		push_error("CoordinateSystem: Invalid coordinate frames")
		return velocity
	
	# If frames are the same, no transformation needed
	if from_frame == to_frame:
		return velocity
	
	# Transform position to get frame velocities
	var absolute_pos = _to_absolute_coordinates(position, from_frame)
	
	# Rotate velocity to absolute frame
	var absolute_vel = from_frame.rotation * velocity
	
	# Add frame velocity if origin is moving
	if from_frame.origin_body != null and is_instance_valid(from_frame.origin_body):
		absolute_vel += from_frame.origin_body.velocity
	
	# Subtract target frame velocity
	if to_frame.origin_body != null and is_instance_valid(to_frame.origin_body):
		absolute_vel -= to_frame.origin_body.velocity
	
	# Rotate to target frame
	var result = to_frame.rotation.inverse() * absolute_vel
	
	return result


## Transform a full state (position and velocity) between frames
static func transform_state(position: Vector3, velocity: Vector3,
							 from_frame: CoordinateFrame, to_frame: CoordinateFrame) -> Dictionary:
	"""Transform both position and velocity between coordinate frames."""
	var new_position = transform_position(position, from_frame, to_frame)
	var new_velocity = transform_velocity(velocity, position, from_frame, to_frame)
	
	return {
		"position": new_position,
		"velocity": new_velocity
	}


## Create a transformation matrix from one frame to another
## Requirement 18.2: Correct transformation matrices
static func get_transformation_matrix(from_frame: CoordinateFrame, to_frame: CoordinateFrame) -> Transform3D:
	"""Get the transformation matrix from one coordinate frame to another."""
	if from_frame == null or to_frame == null:
		return Transform3D.IDENTITY
	
	# Calculate origin offset
	var origin_offset = Vector3.ZERO
	
	# From frame origin in absolute coordinates
	var from_origin_abs = _get_frame_origin_absolute(from_frame)
	
	# To frame origin in absolute coordinates
	var to_origin_abs = _get_frame_origin_absolute(to_frame)
	
	# Offset between origins
	origin_offset = from_origin_abs - to_origin_abs
	
	# Rotation: from source frame to absolute, then to target frame
	var rotation = to_frame.rotation.inverse() * from_frame.rotation
	
	# Create transformation
	var transform = Transform3D(rotation, origin_offset)
	
	return transform

#endregion


#region Frame Creation Helpers

## Create a heliocentric coordinate frame
## Requirement 18.1: Support heliocentric coordinate system
static func create_heliocentric_frame(sun: CelestialBody) -> CoordinateFrame:
	"""Create a heliocentric coordinate frame centered on the Sun."""
	var frame = CoordinateFrame.new(SystemType.HELIOCENTRIC, "Heliocentric")
	frame.origin_body = sun
	frame.metadata["description"] = "Coordinate system centered on the Sun"
	return frame


## Create a barycentric coordinate frame
## Requirement 18.1: Support barycentric coordinate system
static func create_barycentric_frame(bodies: Array[CelestialBody]) -> CoordinateFrame:
	"""Create a barycentric coordinate frame at the center of mass."""
	var frame = CoordinateFrame.new(SystemType.BARYCENTRIC, "Barycentric")
	
	# Calculate barycenter position
	var barycenter = calculate_barycenter(bodies)
	frame.origin_position = barycenter
	frame.metadata["description"] = "Coordinate system at the solar system barycenter"
	frame.metadata["body_count"] = bodies.size()
	
	return frame


## Create a planetocentric coordinate frame
## Requirement 18.1: Support planetocentric coordinate system
static func create_planetocentric_frame(planet: CelestialBody) -> CoordinateFrame:
	"""Create a planetocentric coordinate frame centered on a planet."""
	var frame = CoordinateFrame.new(SystemType.PLANETOCENTRIC, "Planetocentric")
	frame.origin_body = planet
	
	# Set rotation to align with planet's rotation axis
	if planet != null:
		frame.frame_name = planet.body_name + "-centric"
		frame.metadata["planet_name"] = planet.body_name
		frame.metadata["description"] = "Coordinate system centered on " + planet.body_name
		
		# Align frame with planet's rotation axis
		var rotation_axis = planet.get_rotation_axis()
		if rotation_axis.length_squared() > EPSILON:
			# Create basis with planet's rotation axis as up
			var up = rotation_axis.normalized()
			var right = Vector3.RIGHT
			if absf(up.dot(Vector3.RIGHT)) > 0.9:
				right = Vector3.FORWARD
			var forward = up.cross(right).normalized()
			right = forward.cross(up).normalized()
			frame.rotation = Basis(right, up, -forward)
	
	return frame


## Create a local coordinate frame at a specific position
static func create_local_frame(position: Vector3, rotation: Basis = Basis.IDENTITY, name: String = "Local") -> CoordinateFrame:
	"""Create a local coordinate frame at a specific position."""
	var frame = CoordinateFrame.new(SystemType.LOCAL, name)
	frame.origin_position = position
	frame.rotation = rotation
	frame.metadata["description"] = "Local coordinate frame"
	return frame


## Create a galactic coordinate frame
static func create_galactic_frame() -> CoordinateFrame:
	"""Create a galactic coordinate frame."""
	var frame = CoordinateFrame.new(SystemType.GALACTIC, "Galactic")
	frame.metadata["description"] = "Galactic coordinate system"
	return frame

#endregion


#region Distance Formatting

## Format a distance with appropriate units
## Requirement 18.3: Format coordinates with appropriate units
static func format_distance(distance: float, unit: DistanceUnit = DistanceUnit.GAME_UNITS, precision: int = 2) -> String:
	"""Format a distance value with appropriate units."""
	var value: float
	var unit_str: String
	
	match unit:
		DistanceUnit.METERS:
			value = distance * METERS_PER_GAME_UNIT
			unit_str = "m"
		DistanceUnit.KILOMETERS:
			value = distance * METERS_PER_GAME_UNIT / 1000.0
			unit_str = "km"
		DistanceUnit.ASTRONOMICAL_UNITS:
			value = distance * METERS_PER_GAME_UNIT / METERS_PER_AU
			unit_str = "AU"
		DistanceUnit.LIGHT_YEARS:
			value = distance * METERS_PER_GAME_UNIT / METERS_PER_LIGHT_YEAR
			unit_str = "ly"
		DistanceUnit.PARSECS:
			value = distance * METERS_PER_GAME_UNIT / METERS_PER_PARSEC
			unit_str = "pc"
		DistanceUnit.GAME_UNITS:
			value = distance
			unit_str = "units"
		_:
			value = distance
			unit_str = "units"
	
	# Format with appropriate precision
	var format_str = "%." + str(precision) + "f %s"
	return format_str % [value, unit_str]


## Automatically choose the best unit for a distance
## Requirement 18.3: Use appropriate units based on scale
static func format_distance_auto(distance: float, precision: int = 2) -> String:
	"""Automatically format distance with the most appropriate unit."""
	var distance_meters = absf(distance) * METERS_PER_GAME_UNIT
	
	# Choose unit based on magnitude
	if distance_meters < 1000.0:
		return format_distance(distance, DistanceUnit.METERS, precision)
	elif distance_meters < METERS_PER_AU * 0.1:
		return format_distance(distance, DistanceUnit.KILOMETERS, precision)
	elif distance_meters < METERS_PER_LIGHT_YEAR * 0.1:
		return format_distance(distance, DistanceUnit.ASTRONOMICAL_UNITS, precision)
	else:
		return format_distance(distance, DistanceUnit.LIGHT_YEARS, precision)


## Format a position vector with units
## Requirement 18.3: Format coordinates with appropriate units
static func format_position(position: Vector3, unit: DistanceUnit = DistanceUnit.GAME_UNITS, precision: int = 2) -> String:
	"""Format a position vector with units."""
	var x_str = format_distance(position.x, unit, precision)
	var y_str = format_distance(position.y, unit, precision)
	var z_str = format_distance(position.z, unit, precision)
	
	return "(%s, %s, %s)" % [x_str, y_str, z_str]


## Format a velocity vector with units
static func format_velocity(velocity: Vector3, precision: int = 2) -> String:
	"""Format a velocity vector."""
	var format_str = "%." + str(precision) + "f"
	var x_str = format_str % velocity.x
	var y_str = format_str % velocity.y
	var z_str = format_str % velocity.z
	
	return "(%s, %s, %s) units/s" % [x_str, y_str, z_str]

#endregion


#region Coordinate Conversion

## Convert distance from one unit to another
static func convert_distance(distance: float, from_unit: DistanceUnit, to_unit: DistanceUnit) -> float:
	"""Convert a distance from one unit to another."""
	# Convert to meters first
	var meters: float
	match from_unit:
		DistanceUnit.METERS:
			meters = distance
		DistanceUnit.KILOMETERS:
			meters = distance * 1000.0
		DistanceUnit.ASTRONOMICAL_UNITS:
			meters = distance * METERS_PER_AU
		DistanceUnit.LIGHT_YEARS:
			meters = distance * METERS_PER_LIGHT_YEAR
		DistanceUnit.PARSECS:
			meters = distance * METERS_PER_PARSEC
		DistanceUnit.GAME_UNITS:
			meters = distance * METERS_PER_GAME_UNIT
		_:
			meters = distance * METERS_PER_GAME_UNIT
	
	# Convert from meters to target unit
	match to_unit:
		DistanceUnit.METERS:
			return meters
		DistanceUnit.KILOMETERS:
			return meters / 1000.0
		DistanceUnit.ASTRONOMICAL_UNITS:
			return meters / METERS_PER_AU
		DistanceUnit.LIGHT_YEARS:
			return meters / METERS_PER_LIGHT_YEAR
		DistanceUnit.PARSECS:
			return meters / METERS_PER_PARSEC
		DistanceUnit.GAME_UNITS:
			return meters / METERS_PER_GAME_UNIT
		_:
			return meters / METERS_PER_GAME_UNIT

#endregion


#region Barycenter Calculation

## Calculate the barycenter (center of mass) of multiple bodies
static func calculate_barycenter(bodies: Array[CelestialBody]) -> Vector3:
	"""Calculate the barycenter position of multiple celestial bodies."""
	if bodies.is_empty():
		return Vector3.ZERO
	
	var total_mass: float = 0.0
	var weighted_position: Vector3 = Vector3.ZERO
	
	for body in bodies:
		if body != null and is_instance_valid(body):
			total_mass += body.mass
			weighted_position += body.global_position * body.mass
	
	if total_mass < EPSILON:
		return Vector3.ZERO
	
	return weighted_position / total_mass


## Calculate the barycentric velocity of multiple bodies
static func calculate_barycentric_velocity(bodies: Array[CelestialBody]) -> Vector3:
	"""Calculate the barycentric velocity of multiple celestial bodies."""
	if bodies.is_empty():
		return Vector3.ZERO
	
	var total_mass: float = 0.0
	var weighted_velocity: Vector3 = Vector3.ZERO
	
	for body in bodies:
		if body != null and is_instance_valid(body):
			total_mass += body.mass
			weighted_velocity += body.velocity * body.mass
	
	if total_mass < EPSILON:
		return Vector3.ZERO
	
	return weighted_velocity / total_mass

#endregion


#region Validation

## Validate a coordinate frame
## Requirement 18.4: Correctly interpret coordinate system metadata
static func validate_frame(frame: CoordinateFrame) -> bool:
	"""Validate that a coordinate frame is properly configured."""
	if frame == null:
		return false
	
	# Check that planetocentric frames have an origin body
	if frame.system_type == SystemType.PLANETOCENTRIC:
		if frame.origin_body == null or not is_instance_valid(frame.origin_body):
			push_warning("CoordinateSystem: Planetocentric frame missing origin body")
			return false
	
	# Check that heliocentric frames have a sun
	if frame.system_type == SystemType.HELIOCENTRIC:
		if frame.origin_body == null or not is_instance_valid(frame.origin_body):
			push_warning("CoordinateSystem: Heliocentric frame missing sun")
			return false
	
	# Check rotation basis is valid
	# Check if basis is approximately orthonormal (determinant ≈ 1 and columns are unit vectors)
	if not frame.rotation.is_conformal(): # Use is_conformal as a proxy for orthogonality check
		push_warning("CoordinateSystem: Frame rotation basis is not conformal/orthogonal")
		return false
		
	var det = frame.rotation.determinant()
	if abs(det - 1.0) > 0.01:
		push_warning("CoordinateSystem: Frame rotation basis is not orthonormal (det=" + str(det) + ")")
		return false
	
	return true


## Check if two frames are compatible for transformation
static func are_frames_compatible(frame1: CoordinateFrame, frame2: CoordinateFrame) -> bool:
	"""Check if two coordinate frames can be transformed between."""
	return validate_frame(frame1) and validate_frame(frame2)

#endregion


#region Private Helper Methods

## Convert position from a frame to absolute coordinates
static func _to_absolute_coordinates(position: Vector3, frame: CoordinateFrame) -> Vector3:
	"""Convert position from a coordinate frame to absolute coordinates."""
	# Rotate by frame rotation
	var rotated = frame.rotation * position
	
	# Add frame origin
	var origin = _get_frame_origin_absolute(frame)
	
	return rotated + origin


## Convert position from absolute coordinates to a frame
static func _from_absolute_coordinates(position: Vector3, frame: CoordinateFrame) -> Vector3:
	"""Convert position from absolute coordinates to a coordinate frame."""
	# Subtract frame origin
	var origin = _get_frame_origin_absolute(frame)
	var relative = position - origin
	
	# Rotate by inverse frame rotation
	return frame.rotation.inverse() * relative


## Get the absolute position of a frame's origin
static func _get_frame_origin_absolute(frame: CoordinateFrame) -> Vector3:
	"""Get the absolute position of a coordinate frame's origin."""
	if frame.origin_body != null and is_instance_valid(frame.origin_body):
		return frame.origin_body.global_position
	else:
		return frame.origin_position

#endregion


#region Precision Handling

## Check if a position is within safe floating-point precision range
## Requirement 18.5: Handle floating-point precision for vast distances
static func is_position_safe(position: Vector3, threshold: float = 1e6) -> bool:
	"""Check if a position is within safe floating-point precision range."""
	return position.length() < threshold


## Calculate relative error in position due to floating-point precision
## Requirement 18.5: Handle floating-point precision
static func calculate_precision_error(position: Vector3) -> float:
	"""Estimate the relative precision error at a given position."""
	var magnitude = position.length()
	if magnitude < EPSILON:
		return 0.0
	
	# Floating-point precision degrades with magnitude
	# Single precision has ~7 decimal digits, double has ~16
	# Estimate error as magnitude * machine epsilon
	var machine_epsilon = 1.19209e-07  # Single precision epsilon
	return magnitude * machine_epsilon


## Get recommended rebasing threshold for a coordinate frame
static func get_rebasing_threshold(frame: CoordinateFrame) -> float:
	"""Get the recommended distance threshold for coordinate rebasing."""
	# Default threshold from FloatingOriginSystem
	return 5000.0

#endregion
