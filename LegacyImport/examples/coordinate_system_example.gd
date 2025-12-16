## Coordinate System Integration Example
## Demonstrates how to use the CoordinateSystem with CelestialBody objects
extends Node

const CoordinateSystem = preload("res://scripts/celestial/coordinate_system.gd")
const CelestialBody = preload("res://scripts/celestial/celestial_body.gd")


func _ready() -> void:
	print("\n=== Coordinate System Integration Example ===\n")
	
	# Example 1: Create celestial bodies
	example_1_create_bodies()
	
	# Example 2: Transform between frames
	example_2_transform_coordinates()
	
	# Example 3: Format distances
	example_3_format_distances()
	
	# Example 4: Calculate barycenter
	example_4_barycenter()
	
	# Example 5: Spacecraft navigation
	example_5_spacecraft_navigation()
	
	print("\n=== Examples Complete ===\n")


func example_1_create_bodies() -> void:
	"""Example 1: Create celestial bodies and coordinate frames."""
	print("Example 1: Creating Celestial Bodies and Frames")
	print("==================================================")
	
	# Create Sun
	var sun = CelestialBody.new()
	sun.body_name = "Sun"
	sun.mass = 1989000.0  # Solar masses in game units
	sun.radius = 696.0
	sun.body_type = CelestialBody.BodyType.STAR
	sun.global_position = Vector3.ZERO
	
	# Create Earth
	var earth = CelestialBody.new()
	earth.body_name = "Earth"
	earth.mass = 5972.0
	earth.radius = 6.371
	earth.body_type = CelestialBody.BodyType.PLANET
	earth.global_position = Vector3(149597.870700, 0, 0)  # 1 AU from Sun
	earth.velocity = Vector3(0, 29.78, 0)  # Orbital velocity
	
	# Create coordinate frames
	var helio_frame = CoordinateSystem.create_heliocentric_frame(sun)
	var earth_frame = CoordinateSystem.create_planetocentric_frame(earth)
	
	print("Created Sun at: ", sun.global_position)
	print("Created Earth at: ", earth.global_position)
	print("Heliocentric frame: ", helio_frame.frame_name)
	print("Earth-centric frame: ", earth_frame.frame_name)
	print()
	
	# Cleanup
	sun.free()
	earth.free()


func example_2_transform_coordinates() -> void:
	"""Example 2: Transform coordinates between frames."""
	print("Example 2: Coordinate Transformations")
	print("==================================================")
	
	# Setup
	var sun = CelestialBody.new()
	sun.global_position = Vector3.ZERO
	sun.mass = 1989000.0
	
	var earth = CelestialBody.new()
	earth.global_position = Vector3(149597.870700, 0, 0)
	earth.mass = 5972.0
	
	var helio_frame = CoordinateSystem.create_heliocentric_frame(sun)
	var earth_frame = CoordinateSystem.create_planetocentric_frame(earth)
	
	# Spacecraft position in heliocentric coordinates
	var spacecraft_pos_helio = Vector3(149597.870700 + 6.371 + 400.0, 0, 0)
	print("Spacecraft position (heliocentric): ", spacecraft_pos_helio)
	
	# Transform to Earth-centric coordinates
	var spacecraft_pos_earth = CoordinateSystem.transform_position(
		spacecraft_pos_helio,
		helio_frame,
		earth_frame
	)
	print("Spacecraft position (Earth-centric): ", spacecraft_pos_earth)
	
	# Calculate altitude
	var altitude = spacecraft_pos_earth.length() - earth.radius
	print("Altitude above Earth surface: ", altitude, " game units")
	print()
	
	# Cleanup
	sun.free()
	earth.free()


func example_3_format_distances() -> void:
	"""Example 3: Format distances with different units."""
	print("Example 3: Distance Formatting")
	print("==================================================")
	
	var distances = [
		{"value": 0.4, "name": "Low Earth Orbit"},
		{"value": 384.4, "name": "Moon distance"},
		{"value": 149597.870700, "name": "1 AU (Earth-Sun)"},
		{"value": 5906376272000.0, "name": "1 light-year"}
	]
	
	for dist_data in distances:
		var distance = dist_data.value
		var name = dist_data.name
		
		print("\n", name, ":")
		print("  Meters: ", CoordinateSystem.format_distance(
			distance, CoordinateSystem.DistanceUnit.METERS, 2
		))
		print("  Kilometers: ", CoordinateSystem.format_distance(
			distance, CoordinateSystem.DistanceUnit.KILOMETERS, 2
		))
		print("  Auto: ", CoordinateSystem.format_distance_auto(distance, 3))
	
	print()


func example_4_barycenter() -> void:
	"""Example 4: Calculate solar system barycenter."""
	print("Example 4: Barycenter Calculation")
	print("==================================================")
	
	# Create simplified solar system
	var sun = CelestialBody.new()
	sun.body_name = "Sun"
	sun.mass = 1989000.0
	sun.global_position = Vector3.ZERO
	
	var jupiter = CelestialBody.new()
	jupiter.body_name = "Jupiter"
	jupiter.mass = 1898.0
	jupiter.global_position = Vector3(778000.0, 0, 0)  # ~5.2 AU
	
	var earth = CelestialBody.new()
	earth.body_name = "Earth"
	earth.mass = 5972.0
	earth.global_position = Vector3(149597.870700, 0, 0)
	
	var bodies: Array[CelestialBody] = [sun, jupiter, earth]
	
	# Calculate barycenter
	var barycenter = CoordinateSystem.calculate_barycenter(bodies)
	print("Solar system barycenter: ", barycenter)
	print("Distance from Sun center: ", barycenter.length(), " game units")
	
	# Create barycentric frame
	var bary_frame = CoordinateSystem.create_barycentric_frame(bodies)
	print("Barycentric frame created: ", bary_frame.frame_name)
	print()
	
	# Cleanup
	sun.free()
	jupiter.free()
	earth.free()


func example_5_spacecraft_navigation() -> void:
	"""Example 5: Spacecraft navigation using coordinate systems."""
	print("Example 5: Spacecraft Navigation")
	print("==================================================")
	
	# Setup
	var sun = CelestialBody.new()
	sun.global_position = Vector3.ZERO
	sun.mass = 1989000.0
	
	var mars = CelestialBody.new()
	mars.body_name = "Mars"
	mars.global_position = Vector3(227900.0, 0, 0)  # ~1.52 AU
	mars.mass = 641.0
	mars.radius = 3.389
	
	var helio_frame = CoordinateSystem.create_heliocentric_frame(sun)
	var mars_frame = CoordinateSystem.create_planetocentric_frame(mars)
	
	# Spacecraft approaching Mars
	var spacecraft_pos_helio = Vector3(227900.0 + 100.0, 50.0, 25.0)
	var spacecraft_vel_helio = Vector3(-5.0, 2.0, 1.0)
	
	print("Spacecraft approaching Mars:")
	print("  Position (heliocentric): ", 
		CoordinateSystem.format_position(
			spacecraft_pos_helio,
			CoordinateSystem.DistanceUnit.ASTRONOMICAL_UNITS,
			4
		)
	)
	
	# Transform to Mars-centric coordinates
	var spacecraft_pos_mars = CoordinateSystem.transform_position(
		spacecraft_pos_helio,
		helio_frame,
		mars_frame
	)
	
	var spacecraft_vel_mars = CoordinateSystem.transform_velocity(
		spacecraft_vel_helio,
		spacecraft_pos_helio,
		helio_frame,
		mars_frame
	)
	
	print("  Position (Mars-centric): ", spacecraft_pos_mars)
	print("  Velocity (Mars-centric): ", spacecraft_vel_mars)
	
	# Calculate distance to Mars surface
	var distance_to_surface = spacecraft_pos_mars.length() - mars.radius
	print("  Distance to Mars surface: ", 
		CoordinateSystem.format_distance(
			distance_to_surface,
			CoordinateSystem.DistanceUnit.KILOMETERS,
			2
		)
	)
	
	# Check if in sphere of influence
	if mars.is_point_in_soi(spacecraft_pos_mars):
		print("  Status: Inside Mars sphere of influence")
	else:
		print("  Status: Outside Mars sphere of influence")
	
	print()
	
	# Cleanup
	sun.free()
	mars.free()
