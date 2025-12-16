## AccessibilityManager - Accessibility Options System
##
## Manages accessibility features including colorblind modes, subtitles,
## control remapping, and motion sensitivity reduction.
##
## Requirements: 70.1, 70.2, 70.3, 70.4, 70.5
## - 70.1: Provide colorblind mode options (Protanopia, Deuteranopia, Tritanopia)
## - 70.2: Adjust UI colors when colorblind mode is enabled
## - 70.3: Display subtitles for audio cues
## - 70.4: Allow complete control remapping using InputMap
## - 70.5: Reduce motion effects when sensitivity mode is enabled

extends Node
class_name AccessibilityManager

## Signals
signal colorblind_mode_changed(mode: String)
signal subtitles_toggled(enabled: bool)
signal subtitle_displayed(text: String, duration: float)
signal control_remapped(action: String, event: InputEvent)
signal motion_sensitivity_changed(reduced: bool)

## Colorblind mode types
enum ColorblindMode {
	NONE,
	PROTANOPIA,      # Red-blind
	DEUTERANOPIA,    # Green-blind
	TRITANOPIA       # Blue-blind
}

## Current colorblind mode
var current_colorblind_mode: ColorblindMode = ColorblindMode.NONE

## Subtitles enabled
var subtitles_enabled: bool = false

## Motion sensitivity reduced
var motion_sensitivity_reduced: bool = false

## Subtitle display container
var subtitle_container: Control = null
var subtitle_label: Label = null
var subtitle_timer: Timer = null

## Color transformation matrices for colorblind modes
## Based on Brettel, Viénot and Mollon CVPR 1997
var colorblind_matrices: Dictionary = {
	ColorblindMode.PROTANOPIA: [
		Vector3(0.567, 0.433, 0.0),
		Vector3(0.558, 0.442, 0.0),
		Vector3(0.0, 0.242, 0.758)
	],
	ColorblindMode.DEUTERANOPIA: [
		Vector3(0.625, 0.375, 0.0),
		Vector3(0.7, 0.3, 0.0),
		Vector3(0.0, 0.3, 0.7)
	],
	ColorblindMode.TRITANOPIA: [
		Vector3(0.95, 0.05, 0.0),
		Vector3(0.0, 0.433, 0.567),
		Vector3(0.0, 0.475, 0.525)
	]
}

## Reference to settings manager
var settings_manager = null

## Reference to HUD for color adjustments
var hud = null

## Reference to menu system for color adjustments
var menu_system = null

## Initialize accessibility manager
func _ready() -> void:
	_find_system_references()
	_create_subtitle_ui()
	_load_accessibility_settings()
	_connect_to_settings()
	print("AccessibilityManager initialized")

## Find references to other systems
func _find_system_references() -> void:
	"""Find references to settings manager and UI systems."""
	# Get settings manager
	if has_node("/root/SettingsManager"):
		settings_manager = get_node("/root/SettingsManager")
	
	# Get HUD (may not exist yet)
	var engine_node = get_node_or_null("/root/ResonanceEngine")
	if engine_node and engine_node.has_method("get_hud"):
		hud = engine_node.get_hud()
	
	# Get menu system (may not exist yet)
	if engine_node and engine_node.has_method("get_menu_system"):
		menu_system = engine_node.get_menu_system()

## Create subtitle UI overlay
func _create_subtitle_ui() -> void:
	"""Create subtitle display UI."""
	# Create container
	subtitle_container = Control.new()
	subtitle_container.name = "SubtitleContainer"
	subtitle_container.anchor_left = 0.0
	subtitle_container.anchor_top = 0.8
	subtitle_container.anchor_right = 1.0
	subtitle_container.anchor_bottom = 1.0
	subtitle_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle_container)
	
	# Create background panel
	var panel = Panel.new()
	panel.anchor_left = 0.1
	panel.anchor_top = 0.0
	panel.anchor_right = 0.9
	panel.anchor_bottom = 1.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Create semi-transparent background
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.0, 0.0, 0.0, 0.7)
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(1.0, 1.0, 1.0, 0.3)
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style_box)
	
	subtitle_container.add_child(panel)
	
	# Create label
	subtitle_label = Label.new()
	subtitle_label.name = "SubtitleLabel"
	subtitle_label.anchor_left = 0.0
	subtitle_label.anchor_top = 0.0
	subtitle_label.anchor_right = 1.0
	subtitle_label.anchor_bottom = 1.0
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_font_size_override("font_size", 24)
	subtitle_label.add_theme_color_override("font_color", Color.WHITE)
	subtitle_label.add_theme_color_override("font_outline_color", Color.BLACK)
	subtitle_label.add_theme_constant_override("outline_size", 2)
	panel.add_child(subtitle_label)
	
	# Create timer for auto-hiding subtitles
	subtitle_timer = Timer.new()
	subtitle_timer.name = "SubtitleTimer"
	subtitle_timer.one_shot = true
	subtitle_timer.timeout.connect(_on_subtitle_timeout)
	add_child(subtitle_timer)
	
	# Initially hide subtitles
	subtitle_container.visible = false

## Load accessibility settings from SettingsManager
func _load_accessibility_settings() -> void:
	"""Load accessibility settings from SettingsManager."""
	if not settings_manager:
		return
	
	# Load colorblind mode
	var mode_string = settings_manager.colorblind_mode
	set_colorblind_mode_from_string(mode_string)
	
	# Load subtitles setting
	set_subtitles_enabled(settings_manager.subtitles_enabled)
	
	# Load motion sensitivity setting
	set_motion_sensitivity_reduced(settings_manager.motion_sensitivity_reduced)
	
	print("AccessibilityManager: Loaded settings - Colorblind: %s, Subtitles: %s, Motion: %s" % [
		mode_string, subtitles_enabled, motion_sensitivity_reduced
	])

## Connect to settings manager signals
func _connect_to_settings() -> void:
	"""Connect to settings manager for reactive updates."""
	if not settings_manager:
		return
	
	if not settings_manager.setting_changed.is_connected(_on_setting_changed):
		settings_manager.setting_changed.connect(_on_setting_changed)

#region Colorblind Mode

## Set colorblind mode
## Requirement 70.1: Provide colorblind mode options
func set_colorblind_mode(mode: ColorblindMode) -> void:
	"""Set the colorblind mode."""
	current_colorblind_mode = mode
	
	# Apply color adjustments to UI
	_apply_colorblind_adjustments()
	
	# Update settings manager
	if settings_manager:
		var mode_string = _colorblind_mode_to_string(mode)
		settings_manager.set_colorblind_mode(mode_string)
	
	colorblind_mode_changed.emit(_colorblind_mode_to_string(mode))
	print("AccessibilityManager: Colorblind mode set to %s" % _colorblind_mode_to_string(mode))

## Set colorblind mode from string
func set_colorblind_mode_from_string(mode_string: String) -> void:
	"""Set colorblind mode from string name."""
	match mode_string:
		"Protanopia":
			set_colorblind_mode(ColorblindMode.PROTANOPIA)
		"Deuteranopia":
			set_colorblind_mode(ColorblindMode.DEUTERANOPIA)
		"Tritanopia":
			set_colorblind_mode(ColorblindMode.TRITANOPIA)
		_:
			set_colorblind_mode(ColorblindMode.NONE)

## Convert colorblind mode enum to string
func _colorblind_mode_to_string(mode: ColorblindMode) -> String:
	"""Convert colorblind mode enum to string."""
	match mode:
		ColorblindMode.PROTANOPIA:
			return "Protanopia"
		ColorblindMode.DEUTERANOPIA:
			return "Deuteranopia"
		ColorblindMode.TRITANOPIA:
			return "Tritanopia"
		_:
			return "None"

## Apply colorblind color adjustments to UI
## Requirement 70.2: Adjust UI colors when colorblind mode is enabled
func _apply_colorblind_adjustments() -> void:
	"""Apply color transformations to UI elements based on colorblind mode."""
	if current_colorblind_mode == ColorblindMode.NONE:
		# Reset to default colors
		_reset_ui_colors()
		return
	
	# Get transformation matrix
	var matrix = colorblind_matrices.get(current_colorblind_mode, [])
	if matrix.is_empty():
		return
	
	# Apply to HUD colors
	if hud:
		_apply_colorblind_to_hud(matrix)
	
	# Apply to menu system colors
	if menu_system:
		_apply_colorblind_to_menu(matrix)
	
	print("AccessibilityManager: Applied colorblind adjustments for %s" % _colorblind_mode_to_string(current_colorblind_mode))

## Transform color using colorblind matrix
func _transform_color(color: Color, matrix: Array) -> Color:
	"""Transform a color using the colorblind transformation matrix."""
	if matrix.size() != 3:
		return color
	
	var r = color.r * matrix[0].x + color.g * matrix[0].y + color.b * matrix[0].z
	var g = color.r * matrix[1].x + color.g * matrix[1].y + color.b * matrix[1].z
	var b = color.r * matrix[2].x + color.g * matrix[2].y + color.b * matrix[2].z
	
	return Color(clamp(r, 0.0, 1.0), clamp(g, 0.0, 1.0), clamp(b, 0.0, 1.0), color.a)

## Apply colorblind adjustments to HUD
func _apply_colorblind_to_hud(matrix: Array) -> void:
	"""Apply colorblind color transformations to HUD elements."""
	if not hud:
		return
	
	# Transform HUD colors
	# Note: This is a simplified approach. In a real implementation,
	# you would need to access and modify specific HUD elements
	
	# Example: Transform common HUD colors
	var normal_color = Color(0.0, 1.0, 0.8)  # Cyan
	var warning_color = Color(1.0, 0.8, 0.0)  # Yellow
	var critical_color = Color(1.0, 0.2, 0.2)  # Red
	var good_color = Color(0.2, 1.0, 0.2)  # Green
	
	var transformed_normal = _transform_color(normal_color, matrix)
	var transformed_warning = _transform_color(warning_color, matrix)
	var transformed_critical = _transform_color(critical_color, matrix)
	var transformed_good = _transform_color(good_color, matrix)
	
	# Store transformed colors for HUD to use
	# This would require HUD to have a method to accept new color schemes
	if hud.has_method("set_color_scheme"):
		hud.set_color_scheme({
			"normal": transformed_normal,
			"warning": transformed_warning,
			"critical": transformed_critical,
			"good": transformed_good
		})

## Apply colorblind adjustments to menu system
func _apply_colorblind_to_menu(matrix: Array) -> void:
	"""Apply colorblind color transformations to menu elements."""
	if not menu_system:
		return
	
	# Similar to HUD, transform menu colors
	# This would require menu system to support color scheme changes

## Reset UI colors to defaults
func _reset_ui_colors() -> void:
	"""Reset all UI colors to their default values."""
	if hud and hud.has_method("reset_color_scheme"):
		hud.reset_color_scheme()
	
	if menu_system and menu_system.has_method("reset_color_scheme"):
		menu_system.reset_color_scheme()

#endregion

#region Subtitles

## Set subtitles enabled
## Requirement 70.3: Display subtitles for audio cues
func set_subtitles_enabled(enabled: bool) -> void:
	"""Enable or disable subtitles."""
	subtitles_enabled = enabled
	
	# Update settings manager
	if settings_manager:
		settings_manager.set_subtitles_enabled(enabled)
	
	# Hide subtitle container if disabled
	if not enabled and subtitle_container:
		subtitle_container.visible = false
	
	subtitles_toggled.emit(enabled)
	print("AccessibilityManager: Subtitles %s" % ("enabled" if enabled else "disabled"))

## Display subtitle text
## Requirement 70.3: Display subtitles for audio cues
func display_subtitle(text: String, duration: float = 3.0) -> void:
	"""Display a subtitle for the specified duration."""
	if not subtitles_enabled or not subtitle_label or not subtitle_container:
		return
	
	# Set subtitle text
	subtitle_label.text = text
	
	# Show subtitle container
	subtitle_container.visible = true
	
	# Start timer to hide subtitle
	if subtitle_timer:
		subtitle_timer.start(duration)
	
	subtitle_displayed.emit(text, duration)
	print("AccessibilityManager: Displayed subtitle - '%s' for %.1fs" % [text, duration])

## Hide subtitle
func hide_subtitle() -> void:
	"""Hide the subtitle display."""
	if subtitle_container:
		subtitle_container.visible = false

## Subtitle timer timeout handler
func _on_subtitle_timeout() -> void:
	"""Handle subtitle timer timeout."""
	hide_subtitle()

#endregion

#region Control Remapping

## Remap control action
## Requirement 70.4: Allow complete control remapping using InputMap
func remap_control(action: String, new_event: InputEvent) -> void:
	"""Remap a control action to a new input event."""
	if not InputMap.has_action(action):
		push_error("AccessibilityManager: Action '%s' does not exist in InputMap" % action)
		return
	
	# Remove existing events for this action
	InputMap.action_erase_events(action)
	
	# Add new event
	InputMap.action_add_event(action, new_event)
	
	# Update settings manager
	if settings_manager:
		settings_manager.set_control_mapping(action, new_event)
	
	control_remapped.emit(action, new_event)
	print("AccessibilityManager: Remapped control '%s' to %s" % [action, new_event])

## Get current control mapping
func get_control_mapping(action: String) -> Array[InputEvent]:
	"""Get the current input events for an action."""
	if not InputMap.has_action(action):
		return []
	
	return InputMap.action_get_events(action)

## Reset control mapping to default
func reset_control_mapping(action: String) -> void:
	"""Reset a control action to its default mapping."""
	if not InputMap.has_action(action):
		return
	
	# This would require storing default mappings
	# For now, just clear the action
	InputMap.action_erase_events(action)
	
	# Update settings manager
	if settings_manager:
		settings_manager.set_control_mapping(action, null)
	
	print("AccessibilityManager: Reset control mapping for '%s'" % action)

## Reset all control mappings
func reset_all_control_mappings() -> void:
	"""Reset all control mappings to defaults."""
	if settings_manager:
		settings_manager.reset_control_mappings()
	
	print("AccessibilityManager: Reset all control mappings")

## Get all available actions
func get_all_actions() -> Array[StringName]:
	"""Get list of all available input actions."""
	return InputMap.get_actions()

#endregion

#region Motion Sensitivity

## Set motion sensitivity reduced
## Requirement 70.5: Reduce motion effects when sensitivity mode is enabled
func set_motion_sensitivity_reduced(reduced: bool) -> void:
	"""Enable or disable reduced motion sensitivity."""
	motion_sensitivity_reduced = reduced
	
	# Update settings manager
	if settings_manager:
		settings_manager.set_motion_sensitivity_reduced(reduced)
	
	# Apply motion reduction to systems
	_apply_motion_sensitivity_settings()
	
	motion_sensitivity_changed.emit(reduced)
	print("AccessibilityManager: Motion sensitivity %s" % ("reduced" if reduced else "normal"))

## Apply motion sensitivity settings to game systems
func _apply_motion_sensitivity_settings() -> void:
	"""Apply motion sensitivity settings to relevant game systems."""
	var engine_node = get_node_or_null("/root/ResonanceEngine")
	if not engine_node:
		return
	
	# Reduce camera shake
	if engine_node.has_method("set_camera_shake_intensity"):
		var intensity = 0.3 if motion_sensitivity_reduced else 1.0
		engine_node.set_camera_shake_intensity(intensity)
	
	# Reduce post-processing effects
	if engine_node.has_method("get_post_processing"):
		var post_processing = engine_node.get_post_processing()
		if post_processing and post_processing.has_method("set_effect_intensity"):
			var intensity = 0.5 if motion_sensitivity_reduced else 1.0
			post_processing.set_effect_intensity(intensity)
	
	# Reduce lattice animation speed
	if engine_node.has_method("get_lattice_renderer"):
		var lattice = engine_node.get_lattice_renderer()
		if lattice and lattice.has_method("set_animation_speed"):
			var speed = 0.5 if motion_sensitivity_reduced else 1.0
			lattice.set_animation_speed(speed)
	
	print("AccessibilityManager: Applied motion sensitivity settings")

#endregion

#region Settings Integration

## Handle setting changed from SettingsManager
func _on_setting_changed(category: String, key: String, value: Variant) -> void:
	"""Handle setting changes from SettingsManager."""
	if category == "accessibility":
		match key:
			"colorblind_mode":
				set_colorblind_mode_from_string(value)
			"subtitles_enabled":
				set_subtitles_enabled(value)
			"motion_sensitivity_reduced":
				set_motion_sensitivity_reduced(value)

#endregion

#region Public Interface

## Get current colorblind mode
func get_colorblind_mode() -> ColorblindMode:
	"""Get the current colorblind mode."""
	return current_colorblind_mode

## Get current colorblind mode as string
func get_colorblind_mode_string() -> String:
	"""Get the current colorblind mode as a string."""
	return _colorblind_mode_to_string(current_colorblind_mode)

## Check if subtitles are enabled
func are_subtitles_enabled() -> bool:
	"""Check if subtitles are currently enabled."""
	return subtitles_enabled

## Check if motion sensitivity is reduced
func is_motion_sensitivity_reduced() -> bool:
	"""Check if motion sensitivity is currently reduced."""
	return motion_sensitivity_reduced

## Get accessibility status summary
func get_accessibility_status() -> Dictionary:
	"""Get a summary of all accessibility settings."""
	return {
		"colorblind_mode": get_colorblind_mode_string(),
		"subtitles_enabled": subtitles_enabled,
		"motion_sensitivity_reduced": motion_sensitivity_reduced
	}

#endregion
