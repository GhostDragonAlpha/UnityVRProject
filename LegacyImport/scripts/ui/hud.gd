## HUD - 3D Heads-Up Display System
## Displays spacecraft status information in VR-friendly 3D space including
## velocity, light speed percentage, SNR health, escape velocity, and time information.
##
## Requirements: 39.1, 39.2, 39.3, 39.4, 39.5
## - 39.1: Display velocity magnitude and direction
## - 39.2: Display percentage of c with color coding
## - 39.3: Display SNR percentage with visual health bar
## - 39.4: Display escape velocity comparison in gravity wells
## - 39.5: Display time multiplier and simulated date
extends Node3D
class_name HUD

# Preload custom classes for type references
const Spacecraft = preload("res://scripts/player/spacecraft.gd")
const SignalManager = preload("res://scripts/player/signal_manager.gd")
const TimeManager = preload("res://scripts/core/time_manager.gd")
const CelestialBody = preload("res://scripts/celestial/celestial_body.gd")
## Reference to spacecraft for velocity data
var spacecraft: Spacecraft = null

## Reference to signal manager for SNR data
var signal_manager: SignalManager = null

## Reference to time manager for time data
var time_manager: TimeManager = null

## Reference to relativity manager for light speed calculations
var relativity_manager = null

## Reference to nearest celestial body (for escape velocity)
var nearest_celestial_body: CelestialBody = null

#region UI Elements - Label3D nodes

## Velocity display
var velocity_label: Label3D = null
var velocity_direction_label: Label3D = null

## Light speed percentage display
var light_speed_label: Label3D = null

## SNR health display
var snr_label: Label3D = null
var snr_bar: MeshInstance3D = null  # Visual health bar

## Escape velocity display
var escape_velocity_label: Label3D = null

## Time display
var time_multiplier_label: Label3D = null
var simulated_date_label: Label3D = null

#endregion

#region Configuration

## HUD position offset from player camera
@export var hud_offset: Vector3 = Vector3(0, 0.2, -1.5)

## HUD scale
@export var hud_scale: float = 0.5

## Update frequency (updates per second)
@export var update_frequency: float = 10.0

## Color coding thresholds
const CRITICAL_THRESHOLD: float = 0.25  # 25%
const WARNING_THRESHOLD: float = 0.50   # 50%

## Colors for different states
const COLOR_NORMAL: Color = Color(0.0, 1.0, 0.8)      # Cyan
const COLOR_WARNING: Color = Color(1.0, 0.8, 0.0)     # Yellow
const COLOR_CRITICAL: Color = Color(1.0, 0.2, 0.2)    # Red
const COLOR_GOOD: Color = Color(0.2, 1.0, 0.2)        # Green

#endregion

#region Runtime State

## Time since last update
var _time_since_update: float = 0.0

## Update interval
var _update_interval: float = 0.1

## Current velocity for display
var _current_velocity: Vector3 = Vector3.ZERO
var _current_speed: float = 0.0

## Current SNR percentage
var _current_snr_percentage: float = 1.0

## Current escape velocity at position
var _current_escape_velocity: float = 0.0

#endregion


func _ready() -> void:
	_update_interval = 1.0 / update_frequency
	_find_system_references()
	_create_hud_elements()
	_connect_signals()


func _process(delta: float) -> void:
	_time_since_update += delta
	
	if _time_since_update >= _update_interval:
		_update_hud_data()
		_update_hud_display()
		_time_since_update = 0.0


#region Initialization

## Find references to game systems
func _find_system_references() -> void:
	"""Find references to spacecraft, signal manager, and time manager."""
	var engine_node = get_node_or_null("/root/ResonanceEngine")
	
	if engine_node:
		# Get spacecraft
		if engine_node.has_method("get_spacecraft"):
			spacecraft = engine_node.get_spacecraft()
		
		# Get signal manager
		if engine_node.has_method("get_signal_manager"):
			signal_manager = engine_node.get_signal_manager()
		
		# Get time manager
		if engine_node.has_method("get_time_manager"):
			time_manager = engine_node.get_time_manager()
		
		# Get relativity manager
		if engine_node.has_method("get_relativity_manager"):
			relativity_manager = engine_node.get_relativity_manager()
		
		# Get physics engine for nearest celestial body
		if engine_node.has_method("get_physics_engine"):
			var physics_engine = engine_node.get_physics_engine()
			if physics_engine and physics_engine.has_method("get_nearest_celestial_body"):
				# Will be updated each frame
				pass


## Create all HUD UI elements
func _create_hud_elements() -> void:
	"""Create all Label3D and visual elements for the HUD."""
	# Create container for HUD elements
	var hud_container = Node3D.new()
	hud_container.name = "HUDContainer"
	add_child(hud_container)
	hud_container.scale = Vector3.ONE * hud_scale
	
	# Requirement 39.1: Display velocity magnitude and direction
	_create_velocity_display(hud_container)
	
	# Requirement 39.2: Display percentage of c with color coding
	_create_light_speed_display(hud_container)
	
	# Requirement 39.3: Display SNR percentage with health bar
	_create_snr_display(hud_container)
	
	# Requirement 39.4: Display escape velocity comparison
	_create_escape_velocity_display(hud_container)
	
	# Requirement 39.5: Display time multiplier and simulated date
	_create_time_display(hud_container)


## Create velocity display elements
## Requirement 39.1: Display velocity magnitude and direction
func _create_velocity_display(parent: Node3D) -> void:
	"""Create velocity magnitude and direction display."""
	# Velocity magnitude label
	velocity_label = Label3D.new()
	velocity_label.name = "VelocityLabel"
	velocity_label.position = Vector3(-0.5, 0.4, 0)
	velocity_label.text = "Velocity: 0.0 m/s"
	velocity_label.font_size = 32
	velocity_label.modulate = COLOR_NORMAL
	velocity_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	velocity_label.no_depth_test = true
	velocity_label.render_priority = 10
	parent.add_child(velocity_label)
	
	# Velocity direction label
	velocity_direction_label = Label3D.new()
	velocity_direction_label.name = "VelocityDirectionLabel"
	velocity_direction_label.position = Vector3(-0.5, 0.3, 0)
	velocity_direction_label.text = "Direction: (0.0, 0.0, 0.0)"
	velocity_direction_label.font_size = 24
	velocity_direction_label.modulate = COLOR_NORMAL
	velocity_direction_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	velocity_direction_label.no_depth_test = true
	velocity_direction_label.render_priority = 10
	parent.add_child(velocity_direction_label)


## Create light speed percentage display
## Requirement 39.2: Display percentage of c with color coding
func _create_light_speed_display(parent: Node3D) -> void:
	"""Create light speed percentage display with color coding."""
	light_speed_label = Label3D.new()
	light_speed_label.name = "LightSpeedLabel"
	light_speed_label.position = Vector3(-0.5, 0.15, 0)
	light_speed_label.text = "Speed: 0.0% of c"
	light_speed_label.font_size = 36
	light_speed_label.modulate = COLOR_NORMAL
	light_speed_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	light_speed_label.no_depth_test = true
	light_speed_label.render_priority = 10
	parent.add_child(light_speed_label)


## Create SNR health display with progress bar
## Requirement 39.3: Display SNR percentage with visual health bar
func _create_snr_display(parent: Node3D) -> void:
	"""Create SNR percentage display with visual health bar."""
	# SNR percentage label
	snr_label = Label3D.new()
	snr_label.name = "SNRLabel"
	snr_label.position = Vector3(-0.5, 0.0, 0)
	snr_label.text = "Signal: 100%"
	snr_label.font_size = 32
	snr_label.modulate = COLOR_GOOD
	snr_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	snr_label.no_depth_test = true
	snr_label.render_priority = 10
	parent.add_child(snr_label)
	
	# Create visual health bar using a MeshInstance3D
	_create_snr_health_bar(parent)


## Create visual health bar for SNR
func _create_snr_health_bar(parent: Node3D) -> void:
	"""Create a 3D health bar for SNR visualization."""
	# Background bar (dark)
	var bar_background = MeshInstance3D.new()
	bar_background.name = "SNRBarBackground"
	bar_background.position = Vector3(0.2, 0.0, 0)
	
	var bg_mesh = BoxMesh.new()
	bg_mesh.size = Vector3(0.5, 0.05, 0.01)
	bar_background.mesh = bg_mesh
	
	var bg_material = StandardMaterial3D.new()
	bg_material.albedo_color = Color(0.2, 0.2, 0.2, 0.8)
	bg_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bar_background.material_override = bg_material
	
	parent.add_child(bar_background)
	
	# Foreground bar (colored, scales with SNR)
	snr_bar = MeshInstance3D.new()
	snr_bar.name = "SNRBar"
	snr_bar.position = Vector3(0.2, 0.0, 0.001)  # Slightly in front
	
	var fg_mesh = BoxMesh.new()
	fg_mesh.size = Vector3(0.5, 0.05, 0.01)
	snr_bar.mesh = fg_mesh
	
	var fg_material = StandardMaterial3D.new()
	fg_material.albedo_color = COLOR_GOOD
	fg_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fg_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fg_material.emission_enabled = true
	fg_material.emission = COLOR_GOOD
	fg_material.emission_energy_multiplier = 0.5
	snr_bar.material_override = fg_material
	
	parent.add_child(snr_bar)


## Create escape velocity comparison display
## Requirement 39.4: Display escape velocity comparison in gravity wells
func _create_escape_velocity_display(parent: Node3D) -> void:
	"""Create escape velocity comparison display."""
	escape_velocity_label = Label3D.new()
	escape_velocity_label.name = "EscapeVelocityLabel"
	escape_velocity_label.position = Vector3(-0.5, -0.15, 0)
	escape_velocity_label.text = "Escape Velocity: N/A"
	escape_velocity_label.font_size = 28
	escape_velocity_label.modulate = COLOR_NORMAL
	escape_velocity_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	escape_velocity_label.no_depth_test = true
	escape_velocity_label.render_priority = 10
	escape_velocity_label.visible = false  # Only show when near celestial bodies
	parent.add_child(escape_velocity_label)


## Create time display elements
## Requirement 39.5: Display time multiplier and simulated date
func _create_time_display(parent: Node3D) -> void:
	"""Create time multiplier and simulated date display."""
	# Time multiplier label
	time_multiplier_label = Label3D.new()
	time_multiplier_label.name = "TimeMultiplierLabel"
	time_multiplier_label.position = Vector3(-0.5, -0.3, 0)
	time_multiplier_label.text = "Time: 1x"
	time_multiplier_label.font_size = 28
	time_multiplier_label.modulate = COLOR_NORMAL
	time_multiplier_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	time_multiplier_label.no_depth_test = true
	time_multiplier_label.render_priority = 10
	parent.add_child(time_multiplier_label)
	
	# Simulated date label
	simulated_date_label = Label3D.new()
	simulated_date_label.name = "SimulatedDateLabel"
	simulated_date_label.position = Vector3(-0.5, -0.4, 0)
	simulated_date_label.text = "Date: 2000-01-01 12:00:00"
	simulated_date_label.font_size = 24
	simulated_date_label.modulate = COLOR_NORMAL
	simulated_date_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	simulated_date_label.no_depth_test = true
	simulated_date_label.render_priority = 10
	parent.add_child(simulated_date_label)


## Connect to system signals for reactive updates
func _connect_signals() -> void:
	"""Connect to signals from game systems."""
	if spacecraft:
		spacecraft.velocity_changed.connect(_on_spacecraft_velocity_changed)
	
	if signal_manager:
		signal_manager.snr_changed.connect(_on_snr_changed)
		signal_manager.signal_critical.connect(_on_signal_critical)
		signal_manager.signal_low.connect(_on_signal_low)
	
	if time_manager:
		time_manager.time_acceleration_changed.connect(_on_time_acceleration_changed)
		time_manager.simulation_date_changed.connect(_on_simulation_date_changed)


#endregion

#region Data Updates

## Update all HUD data from game systems
func _update_hud_data() -> void:
	"""Gather data from all game systems."""
	# Update velocity data
	if spacecraft:
		_current_velocity = spacecraft.get_velocity()
		_current_speed = spacecraft.get_velocity_magnitude()
	
	# Update SNR data
	if signal_manager:
		_current_snr_percentage = signal_manager.get_snr_percentage()
	
	# Update escape velocity data
	_update_escape_velocity_data()


## Update escape velocity data from nearest celestial body
func _update_escape_velocity_data() -> void:
	"""Update escape velocity from nearest celestial body."""
	var engine_node = get_node_or_null("/root/ResonanceEngine")
	if not engine_node:
		return
	
	if engine_node.has_method("get_physics_engine"):
		var physics_engine = engine_node.get_physics_engine()
		if physics_engine and physics_engine.has_method("get_nearest_celestial_body"):
			nearest_celestial_body = physics_engine.get_nearest_celestial_body()
			
			if nearest_celestial_body and spacecraft:
				_current_escape_velocity = nearest_celestial_body.get_escape_velocity_at_point(
					spacecraft.global_position
				)


#endregion

#region Display Updates

## Update all HUD display elements
func _update_hud_display() -> void:
	"""Update all HUD visual elements with current data."""
	_update_velocity_display()
	_update_light_speed_display()
	_update_snr_display()
	_update_escape_velocity_display()
	_update_time_display()


## Update velocity display
## Requirement 39.1: Display velocity magnitude and direction
func _update_velocity_display() -> void:
	"""Update velocity magnitude and direction labels."""
	if not velocity_label or not velocity_direction_label:
		return
	
	# Update magnitude
	velocity_label.text = "Velocity: %.1f m/s" % _current_speed
	
	# Update direction (normalized)
	if _current_velocity.length_squared() > 0.001:
		var direction = _current_velocity.normalized()
		velocity_direction_label.text = "Direction: (%.2f, %.2f, %.2f)" % [
			direction.x, direction.y, direction.z
		]
	else:
		velocity_direction_label.text = "Direction: (0.0, 0.0, 0.0)"


## Update light speed percentage display with color coding
## Requirement 39.2: Display percentage of c with color coding
func _update_light_speed_display() -> void:
	"""Update light speed percentage with color coding."""
	if not light_speed_label:
		return
	
	var percentage_of_c: float = 0.0
	
	if relativity_manager:
		percentage_of_c = relativity_manager.get_velocity_as_percentage_of_c()
	elif spacecraft:
		percentage_of_c = spacecraft.get_velocity_fraction_of_c() * 100.0
	
	light_speed_label.text = "Speed: %.2f%% of c" % percentage_of_c
	
	# Color coding based on speed
	# Green at low speeds, yellow at medium, red approaching c
	if percentage_of_c < 50.0:
		light_speed_label.modulate = COLOR_GOOD
	elif percentage_of_c < 80.0:
		light_speed_label.modulate = COLOR_WARNING
	else:
		light_speed_label.modulate = COLOR_CRITICAL


## Update SNR display with health bar
## Requirement 39.3: Display SNR percentage with visual health bar
func _update_snr_display() -> void:
	"""Update SNR percentage label and health bar."""
	if not snr_label or not snr_bar:
		return
	
	var snr_percent = _current_snr_percentage * 100.0
	snr_label.text = "Signal: %.0f%%" % snr_percent
	
	# Color coding based on SNR
	var display_color: Color
	if _current_snr_percentage > WARNING_THRESHOLD:
		display_color = COLOR_GOOD
	elif _current_snr_percentage > CRITICAL_THRESHOLD:
		display_color = COLOR_WARNING
	else:
		display_color = COLOR_CRITICAL
	
	snr_label.modulate = display_color
	
	# Update health bar scale and color
	snr_bar.scale.x = _current_snr_percentage
	
	var bar_material = snr_bar.material_override as StandardMaterial3D
	if bar_material:
		bar_material.albedo_color = display_color
		bar_material.emission = display_color


## Update escape velocity comparison display
## Requirement 39.4: Display escape velocity comparison in gravity wells
func _update_escape_velocity_display() -> void:
	"""Update escape velocity comparison display."""
	if not escape_velocity_label:
		return
	
	# Only show when near a celestial body
	if nearest_celestial_body and _current_escape_velocity > 0.1:
		escape_velocity_label.visible = true
		
		# Show comparison: current velocity vs escape velocity
		var comparison_text = "Escape: %.1f m/s (Current: %.1f m/s)" % [
			_current_escape_velocity,
			_current_speed
		]
		
		escape_velocity_label.text = comparison_text
		
		# Color code based on whether we're above or below escape velocity
		if _current_speed >= _current_escape_velocity:
			escape_velocity_label.modulate = COLOR_GOOD  # Can escape
		elif _current_speed >= _current_escape_velocity * 0.8:
			escape_velocity_label.modulate = COLOR_WARNING  # Close to escape
		else:
			escape_velocity_label.modulate = COLOR_CRITICAL  # Captured
	else:
		escape_velocity_label.visible = false


## Update time display
## Requirement 39.5: Display time multiplier and simulated date
func _update_time_display() -> void:
	"""Update time multiplier and simulated date labels."""
	if not time_multiplier_label or not simulated_date_label:
		return
	
	if time_manager:
		# Update time multiplier
		var time_factor = time_manager.get_time_factor()
		time_multiplier_label.text = "Time: %s" % time_manager.get_formatted_time_factor()
		
		# Highlight when time is accelerated
		if time_factor > 1.0:
			time_multiplier_label.modulate = COLOR_WARNING
		else:
			time_multiplier_label.modulate = COLOR_NORMAL
		
		# Update simulated date
		simulated_date_label.text = "Date: %s" % time_manager.get_formatted_date()


#endregion

#region Signal Handlers

## Handle spacecraft velocity changes
func _on_spacecraft_velocity_changed(velocity: Vector3, speed: float) -> void:
	"""React to spacecraft velocity changes."""
	_current_velocity = velocity
	_current_speed = speed


## Handle SNR changes
func _on_snr_changed(snr: float, percentage: float) -> void:
	"""React to SNR changes."""
	_current_snr_percentage = percentage


## Handle critical signal strength
func _on_signal_critical(snr_percentage: float) -> void:
	"""React to critical signal strength."""
	# Could add pulsing effect or additional warnings here
	pass


## Handle low signal strength
func _on_signal_low(snr_percentage: float) -> void:
	"""React to low signal strength."""
	# Could add visual warnings here
	pass


## Handle time acceleration changes
func _on_time_acceleration_changed(new_factor: float) -> void:
	"""React to time acceleration changes."""
	# Update will happen on next display update
	pass


## Handle simulation date changes
func _on_simulation_date_changed(julian_date: float, calendar_date: Dictionary) -> void:
	"""React to simulation date changes."""
	# Update will happen on next display update
	pass


#endregion

#region Public Interface

## Set the spacecraft reference
func set_spacecraft(craft: Spacecraft) -> void:
	"""Set the spacecraft reference."""
	spacecraft = craft
	if spacecraft and not spacecraft.velocity_changed.is_connected(_on_spacecraft_velocity_changed):
		spacecraft.velocity_changed.connect(_on_spacecraft_velocity_changed)


## Set the signal manager reference
func set_signal_manager(manager: SignalManager) -> void:
	"""Set the signal manager reference."""
	signal_manager = manager
	if signal_manager:
		if not signal_manager.snr_changed.is_connected(_on_snr_changed):
			signal_manager.snr_changed.connect(_on_snr_changed)
		if not signal_manager.signal_critical.is_connected(_on_signal_critical):
			signal_manager.signal_critical.connect(_on_signal_critical)
		if not signal_manager.signal_low.is_connected(_on_signal_low):
			signal_manager.signal_low.connect(_on_signal_low)


## Set the time manager reference
func set_time_manager(manager: TimeManager) -> void:
	"""Set the time manager reference."""
	time_manager = manager
	if time_manager:
		if not time_manager.time_acceleration_changed.is_connected(_on_time_acceleration_changed):
			time_manager.time_acceleration_changed.connect(_on_time_acceleration_changed)
		if not time_manager.simulation_date_changed.is_connected(_on_simulation_date_changed):
			time_manager.simulation_date_changed.connect(_on_simulation_date_changed)


## Set the relativity manager reference
func set_relativity_manager(manager) -> void:
	"""Set the relativity manager reference."""
	relativity_manager = manager


## Set the nearest celestial body
func set_nearest_celestial_body(body: CelestialBody) -> void:
	"""Set the nearest celestial body for escape velocity calculations."""
	nearest_celestial_body = body


## Update velocity display with new velocity data
func update_velocity(velocity: Vector3) -> void:
	"""Update velocity display with new velocity data."""
	_current_velocity = velocity
	_current_speed = velocity.length()
	_update_velocity_display()
	print("HUD: Updated velocity display - Speed: %.1f m/s" % _current_speed)


## Update SNR display with signal strength and noise level
func update_snr(signal_strength: float, noise_level: float) -> void:
	"""Update SNR display with signal strength and noise level."""
	if signal_manager:
		# Calculate SNR percentage
		var total = signal_strength + noise_level
		if total > 0:
			_current_snr_percentage = signal_strength / total
		else:
			_current_snr_percentage = 1.0
		
		_update_snr_display()
		print("HUD: Updated SNR display - Signal: %.0f%%" % (_current_snr_percentage * 100.0))


## Update escape velocity display for given planet parameters
func update_escape_velocity(planet_mass: float, radius: float) -> void:
	"""Update escape velocity display for given planet parameters."""
	# Calculate escape velocity using formula: sqrt(2GM/r)
	var G = 6.67430e-11  # Gravitational constant
	_current_escape_velocity = sqrt(2 * G * planet_mass / radius)
	
	if escape_velocity_label:
		escape_velocity_label.visible = true
		escape_velocity_label.text = "Escape: %.1f m/s" % _current_escape_velocity
		
		# Color code based on current speed comparison
		if _current_speed >= _current_escape_velocity:
			escape_velocity_label.modulate = COLOR_GOOD
		elif _current_speed >= _current_escape_velocity * 0.8:
			escape_velocity_label.modulate = COLOR_WARNING
		else:
			escape_velocity_label.modulate = COLOR_CRITICAL
	
	print("HUD: Updated escape velocity - %.1f m/s" % _current_escape_velocity)


## Update time display with unix timestamp
func update_time(unix_timestamp: float) -> void:
	"""Update time display with unix timestamp."""
	if time_manager and time_manager.has_method("set_simulation_time"):
		time_manager.set_simulation_time(unix_timestamp)
		_update_time_display()
		print("HUD: Updated time display - Timestamp: %.0f" % unix_timestamp)


## Update position display with current position
func update_position(position: Vector3) -> void:
	"""Update position display with current position."""
	_current_velocity = position  # Reuse velocity variable for position update
	_update_velocity_display()
	print("HUD: Updated position display - Position: (%.1f, %.1f, %.1f)" % [position.x, position.y, position.z])


## Show the HUD
func show_hud() -> void:
	"""Show the HUD."""
	visible = true


## Hide the HUD
func hide_hud() -> void:
	"""Hide the HUD."""
	visible = false


## Toggle HUD visibility
func toggle_hud() -> void:
	"""Toggle HUD visibility."""
	visible = not visible


#endregion
