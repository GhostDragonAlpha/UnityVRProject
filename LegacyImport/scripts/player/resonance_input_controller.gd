## ResonanceInputController - VR Controller Input for Resonance System
## Maps VR controller inputs to resonance system interactions
## Handles scanning, frequency emission, and resonance mode switching
##
## Requirements:
## - 20.1: Scan objects to determine harmonic frequency
## - 20.2: Emit matching frequency for constructive interference
## - 20.3: Emit inverted frequency for destructive interference
## - 20.4: Calculate interference as sum of wave amplitudes
## - 20.5: Cancel objects through destructive interference
## - 69.1-69.5: Haptic feedback integration
extends Node
class_name ResonanceInputController

## Preload HapticManager script for class constant access
const HapticManagerScript = preload("res://scripts/core/haptic_manager.gd")

## Emitted when an object is successfully scanned
signal object_scanned(object: Node3D, frequency: float)
## Emitted when frequency emission starts
signal frequency_emitted(frequency: float, mode: String)
## Emitted when frequency emission stops
signal emission_stopped()
## Emitted when resonance mode changes
signal mode_changed(mode: String)
## Emitted when quick-switching to a recent frequency
signal frequency_switched(frequency: float)

## Resonance operation modes
enum ResonanceMode {
	CONSTRUCTIVE = 0,  ## Amplify objects with matching frequency
	DESTRUCTIVE = 1    ## Cancel objects with inverted frequency
}

## Controller hands
enum ControllerHand {
	LEFT = 0,
	RIGHT = 1,
	DOMINANT = 2  ## Use whichever hand is configured as dominant
}

## References
var resonance_system: ResonanceSystem = null
var vr_manager: VRManager = null
var haptic_manager: HapticManager = null
var xr_camera: XRCamera3D = null

## Input configuration
@export var dominant_hand: ControllerHand = ControllerHand.RIGHT
@export var scan_button: String = "trigger"  ## Primary trigger (index finger)
@export var mode_toggle_button: String = "grip"  ## Secondary trigger (middle finger)
@export var emit_button: String = "ax_button"  ## A/X button
@export var quick_switch_button: String = "by_button"  ## B/Y button
@export var hud_button: String = "menu_button"  ## Menu button for HUD toggle

## Input settings
@export var scan_hold_time: float = 0.5  ## Seconds to hold for scan
@export var emission_cooldown: float = 0.2  ## Seconds between emissions
@export var max_recent_frequencies: int = 5  ## Number of frequencies to remember
@export var aim_assist_distance: float = 10.0  ## Max distance for object targeting
@export var aim_assist_angle: float = 15.0  ## Degrees for aim assist cone

## State management
var current_mode: ResonanceMode = ResonanceMode.CONSTRUCTIVE
var is_scanning: bool = false
var scan_start_time: float = 0.0
var last_emission_time: float = 0.0
var recent_frequencies: Array[float] = []
var current_target_object: Node3D = null
var hud_overlay_visible: bool = false

## Input tracking
var _pressed_buttons: Dictionary = {}
var _controller_states: Dictionary = {}
var _hand_tracking_active: bool = false

## Raycasting for object targeting
var _aim_raycast: RayCast3D = null


func _ready() -> void:
	# Create aim raycast for object targeting
	_setup_aim_raycast()
	
	# Find required systems
	_find_references()
	
	# Initialize input state
	_reset_input_state()


func _setup_aim_raycast() -> void:
	"""Create raycast for aiming at objects."""
	_aim_raycast = RayCast3D.new()
	_aim_raycast.name = "ResonanceAimRaycast"
	_aim_raycast.enabled = true
	_aim_raycast.collide_with_areas = true
	_aim_raycast.collide_with_bodies = true
	_aim_raycast.target_position = Vector3(0, 0, -aim_assist_distance)
	add_child(_aim_raycast)


func _find_references() -> void:
	"""Find references to required systems."""
	# Find VR manager
	var engine_node = get_node_or_null("/root/ResonanceEngine")
	if engine_node and engine_node.has_method("get_vr_manager"):
		vr_manager = engine_node.get_vr_manager()
	
	if vr_manager == null:
		vr_manager = _find_node_of_type("VRManager")
	
	# Find XR camera
	if vr_manager:
		xr_camera = vr_manager.get_xr_camera()
	
	# Find haptic manager
	if engine_node and engine_node.has_method("get_haptic_manager"):
		haptic_manager = engine_node.get_haptic_manager()
	
	if haptic_manager == null:
		haptic_manager = _find_node_of_type("HapticManager")
	
	# Find resonance system
	resonance_system = _find_node_of_type("ResonanceSystem")
	
	# Connect to VR manager signals
	if vr_manager:
		if vr_manager.has_signal("vr_initialized"):
			vr_manager.vr_initialized.connect(_on_vr_initialized)
		if vr_manager.has_signal("controller_button_pressed"):
			vr_manager.controller_button_pressed.connect(_on_controller_button_pressed)
		if vr_manager.has_signal("controller_button_released"):
			vr_manager.controller_button_released.connect(_on_controller_button_released)
		if vr_manager.has_signal("hand_tracking_updated"):
			vr_manager.hand_tracking_updated.connect(_on_hand_tracking_updated)


func _find_node_of_type(type_name: String) -> Node:
	"""Find a node of a specific type in the scene tree."""
	var root := get_tree().root
	return _recursive_find_type(root, type_name)


func _recursive_find_type(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name or (node.has_method("get_class") and node.get_class() == type_name):
		return node
	
	# Check script class name
	if node.get_script() != null:
		var script = node.get_script()
		if script.has_method("get_global_name"):
			if script.get_global_name() == type_name:
				return node
	
	# Check by class_name for custom classes
	if node is ResonanceSystem and type_name == "ResonanceSystem":
		return node
	if node is VRManager and type_name == "VRManager":
		return node
	if node is HapticManager and type_name == "HapticManager":
		return node
	
	for child in node.get_children():
		var result := _recursive_find_type(child, type_name)
		if result != null:
			return result
	return null


func _process(delta: float) -> void:
	"""Process input every frame."""
	if vr_manager == null or not vr_manager.is_vr_active():
		return
	
	# Update controller states
	_update_controller_states()
	
	# Process scanning
	_process_scanning(delta)
	
	# Update aim raycast position
	_update_aim_raycast()
	
	# Process continuous input
	_process_continuous_input()


func _update_controller_states() -> void:
	"""Update current controller states."""
	if vr_manager:
		_controller_states["left"] = vr_manager.get_controller_state("left")
		_controller_states["right"] = vr_manager.get_controller_state("right")


func _update_aim_raycast() -> void:
	"""Update aim raycast based on controller or hand position."""
	var aim_transform: Transform3D
	
	# Use controller or hand position for aiming
	if _hand_tracking_active:
		# Use index finger tip position for hand tracking
		aim_transform = _get_hand_aim_transform()
	else:
		# Use controller position
		aim_transform = _get_controller_aim_transform()
	
	if aim_transform:
		# Position raycast at aim origin
		_aim_raycast.global_transform = aim_transform


func _get_controller_aim_transform() -> Transform3D:
	"""Get aim transform from dominant hand controller."""
	var hand_name: String = _get_dominant_hand_name()
	var controller_state = _controller_states.get(hand_name, {})
	
	if controller_state.is_empty():
		return Transform3D.IDENTITY
	
	# Get controller position and rotation
	var pos: Vector3 = controller_state.get("position", Vector3.ZERO)
	var rot: Quaternion = controller_state.get("rotation", Quaternion.IDENTITY)
	
	# Create transform with forward direction
	var transform = Transform3D(rot, pos)
	return transform


func _get_hand_aim_transform() -> Transform3D:
	"""Get aim transform from hand tracking."""
	# This would integrate with hand tracking data
	# For now, fall back to controller
	return _get_controller_aim_transform()


func _get_dominant_hand_name() -> String:
	"""Get the name of the dominant hand."""
	match dominant_hand:
		ControllerHand.LEFT:
			return "left"
		ControllerHand.RIGHT:
			return "right"
		ControllerHand.DOMINANT:
			# Could be configured in settings
			return "right"
		_:
			return "right"


func _process_scanning(delta: float) -> void:
	"""Process object scanning input."""
	var hand_name: String = _get_dominant_hand_name()
	var controller_state = _controller_states.get(hand_name, {})
	
	if controller_state.is_empty():
		return
	
	# Check if scan button is pressed
	var scan_pressed: bool = controller_state.get(scan_button, false)
	var scan_key: String = hand_name + "_" + scan_button
	
	if scan_pressed and not _pressed_buttons.get(scan_key, false):
		# Button just pressed - start scanning
		_pressed_buttons[scan_key] = true
		is_scanning = true
		scan_start_time = Time.get_ticks_msec() / 1000.0
		
		# Haptic feedback for scan start
		_trigger_haptic(hand_name, HapticManagerScript.HapticIntensity.LIGHT, HapticManagerScript.DURATION_SHORT)
		
	elif scan_pressed and _pressed_buttons.get(scan_key, false):
		# Button held - check if scan complete
		if is_scanning:
			var hold_time: float = (Time.get_ticks_msec() / 1000.0) - scan_start_time
			if hold_time >= scan_hold_time:
				_complete_scan()
				is_scanning = false
	
	elif not scan_pressed and _pressed_buttons.get(scan_key, false):
		# Button released - cancel scan if not complete
		_pressed_buttons[scan_key] = false
		if is_scanning:
			is_scanning = false
			_trigger_haptic(hand_name, HapticManagerScript.HapticIntensity.SUBTLE, HapticManagerScript.DURATION_INSTANT)


func _complete_scan() -> void:
	"""Complete the scanning of a targeted object."""
	var target_object: Node3D = _get_target_object()
	
	if target_object == null:
		_log_debug("No object to scan")
		return
	
	if resonance_system == null:
		_log_error("Resonance system not available")
		return
	
	# Scan the object
	var frequency: float = resonance_system.scan_object(target_object)
	
	if frequency > 0.0:
		# Add to recent frequencies
		_add_recent_frequency(frequency)
		
		# Update current target
		current_target_object = target_object
		
		# Haptic feedback for successful scan
		var hand_name: String = _get_dominant_hand_name()
		_trigger_haptic(hand_name, HapticManagerScript.HapticIntensity.MEDIUM, HapticManagerScript.DURATION_MEDIUM)
		
		# Emit signal
		object_scanned.emit(target_object, frequency)
		
		_log_debug("Scanned object: %s at %.2f Hz" % [target_object.name, frequency])


func _get_target_object() -> Node3D:
	"""Get the object currently being aimed at."""
	if _aim_raycast == null or not _aim_raycast.is_colliding():
		return null
	
	var collider = _aim_raycast.get_collider()
	if collider is Node3D:
		return collider
	
	return null


func _add_recent_frequency(frequency: float) -> void:
	"""Add a frequency to the recent frequencies list."""
	# Remove if already exists (to update position)
	recent_frequencies.erase(frequency)
	
	# Add to beginning
	recent_frequencies.insert(0, frequency)
	
	# Limit size
	if recent_frequencies.size() > max_recent_frequencies:
		recent_frequencies.resize(max_recent_frequencies)


func _process_continuous_input() -> void:
	"""Process continuous input like emission and mode toggles."""
	var current_time: float = Time.get_ticks_msec() / 1000.0
	
	# Check emission cooldown
	if current_time - last_emission_time < emission_cooldown:
		return
	
	var hand_name: String = _get_dominant_hand_name()
	var controller_state = _controller_states.get(hand_name, {})
	
	if controller_state.is_empty():
		return
	
	# Process mode toggle (grip button)
	var mode_pressed: bool = controller_state.get(mode_toggle_button, false)
	var mode_key: String = hand_name + "_" + mode_toggle_button
	
	if mode_pressed and not _pressed_buttons.get(mode_key, false):
		_pressed_buttons[mode_key] = true
		_toggle_resonance_mode()
		_trigger_haptic(hand_name, HapticManagerScript.HapticIntensity.LIGHT, HapticManagerScript.DURATION_SHORT)
		
	elif not mode_pressed and _pressed_buttons.get(mode_key, false):
		_pressed_buttons[mode_key] = false
	
	# Process frequency emission (A/X button)
	var emit_pressed: bool = controller_state.get(emit_button, false)
	var emit_key: String = hand_name + "_" + emit_button
	
	if emit_pressed and not _pressed_buttons.get(emit_key, false):
		_pressed_buttons[emit_key] = true
		_emit_frequency()
		last_emission_time = current_time
		
	elif not emit_pressed and _pressed_buttons.get(emit_key, false):
		_pressed_buttons[emit_key] = false
		_stop_emission()
	
	# Process quick-switch (B/Y button)
	var switch_pressed: bool = controller_state.get(quick_switch_button, false)
	var switch_key: String = hand_name + "_" + quick_switch_button
	
	if switch_pressed and not _pressed_buttons.get(switch_key, false):
		_pressed_buttons[switch_key] = true
		_quick_switch_frequency()
		_trigger_haptic(hand_name, HapticManagerScript.HapticIntensity.LIGHT, HapticManagerScript.DURATION_SHORT)
		
	elif not switch_pressed and _pressed_buttons.get(switch_key, false):
		_pressed_buttons[switch_key] = false


func _toggle_resonance_mode() -> void:
	"""Toggle between constructive and destructive interference modes."""
	if current_mode == ResonanceMode.CONSTRUCTIVE:
		current_mode = ResonanceMode.DESTRUCTIVE
	else:
		current_mode = ResonanceMode.CONSTRUCTIVE
	
	mode_changed.emit(_get_mode_name())
	_log_debug("Resonance mode changed to: %s" % _get_mode_name())


func _get_mode_name() -> String:
	"""Get the name of the current resonance mode."""
	match current_mode:
		ResonanceMode.CONSTRUCTIVE:
			return "constructive"
		ResonanceMode.DESTRUCTIVE:
			return "destructive"
		_:
			return "unknown"


func _emit_frequency() -> void:
	"""Emit frequency based on current target and mode."""
	if resonance_system == null:
		_log_error("Resonance system not available")
		return
	
	if current_target_object == null or not is_instance_valid(current_target_object):
		_log_debug("No target object for emission")
		return
	
	var target_frequency: float = resonance_system.get_object_frequency(current_target_object)
	
	if target_frequency <= 0.0:
		_log_debug("No valid frequency for target object")
		return
	
	var hand_name: String = _get_dominant_hand_name()
	
	# Emit based on current mode
	if current_mode == ResonanceMode.CONSTRUCTIVE:
		resonance_system.emit_matching_frequency(target_frequency)
		_trigger_haptic(hand_name, HapticManagerScript.HapticIntensity.MEDIUM, HapticManagerScript.DURATION_LONG)
		_log_debug("Emitting constructive frequency: %.2f Hz" % target_frequency)
	else:
		resonance_system.emit_inverted_frequency(target_frequency)
		_trigger_haptic(hand_name, HapticManagerScript.HapticIntensity.STRONG, HapticManagerScript.DURATION_LONG)
		_log_debug("Emitting destructive frequency: %.2f Hz" % target_frequency)
	
	frequency_emitted.emit(target_frequency, _get_mode_name())


func _stop_emission() -> void:
	"""Stop frequency emission."""
	if resonance_system == null:
		return
	
	resonance_system.stop_emission()
	emission_stopped.emit()
	_log_debug("Emission stopped")


func _quick_switch_frequency() -> void:
	"""Quick-switch to a recently scanned frequency."""
	if recent_frequencies.is_empty():
		_log_debug("No recent frequencies to switch to")
		return
	
	# Cycle through recent frequencies
	var next_frequency: float = recent_frequencies[0]
	recent_frequencies.remove_at(0)
	recent_frequencies.append(next_frequency)
	
	# Find object with this frequency (if still valid)
	var target_object: Node3D = _find_object_by_frequency(next_frequency)
	
	if target_object != null:
		current_target_object = target_object
		frequency_switched.emit(next_frequency)
		_log_debug("Switched to frequency: %.2f Hz (object: %s)" % [next_frequency, target_object.name])
	else:
		_log_debug("Switched to frequency: %.2f Hz (object no longer valid)" % next_frequency)


func _find_object_by_frequency(frequency: float) -> Node3D:
	"""Find an object with the given frequency."""
	if resonance_system == null:
		return null
	
	var tracked_objects: Array[Node3D] = resonance_system.get_tracked_objects()
	
	for obj in tracked_objects:
		if is_instance_valid(obj):
			var obj_freq: float = resonance_system.get_object_frequency(obj)
			if abs(obj_freq - frequency) < 0.01:  # Tolerance for floating point
				return obj
	
	return null


func _on_controller_button_pressed(hand: String, button: String) -> void:
	"""Handle controller button press events."""
	# This is handled in _process, but we can add additional logic here
	pass


func _on_controller_button_released(hand: String, button: String) -> void:
	"""Handle controller button release events."""
	# This is handled in _process, but we can add additional logic here
	pass


func _on_hand_tracking_updated(hand: String, tracking_data: Dictionary) -> void:
	"""Handle hand tracking updates."""
	_hand_tracking_active = true
	# Process hand gestures here
	_process_hand_gestures(hand, tracking_data)


func _process_hand_gestures(hand: String, tracking_data: Dictionary) -> void:
	"""Process hand tracking gestures for resonance control."""
	# Pinch gesture for scanning
	var pinch_strength: float = tracking_data.get("pinch_strength", 0.0)
	
	if pinch_strength > 0.8:
		if not is_scanning:
			is_scanning = true
			scan_start_time = Time.get_ticks_msec() / 1000.0
	else:
		if is_scanning:
			var hold_time: float = (Time.get_ticks_msec() / 1000.0) - scan_start_time
			if hold_time >= scan_hold_time:
				_complete_scan()
			is_scanning = false
	
	# Push gesture for emission
	var push_strength: float = tracking_data.get("push_strength", 0.0)
	if push_strength > 0.7:
		_emit_frequency()


func _on_vr_initialized() -> void:
	"""Handle VR initialization."""
	_log_info("VR initialized for resonance input")
	_reset_input_state()


func _trigger_haptic(hand: String, intensity: HapticManagerScript.HapticIntensity, duration: float) -> void:
	"""Trigger haptic feedback on specified hand."""
	if haptic_manager == null:
		return
	
	var intensity_value: float = _get_haptic_intensity_value(intensity)
	haptic_manager.trigger_haptic(hand, intensity_value, duration)


func _get_haptic_intensity_value(intensity: HapticManagerScript.HapticIntensity) -> float:
	"""Convert haptic intensity enum to float value."""
	match intensity:
		HapticManagerScript.HapticIntensity.SUBTLE:
			return 0.2
		HapticManagerScript.HapticIntensity.LIGHT:
			return 0.4
		HapticManagerScript.HapticIntensity.MEDIUM:
			return 0.6
		HapticManagerScript.HapticIntensity.STRONG:
			return 0.8
		HapticManagerScript.HapticIntensity.VERY_STRONG:
			return 1.0
		_:
			return 0.5


func _reset_input_state() -> void:
	"""Reset all input state."""
	is_scanning = false
	scan_start_time = 0.0
	last_emission_time = 0.0
	_pressed_buttons.clear()


## Public API

func set_resonance_system(system: ResonanceSystem) -> void:
	"""Set the resonance system to control."""
	resonance_system = system


func set_dominant_hand(hand: ControllerHand) -> void:
	"""Set the dominant hand for controls."""
	dominant_hand = hand


func get_current_mode() -> ResonanceMode:
	"""Get the current resonance mode."""
	return current_mode


func get_recent_frequencies() -> Array[float]:
	"""Get the list of recently scanned frequencies."""
	return recent_frequencies.duplicate()


func get_current_target() -> Node3D:
	"""Get the current target object."""
	return current_target_object


func is_hud_overlay_visible() -> bool:
	"""Check if the resonance HUD overlay is visible."""
	return hud_overlay_visible


func set_hud_overlay_visible(visible: bool) -> void:
	"""Show or hide the resonance HUD overlay."""
	hud_overlay_visible = visible


func clear_recent_frequencies() -> void:
	"""Clear the recent frequencies list."""
	recent_frequencies.clear()


func get_input_state() -> Dictionary:
	"""Get current input state for debugging."""
	return {
		"current_mode": _get_mode_name(),
		"is_scanning": is_scanning,
		"current_target": current_target_object,
		"recent_frequencies": recent_frequencies,
		"hud_visible": hud_overlay_visible,
		"hand_tracking_active": _hand_tracking_active
	}


## Logging helpers

func _log_debug(message: String) -> void:
	var engine := get_node_or_null("/root/ResonanceEngine")
	if engine != null and engine.has_method("log_debug"):
		engine.log_debug("[ResonanceInputController] " + message)
	else:
		print("[DEBUG] [ResonanceInputController] " + message)


func _log_info(message: String) -> void:
	var engine := get_node_or_null("/root/ResonanceEngine")
	if engine != null and engine.has_method("log_info"):
		engine.log_info("[ResonanceInputController] " + message)
	else:
		print("[INFO] [ResonanceInputController] " + message)


func _log_warning(message: String) -> void:
	var engine := get_node_or_null("/root/ResonanceEngine")
	if engine != null and engine.has_method("log_warning"):
		engine.log_warning("[ResonanceInputController] " + message)
	else:
		push_warning("[ResonanceInputController] " + message)


func _log_error(message: String) -> void:
	var engine := get_node_or_null("/root/ResonanceEngine")
	if engine != null and engine.has_method("log_error"):
		engine.log_error("[ResonanceInputController] " + message)
	else:
		push_error("[ResonanceInputController] " + message)