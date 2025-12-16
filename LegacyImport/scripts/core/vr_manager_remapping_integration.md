## VRManager Button Remapping Integration Guide
##
## This file shows the changes needed to integrate ControllerButtonRemapper into VRManager.
## Copy the relevant sections into vr_manager.gd
##
## The key changes are:
## 1. Add ControllerButtonRemapper as a member variable
## 2. Initialize it in _ready()
## 3. Update _update_controller_state() to use mapped button names
## 4. Update _on_controller_button_pressed/released to emit mapped action names

## STEP 1: Add this to the VRManager class members section
## (after line 76, with the other member variables)

## Button remapping system for cross-controller compatibility
var button_remapper: ControllerButtonRemapper = null


## STEP 2: Update _ready() function to initialize the remapper
##
## OLD CODE (in VRManager._ready):
##	func _ready() -> void:
##		# Don't auto-initialize - let the engine coordinator call initialize_vr()
##		# Load dead zone settings from SettingsManager if available
##		_load_deadzone_settings()
##		pass
##
## NEW CODE:
##	func _ready() -> void:
##		# Don't auto-initialize - let the engine coordinator call initialize_vr()
##		# Load dead zone settings from SettingsManager if available
##		_load_deadzone_settings()
##		# Initialize button remapping system
##		_init_button_remapper()


## STEP 3: Add this helper function to VRManager

func _init_button_remapper() -> void:
	"""Initialize the button remapping system."""
	# Create and add the remapper as a child node
	button_remapper = ControllerButtonRemapper.new()
	button_remapper.name = "ControllerButtonRemapper"
	add_child(button_remapper)
	_log_info("Button remapping system initialized")


## STEP 4: Update _update_controller_state() function
##
## OLD CODE (lines 373-405):
##	func _update_controller_state(controller: XRController3D, hand: String) -> void:
##		# Defensive null check
##		if not controller or not is_instance_valid(controller):
##			return
##
##		var state: Dictionary = _left_controller_state if hand == "left" else _right_controller_state
##
##		# Update trigger value
##		state["trigger"] = controller.get_float("trigger")
##
##		# Update grip value
##		state["grip"] = controller.get_float("grip")
##
##		# Update thumbstick
##		var thumbstick_value = controller.get_vector2("primary")
##		state["thumbstick"] = thumbstick_value
##
##		# Debug: Print thumbstick value for left controller
##		if hand == "left" and thumbstick_value != Vector2.ZERO:
##			print("[VRManager] Left thumbstick: ", thumbstick_value)
##
##		# Update button states
##		state["button_ax"] = controller.is_button_pressed("ax_button")
##		state["button_by"] = controller.is_button_pressed("by_button")
##		state["button_menu"] = controller.is_button_pressed("menu_button")
##		state["thumbstick_click"] = controller.is_button_pressed("primary_click")
##
##		if hand == "left":
##			_left_controller_state = state
##		else:
##			_right_controller_state = state
##
##
## NEW CODE:
func _update_controller_state(controller: XRController3D, hand: String) -> void:
	"""Update controller state with remapped button names."""
	# Defensive null check
	if not controller or not is_instance_valid(controller):
		return

	var state: Dictionary = _left_controller_state if hand == "left" else _right_controller_state

	# Update trigger value
	state["trigger"] = controller.get_float("trigger")

	# Update grip value
	state["grip"] = controller.get_float("grip")

	# Update thumbstick
	var thumbstick_value = controller.get_vector2("primary")
	state["thumbstick"] = thumbstick_value

	# Debug: Print thumbstick value for left controller
	if hand == "left" and thumbstick_value != Vector2.ZERO:
		print("[VRManager] Left thumbstick: ", thumbstick_value)

	# Update button states using remapped button names
	if button_remapper:
		# Store both mapped action names and hardware button states
		state["interact"] = button_remapper.is_action_pressed("interact", controller)
		state["menu_action"] = button_remapper.is_action_pressed("menu_action", controller)
		state["grab"] = button_remapper.is_action_pressed("grab", controller)
		state["menu"] = button_remapper.is_action_pressed("menu", controller)
		state["thumbstick_click"] = button_remapper.is_action_pressed("thumbstick_click", controller)
		state["touchpad"] = button_remapper.is_action_pressed("touchpad", controller)

		# Still track hardware buttons for backward compatibility
		state["button_ax"] = button_remapper.is_action_pressed("interact", controller)
		state["button_by"] = button_remapper.is_action_pressed("menu_action", controller)
		state["button_menu"] = button_remapper.is_action_pressed("menu", controller)
	else:
		# Fallback to direct button checks if remapper not available
		state["button_ax"] = controller.is_button_pressed("ax_button")
		state["button_by"] = controller.is_button_pressed("by_button")
		state["button_menu"] = controller.is_button_pressed("menu_button")
		state["thumbstick_click"] = controller.is_button_pressed("primary_click")

	if hand == "left":
		_left_controller_state = state
	else:
		_right_controller_state = state


## STEP 5: Update signal handlers to use semantic action names
##
## OLD CODE (line 611-618):
##	func _on_controller_button_pressed(button_name: String, hand: String) -> void:
##		_log_debug("Controller button pressed: %s on %s hand" % [button_name, hand])
##		controller_button_pressed.emit(hand, button_name)
##
##
##	func _on_controller_button_released(button_name: String, hand: String) -> void:
##		_log_debug("Controller button released: %s on %s hand" % [button_name, hand])
##		controller_button_released.emit(hand, button_name)
##
##
## NEW CODE:
func _on_controller_button_pressed(button_name: String, hand: String) -> void:
	"""Handle controller button press with remapping."""
	_log_debug("Controller button pressed: %s on %s hand" % [button_name, hand])

	# Map hardware button to semantic action name
	var action_name = _reverse_map_button_name(button_name)

	# Emit with semantic action name (subscribers can identify action without hardcoding button names)
	controller_button_pressed.emit(hand, action_name)


func _on_controller_button_released(button_name: String, hand: String) -> void:
	"""Handle controller button release with remapping."""
	_log_debug("Controller button released: %s on %s hand" % [button_name, hand])

	# Map hardware button to semantic action name
	var action_name = _reverse_map_button_name(button_name)

	# Emit with semantic action name
	controller_button_released.emit(hand, action_name)


## Helper function to reverse-map hardware button names to action names
func _reverse_map_button_name(hardware_button: String) -> String:
	"""Map a hardware button name back to its semantic action name."""
	if not button_remapper:
		return hardware_button

	# Check all mappings to find which action uses this button
	for action_name in button_remapper.button_remapping.keys():
		var mapped = button_remapper.map_button_name(action_name)
		if mapped == hardware_button:
			return action_name

	# If not found in mappings, return the hardware button name
	return hardware_button


## STEP 6: Update SettingsManager defaults to include button remapping settings
##
## In scripts/core/settings_manager.gd, update the defaults dictionary:
##
## OLD CODE (in defaults dictionary):
##	"vr": {
##		"enabled": true,
##		"comfort_mode": true,
##		"vignetting_enabled": true,
##		"vignetting_intensity": 0.7,
##		"snap_turn_enabled": false,
##		"snap_turn_angle": 45.0,
##		"stationary_mode": false
##	},
##
## NEW CODE:
##	"vr": {
##		"enabled": true,
##		"comfort_mode": true,
##		"vignetting_enabled": true,
##		"vignetting_intensity": 0.7,
##		"snap_turn_enabled": false,
##		"snap_turn_angle": 45.0,
##		"stationary_mode": false,
##		"controller_type": "generic",  # Auto-detected, can be: meta, valve, htc, generic
##		"button_remappings": {}  # Custom button remappings per action
##	},


## USAGE EXAMPLES:

## Example 1: In a gameplay script, listen to semantic actions instead of button names
##	func _ready():
##		var vr_manager = ResonanceEngine.get_vr_manager()
##		vr_manager.controller_button_pressed.connect(_on_button_pressed)
##
##	func _on_button_pressed(hand: String, action: String):
##		match action:
##			"interact":
##				# Handle primary interaction (works on Meta, Valve, HTC)
##				player.interact()
##			"grab":
##				# Handle grab action
##				player.grab()
##			"menu":
##				# Handle menu (pause)
##				show_menu()


## Example 2: Query current button state using semantic names
##	var vr_manager = ResonanceEngine.get_vr_manager()
##	var remapper = vr_manager.button_remapper
##
##	var left_controller = vr_manager.get_controller("left")
##	if remapper.is_action_pressed("interact", left_controller):
##		print("Interact button pressed!")
##
##	if remapper.is_action_pressed("grab", left_controller):
##		print("Grab button pressed!")


## Example 3: Set custom button remapping at runtime
##	var remapper = vr_manager.button_remapper
##
##	# Swap interact button priority (try trigger_click first, then ax_button)
##	remapper.set_custom_mapping("interact", ["trigger_click", "ax_button"])
##
##	# This will be saved to SettingsManager automatically


## Example 4: Get all available mappings for settings UI
##	var remapper = vr_manager.button_remapper
##
##	# Get all current mappings
##	var all_mappings = remapper.get_all_mappings()
##	for action_name in all_mappings:
##		print("Action: %s -> Button: %s" % [action_name, all_mappings[action_name]])
##
##	# Get detailed action info for UI display
##	var action_info = remapper.get_action_info()
##	for info in action_info:
##		print("Action: %s" % info.action)
##		print("  Description: %s" % info.description)
##		print("  Mapped to: %s" % info.mapped_to)
##		print("  Available: %s" % info.button_names)
