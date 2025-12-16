## RelativityManager - Relativistic Physics System
## Calculates time dilation, Lorentz factor, Doppler shift, and length contraction
## for realistic relativistic effects as velocity approaches the speed of light.
##
## Requirements: 6.1, 6.2, 7.1, 7.2, 7.3, 7.4, 7.5
## - 6.1: Calculate Lorentz factor using sqrt(1 - v²/c²)
## - 6.2: Scale world time by Lorentz factor for non-player objects
## - 7.1: Apply Doppler shift coloring to lattice grid
## - 7.2: Shift forward grid lines toward blue wavelengths
## - 7.3: Shift backward grid lines toward red wavelengths
## - 7.4: Apply Lorentz contraction by compressing geometry along travel direction
## - 7.5: Scale world geometry by Lorentz factor in direction of motion
extends Node
class_name RelativityManager

## Emitted when the Lorentz factor changes significantly
signal lorentz_factor_changed(new_factor: float)
## Emitted when time dilation state changes (active/inactive)
signal time_dilation_state_changed(is_active: bool)
## Emitted when velocity is clamped to prevent exceeding c
signal velocity_clamped(original_speed: float, clamped_speed: float)

## Speed of light constant in game units per second
## This defines the maximum information propagation rate through the lattice
const SPEED_OF_LIGHT: float = 1000.0

## Alias for SPEED_OF_LIGHT for convenience
const C: float = SPEED_OF_LIGHT

## Maximum velocity as a fraction of c (prevents division by zero in Lorentz calculation)
## Requirement 6.3: Clamp at 99% of c to prevent division by zero
const MAX_VELOCITY_FRACTION: float = 0.99

## Minimum Lorentz factor (corresponds to MAX_VELOCITY_FRACTION)
## gamma_min = sqrt(1 - 0.99²) ≈ 0.141
const MIN_LORENTZ_FACTOR: float = 0.141

## Threshold for considering time dilation "active" (gamma < 0.99)
const TIME_DILATION_THRESHOLD: float = 0.99

## Smoothing factor for time restoration when decelerating
## Requirement 6.5: Restore normal time flow within 0.5 seconds
const TIME_RESTORATION_RATE: float = 2.0  # 1/0.5 = 2.0 per second

## Current world time scale (affected by time dilation)
var world_time_scale: float = 1.0

## Current Lorentz factor (gamma)
## gamma = 1 at rest, approaches 0 as velocity approaches c
var lorentz_factor: float = 1.0

## Target Lorentz factor (for smooth transitions)
var _target_lorentz_factor: float = 1.0

## Current player velocity (set externally)
var _current_velocity: Vector3 = Vector3.ZERO

## Whether time dilation is currently active
var _time_dilation_active: bool = false

## Previous Lorentz factor for change detection
var _previous_lorentz_factor: float = 1.0

## Epsilon for floating-point comparisons
const EPSILON: float = 0.0001


func _ready() -> void:
	pass


## Update method called by the engine coordinator
func update(delta: float) -> void:
	_update_lorentz_factor(delta)
	_update_world_time_scale(delta)


## Set the current velocity for relativistic calculations
func set_velocity(velocity: Vector3) -> void:
	_current_velocity = velocity
	_target_lorentz_factor = calculate_lorentz_factor(velocity)


## Get the current velocity
func get_velocity() -> Vector3:
	return _current_velocity



## Calculate the Lorentz factor for a given velocity
## Requirement 6.1: gamma = sqrt(1 - v²/c²)
## Returns a value between MIN_LORENTZ_FACTOR and 1.0
func calculate_lorentz_factor(velocity: Vector3) -> float:
	var speed = velocity.length()
	return calculate_lorentz_factor_from_speed(speed)


## Calculate the Lorentz factor from a scalar speed value
## Requirement 6.1: gamma = sqrt(1 - v²/c²)
func calculate_lorentz_factor_from_speed(speed: float) -> float:
	# Clamp speed to prevent exceeding c
	var clamped_speed = clamp_speed(speed)
	
	# Calculate v²/c²
	var v_over_c_squared = (clamped_speed * clamped_speed) / (C * C)
	
	# Calculate gamma = sqrt(1 - v²/c²)
	# Clamp to prevent negative values due to floating-point errors
	var one_minus_v2_c2 = maxf(1.0 - v_over_c_squared, MIN_LORENTZ_FACTOR * MIN_LORENTZ_FACTOR)
	
	return sqrt(one_minus_v2_c2)


## Clamp velocity to prevent exceeding the speed of light
## Requirement 6.3: Clamp at 99% of c
func clamp_velocity(velocity: Vector3) -> Vector3:
	var speed = velocity.length()
	var max_speed = C * MAX_VELOCITY_FRACTION
	
	if speed > max_speed:
		velocity_clamped.emit(speed, max_speed)
		return velocity.normalized() * max_speed
	
	return velocity


## Clamp a scalar speed value to prevent exceeding c
func clamp_speed(speed: float) -> float:
	var max_speed = C * MAX_VELOCITY_FRACTION
	if speed > max_speed:
		return max_speed
	return speed


## Get the world delta time adjusted for time dilation
## Requirement 6.2: Scale world time by Lorentz factor
func get_world_dt(real_dt: float) -> float:
	return real_dt * lorentz_factor


## Get the current world time scale
func get_world_time_scale() -> float:
	return world_time_scale


## Get the current Lorentz factor
func get_lorentz_factor() -> float:
	return lorentz_factor


## Check if time dilation is currently active
func is_time_dilation_active() -> bool:
	return _time_dilation_active


## Calculate the Doppler shift factor for a given velocity and observation direction
## Requirement 7.1, 7.2, 7.3: Doppler shift for audio and visuals
## Returns a factor where:
##   > 1.0 = blueshift (approaching, higher frequency)
##   < 1.0 = redshift (receding, lower frequency)
##   = 1.0 = no shift (perpendicular motion)
func calculate_doppler_shift(velocity: Vector3, direction: Vector3) -> float:
	if velocity.length_squared() < EPSILON or direction.length_squared() < EPSILON:
		return 1.0
	
	# Normalize direction
	var dir_normalized = direction.normalized()
	
	# Calculate velocity component along the direction
	# Positive = moving toward the direction (blueshift)
	# Negative = moving away from the direction (redshift)
	var v_radial = velocity.dot(dir_normalized)
	
	# Relativistic Doppler formula:
	# f_observed / f_source = sqrt((1 + v/c) / (1 - v/c)) for approaching
	# We use the general formula: f_observed / f_source = gamma * (1 + v_radial/c)
	
	var v_over_c = v_radial / C
	
	# Clamp to prevent extreme values
	v_over_c = clampf(v_over_c, -MAX_VELOCITY_FRACTION, MAX_VELOCITY_FRACTION)
	
	# Classical Doppler factor (simplified for game purposes)
	# For approaching (positive v_radial): factor > 1 (blueshift)
	# For receding (negative v_radial): factor < 1 (redshift)
	var doppler_factor = 1.0 / (1.0 - v_over_c)
	
	# Apply relativistic correction using Lorentz factor
	doppler_factor *= lorentz_factor
	
	return doppler_factor


## Calculate the Doppler shift for forward direction (blueshift)
## Requirement 7.2: Shift forward grid lines toward blue wavelengths
func calculate_forward_doppler_shift(velocity: Vector3, forward_direction: Vector3) -> float:
	return calculate_doppler_shift(velocity, forward_direction)


## Calculate the Doppler shift for backward direction (redshift)
## Requirement 7.3: Shift backward grid lines toward red wavelengths
func calculate_backward_doppler_shift(velocity: Vector3, forward_direction: Vector3) -> float:
	return calculate_doppler_shift(velocity, -forward_direction)


## Calculate the length contraction factor along the direction of motion
## Requirement 7.4, 7.5: Lorentz contraction compresses geometry along travel direction
## Returns a factor between MIN_LORENTZ_FACTOR and 1.0
## Objects appear contracted by this factor in the direction of motion
func calculate_length_contraction(velocity: Vector3) -> float:
	# Length contraction factor is the same as the Lorentz factor
	# L = L_0 * gamma, where gamma = sqrt(1 - v²/c²)
	return calculate_lorentz_factor(velocity)


## Calculate the contracted length of an object
## Requirement 7.4: Apply Lorentz contraction
func calculate_contracted_length(rest_length: float, velocity: Vector3) -> float:
	var contraction_factor = calculate_length_contraction(velocity)
	return rest_length * contraction_factor


## Get the length contraction scale vector for rendering
## Requirement 7.5: Scale world geometry by Lorentz factor in direction of motion
## Returns a Vector3 scale where the direction of motion is contracted
func get_length_contraction_scale(velocity: Vector3) -> Vector3:
	if velocity.length_squared() < EPSILON:
		return Vector3.ONE
	
	var contraction_factor = calculate_length_contraction(velocity)
	var velocity_dir = velocity.normalized()
	
	# Create a scale vector that contracts along the velocity direction
	# We need to decompose into velocity direction and perpendicular
	# For simplicity, we return a scale that can be applied to objects
	
	# The contraction only applies along the direction of motion
	# Perpendicular dimensions remain unchanged
	
	# This returns a simplified scale - for full implementation,
	# you would need to apply a transformation matrix
	return Vector3(
		1.0 - (1.0 - contraction_factor) * abs(velocity_dir.x),
		1.0 - (1.0 - contraction_factor) * abs(velocity_dir.y),
		1.0 - (1.0 - contraction_factor) * abs(velocity_dir.z)
	)



## Convert a wavelength based on Doppler shift
## Useful for visual effects - shifts color based on velocity
func shift_wavelength(base_wavelength: float, doppler_factor: float) -> float:
	# Wavelength is inversely proportional to frequency
	# Higher doppler_factor = higher frequency = shorter wavelength (blueshift)
	return base_wavelength / doppler_factor


## Get the color shift for a given velocity and direction
## Returns a value from -1 (full redshift) to +1 (full blueshift)
## 0 = no shift
func get_color_shift_value(velocity: Vector3, direction: Vector3) -> float:
	var doppler = calculate_doppler_shift(velocity, direction)
	
	# Convert doppler factor to a -1 to +1 range
	# doppler = 1.0 -> shift = 0
	# doppler > 1.0 -> shift > 0 (blueshift)
	# doppler < 1.0 -> shift < 0 (redshift)
	
	if doppler >= 1.0:
		# Blueshift: map 1.0-2.0+ to 0.0-1.0
		return clampf((doppler - 1.0), 0.0, 1.0)
	else:
		# Redshift: map 0.5-1.0 to -1.0-0.0
		return clampf((doppler - 1.0), -1.0, 0.0)


## Get the percentage of light speed for the current velocity
func get_velocity_as_percentage_of_c() -> float:
	return (_current_velocity.length() / C) * 100.0


## Get the current speed as a fraction of c (0.0 to MAX_VELOCITY_FRACTION)
func get_beta() -> float:
	return clampf(_current_velocity.length() / C, 0.0, MAX_VELOCITY_FRACTION)


## Internal: Update the Lorentz factor based on current velocity
func _update_lorentz_factor(delta: float) -> void:
	_previous_lorentz_factor = lorentz_factor
	
	# Smoothly interpolate toward target Lorentz factor
	# Requirement 6.5: Restore normal time flow within 0.5 seconds
	var lerp_factor = minf(delta * TIME_RESTORATION_RATE, 1.0)
	lorentz_factor = lerpf(lorentz_factor, _target_lorentz_factor, lerp_factor)
	
	# Clamp to valid range
	lorentz_factor = clampf(lorentz_factor, MIN_LORENTZ_FACTOR, 1.0)
	
	# Emit signal if Lorentz factor changed significantly
	if absf(lorentz_factor - _previous_lorentz_factor) > EPSILON:
		lorentz_factor_changed.emit(lorentz_factor)


## Internal: Update the world time scale based on Lorentz factor
func _update_world_time_scale(delta: float) -> void:
	# Requirement 6.2: Scale world time by Lorentz factor
	world_time_scale = lorentz_factor
	
	# Check if time dilation state changed
	var was_active = _time_dilation_active
	_time_dilation_active = lorentz_factor < TIME_DILATION_THRESHOLD
	
	if was_active != _time_dilation_active:
		time_dilation_state_changed.emit(_time_dilation_active)


## Calculate relativistic kinetic energy
## E_k = (gamma - 1) * m * c²
func calculate_relativistic_kinetic_energy(mass: float, velocity: Vector3) -> float:
	var gamma = calculate_lorentz_factor(velocity)
	return (gamma - 1.0) * mass * C * C


## Calculate relativistic momentum
## p = gamma * m * v
func calculate_relativistic_momentum(mass: float, velocity: Vector3) -> Vector3:
	var gamma = calculate_lorentz_factor(velocity)
	return gamma * mass * velocity


## Calculate the velocity required to achieve a given Lorentz factor
func velocity_for_lorentz_factor(target_gamma: float) -> float:
	# gamma = sqrt(1 - v²/c²)
	# gamma² = 1 - v²/c²
	# v²/c² = 1 - gamma²
	# v = c * sqrt(1 - gamma²)
	
	target_gamma = clampf(target_gamma, MIN_LORENTZ_FACTOR, 1.0)
	var v_over_c_squared = 1.0 - (target_gamma * target_gamma)
	
	if v_over_c_squared <= 0:
		return 0.0
	
	return C * sqrt(v_over_c_squared)


## Get statistics about the relativity system
func get_statistics() -> Dictionary:
	return {
		"lorentz_factor": lorentz_factor,
		"world_time_scale": world_time_scale,
		"current_speed": _current_velocity.length(),
		"speed_of_light": C,
		"beta": get_beta(),
		"percentage_of_c": get_velocity_as_percentage_of_c(),
		"time_dilation_active": _time_dilation_active,
		"length_contraction_factor": calculate_length_contraction(_current_velocity)
	}


## Reset the relativity system to default state
func reset() -> void:
	lorentz_factor = 1.0
	_target_lorentz_factor = 1.0
	world_time_scale = 1.0
	_current_velocity = Vector3.ZERO
	_time_dilation_active = false
	_previous_lorentz_factor = 1.0


## Shutdown the system
func shutdown() -> void:
	reset()
