## WarningSystem - Audio and Visual Warning Indicators
## Provides warnings for dangerous situations including gravity wells, low SNR,
## collisions, and critical system failures with clear resolution instructions.
##
## Requirements: 42.1, 42.2, 42.3, 42.4, 42.5
## - 42.1: Display red warning for dangerous gravity approach with alert sound
## - 42.2: Pulse HUD red when signal strength drops below 25% with degrading audio
## - 42.3: Display proximity warning with time to impact for collision courses
## - 42.4: Display critical system failure warning when entropy exceeds 75%
## - 42.5: Provide clear instructions on how to resolve the danger
extends Node3D
class_name WarningSystem

# Preload custom classes for type references
const Spacecraft = preload("res://scripts/player/spacecraft.gd")
const SignalManager = preload("res://scripts/player/signal_manager.gd")
## Warning types
enum WarningType {
	NONE,
	GRAVITY_DANGER,      ## Approaching gravity well too fast
	SNR_CRITICAL,        ## Signal strength below 25%
	COLLISION_WARNING,   ## On collision course
	SYSTEM_FAILURE       ## Entropy exceeds 75%
}

## Emitted when a warning is triggered
signal warning_triggered(warning_type: WarningType, severity: float)
## Emitted when a warning is cleared
signal warning_cleared(warning_type: WarningType)
## Emitted when warning severity changes
signal warning_severity_changed(warning_type: WarningType, severity: float)

#region References

## Reference to spacecraft
var spacecraft: Spacecraft = null
## Reference to signal manager
var signal_manager: SignalManager = null
## Reference to physics engine
var physics_engine: PhysicsEngine = null
## Reference to HUD for pulsing effects
var hud: HUD = null

#endregion

#region UI Elements

## Warning label for displaying messages
var warning_label: Label3D = null
## Resolution instructions label
var resolution_label: Label3D = null
## Warning indicator (flashing red panel)
var warning_indicator: MeshInstance3D = null

#endregion

#region Configuration

## Position offset from player camera
@export var warning_offset: Vector3 = Vector3(0, 0.5, -1.5)
## Warning scale
@export var warning_scale: float = 0.6

## Gravity warning thresholds
@export var gravity_danger_distance: float = 500.0  ## Distance threshold
@export var gravity_danger_velocity: float = 100.0  ## Velocity threshold

## SNR critical threshold (25%)
const SNR_CRITICAL_THRESHOLD: float = 0.25

## Entropy critical threshold (75%)
const ENTROPY_CRITICAL_THRESHOLD: float = 0.75

## Collision warning time threshold (seconds)
@export var collision_warning_time: float = 5.0

## Pulse frequency for warnings (Hz)
@export var pulse_frequency: float = 2.0

## Audio alert volume
@export var alert_volume_db: float = -10.0

#endregion

#region Runtime State

## Active warnings
var active_warnings: Dictionary = {}

## Pulse timer for visual effects
var pulse_timer: float = 0.0

## Current pulse intensity (0.0 to 1.0)
var pulse_intensity: float = 0.0

## Audio player for alert sounds
var audio_player: AudioStreamPlayer3D = null

## Degrading audio effect for SNR warnings
var audio_effect_bus: int = -1

#endregion

#region Colors

const COLOR_WARNING: Color = Color(1.0, 0.2, 0.2, 0.9)  ## Red
const COLOR_CRITICAL: Color = Color(1.0, 0.0, 0.0, 1.0)  ## Bright red
const COLOR_NORMAL: Color = Color(0.0, 1.0, 0.8, 0.8)    ## Cyan

#endregion


func _ready() -> void:
	_find_system_references()
	_create_warning_elements()
	_setup_audio()
	_connect_signals()


func _process(delta: float) -> void:
	# Update pulse timer
	pulse_timer += delta * pulse_frequency * TAU
	pulse_intensity = (sin(pulse_timer) + 1.0) * 0.5  # 0.0 to 1.0
	
	# Check for warnings
	_check_gravity_warning()
	_check_snr_warning()
	_check_collision_warning()
	_check_system_failure_warning()
	
	# Update visual effects
	_update_warning_display()


#region Initialization

## Find references to game systems
func _find_system_references() -> void:
	"""Find references to spacecraft, signal manager, and physics engine."""
	var engine_node = get_node_or_null("/root/ResonanceEngine")
	
	if engine_node:
		if engine_node.has_method("get_spacecraft"):
			spacecraft = engine_node.get_spacecraft()
		
		if engine_node.has_method("get_signal_manager"):
			signal_manager = engine_node.get_signal_manager()
		
		if engine_node.has_method("get_physics_engine"):
			physics_engine = engine_node.get_physics_engine()
		
		if engine_node.has_method("get_hud"):
			hud = engine_node.get_hud()


## Create warning UI elements
func _create_warning_elements() -> void:
	"""Create all warning UI elements."""
	var warning_container = Node3D.new()
	warning_container.name = "WarningContainer"
	add_child(warning_container)
	warning_container.scale = Vector3.ONE * warning_scale
	
	# Create warning indicator (flashing red panel)
	_create_warning_indicator(warning_container)
	
	# Create warning message label
	_create_warning_label(warning_container)
	
	# Create resolution instructions label
	_create_resolution_label(warning_container)


## Create visual warning indicator
func _create_warning_indicator(parent: Node3D) -> void:
	"""Create a flashing red warning indicator."""
	warning_indicator = MeshInstance3D.new()
	warning_indicator.name = "WarningIndicator"
	warning_indicator.position = Vector3(0, 0.2, 0)
	
	var mesh = BoxMesh.new()
	mesh.size = Vector3(1.0, 0.1, 0.01)
	warning_indicator.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = COLOR_WARNING
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = COLOR_WARNING
	material.emission_energy_multiplier = 2.0
	warning_indicator.material_override = material
	
	warning_indicator.visible = false
	parent.add_child(warning_indicator)


## Create warning message label
func _create_warning_label(parent: Node3D) -> void:
	"""Create warning message label."""
	warning_label = Label3D.new()
	warning_label.name = "WarningLabel"
	warning_label.position = Vector3(0, 0.1, 0)
	warning_label.text = ""
	warning_label.font_size = 48
	warning_label.modulate = COLOR_WARNING
	warning_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	warning_label.no_depth_test = true
	warning_label.render_priority = 20
	warning_label.visible = false
	parent.add_child(warning_label)


## Create resolution instructions label
func _create_resolution_label(parent: Node3D) -> void:
	"""Create resolution instructions label."""
	resolution_label = Label3D.new()
	resolution_label.name = "ResolutionLabel"
	resolution_label.position = Vector3(0, 0.0, 0)
	resolution_label.text = ""
	resolution_label.font_size = 32
	resolution_label.modulate = COLOR_NORMAL
	resolution_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	resolution_label.no_depth_test = true
	resolution_label.render_priority = 20
	resolution_label.visible = false
	parent.add_child(resolution_label)


## Setup audio system
func _setup_audio() -> void:
	"""Setup audio player for alert sounds."""
	audio_player = AudioStreamPlayer3D.new()
	audio_player.name = "AlertAudioPlayer"
	audio_player.volume_db = alert_volume_db
	audio_player.max_distance = 100.0
	add_child(audio_player)


## Connect to system signals
func _connect_signals() -> void:
	"""Connect to signals from game systems."""
	if signal_manager:
		signal_manager.signal_critical.connect(_on_signal_critical)
		signal_manager.entropy_changed.connect(_on_entropy_changed)
	
	if spacecraft:
		spacecraft.collision_occurred.connect(_on_collision_occurred)


#endregion

#region Warning Checks

## Check for gravity well danger
## Requirement 42.1: Display red warning for dangerous gravity approach
func _check_gravity_warning() -> void:
	"""Check if approaching a gravity well too fast."""
	if not spacecraft or not physics_engine:
		_clear_warning(WarningType.GRAVITY_DANGER)
		return
	
	# Get nearest celestial body
	var nearest_body = physics_engine.get_nearest_celestial_body() if physics_engine.has_method("get_nearest_celestial_body") else null
	
	if not nearest_body:
		_clear_warning(WarningType.GRAVITY_DANGER)
		return
	
	# Calculate distance to body
	var distance = spacecraft.global_position.distance_to(nearest_body.global_position)
	var velocity = spacecraft.get_velocity_magnitude()
	
	# Check if we're approaching too fast
	var is_dangerous = distance < gravity_danger_distance and velocity > gravity_danger_velocity
	
	if is_dangerous:
		# Calculate severity based on distance and velocity
		var distance_factor = 1.0 - (distance / gravity_danger_distance)
		var velocity_factor = velocity / (gravity_danger_velocity * 2.0)
		var severity = clampf((distance_factor + velocity_factor) * 0.5, 0.0, 1.0)
		
		var escape_velocity = nearest_body.get_escape_velocity_at_point(spacecraft.global_position) if nearest_body.has_method("get_escape_velocity_at_point") else 0.0
		
		_trigger_warning(
			WarningType.GRAVITY_DANGER,
			"WARNING: DANGEROUS GRAVITY APPROACH",
			"Reduce velocity or change course to avoid capture\nEscape velocity: %.1f m/s" % escape_velocity,
			severity
		)
	else:
		_clear_warning(WarningType.GRAVITY_DANGER)


## Check for critical SNR
## Requirement 42.2: Pulse HUD red when signal strength drops below 25%
func _check_snr_warning() -> void:
	"""Check if SNR is critically low."""
	if not signal_manager:
		_clear_warning(WarningType.SNR_CRITICAL)
		return
	
	var snr_percentage = signal_manager.get_snr_percentage()
	
	if snr_percentage <= SNR_CRITICAL_THRESHOLD:
		var severity = 1.0 - (snr_percentage / SNR_CRITICAL_THRESHOLD)
		
		_trigger_warning(
			WarningType.SNR_CRITICAL,
			"CRITICAL: SIGNAL COHERENCE FAILING",
			"Move closer to star nodes to regenerate signal\nAvoid damage sources",
			severity
		)
		
		# Pulse HUD red
		_pulse_hud_red(severity)
	else:
		_clear_warning(WarningType.SNR_CRITICAL)


## Check for collision course
## Requirement 42.3: Display proximity warning with time to impact
func _check_collision_warning() -> void:
	"""Check if on collision course with an object."""
	if not spacecraft or not physics_engine:
		_clear_warning(WarningType.COLLISION_WARNING)
		return
	
	# Perform raycast in direction of travel
	var velocity = spacecraft.get_velocity()
	if velocity.length() < 0.1:
		_clear_warning(WarningType.COLLISION_WARNING)
		return
	
	var direction = velocity.normalized()
	var speed = velocity.length()
	
	# Cast ray ahead
	var ray_distance = speed * collision_warning_time
	var space_state = spacecraft.get_world_3d().direct_space_state
	
	var query = PhysicsRayQueryParameters3D.create(
		spacecraft.global_position,
		spacecraft.global_position + direction * ray_distance
	)
	query.exclude = [spacecraft]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		# Calculate time to impact
		var distance_to_impact = spacecraft.global_position.distance_to(result.position)
		var time_to_impact = distance_to_impact / speed
		
		if time_to_impact <= collision_warning_time:
			var severity = 1.0 - (time_to_impact / collision_warning_time)
			
			_trigger_warning(
				WarningType.COLLISION_WARNING,
				"COLLISION WARNING: %.1f SECONDS" % time_to_impact,
				"Change course immediately or reduce velocity\nObject: %s" % result.collider.name,
				severity
			)
		else:
			_clear_warning(WarningType.COLLISION_WARNING)
	else:
		_clear_warning(WarningType.COLLISION_WARNING)


## Check for system failure
## Requirement 42.4: Display critical system failure warning when entropy exceeds 75%
func _check_system_failure_warning() -> void:
	"""Check if entropy indicates system failure."""
	if not signal_manager:
		_clear_warning(WarningType.SYSTEM_FAILURE)
		return
	
	var entropy = signal_manager.get_entropy()
	
	if entropy >= ENTROPY_CRITICAL_THRESHOLD:
		var severity = (entropy - ENTROPY_CRITICAL_THRESHOLD) / (1.0 - ENTROPY_CRITICAL_THRESHOLD)
		
		_trigger_warning(
			WarningType.SYSTEM_FAILURE,
			"CRITICAL: SYSTEM FAILURE IMMINENT",
			"Entropy at critical levels - seek repair immediately\nAvoid further damage",
			severity
		)
	else:
		_clear_warning(WarningType.SYSTEM_FAILURE)


#endregion

#region Warning Management

## Trigger a warning
## Requirement 42.5: Provide clear instructions on how to resolve the danger
func _trigger_warning(type: WarningType, message: String, resolution: String, severity: float) -> void:
	"""Trigger a warning with message and resolution instructions."""
	var was_active = active_warnings.has(type)
	
	active_warnings[type] = {
		"message": message,
		"resolution": resolution,
		"severity": severity,
		"time": Time.get_ticks_msec() / 1000.0
	}
	
	if not was_active:
		warning_triggered.emit(type, severity)
		_play_alert_sound(type, severity)
	else:
		warning_severity_changed.emit(type, severity)


## Clear a warning
func _clear_warning(type: WarningType) -> void:
	"""Clear a specific warning."""
	if active_warnings.has(type):
		active_warnings.erase(type)
		warning_cleared.emit(type)


## Clear all warnings
func clear_all_warnings() -> void:
	"""Clear all active warnings."""
	for type in active_warnings.keys():
		warning_cleared.emit(type)
	active_warnings.clear()


## Get highest priority warning
func _get_highest_priority_warning() -> Dictionary:
	"""Get the warning with highest severity."""
	if active_warnings.is_empty():
		return {}
	
	var highest = null
	var highest_severity = -1.0
	
	for type in active_warnings:
		var warning = active_warnings[type]
		if warning.severity > highest_severity:
			highest_severity = warning.severity
			highest = warning
	
	return highest if highest else {}


#endregion

#region Visual Effects

## Update warning display
func _update_warning_display() -> void:
	"""Update visual warning elements."""
	var highest_warning = _get_highest_priority_warning()
	
	if highest_warning.is_empty():
		# No warnings - hide everything
		if warning_indicator:
			warning_indicator.visible = false
		if warning_label:
			warning_label.visible = false
		if resolution_label:
			resolution_label.visible = false
		return
	
	# Show warning elements
	if warning_indicator:
		warning_indicator.visible = true
		# Pulse the indicator
		var material = warning_indicator.material_override as StandardMaterial3D
		if material:
			var pulse_alpha = 0.5 + (pulse_intensity * 0.5)
			var color = COLOR_WARNING
			color.a = pulse_alpha
			material.albedo_color = color
			material.emission_energy_multiplier = 1.0 + (pulse_intensity * 2.0)
	
	# Update warning message
	if warning_label:
		warning_label.visible = true
		warning_label.text = highest_warning.message
		# Pulse the text color
		var pulse_color = COLOR_WARNING.lerp(COLOR_CRITICAL, pulse_intensity * highest_warning.severity)
		warning_label.modulate = pulse_color
	
	# Update resolution instructions
	## Requirement 42.5: Provide clear instructions
	if resolution_label:
		resolution_label.visible = true
		resolution_label.text = highest_warning.resolution


## Pulse HUD red for critical SNR
## Requirement 42.2: Pulse HUD red when signal strength drops below 25%
func _pulse_hud_red(severity: float) -> void:
	"""Pulse the HUD red for critical signal warnings."""
	if not hud:
		return
	
	# Apply red tint to HUD based on pulse
	var pulse_color = Color.WHITE.lerp(COLOR_CRITICAL, pulse_intensity * severity * 0.5)
	
	# This would require HUD to have a modulate property or method
	if hud.has_method("set_warning_tint"):
		hud.set_warning_tint(pulse_color)


#endregion

#region Audio

## Play alert sound
## Requirement 42.1: Play an alert sound
## Requirement 42.2: Play a degrading audio tone
func _play_alert_sound(type: WarningType, severity: float) -> void:
	"""Play appropriate alert sound for warning type."""
	if not audio_player:
		return
	
	# Generate alert tone based on warning type
	match type:
		WarningType.GRAVITY_DANGER:
			_play_gravity_alert(severity)
		WarningType.SNR_CRITICAL:
			_play_snr_alert(severity)
		WarningType.COLLISION_WARNING:
			_play_collision_alert(severity)
		WarningType.SYSTEM_FAILURE:
			_play_system_failure_alert(severity)


## Play gravity danger alert
func _play_gravity_alert(severity: float) -> void:
	"""Play gravity danger alert sound."""
	# Create a low-frequency warning tone
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.1
	
	audio_player.stream = generator
	audio_player.play()


## Play SNR critical alert
## Requirement 42.2: Play a degrading audio tone
func _play_snr_alert(severity: float) -> void:
	"""Play degrading audio tone for SNR warning."""
	# Create a degrading tone that gets worse with severity
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.1
	
	audio_player.stream = generator
	audio_player.pitch_scale = 1.0 - (severity * 0.3)  # Lower pitch as severity increases
	audio_player.play()


## Play collision warning alert
func _play_collision_alert(severity: float) -> void:
	"""Play collision warning alert sound."""
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.05
	
	audio_player.stream = generator
	audio_player.play()


## Play system failure alert
func _play_system_failure_alert(severity: float) -> void:
	"""Play system failure alert sound."""
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.1
	
	audio_player.stream = generator
	audio_player.play()


#endregion

#region Signal Handlers

## Handle signal critical event
func _on_signal_critical(snr_percentage: float) -> void:
	"""React to critical signal strength."""
	# Warning check will handle this in _process
	pass


## Handle entropy changes
func _on_entropy_changed(entropy: float) -> void:
	"""React to entropy changes."""
	# Warning check will handle this in _process
	pass


## Handle collision events
func _on_collision_occurred(collision_info: Dictionary) -> void:
	"""React to actual collisions."""
	# Could add impact warning here
	pass


#endregion

#region Public Interface

## Set spacecraft reference
func set_spacecraft(craft: Spacecraft) -> void:
	"""Set the spacecraft reference."""
	spacecraft = craft
	if spacecraft and not spacecraft.collision_occurred.is_connected(_on_collision_occurred):
		spacecraft.collision_occurred.connect(_on_collision_occurred)


## Set signal manager reference
func set_signal_manager(manager: SignalManager) -> void:
	"""Set the signal manager reference."""
	signal_manager = manager
	if signal_manager:
		if not signal_manager.signal_critical.is_connected(_on_signal_critical):
			signal_manager.signal_critical.connect(_on_signal_critical)
		if not signal_manager.entropy_changed.is_connected(_on_entropy_changed):
			signal_manager.entropy_changed.connect(_on_entropy_changed)


## Set physics engine reference
func set_physics_engine(engine: PhysicsEngine) -> void:
	"""Set the physics engine reference."""
	physics_engine = engine


## Set HUD reference
func set_hud(hud_ref: HUD) -> void:
	"""Set the HUD reference for pulsing effects."""
	hud = hud_ref


## Check if any warnings are active
func has_active_warnings() -> bool:
	"""Check if any warnings are currently active."""
	return not active_warnings.is_empty()


## Get all active warnings
func get_active_warnings() -> Array:
	"""Get list of all active warning types."""
	return active_warnings.keys()


## Get warning info
func get_warning_info(type: WarningType) -> Dictionary:
	"""Get information about a specific warning."""
	return active_warnings.get(type, {})


## Enable/disable warning system
func set_enabled(enabled: bool) -> void:
	"""Enable or disable the warning system."""
	visible = enabled
	if not enabled:
		clear_all_warnings()


## Check gravity warning for spacecraft near celestial body
func check_gravity_warning(spacecraft: Spacecraft, planet: CelestialBody) -> void:
	"""Check gravity warning for spacecraft near celestial body."""
	if not spacecraft or not planet:
		return
	
	# Calculate distance and check for dangerous approach
	var distance = spacecraft.global_position.distance_to(planet.global_position)
	var velocity = spacecraft.get_velocity_magnitude()
	var escape_velocity = planet.get_escape_velocity_at_point(spacecraft.global_position)
	
	# Check if approach is dangerous
	if distance < gravity_danger_distance and velocity > gravity_danger_velocity:
		var severity = 1.0 - (distance / gravity_danger_distance)
		_trigger_warning(
			WarningType.GRAVITY_DANGER,
			"GRAVITY WARNING: Dangerous approach detected",
			"Reduce velocity below %.1f m/s or increase distance" % escape_velocity,
			severity
		)
		print("WarningSystem: Gravity warning triggered - Severity: %.2f" % severity)
	else:
		_clear_warning(WarningType.GRAVITY_DANGER)


## Check SNR warning based on signal strength threshold
func check_snr_warning(signal_strength: float, threshold: float) -> void:
	"""Check SNR warning based on signal strength threshold."""
	if signal_strength < threshold:
		var severity = 1.0 - (signal_strength / threshold)
		_trigger_warning(
			WarningType.SNR_CRITICAL,
			"SNR WARNING: Signal strength below threshold",
			"Move closer to signal source or reduce interference",
			severity
		)
		print("WarningSystem: SNR warning triggered - Strength: %.1f, Threshold: %.1f" % [signal_strength, threshold])
		_pulse_hud_red(severity)
	else:
		_clear_warning(WarningType.SNR_CRITICAL)


## Check collision warning based on trajectory and obstacles
func check_collision_warning(trajectory: Array, obstacles: Array) -> void:
	"""Check collision warning based on trajectory and obstacles."""
	if trajectory.is_empty() or obstacles.is_empty():
		_clear_warning(WarningType.COLLISION_WARNING)
		return
	
	# Check each trajectory point against each obstacle
	for point in trajectory:
		for obstacle in obstacles:
			if not obstacle or not obstacle.has_method("get_global_position") or not obstacle.has_method("get_radius"):
				continue
			
			var obstacle_pos = obstacle.get_global_position()
			var obstacle_radius = obstacle.get_radius()
			var distance = point.distance_to(obstacle_pos)
			
			# Check if trajectory passes through obstacle
			if distance < obstacle_radius:
				var severity = 1.0 - (distance / obstacle_radius)
				_trigger_warning(
					WarningType.COLLISION_WARNING,
					"COLLISION WARNING: Trajectory intersects obstacle",
					"Alter course to avoid %s" % obstacle.name,
					severity
				)
				print("WarningSystem: Collision warning triggered - Obstacle: %s" % obstacle.name)
				return
	
	_clear_warning(WarningType.COLLISION_WARNING)


## Show system failure warning with system name and failure type
func show_system_failure(system_name: String, failure_type: String) -> void:
	"""Show system failure warning with system name and failure type."""
	var severity = 1.0  # System failures are always critical
	
	var message = "SYSTEM FAILURE: %s - %s" % [system_name.to_upper(), failure_type.to_upper()]
	var resolution = "System requires immediate attention. Check system diagnostics."
	
	_trigger_warning(WarningType.SYSTEM_FAILURE, message, resolution, severity)
	print("WarningSystem: System failure warning - %s: %s" % [system_name, failure_type])


## Show resolution instructions for specific warning type
func show_resolution_instructions(warning_type: String) -> void:
	"""Show resolution instructions for specific warning type."""
	var instructions = ""
	
	match warning_type:
		"gravity":
			instructions = "To resolve gravity warning:\n1. Reduce velocity\n2. Increase distance from celestial body\n3. Engage reverse thrusters if needed"
		"snr":
			instructions = "To resolve SNR warning:\n1. Move closer to signal source\n2. Avoid signal interference\n3. Check antenna alignment"
		"collision":
			instructions = "To resolve collision warning:\n1. Alter course immediately\n2. Reduce velocity\n3. Engage emergency maneuvers"
		"system_failure":
			instructions = "To resolve system failure:\n1. Identify failed system\n2. Engage backup systems\n3. Seek repair facilities"
		_:
			instructions = "No specific instructions available for this warning type."
	
	if resolution_label:
		resolution_label.text = instructions
		resolution_label.visible = true
	
	print("WarningSystem: Showed resolution instructions for %s" % warning_type)


#endregion
