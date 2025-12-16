## VRManager - OpenXR Integration and VR Hardware Management
## Handles VR hardware communication, HMD tracking, and motion controller input.
## Provides desktop fallback mode when VR hardware is unavailable.
##
## Requirements:
## - 3.1: Use Godot's OpenXRInterface to interface with VR hardware through OpenXR runtime
## - 3.2: Detect and initialize HMD using XROrigin3D
## - 3.3: Update XRCamera3D node every frame with HMD position/rotation
## - 3.4: Track motion controller positions and button states using XRController3D nodes
## - 4.1-4.4: VR comfort features (handled by other systems)
## - 4.5: Fall back to desktop mode with keyboard and mouse controls when VR unavailable
extends Node
class_name VRManager

## Emitted when VR is successfully initialized
signal vr_initialized
## Emitted when VR initialization fails and desktop fallback is activated
signal desktop_fallback_activated
## Emitted when HMD tracking is updated
signal hmd_tracking_updated(transform: Transform3D)
## Emitted when a controller's tracking is updated
signal controller_tracking_updated(hand: String, transform: Transform3D)
## Emitted when a controller button is pressed
signal controller_button_pressed(hand: String, button: String)
## Emitted when a controller button is released
signal controller_button_released(hand: String, button: String)
## Emitted when VR session ends
signal vr_session_ended

## Hand identifiers
enum Hand {
	LEFT = 0,
	RIGHT = 1
}

## VR mode state
enum VRMode {
	NONE = 0,      ## Not initialized
	VR = 1,        ## Full VR mode with HMD
	DESKTOP = 2   ## Desktop fallback mode
}

## OpenXR interface reference
var xr_interface: XRInterface = null

## XR scene nodes - these will be created or found in the scene tree
var xr_origin: XROrigin3D = null
var xr_camera: XRCamera3D = null
var left_controller: XRController3D = null
var right_controller: XRController3D = null

## Current VR mode
var current_mode: VRMode = VRMode.NONE

## Desktop fallback camera (used when VR is not available)
var desktop_camera: Camera3D = null

## Tracking state
var _hmd_connected: bool = false
var _left_controller_connected: bool = false
var _right_controller_connected: bool = false

## Last known poses for interpolation
var _last_hmd_transform: Transform3D = Transform3D.IDENTITY
var _last_left_controller_transform: Transform3D = Transform3D.IDENTITY
var _last_right_controller_transform: Transform3D = Transform3D.IDENTITY

## Controller state tracking
var _left_controller_state: Dictionary = {}
var _right_controller_state: Dictionary = {}

## Dead zone configuration
var _deadzone_trigger: float = 0.1
var _deadzone_grip: float = 0.1
var _deadzone_thumbstick: float = 0.15
var _deadzone_enabled: bool = true

## Button debouncing
var _button_last_pressed: Dictionary = {}  # Track last press time for each button
var _debounce_threshold_ms: float = 50.0  # 50ms debounce window

## Desktop mode settings
var _desktop_mouse_sensitivity: float = 0.002
var _desktop_move_speed: float = 10.0
var _desktop_camera_pitch: float = 0.0
var _desktop_camera_yaw: float = 0.0


func _ready() -> void:
	# Don't auto-initialize - let the engine coordinator call initialize_vr()
	# Load dead zone settings from SettingsManager if available
	_load_deadzone_settings()
	pass



## Initialize VR system - attempts OpenXR first, falls back to desktop if unavailable
## Returns true if initialization succeeded (either VR or desktop mode)
func initialize_vr(force_vr: bool = false, force_desktop: bool = false) -> bool:
	_log_info("Initializing VR Manager...")
	
	if force_desktop:
		_log_info("Launch Flag: Forcing Desktop Mode (skipping OpenXR)")
		enable_desktop_fallback()
		return true

	# Try to initialize OpenXR
	if _init_openxr():
		current_mode = VRMode.VR
		_log_info("VR mode initialized successfully")
		vr_initialized.emit()
		return true
	
	# If VR was forced but failed, we should still fallback but log a critical error
	if force_vr:
		_log_error("Launch Flag: Forced VR failed! Falling back to desktop.")
	
	# Fall back to desktop mode
	_log_warning("VR hardware not available or OpenXR initialization failed, enabling desktop fallback")
	_log_debug("OpenXR initialization failed - this is expected when:")
	_log_debug("- No VR headset is connected")
	_log_debug("- VR runtime (SteamVR, Oculus, etc.) is not running")
	_log_debug("- Graphics requirements are not met")
	_log_debug("- OpenXR runtime is not properly installed")
	enable_desktop_fallback()
	return true


## Initialize OpenXR interface and detect HMD
## Requirements: 3.1, 3.2
func _init_openxr() -> bool:
	# Find the OpenXR interface
	xr_interface = XRServer.find_interface("OpenXR")
	
	if xr_interface == null:
		_log_warning("OpenXR interface not found")
		return false
	
	# CRITICAL: Set up viewport XR mode BEFORE initializing OpenXR
	# This MUST be done first to prevent XR_ERROR_GRAPHICS_REQUIREMENTS_CALL_MISSING
	# Setting viewport.use_xr = true triggers Godot's internal OpenXR graphics requirements setup
	# This is the key step that prevents the graphics requirements error
	var viewport := get_viewport()
	if viewport:
		viewport.use_xr = true
		_log_info("Viewport XR mode enabled - triggering internal graphics requirements setup")
	else:
		_log_error("Could not get viewport - OpenXR initialization will likely fail")
		return false
	
	# Check if OpenXR is initialized
	if not xr_interface.is_initialized():
		# Try to initialize it
		if not xr_interface.initialize():
			_log_warning("Failed to initialize OpenXR interface")
			return false
	
	_log_info("OpenXR interface initialized successfully")
	
	# Connect to XR server signals for tracking
	XRServer.tracker_added.connect(_on_tracker_added)
	XRServer.tracker_removed.connect(_on_tracker_removed)
	
	# Set up XR scene nodes
	_setup_xr_nodes()
	
	_hmd_connected = true
	return true


## Set up graphics requirements for OpenXR
## This is REQUIRED by the OpenXR specification before session creation
## Prevents XR_ERROR_GRAPHICS_REQUIREMENTS_CALL_MISSING error
func _setup_graphics_requirements() -> bool:
	_log_info("Setting up OpenXR graphics requirements...")
	
	# Validate that we have a valid XR interface
	if xr_interface == null:
		_log_error("Cannot set up graphics requirements: XR interface is null")
		return false
	
	# Check if the interface supports get_graphics_requirements method
	if not xr_interface.has_method("get_graphics_requirements"):
		_log_warning("OpenXR interface does not support get_graphics_requirements() method")
		_log_warning("This may cause XR_ERROR_GRAPHICS_REQUIREMENTS_CALL_MISSING error")
		# Some Godot versions may not have this method exposed
		# We'll continue and hope the OpenXR runtime handles it
		return true
	
	# Check if we have a valid rendering driver
	var rendering_driver = ProjectSettings.get_setting("rendering/driver/name")

	_log_info("Current rendering driver: %s" % rendering_driver)
	
	# For Vulkan (the primary rendering driver for OpenXR)
	if rendering_driver == "vulkan":
		# Get the Vulkan graphics requirements for OpenXR
		# This ensures the graphics requirements are properly set before initialization
		# This is the CRITICAL call that prevents XR_ERROR_GRAPHICS_REQUIREMENTS_CALL_MISSING
		var vulkan_requirements = xr_interface.get_graphics_requirements()
		
		if vulkan_requirements == null:
			_log_warning("get_graphics_requirements() returned null - interface may not support this method")
			# Don't fail here - some OpenXR implementations may not require explicit graphics requirements
			return true
		
		_log_info("Vulkan graphics requirements retrieved successfully")
		_log_debug("Graphics requirements: %s" % str(vulkan_requirements))
		
		# Additional validation could be added here to check:
		# - Minimum Vulkan version
		# - Required extensions
		# - Hardware capabilities
		
		return true
	
	# For other rendering drivers (OpenGL, etc.)
	elif rendering_driver == "opengl3":
		_log_info("OpenGL rendering driver detected - OpenXR may have limited support")
		# OpenGL has different requirements, but similar principles apply
		# For OpenGL, we might need to set up the graphics context differently
		var gl_requirements = xr_interface.get_graphics_requirements()
		_log_debug("OpenGL graphics requirements: %s" % str(gl_requirements))
		return true
	
	else:
		_log_warning("Unsupported rendering driver for OpenXR: %s" % rendering_driver)
		_log_warning("This may cause XR_ERROR_GRAPHICS_REQUIREMENTS_CALL_MISSING or similar errors")
		# Still return true to allow initialization attempt
		# The OpenXR runtime will handle unsupported drivers appropriately
		return true


## Set up XROrigin3D, XRCamera3D, and XRController3D nodes
## Requirements: 3.2, 3.4
func _setup_xr_nodes() -> void:
	# Look for existing XR nodes in the scene tree first
	xr_origin = _find_node_of_type("XROrigin3D")
	
	if xr_origin == null:
		# Create XROrigin3D if not found
		xr_origin = XROrigin3D.new()
		xr_origin.name = "XROrigin3D"
		add_child(xr_origin)
		_log_info("Created XROrigin3D node")
	
	# Set up XRCamera3D
	xr_camera = _find_child_of_type(xr_origin, "XRCamera3D")
	if xr_camera == null:
		xr_camera = XRCamera3D.new()
		xr_camera.name = "XRCamera3D"
		xr_origin.add_child(xr_camera)
		_log_info("Created XRCamera3D node")
	
	# Set up left controller
	left_controller = _find_controller(xr_origin, "left")
	if left_controller == null:
		left_controller = XRController3D.new()
		left_controller.name = "LeftController"
		left_controller.tracker = "left_hand"
		xr_origin.add_child(left_controller)
		_log_info("Created left XRController3D node")
	
	# Set up right controller
	right_controller = _find_controller(xr_origin, "right")
	if right_controller == null:
		right_controller = XRController3D.new()
		right_controller.name = "RightController"
		right_controller.tracker = "right_hand"
		xr_origin.add_child(right_controller)
		_log_info("Created right XRController3D node")
	
	# Connect controller signals
	_connect_controller_signals(left_controller, "left")
	_connect_controller_signals(right_controller, "right")


## Connect controller input signals
func _connect_controller_signals(controller: XRController3D, hand: String) -> void:
	if controller == null:
		return
	
	controller.button_pressed.connect(_on_controller_button_pressed.bind(hand))
	controller.button_released.connect(_on_controller_button_released.bind(hand))
	controller.input_float_changed.connect(_on_controller_float_changed.bind(hand))
	controller.input_vector2_changed.connect(_on_controller_vector2_changed.bind(hand))


## Find a node of a specific type in the scene tree
func _find_node_of_type(type_name: String) -> Node:
	var root := get_tree().root
	return _recursive_find_type(root, type_name)


func _recursive_find_type(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name:
		return node
	for child in node.get_children():
		var result := _recursive_find_type(child, type_name)
		if result != null:
			return result
	return null


## Find a child node of a specific type
func _find_child_of_type(parent: Node, type_name: String) -> Node:
	for child in parent.get_children():
		if child.get_class() == type_name:
			return child
	return null


## Find a controller by hand tracker name
func _find_controller(parent: Node, hand: String) -> XRController3D:
	var tracker_name := hand + "_hand"
	for child in parent.get_children():
		if child is XRController3D:
			if child.tracker == tracker_name:
				return child
	return null



## Enable desktop fallback mode when VR hardware is unavailable
## Requirements: 4.5
func enable_desktop_fallback() -> void:
	current_mode = VRMode.DESKTOP
	
	# Disable XR on viewport
	var viewport := get_viewport()
	if viewport:
		viewport.use_xr = false
	
	# Create or find a desktop camera
	if not desktop_camera or not is_instance_valid(desktop_camera):
		desktop_camera = _find_node_of_type("Camera3D")
		
		if not desktop_camera or not is_instance_valid(desktop_camera):
			# Create a new camera for desktop mode
			desktop_camera = Camera3D.new()
			desktop_camera.name = "DesktopCamera"
			desktop_camera.current = true
			add_child(desktop_camera)
			_log_info("Created desktop fallback camera")
		else:
			desktop_camera.current = true
	
	# Set up mouse capture for desktop mode
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	_log_info("Desktop fallback mode enabled")
	desktop_fallback_activated.emit()


## Process function - updates tracking every frame
## Requirements: 3.3
func _process(delta: float) -> void:
	if current_mode == VRMode.VR:
		update_tracking()
	elif current_mode == VRMode.DESKTOP:
		_update_desktop_controls(delta)


## Update HMD and controller tracking
## Requirements: 3.3, 3.4
func update_tracking() -> void:
	if current_mode != VRMode.VR:
		return
	
	# Update HMD tracking
	if xr_camera and is_instance_valid(xr_camera) and _hmd_connected:
		var hmd_transform := xr_camera.global_transform
		if hmd_transform != _last_hmd_transform:
			_last_hmd_transform = hmd_transform
			hmd_tracking_updated.emit(hmd_transform)
	
	# Update left controller tracking
	if left_controller and is_instance_valid(left_controller) and _left_controller_connected:
		var left_transform := left_controller.global_transform
		if left_transform != _last_left_controller_transform:
			_last_left_controller_transform = left_transform
			controller_tracking_updated.emit("left", left_transform)
		_update_controller_state(left_controller, "left")
	
	# Update right controller tracking
	if right_controller and is_instance_valid(right_controller) and _right_controller_connected:
		var right_transform := right_controller.global_transform
		if right_transform != _last_right_controller_transform:
			_last_right_controller_transform = right_transform
			controller_tracking_updated.emit("right", right_transform)
		_update_controller_state(right_controller, "right")


## Update controller state (buttons, triggers, thumbsticks)
func _update_controller_state(controller: XRController3D, hand: String) -> void:
	# Defensive null check
	if not controller or not is_instance_valid(controller):
		return

	var state: Dictionary = _left_controller_state if hand == "left" else _right_controller_state

	# Update trigger value with dead zone
	var trigger_raw = controller.get_float("trigger")
	state["trigger"] = _apply_deadzone(trigger_raw, _deadzone_trigger)

	# Update grip value with dead zone
	var grip_raw = controller.get_float("grip")
	state["grip"] = _apply_deadzone(grip_raw, _deadzone_grip)

	# Update thumbstick with dead zone
	var thumbstick_raw = controller.get_vector2("primary")
	state["thumbstick"] = _apply_deadzone_vector2(thumbstick_raw, _deadzone_thumbstick)

	# Debug: Print thumbstick value for left controller (only if significant)
	if hand == "left" and state["thumbstick"] != Vector2.ZERO:
		print("[VRManager] Left thumbstick: ", state["thumbstick"])

	# Update button states with debouncing
	var button_ax_pressed = controller.is_button_pressed("ax_button")
	state["button_ax"] = _debounce_button("ax_button_%s" % hand, button_ax_pressed)

	var button_by_pressed = controller.is_button_pressed("by_button")
	state["button_by"] = _debounce_button("by_button_%s" % hand, button_by_pressed)

	var button_menu_pressed = controller.is_button_pressed("menu_button")
	state["button_menu"] = _debounce_button("menu_button_%s" % hand, button_menu_pressed)

	var thumbstick_click_pressed = controller.is_button_pressed("primary_click")
	state["thumbstick_click"] = _debounce_button("primary_click_%s" % hand, thumbstick_click_pressed)

	if hand == "left":
		_left_controller_state = state
	else:
		_right_controller_state = state


## Desktop mode controls update
func _update_desktop_controls(delta: float) -> void:
	if not desktop_camera or not is_instance_valid(desktop_camera):
		return
	
	# Handle keyboard movement
	var input_dir := Vector3.ZERO
	
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_dir.z -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_dir.z += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	if Input.is_key_pressed(KEY_SPACE):
		input_dir.y += 1
	if Input.is_key_pressed(KEY_SHIFT):
		input_dir.y -= 1
	
	if input_dir != Vector3.ZERO:
		input_dir = input_dir.normalized()
		var movement := desktop_camera.global_transform.basis * input_dir * _desktop_move_speed * delta
		desktop_camera.global_position += movement
	
	# Emit tracking update for desktop camera (simulates HMD)
	hmd_tracking_updated.emit(desktop_camera.global_transform)


## Handle mouse input for desktop mode
func _input(event: InputEvent) -> void:
	if current_mode != VRMode.DESKTOP:
		return
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_desktop_camera_yaw -= event.relative.x * _desktop_mouse_sensitivity
		_desktop_camera_pitch -= event.relative.y * _desktop_mouse_sensitivity
		_desktop_camera_pitch = clamp(_desktop_camera_pitch, -PI/2, PI/2)
		
		# Null check and instance validity check before accessing camera properties
		if desktop_camera and is_instance_valid(desktop_camera):
			desktop_camera.rotation = Vector3(_desktop_camera_pitch, _desktop_camera_yaw, 0)
		else:
			push_warning("VRManager: desktop_camera is null or invalid when setting rotation")
	
	# Toggle mouse capture with Escape
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED



## Get HMD pose (position and rotation)
## Returns the current HMD transform
func get_hmd_pose() -> Transform3D:
	if current_mode == VRMode.VR and xr_camera and is_instance_valid(xr_camera):
		return xr_camera.global_transform
	elif current_mode == VRMode.DESKTOP and desktop_camera and is_instance_valid(desktop_camera):
		return desktop_camera.global_transform
	return Transform3D.IDENTITY


## Get controller state for a specific hand
## Returns a dictionary with trigger, grip, thumbstick, and button states
func get_controller_state(hand: String) -> Dictionary:
	# Check if there's a VR input simulator running
	var simulator = get_tree().root.find_child("VRInputSimulator", true, false)
	if simulator and simulator.has_method("get_simulated_state"):
		return simulator.get_simulated_state(hand)

	if current_mode == VRMode.DESKTOP:
		# Return simulated controller state for desktop mode
		return _get_desktop_simulated_controller_state(hand)

	if hand == "left":
		return _left_controller_state.duplicate()
	elif hand == "right":
		return _right_controller_state.duplicate()

	return {}


## Get simulated controller state for desktop mode
func _get_desktop_simulated_controller_state(hand: String) -> Dictionary:
	var state := {
		"trigger": 0.0,
		"grip": 0.0,
		"thumbstick": Vector2.ZERO,
		"button_ax": false,
		"button_by": false,
		"button_menu": false,
		"thumbstick_click": false,
		"position": Vector3.ZERO,
		"rotation": Quaternion.IDENTITY
	}
	
	# Simulate right controller with mouse buttons
	if hand == "right":
		state["trigger"] = 1.0 if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) else 0.0
		state["grip"] = 1.0 if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) else 0.0
	
	return state


## Get controller transform for a specific hand
func get_controller_transform(hand: String) -> Transform3D:
	if current_mode == VRMode.VR:
		if hand == "left" and left_controller and is_instance_valid(left_controller):
			return left_controller.global_transform
		elif hand == "right" and right_controller and is_instance_valid(right_controller):
			return right_controller.global_transform
	elif current_mode == VRMode.DESKTOP and desktop_camera and is_instance_valid(desktop_camera):
		# In desktop mode, simulate controller at camera position
		return desktop_camera.global_transform
	
	return Transform3D.IDENTITY


## Check if VR mode is active
func is_vr_active() -> bool:
	return current_mode == VRMode.VR


## Check if desktop fallback is active
func is_desktop_mode() -> bool:
	return current_mode == VRMode.DESKTOP


## Check if HMD is connected and tracking
func is_hmd_connected() -> bool:
	return _hmd_connected


## Check if a specific controller is connected
func is_controller_connected(hand: String) -> bool:
	if hand == "left":
		return _left_controller_connected
	elif hand == "right":
		return _right_controller_connected
	return false


## Get the XROrigin3D node
func get_xr_origin() -> XROrigin3D:
	return xr_origin


## Get the XRCamera3D node
func get_xr_camera() -> XRCamera3D:
	return xr_camera


## Get a controller node by hand
func get_controller(hand: String) -> XRController3D:
	if hand == "left":
		return left_controller
	elif hand == "right":
		return right_controller
	return null


## Get the current VR mode
func get_current_mode() -> VRMode:
	return current_mode


## Get the current camera (XR or desktop)
func get_current_camera() -> Camera3D:
	if current_mode == VRMode.VR and xr_camera and is_instance_valid(xr_camera):
		return xr_camera
	elif current_mode == VRMode.DESKTOP and desktop_camera and is_instance_valid(desktop_camera):
		return desktop_camera
	return null



## Signal handlers for tracker events

func _on_tracker_added(tracker_name: StringName, type: int) -> void:
	_log_info("Tracker added: %s (type: %d)" % [tracker_name, type])
	
	if tracker_name == &"left_hand":
		_left_controller_connected = true
	elif tracker_name == &"right_hand":
		_right_controller_connected = true
	elif tracker_name == &"head":
		_hmd_connected = true


func _on_tracker_removed(tracker_name: StringName, type: int) -> void:
	_log_info("Tracker removed: %s (type: %d)" % [tracker_name, type])
	
	if tracker_name == &"left_hand":
		_left_controller_connected = false
	elif tracker_name == &"right_hand":
		_right_controller_connected = false
	elif tracker_name == &"head":
		_hmd_connected = false
		# If HMD is disconnected, consider falling back to desktop
		_log_warning("HMD disconnected - consider enabling desktop fallback")


## Controller button signal handlers

func _on_controller_button_pressed(button_name: String, hand: String) -> void:
	_log_debug("Controller button pressed: %s on %s hand" % [button_name, hand])
	controller_button_pressed.emit(hand, button_name)


func _on_controller_button_released(button_name: String, hand: String) -> void:
	_log_debug("Controller button released: %s on %s hand" % [button_name, hand])
	controller_button_released.emit(hand, button_name)


func _on_controller_float_changed(input_name: String, value: float, hand: String) -> void:
	# Update state dictionary with dead zone applied
	var state: Dictionary = _left_controller_state if hand == "left" else _right_controller_state

	# Apply appropriate dead zone based on input type
	var processed_value: float = value
	if _deadzone_enabled:
		if input_name == "trigger":
			processed_value = _apply_deadzone(value, _deadzone_trigger)
		elif input_name == "grip" or input_name == "squeeze":
			processed_value = _apply_deadzone(value, _deadzone_grip)

	state[input_name] = processed_value

	if hand == "left":
		_left_controller_state = state
	else:
		_right_controller_state = state


func _on_controller_vector2_changed(input_name: String, value: Vector2, hand: String) -> void:
	# Update state dictionary with dead zone applied
	var state: Dictionary = _left_controller_state if hand == "left" else _right_controller_state

	# Apply dead zone for analog stick inputs
	var processed_value: Vector2 = value
	if _deadzone_enabled and input_name == "primary":
		processed_value = _apply_deadzone_vector2(value, _deadzone_thumbstick)

	state[input_name] = processed_value

	if hand == "left":
		_left_controller_state = state
	else:
		_right_controller_state = state


## Shutdown and cleanup

func shutdown() -> void:
	_log_info("VRManager shutting down...")
	
	# Disconnect signals
	if XRServer.tracker_added.is_connected(_on_tracker_added):
		XRServer.tracker_added.disconnect(_on_tracker_added)
	if XRServer.tracker_removed.is_connected(_on_tracker_removed):
		XRServer.tracker_removed.disconnect(_on_tracker_removed)
	
	# Reset state
	_hmd_connected = false
	_left_controller_connected = false
	_right_controller_connected = false
	current_mode = VRMode.NONE
	
	# Restore mouse mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	vr_session_ended.emit()
	_log_info("VRManager shutdown complete")


## Dead zone and debouncing utility functions

## Apply dead zone to a scalar analog value (trigger, grip)
## Returns 0.0 if below threshold, otherwise returns normalized value (0.0-1.0)
func _apply_deadzone(value: float, threshold: float) -> float:
	if not _deadzone_enabled:
		return value

	# Clamp to valid range
	value = clamp(value, 0.0, 1.0)

	# If below dead zone threshold, return 0
	if abs(value) < threshold:
		return 0.0

	# Normalize the remaining range (threshold to 1.0 maps to 0.0 to 1.0)
	# This ensures the input feels responsive at the edge of the dead zone
	return (value - threshold) / (1.0 - threshold)


## Apply dead zone to a vector2 analog value (thumbstick)
## Returns Vector2.ZERO if magnitude is below threshold, otherwise returns normalized vector
func _apply_deadzone_vector2(value: Vector2, threshold: float) -> Vector2:
	if not _deadzone_enabled:
		return value

	# Get magnitude of the vector
	var magnitude: float = value.length()

	# If below dead zone threshold, return zero
	if magnitude < threshold:
		return Vector2.ZERO

	# Normalize the vector direction
	var direction: Vector2 = value.normalized()

	# Scale magnitude to remove dead zone (similar to scalar version)
	# Maps (threshold to 1.0) to (0.0 to 1.0)
	var scaled_magnitude: float = (magnitude - threshold) / (1.0 - threshold)
	scaled_magnitude = clamp(scaled_magnitude, 0.0, 1.0)

	return direction * scaled_magnitude


## Debounce button input to prevent multiple presses within the debounce window
## Returns true if this press should be accepted, false if it's a duplicate within the debounce window
func _debounce_button(button_id: String, is_pressed: bool) -> bool:
	var current_time_ms: int = Time.get_ticks_msec()
	var last_press_time: int = _button_last_pressed.get(button_id, -10000)

	# Button is not currently pressed
	if not is_pressed:
		return false

	# Check if enough time has passed since last press
	if (current_time_ms - last_press_time) >= _debounce_threshold_ms:
		# Update last press time
		_button_last_pressed[button_id] = current_time_ms
		return true

	# Still within debounce window, ignore duplicate press
	return false


## Load dead zone settings from SettingsManager if available
func _load_deadzone_settings() -> void:
	var settings = get_node_or_null("/root/SettingsManager")

	if settings == null:
		# Settings manager not available yet, use defaults
		_log_debug("SettingsManager not available, using default dead zones")
		return

	# Load dead zone values from settings
	if settings.has_method("get_setting"):
		_deadzone_trigger = settings.get_setting("controls", "deadzone_trigger", _deadzone_trigger)
		_deadzone_grip = settings.get_setting("controls", "deadzone_grip", _deadzone_grip)
		_deadzone_thumbstick = settings.get_setting("controls", "deadzone_thumbstick", _deadzone_thumbstick)
		_deadzone_enabled = settings.get_setting("controls", "deadzone_enabled", _deadzone_enabled)
		_debounce_threshold_ms = settings.get_setting("controls", "button_debounce_ms", _debounce_threshold_ms)

		_log_info("Dead zone settings loaded: trigger=%.2f, grip=%.2f, thumbstick=%.2f, debounce=%dms" % [
			_deadzone_trigger, _deadzone_grip, _deadzone_thumbstick, int(_debounce_threshold_ms)
		])


## Set dead zone values at runtime
func set_deadzone(trigger: float = -1.0, grip: float = -1.0, thumbstick: float = -1.0, enabled: bool = true) -> void:
	if trigger >= 0.0:
		_deadzone_trigger = clamp(trigger, 0.0, 1.0)
	if grip >= 0.0:
		_deadzone_grip = clamp(grip, 0.0, 1.0)
	if thumbstick >= 0.0:
		_deadzone_thumbstick = clamp(thumbstick, 0.0, 1.0)
	_deadzone_enabled = enabled

	_log_debug("Dead zones updated: trigger=%.2f, grip=%.2f, thumbstick=%.2f, enabled=%s" % [
		_deadzone_trigger, _deadzone_grip, _deadzone_thumbstick, enabled
	])


## Set button debounce threshold
func set_debounce_threshold(milliseconds: float) -> void:
	_debounce_threshold_ms = clamp(milliseconds, 0.0, 500.0)
	_log_debug("Button debounce threshold set to %dms" % int(_debounce_threshold_ms))


## Get current dead zone configuration
func get_deadzone_config() -> Dictionary:
	return {
		"trigger": _deadzone_trigger,
		"grip": _deadzone_grip,
		"thumbstick": _deadzone_thumbstick,
		"enabled": _deadzone_enabled,
		"debounce_ms": int(_debounce_threshold_ms)
	}


## Logging helpers (use engine logger if available)

func _log_debug(message: String) -> void:
	var engine := _get_engine()
	if engine != null and engine.has_method("log_debug"):
		engine.log_debug("[VRManager] " + message)
	else:
		print("[DEBUG] [VRManager] " + message)


func _log_info(message: String) -> void:
	var engine := _get_engine()
	if engine != null and engine.has_method("log_info"):
		engine.log_info("[VRManager] " + message)
	else:
		print("[INFO] [VRManager] " + message)


func _log_warning(message: String) -> void:
	var engine := _get_engine()
	if engine != null and engine.has_method("log_warning"):
		engine.log_warning("[VRManager] " + message)
	else:
		push_warning("[VRManager] " + message)


func _log_error(message: String) -> void:
	var engine := _get_engine()
	if engine != null and engine.has_method("log_error"):
		engine.log_error("[VRManager] " + message)
	else:
		push_error("[VRManager] " + message)


func _get_engine() -> Node:
	if Engine.has_singleton("ResonanceEngine"):
		return Engine.get_singleton("ResonanceEngine")
	return get_node_or_null("/root/ResonanceEngine")


## Clean up resources when node exits tree
func _exit_tree() -> void:
	"""Clean up resources when node exits tree."""
	_log_info("VRManager exiting tree, cleaning up resources...")

	# Disconnect XRServer signals to prevent memory leaks
	if XRServer.tracker_added.is_connected(_on_tracker_added):
		XRServer.tracker_added.disconnect(_on_tracker_added)
	if XRServer.tracker_removed.is_connected(_on_tracker_removed):
		XRServer.tracker_removed.disconnect(_on_tracker_removed)

	# Disconnect controller signals to prevent memory leaks
	if left_controller and is_instance_valid(left_controller):
		if left_controller.button_pressed.is_connected(_on_controller_button_pressed):
			left_controller.button_pressed.disconnect(_on_controller_button_pressed)
		if left_controller.button_released.is_connected(_on_controller_button_released):
			left_controller.button_released.disconnect(_on_controller_button_released)
		if left_controller.input_float_changed.is_connected(_on_controller_float_changed):
			left_controller.input_float_changed.disconnect(_on_controller_float_changed)
		if left_controller.input_vector2_changed.is_connected(_on_controller_vector2_changed):
			left_controller.input_vector2_changed.disconnect(_on_controller_vector2_changed)

	if right_controller and is_instance_valid(right_controller):
		if right_controller.button_pressed.is_connected(_on_controller_button_pressed):
			right_controller.button_pressed.disconnect(_on_controller_button_pressed)
		if right_controller.button_released.is_connected(_on_controller_button_released):
			right_controller.button_released.disconnect(_on_controller_button_released)
		if right_controller.input_float_changed.is_connected(_on_controller_float_changed):
			right_controller.input_float_changed.disconnect(_on_controller_float_changed)
		if right_controller.input_vector2_changed.is_connected(_on_controller_vector2_changed):
			right_controller.input_vector2_changed.disconnect(_on_controller_vector2_changed)

	# Uninitialize XR interface before cleaning up nodes
	if xr_interface and xr_interface.is_initialized():
		xr_interface.uninitialize()
		xr_interface = null

	# Clean up dynamically created nodes
	if desktop_camera and is_instance_valid(desktop_camera):
		if desktop_camera.get_parent() == self:
			desktop_camera.queue_free()
		desktop_camera = null

	# Clean up XR nodes (only if we created them)
	if xr_origin and is_instance_valid(xr_origin):
		if xr_origin.get_parent() == self:
			# XR origin will free its children (camera, controllers) automatically
			xr_origin.queue_free()
		xr_origin = null

	# Clear references to prevent accessing freed nodes
	xr_camera = null
	left_controller = null
	right_controller = null

	_log_info("VRManager resource cleanup complete")
