## PilotController - VR Input Handling for Spacecraft Controls
## Maps XRController3D inputs to spacecraft controls with desktop fallback support.
## Handles throttle (trigger), rotation (thumbstick), and action buttons.
##
## Requirements:
## - 2.1-2.5: VR rendering and performance
## - 19.1: Load and render spacecraft cockpit with interactive controls
## - 19.2: Position camera at pilot viewpoint
## - 19.3: Detect collisions between controller models and cockpit elements
## - 19.4: Trigger spacecraft system response on control activation
## - 19.5: Show real-time telemetry data (velocity, position, SNR)
extends Node
class_name PilotController

## Emitted when throttle value changes
signal throttle_changed(value: float)
## Emitted when rotation input changes
signal rotation_changed(pitch: float, yaw: float, roll: float)
## Emitted when an action button is pressed
signal action_pressed(action_name: String)
## Emitted when an action button is released
signal action_released(action_name: String)
## Emitted when control mode changes (VR/Desktop)
signal control_mode_changed(is_vr: bool)

## Control hand configuration
enum ControlHand {
	LEFT = 0,   ## Left hand controls throttle
	RIGHT = 1   ## Right hand controls rotation
}

## Reference to the spacecraft being controlled
@export var spacecraft: Spacecraft = null

## Reference to VR manager
var vr_manager: VRManager = null

## Which hand controls throttle (default: left trigger)
@export var throttle_hand: ControlHand = ControlHand.LEFT

## Which hand controls rotation (default: right thumbstick)
@export var rotation_hand: ControlHand = ControlHand.RIGHT

## Throttle sensitivity (how quickly throttle responds)
@export var throttle_sensitivity: float = 1.0

## Rotation sensitivity multipliers
@export var pitch_sensitivity: float = 1.0
@export var yaw_sensitivity: float = 1.0
@export var roll_sensitivity: float = 1.0

## Deadzone for thumbstick input (prevents drift)
@export var thumbstick_deadzone: float = 0.15

## Whether to invert pitch (up/down)
@export var invert_pitch: bool = false

## Whether to invert yaw (left/right)
@export var invert_yaw: bool = false

## Current control state
var _current_throttle: float = 0.0
var _current_pitch: float = 0.0
var _current_yaw: float = 0.0
var _current_roll: float = 0.0

## Desktop control state
var _desktop_throttle_up: bool = false
var _desktop_throttle_down: bool = false

## Action button mappings (button name -> action name)
var _action_mappings: Dictionary = {
	"ax_button": "primary_action",      ## A/X button - primary action (scan, interact)
	"by_button": "secondary_action",    ## B/Y button - secondary action (menu, cancel)
	"grip": "grab",                     ## Grip button - grab objects
	"menu_button": "pause",             ## Menu button - pause game
	"thumbstick_click": "boost"         ## Thumbstick click - boost/sprint
}

## Track which actions are currently pressed
var _pressed_actions: Dictionary = {}

## Is VR mode active
var _is_vr_mode: bool = false

## Are controls currently locked (for capture events, cutscenes, etc.)
var _controls_locked: bool = false


func _ready() -> void:
	# Try to find VR manager and spacecraft if not set
	_find_references()
	
	# Set up input actions for desktop mode
	_setup_desktop_input_actions()


func _find_references() -> void:
	"""Find references to VR manager and spacecraft."""
	# Find VR manager
	var engine_node = get_node_or_null("/root/ResonanceEngine")
	if engine_node and engine_node.has_method("get_vr_manager"):
		vr_manager = engine_node.get_vr_manager()
	
	if vr_manager == null:
		# Try to find VRManager directly
		vr_manager = _find_node_of_type("VRManager")
	
	# Find spacecraft if not set
	if spacecraft == null:
		spacecraft = _find_node_of_type("Spacecraft")
	
	# Connect to VR manager signals if available
	if vr_manager != null:
		if vr_manager.has_signal("vr_initialized"):
			vr_manager.vr_initialized.connect(_on_vr_initialized)
		if vr_manager.has_signal("desktop_fallback_activated"):
			vr_manager.desktop_fallback_activated.connect(_on_desktop_fallback)
		if vr_manager.has_signal("controller_button_pressed"):
			vr_manager.controller_button_pressed.connect(_on_vr_button_pressed)
		if vr_manager.has_signal("controller_button_released"):
			vr_manager.controller_button_released.connect(_on_vr_button_released)
		
		# Check current mode
		_is_vr_mode = vr_manager.is_vr_active()


func _find_node_of_type(type_name: String) -> Node:
	"""Find a node of a specific type in the scene tree."""
	var root := get_tree().root
	return _recursive_find_type(root, type_name)


func _recursive_find_type(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name or (node.has_method("get_class") and node.get_class() == type_name):
		return node
	# Also check script class name
	if node.get_script() != null:
		var script = node.get_script()
		if script.has_method("get_global_name"):
			if script.get_global_name() == type_name:
				return node
	# Check by class_name for custom classes
	if node is Spacecraft and type_name == "Spacecraft":
		return node
	if node is VRManager and type_name == "VRManager":
		return node
	
	for child in node.get_children():
		var result := _recursive_find_type(child, type_name)
		if result != null:
			return result
	return null


func _setup_desktop_input_actions() -> void:
	"""Set up input actions for desktop fallback mode."""
	# These actions should be defined in project settings, but we'll check for them
	# and use key codes directly if not available
	pass


func _process(delta: float) -> void:
	"""Process input every frame."""
	if vr_manager != null and vr_manager.is_vr_active():
		_process_vr_input(delta)
	else:
		_process_desktop_input(delta)
	
	# Apply controls to spacecraft
	_apply_controls_to_spacecraft()


## Process VR controller input
## Requirements: 19.3, 19.4
func _process_vr_input(delta: float) -> void:
	"""Process VR controller input."""
	if vr_manager == null:
		return
	
	# Get controller states
	var left_state := vr_manager.get_controller_state("left")
	var right_state := vr_manager.get_controller_state("right")
	
	# Process throttle from configured hand
	var throttle_state := left_state if throttle_hand == ControlHand.LEFT else right_state
	_process_throttle_input(throttle_state)
	
	# Process rotation from configured hand
	var rotation_state := right_state if rotation_hand == ControlHand.RIGHT else left_state
	_process_rotation_input(rotation_state)
	
	# Process action buttons from both hands
	_process_action_buttons(left_state, "left")
	_process_action_buttons(right_state, "right")


## Process throttle input from controller trigger
func _process_throttle_input(controller_state: Dictionary) -> void:
	"""Process throttle from trigger input."""
	var trigger_value: float = controller_state.get("trigger", 0.0)
	
	# Apply sensitivity
	var new_throttle := trigger_value * throttle_sensitivity
	new_throttle = clampf(new_throttle, 0.0, 1.0)
	
	# Check if throttle changed
	if abs(new_throttle - _current_throttle) > 0.01:
		_current_throttle = new_throttle
		throttle_changed.emit(_current_throttle)


## Process rotation input from thumbstick
func _process_rotation_input(controller_state: Dictionary) -> void:
	"""Process rotation from thumbstick input."""
	var thumbstick: Vector2 = controller_state.get("thumbstick", Vector2.ZERO)
	if thumbstick == null:
		thumbstick = controller_state.get("primary", Vector2.ZERO)
	if thumbstick == null:
		thumbstick = Vector2.ZERO
	
	# Apply deadzone
	thumbstick = _apply_deadzone(thumbstick)
	
	# Map thumbstick to pitch and yaw
	# X axis = yaw (left/right)
	# Y axis = pitch (up/down)
	var new_pitch := thumbstick.y * pitch_sensitivity
	var new_yaw := thumbstick.x * yaw_sensitivity
	
	# Apply inversion if configured
	if invert_pitch:
		new_pitch = -new_pitch
	if invert_yaw:
		new_yaw = -new_yaw
	
	# Roll is controlled by grip buttons or separate input
	# For now, check if grip is pressed on the rotation hand controller
	var grip_value: float = controller_state.get("grip", 0.0)
	var new_roll := 0.0
	
	# Use grip + thumbstick X for roll when grip is held
	if grip_value > 0.5:
		new_roll = thumbstick.x * roll_sensitivity
		new_yaw = 0.0  # Disable yaw when rolling
	
	# Check if rotation changed
	var rotation_changed_flag := false
	if abs(new_pitch - _current_pitch) > 0.01:
		_current_pitch = new_pitch
		rotation_changed_flag = true
	if abs(new_yaw - _current_yaw) > 0.01:
		_current_yaw = new_yaw
		rotation_changed_flag = true
	if abs(new_roll - _current_roll) > 0.01:
		_current_roll = new_roll
		rotation_changed_flag = true
	
	if rotation_changed_flag:
		rotation_changed.emit(_current_pitch, _current_yaw, _current_roll)


## Apply deadzone to thumbstick input
func _apply_deadzone(input: Vector2) -> Vector2:
	"""Apply deadzone to prevent stick drift."""
	var length := input.length()
	if length < thumbstick_deadzone:
		return Vector2.ZERO
	
	# Remap the input to start from 0 after deadzone
	var normalized := input.normalized()
	var remapped_length := (length - thumbstick_deadzone) / (1.0 - thumbstick_deadzone)
	return normalized * remapped_length


## Process action buttons from a controller
func _process_action_buttons(controller_state: Dictionary, hand: String) -> void:
	"""Process action button presses."""
	for button_name in _action_mappings:
		var action_name: String = _action_mappings[button_name]
		var is_pressed: bool = controller_state.get(button_name, false)
		
		# Handle boolean buttons
		if typeof(is_pressed) == TYPE_BOOL:
			var action_key := hand + "_" + action_name
			var was_pressed: bool = _pressed_actions.get(action_key, false)
			
			if is_pressed and not was_pressed:
				_pressed_actions[action_key] = true
				action_pressed.emit(action_name)
			elif not is_pressed and was_pressed:
				_pressed_actions[action_key] = false
				action_released.emit(action_name)


## Process desktop keyboard/mouse input
## Requirements: 4.5 (desktop fallback)
func _process_desktop_input(delta: float) -> void:
	"""Process desktop keyboard and mouse input."""
	# Throttle control with W/S or Shift/Ctrl
	var throttle_input := 0.0
	
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_SHIFT):
		throttle_input = 1.0
	elif Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_CTRL):
		throttle_input = 0.0
		# Apply braking (reverse thrust) - optional
	
	# Smooth throttle changes
	var throttle_change := (throttle_input - _current_throttle) * throttle_sensitivity * 2.0
	_current_throttle = clampf(_current_throttle + throttle_change * delta * 5.0, 0.0, 1.0)
	
	# Rotation control with arrow keys or IJKL
	var pitch_input := 0.0
	var yaw_input := 0.0
	var roll_input := 0.0
	
	# Pitch (up/down)
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_I):
		pitch_input = 1.0 if not invert_pitch else -1.0
	elif Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_K):
		pitch_input = -1.0 if not invert_pitch else 1.0
	
	# Yaw (left/right)
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_J):
		yaw_input = -1.0 if not invert_yaw else 1.0
	elif Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_L):
		yaw_input = 1.0 if not invert_yaw else -1.0
	
	# Roll (Q/E)
	if Input.is_key_pressed(KEY_Q):
		roll_input = -1.0
	elif Input.is_key_pressed(KEY_E):
		roll_input = 1.0
	
	# Apply sensitivity
	_current_pitch = pitch_input * pitch_sensitivity
	_current_yaw = yaw_input * yaw_sensitivity
	_current_roll = roll_input * roll_sensitivity
	
	# Process action keys
	_process_desktop_actions()


## Process desktop action key presses
func _process_desktop_actions() -> void:
	"""Process desktop action key presses."""
	# Space = primary action
	if Input.is_key_pressed(KEY_SPACE):
		if not _pressed_actions.get("desktop_primary_action", false):
			_pressed_actions["desktop_primary_action"] = true
			action_pressed.emit("primary_action")
	else:
		if _pressed_actions.get("desktop_primary_action", false):
			_pressed_actions["desktop_primary_action"] = false
			action_released.emit("primary_action")
	
	# F = secondary action
	if Input.is_key_pressed(KEY_F):
		if not _pressed_actions.get("desktop_secondary_action", false):
			_pressed_actions["desktop_secondary_action"] = true
			action_pressed.emit("secondary_action")
	else:
		if _pressed_actions.get("desktop_secondary_action", false):
			_pressed_actions["desktop_secondary_action"] = false
			action_released.emit("secondary_action")
	
	# Tab = boost
	if Input.is_key_pressed(KEY_TAB):
		if not _pressed_actions.get("desktop_boost", false):
			_pressed_actions["desktop_boost"] = true
			action_pressed.emit("boost")
	else:
		if _pressed_actions.get("desktop_boost", false):
			_pressed_actions["desktop_boost"] = false
			action_released.emit("boost")
	
	# Escape = pause (handled by VR manager for mouse capture)
	if Input.is_key_pressed(KEY_ESCAPE):
		if not _pressed_actions.get("desktop_pause", false):
			_pressed_actions["desktop_pause"] = true
			action_pressed.emit("pause")
	else:
		if _pressed_actions.get("desktop_pause", false):
			_pressed_actions["desktop_pause"] = false
			action_released.emit("pause")


## Apply current control state to spacecraft
## Requirements: 19.4
func _apply_controls_to_spacecraft() -> void:
	"""Apply current control inputs to the spacecraft."""
	if spacecraft == null:
		return
	
	# Don't apply controls if locked
	if _controls_locked:
		# Set spacecraft to neutral when locked
		spacecraft.set_throttle(0.0)
		spacecraft.apply_rotation(0.0, 0.0, 0.0)
		return
	
	# Apply throttle
	spacecraft.set_throttle(_current_throttle)
	
	# Apply rotation
	spacecraft.apply_rotation(_current_pitch, _current_yaw, _current_roll)


## Signal handlers for VR manager events

func _on_vr_initialized() -> void:
	"""Handle VR initialization."""
	_is_vr_mode = true
	control_mode_changed.emit(true)
	_log_info("VR mode activated")


func _on_desktop_fallback() -> void:
	"""Handle desktop fallback activation."""
	_is_vr_mode = false
	control_mode_changed.emit(false)
	_log_info("Desktop mode activated")


func _on_vr_button_pressed(hand: String, button: String) -> void:
	"""Handle VR controller button press."""
	if button in _action_mappings:
		var action_name: String = _action_mappings[button]
		var action_key := hand + "_" + action_name
		if not _pressed_actions.get(action_key, false):
			_pressed_actions[action_key] = true
			action_pressed.emit(action_name)


func _on_vr_button_released(hand: String, button: String) -> void:
	"""Handle VR controller button release."""
	if button in _action_mappings:
		var action_name: String = _action_mappings[button]
		var action_key := hand + "_" + action_name
		if _pressed_actions.get(action_key, false):
			_pressed_actions[action_key] = false
			action_released.emit(action_name)


## Public API

## Set the spacecraft to control
func set_spacecraft(new_spacecraft: Spacecraft) -> void:
	"""Set the spacecraft to control."""
	spacecraft = new_spacecraft


## Get the current throttle value
func get_throttle() -> float:
	"""Get the current throttle value (0.0 to 1.0)."""
	return _current_throttle


## Get the current rotation input
func get_rotation() -> Vector3:
	"""Get the current rotation input (pitch, yaw, roll)."""
	return Vector3(_current_pitch, _current_yaw, _current_roll)


## Get the current pitch input
func get_pitch() -> float:
	"""Get the current pitch input (-1.0 to 1.0)."""
	return _current_pitch


## Get the current yaw input
func get_yaw() -> float:
	"""Get the current yaw input (-1.0 to 1.0)."""
	return _current_yaw


## Get the current roll input
func get_roll() -> float:
	"""Get the current roll input (-1.0 to 1.0)."""
	return _current_roll


## Check if an action is currently pressed
func is_action_pressed(action_name: String) -> bool:
	"""Check if an action is currently pressed."""
	for key in _pressed_actions:
		if key.ends_with("_" + action_name) and _pressed_actions[key]:
			return true
	return false


## Check if VR mode is active
func is_vr_mode() -> bool:
	"""Check if VR mode is active."""
	return _is_vr_mode


## Set throttle sensitivity
func set_throttle_sensitivity(sensitivity: float) -> void:
	"""Set throttle sensitivity."""
	throttle_sensitivity = maxf(sensitivity, 0.1)


## Set rotation sensitivities
func set_rotation_sensitivity(pitch: float, yaw: float, roll: float) -> void:
	"""Set rotation sensitivities."""
	pitch_sensitivity = maxf(pitch, 0.1)
	yaw_sensitivity = maxf(yaw, 0.1)
	roll_sensitivity = maxf(roll, 0.1)


## Set thumbstick deadzone
func set_deadzone(deadzone: float) -> void:
	"""Set thumbstick deadzone."""
	thumbstick_deadzone = clampf(deadzone, 0.0, 0.5)


## Set pitch inversion
func set_invert_pitch(invert: bool) -> void:
	"""Set pitch inversion."""
	invert_pitch = invert


## Set yaw inversion
func set_invert_yaw(invert: bool) -> void:
	"""Set yaw inversion."""
	invert_yaw = invert


## Swap throttle and rotation hands
func swap_hands() -> void:
	"""Swap which hand controls throttle vs rotation."""
	var temp := throttle_hand
	throttle_hand = rotation_hand
	rotation_hand = temp as ControlHand


## Set action mapping
func set_action_mapping(button_name: String, action_name: String) -> void:
	"""Set a custom action mapping for a button."""
	_action_mappings[button_name] = action_name


## Get all action mappings
func get_action_mappings() -> Dictionary:
	"""Get all action mappings."""
	return _action_mappings.duplicate()


## Lock or unlock player controls
func set_controls_locked(locked: bool) -> void:
	"""Lock or unlock player controls (for capture events, cutscenes, etc.)."""
	_controls_locked = locked
	
	if locked:
		# Reset controls to neutral when locking
		_current_throttle = 0.0
		_current_pitch = 0.0
		_current_yaw = 0.0
		_current_roll = 0.0
		
		if spacecraft != null:
			spacecraft.set_throttle(0.0)
			spacecraft.apply_rotation(0.0, 0.0, 0.0)
		
		_log_info("Controls locked")
	else:
		_log_info("Controls unlocked")


## Check if controls are currently locked
func are_controls_locked() -> bool:
	"""Check if controls are currently locked."""
	return _controls_locked


## Reset controls to neutral
func reset_controls() -> void:
	"""Reset all controls to neutral position."""
	_current_throttle = 0.0
	_current_pitch = 0.0
	_current_yaw = 0.0
	_current_roll = 0.0
	_pressed_actions.clear()
	
	if spacecraft != null:
		spacecraft.set_throttle(0.0)
		spacecraft.apply_rotation(0.0, 0.0, 0.0)


## Get control state for saving/debugging
func get_control_state() -> Dictionary:
	"""Get current control state."""
	return {
		"throttle": _current_throttle,
		"pitch": _current_pitch,
		"yaw": _current_yaw,
		"roll": _current_roll,
		"is_vr_mode": _is_vr_mode,
		"throttle_hand": throttle_hand,
		"rotation_hand": rotation_hand,
		"throttle_sensitivity": throttle_sensitivity,
		"pitch_sensitivity": pitch_sensitivity,
		"yaw_sensitivity": yaw_sensitivity,
		"roll_sensitivity": roll_sensitivity,
		"thumbstick_deadzone": thumbstick_deadzone,
		"invert_pitch": invert_pitch,
		"invert_yaw": invert_yaw
	}


## Set control state from saved data
func set_control_state(state: Dictionary) -> void:
	"""Set control state from saved data."""
	if state.has("throttle_hand"):
		throttle_hand = state.throttle_hand
	if state.has("rotation_hand"):
		rotation_hand = state.rotation_hand
	if state.has("throttle_sensitivity"):
		throttle_sensitivity = state.throttle_sensitivity
	if state.has("pitch_sensitivity"):
		pitch_sensitivity = state.pitch_sensitivity
	if state.has("yaw_sensitivity"):
		yaw_sensitivity = state.yaw_sensitivity
	if state.has("roll_sensitivity"):
		roll_sensitivity = state.roll_sensitivity
	if state.has("thumbstick_deadzone"):
		thumbstick_deadzone = state.thumbstick_deadzone
	if state.has("invert_pitch"):
		invert_pitch = state.invert_pitch
	if state.has("invert_yaw"):
		invert_yaw = state.invert_yaw


## Logging helpers

func _log_info(message: String) -> void:
	var engine := get_node_or_null("/root/ResonanceEngine")
	if engine != null and engine.has_method("log_info"):
		engine.log_info("[PilotController] " + message)
	else:
		print("[INFO] [PilotController] " + message)


func _log_debug(message: String) -> void:
	var engine := get_node_or_null("/root/ResonanceEngine")
	if engine != null and engine.has_method("log_debug"):
		engine.log_debug("[PilotController] " + message)
	else:
		print("[DEBUG] [PilotController] " + message)
