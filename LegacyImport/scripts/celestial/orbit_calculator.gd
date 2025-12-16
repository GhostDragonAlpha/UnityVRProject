## OrbitCalculator - Keplerian Orbital Mechanics Calculator
## Calculates orbital mechanics using Keplerian elements for accurate
## celestial body positioning and trajectory prediction.
##
## Requirements: 6.4, 7.1, 7.2, 7.3, 7.4, 7.5, 14.4
## - 6.4: Slow down celestial body movements proportionally (time dilation)
## - 7.1-7.5: Support for relativistic effects (Doppler shift, Lorentz contraction)
## - 14.4: Maintain conservation of energy within 0.01% error tolerance
extends RefCounted
class_name OrbitCalculator

## J2000.0 epoch in Julian Date (January 1, 2000, 12:00 TT)
const J2000_EPOCH: float = 2451545.0

## Gravitational constant (scaled for game units, same as CelestialBody.G)
const G: float = 6.674e-23

## Numerical precision tolerance for calculations
const EPSILON: float = 1e-10

## Maximum iterations for Kepler's equation solver
const MAX_KEPLER_ITERATIONS: int = 50

## Convergence tolerance for Kepler's equation
const KEPLER_TOLERANCE: float = 1e-12

## Minimum eccentricity for elliptical orbit calculations
const MIN_ECCENTRICITY: float = 0.0

## Maximum eccentricity for elliptical orbits (< 1.0)
const MAX_ECCENTRICITY: float = 0.9999

## Minimum semi-major axis
const MIN_SEMI_MAJOR_AXIS: float = 0.001


#region Data Structures

## Orbital elements structure (Keplerian elements)
## All angles are in radians
class OrbitalElements:
	## Semi-major axis (game units)
	var semi_major_axis: float = 1.0
	## Eccentricity (0 = circular, 0-1 = elliptical)
	var eccentricity: float = 0.0
	## Inclination (radians, 0 = equatorial)
	var inclination: float = 0.0
	## Longitude of ascending node (radians)
	var longitude_ascending_node: float = 0.0
	## Argument of periapsis (radians)
	var argument_of_periapsis: float = 0.0
	## Mean anomaly at epoch (radians)
	var mean_anomaly_at_epoch: float = 0.0
	## Epoch time (Julian Date or simulation time)
	var epoch: float = J2000_EPOCH
	## Standard gravitational parameter (G * M of central body)
	var mu: float = 1.0
	
	func _init(a: float = 1.0, e: float = 0.0, i: float = 0.0, 
			   omega_big: float = 0.0, omega_small: float = 0.0, 
			   m0: float = 0.0, t0: float = J2000_EPOCH, gm: float = 1.0) -> void:
		semi_major_axis = a
		eccentricity = e
		inclination = i
		longitude_ascending_node = omega_big
		argument_of_periapsis = omega_small
		mean_anomaly_at_epoch = m0
		epoch = t0
		mu = gm
	
	func duplicate() -> OrbitalElements:
		return OrbitalElements.new(
			semi_major_axis, eccentricity, inclination,
			longitude_ascending_node, argument_of_periapsis,
			mean_anomaly_at_epoch, epoch, mu
		)
	
	func to_dictionary() -> Dictionary:
		return {
			"semi_major_axis": semi_major_axis,
			"eccentricity": eccentricity,
			"inclination": inclination,
			"longitude_ascending_node": longitude_ascending_node,
			"argument_of_periapsis": argument_of_periapsis,
			"mean_anomaly_at_epoch": mean_anomaly_at_epoch,
			"epoch": epoch,
			"mu": mu
		}
	
	static func from_dictionary(data: Dictionary) -> OrbitalElements:
		return OrbitalElements.new(
			data.get("semi_major_axis", 1.0),
			data.get("eccentricity", 0.0),
			data.get("inclination", 0.0),
			data.get("longitude_ascending_node", 0.0),
			data.get("argument_of_periapsis", 0.0),
			data.get("mean_anomaly_at_epoch", 0.0),
			data.get("epoch", J2000_EPOCH),
			data.get("mu", 1.0)
		)


## State vector structure (position and velocity at a time)
class StateVector:
	var position: Vector3 = Vector3.ZERO
	var velocity: Vector3 = Vector3.ZERO
	var time: float = 0.0
	
	func _init(pos: Vector3 = Vector3.ZERO, vel: Vector3 = Vector3.ZERO, t: float = 0.0) -> void:
		position = pos
		velocity = vel
		time = t
	
	func duplicate() -> StateVector:
		return StateVector.new(position, velocity, time)
	
	func to_dictionary() -> Dictionary:
		return {
			"position": position,
			"velocity": velocity,
			"time": time
		}
	
	static func from_dictionary(data: Dictionary) -> StateVector:
		return StateVector.new(
			data.get("position", Vector3.ZERO),
			data.get("velocity", Vector3.ZERO),
			data.get("time", 0.0)
		)

#endregion


#region Position and Velocity Calculations

## Calculate position from orbital elements at a given time
## Requirement 14.4: Uses Keplerian orbital elements for accurate positioning
func calculate_position(elements: OrbitalElements, time: float) -> Vector3:
	"""Calculate the position vector from orbital elements at a given time."""
	if not validate_orbital_elements(elements):
		push_warning("OrbitCalculator: Invalid orbital elements")
		return Vector3.ZERO
	
	# Calculate mean anomaly at the given time
	var mean_motion = calculate_mean_motion(elements.semi_major_axis, elements.mu)
	var dt = time - elements.epoch
	var mean_anomaly = elements.mean_anomaly_at_epoch + mean_motion * dt
	
	# Normalize mean anomaly to [0, 2π)
	mean_anomaly = fmod(mean_anomaly, TAU)
	if mean_anomaly < 0:
		mean_anomaly += TAU
	
	# Solve Kepler's equation to get eccentric anomaly
	var eccentric_anomaly = solve_kepler_equation(mean_anomaly, elements.eccentricity)
	
	# Calculate true anomaly from eccentric anomaly
	var true_anomaly = calculate_true_anomaly(eccentric_anomaly, elements.eccentricity)
	
	# Calculate distance from focus (radius)
	var radius = calculate_radius(elements.semi_major_axis, elements.eccentricity, true_anomaly)
	
	# Calculate position in orbital plane (perifocal coordinates)
	var x_orbital = radius * cos(true_anomaly)
	var y_orbital = radius * sin(true_anomaly)
	
	# Transform to 3D coordinates using orbital elements
	return transform_to_inertial(x_orbital, y_orbital, elements)


## Calculate velocity from orbital elements at a given time
## Requirement 14.4: Accurate velocity calculation for orbital mechanics
func calculate_velocity(elements: OrbitalElements, time: float) -> Vector3:
	"""Calculate the velocity vector from orbital elements at a given time."""
	if not validate_orbital_elements(elements):
		push_warning("OrbitCalculator: Invalid orbital elements")
		return Vector3.ZERO
	
	# Calculate mean anomaly at the given time
	var mean_motion = calculate_mean_motion(elements.semi_major_axis, elements.mu)
	var dt = time - elements.epoch
	var mean_anomaly = elements.mean_anomaly_at_epoch + mean_motion * dt
	
	# Normalize mean anomaly
	mean_anomaly = fmod(mean_anomaly, TAU)
	if mean_anomaly < 0:
		mean_anomaly += TAU
	
	# Solve Kepler's equation
	var eccentric_anomaly = solve_kepler_equation(mean_anomaly, elements.eccentricity)
	
	# Calculate true anomaly
	var true_anomaly = calculate_true_anomaly(eccentric_anomaly, elements.eccentricity)
	
	# Calculate semi-latus rectum
	var p = elements.semi_major_axis * (1.0 - elements.eccentricity * elements.eccentricity)
	
	# Calculate velocity magnitude factor
	var h = sqrt(elements.mu * p)  # Specific angular momentum
	
	# Velocity components in orbital plane
	var vx_orbital = -elements.mu / h * sin(true_anomaly)
	var vy_orbital = elements.mu / h * (elements.eccentricity + cos(true_anomaly))
	
	# Transform to 3D coordinates
	return transform_velocity_to_inertial(vx_orbital, vy_orbital, elements)


## Calculate both position and velocity (state vector) at a given time
func calculate_state_vector(elements: OrbitalElements, time: float) -> StateVector:
	"""Calculate the complete state vector from orbital elements."""
	var pos = calculate_position(elements, time)
	var vel = calculate_velocity(elements, time)
	return StateVector.new(pos, vel, time)

#endregion


#region State Vector to Orbital Elements Conversion

## Convert state vectors (position, velocity) to orbital elements
## Requirement 14.4: Bidirectional conversion for accurate orbital mechanics
func elements_from_state_vectors(pos: Vector3, vel: Vector3, mu: float, time: float = 0.0) -> OrbitalElements:
	"""Convert position and velocity vectors to Keplerian orbital elements."""
	var elements = OrbitalElements.new()
	elements.mu = mu
	elements.epoch = time
	
	# Handle degenerate case
	if pos.length_squared() < EPSILON or mu < EPSILON:
		push_warning("OrbitCalculator: Degenerate state vectors")
		return elements
	
	var r = pos.length()
	var v = vel.length()
	
	# Specific angular momentum vector: h = r × v
	var h_vec = pos.cross(vel)
	var h = h_vec.length()
	
	# Handle radial or near-radial orbits
	if h < EPSILON:
		push_warning("OrbitCalculator: Near-radial orbit detected")
		# Return a degenerate orbit
		elements.semi_major_axis = r
		elements.eccentricity = 0.999
		return elements
	
	# Node vector: n = k × h (k is unit vector in z direction)
	var k = Vector3(0, 0, 1)
	var n_vec = k.cross(h_vec)
	var n = n_vec.length()
	
	# Eccentricity vector: e = (v × h) / μ - r / |r|
	var e_vec = vel.cross(h_vec) / mu - pos / r
	var e = e_vec.length()
	
	# Clamp eccentricity to valid range
	e = clampf(e, MIN_ECCENTRICITY, MAX_ECCENTRICITY)
	elements.eccentricity = e
	
	# Specific orbital energy: ε = v²/2 - μ/r
	var energy = v * v / 2.0 - mu / r
	
	# Semi-major axis: a = -μ / (2ε)
	if absf(energy) > EPSILON:
		elements.semi_major_axis = -mu / (2.0 * energy)
	else:
		# Parabolic orbit (energy ≈ 0)
		elements.semi_major_axis = INF
	
	# Ensure positive semi-major axis for elliptical orbits
	if elements.semi_major_axis < MIN_SEMI_MAJOR_AXIS:
		elements.semi_major_axis = MIN_SEMI_MAJOR_AXIS
	
	# Inclination: i = arccos(h_z / |h|)
	elements.inclination = acos(clampf(h_vec.z / h, -1.0, 1.0))
	
	# Longitude of ascending node: Ω
	if n > EPSILON:
		elements.longitude_ascending_node = acos(clampf(n_vec.x / n, -1.0, 1.0))
		if n_vec.y < 0:
			elements.longitude_ascending_node = TAU - elements.longitude_ascending_node
	else:
		# Equatorial orbit - ascending node undefined
		elements.longitude_ascending_node = 0.0
	
	# Argument of periapsis: ω
	if n > EPSILON and e > EPSILON:
		var cos_omega = n_vec.dot(e_vec) / (n * e)
		elements.argument_of_periapsis = acos(clampf(cos_omega, -1.0, 1.0))
		if e_vec.z < 0:
			elements.argument_of_periapsis = TAU - elements.argument_of_periapsis
	else:
		# Circular or equatorial orbit
		elements.argument_of_periapsis = 0.0
	
	# True anomaly: ν
	var true_anomaly: float
	if e > EPSILON:
		var cos_nu = e_vec.dot(pos) / (e * r)
		true_anomaly = acos(clampf(cos_nu, -1.0, 1.0))
		if pos.dot(vel) < 0:
			true_anomaly = TAU - true_anomaly
	else:
		# Circular orbit - use argument of latitude
		if n > EPSILON:
			var cos_u = n_vec.dot(pos) / (n * r)
			true_anomaly = acos(clampf(cos_u, -1.0, 1.0))
			if pos.z < 0:
				true_anomaly = TAU - true_anomaly
		else:
			# Equatorial circular orbit - use true longitude
			true_anomaly = atan2(pos.y, pos.x)
			if true_anomaly < 0:
				true_anomaly += TAU
	
	# Convert true anomaly to mean anomaly
	var eccentric_anomaly = calculate_eccentric_anomaly_from_true(true_anomaly, e)
	elements.mean_anomaly_at_epoch = calculate_mean_anomaly_from_eccentric(eccentric_anomaly, e)
	
	return elements

#endregion


#region Trajectory Prediction

## Predict trajectory over a duration
## Requirement 14.4: Trajectory prediction for orbital mechanics
## Property 18: Trajectory Prediction Accuracy
func predict_trajectory(initial_state: StateVector, mu: float, duration: float, steps: int) -> Array[Vector3]:
	"""Predict trajectory positions over a given duration."""
	var trajectory: Array[Vector3] = []
	
	if steps < 2:
		steps = 2
	
	# Convert initial state to orbital elements
	var elements = elements_from_state_vectors(
		initial_state.position, 
		initial_state.velocity, 
		mu, 
		initial_state.time
	)
	
	# Calculate positions at each time step
	var dt = duration / float(steps - 1)
	for i in range(steps):
		var t = initial_state.time + dt * i
		var pos = calculate_position(elements, t)
		trajectory.append(pos)
	
	return trajectory


## Predict trajectory with full state vectors
func predict_trajectory_states(initial_state: StateVector, mu: float, duration: float, steps: int) -> Array[StateVector]:
	"""Predict trajectory with full state vectors (position and velocity)."""
	var trajectory: Array[StateVector] = []
	
	if steps < 2:
		steps = 2
	
	# Convert initial state to orbital elements
	var elements = elements_from_state_vectors(
		initial_state.position, 
		initial_state.velocity, 
		mu, 
		initial_state.time
	)
	
	# Calculate state vectors at each time step
	var dt = duration / float(steps - 1)
	for i in range(steps):
		var t = initial_state.time + dt * i
		var state = calculate_state_vector(elements, t)
		trajectory.append(state)
	
	return trajectory

#endregion


#region Validation

## Validate orbital elements are within physical constraints
func validate_orbital_elements(elements: OrbitalElements) -> bool:
	"""Validate that orbital elements are physically valid."""
	# Check semi-major axis
	if elements.semi_major_axis < MIN_SEMI_MAJOR_AXIS:
		return false
	
	# Check eccentricity (must be 0 <= e < 1 for elliptical orbits)
	if elements.eccentricity < MIN_ECCENTRICITY or elements.eccentricity >= 1.0:
		return false
	
	# Check inclination (0 to π)
	if elements.inclination < 0 or elements.inclination > PI:
		return false
	
	# Check gravitational parameter
	if elements.mu <= 0:
		return false
	
	return true


## Check if orbit is valid (not hyperbolic or parabolic)
func is_elliptical_orbit(elements: OrbitalElements) -> bool:
	"""Check if the orbit is elliptical (bound orbit)."""
	return elements.eccentricity >= 0 and elements.eccentricity < 1.0

#endregion


#region Orbital Properties

## Calculate orbital period
func calculate_orbital_period(elements: OrbitalElements) -> float:
	"""Calculate the orbital period in time units."""
	if not validate_orbital_elements(elements):
		return INF
	
	# T = 2π * sqrt(a³ / μ)
	return TAU * sqrt(pow(elements.semi_major_axis, 3) / elements.mu)


## Calculate mean motion (angular velocity)
func calculate_mean_motion(semi_major_axis: float, mu: float) -> float:
	"""Calculate mean motion (radians per time unit)."""
	if semi_major_axis <= 0 or mu <= 0:
		return 0.0
	
	# n = sqrt(μ / a³)
	return sqrt(mu / pow(semi_major_axis, 3))


## Calculate periapsis distance
func calculate_periapsis(elements: OrbitalElements) -> float:
	"""Calculate the periapsis (closest approach) distance."""
	return elements.semi_major_axis * (1.0 - elements.eccentricity)


## Calculate apoapsis distance
func calculate_apoapsis(elements: OrbitalElements) -> float:
	"""Calculate the apoapsis (farthest point) distance."""
	return elements.semi_major_axis * (1.0 + elements.eccentricity)


## Calculate specific orbital energy
func calculate_specific_energy(elements: OrbitalElements) -> float:
	"""Calculate specific orbital energy (energy per unit mass)."""
	# ε = -μ / (2a)
	return -elements.mu / (2.0 * elements.semi_major_axis)


## Calculate specific angular momentum
func calculate_specific_angular_momentum(elements: OrbitalElements) -> float:
	"""Calculate specific angular momentum magnitude."""
	# h = sqrt(μ * a * (1 - e²))
	var p = elements.semi_major_axis * (1.0 - elements.eccentricity * elements.eccentricity)
	return sqrt(elements.mu * p)


## Calculate velocity at a given radius (vis-viva equation)
func calculate_velocity_at_radius(elements: OrbitalElements, radius: float) -> float:
	"""Calculate orbital velocity at a given radius using vis-viva equation."""
	if radius <= 0:
		return 0.0
	
	# v² = μ * (2/r - 1/a)
	var v_squared = elements.mu * (2.0 / radius - 1.0 / elements.semi_major_axis)
	if v_squared < 0:
		return 0.0
	
	return sqrt(v_squared)

#endregion


#region Energy Conservation

## Calculate total specific orbital energy from state vector
## Requirement 14.4: Maintain conservation of energy within 0.01% error tolerance
func calculate_energy_from_state(pos: Vector3, vel: Vector3, mu: float) -> float:
	"""Calculate specific orbital energy from position and velocity."""
	var r = pos.length()
	var v = vel.length()
	
	if r < EPSILON:
		return 0.0
	
	# ε = v²/2 - μ/r
	return v * v / 2.0 - mu / r


## Verify energy conservation between two states
## Returns the relative error in energy
func verify_energy_conservation(state1: StateVector, state2: StateVector, mu: float) -> float:
	"""Verify energy conservation between two states. Returns relative error."""
	var energy1 = calculate_energy_from_state(state1.position, state1.velocity, mu)
	var energy2 = calculate_energy_from_state(state2.position, state2.velocity, mu)
	
	if absf(energy1) < EPSILON:
		return absf(energy2 - energy1)
	
	return absf((energy2 - energy1) / energy1)

#endregion


#region Private Helper Methods

## Solve Kepler's equation: M = E - e * sin(E)
## Uses Newton-Raphson iteration
func solve_kepler_equation(mean_anomaly: float, eccentricity: float) -> float:
	"""Solve Kepler's equation for eccentric anomaly."""
	# Initial guess
	var E = mean_anomaly
	if eccentricity > 0.8:
		E = PI  # Better initial guess for high eccentricity
	
	# Newton-Raphson iteration
	for i in range(MAX_KEPLER_ITERATIONS):
		var f = E - eccentricity * sin(E) - mean_anomaly
		var f_prime = 1.0 - eccentricity * cos(E)
		
		if absf(f_prime) < EPSILON:
			break
		
		var delta = f / f_prime
		E -= delta
		
		if absf(delta) < KEPLER_TOLERANCE:
			break
	
	return E


## Calculate true anomaly from eccentric anomaly
func calculate_true_anomaly(eccentric_anomaly: float, eccentricity: float) -> float:
	"""Convert eccentric anomaly to true anomaly."""
	var beta = eccentricity / (1.0 + sqrt(1.0 - eccentricity * eccentricity))
	return eccentric_anomaly + 2.0 * atan(beta * sin(eccentric_anomaly) / (1.0 - beta * cos(eccentric_anomaly)))


## Calculate eccentric anomaly from true anomaly
func calculate_eccentric_anomaly_from_true(true_anomaly: float, eccentricity: float) -> float:
	"""Convert true anomaly to eccentric anomaly."""
	var cos_nu = cos(true_anomaly)
	var sin_nu = sin(true_anomaly)
	
	var sin_E = sin_nu * sqrt(1.0 - eccentricity * eccentricity) / (1.0 + eccentricity * cos_nu)
	var cos_E = (eccentricity + cos_nu) / (1.0 + eccentricity * cos_nu)
	
	return atan2(sin_E, cos_E)


## Calculate mean anomaly from eccentric anomaly
func calculate_mean_anomaly_from_eccentric(eccentric_anomaly: float, eccentricity: float) -> float:
	"""Convert eccentric anomaly to mean anomaly."""
	return eccentric_anomaly - eccentricity * sin(eccentric_anomaly)


## Calculate radius from orbital elements and true anomaly
func calculate_radius(semi_major_axis: float, eccentricity: float, true_anomaly: float) -> float:
	"""Calculate orbital radius at a given true anomaly."""
	var p = semi_major_axis * (1.0 - eccentricity * eccentricity)
	return p / (1.0 + eccentricity * cos(true_anomaly))


## Transform position from orbital plane to inertial coordinates
func transform_to_inertial(x_orbital: float, y_orbital: float, elements: OrbitalElements) -> Vector3:
	"""Transform position from perifocal to inertial coordinates."""
	var cos_omega = cos(elements.argument_of_periapsis)
	var sin_omega = sin(elements.argument_of_periapsis)
	var cos_Omega = cos(elements.longitude_ascending_node)
	var sin_Omega = sin(elements.longitude_ascending_node)
	var cos_i = cos(elements.inclination)
	var sin_i = sin(elements.inclination)
	
	# Rotation matrix elements
	var r11 = cos_Omega * cos_omega - sin_Omega * sin_omega * cos_i
	var r12 = -cos_Omega * sin_omega - sin_Omega * cos_omega * cos_i
	var r21 = sin_Omega * cos_omega + cos_Omega * sin_omega * cos_i
	var r22 = -sin_Omega * sin_omega + cos_Omega * cos_omega * cos_i
	var r31 = sin_omega * sin_i
	var r32 = cos_omega * sin_i
	
	return Vector3(
		r11 * x_orbital + r12 * y_orbital,
		r21 * x_orbital + r22 * y_orbital,
		r31 * x_orbital + r32 * y_orbital
	)


## Transform velocity from orbital plane to inertial coordinates
func transform_velocity_to_inertial(vx_orbital: float, vy_orbital: float, elements: OrbitalElements) -> Vector3:
	"""Transform velocity from perifocal to inertial coordinates."""
	# Same rotation matrix as position
	return transform_to_inertial(vx_orbital, vy_orbital, elements)

#endregion
