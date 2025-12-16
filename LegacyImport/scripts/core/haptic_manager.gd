## HapticManager - VR Controller Haptic Feedback System
## Provides tactile feedback through VR controllers for various game events.
## Enhances immersion by making interactions feel physical and responsive.
##
## Requirements:
## - 69.1: Trigger haptic feedback on cockpit control activation
## - 69.2: Apply strong haptic pulses on spacecraft collision
## - 69.3: Apply continuous vibration in gravity wells (increases with strength)
## - 69.4: Pulse haptics in sync with visual glitch effects when taking damage
## - 69.5: Provide brief haptic confirmation pulse on resource collection
extends Node
class_name HapticManager

## Emitted when haptic feedback is triggered
signal haptic_triggered(hand: String, intensity: float, duration: float)

## Haptic intensity presets
enum HapticIntensity {
	SUBTLE = 0,      ## Very light feedback (0.1-0.3)
	LIGHT = 1,       ## Light feedback (0.3-0.5)
	MEDIUM = 2,      ## Medium feedback (0.5-0.7)
	STRONG = 3,      ## Strong feedback (0.7-0.9)
	VERY_STRONG = 4  ## Maximum feedback (0.9-1.0)
}

## Haptic duration presets (in seconds) - Class constants for external access
const DURATION_INSTANT: float = 0.05   ## Very brief pulse
const DURATION_SHORT: float = 0.1      ## Short pulse
const DURATION_MEDIUM: float = 0.2     ## Medium pulse
const DURATION_LONG: float = 0.5       ## Long pulse
const DURATION_CONTINUOUS: float = 1.0 ## Continuous (for looping effects)

## Instance-level exported durations (for runtime customization)
@export var duration_instant: float = DURATION_INSTANT
@export var duration_short: float = DURATION_SHORT
@export var duration_medium: float = DURATION_MEDIUM
@export var duration_long: float = DURATION_LONG
@export var duration_continuous: float = DURATION_CONTINUOUS

## Reference to VR manager
var vr_manager: VRManager = null

## Reference to left and right controllers
var left_controller: XRController3D = null
var right_controller: XRController3D = null

## Haptic feedback enabled state
var haptics_enabled: bool = true

## Master haptic intensity multiplier (0.0 to 1.0)
var master_intensity: float = 1.0

## Continuous haptic effects tracking
var _continuous_effects: Dictionary = {
	"left": {},   ## {effect_name: {intensity: float, start_time: float}}
	"right": {}
}

## Gravity well haptic state
var _gravity_well_intensity: float = 0.0
var _last_gravity_update_time: float = 0.0
const GRAVITY_UPDATE_INTERVAL: float = 0.1  ## Update gravity haptics every 100ms

## Continuous effect update throttling
var _last_continuous_update_time: float = 0.0
const CONTINUOUS_UPDATE_INTERVAL: float = 0.0167  ## ~60 Hz (17ms per update)


func _ready() -> void:
	# Don't auto-initialize - let the engine coordinator call initialize()
	pass


## Initialize the haptic manager
## Connects to VR manager and sets up signal connections
func initialize() -> bool:
	_log_info("Initializing Haptic Manager...")
	
	# Find VR manager
	vr_manager = _get_vr_manager()
	if vr_manager == null:
		_log_warning("VR Manager not found - haptic feedback will be disabled")
		return false
	
	# Get controller references
	left_controller = vr_manager.get_controller("left")
	right_controller = vr_manager.get_controller("right")
	
	if left_controller == null and right_controller == null:
		_log_warning("No VR controllers found - haptic feedback will be disabled")
		return false
	
	_log_info("Haptic Manager initialized successfully")
	_log_info("Left controller: %s" % ("found" if left_controller != null else "not found"))
	_log_info("Right controller: %s" % ("found" if right_controller != null else "not found"))
	
	# Connect to relevant game signals
	_connect_game_signals()
	
	return true


## Connect to game event signals for automatic haptic feedback
func _connect_game_signals() -> void:
	# Try to find and connect to spacecraft signals
	var spacecraft = _find_spacecraft()
	if spacecraft != null:
		if spacecraft.has_signal("collision_occurred"):
			spacecraft.collision_occurred.connect(_on_spacecraft_collision)
			_log_info("Connected to spacecraft collision signal")
	
	# Try to find and connect to cockpit UI signals
	var cockpit_ui = _find_cockpit_ui()
	if cockpit_ui != null:
		if cockpit_ui.has_signal("control_activated"):
			cockpit_ui.control_activated.connect(_on_cockpit_control_activated)
			_log_info("Connected to cockpit control activated signal")
	
	# Note: Other signals (damage, resource collection) should be connected
	# by the systems that emit them, calling the appropriate haptic methods


func _process(delta: float) -> void:
	# Update continuous haptic effects
	_update_continuous_effects(delta)
	
	# Update gravity well haptics
	_update_gravity_well_haptics(delta)


## Update continuous haptic effects
## FIXED: Now actually triggers haptic feedback at throttled update rate (60 Hz max)
func _update_continuous_effects(delta: float) -> void:
	var current_time := Time.get_ticks_msec() / 1000.0
	
	# Throttle updates to respect hardware limits (max 60 Hz)
	if current_time - _last_continuous_update_time < CONTINUOUS_UPDATE_INTERVAL:
		return
	
	_last_continuous_update_time = current_time
	
	for hand in ["left", "right"]:
		var effects: Dictionary = _continuous_effects[hand]
		var effects_to_remove: Array[String] = []
		
		for effect_name in effects.keys():
			var effect: Dictionary = effects[effect_name]
			var elapsed: float = current_time - effect.start_time
			
			# Check if effect should continue
			if elapsed >= effect.get("duration", DURATION_CONTINUOUS):
				# Effect duration expired, mark for removal
				effects_to_remove.append(effect_name)
			else:
				# Effect is still active - trigger haptic feedback
				# This is the CRITICAL FIX: actually pulse the haptics
				var intensity: float = effect.get("intensity", 0.5)
				trigger_haptic(hand, intensity, DURATION_CONTINUOUS)
		
		# Remove expired effects
		for effect_name in effects_to_remove:
			effects.erase(effect_name)
			_log_debug("Continuous effect '%s' stopped on %s hand" % [effect_name, hand])


## Update gravity well continuous haptics
func _update_gravity_well_haptics(delta: float) -> void:
	if _gravity_well_intensity <= 0.0:
		return
	
	var current_time := Time.get_ticks_msec() / 1000.0
	if current_time - _last_gravity_update_time < GRAVITY_UPDATE_INTERVAL:
		return
	
	_last_gravity_update_time = current_time
	
	# Apply continuous vibration to both controllers
	# Intensity scales with gravity well strength
	var intensity := _gravity_well_intensity * 0.5  ## Scale down for comfort
	trigger_haptic_both(intensity, DURATION_CONTINUOUS)


#region Public API - Requirement-specific methods

## Requirement 69.1: Trigger haptic feedback when a cockpit control is activated
func trigger_control_activation(hand: String = "both") -> void:
	var intensity := _get_intensity_value(HapticIntensity.LIGHT)
	var duration := DURATION_SHORT
	
	if hand == "both":
		trigger_haptic_both(intensity, duration)
	else:
		trigger_haptic(hand, intensity, duration)
	
	_log_debug("Control activation haptic triggered (hand: %s)" % hand)


## Requirement 69.2: Trigger strong haptic pulse on spacecraft collision
## Args:
##   collision_velocity: Magnitude of collision velocity (affects intensity)
func trigger_collision(collision_velocity: float = 10.0) -> void:
	# Scale intensity based on collision velocity
	# Clamp between MEDIUM and VERY_STRONG
	var velocity_factor: float = clamp(collision_velocity / 50.0, 0.5, 1.0)
	var intensity: float = lerp(
		_get_intensity_value(HapticIntensity.MEDIUM),
		_get_intensity_value(HapticIntensity.VERY_STRONG),
		velocity_factor
	)
	var duration := DURATION_MEDIUM
	
	# Apply to both controllers
	trigger_haptic_both(intensity, duration)
	
	_log_debug("Collision haptic triggered (velocity: %.1f, intensity: %.2f)" % [collision_velocity, intensity])


## Requirement 69.3: Set the intensity of continuous gravity well vibration
## Args:
##   intensity: Gravity well strength (0.0 to 1.0)
func set_gravity_well_intensity(intensity: float) -> void:
	_gravity_well_intensity = clamp(intensity, 0.0, 1.0)
	
	if _gravity_well_intensity > 0.0:
		_log_debug("Gravity well haptic intensity set to %.2f" % _gravity_well_intensity)


## Requirement 69.4: Trigger haptic pulse synchronized with visual glitch effects
## Args:
##   damage_amount: Amount of damage taken (affects intensity)
func trigger_damage_pulse(damage_amount: float = 10.0) -> void:
	# Scale intensity based on damage amount
	var damage_factor: float = clamp(damage_amount / 50.0, 0.3, 1.0)
	var intensity: float = lerp(
		_get_intensity_value(HapticIntensity.LIGHT),
		_get_intensity_value(HapticIntensity.STRONG),
		damage_factor
	)
	var duration := DURATION_SHORT
	
	# Apply to both controllers
	trigger_haptic_both(intensity, duration)
	
	_log_debug("Damage pulse haptic triggered (damage: %.1f, intensity: %.2f)" % [damage_amount, intensity])


## Requirement 69.5: Trigger brief haptic confirmation pulse on resource collection
func trigger_resource_collection() -> void:
	var intensity := _get_intensity_value(HapticIntensity.MEDIUM)
	var duration := DURATION_INSTANT
	
	# Apply to both controllers
	trigger_haptic_both(intensity, duration)
	
	_log_debug("Resource collection haptic triggered")

#endregion


#region Core Haptic Methods

## Trigger haptic feedback on a specific controller
## Args:
##   hand: "left" or "right"
##   intensity: Haptic intensity (0.0 to 1.0)
##   duration: Duration in seconds
func trigger_haptic(hand: String, intensity: float, duration: float) -> void:
	if not haptics_enabled:
		return
	
	if not vr_manager or not vr_manager.is_vr_active():
		return  # No haptics in desktop mode

	# Apply master intensity multiplier
	var final_intensity: float = clamp(intensity * master_intensity, 0.0, 1.0)
	
	var controller: XRController3D = null
	if hand == "left":
		controller = left_controller
	elif hand == "right":
		controller = right_controller
	
	if controller == null:
		return
	
	# Trigger haptic pulse using OpenXR action
	# Parameters: action_name, frequency, amplitude, duration_sec, delay_sec
	controller.trigger_haptic_pulse("haptic", 0.0, final_intensity, duration, 0.0)
	
	haptic_triggered.emit(hand, final_intensity, duration)


## Trigger haptic feedback on both controllers simultaneously
## Args:
##   intensity: Haptic intensity (0.0 to 1.0)
##   duration: Duration in seconds
func trigger_haptic_both(intensity: float, duration: float) -> void:
	trigger_haptic("left", intensity, duration)
	trigger_haptic("right", intensity, duration)


## Start a continuous haptic effect that repeats until stopped
## Args:
##   hand: "left", "right", or "both"
##   effect_name: Unique name for this effect
##   intensity: Haptic intensity (0.0 to 1.0)
##   duration: Total duration (-1.0 for infinite)
func start_continuous_effect(hand: String, effect_name: String, intensity: float, duration: float = -1.0) -> void:
	var current_time := Time.get_ticks_msec() / 1000.0
	
	var effect_data := {
		"intensity": intensity,
		"start_time": current_time,
		"duration": duration
	}
	
	if hand == "both":
		_continuous_effects["left"][effect_name] = effect_data.duplicate()
		_continuous_effects["right"][effect_name] = effect_data.duplicate()
	else:
		_continuous_effects[hand][effect_name] = effect_data

	_log_debug("Continuous effect '%s' started on %s hand (intensity: %.2f)" % [effect_name, hand, intensity])


## Stop a continuous haptic effect
## Args:
##   hand: "left", "right", or "both"
##   effect_name: Name of the effect to stop
func stop_continuous_effect(hand: String, effect_name: String) -> void:
	if hand == "both":
		_continuous_effects["left"].erase(effect_name)
		_continuous_effects["right"].erase(effect_name)
	else:
		_continuous_effects[hand].erase(effect_name)

	_log_debug("Continuous effect '%s' stopped on %s hand" % [effect_name, hand])


## Stop all continuous haptic effects on both controllers
func stop_all_continuous_effects() -> void:
	_continuous_effects["left"].clear()
	_continuous_effects["right"].clear()
	_gravity_well_intensity = 0.0

#endregion


#region Settings and Configuration

## Enable or disable all haptic feedback
func set_haptics_enabled(enabled: bool) -> void:
	haptics_enabled = enabled
	if not enabled:
		stop_all_continuous_effects()
	_log_info("Haptics %s" % ("enabled" if enabled else "disabled"))


## Set the master intensity multiplier for all haptic feedback
## Args:
##   intensity: Multiplier value (0.0 to 1.0)
func set_master_intensity(intensity: float) -> void:
	master_intensity = clamp(intensity, 0.0, 1.0)
	_log_info("Master haptic intensity set to %.2f" % master_intensity)


## Check if haptic feedback is available (VR mode with controllers)
func is_haptics_available() -> bool:
	return vr_manager != null and vr_manager.is_vr_active() and (left_controller != null or right_controller != null)

#endregion


#region Signal Handlers

## Handle spacecraft collision event
func _on_spacecraft_collision(collision_info: Dictionary) -> void:
	var velocity: Vector3 = collision_info.get("velocity", Vector3.ZERO)
	var collision_velocity: float = velocity.length()
	trigger_collision(collision_velocity)


## Handle cockpit control activation event
func _on_cockpit_control_activated(control_name: String) -> void:
	# Determine which hand activated the control (if available)
	# For now, trigger on both hands
	trigger_control_activation("both")

#endregion


#region Helper Methods

## Convert intensity preset to float value
func _get_intensity_value(preset: HapticIntensity) -> float:
	match preset:
		HapticIntensity.SUBTLE:
			return 0.2
		HapticIntensity.LIGHT:
			return 0.4
		HapticIntensity.MEDIUM:
			return 0.6
		HapticIntensity.STRONG:
			return 0.8
		HapticIntensity.VERY_STRONG:
			return 1.0
	return 0.5


## Get reference to VR manager
func _get_vr_manager() -> VRManager:
	var engine := _get_engine()
	if engine != null and engine.has_method("get_vr_manager"):
		return engine.get_vr_manager()
	
	# Try to find it directly
	return get_node_or_null("/root/ResonanceEngine/VRManager")


## Find spacecraft node in scene tree
func _find_spacecraft() -> Node:
	var engine := _get_engine()
	if engine != null and engine.has_method("get_spacecraft"):
		return engine.get_spacecraft()
	
	# Search for Spacecraft class
	return _find_node_by_class("Spacecraft")


## Find cockpit UI node in scene tree
func _find_cockpit_ui() -> Node:
	return _find_node_by_class("CockpitUI")


## Recursively search for a node with the given class name
func _find_node_by_class(target_class_name: String) -> Node:
	var root := get_tree().root
	return _recursive_find_class(root, target_class_name)


## Recursively search for a node with the given class
func _recursive_find_class(node: Node, target_class_name: String) -> Node:
	if node.get_class() == target_class_name:
		return node
	for child in node.get_children():
		var result := _recursive_find_class(child, target_class_name)
		if result != null:
			return result
	return null


## Get reference to ResonanceEngine
func _get_engine() -> Node:
	return get_node_or_null("/root/ResonanceEngine")

#endregion


#region Shutdown

## Clean up haptic manager resources
func shutdown() -> void:
	_log_info("HapticManager shutting down...")
	
	# Stop all continuous effects
	stop_all_continuous_effects()
	
	# Disconnect signals
	var spacecraft = _find_spacecraft()
	if spacecraft != null and spacecraft.has_signal("collision_occurred"):
		if spacecraft.collision_occurred.is_connected(_on_spacecraft_collision):
			spacecraft.collision_occurred.disconnect(_on_spacecraft_collision)
	
	var cockpit_ui = _find_cockpit_ui()
	if cockpit_ui != null and cockpit_ui.has_signal("control_activated"):
		if cockpit_ui.control_activated.is_connected(_on_cockpit_control_activated):
			cockpit_ui.control_activated.disconnect(_on_cockpit_control_activated)
	
	# Clear references
	vr_manager = null
	left_controller = null
	right_controller = null
	
	_log_info("HapticManager shutdown complete")

func _exit_tree() -> void:
	"""Cleanup when node is removed from tree."""
	_log_info("HapticManager exiting tree, cleaning up...")

	# Stop all continuous effects
	stop_all_continuous_effects()

	# Disconnect signal connections to prevent memory leaks
	var spacecraft = _find_spacecraft()
	if spacecraft and is_instance_valid(spacecraft):
		if spacecraft.has_signal("collision_occurred") and spacecraft.collision_occurred.is_connected(_on_spacecraft_collision):
			spacecraft.collision_occurred.disconnect(_on_spacecraft_collision)

	var cockpit_ui = _find_cockpit_ui()
	if cockpit_ui and is_instance_valid(cockpit_ui):
		if cockpit_ui.has_signal("control_activated") and cockpit_ui.control_activated.is_connected(_on_cockpit_control_activated):
			cockpit_ui.control_activated.disconnect(_on_cockpit_control_activated)

	# Clear references
	vr_manager = null
	left_controller = null
	right_controller = null

	_log_info("HapticManager cleanup complete")


#endregion


#region Logging

func _log_debug(message: String) -> void:
	var engine := _get_engine()
	if engine != null and engine.has_method("log_debug"):
		engine.log_debug("[HapticManager] " + message)
	else:
		print("[DEBUG] [HapticManager] " + message)


func _log_info(message: String) -> void:
	var engine := _get_engine()
	if engine != null and engine.has_method("log_info"):
		engine.log_info("[HapticManager] " + message)
	else:
		print("[INFO] [HapticManager] " + message)


func _log_warning(message: String) -> void:
	var engine := _get_engine()
	if engine != null and engine.has_method("log_warning"):
		engine.log_warning("[HapticManager] " + message)
	else:
		push_warning("[HapticManager] " + message)


func _log_error(message: String) -> void:
	var engine := _get_engine()
	if engine != null and engine.has_method("log_error"):
		engine.log_error("[HapticManager] " + message)
	else:
		push_error("[HapticManager] " + message)

#endregion
