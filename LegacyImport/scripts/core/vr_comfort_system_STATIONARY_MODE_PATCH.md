## =================================================================
## VRComfortSystem - Stationary Mode Integration Patch
## =================================================================
## This file contains the complete stationary mode implementation
## that integrates with FloatingOriginSystem.
##
## CHANGES REQUIRED TO C:/godot/scripts/core/vr_comfort_system.gd:
## =================================================================

## 1. ADD NEW CLASS VARIABLE (after line 26):
##    var floating_origin_system: FloatingOriginSystem = null

## 2. REPLACE STATIONARY MODE STATE VARIABLES (replace line 37):
##    OLD: var _universe_offset: Vector3 = Vector3.ZERO
##    NEW: var _stationary_player_position: Vector3 = Vector3.ZERO
##    ADD: var _stationary_player_velocity: Vector3 = Vector3.ZERO

## 3. UPDATE initialize() FUNCTION (add after line 72, before line 73):
# Get FloatingOriginSystem reference from ResonanceEngine
var resonance_engine = get_node_or_null("/root/ResonanceEngine")
if resonance_engine:
	floating_origin_system = resonance_engine.get_node_or_null("FloatingOriginSystem")
	if floating_origin_system == null:
		push_warning("VRComfortSystem: FloatingOriginSystem not found - stationary mode will be limited")
else:
	push_warning("VRComfortSystem: ResonanceEngine not found - stationary mode will be limited")

## 4. ADD NEW _physics_process() FUNCTION (add after _process() function, around line 136):
## Physics process for stationary mode updates
func _physics_process(delta: float) -> void:
	if not _initialized or not _stationary_mode_active:
		return

	# Handle stationary mode: keep player locked, move universe instead
	if spacecraft and spacecraft is RigidBody3D:
		_update_stationary_mode(delta)

## 5. ADD NEW _update_stationary_mode() FUNCTION (add after _physics_process()):
## Update stationary mode - inverse player movement to universe movement
func _update_stationary_mode(delta: float) -> void:
	if not spacecraft or not floating_origin_system:
		return

	var player_body := spacecraft as RigidBody3D

	# Get the player's current position
	var current_position := player_body.global_position

	# Calculate how much the player has moved since last frame
	var movement_delta := current_position - _stationary_player_position

	# If player has moved significantly, trigger inverse rebasing
	if movement_delta.length() > 0.001:
		# Instead of letting the player move, we move the universe in the opposite direction
		# This is achieved by forcing a rebase with the negative movement delta
		floating_origin_system.rebase_coordinates(movement_delta)

		# Keep the player locked at their stationary position
		player_body.global_position = _stationary_player_position

		# Preserve the player's velocity for smooth physics continuation
		# (velocities are relative, so they don't need adjustment)
		# The floating origin system handles velocity preservation

## 6. REPLACE set_stationary_mode() FUNCTION (lines 307-331):
## Toggle or set stationary mode
## @param enabled: true to enable stationary mode, false to disable
func set_stationary_mode(enabled: bool) -> void:
	if _stationary_mode_active == enabled:
		return

	_stationary_mode_active = enabled

	if enabled:
		# Enable stationary mode - freeze player position, move universe instead
		if spacecraft and spacecraft is RigidBody3D:
			var player_body := spacecraft as RigidBody3D

			# Store the current player position as the "locked" position
			_stationary_player_position = player_body.global_position
			_stationary_player_velocity = player_body.linear_velocity

			# Verify FloatingOriginSystem is available
			if floating_origin_system == null:
				push_warning("VRComfortSystem: Stationary mode enabled but FloatingOriginSystem not available!")
				push_warning("VRComfortSystem: Player movement will not be properly compensated.")

			print("VRComfortSystem: Stationary mode ENABLED")
			print("  - Player locked at position: %s" % _stationary_player_position)
			print("  - Universe will move inversely to compensate for any player movement")
			print("  - FloatingOriginSystem integration: %s" % ("ACTIVE" if floating_origin_system else "UNAVAILABLE"))
	else:
		# Disable stationary mode - return to normal movement
		print("VRComfortSystem: Stationary mode DISABLED - normal movement restored")
		_stationary_player_position = Vector3.ZERO
		_stationary_player_velocity = Vector3.ZERO

	# Update setting if settings manager available
	if settings_manager:
		settings_manager.set_setting("vr", "stationary_mode", enabled)

	# Emit signal
	stationary_mode_changed.emit(enabled)

## 7. UPDATE set_spacecraft() FUNCTION (add at end, before final brace, around line 349):
	# If stationary mode is active and spacecraft changed, update locked position
	if _stationary_mode_active and spacecraft and spacecraft is RigidBody3D:
		var player_body := spacecraft as RigidBody3D
		_stationary_player_position = player_body.global_position
		_stationary_player_velocity = player_body.linear_velocity

## =================================================================
## HOW IT WORKS
## =================================================================
##
## Stationary Mode prevents VR motion sickness by keeping the player
## physically locked in place while moving the entire universe instead.
##
## INTEGRATION WITH FloatingOriginSystem:
##
## 1. When stationary mode is enabled:
##    - Store the player's current global_position as the "locked" position
##    - This becomes the reference point that never changes
##
## 2. Every physics frame (_physics_process):
##    - Check if the player has moved from the locked position
##    - Calculate movement_delta = current_position - locked_position
##    - If movement detected:
##      a) Call floating_origin_system.rebase_coordinates(movement_delta)
##         This moves ALL universe objects by -movement_delta
##      b) Snap player back to locked_position
##      c) FloatingOriginSystem preserves physics velocities automatically
##
## 3. Result:
##    - Player stays at the same position in world space
##    - Universe moves around the player instead
##    - Physics still works correctly (velocities relative)
##    - No motion sickness from VR locomotion
##
## EXAMPLE:
## - Player at position (0, 0, 0) enables stationary mode
## - Spacecraft thrusts forward, would move to (10, 0, 0)
## - Instead: Universe rebases by (-10, 0, 0)
## - All stars, planets, objects move backward by 10 units
## - Player stays at (0, 0, 0) - no VR movement
## - From player's perspective: They moved forward
## - Reality: Universe moved backward around them
##
## This is the "treadmill" approach to VR locomotion - extremely
## effective at preventing motion sickness while preserving gameplay.
##
## =================================================================
## TESTING
## =================================================================
##
## To test stationary mode:
##
## 1. Enable stationary mode:
##    var vr_comfort = get_node("/root/ResonanceEngine/VRComfortSystem")
##    vr_comfort.set_stationary_mode(true)
##
## 2. Move spacecraft with thrust controls
##
## 3. Verify:
##    - Player position stays constant
##    - Universe objects move inversely
##    - No VR headset movement
##    - Physics still works (collisions, etc.)
##
## 4. Check telemetry:
##    curl http://127.0.0.1:8080/debug/getPosition
##    # Should show constant player position
##
## 5. Monitor rebasing:
##    # FloatingOriginSystem emits rebasing_completed signal
##    # Should trigger every frame player would move
##
## =================================================================
