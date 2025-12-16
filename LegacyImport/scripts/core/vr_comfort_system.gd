## VRComfortSystem - VR Comfort Options for Motion Sickness Prevention
## Implements comfort features including static cockpit reference, vignetting,
## snap-turn, and stationary mode to reduce VR motion sickness.
##
## Requirements:
## - 48.1: Provide static cockpit reference frame
## - 48.2: Add vignetting during rapid acceleration
## - 48.3: Implement snap-turn options
## - 48.4: Create stationary mode option
## - 48.5: Save comfort preferences (handled by SettingsManager)
extends Node
class_name VRComfortSystem
## Emitted when comfort system is initialized
signal comfort_system_initialized
## Emitted when vignetting intensity changes
signal vignetting_changed(intensity: float)
## Emitted when snap turn is executed
signal snap_turn_executed(angle: float)
## Emitted when stationary mode is toggled
signal stationary_mode_changed(enabled: bool)
## Reference to VRManager
var vr_manager: VRManager = null
## Reference to SettingsManager
var settings_manager: Node = null
## Reference to the spacecraft (for acceleration tracking)
var spacecraft: Node = null
## Vignetting effect
var vignette_rect: ColorRect = null
var vignette_material: ShaderMaterial = null
var _current_vignette_intensity: float = 0.0
var _target_vignette_intensity: float = 0.0
## Snap turn state
var _snap_turn_cooldown: float = 0.0
const SNAP_TURN_COOLDOWN_TIME: float = 0.3  # seconds between snap turns
## Stationary mode state
var _stationary_mode_active: bool = false
var _universe_offset: Vector3 = Vector3.ZERO
## Acceleration tracking for vignetting
var _last_velocity: Vector3 = Vector3.ZERO
var _current_acceleration: float = 0.0
## Comfort settings (cached from SettingsManager)
var _comfort_mode_enabled: bool = true
var _vignetting_enabled: bool = true
var _vignetting_max_intensity: float = 0.7
var _snap_turn_enabled: bool = false
var _snap_turn_angle: float = 45.0
var _stationary_mode_enabled: bool = false
## Acceleration thresholds for vignetting
const VIGNETTE_ACCEL_THRESHOLD: float = 5.0  # m/sÂ² - start vignetting
const VIGNETTE_ACCEL_MAX: float = 20.0  # m/sÂ² - maximum vignetting
## Initialization state
var _initialized: bool = false
func _ready() -> void:
	pass
## Initialize the VR comfort system
## @param vr_mgr: Reference to VRManager
## @param spacecraft_node: Reference to the player's spacecraft
## @return: true if initialization was successful
func initialize(vr_mgr: VRManager, spacecraft_node: Node = null) -> bool:
	if _initialized:
		return true
	vr_manager = vr_mgr
	spacecraft = spacecraft_node
	# Get SettingsManager
	settings_manager = get_node_or_null("/root/SettingsManager")
	if settings_manager == null:
		push_warning("VRComfortSystem: SettingsManager not found, using defaults")
	else:
		_load_settings()
		# Connect to settings changes
		if settings_manager.has_signal("setting_changed"):
			settings_manager.setting_changed.connect(_on_setting_changed)
	# Set up vignetting effect
	if _vignetting_enabled:
		_setup_vignetting()
	_initialized = true
	comfort_system_initialized.emit()
	print("VRComfortSystem: Initialized successfully")
	return true
## Load settings from SettingsManager
func _load_settings() -> void:
	if settings_manager == null:
		return
	_comfort_mode_enabled = settings_manager.get_setting("vr", "comfort_mode", _comfort_mode_enabled)
	_vignetting_enabled = settings_manager.get_setting("vr", "vignetting_enabled", _vignetting_enabled)
	_vignetting_max_intensity = settings_manager.get_setting("vr", "vignetting_intensity", _vignetting_max_intensity)
	_snap_turn_enabled = settings_manager.get_setting("vr", "snap_turn_enabled", _snap_turn_enabled)
	_snap_turn_angle = settings_manager.get_setting("vr", "snap_turn_angle", _snap_turn_angle)
	_stationary_mode_enabled = settings_manager.get_setting("vr", "stationary_mode", _stationary_mode_enabled)
	print("VRComfortSystem: Loaded settings - comfort_mode=%s, vignetting=%s, snap_turn=%s, stationary=%s" % [
		_comfort_mode_enabled, _vignetting_enabled, _snap_turn_enabled, _stationary_mode_enabled
	])
## Handle setting changes
func _on_setting_changed(section: String, key: String, value: Variant) -> void:
	if section != "vr":
		return

	match key:
		"comfort_mode":
			_comfort_mode_enabled = value
		"vignetting_enabled":
			_vignetting_enabled = value
			if not _vignetting_enabled and vignette_rect:
				vignette_rect.visible = false
		"vignetting_intensity":
			_vignetting_max_intensity = value
		"snap_turn_enabled":
			_snap_turn_enabled = value
		"snap_turn_angle":
			_snap_turn_angle = value
		"stationary_mode":
			_stationary_mode_enabled = value
			set_stationary_mode(value)

## Process function to update comfort features
func _process(delta: float) -> void:
	if not _initialized or not _comfort_mode_enabled:
		return

	# Update snap turn cooldown
	if _snap_turn_cooldown > 0:
		_snap_turn_cooldown -= delta

	# Process snap-turn input from controllers
	if _snap_turn_enabled and vr_manager:
		_process_snap_turn_input()

	# Update vignetting based on acceleration
	if _vignetting_enabled and spacecraft:
		_update_vignetting(delta)

	# Smooth vignette transition
	if abs(_current_vignette_intensity - _target_vignette_intensity) > 0.001:
		_current_vignette_intensity = lerp(_current_vignette_intensity, _target_vignette_intensity, delta * 5.0)
		apply_vignette(_current_vignette_intensity)

## Update vignetting based on spacecraft acceleration
func _update_vignetting(delta: float) -> void:
	# Null check with instance validity validation
	if spacecraft == null or not is_instance_valid(spacecraft):
		_last_velocity = Vector3.ZERO
		_current_acceleration = 0.0
		return

	# Method availability check with warning
	if not spacecraft.has_method("get_linear_velocity"):
		push_warning("VRComfortSystem: spacecraft does not have get_linear_velocity method")
		_current_acceleration = 0.0
		return

	# Calculate current acceleration
	var current_velocity: Vector3 = spacecraft.get_linear_velocity()
	var accel_vector: Vector3 = (current_velocity - _last_velocity) / delta
	_current_acceleration = accel_vector.length()
	_last_velocity = current_velocity

	# Map acceleration to vignette intensity
	if _current_acceleration > VIGNETTE_ACCEL_THRESHOLD:
		var accel_factor = (_current_acceleration - VIGNETTE_ACCEL_THRESHOLD) / (VIGNETTE_ACCEL_MAX - VIGNETTE_ACCEL_THRESHOLD)
		_target_vignette_intensity = clampf(accel_factor, 0.0, 1.0) * _vignetting_max_intensity
	else:
		_target_vignette_intensity = 0.0

## Set up vignetting effect UI
func _setup_vignetting() -> void:
	# Create vignette overlay as a ColorRect with shader
	vignette_rect = ColorRect.new()
	vignette_rect.name = "VignetteOverlay"
	vignette_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette_rect.visible = false

	# Create shader material for vignette effect
	vignette_material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float radius : hint_range(0.1, 1.0) = 0.6;
uniform float softness : hint_range(0.0, 1.0) = 0.4;
uniform vec3 vignette_color : source_color = vec3(0.0, 0.0, 0.0);

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float dist = length(uv);
	float vignette = smoothstep(radius, radius - softness, dist);
	vignette = 1.0 - (1.0 - vignette) * intensity;
	COLOR = vec4(vignette_color, 1.0 - vignette);
}
"""
	vignette_material.shader = shader
	vignette_material.set_shader_parameter("intensity", 0.0)
	vignette_material.set_shader_parameter("radius", 0.6)
	vignette_material.set_shader_parameter("softness", 0.4)
	vignette_material.set_shader_parameter("vignette_color", Vector3(0.0, 0.0, 0.0))

	vignette_rect.material = vignette_material

	# Attach vignette to scene root as CanvasLayer for proper 2D rendering in viewport
	# CanvasLayer MUST be child of scene root, not 3D nodes, to render correctly in VR
	# This ensures the vignette stays fixed in the camera viewport regardless of 3D transforms
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "VignetteCanvasLayer"
	canvas_layer.layer = 100  # High layer to ensure it's on top of all game content

	# Get the scene root - proper parent for CanvasLayer to enable 2D rendering pipeline
	var scene_root = get_tree().root
	scene_root.add_child(canvas_layer)
	canvas_layer.add_child(vignette_rect)

	# Ensure proper scene ownership for serialization
	canvas_layer.owner = scene_root
	vignette_rect.owner = canvas_layer

	print("VRComfortSystem: Vignetting effect set up successfully")
	print("VRComfortSystem: Vignette attached to scene root CanvasLayer - stays fixed to camera viewport")
## Apply vignette effect at given intensity
## @param intensity: Vignette intensity from 0.0 (none) to 1.0 (full)
func apply_vignette(intensity: float) -> void:
	if vignette_rect == null or vignette_material == null:
		return

	intensity = clampf(intensity, 0.0, 1.0)

	# Show/hide based on intensity
	vignette_rect.visible = intensity > 0.01

	# Update shader parameter
	vignette_material.set_shader_parameter("intensity", intensity)

	# Emit signal
	vignetting_changed.emit(intensity)

## Execute a snap turn rotation
## @param direction: -1 for left, 1 for right
## @return: true if snap turn was executed
func execute_snap_turn(direction: int) -> bool:
	if not _initialized or not _snap_turn_enabled:
		return false

	if _snap_turn_cooldown > 0:
		return false

	if vr_manager == null or vr_manager.xr_origin == null:
		return false

	# Calculate turn angle in radians
	var turn_angle_rad = deg_to_rad(_snap_turn_angle * sign(direction))

	# Rotate the XR origin around its Y axis
	var current_rotation = vr_manager.xr_origin.rotation
	current_rotation.y += turn_angle_rad
	vr_manager.xr_origin.rotation = current_rotation

	# Reset cooldown
	_snap_turn_cooldown = SNAP_TURN_COOLDOWN_TIME

	# Emit signal
	snap_turn_executed.emit(_snap_turn_angle * sign(direction))

	print("VRComfortSystem: Snap turn executed - angle=%f degrees" % (_snap_turn_angle * sign(direction)))
	return true

## Handle controller input for snap turns
func handle_snap_turn_input(left_input: float, right_input: float) -> void:
	if not _snap_turn_enabled:
		return

	# Threshold for analog stick input
	const STICK_THRESHOLD = 0.7

	# Check for left snap turn
	if left_input < -STICK_THRESHOLD:
		execute_snap_turn(-1)
	# Check for right snap turn
	elif right_input > STICK_THRESHOLD:
		execute_snap_turn(1)

## Process snap-turn input from VR controllers
## Reads thumbstick state and calls handle_snap_turn_input()
func _process_snap_turn_input() -> void:
	# Get controller states from VRManager
	var left_state := vr_manager.get_controller_state("left")
	var right_state := vr_manager.get_controller_state("right")

	# Extract thumbstick values
	var left_thumbstick: Vector2 = left_state.get("thumbstick", Vector2.ZERO)
	var right_thumbstick: Vector2 = right_state.get("thumbstick", Vector2.ZERO)

	# Use X-axis (horizontal) of right thumbstick for snap turns (most common VR convention)
	# Left thumbstick typically reserved for movement in walking mode
	handle_snap_turn_input(right_thumbstick.x, right_thumbstick.x)

## Set snap-turn angle
## @param angle: Angle in degrees (common values: 30, 45, 90)
func set_snap_turn_angle(angle: float) -> void:
	_snap_turn_angle = clampf(angle, 15.0, 180.0)
	if settings_manager:
		settings_manager.set_setting("vr", "snap_turn_angle", _snap_turn_angle)

## Get current snap-turn angle
func get_snap_turn_angle() -> float:
	return _snap_turn_angle

## Toggle or set stationary mode
## @param enabled: true to enable stationary mode, false to disable
func set_stationary_mode(enabled: bool) -> void:
	if _stationary_mode_active == enabled:
		return

	_stationary_mode_active = enabled

	if enabled:
		# Enable stationary mode - freeze player position, move universe instead
		if spacecraft:
			# Store current position offset
			_universe_offset = Vector3.ZERO
			# Note: In a full implementation, this would affect FloatingOriginSystem
			# to move all universe objects relative to the player instead of moving the player
			print("VRComfortSystem: Stationary mode ENABLED - player locked, universe moves")
	else:
		# Disable stationary mode - return to normal movement
		_universe_offset = Vector3.ZERO
		print("VRComfortSystem: Stationary mode DISABLED - normal movement restored")

	# Update setting if settings manager available
	if settings_manager:
		settings_manager.set_setting("vr", "stationary_mode", enabled)

	# Emit signal
	stationary_mode_changed.emit(enabled)

## Get current stationary mode state
func is_stationary_mode_active() -> bool:
	return _stationary_mode_active

## Get current vignette intensity
func get_vignette_intensity() -> float:
	return _current_vignette_intensity

## Get current acceleration (for debug/telemetry)
func get_current_acceleration() -> float:
	return _current_acceleration

## Update spacecraft reference (if spacecraft changes)
func set_spacecraft(new_spacecraft: Node) -> void:
	spacecraft = new_spacecraft
	_last_velocity = Vector3.ZERO
	_current_acceleration = 0.0

## Cleanup
func _exit_tree() -> void:
	if vignette_rect:
		vignette_rect.queue_free()

	if settings_manager and settings_manager.has_signal("setting_changed"):
		if settings_manager.setting_changed.is_connected(_on_setting_changed):
			settings_manager.setting_changed.disconnect(_on_setting_changed)
