extends Node

## Example: Using AccessibilityManager in Project Resonance
##
## This example demonstrates how to integrate and use the AccessibilityManager
## in various game scenarios.

var accessibility_manager: Node = null

func _ready() -> void:
	# Get reference to AccessibilityManager
	# In the actual game, this would be an autoload
	accessibility_manager = get_node_or_null("/root/AccessibilityManager")
	
	if not accessibility_manager:
		print("AccessibilityManager not found - creating instance for example")
		accessibility_manager = load("res://scripts/ui/accessibility.gd").new()
		add_child(accessibility_manager)
	
	# Connect to signals
	_connect_signals()
	
	# Run examples
	example_colorblind_modes()
	example_subtitles()
	example_control_remapping()
	example_motion_sensitivity()
	example_settings_integration()

func _connect_signals() -> void:
	"""Connect to AccessibilityManager signals."""
	accessibility_manager.colorblind_mode_changed.connect(_on_colorblind_mode_changed)
	accessibility_manager.subtitles_toggled.connect(_on_subtitles_toggled)
	accessibility_manager.subtitle_displayed.connect(_on_subtitle_displayed)
	accessibility_manager.control_remapped.connect(_on_control_remapped)
	accessibility_manager.motion_sensitivity_changed.connect(_on_motion_sensitivity_changed)

#region Example 1: Colorblind Modes

func example_colorblind_modes() -> void:
	"""Example: Setting and using colorblind modes."""
	print("\n=== Example 1: Colorblind Modes ===\n")
	
	# Set colorblind mode via string (useful for UI dropdowns)
	print("Setting colorblind mode to Protanopia...")
	accessibility_manager.set_colorblind_mode_from_string("Protanopia")
	
	# Get current mode
	var current_mode = accessibility_manager.get_colorblind_mode_string()
	print("Current mode: %s" % current_mode)
	
	# Transform a color for display
	var original_color = Color(1.0, 0.0, 0.0)  # Red
	print("Original color: %s" % original_color)
	
	# In actual use, colors are automatically transformed by the system
	# This is just to demonstrate the transformation
	var matrix = accessibility_manager.colorblind_matrices.get(1)  # PROTANOPIA
	if matrix:
		var transformed = accessibility_manager._transform_color(original_color, matrix)
		print("Transformed color: %s" % transformed)

#endregion

#region Example 2: Subtitles

func example_subtitles() -> void:
	"""Example: Displaying subtitles for audio cues."""
	print("\n=== Example 2: Subtitles ===\n")
	
	# Enable subtitles
	print("Enabling subtitles...")
	accessibility_manager.set_subtitles_enabled(true)
	
	# Simulate playing an audio cue with subtitle
	print("Playing engine sound with subtitle...")
	play_audio_with_subtitle("engine_thrust", "Engine thrust engaged", 3.0)
	
	# Simulate a warning sound
	await get_tree().create_timer(3.5).timeout
	print("Playing warning sound with subtitle...")
	play_audio_with_subtitle("warning_beep", "[Warning Beep] Low signal strength", 4.0)

func play_audio_with_subtitle(audio_id: String, subtitle_text: String, duration: float) -> void:
	"""Play audio and show subtitle if enabled."""
	# In actual game, this would play the audio:
	# audio_manager.play_sound(audio_id)
	print("  Playing audio: %s" % audio_id)
	
	# Show subtitle if enabled
	if accessibility_manager.are_subtitles_enabled():
		accessibility_manager.display_subtitle(subtitle_text, duration)

#endregion

#region Example 3: Control Remapping

func example_control_remapping() -> void:
	"""Example: Remapping controls."""
	print("\n=== Example 3: Control Remapping ===\n")
	
	# Create a test action
	var test_action = "test_thrust"
	if not InputMap.has_action(test_action):
		InputMap.add_action(test_action)
		print("Created test action: %s" % test_action)
	
	# Show current mapping
	var current_events = accessibility_manager.get_control_mapping(test_action)
	print("Current mapping for '%s': %d events" % [test_action, current_events.size()])
	
	# Remap to a new key
	var new_event = InputEventKey.new()
	new_event.keycode = KEY_T
	print("Remapping '%s' to T key..." % test_action)
	accessibility_manager.remap_control(test_action, new_event)
	
	# Verify new mapping
	var updated_events = accessibility_manager.get_control_mapping(test_action)
	print("Updated mapping: %d events" % updated_events.size())
	if updated_events.size() > 0:
		print("  First event keycode: %d" % updated_events[0].keycode)
	
	# Cleanup
	InputMap.erase_action(test_action)

#endregion

#region Example 4: Motion Sensitivity

func example_motion_sensitivity() -> void:
	"""Example: Reducing motion effects."""
	print("\n=== Example 4: Motion Sensitivity ===\n")
	
	# Enable motion sensitivity reduction
	print("Enabling motion sensitivity reduction...")
	accessibility_manager.set_motion_sensitivity_reduced(true)
	
	# Check status
	if accessibility_manager.is_motion_sensitivity_reduced():
		print("Motion effects are now reduced")
		print("  - Camera shake: 30% intensity")
		print("  - Post-processing: 50% intensity")
		print("  - Animations: 50% speed")
	
	# In actual game, you would apply these reductions:
	# apply_camera_shake_with_sensitivity()
	# apply_post_processing_with_sensitivity()
	# apply_animations_with_sensitivity()

func apply_camera_shake_with_sensitivity() -> void:
	"""Apply camera shake respecting motion sensitivity."""
	var base_intensity = 1.0
	var intensity = base_intensity
	
	if accessibility_manager.is_motion_sensitivity_reduced():
		intensity *= 0.3  # Reduce to 30%
	
	# Apply shake with adjusted intensity
	# camera.apply_shake(intensity)
	print("Applying camera shake with intensity: %.2f" % intensity)

#endregion

#region Example 5: Settings Integration

func example_settings_integration() -> void:
	"""Example: Integrating with settings menu."""
	print("\n=== Example 5: Settings Integration ===\n")
	
	# Get complete accessibility status
	var status = accessibility_manager.get_accessibility_status()
	print("Current accessibility settings:")
	print("  Colorblind Mode: %s" % status.colorblind_mode)
	print("  Subtitles: %s" % ("Enabled" if status.subtitles_enabled else "Disabled"))
	print("  Motion Reduction: %s" % ("Enabled" if status.motion_sensitivity_reduced else "Disabled"))
	
	# Simulate settings menu UI
	print("\nSimulating settings menu changes...")
	
	# User selects Deuteranopia from dropdown
	print("User selects Deuteranopia...")
	accessibility_manager.set_colorblind_mode_from_string("Deuteranopia")
	
	# User toggles subtitles
	print("User toggles subtitles...")
	accessibility_manager.set_subtitles_enabled(false)
	
	# User enables motion reduction
	print("User enables motion reduction...")
	accessibility_manager.set_motion_sensitivity_reduced(true)
	
	# Show updated status
	status = accessibility_manager.get_accessibility_status()
	print("\nUpdated accessibility settings:")
	print("  Colorblind Mode: %s" % status.colorblind_mode)
	print("  Subtitles: %s" % ("Enabled" if status.subtitles_enabled else "Disabled"))
	print("  Motion Reduction: %s" % ("Enabled" if status.motion_sensitivity_reduced else "Disabled"))

#endregion

#region Signal Handlers

func _on_colorblind_mode_changed(mode: String) -> void:
	"""Handle colorblind mode change."""
	print("[Signal] Colorblind mode changed to: %s" % mode)

func _on_subtitles_toggled(enabled: bool) -> void:
	"""Handle subtitles toggle."""
	print("[Signal] Subtitles %s" % ("enabled" if enabled else "disabled"))

func _on_subtitle_displayed(text: String, duration: float) -> void:
	"""Handle subtitle display."""
	print("[Signal] Subtitle displayed: '%s' for %.1fs" % [text, duration])

func _on_control_remapped(action: String, event: InputEvent) -> void:
	"""Handle control remapping."""
	print("[Signal] Control remapped: %s" % action)

func _on_motion_sensitivity_changed(reduced: bool) -> void:
	"""Handle motion sensitivity change."""
	print("[Signal] Motion sensitivity %s" % ("reduced" if reduced else "normal"))

#endregion
