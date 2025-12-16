## Controller Button Remapping Examples
##
## This file demonstrates practical usage patterns for the ControllerButtonRemapper
## system in various gameplay contexts.

extends Node
class_name ControllerRemappingExamples


## EXAMPLE 1: Basic button state checking in a gameplay script
##
## This pattern can be used in any script that needs to check VR controller input

func example_basic_input_checking() -> void:
	var vr_manager = _get_vr_manager()
	if not vr_manager or not vr_manager.button_remapper:
		return

	var remapper = vr_manager.button_remapper
	var right_controller = vr_manager.get_controller("right")

	if not right_controller:
		return

	# Check semantic actions instead of hardware button names
	if remapper.is_action_pressed("interact", right_controller):
		print("Player is performing primary interaction")

	if remapper.is_action_pressed("grab", right_controller):
		print("Player is grabbing")

	if remapper.is_action_pressed("menu", right_controller):
		print("Player opened menu")


## EXAMPLE 2: Signal-based input handling (preferred pattern)
##
## Listen to semantic action signals instead of button names

func example_signal_based_input() -> void:
	var vr_manager = _get_vr_manager()
	if not vr_manager:
		return

	# Connect to semantic action signals
	vr_manager.controller_button_pressed.connect(_on_action_pressed)
	vr_manager.controller_button_released.connect(_on_action_released)


func _on_action_pressed(hand: String, action: String) -> void:
	"""Handle semantic action press (not hardware button press)."""
	match action:
		"interact":
			print("Interact action pressed on %s hand" % hand)
			_handle_interact(hand)
		"grab":
			print("Grab action pressed on %s hand" % hand)
			_handle_grab(hand)
		"menu":
			print("Menu action pressed")
			_handle_menu()
		"menu_action":
			print("Menu action button pressed on %s hand" % hand)
			_handle_menu_action(hand)
		_:
			print("Unknown action: %s" % action)


func _on_action_released(hand: String, action: String) -> void:
	"""Handle semantic action release."""
	match action:
		"interact":
			_stop_interact(hand)
		"grab":
			_stop_grab(hand)


func _handle_interact(hand: String) -> void:
	print("Player interacting with %s hand" % hand)


func _stop_interact(hand: String) -> void:
	print("Player stopped interacting")


func _handle_grab(hand: String) -> void:
	print("Player grabbed with %s hand" % hand)


func _stop_grab(hand: String) -> void:
	print("Player released grab")


func _handle_menu() -> void:
	print("Opening menu")


func _handle_menu_action(hand: String) -> void:
	print("Secondary action with %s hand" % hand)


## EXAMPLE 3: Polling-based input in _process
##
## Some systems prefer polling input each frame

func example_polling_input(delta: float) -> void:
	var vr_manager = _get_vr_manager()
	if not vr_manager or not vr_manager.button_remapper:
		return

	var remapper = vr_manager.button_remapper
	var left_controller = vr_manager.get_controller("left")
	var right_controller = vr_manager.get_controller("right")

	if not left_controller or not right_controller:
		return

	# Poll various actions
	_update_interaction_state(remapper, left_controller, right_controller)
	_update_locomotion_input(remapper, left_controller, right_controller)


func _update_interaction_state(remapper: ControllerButtonRemapper, left: XRController3D, right: XRController3D) -> void:
	"""Example of checking interaction state each frame."""
	var left_interact = remapper.is_action_pressed("interact", left)
	var right_interact = remapper.is_action_pressed("interact", right)

	if left_interact or right_interact:
		print("Interaction active")


func _update_locomotion_input(remapper: ControllerButtonRemapper, left: XRController3D, right: XRController3D) -> void:
	"""Example of checking movement input each frame."""
	var grab_left = remapper.is_action_pressed("grab", left)
	var grab_right = remapper.is_action_pressed("grab", right)

	if grab_left and grab_right:
		print("Player might be doing climbing motion")


## EXAMPLE 4: Displaying available mappings in UI
##
## For settings menus that let players see/change button mappings

func example_display_mappings_in_ui() -> void:
	var vr_manager = _get_vr_manager()
	if not vr_manager or not vr_manager.button_remapper:
		return

	var remapper = vr_manager.button_remapper

	# Get all action mappings
	var all_mappings = remapper.get_all_mappings()

	print("\n=== Current Button Mappings ===")
	for action_name in all_mappings:
		var mapped_button = all_mappings[action_name]
		print("  %s -> %s" % [action_name, mapped_button])

	# Get detailed action info for UI
	print("\n=== Action Details ===")
	var action_info = remapper.get_action_info()
	for info in action_info:
		print("  Action: %s" % info.action)
		print("    Description: %s" % info.description)
		print("    Mapped to: %s" % info.mapped_to)
		print("    Available buttons: %s" % info.button_names)
		print("    Fallback: %s" % info.fallback)
		print()


## EXAMPLE 5: Custom button remapping at runtime
##
## Allow players to customize button mappings

func example_custom_remapping() -> void:
	var vr_manager = _get_vr_manager()
	if not vr_manager or not vr_manager.button_remapper:
		return

	var remapper = vr_manager.button_remapper

	# Example: Swap interact button priority
	# Try trigger_click first (for Valve Index), then fall back to ax_button (Meta)
	remapper.set_custom_mapping("interact", ["trigger_click", "ax_button"])

	# Example: Configure grab button
	remapper.set_custom_mapping("grab", ["grip", "squeeze", "grip_click"])

	# Settings are automatically saved to SettingsManager
	print("Custom mappings saved!")


## EXAMPLE 6: Detecting and handling different controller types
##
## Different VR systems have different button layouts

func example_controller_type_detection() -> void:
	var vr_manager = _get_vr_manager()
	if not vr_manager or not vr_manager.button_remapper:
		return

	var remapper = vr_manager.button_remapper

	print("Detected controller type: %s" % remapper.current_controller_type)

	# Get controller profile info
	var profile = remapper.get_controller_profile_info()
	print("Controller profile: %s" % profile.description)
	print("Available buttons: %s" % profile.buttons)

	# Handle controller-specific behavior if needed
	match remapper.current_controller_type:
		"meta":
			print("Using Meta/Oculus Touch controller layout")
			# Meta has ax_button, by_button, menu_button
		"valve":
			print("Using Valve Index controller layout")
			# Valve has a_button, b_button, system button, trackpad
		"htc":
			print("Using HTC Vive controller layout")
			# HTC has touchpad and fewer buttons
		"generic":
			print("Using generic controller fallback")


## EXAMPLE 7: Analog input handling (triggers, grips)
##
## For continuous controls like trigger pulls and grip squeezes

func example_analog_input(delta: float) -> void:
	var vr_manager = _get_vr_manager()
	if not vr_manager or not vr_manager.button_remapper:
		return

	var remapper = vr_manager.button_remapper
	var right_controller = vr_manager.get_controller("right")

	if not right_controller:
		return

	# Get analog values for triggers and grips
	# These are typically 0.0 to 1.0
	var trigger_value = right_controller.get_float("trigger")
	var grip_value = right_controller.get_float("grip")

	# Example: Use trigger for throttle in spacecraft control
	if trigger_value > 0.1:
		print("Throttle: %.2f" % trigger_value)

	# Example: Use grip for force magnitude in interaction
	if grip_value > 0.5:
		print("Strong grip detected")


## EXAMPLE 8: Integrating with existing pilot controller
##
## Example of updating PilotController to use remapping

func example_pilot_controller_integration() -> void:
	# In PilotController class:
	var vr_manager = _get_vr_manager()
	var remapper = vr_manager.button_remapper if vr_manager else null

	var right_controller = vr_manager.get_controller("right") if vr_manager else null

	if remapper and right_controller:
		# Check for primary action (works on all controller types)
		if remapper.is_action_pressed("interact", right_controller):
			print("Spacecraft scan/interact")

		# Check for secondary action
		if remapper.is_action_pressed("menu_action", right_controller):
			print("Cancel/deselect")

		# Check for menu/pause
		if remapper.is_action_pressed("menu", right_controller):
			print("Open spacecraft menu")


## EXAMPLE 9: Accessibility customization
##
## Allow players to remap buttons for accessibility

func example_accessibility_remapping() -> void:
	var vr_manager = _get_vr_manager()
	if not vr_manager or not vr_manager.button_remapper:
		return

	var remapper = vr_manager.button_remapper

	# Example 1: Player with grip strength issues
	# Map grab to a button instead of grip squeeze
	remapper.set_custom_mapping("grab", ["by_button", "grip", "squeeze"])

	# Example 2: Player with limited hand mobility
	# Use only thumbstick click instead of multiple buttons
	remapper.set_custom_mapping("interact", ["primary_click"])
	remapper.set_custom_mapping("menu_action", ["touchpad"])

	print("Accessibility remapping applied")


## EXAMPLE 10: Planetary Survival terrain tool integration
##
## Real example from terrain_tool.gd refactored with remapping

func example_terrain_tool_with_remapping(vr_manager: Node, right_controller: XRController3D) -> void:
	"""
	Old code:
		if right_controller.is_button_pressed("ax_button"):
			activate_terrain_tool()

	New code with remapping:
	"""
	if not vr_manager or not vr_manager.button_remapper:
		return

	var remapper = vr_manager.button_remapper

	# Instead of checking "ax_button" directly, check semantic action
	if remapper.is_action_pressed("interact", right_controller):
		print("Terrain tool activated")


## EXAMPLE 11: Planetary Survival UI integration
##
## Real example from vr_crafting_ui.gd refactored with remapping

func example_crafting_ui_with_remapping(vr_manager: Node, left_controller: XRController3D, right_controller: XRController3D) -> void:
	"""
	Old code:
		var trigger_now = left_controller.is_button_pressed("trigger_click")
		var grip_now = left_controller.is_button_pressed("grip_click")

	New code with remapping (more portable across controllers):
	"""
	if not vr_manager or not vr_manager.button_remapper:
		return

	var remapper = vr_manager.button_remapper

	# These mappings work with any VR system
	var interact_pressed = remapper.is_action_pressed("interact", left_controller)
	var grab_pressed = remapper.is_action_pressed("grab", left_controller)

	if interact_pressed:
		print("Crafting UI: Confirm selection")
	if grab_pressed:
		print("Crafting UI: Grab/move item")


## EXAMPLE 12: Menu system using remapped buttons
##
## For VR menu navigation

func example_menu_navigation(vr_manager: Node, right_controller: XRController3D) -> void:
	if not vr_manager or not vr_manager.button_remapper:
		return

	var remapper = vr_manager.button_remapper

	# Menu navigation works with any controller type
	if remapper.is_action_pressed("interact", right_controller):
		print("Menu: Select highlighted item")

	if remapper.is_action_pressed("menu_action", right_controller):
		print("Menu: Cancel/go back")

	# Thumbstick for navigation
	var thumbstick = right_controller.get_vector2("primary")
	if thumbstick.length() > 0.5:
		print("Menu: Navigate in direction %s" % thumbstick)


## Helper functions

func _get_vr_manager() -> Node:
	"""Get the VRManager from ResonanceEngine."""
	var engine = Engine.get_singleton("ResonanceEngine") if Engine.has_singleton("ResonanceEngine") else get_node_or_null("/root/ResonanceEngine")
	if engine and engine.has_method("get_vr_manager"):
		return engine.get_vr_manager()
	return null


## Summary of Best Practices:
##
## 1. USE SEMANTIC ACTION NAMES
##    - Instead of: if controller.is_button_pressed("ax_button")
##    - Use: if remapper.is_action_pressed("interact", controller)
##    - This works across all controller types!
##
## 2. LISTEN TO SIGNALS FOR EVENTS
##    - Connect to vr_manager.controller_button_pressed signal
##    - Signals emit semantic action names, not hardware button names
##    - Cleaner and more maintainable code
##
## 3. DEFINE CLEAR ACTION SEMANTICS
##    - "interact" = primary action (confirm, select, scan)
##    - "grab" = grab/hold objects
##    - "menu" = pause/system menu
##    - "menu_action" = secondary/cancel action
##
## 4. CACHE VR MANAGER REFERENCE
##    - Get reference once in _ready()
##    - Reuse in _process() for polling input
##
## 5. PROVIDE CUSTOMIZATION
##    - Allow players to remap buttons in settings
##    - Remapper.set_custom_mapping() saves to SettingsManager
##    - Include accessibility options
##
## 6. HANDLE MISSING BUTTONS GRACEFULLY
##    - Remapper returns false for unavailable buttons
##    - Fallback chains ensure graceful degradation
##    - Test on actual VR hardware
##
## 7. DOCUMENT ACTION MEANINGS
##    - Include description of what each action does
##    - Help users understand button remapping options
##    - Display in settings UI using get_action_info()
