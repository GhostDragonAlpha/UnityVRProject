## DayNightCycle - Planetary Day/Night Cycle System
##
## Calculates sun position from planet rotation and orbital mechanics
## to create realistic day/night cycles. Uses the planet's actual spin
## and position relative to the sun (star) for accurate lighting.
##
## Requirements: 60.1, 60.2, 60.3, 60.4, 60.5

extends Node
class_name DayNightCycle

## Reference to the directional light representing the sun
@export var sun_light: DirectionalLight3D

## Reference to the planet this cycle is for
@export var planet: CelestialBody

## Reference to the star (sun) that illuminates this planet
@export var star: CelestialBody

## Transition speed for lighting changes (Tween-based smooth transitions)
@export var transition_speed: float = 2.0

## Colors for different times of day
@export var day_color: Color = Color(1.0, 0.95, 0.9, 1.0)  # Warm daylight
@export var sunset_color: Color = Color(1.0, 0.6, 0.3, 1.0)  # Orange sunset
@export var night_color: Color = Color(0.1, 0.15, 0.3, 1.0)  # Cool night

## Light intensities
@export var day_intensity: float = 1.0
@export var night_intensity: float = 0.05

## Current target color and intensity
var target_color: Color
var target_intensity: float

## Reference to player/camera position for local day/night calculation
var player_position: Vector3 = Vector3.ZERO

## Initialize the day/night cycle
func _ready() -> void:
	# Validate required references
	if not sun_light:
		push_error("DayNightCycle: No sun light assigned!")
		return
	
	if not planet:
		push_error("DayNightCycle: No planet assigned!")
		return
	
	if not star:
		push_warning("DayNightCycle: No star assigned, will use default sun direction")
	
	# Set initial lighting
	update_sun_direction()
	update_lighting()
	
	print("DayNightCycle initialized for planet: ", planet.body_name)
	print("  Rotation period: ", planet.rotation_period, " seconds")
	print("  Axial tilt: ", rad_to_deg(planet.axial_tilt), " degrees")

## Update the day/night cycle
## Requirement 60.2: Update DirectionalLight3D based on time of day
## Requirement 60.3: Smoothly interpolate lighting transitions using Tween
func _process(delta: float) -> void:
	if not sun_light or not planet:
		return
	
	# Update sun direction based on planet rotation and star position
	update_sun_direction()
	
	# Update lighting based on sun elevation
	update_lighting()
	
	# Smoothly interpolate to target values
	# Requirement 60.3: Smooth lighting transitions
	if sun_light.light_color != target_color:
		sun_light.light_color = sun_light.light_color.lerp(target_color, transition_speed * delta)
	
	if not is_equal_approx(sun_light.light_energy, target_intensity):
		sun_light.light_energy = lerp(sun_light.light_energy, target_intensity, transition_speed * delta)

## Update sun direction based on planet rotation and star position
## Requirement 60.1: Calculate sun position from planet rotation
func update_sun_direction() -> void:
	if not sun_light or not planet:
		return
	
	# Get the direction from planet to star
	var sun_direction: Vector3
	
	if star and is_instance_valid(star):
		# Use actual star position for accurate lighting
		sun_direction = (star.global_position - planet.global_position).normalized()
	else:
		# Fallback: use a default sun direction
		sun_direction = Vector3(0, -1, 0)
	
	# Account for planet's rotation
	# The planet's current_rotation represents how much it has rotated
	# We need to rotate the sun direction by the opposite amount to simulate
	# the sun moving across the sky from the planet's surface perspective
	var rotation_axis = planet.get_rotation_axis()
	var rotation_angle = planet.get_current_rotation()
	
	# Rotate the sun direction around the planet's rotation axis
	# This simulates the sun's apparent motion across the sky
	sun_direction = sun_direction.rotated(rotation_axis, -rotation_angle)
	
	# Set the light direction
	# The light should point FROM the sun TO the planet
	sun_light.rotation = Vector3.ZERO
	sun_light.look_at(sun_light.global_position + sun_direction, Vector3.UP)

## Update lighting color and intensity based on sun elevation
## Requirement 60.2: Update DirectionalLight3D based on time of day
## Requirement 60.4: Render stars and celestial bodies at night
func update_lighting() -> void:
	if not sun_light or not planet:
		return
	
	# Calculate sun elevation relative to the player's position on the planet
	var sun_elevation = calculate_sun_elevation()
	
	# Determine lighting phase based on sun elevation
	# Requirement 60.2: Update lighting based on time of day
	if sun_elevation > 0.8:
		# High noon - full daylight
		target_color = day_color
		target_intensity = day_intensity
	
	elif sun_elevation > 0.0:
		# Morning/afternoon - interpolate between sunrise and day
		var t = sun_elevation / 0.8
		target_color = sunset_color.lerp(day_color, t)
		target_intensity = lerp(day_intensity * 0.5, day_intensity, t)
	
	elif sun_elevation > -0.2:
		# Sunrise/sunset - orange/red colors
		var t = (sun_elevation + 0.2) / 0.2
		target_color = night_color.lerp(sunset_color, t)
		target_intensity = lerp(night_intensity, day_intensity * 0.5, t)
	
	else:
		# Night - low intensity, cool colors
		# Requirement 60.4: Stars visible at night (low ambient light)
		target_color = night_color
		target_intensity = night_intensity

## Calculate sun elevation at the player's position
## Returns a value from -1.0 (midnight) to 1.0 (noon)
func calculate_sun_elevation() -> float:
	if not planet:
		return 0.0
	
	# Get the sun direction in world space
	var sun_direction: Vector3
	if star and is_instance_valid(star):
		sun_direction = (star.global_position - planet.global_position).normalized()
	else:
		sun_direction = Vector3(0, -1, 0)
	
	# Get the player's position relative to the planet
	# If we don't have a player position, use the planet's "up" direction
	var local_up: Vector3
	if player_position != Vector3.ZERO:
		local_up = (player_position - planet.global_position).normalized()
	else:
		# Use the planet's rotation axis as "up"
		local_up = planet.get_rotation_axis()
	
	# Account for planet rotation
	var rotation_axis = planet.get_rotation_axis()
	var rotation_angle = planet.get_current_rotation()
	local_up = local_up.rotated(rotation_axis, rotation_angle)
	
	# Calculate sun elevation as dot product
	# 1.0 = sun directly overhead (noon)
	# 0.0 = sun at horizon (sunrise/sunset)
	# -1.0 = sun directly below (midnight)
	var elevation = sun_direction.dot(local_up)
	
	return elevation

## Set the player position for local day/night calculation
func set_player_position(pos: Vector3) -> void:
	player_position = pos

## Get current time of day as a readable string (based on planet rotation)
func get_time_string() -> String:
	if not planet:
		return "00:00"
	
	# Calculate time of day from rotation angle (0.0 to 1.0)
	var time_of_day = planet.get_current_rotation() / TAU
	
	var hours = int(time_of_day * 24.0)
	var minutes = int((time_of_day * 24.0 - hours) * 60.0)
	return "%02d:%02d" % [hours, minutes]

## Get current phase of day
func get_day_phase() -> String:
	var sun_elevation = calculate_sun_elevation()
	
	if sun_elevation > 0.8:
		return "noon"
	elif sun_elevation > 0.0:
		var time_of_day = planet.get_current_rotation() / TAU
		if time_of_day < 0.5:
			return "morning"
		else:
			return "afternoon"
	elif sun_elevation > -0.2:
		var time_of_day = planet.get_current_rotation() / TAU
		if time_of_day < 0.5:
			return "sunrise"
		else:
			return "sunset"
	else:
		return "night"

## Check if it's currently daytime at the player's position
func is_daytime() -> bool:
	var sun_elevation = calculate_sun_elevation()
	return sun_elevation > 0.0

## Check if it's currently nighttime at the player's position
func is_nighttime() -> bool:
	return not is_daytime()

## Get the current sun elevation (-1.0 to 1.0)
func get_sun_elevation() -> float:
	return calculate_sun_elevation()
