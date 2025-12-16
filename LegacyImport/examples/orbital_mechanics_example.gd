## Example: Using OrbitalMechanics for Spacecraft Orbital Calculations
## This example demonstrates how to use the OrbitalMechanics class
## to calculate orbital parameters and predict spacecraft trajectories.

extends Node

func _ready() -> void:
	example_orbital_calculations()


func example_orbital_calculations() -> void:
	"""Demonstrate orbital mechanics calculations."""
	print("\n=== Orbital Mechanics Example ===\n")

	# Create an orbital mechanics calculator
	var orbital_calc = OrbitalMechanics.new()

	# Create a mock central body (e.g., Earth-like planet)
	var earth = CelestialBody.new()
	earth.body_name = "Earth"
	earth.mass = 5972.0  # Scaled mass
	earth.radius = 63.71  # Scaled radius (100x smaller than real Earth)
	earth.global_position = Vector3.ZERO

	# Spacecraft initial conditions (circular orbit at 200 km altitude)
	var orbit_altitude = 20.0  # Scaled altitude
	var orbit_radius = earth.radius + orbit_altitude

	# Calculate circular orbit velocity
	var circular_velocity = orbital_calc.calculate_circular_orbit_velocity(
		Vector3(orbit_radius, 0, 0),
		earth
	)

	var spacecraft_position = Vector3(orbit_radius, 0, 0)
	var spacecraft_velocity = Vector3(0, circular_velocity, 0)

	print("Initial Conditions:")
	print("  Position: %s" % spacecraft_position)
	print("  Velocity: %s" % spacecraft_velocity)
	print("  Speed: %.2f units/s" % spacecraft_velocity.length())
	print()

	# Calculate orbital elements
	var elements = orbital_calc.calculate_orbit(
		spacecraft_position,
		spacecraft_velocity,
		earth
	)

	print("Orbital Elements:")
	print("  Semi-major axis: %.2f units" % elements.semi_major_axis)
	print("  Eccentricity: %.6f" % elements.eccentricity)
	print("  Inclination: %.2f degrees" % rad_to_deg(elements.inclination))
	print("  Period: %.2f seconds" % orbital_calc.orbital_period(elements))
	print()

	# Calculate escape velocity
	var v_escape = orbital_calc.escape_velocity(spacecraft_position, earth)
	print("Escape Velocity at Position: %.2f units/s" % v_escape)
	print()

	# Predict future position
	var time_offset = orbital_calc.orbital_period(elements) / 4.0  # Quarter orbit
	var predicted_state = orbital_calc.predict_position(elements, time_offset)

	print("Prediction after %.2f seconds (quarter orbit):" % time_offset)
	print("  Position: %s" % predicted_state.position)
	print("  Velocity: %s" % predicted_state.velocity)
	print()

	# Calculate orbital info
	var orbital_info = orbital_calc.get_orbital_info(elements)
	print("Detailed Orbital Information:")
	for key in orbital_info:
		if orbital_info[key] is float:
			print("  %s: %.4f" % [key, orbital_info[key]])
		else:
			print("  %s: %s" % [key, orbital_info[key]])
	print()

	# Predict trajectory over one full orbit
	var trajectory = orbital_calc.predict_trajectory(
		spacecraft_position,
		spacecraft_velocity,
		earth,
		orbital_calc.orbital_period(elements),
		16  # 16 points around the orbit
	)

	print("Trajectory Preview (16 points over full orbit):")
	for i in range(min(4, trajectory.size())):
		print("  Point %d: %s" % [i, trajectory[i]])
	print("  ... (%d total points)" % trajectory.size())
	print()

	# Check for escape trajectory
	var is_escaping = orbital_calc.is_escape_trajectory(
		spacecraft_position,
		spacecraft_velocity,
		earth
	)
	print("Is on escape trajectory: %s" % is_escaping)

	# Calculate Hohmann transfer to higher orbit
	var target_radius = orbit_radius * 2.0
	var mu = OrbitalMechanics.G * earth.mass
	var hohmann = orbital_calc.calculate_hohmann_transfer_dv(
		orbit_radius,
		target_radius,
		mu
	)

	print("\nHohmann Transfer to %.2f units altitude:" % (target_radius - earth.radius))
	print("  Departure Δv: %.2f units/s" % hohmann.departure_dv)
	print("  Arrival Δv: %.2f units/s" % hohmann.arrival_dv)
	print("  Total Δv: %.2f units/s" % hohmann.total_dv)
	print("  Transfer time: %.2f seconds" % hohmann.transfer_time)
	print()

	# Verify energy conservation
	var state1 = OrbitCalculator.StateVector.new(
		spacecraft_position - earth.global_position,
		spacecraft_velocity,
		0.0
	)
	var state2 = predicted_state
	state2.position -= earth.global_position

	var energy_error = orbital_calc.verify_energy_conservation(state1, state2, mu)
	print("Energy Conservation Check:")
	print("  Relative error: %.8f (%.4f%%)" % [energy_error, energy_error * 100.0])
	print("  Within 0.01%% tolerance: %s" % (energy_error < 0.0001))

	print("\n=== Example Complete ===\n")


func example_elliptical_orbit() -> void:
	"""Example with an elliptical orbit."""
	print("\n=== Elliptical Orbit Example ===\n")

	var orbital_calc = OrbitalMechanics.new()

	# Create central body
	var star = CelestialBody.new()
	star.body_name = "Star"
	star.mass = 10000.0
	star.radius = 100.0
	star.global_position = Vector3.ZERO

	# Spacecraft in elliptical orbit (at periapsis)
	var periapsis = 200.0
	var spacecraft_position = Vector3(periapsis, 0, 0)

	# Give velocity perpendicular to position, but not circular
	var circular_v = orbital_calc.calculate_circular_orbit_velocity(spacecraft_position, star)
	var spacecraft_velocity = Vector3(0, circular_v * 1.3, 0)  # 30% faster = elliptical

	print("Initial Conditions (at periapsis):")
	print("  Position: %s" % spacecraft_position)
	print("  Velocity magnitude: %.2f" % spacecraft_velocity.length())
	print()

	# Calculate orbital elements
	var elements = orbital_calc.calculate_orbit(
		spacecraft_position,
		spacecraft_velocity,
		star
	)

	print("Orbital Elements:")
	print("  Semi-major axis: %.2f" % elements.semi_major_axis)
	print("  Eccentricity: %.4f" % elements.eccentricity)
	print("  Periapsis: %.2f" % orbital_calc.calculate_periapsis_distance(elements))
	print("  Apoapsis: %.2f" % orbital_calc.calculate_apoapsis_distance(elements))
	print("  Period: %.2f seconds" % orbital_calc.orbital_period(elements))
	print()

	# Velocity at periapsis and apoapsis
	var v_peri = orbital_calc.calculate_periapsis_velocity(elements)
	var v_apo = orbital_calc.calculate_apoapsis_velocity(elements)

	print("Velocities:")
	print("  At periapsis: %.2f" % v_peri)
	print("  At apoapsis: %.2f" % v_apo)
	print("  Ratio (Vp/Va): %.2f" % (v_peri / v_apo))
	print()

	print("=== Example Complete ===\n")
