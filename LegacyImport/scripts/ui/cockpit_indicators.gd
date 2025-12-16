extends Node
class_name CockpitIndicators
## Manages dynamic cockpit lighting including thruster lights and warning indicators
## Integrates with Spacecraft to modulate lights based on thrust, altitude, fuel, and speed

## References
var spacecraft: Spacecraft = null
var landing_detector: LandingDetector = null

## Thruster lights
var thruster_light_main: OmniLight3D = null
var thruster_light_left: OmniLight3D = null
var thruster_light_right: OmniLight3D = null

## Warning lights
var warning_light_altitude: OmniLight3D = null
var warning_light_fuel: OmniLight3D = null
var warning_light_speed: OmniLight3D = null

## Light intensity parameters
const THRUSTER_LIGHT_COLOR := Color(0.8, 0.9, 1.0)  # Cool blue-white
const THRUSTER_LIGHT_RANGE_MIN := 10.0
const THRUSTER_LIGHT_RANGE_MAX := 20.0
const THRUSTER_BASE_ENERGY := 2.0
const THRUSTER_MAX_ENERGY := 8.0

## Warning light parameters
const WARNING_COLOR_RED := Color(1.0, 0.2, 0.2)
const WARNING_COLOR_YELLOW := Color(1.0, 0.8, 0.2)
const WARNING_COLOR_GREEN := Color(0.2, 1.0, 0.2)
const WARNING_BLINK_RATE := 2.0  # Blinks per second

## Thresholds
const ALTITUDE_WARNING_THRESHOLD := 10.0  # meters
const FUEL_WARNING_THRESHOLD := 25.0  # percent
const SPEED_WARNING_THRESHOLD := 50.0  # m/s

## State
var _blink_timer: float = 0.0
var _blink_state: bool = false


func _ready() -> void:
	set_process(false)


## Initialize the indicator system
func initialize(craft: Spacecraft, detector: LandingDetector = null) -> void:
	spacecraft = craft
	landing_detector = detector

	# Find light nodes
	_find_light_nodes()

	set_process(true)
	print("[CockpitIndicators] Initialized")


func _process(delta: float) -> void:
	if not spacecraft:
		return

	# Update thruster lights based on thrust level
	_update_thruster_lights()

	# Update warning lights
	_update_warning_lights(delta)


## Find all light nodes in the scene
func _find_light_nodes() -> void:
	# Find thruster lights
	thruster_light_main = get_node_or_null("../Spacecraft/ThrusterLightMain")
	thruster_light_left = get_node_or_null("../Spacecraft/ThrusterLightLeft")
	thruster_light_right = get_node_or_null("../Spacecraft/ThrusterLightRight")

	# Find warning lights
	warning_light_altitude = get_node_or_null("../Spacecraft/WarningLightAltitude")
	warning_light_fuel = get_node_or_null("../Spacecraft/WarningLightFuel")
	warning_light_speed = get_node_or_null("../Spacecraft/WarningLightSpeed")

	if thruster_light_main:
		print("[CockpitIndicators] Found main thruster light")
	if thruster_light_left:
		print("[CockpitIndicators] Found left thruster light")
	if thruster_light_right:
		print("[CockpitIndicators] Found right thruster light")

	if warning_light_altitude:
		print("[CockpitIndicators] Found altitude warning light")
	if warning_light_fuel:
		print("[CockpitIndicators] Found fuel warning light")
	if warning_light_speed:
		print("[CockpitIndicators] Found speed warning light")


## Update thruster lights based on current thrust level
func _update_thruster_lights() -> void:
	if not spacecraft:
		return

	# Get thrust level (0.0 to 1.0)
	var throttle = abs(spacecraft.get_throttle())
	var vertical_thrust = abs(spacecraft.vertical_thrust)

	# Calculate combined thrust level
	var thrust_level = max(throttle, vertical_thrust)

	# Modulate main thruster light
	if thruster_light_main:
		var energy = lerp(0.0, THRUSTER_MAX_ENERGY, thrust_level)
		var range_value = lerp(THRUSTER_LIGHT_RANGE_MIN, THRUSTER_LIGHT_RANGE_MAX, thrust_level)

		thruster_light_main.light_energy = energy
		thruster_light_main.omni_range = range_value
		thruster_light_main.light_color = THRUSTER_LIGHT_COLOR
		thruster_light_main.visible = thrust_level > 0.01

	# Modulate side thruster lights based on rotation input
	if spacecraft.rotation_input.length() > 0.01:
		# Left thruster (yaw right)
		if thruster_light_left:
			var left_intensity = clampf(spacecraft.rotation_input.y, 0.0, 1.0)
			thruster_light_left.light_energy = lerp(0.0, THRUSTER_BASE_ENERGY, left_intensity)
			thruster_light_left.omni_range = lerp(5.0, 15.0, left_intensity)
			thruster_light_left.light_color = THRUSTER_LIGHT_COLOR
			thruster_light_left.visible = left_intensity > 0.01

		# Right thruster (yaw left)
		if thruster_light_right:
			var right_intensity = clampf(-spacecraft.rotation_input.y, 0.0, 1.0)
			thruster_light_right.light_energy = lerp(0.0, THRUSTER_BASE_ENERGY, right_intensity)
			thruster_light_right.omni_range = lerp(5.0, 15.0, right_intensity)
			thruster_light_right.light_color = THRUSTER_LIGHT_COLOR
			thruster_light_right.visible = right_intensity > 0.01
	else:
		# Turn off side lights when not rotating
		if thruster_light_left:
			thruster_light_left.visible = false
		if thruster_light_right:
			thruster_light_right.visible = false


## Update warning lights based on spacecraft state
func _update_warning_lights(delta: float) -> void:
	# Update blink timer
	_blink_timer += delta * WARNING_BLINK_RATE
	if _blink_timer >= 1.0:
		_blink_timer = 0.0
		_blink_state = not _blink_state

	# Update altitude warning light
	_update_altitude_warning()

	# Update fuel warning light (placeholder - assumes fuel system exists)
	_update_fuel_warning()

	# Update speed warning light
	_update_speed_warning()


## Update altitude warning light
func _update_altitude_warning() -> void:
	if not warning_light_altitude:
		return

	var altitude = 999999.0
	if landing_detector:
		altitude = landing_detector.get_altitude()

	if altitude < ALTITUDE_WARNING_THRESHOLD:
		# Blink red when low altitude
		warning_light_altitude.visible = _blink_state
		warning_light_altitude.light_color = WARNING_COLOR_RED
		warning_light_altitude.light_energy = 3.0
		warning_light_altitude.omni_range = 2.0
	else:
		# Solid green when safe altitude
		warning_light_altitude.visible = true
		warning_light_altitude.light_color = WARNING_COLOR_GREEN
		warning_light_altitude.light_energy = 1.0
		warning_light_altitude.omni_range = 1.5


## Update fuel warning light (placeholder)
func _update_fuel_warning() -> void:
	if not warning_light_fuel:
		return

	# Placeholder: Assume full fuel for now
	# In a real implementation, this would check spacecraft fuel level
	var fuel_percent = 100.0

	if fuel_percent < FUEL_WARNING_THRESHOLD:
		# Blink yellow/red when low fuel
		warning_light_fuel.visible = _blink_state
		if fuel_percent < 10.0:
			warning_light_fuel.light_color = WARNING_COLOR_RED
		else:
			warning_light_fuel.light_color = WARNING_COLOR_YELLOW
		warning_light_fuel.light_energy = 3.0
		warning_light_fuel.omni_range = 2.0
	else:
		# Solid green when fuel OK
		warning_light_fuel.visible = true
		warning_light_fuel.light_color = WARNING_COLOR_GREEN
		warning_light_fuel.light_energy = 1.0
		warning_light_fuel.omni_range = 1.5


## Update speed warning light
func _update_speed_warning() -> void:
	if not warning_light_speed:
		return

	var speed = spacecraft.get_velocity_magnitude()

	if speed > SPEED_WARNING_THRESHOLD:
		# Blink yellow when high speed
		warning_light_speed.visible = _blink_state
		warning_light_speed.light_color = WARNING_COLOR_YELLOW
		warning_light_speed.light_energy = 3.0
		warning_light_speed.omni_range = 2.0
	else:
		# Solid green when safe speed
		warning_light_speed.visible = true
		warning_light_speed.light_color = WARNING_COLOR_GREEN
		warning_light_speed.light_energy = 1.0
		warning_light_speed.omni_range = 1.5


## Cleanup
func _exit_tree() -> void:
	set_process(false)
