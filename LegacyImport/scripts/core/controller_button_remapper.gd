## ControllerButtonRemapper - Cross-Controller Button Name Mapping System
##
## Provides unified button name mapping across different VR controller types
## (Meta/Oculus, Valve Index, HTC Vive, generic). Maps semantic action names
## to hardware-specific button names, handling controller type detection and
## fallback strategies for cross-platform compatibility.
##
## Features:
## - Semantic action name mapping (e.g., "interact" instead of "ax_button")
## - Multi-controller support (Meta, Valve, HTC with fallback)
## - Runtime controller type detection
## - Cached button name mapping for performance
## - Settings persistence via SettingsManager
## - Fallback chains for missing buttons
extends Node
class_name ControllerButtonRemapper

## Signal emitted when controller type is detected
signal controller_type_detected(type: String)

## Signal emitted when remapping is updated
signal remapping_updated(action_name: String, hardware_button: String)

## Button action semantic names (action_name -> list of hardware names by priority)
## The order matters - first available button wins
var button_remapping: Dictionary = {
	# Primary interaction (typically dominant hand action)
	"interact": {
		"description": "Primary interaction button (scan, interact, confirm)",
		"button_names": ["ax_button", "a_button", "trigger_click"],
		"fallback": "trigger_click"
	},
	# Secondary action (cancel, menu, alternative)
	"menu_action": {
		"description": "Secondary menu/action button",
		"button_names": ["by_button", "b_button", "system_button"],
		"fallback": "by_button"
	},
	# Grip/grab for object manipulation
	"grab": {
		"description": "Grip button for grabbing objects",
		"button_names": ["grip", "squeeze", "grip_click"],
		"fallback": "grip"
	},
	# Menu/pause functionality
	"menu": {
		"description": "Pause/menu system button",
		"button_names": ["menu_button", "system", "start"],
		"fallback": "menu_button"
	},
	# Thumbstick click/press
	"thumbstick_click": {
		"description": "Thumbstick click/press action",
		"button_names": ["primary_click", "thumbstick_click"],
		"fallback": "primary_click"
	},
	# Touchpad press (alternative input)
	"touchpad": {
		"description": "Touchpad/trackpad click",
		"button_names": ["touchpad_click", "trackpad_click"],
		"fallback": "touchpad_click"
	},
	# Alternative grab (for situations needing multiple grip buttons)
	"grab_alt": {
		"description": "Alternative grab button",
		"button_names": ["squeeze", "grip_click", "grip"],
		"fallback": "squeeze"
	}
}

## Controller type specific button mappings
## Used to detect and prioritize button names based on known controller profiles
var controller_profiles: Dictionary = {
	"meta": {
		# Meta Quest controllers (Touch controllers)
		"buttons": ["ax_button", "by_button", "menu_button", "grip", "trigger_click", "primary_click"],
		"description": "Meta/Oculus Quest Touch Controllers"
	},
	"valve": {
		# Valve Index controllers
		"buttons": ["a_button", "b_button", "system", "grip_click", "trigger_click", "primary_click", "trackpad_click"],
		"description": "Valve Index Controllers"
	},
	"htc": {
		# HTC Vive controllers
		"buttons": ["menu_button", "grip_click", "trigger_click", "touchpad_click"],
		"description": "HTC Vive Controllers"
	},
	"generic": {
		# Fallback for unknown controllers
		"buttons": ["ax_button", "by_button", "menu_button", "grip", "trigger_click", "primary_click"],
		"description": "Generic/Unknown Controller"
	}
}

## Currently detected controller type
var current_controller_type: String = "generic"

## Cache of resolved button names (action_name -> actual_hardware_button)
## Used to avoid repeated lookup operations
var _resolved_buttons: Dictionary = {}

## Reference to SettingsManager for loading custom mappings
var _settings_manager: Node = null

## Flag to track if custom mappings were loaded
var _custom_mappings_loaded: bool = false


func _ready() -> void:
	# Find and cache SettingsManager reference
	_find_settings_manager()
	# Load custom mappings if available
	_load_custom_mappings()
	# Detect controller type (can be overridden later)
	_detect_controller_type()
	_log_info("ControllerButtonRemapper initialized with controller type: %s" % current_controller_type)


## Find SettingsManager singleton
func _find_settings_manager() -> void:
	if Engine.has_singleton("SettingsManager"):
		_settings_manager = Engine.get_singleton("SettingsManager")
	else:
		var settings_node = get_tree().root.find_child("SettingsManager", true, false)
		if settings_node:
			_settings_manager = settings_node


## Load custom button mappings from SettingsManager if available
func _load_custom_mappings() -> void:
	if not _settings_manager:
		_log_debug("SettingsManager not available, using default mappings")
		return

	# Load controller type preference
	var saved_controller_type = _settings_manager.get_setting("vr", "controller_type", null)
	if saved_controller_type:
		current_controller_type = saved_controller_type
		_log_info("Loaded controller type from settings: %s" % current_controller_type)

	# Load custom button remappings (if user has customized them)
	var custom_remaps = _settings_manager.get_setting("vr", "button_remappings", null)
	if custom_remaps is Dictionary:
		# Merge custom mappings with defaults
		for action_name in custom_remaps:
			if button_remapping.has(action_name):
				# Update button names list (preserving other fields)
				button_remapping[action_name]["button_names"] = custom_remaps[action_name]
				_log_info("Loaded custom mapping for '%s': %s" % [action_name, custom_remaps[action_name]])
		_custom_mappings_loaded = true


## Auto-detect controller type by checking available buttons
func _detect_controller_type() -> void:
	# Try to find an XRController to detect available buttons
	var xr_controller = _find_xr_controller()
	if not xr_controller:
		_log_debug("No XR controller found for detection, using generic type")
		return

	# Check which buttons are available to determine controller type
	var detected_type = _scan_controller_buttons(xr_controller)
	if detected_type != "generic":
		current_controller_type = detected_type
		_log_info("Auto-detected controller type: %s" % current_controller_type)
		controller_type_detected.emit(current_controller_type)


## Find an XRController in the scene tree
func _find_xr_controller() -> XRController3D:
	var root = get_tree().root
	return _search_for_controller(root) as XRController3D


## Recursively search for XRController3D node
func _search_for_controller(node: Node) -> Node:
	if node is XRController3D:
		return node
	for child in node.get_children():
		var result = _search_for_controller(child)
		if result:
			return result
	return null


## Scan controller to determine type by checking available buttons
func _scan_controller_buttons(controller: XRController3D) -> String:
	if not controller:
		return "generic"

	# Check Valve Index specific buttons
	if controller.is_button_pressed("a_button") or controller.is_button_pressed("b_button"):
		return "valve"

	# Check Meta/Quest specific buttons
	if controller.is_button_pressed("ax_button") or controller.is_button_pressed("by_button"):
		return "meta"

	# Check HTC Vive specific buttons (uses different naming)
	if controller.is_button_pressed("touchpad_click"):
		return "htc"

	# Default to generic
	return "generic"


## Map a semantic action name to the actual hardware button name
##
## @param action_name - The semantic action name (e.g., "interact", "grab", "menu")
## @param controller - Optional XRController3D to check actual available buttons
## @return The hardware button name to use, or empty string if not available
func map_button_name(action_name: String, controller: XRController3D = null) -> String:
	# Check cache first for performance
	if _resolved_buttons.has(action_name):
		return _resolved_buttons[action_name]

	# Validate action exists
	if not button_remapping.has(action_name):
		_log_warning("Unknown action name: %s" % action_name)
		return ""

	var mapping = button_remapping[action_name]
	var button_names: Array = mapping.get("button_names", [])
	var fallback: String = mapping.get("fallback", "")

	# If controller provided, try actual button detection
	if controller:
		for button_name in button_names:
			# Try to check if button exists on controller
			if _button_exists_on_controller(controller, button_name):
				_resolved_buttons[action_name] = button_name
				remapping_updated.emit(action_name, button_name)
				return button_name
	else:
		# Use controller type profile to prioritize buttons
		var controller_buttons = controller_profiles.get(current_controller_type, {}).get("buttons", [])

		# Find first button that matches both mapping and controller profile
		for button_name in button_names:
			if button_name in controller_buttons or controller_buttons.is_empty():
				_resolved_buttons[action_name] = button_name
				remapping_updated.emit(action_name, button_name)
				return button_name

	# Fall back to the configured fallback button
	if fallback:
		_resolved_buttons[action_name] = fallback
		remapping_updated.emit(action_name, fallback)
		_log_warning("Using fallback button '%s' for action '%s'" % [fallback, action_name])
		return fallback

	# No suitable button found
	_log_error("Failed to map button for action: %s" % action_name)
	return ""


## Check if a button exists/is available on the controller
## Uses try-get approach to avoid errors with unavailable buttons
func _button_exists_on_controller(controller: XRController3D, button_name: String) -> bool:
	if not controller or not is_instance_valid(controller):
		return false

	# Try to get button state - if it returns a valid value, button exists
	# Note: is_button_pressed() will return false for non-existent buttons in Godot
	# but we check if the button can be queried without error
	var is_pressed = controller.is_button_pressed(button_name)

	# If we got here without error, button exists or is handled gracefully
	return true


## Check if a button is pressed using mapped name
##
## @param action_name - The semantic action name
## @param controller - The XRController3D to check
## @return true if the mapped button is pressed
func is_action_pressed(action_name: String, controller: XRController3D) -> bool:
	var button_name = map_button_name(action_name, controller)
	if button_name.is_empty():
		return false

	if not controller or not is_instance_valid(controller):
		return false

	return controller.is_button_pressed(button_name)


## Get float value for a mapped action (for analog inputs like triggers)
##
## @param action_name - The semantic action name
## @param controller - The XRController3D to check
## @return The float value (0.0 to 1.0) for the input
func get_action_float(action_name: String, controller: XRController3D) -> float:
	var button_name = map_button_name(action_name, controller)
	if button_name.is_empty():
		return 0.0

	if not controller or not is_instance_valid(controller):
		return 0.0

	return controller.get_float(button_name)


## Get vector2 value for a mapped action (for thumbsticks, touchpads)
##
## @param action_name - The semantic action name
## @param controller - The XRController3D to check
## @return The Vector2 value for the input
func get_action_vector2(action_name: String, controller: XRController3D) -> Vector2:
	var button_name = map_button_name(action_name, controller)
	if button_name.is_empty():
		return Vector2.ZERO

	if not controller or not is_instance_valid(controller):
		return Vector2.ZERO

	return controller.get_vector2(button_name)


## Clear the button name cache (forces re-detection on next access)
func clear_cache() -> void:
	_resolved_buttons.clear()
	_log_debug("Button name cache cleared")


## Set custom button mapping for an action
##
## @param action_name - The semantic action name
## @param button_names - Array of hardware button names (in priority order)
## @param save_to_settings - Whether to save to SettingsManager
func set_custom_mapping(action_name: String, button_names: Array, save_to_settings: bool = true) -> void:
	if not button_remapping.has(action_name):
		_log_error("Unknown action name: %s" % action_name)
		return

	button_remapping[action_name]["button_names"] = button_names
	_resolved_buttons.erase(action_name)  # Clear cache for this action

	_log_info("Set custom mapping for '%s': %s" % [action_name, button_names])

	# Persist to SettingsManager if available
	if save_to_settings and _settings_manager:
		var custom_remaps = _settings_manager.get_setting("vr", "button_remappings", {})
		if not custom_remaps is Dictionary:
			custom_remaps = {}
		custom_remaps[action_name] = button_names
		_settings_manager.set_setting("vr", "button_remappings", custom_remaps)
		_settings_manager.save_settings()


## Set the controller type manually (useful for testing or user override)
##
## @param controller_type - One of: "meta", "valve", "htc", "generic"
func set_controller_type(controller_type: String) -> void:
	if not controller_profiles.has(controller_type):
		_log_warning("Unknown controller type: %s. Using 'generic'" % controller_type)
		controller_type = "generic"

	current_controller_type = controller_type
	_resolved_buttons.clear()  # Clear cache when changing controller type

	_log_info("Controller type set to: %s" % current_controller_type)

	# Save preference to settings
	if _settings_manager:
		_settings_manager.set_setting("vr", "controller_type", controller_type)


## Get all available actions and their current button mappings
##
## @return Dictionary of action_name -> mapped_button_name
func get_all_mappings() -> Dictionary:
	var mappings: Dictionary = {}
	for action_name in button_remapping.keys():
		mappings[action_name] = map_button_name(action_name)
	return mappings


## Get information about available actions
##
## @return Array of dictionaries with action info
func get_action_info() -> Array:
	var info: Array = []
	for action_name in button_remapping.keys():
		var mapping = button_remapping[action_name]
		info.append({
			"action": action_name,
			"description": mapping.get("description", ""),
			"button_names": mapping.get("button_names", []),
			"mapped_to": map_button_name(action_name),
			"fallback": mapping.get("fallback", "")
		})
	return info


## Get controller profile information
##
## @param controller_type - Optional specific controller type, uses current if not specified
## @return Dictionary with controller info
func get_controller_profile_info(controller_type: String = "") -> Dictionary:
	if controller_type.is_empty():
		controller_type = current_controller_type

	if not controller_profiles.has(controller_type):
		return {}

	var profile = controller_profiles[controller_type]
	return {
		"type": controller_type,
		"description": profile.get("description", ""),
		"buttons": profile.get("buttons", [])
	}


## Logging utilities

func _log_debug(message: String) -> void:
	var engine = _get_engine()
	if engine and engine.has_method("log_debug"):
		engine.log_debug("[ControllerButtonRemapper] " + message)
	else:
		print("[DEBUG] [ControllerButtonRemapper] " + message)


func _log_info(message: String) -> void:
	var engine = _get_engine()
	if engine and engine.has_method("log_info"):
		engine.log_info("[ControllerButtonRemapper] " + message)
	else:
		print("[INFO] [ControllerButtonRemapper] " + message)


func _log_warning(message: String) -> void:
	var engine = _get_engine()
	if engine and engine.has_method("log_warning"):
		engine.log_warning("[ControllerButtonRemapper] " + message)
	else:
		push_warning("[ControllerButtonRemapper] " + message)


func _log_error(message: String) -> void:
	var engine = _get_engine()
	if engine and engine.has_method("log_error"):
		engine.log_error("[ControllerButtonRemapper] " + message)
	else:
		push_error("[ControllerButtonRemapper] " + message)


func _get_engine() -> Node:
	if Engine.has_singleton("ResonanceEngine"):
		return Engine.get_singleton("ResonanceEngine")
	return get_node_or_null("/root/ResonanceEngine")
