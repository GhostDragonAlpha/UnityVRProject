extends Node
class_name ControllerModeManager

## Controller Mode Manager
## Handles switching between VR Player mode and AI Training mode
## Prevents physics interference with VR tracking

enum ControllerMode {
	VR_PLAYER,      ## Human player controls via VR tracking
	AI_TRAINING,    ## RL agent controls character with physics
	HYBRID          ## Experimental: VR observation + AI actions
}

## Current active controller mode
var current_mode: ControllerMode = ControllerMode.VR_PLAYER

## Reference to VR main scene (set externally)
var vr_main: Node3D = null

## Reference to AI controller (if available)
var ai_controller: Node = null

## Signal emitted when mode changes
signal mode_changed(old_mode: ControllerMode, new_mode: ControllerMode)

## Signal emitted when mode switch fails
signal mode_switch_failed(requested_mode: ControllerMode, reason: String)


func _ready():
	print("[ControllerModeManager] Initialized")


## Switch to a different controller mode
func switch_mode(new_mode: ControllerMode) -> bool:
	if new_mode == current_mode:
		print("[ControllerModeManager] Already in mode: ", _mode_name(new_mode))
		return true

	var old_mode = current_mode
	print("[ControllerModeManager] Switching from ", _mode_name(old_mode), " to ", _mode_name(new_mode))

	# Validate mode switch
	if not _can_switch_to_mode(new_mode):
		var reason = _get_switch_failure_reason(new_mode)
		push_error("[ControllerModeManager] Cannot switch to ", _mode_name(new_mode), ": ", reason)
		mode_switch_failed.emit(new_mode, reason)
		return false

	# Disable old mode
	_disable_mode(old_mode)

	# Enable new mode
	_enable_mode(new_mode)

	# Update current mode
	current_mode = new_mode

	print("[ControllerModeManager] Mode switched successfully to: ", _mode_name(new_mode))
	mode_changed.emit(old_mode, new_mode)

	return true


## Check if we can switch to the requested mode
func _can_switch_to_mode(mode: ControllerMode) -> bool:
	match mode:
		ControllerMode.VR_PLAYER:
			# Can always switch to VR mode
			return true

		ControllerMode.AI_TRAINING:
			# Requires AI controller to be available
			return is_instance_valid(ai_controller)

		ControllerMode.HYBRID:
			# Requires both VR and AI controller
			return is_instance_valid(vr_main) and is_instance_valid(ai_controller)

	return false


## Get reason why mode switch would fail
func _get_switch_failure_reason(mode: ControllerMode) -> String:
	match mode:
		ControllerMode.AI_TRAINING:
			if not is_instance_valid(ai_controller):
				return "AI controller not available"

		ControllerMode.HYBRID:
			if not is_instance_valid(vr_main):
				return "VR main scene not available"
			if not is_instance_valid(ai_controller):
				return "AI controller not available"

	return "Unknown reason"


## Disable the specified mode
func _disable_mode(mode: ControllerMode):
	match mode:
		ControllerMode.VR_PLAYER:
			_disable_vr_player_mode()

		ControllerMode.AI_TRAINING:
			_disable_ai_training_mode()

		ControllerMode.HYBRID:
			_disable_hybrid_mode()


## Enable the specified mode
func _enable_mode(mode: ControllerMode):
	match mode:
		ControllerMode.VR_PLAYER:
			_enable_vr_player_mode()

		ControllerMode.AI_TRAINING:
			_enable_ai_training_mode()

		ControllerMode.HYBRID:
			_enable_hybrid_mode()


## Enable VR Player mode: VR tracking + physics for gameplay, AI disabled
func _enable_vr_player_mode():
	print("[ControllerModeManager] Enabling VR Player mode")

	if is_instance_valid(vr_main):
		# KEEP physics enabled for walking, collisions, grabbing
		# The key is that the CharacterBody3D should follow the XROrigin3D
		# not override it with move_and_slide()
		if vr_main.has_method("set_physics_movement_enabled"):
			vr_main.set_physics_movement_enabled(true)
			print("[ControllerModeManager] Physics movement enabled (follows VR tracking)")
		else:
			vr_main.set("physics_movement_enabled", true)

		# Enable local gravity for ground detection (not N-body orbital gravity)
		vr_main.set("gravity_enabled", false)  # Disable N-body gravity
		print("[ControllerModeManager] N-body gravity disabled (using local ground gravity)")

	# Disable AI controller - player has full control
	if is_instance_valid(ai_controller):
		if ai_controller.has_method("set_enabled"):
			ai_controller.set_enabled(false)
			print("[ControllerModeManager] AI controller disabled")


func _disable_vr_player_mode():
	print("[ControllerModeManager] Disabling VR Player mode")
	# VR tracking always stays active, just allow physics to take over


## Enable AI Training mode: RL agent controls character with physics
func _enable_ai_training_mode():
	print("[ControllerModeManager] Enabling AI Training mode")

	if is_instance_valid(vr_main):
		# Enable physics movement for AI control
		if vr_main.has_method("set_physics_movement_enabled"):
			vr_main.set_physics_movement_enabled(true)
			print("[ControllerModeManager] Physics movement enabled")
		else:
			vr_main.set("physics_movement_enabled", true)

		# Enable gravity simulation for realistic physics
		vr_main.set("gravity_enabled", true)
		print("[ControllerModeManager] Gravity enabled")

	# Enable AI controller
	if is_instance_valid(ai_controller):
		if ai_controller.has_method("set_enabled"):
			ai_controller.set_enabled(true)
			print("[ControllerModeManager] AI controller enabled")

		# Reset AI controller state for new training episode
		if ai_controller.has_method("reset"):
			ai_controller.reset()
			print("[ControllerModeManager] AI controller reset for training")


func _disable_ai_training_mode():
	print("[ControllerModeManager] Disabling AI Training mode")

	if is_instance_valid(ai_controller):
		if ai_controller.has_method("set_enabled"):
			ai_controller.set_enabled(false)


## Enable Hybrid mode: VR observation + AI actions (experimental)
func _enable_hybrid_mode():
	print("[ControllerModeManager] Enabling Hybrid mode (EXPERIMENTAL)")
	push_warning("[ControllerModeManager] Hybrid mode is experimental and may have conflicts")

	# Enable physics for AI actions
	if is_instance_valid(vr_main):
		if vr_main.has_method("set_physics_movement_enabled"):
			vr_main.set_physics_movement_enabled(true)
		else:
			vr_main.set("physics_movement_enabled", true)

		vr_main.set("gravity_enabled", true)

	# Enable AI controller
	if is_instance_valid(ai_controller):
		if ai_controller.has_method("set_enabled"):
			ai_controller.set_enabled(true)

	# Note: VR tracking stays active for observation


func _disable_hybrid_mode():
	print("[ControllerModeManager] Disabling Hybrid mode")
	_disable_ai_training_mode()


## Get human-readable mode name
func _mode_name(mode: ControllerMode) -> String:
	match mode:
		ControllerMode.VR_PLAYER:
			return "VR_PLAYER"
		ControllerMode.AI_TRAINING:
			return "AI_TRAINING"
		ControllerMode.HYBRID:
			return "HYBRID"
	return "UNKNOWN"


## Quick mode switches with validation
func switch_to_vr_player() -> bool:
	return switch_mode(ControllerMode.VR_PLAYER)


func switch_to_ai_training() -> bool:
	return switch_mode(ControllerMode.AI_TRAINING)


func switch_to_hybrid() -> bool:
	return switch_mode(ControllerMode.HYBRID)


## Get current mode as string (for debugging/logging)
func get_current_mode_name() -> String:
	return _mode_name(current_mode)


## Check if currently in VR player mode
func is_vr_player_mode() -> bool:
	return current_mode == ControllerMode.VR_PLAYER


## Check if currently in AI training mode
func is_ai_training_mode() -> bool:
	return current_mode == ControllerMode.AI_TRAINING


## Check if currently in hybrid mode
func is_hybrid_mode() -> bool:
	return current_mode == ControllerMode.HYBRID


## Set VR main scene reference
func set_vr_main(vr_main_node: Node3D):
	vr_main = vr_main_node
	print("[ControllerModeManager] VR main scene registered: ", vr_main.name)


## Set AI controller reference
func set_ai_controller(ai_controller_node: Node):
	ai_controller = ai_controller_node
	print("[ControllerModeManager] AI controller registered: ", ai_controller.name)


## Utility: Print current mode status
func print_status():
	print("[ControllerModeManager] ========== STATUS ==========")
	print("[ControllerModeManager] Current Mode: ", get_current_mode_name())
	print("[ControllerModeManager] VR Main: ", "Valid" if is_instance_valid(vr_main) else "Not Set")
	print("[ControllerModeManager] AI Controller: ", "Valid" if is_instance_valid(ai_controller) else "Not Set")

	if is_instance_valid(vr_main):
		var physics_enabled = vr_main.get("physics_movement_enabled")
		var gravity_enabled = vr_main.get("gravity_enabled")
		print("[ControllerModeManager] Physics Movement: ", "Enabled" if physics_enabled else "Disabled")
		print("[ControllerModeManager] Gravity: ", "Enabled" if gravity_enabled else "Disabled")

	print("[ControllerModeManager] =============================")
