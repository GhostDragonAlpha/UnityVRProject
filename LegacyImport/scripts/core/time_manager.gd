## TimeManager - Simulation Time Control System
## Manages simulation time tracking, acceleration, and pause functionality
## for controlling the flow of time in the space simulation.
##
## Requirements: 15.1, 15.2, 15.3, 15.4, 15.5
## - 15.1: Time acceleration with factors (1x, 10x, 100x, 1000x, 10000x, 100000x)
## - 15.2: Smooth transitions between rates within 0.5 seconds
## - 15.3: Update all celestial body positions at accelerated rate
## - 15.4: Pause functionality that freezes celestial movements
## - 15.5: Track current date relative to J2000.0 epoch
extends Node
class_name TimeManager

## Emitted when time acceleration factor changes
signal time_acceleration_changed(new_factor: float)
## Emitted when pause state changes
signal pause_state_changed(is_paused: bool)
## Emitted when simulation date changes (emitted once per real second)
signal simulation_date_changed(julian_date: float, calendar_date: Dictionary)
## Emitted when time acceleration transition starts
signal acceleration_transition_started(from_factor: float, to_factor: float)
## Emitted when time acceleration transition completes
signal acceleration_transition_completed(factor: float)

## J2000.0 epoch in Julian Date (January 1, 2000, 12:00 TT)
## This is the standard astronomical reference epoch
const J2000_EPOCH: float = 2451545.0

## Seconds per Julian day
const SECONDS_PER_DAY: float = 86400.0

## Available time acceleration factors
## Requirement 15.1: Support 1x, 10x, 100x, 1000x, 10000x, 100000x
const TIME_FACTORS: Array[float] = [1.0, 10.0, 100.0, 1000.0, 10000.0, 100000.0]

## Time factor indices for easy reference
enum TimeFactorIndex {
	REALTIME = 0,      # 1x
	FAST = 1,          # 10x
	FASTER = 2,        # 100x
	VERY_FAST = 3,     # 1000x
	ULTRA_FAST = 4,    # 10000x
	MAXIMUM = 5        # 100000x
}

## Transition duration for smooth acceleration changes (in seconds)
## Requirement 15.2: Smooth transitions within 0.5 seconds
@export var transition_duration: float = 0.5

## Convenience property for accessing exported transition duration
var TRANSITION_DURATION: float:
	get: return transition_duration

## Current time acceleration factor
var time_factor: float = 1.0

## Target time acceleration factor (for smooth transitions)
var _target_time_factor: float = 1.0

## Whether the simulation is paused
## Requirement 15.4: Pause freezes celestial movements
var is_paused: bool = false

## Current simulation time in seconds since J2000.0 epoch
## Requirement 15.5: Track time relative to J2000.0
var simulation_time: float = 0.0

## Current Julian Date
var julian_date: float = J2000_EPOCH

## Transition state
var _is_transitioning: bool = false
var _transition_start_factor: float = 1.0
var _transition_elapsed: float = 0.0

## Time tracking for date change signal
var _last_date_signal_time: float = 0.0

## Epsilon for floating-point comparisons
const EPSILON: float = 0.0001


func _ready() -> void:
	# Initialize to current real-world date/time
	_initialize_to_current_date()


## Initialize simulation time to current real-world date
func _initialize_to_current_date() -> void:
	var datetime = Time.get_datetime_dict_from_system(true)  # UTC
	julian_date = _calendar_to_julian(
		datetime.year,
		datetime.month,
		datetime.day,
		datetime.hour,
		datetime.minute,
		datetime.second
	)
	simulation_time = (julian_date - J2000_EPOCH) * SECONDS_PER_DAY


## Update method called by the engine coordinator
## Requirement 15.3: Update celestial positions at accelerated rate
func update(delta: float) -> void:
	# Handle acceleration transitions
	_update_transition(delta)
	
	# Update simulation time if not paused
	if not is_paused:
		_update_simulation_time(delta)
	
	# Emit date change signal periodically (once per real second)
	_last_date_signal_time += delta
	if _last_date_signal_time >= 1.0:
		_last_date_signal_time = 0.0
		var calendar = get_calendar_date()
		simulation_date_changed.emit(julian_date, calendar)


## Update simulation time based on real delta and time factor
func _update_simulation_time(delta: float) -> void:
	# Calculate simulation delta time
	var sim_delta = delta * time_factor
	
	# Update simulation time (seconds since J2000.0)
	simulation_time += sim_delta
	
	# Update Julian Date
	julian_date = J2000_EPOCH + (simulation_time / SECONDS_PER_DAY)


## Handle smooth transitions between time factors
## Requirement 15.2: Smooth transitions within 0.5 seconds
func _update_transition(delta: float) -> void:
	if not _is_transitioning:
		return
	
	_transition_elapsed += delta
	
	if _transition_elapsed >= TRANSITION_DURATION:
		# Transition complete
		time_factor = _target_time_factor
		_is_transitioning = false
		acceleration_transition_completed.emit(time_factor)
	else:
		# Interpolate using smooth step for natural feel
		var t = _transition_elapsed / TRANSITION_DURATION
		t = _smooth_step(t)
		
		# Interpolate in log space for perceptually linear acceleration
		var log_start = log(_transition_start_factor) if _transition_start_factor > 0 else 0.0
		var log_target = log(_target_time_factor) if _target_time_factor > 0 else 0.0
		var log_current = lerpf(log_start, log_target, t)
		time_factor = exp(log_current)


## Smooth step function for natural transitions
func _smooth_step(t: float) -> float:
	# Hermite interpolation: 3t² - 2t³
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


## Set time acceleration factor with smooth transition
## Requirement 15.1: Support multiple acceleration factors
## Requirement 15.2: Smooth transitions
func set_time_factor(factor: float) -> void:
	# Clamp to valid range
	factor = clampf(factor, TIME_FACTORS[0], TIME_FACTORS[TIME_FACTORS.size() - 1])
	
	if absf(factor - time_factor) < EPSILON:
		return  # No change needed
	
	_transition_start_factor = time_factor
	_target_time_factor = factor
	_transition_elapsed = 0.0
	_is_transitioning = true
	
	acceleration_transition_started.emit(time_factor, factor)
	time_acceleration_changed.emit(factor)


## Set time acceleration by index (0-5)
func set_time_factor_index(index: int) -> void:
	index = clampi(index, 0, TIME_FACTORS.size() - 1)
	set_time_factor(TIME_FACTORS[index])


## Increase time acceleration to next level
func increase_time_factor() -> void:
	var current_index = _get_current_factor_index()
	if current_index < TIME_FACTORS.size() - 1:
		set_time_factor_index(current_index + 1)


## Decrease time acceleration to previous level
func decrease_time_factor() -> void:
	var current_index = _get_current_factor_index()
	if current_index > 0:
		set_time_factor_index(current_index - 1)


## Reset time to real-time (1x)
func reset_time_factor() -> void:
	set_time_factor(1.0)


## Get the current factor index (nearest match)
func _get_current_factor_index() -> int:
	var target = _target_time_factor if _is_transitioning else time_factor
	var best_index = 0
	var best_diff = absf(TIME_FACTORS[0] - target)
	
	for i in range(1, TIME_FACTORS.size()):
		var diff = absf(TIME_FACTORS[i] - target)
		if diff < best_diff:
			best_diff = diff
			best_index = i
	
	return best_index


## Pause the simulation
## Requirement 15.4: Pause freezes celestial movements
func pause() -> void:
	if is_paused:
		return
	
	is_paused = true
	pause_state_changed.emit(true)


## Resume the simulation
func resume() -> void:
	if not is_paused:
		return
	
	is_paused = false
	pause_state_changed.emit(false)


## Toggle pause state
func toggle_pause() -> void:
	if is_paused:
		resume()
	else:
		pause()


## Get the simulation delta time for this frame
## This is what celestial bodies should use for their updates
## Requirement 15.3: Celestial bodies update at accelerated rate
func get_simulation_delta(real_delta: float) -> float:
	if is_paused:
		return 0.0
	return real_delta * time_factor


## Get current time factor
func get_time_factor() -> float:
	return time_factor


## Get target time factor (during transitions)
func get_target_time_factor() -> float:
	return _target_time_factor


## Check if currently transitioning between time factors
func is_transitioning() -> bool:
	return _is_transitioning


## Get current Julian Date
## Requirement 15.5: Track current date
func get_julian_date() -> float:
	return julian_date


## Get simulation time in seconds since J2000.0
func get_simulation_time() -> float:
	return simulation_time


## Set simulation time in seconds since J2000.0
## Requirement 38.3: Restore celestial body positions to saved simulation time
func set_simulation_time(time: float) -> void:
	simulation_time = time
	julian_date = J2000_EPOCH + (simulation_time / SECONDS_PER_DAY)
	
	var calendar = get_calendar_date()
	simulation_date_changed.emit(julian_date, calendar)


## Get days since J2000.0 epoch
func get_days_since_j2000() -> float:
	return simulation_time / SECONDS_PER_DAY


## Get current calendar date as a dictionary
## Requirement 15.5: Track current date for ephemeris calculations
func get_calendar_date() -> Dictionary:
	return _julian_to_calendar(julian_date)


## Set simulation time to a specific Julian Date
func set_julian_date(jd: float) -> void:
	julian_date = jd
	simulation_time = (jd - J2000_EPOCH) * SECONDS_PER_DAY
	
	var calendar = get_calendar_date()
	simulation_date_changed.emit(julian_date, calendar)


## Set simulation time to a specific calendar date
func set_calendar_date(year: int, month: int, day: int, hour: int = 12, minute: int = 0, second: int = 0) -> void:
	julian_date = _calendar_to_julian(year, month, day, hour, minute, second)
	simulation_time = (julian_date - J2000_EPOCH) * SECONDS_PER_DAY
	
	var calendar = get_calendar_date()
	simulation_date_changed.emit(julian_date, calendar)


## Convert calendar date to Julian Date
## Algorithm from "Astronomical Algorithms" by Jean Meeus
func _calendar_to_julian(year: int, month: int, day: int, hour: int = 12, minute: int = 0, second: int = 0) -> float:
	# Adjust for January and February
	var y = year
	var m = month
	if m <= 2:
		y -= 1
		m += 12
	
	# Calculate Julian Day Number
	var a = floori(y / 100.0)
	var b = 2 - a + floori(a / 4.0)
	
	var jd = floori(365.25 * (y + 4716)) + floori(30.6001 * (m + 1)) + day + b - 1524.5
	
	# Add time of day
	var day_fraction = (hour + minute / 60.0 + second / 3600.0) / 24.0
	jd += day_fraction
	
	return jd


## Convert Julian Date to calendar date
## Algorithm from "Astronomical Algorithms" by Jean Meeus
func _julian_to_calendar(jd: float) -> Dictionary:
	var z = floori(jd + 0.5)
	var f = (jd + 0.5) - z
	
	var a: int
	if z < 2299161:
		a = z
	else:
		var alpha = floori((z - 1867216.25) / 36524.25)
		a = z + 1 + alpha - floori(alpha / 4.0)
	
	var b = a + 1524
	var c = floori((b - 122.1) / 365.25)
	var d = floori(365.25 * c)
	var e = floori((b - d) / 30.6001)
	
	var day = b - d - floori(30.6001 * e)
	
	var month: int
	if e < 14:
		month = e - 1
	else:
		month = e - 13
	
	var year: int
	if month > 2:
		year = c - 4716
	else:
		year = c - 4715
	
	# Calculate time of day
	var day_fraction = f
	var total_hours = day_fraction * 24.0
	var hour = floori(total_hours)
	var remaining_minutes = (total_hours - hour) * 60.0
	var minute = floori(remaining_minutes)
	var second = floori((remaining_minutes - minute) * 60.0)
	
	return {
		"year": year,
		"month": month,
		"day": day,
		"hour": hour,
		"minute": minute,
		"second": second,
		"julian_date": jd
	}


## Format the current simulation date as a string
func get_formatted_date() -> String:
	var cal = get_calendar_date()
	return "%04d-%02d-%02d %02d:%02d:%02d UTC" % [
		cal.year, cal.month, cal.day,
		cal.hour, cal.minute, cal.second
	]


## Format the current time factor as a string
func get_formatted_time_factor() -> String:
	if time_factor >= 1000.0:
		return "%dx" % int(time_factor)
	elif time_factor >= 1.0:
		return "%.0fx" % time_factor
	else:
		return "%.2fx" % time_factor


## Get statistics about the time manager
func get_statistics() -> Dictionary:
	return {
		"time_factor": time_factor,
		"target_time_factor": _target_time_factor,
		"is_paused": is_paused,
		"is_transitioning": _is_transitioning,
		"simulation_time": simulation_time,
		"julian_date": julian_date,
		"days_since_j2000": get_days_since_j2000(),
		"calendar_date": get_calendar_date(),
		"formatted_date": get_formatted_date()
	}


## Reset the time manager to default state
func reset() -> void:
	time_factor = 1.0
	_target_time_factor = 1.0
	is_paused = false
	_is_transitioning = false
	_transition_elapsed = 0.0
	_last_date_signal_time = 0.0
	
	# Reset to current real-world date
	_initialize_to_current_date()


## Shutdown the system
func shutdown() -> void:
	reset()
