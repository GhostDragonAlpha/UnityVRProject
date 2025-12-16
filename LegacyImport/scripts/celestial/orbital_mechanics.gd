## OrbitalMechanics - Spacecraft Orbital Mechanics Calculator
## High-level API for calculating orbital elements, predicting positions,
## and computing escape velocities for spacecraft around celestial bodies.
##
## This class provides a simplified interface to OrbitCalculator specifically
## designed for spacecraft orbital mechanics calculations.
##
## Key Formulas:
## - Orbital velocity: v = sqrt(μ/r) for circular orbits
## - Escape velocity: v_esc = sqrt(2μ/r)
## - Orbital period: T = 2π√(a³/μ) (Kepler's third law)
## - Vis-viva equation: v² = μ(2/r - 1/a)
## - Specific orbital energy: ε = -μ/(2a)
## - Semi-major axis: a = -μ/(2ε) where ε = v²/2 - μ/r
## - Eccentricity: e = |v × h|/μ - r/|r| where h = r × v
##
## Requirements: 6.4, 7.1-7.5, 9.1, 14.4
extends RefCounted
class_name OrbitalMechanics

## Gravitational constant (scaled for game units, matches CelestialBody.G)
const G: float = 6.674e-23

## Numerical precision tolerance
const EPSILON: float = 1e-10

## Minimum distance for calculations to prevent division by zero
const MIN_DISTANCE: float = 0.001

## Reference to orbit calculator for detailed calculations
var _orbit_calculator: OrbitCalculator = OrbitCalculator.new()


#region Primary API Methods

## Calculate orbital elements from spacecraft state
## Input:
##   - spacecraft_position: Current position vector of spacecraft
##   - spacecraft_velocity: Current velocity vector of spacecraft
##   - central_body: The CelestialBody being orbited
## Output:
##   - OrbitalElements structure containing:
##     * semi_major_axis: Average orbital radius
##     * eccentricity: Orbital shape (0=circular, <1=elliptical)
##     * inclination: Angle from reference plane
##     * longitude_ascending_node: Where orbit crosses reference plane
##     * argument_of_periapsis: Direction to closest approach
##     * mean_anomaly_at_epoch: Position in orbit at current time
##
## Formula: Uses state vector conversion (r, v) → (a, e, i, Ω, ω, M)
## where μ = G * M (standard gravitational parameter)
func calculate_orbit(spacecraft_position: Vector3, spacecraft_velocity: Vector3,
					central_body: CelestialBody) -> OrbitCalculator.OrbitalElements:
	"""Calculate orbital elements from spacecraft position and velocity."""
	if not is_instance_valid(central_body):
		push_error("OrbitalMechanics: Invalid central body")
		return OrbitCalculator.OrbitalElements.new()

	# Convert to relative position (spacecraft position relative to central body)
	var relative_position = spacecraft_position - central_body.global_position

	# Calculate standard gravitational parameter: μ = G * M
	var mu = G * central_body.mass

	# Use orbit calculator to convert state vectors to orbital elements
	var elements = _orbit_calculator.elements_from_state_vectors(
		relative_position,
		spacecraft_velocity,
		mu,
		Time.get_ticks_msec() / 1000.0  # Current time in seconds
	)

	return elements


## Predict future position and velocity from orbital elements
## Input:
##   - elements: OrbitalElements structure
##   - time_offset: Time delta from current epoch (can be positive or negative)
## Output:
##   - StateVector containing predicted position and velocity
##
## Formula: Uses Kepler's equation M = E - e·sin(E)
## where M = mean anomaly, E = eccentric anomaly, e = eccentricity
## Position calculated via perifocal → inertial coordinate transform
func predict_position(elements: OrbitCalculator.OrbitalElements, time_offset: float) -> OrbitCalculator.StateVector:
	"""Predict future position and velocity from orbital elements."""
	if not _orbit_calculator.validate_orbital_elements(elements):
		push_warning("OrbitalMechanics: Invalid orbital elements for prediction")
		return OrbitCalculator.StateVector.new()

	# Calculate target time
	var target_time = elements.epoch + time_offset

	# Use orbit calculator to compute state vector at target time
	var state = _orbit_calculator.calculate_state_vector(elements, target_time)

	return state


## Calculate escape velocity at spacecraft's current position
## Input:
##   - spacecraft_position: Current position vector of spacecraft
##   - central_body: The CelestialBody to escape from
## Output:
##   - Minimum velocity magnitude required to escape (float)
##
## Formula: v_esc = √(2μ/r) where μ = G*M, r = distance from body center
## This is derived from energy conservation: KE + PE = 0 at escape
## (1/2)mv² - GMm/r = 0 → v = √(2GM/r)
func escape_velocity(spacecraft_position: Vector3, central_body: CelestialBody) -> float:
	"""Calculate escape velocity at spacecraft's current position."""
	if not is_instance_valid(central_body):
		push_error("OrbitalMechanics: Invalid central body")
		return 0.0

	# Calculate distance from spacecraft to central body
	var distance = (spacecraft_position - central_body.global_position).length()

	# Ensure minimum distance to prevent division by zero
	if distance < MIN_DISTANCE:
		distance = MIN_DISTANCE

	# Ensure distance is at least the body's radius
	if distance < central_body.radius:
		distance = central_body.radius

	# Calculate standard gravitational parameter: μ = G * M
	var mu = G * central_body.mass

	# Escape velocity: v_esc = sqrt(2 * μ / r)
	return sqrt(2.0 * mu / distance)


## Calculate orbital period from orbital elements
## Input:
##   - elements: OrbitalElements structure
## Output:
##   - Orbital period in seconds (float)
##
## Formula: T = 2π√(a³/μ) (Kepler's third law)
## where a = semi-major axis, μ = G*M
## This relates orbital period to orbital size for all orbits around same body
func orbital_period(elements: OrbitCalculator.OrbitalElements) -> float:
	"""Calculate orbital period from elements."""
	if not _orbit_calculator.validate_orbital_elements(elements):
		push_warning("OrbitalMechanics: Invalid orbital elements")
		return INF

	# Use orbit calculator's period calculation
	return _orbit_calculator.calculate_orbital_period(elements)

#endregion


#region Additional Orbital Properties

## Calculate specific orbital energy
## Formula: ε = v²/2 - μ/r = -μ/(2a)
## This value is constant throughout the orbit (energy conservation)
func calculate_specific_energy(spacecraft_position: Vector3, spacecraft_velocity: Vector3,
								central_body: CelestialBody) -> float:
	"""Calculate specific orbital energy from current state."""
	if not is_instance_valid(central_body):
		return 0.0

	var relative_position = spacecraft_position - central_body.global_position
	var mu = G * central_body.mass

	return _orbit_calculator.calculate_energy_from_state(relative_position, spacecraft_velocity, mu)


## Calculate periapsis distance (closest approach)
## Formula: r_p = a(1 - e) where a = semi-major axis, e = eccentricity
func calculate_periapsis_distance(elements: OrbitCalculator.OrbitalElements) -> float:
	"""Calculate periapsis (closest approach) distance."""
	return _orbit_calculator.calculate_periapsis(elements)


## Calculate apoapsis distance (farthest point)
## Formula: r_a = a(1 + e) where a = semi-major axis, e = eccentricity
func calculate_apoapsis_distance(elements: OrbitCalculator.OrbitalElements) -> float:
	"""Calculate apoapsis (farthest point) distance."""
	return _orbit_calculator.calculate_apoapsis(elements)


## Calculate velocity at periapsis
## Formula: v_p = √(μ(1 + e)/a(1 - e)) using vis-viva equation
func calculate_periapsis_velocity(elements: OrbitCalculator.OrbitalElements) -> float:
	"""Calculate velocity at periapsis."""
	var r_p = calculate_periapsis_distance(elements)
	return _orbit_calculator.calculate_velocity_at_radius(elements, r_p)


## Calculate velocity at apoapsis
## Formula: v_a = √(μ(1 - e)/a(1 + e)) using vis-viva equation
func calculate_apoapsis_velocity(elements: OrbitCalculator.OrbitalElements) -> float:
	"""Calculate velocity at apoapsis."""
	var r_a = calculate_apoapsis_distance(elements)
	return _orbit_calculator.calculate_velocity_at_radius(elements, r_a)


## Calculate circular orbit velocity at current distance
## Formula: v_circ = √(μ/r)
## This is the velocity needed for a circular orbit at distance r
func calculate_circular_orbit_velocity(spacecraft_position: Vector3, central_body: CelestialBody) -> float:
	"""Calculate velocity for circular orbit at current distance."""
	if not is_instance_valid(central_body):
		return 0.0

	var distance = (spacecraft_position - central_body.global_position).length()
	if distance < MIN_DISTANCE:
		distance = MIN_DISTANCE
	if distance < central_body.radius:
		distance = central_body.radius

	return central_body.calculate_circular_orbit_velocity(distance)


## Calculate angular momentum magnitude
## Formula: h = |r × v| (specific angular momentum)
## This value is constant throughout the orbit
func calculate_angular_momentum(spacecraft_position: Vector3, spacecraft_velocity: Vector3,
								central_body: CelestialBody) -> float:
	"""Calculate specific angular momentum magnitude."""
	var relative_position = spacecraft_position - central_body.global_position
	var h_vec = relative_position.cross(spacecraft_velocity)
	return h_vec.length()


## Check if spacecraft is on escape trajectory
## Returns true if orbital energy is positive (unbound orbit)
func is_escape_trajectory(spacecraft_position: Vector3, spacecraft_velocity: Vector3,
						  central_body: CelestialBody) -> bool:
	"""Check if spacecraft is on an escape trajectory."""
	var energy = calculate_specific_energy(spacecraft_position, spacecraft_velocity, central_body)
	return energy >= 0.0


## Check if spacecraft will collide with body on current trajectory
## Returns true if periapsis is less than body radius
func will_collide(elements: OrbitCalculator.OrbitalElements, central_body: CelestialBody) -> bool:
	"""Check if orbit will result in collision with central body."""
	if not is_instance_valid(central_body):
		return false

	var periapsis = calculate_periapsis_distance(elements)
	return periapsis < central_body.radius

#endregion


#region Trajectory Prediction and Analysis

## Predict trajectory positions over a time period
## Input:
##   - spacecraft_position: Current position
##   - spacecraft_velocity: Current velocity
##   - central_body: Body being orbited
##   - duration: Time period to predict (seconds)
##   - steps: Number of points to calculate
## Output:
##   - Array of Vector3 positions at each time step
func predict_trajectory(spacecraft_position: Vector3, spacecraft_velocity: Vector3,
						central_body: CelestialBody, duration: float, steps: int = 100) -> Array[Vector3]:
	"""Predict spacecraft trajectory over a time period."""
	if not is_instance_valid(central_body):
		push_error("OrbitalMechanics: Invalid central body")
		return []

	var relative_position = spacecraft_position - central_body.global_position
	var mu = G * central_body.mass

	var initial_state = OrbitCalculator.StateVector.new(
		relative_position,
		spacecraft_velocity,
		Time.get_ticks_msec() / 1000.0
	)

	var trajectory = _orbit_calculator.predict_trajectory(initial_state, mu, duration, steps)

	# Convert back to absolute positions
	var absolute_trajectory: Array[Vector3] = []
	for pos in trajectory:
		absolute_trajectory.append(pos + central_body.global_position)

	return absolute_trajectory


## Predict trajectory with full state vectors (position and velocity)
func predict_trajectory_states(spacecraft_position: Vector3, spacecraft_velocity: Vector3,
							   central_body: CelestialBody, duration: float,
							   steps: int = 100) -> Array[OrbitCalculator.StateVector]:
	"""Predict spacecraft trajectory with velocity information."""
	if not is_instance_valid(central_body):
		push_error("OrbitalMechanics: Invalid central body")
		return []

	var relative_position = spacecraft_position - central_body.global_position
	var mu = G * central_body.mass

	var initial_state = OrbitCalculator.StateVector.new(
		relative_position,
		spacecraft_velocity,
		Time.get_ticks_msec() / 1000.0
	)

	var trajectory = _orbit_calculator.predict_trajectory_states(initial_state, mu, duration, steps)

	# Convert back to absolute positions
	var absolute_trajectory: Array[OrbitCalculator.StateVector] = []
	for state in trajectory:
		var absolute_state = OrbitCalculator.StateVector.new(
			state.position + central_body.global_position,
			state.velocity,
			state.time
		)
		absolute_trajectory.append(absolute_state)

	return absolute_trajectory


## Calculate time until periapsis passage
## Returns time in seconds until next periapsis (closest approach)
func time_to_periapsis(elements: OrbitCalculator.OrbitalElements, current_time: float = -1.0) -> float:
	"""Calculate time until next periapsis passage."""
	if current_time < 0:
		current_time = Time.get_ticks_msec() / 1000.0

	var period = orbital_period(elements)
	if period == INF:
		return INF

	# Calculate mean motion
	var mean_motion = _orbit_calculator.calculate_mean_motion(elements.semi_major_axis, elements.mu)
	var dt = current_time - elements.epoch
	var mean_anomaly = elements.mean_anomaly_at_epoch + mean_motion * dt

	# Normalize to [0, TAU)
	mean_anomaly = fmod(mean_anomaly, TAU)
	if mean_anomaly < 0:
		mean_anomaly += TAU

	# Time to periapsis is when mean anomaly = 0
	if mean_anomaly == 0:
		return 0.0
	else:
		return (TAU - mean_anomaly) / mean_motion


## Calculate time until apoapsis passage
## Returns time in seconds until next apoapsis (farthest point)
func time_to_apoapsis(elements: OrbitCalculator.OrbitalElements, current_time: float = -1.0) -> float:
	"""Calculate time until next apoapsis passage."""
	if current_time < 0:
		current_time = Time.get_ticks_msec() / 1000.0

	var period = orbital_period(elements)
	if period == INF:
		return INF

	# Calculate mean motion
	var mean_motion = _orbit_calculator.calculate_mean_motion(elements.semi_major_axis, elements.mu)
	var dt = current_time - elements.epoch
	var mean_anomaly = elements.mean_anomaly_at_epoch + mean_motion * dt

	# Normalize to [0, TAU)
	mean_anomaly = fmod(mean_anomaly, TAU)
	if mean_anomaly < 0:
		mean_anomaly += TAU

	# Time to apoapsis is when mean anomaly = PI
	var target_anomaly = PI
	var time_to_target: float

	if mean_anomaly < target_anomaly:
		time_to_target = (target_anomaly - mean_anomaly) / mean_motion
	else:
		time_to_target = (TAU - mean_anomaly + target_anomaly) / mean_motion

	return time_to_target

#endregion


#region Delta-V Calculations

## Calculate delta-v required for Hohmann transfer to target radius
## Formula (simplified for circular orbits):
## Δv₁ = √(μ/r₁) * (√(2r₂/(r₁+r₂)) - 1) at departure
## Δv₂ = √(μ/r₂) * (1 - √(2r₁/(r₁+r₂))) at arrival
func calculate_hohmann_transfer_dv(current_radius: float, target_radius: float, mu: float) -> Dictionary:
	"""Calculate delta-v for Hohmann transfer orbit."""
	if current_radius < MIN_DISTANCE or target_radius < MIN_DISTANCE or mu < EPSILON:
		return {"departure_dv": 0.0, "arrival_dv": 0.0, "total_dv": 0.0, "transfer_time": 0.0}

	# Circular velocities
	var v1 = sqrt(mu / current_radius)
	var v2 = sqrt(mu / target_radius)

	# Transfer orbit semi-major axis
	var a_transfer = (current_radius + target_radius) / 2.0

	# Velocities at periapsis and apoapsis of transfer orbit
	var v_peri = sqrt(mu * (2.0 / current_radius - 1.0 / a_transfer))
	var v_apo = sqrt(mu * (2.0 / target_radius - 1.0 / a_transfer))

	# Delta-v requirements
	var dv1 = abs(v_peri - v1)  # At departure
	var dv2 = abs(v2 - v_apo)    # At arrival

	# Transfer time (half orbit period of transfer ellipse)
	var transfer_time = PI * sqrt(pow(a_transfer, 3) / mu)

	return {
		"departure_dv": dv1,
		"arrival_dv": dv2,
		"total_dv": dv1 + dv2,
		"transfer_time": transfer_time
	}


## Calculate delta-v required to circularize orbit at current position
func calculate_circularization_dv(spacecraft_position: Vector3, spacecraft_velocity: Vector3,
								  central_body: CelestialBody) -> float:
	"""Calculate delta-v needed to circularize orbit at current position."""
	if not is_instance_valid(central_body):
		return 0.0

	var current_speed = spacecraft_velocity.length()
	var circular_speed = calculate_circular_orbit_velocity(spacecraft_position, central_body)

	return abs(circular_speed - current_speed)

#endregion


#region Utility Methods

## Get orbital information as a formatted dictionary
func get_orbital_info(elements: OrbitCalculator.OrbitalElements) -> Dictionary:
	"""Get comprehensive orbital information."""
	return {
		"semi_major_axis": elements.semi_major_axis,
		"eccentricity": elements.eccentricity,
		"inclination_deg": rad_to_deg(elements.inclination),
		"inclination_rad": elements.inclination,
		"longitude_ascending_node_deg": rad_to_deg(elements.longitude_ascending_node),
		"argument_of_periapsis_deg": rad_to_deg(elements.argument_of_periapsis),
		"period_seconds": orbital_period(elements),
		"periapsis_distance": calculate_periapsis_distance(elements),
		"apoapsis_distance": calculate_apoapsis_distance(elements),
		"periapsis_velocity": calculate_periapsis_velocity(elements),
		"apoapsis_velocity": calculate_apoapsis_velocity(elements),
		"specific_energy": _orbit_calculator.calculate_specific_energy(elements),
		"is_elliptical": _orbit_calculator.is_elliptical_orbit(elements)
	}


## Verify energy conservation between two states
## Returns relative error (should be < 0.0001 for 0.01% tolerance per Requirement 14.4)
func verify_energy_conservation(state1: OrbitCalculator.StateVector, state2: OrbitCalculator.StateVector,
								mu: float) -> float:
	"""Verify energy conservation between states."""
	return _orbit_calculator.verify_energy_conservation(state1, state2, mu)

#endregion
