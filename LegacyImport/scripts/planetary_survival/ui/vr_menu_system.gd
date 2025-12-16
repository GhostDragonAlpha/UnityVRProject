## VRMenuSystem - VR-optimized main menu with spatial interaction
##
## Provides ergonomic VR menu system with haptic feedback, proper positioning,
## and smooth transitions. Designed for comfort during 2+ hour play sessions.
##
## Features:
## - Optimal menu positioning (prevent neck strain)
## - Haptic feedback on all interactions
## - Visual feedback for button hovers and presses
## - Smooth transitions between menu states
## - Accessibility support (text size, colorblind modes)

extends Node3D
class_name VRMenuSystem

signal menu_action(action: String)
signal menu_opened(menu_name: String)
signal menu_closed()

## Menu states
enum MenuState {
	CLOSED,
	MAIN,
	SETTINGS,
	TUTORIAL,
	STATS
}

## Current menu state
var current_state: MenuState = MenuState.CLOSED

## Menu positioning settings (ergonomic values for VR)
@export var menu_distance: float = 1.8  # Distance from player (meters)
@export var menu_height_offset: float = -0.2  # Slightly below eye level (prevents neck strain)
@export var menu_angle: float = 10.0  # Tilt down slightly (degrees)

## Menu panel settings
@export var panel_width: float = 1.2
@export var panel_height: float = 1.6
@export var button_height: float = 0.12
@export var button_spacing: float = 0.02

## Text settings (VR readability)
@export var title_font_size: int = 48
@export var button_font_size: int = 32
@export var text_scale: float = 1.0  # Accessibility: adjustable text size

## Haptic feedback settings
@export var haptic_on_hover: float = 0.1  # Light pulse
@export var haptic_on_click: float = 0.4  # Medium pulse

## System references
var vr_manager: VRManager = null
var haptic_manager: HapticManager = null
var settings_manager = null
var left_controller: XRController3D = null
var right_controller: XRController3D = null

## UI components
var root_panel: MeshInstance3D = null
var menu_panels: Dictionary = {}  # MenuState -> Control
var current_panel: Control = null

## Interaction state
var hover_button: Button = null
var last_hover_button: Button = null
var trigger_pressed: bool = false

## Transition animation
var transition_tween: Tween = null
@export var transition_duration: float = 0.3


func _ready() -> void:
	# Get system references
	vr_manager = get_node_or_null("/root/ResonanceEngine/VRManager")
	if vr_manager:
		left_controller = vr_manager.get_controller("left")
		right_controller = vr_manager.get_controller("right")

	haptic_manager = get_node_or_null("/root/ResonanceEngine/HapticManager")
	settings_manager = get_node_or_null("/root/SettingsManager")

	# Load accessibility settings
	_load_accessibility_settings()

	# Create menu UI
	_create_menu_structure()

	# Start hidden
	visible = false

	print("VRMenuSystem: Initialized successfully")


func _load_accessibility_settings() -> void:
	"""Load accessibility settings for text size."""
	if settings_manager:
		text_scale = settings_manager.get_setting("accessibility", "text_scale", 1.0)


func _create_menu_structure() -> void:
	"""Create the 3D menu structure."""
	# Create root panel (3D background)
	root_panel = MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(panel_width, panel_height)
	root_panel.mesh = mesh

	# Create semi-transparent material
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.05, 0.08, 0.12, 0.95)  # Dark blue-gray
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.emission_enabled = true
	material.emission = Color(0.1, 0.15, 0.25)
	material.emission_energy = 0.3
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	root_panel.material_override = material

	add_child.call_deferred(root_panel)

	# Create SubViewport for UI rendering
	var subviewport := SubViewport.new()
	subviewport.size = Vector2i(1024, 1280)
	subviewport.transparent_bg = true
	subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root_panel.add_child.call_deferred(subviewport)

	# Apply viewport texture to panel
	var viewport_material := StandardMaterial3D.new()
	viewport_material.albedo_texture = subviewport.get_texture()
	viewport_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	viewport_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	viewport_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	root_panel.material_override = viewport_material

	# Create menu panels
	_create_main_menu(subviewport)
	_create_settings_menu(subviewport)
	_create_tutorial_menu(subviewport)
	_create_stats_menu(subviewport)


func _create_main_menu(parent: SubViewport) -> void:
	"""Create main menu panel."""
	var panel := Control.new()
	panel.name = "MainMenuPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.visible = false
	parent.add_child.call_deferred(panel)
	menu_panels[MenuState.MAIN] = panel

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0)  # Transparent
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child.call_deferred(bg)

	# Title
	var title := Label.new()
	title.text = "PLANETARY SURVIVAL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	title.add_theme_font_size_override("font_size", int(title_font_size * text_scale))
	title.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	title.position = Vector2(0, 60)
	title.size = Vector2(1024, 100)
	panel.add_child.call_deferred(title)

	# Buttons container
	var container := VBoxContainer.new()
	container.position = Vector2(312, 250)
	container.size = Vector2(400, 800)
	container.add_theme_constant_override("separation", int(button_spacing * 100))
	panel.add_child.call_deferred(container)

	# Create buttons
	var button_data := [
		{"text": "Continue Game", "action": "continue"},
		{"text": "New Game", "action": "new_game"},
		{"text": "Tutorial", "action": "tutorial"},
		{"text": "Settings", "action": "settings"},
		{"text": "Statistics", "action": "stats"},
		{"text": "Exit to Main Menu", "action": "exit"}
	]

	for data in button_data:
		var btn := _create_menu_button(data.text, data.action)
		container.add_child.call_deferred(btn)


func _create_settings_menu(parent: SubViewport) -> void:
	"""Create settings menu panel."""
	var panel := Control.new()
	panel.name = "SettingsMenuPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.visible = false
	parent.add_child.call_deferred(panel)
	menu_panels[MenuState.SETTINGS] = panel

	# Title
	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", int(title_font_size * text_scale))
	title.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	title.position = Vector2(0, 60)
	title.size = Vector2(1024, 100)
	panel.add_child(title)

	# Settings container
	var container := VBoxContainer.new()
	container.position = Vector2(312, 200)
	container.size = Vector2(400, 900)
	container.add_theme_constant_override("separation", 20)
	panel.add_child(container)

	# VR Comfort section
	var comfort_label := Label.new()
	comfort_label.text = "VR COMFORT"
	comfort_label.add_theme_font_size_override("font_size", int(button_font_size * text_scale))
	comfort_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	container.add_child(comfort_label)

	var settings_data := [
		{"text": "Vignette Intensity", "action": "vignette"},
		{"text": "Snap Turn Angle", "action": "snap_turn"},
		{"text": "Locomotion Mode", "action": "locomotion"},
		{"text": "Text Size", "action": "text_size"},
		{"text": "Colorblind Mode", "action": "colorblind"},
		{"text": "Back", "action": "back"}
	]

	for data in settings_data:
		var btn := _create_menu_button(data.text, data.action)
		container.add_child(btn)


func _create_tutorial_menu(parent: SubViewport) -> void:
	"""Create tutorial selection menu."""
	var panel := Control.new()
	panel.name = "TutorialMenuPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.visible = false
	parent.add_child(panel)
	menu_panels[MenuState.TUTORIAL] = panel

	# Title
	var title := Label.new()
	title.text = "TUTORIAL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", int(title_font_size * text_scale))
	title.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	title.position = Vector2(0, 60)
	title.size = Vector2(1024, 100)
	panel.add_child(title)

	# Tutorial options
	var container := VBoxContainer.new()
	container.position = Vector2(312, 250)
	container.size = Vector2(400, 800)
	container.add_theme_constant_override("separation", int(button_spacing * 100))
	panel.add_child(container)

	var tutorial_data := [
		{"text": "Basic Controls", "action": "tutorial_controls"},
		{"text": "Resource Gathering", "action": "tutorial_resources"},
		{"text": "Base Building", "action": "tutorial_building"},
		{"text": "Crafting", "action": "tutorial_crafting"},
		{"text": "Survival Systems", "action": "tutorial_survival"},
		{"text": "Back", "action": "back"}
	]

	for data in tutorial_data:
		var btn := _create_menu_button(data.text, data.action)
		container.add_child(btn)


func _create_stats_menu(parent: SubViewport) -> void:
	"""Create statistics display menu."""
	var panel := Control.new()
	panel.name = "StatsMenuPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.visible = false
	parent.add_child(panel)
	menu_panels[MenuState.STATS] = panel

	# Title
	var title := Label.new()
	title.text = "STATISTICS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", int(title_font_size * text_scale))
	title.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	title.position = Vector2(0, 60)
	title.size = Vector2(1024, 100)
	panel.add_child(title)

	# Stats display
	var stats_label := RichTextLabel.new()
	stats_label.bbcode_enabled = true
	stats_label.position = Vector2(150, 200)
	stats_label.size = Vector2(724, 900)
	stats_label.add_theme_font_size_override("normal_font_size", int(24 * text_scale))
	stats_label.add_theme_color_override("default_color", Color(0.9, 0.9, 0.9))
	panel.add_child(stats_label)

	# Back button
	var back_btn := _create_menu_button("Back", "back")
	back_btn.position = Vector2(312, 1120)
	back_btn.size = Vector2(400, int(button_height * 100))
	panel.add_child(back_btn)


func _create_menu_button(text: String, action: String) -> Button:
	"""Create a styled menu button."""
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(400, int(button_height * 100))
	btn.add_theme_font_size_override("font_size", int(button_font_size * text_scale))

	# Style
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.25, 0.35, 0.8)
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.4, 0.5, 0.7)
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = Color(0.3, 0.4, 0.6, 0.9)
	hover_style.border_color = Color(0.6, 0.7, 1.0)
	hover_style.shadow_size = 4
	hover_style.shadow_color = Color(0.4, 0.5, 0.8, 0.5)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := hover_style.duplicate()
	pressed_style.bg_color = Color(0.4, 0.5, 0.7, 1.0)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	# Connect signals
	btn.pressed.connect(_on_button_pressed.bind(action))
	btn.mouse_entered.connect(_on_button_hover.bind(btn))

	return btn


func show_menu(state: MenuState) -> void:
	"""Show menu and position in front of player."""
	if state == MenuState.CLOSED:
		hide_menu()
		return

	current_state = state
	visible = true

	# Position menu in front of player
	_position_menu()

	# Hide all panels
	for panel in menu_panels.values():
		panel.visible = false

	# Show target panel with transition
	if state in menu_panels:
		current_panel = menu_panels[state]
		_transition_to_panel(current_panel)

	menu_opened.emit(_get_menu_name(state))
	print("VRMenuSystem: Opened menu - %s" % _get_menu_name(state))


func hide_menu() -> void:
	"""Hide menu with smooth transition."""
	if transition_tween:
		transition_tween.kill()

	transition_tween = create_tween()
	transition_tween.set_parallel(true)
	transition_tween.tween_property(self, "scale", Vector3(0.8, 0.8, 0.8), transition_duration)
	transition_tween.tween_property(self, "modulate:a", 0.0, transition_duration)
	transition_tween.chain().tween_callback(func(): visible = false)

	current_state = MenuState.CLOSED
	current_panel = null
	menu_closed.emit()
	print("VRMenuSystem: Closed menu")


func _position_menu() -> void:
	"""Position menu ergonomically in front of player."""
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not camera:
		return

	# Get forward direction (horizontal only)
	var forward: Vector3 = -camera.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	# Position at comfortable distance and height
	var target_pos: Vector3 = camera.global_position + forward * menu_distance
	target_pos.y = camera.global_position.y + menu_height_offset

	# Smooth position transition
	if transition_tween:
		transition_tween.kill()

	transition_tween = create_tween()
	transition_tween.set_parallel(true)
	transition_tween.tween_property(self, "global_position", target_pos, transition_duration)
	transition_tween.tween_property(self, "scale", Vector3.ONE, transition_duration).from(Vector3(0.8, 0.8, 0.8))
	transition_tween.tween_property(self, "modulate:a", 1.0, transition_duration).from(0.0)

	# Face camera with slight downward tilt
	var look_pos := camera.global_position
	look_at(look_pos, Vector3.UP)
	rotate_x(deg_to_rad(menu_angle))


func _transition_to_panel(panel: Control) -> void:
	"""Smoothly transition to a panel."""
	panel.modulate.a = 0.0
	panel.visible = true

	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, transition_duration * 0.5)


func _process(_delta: float) -> void:
	"""Process input and interaction."""
	if not visible or current_state == MenuState.CLOSED:
		return

	# Update hover detection
	_update_hover()

	# Handle trigger input
	_handle_trigger_input()


func _update_hover() -> void:
	"""Update button hover state with VR controllers."""
	last_hover_button = hover_button
	hover_button = null

	# Check right controller raycast
	if right_controller:
		hover_button = _raycast_button(right_controller)

	# Check left controller if right didn't hit
	if not hover_button and left_controller:
		hover_button = _raycast_button(left_controller)

	# Trigger haptic feedback on hover change
	if hover_button != last_hover_button:
		if hover_button:
			_trigger_hover_haptic()


func _raycast_button(controller: XRController3D) -> Button:
	"""Raycast from controller to detect button hover."""
	if not current_panel:
		return null

	# Simple 3D raycast to menu plane
	var ray_start: Vector3 = controller.global_position
	var ray_dir: Vector3 = -controller.global_transform.basis.z

	# Check intersection with menu plane
	var plane := Plane(global_transform.basis.z, global_position)
	var hit_pos: Variant = plane.intersects_ray(ray_start, ray_dir)

	if hit_pos == null or not hit_pos is Vector3:
		return null

	# Convert 3D hit to 2D viewport coordinates
	var local_hit: Vector3 = global_transform.affine_inverse() * hit_pos
	var uv := Vector2(
		(local_hit.x / panel_width + 0.5),
		(-local_hit.y / panel_height + 0.5)
	)

	# Convert to viewport pixel coordinates
	var viewport_pos := uv * Vector2(1024, 1280)

	# Find button at this position
	return _find_button_at_position(current_panel, viewport_pos)


func _find_button_at_position(parent: Control, pos: Vector2) -> Button:
	"""Recursively find button at viewport position."""
	for child in parent.get_children():
		if child is Button:
			var btn := child as Button
			var rect := Rect2(btn.global_position, btn.size)
			if rect.has_point(pos):
				return btn
		elif child is Control:
			var result := _find_button_at_position(child, pos)
			if result:
				return result
	return null


func _handle_trigger_input() -> void:
	"""Handle trigger button press."""
	var trigger_now: bool = false

	if right_controller:
		trigger_now = trigger_now or right_controller.is_button_pressed("trigger_click")
	if left_controller:
		trigger_now = trigger_now or left_controller.is_button_pressed("trigger_click")

	# Detect rising edge
	if trigger_now and not trigger_pressed:
		if hover_button:
			hover_button.emit_signal("pressed")
			_trigger_click_haptic()

	trigger_pressed = trigger_now


func _on_button_pressed(action: String) -> void:
	"""Handle button press."""
	print("VRMenuSystem: Button pressed - %s" % action)

	match action:
		"back":
			show_menu(MenuState.MAIN)
		"settings":
			show_menu(MenuState.SETTINGS)
		"tutorial":
			show_menu(MenuState.TUTORIAL)
		"stats":
			show_menu(MenuState.STATS)
		"exit":
			hide_menu()
		_:
			menu_action.emit(action)


func _on_button_hover(btn: Button) -> void:
	"""Handle button hover."""
	hover_button = btn


func _trigger_hover_haptic() -> void:
	"""Trigger haptic feedback for hover."""
	if haptic_manager:
		haptic_manager.trigger_haptic_both(haptic_on_hover, 0.05)


func _trigger_click_haptic() -> void:
	"""Trigger haptic feedback for click."""
	if haptic_manager:
		haptic_manager.trigger_haptic_both(haptic_on_click, 0.1)


func _get_menu_name(state: MenuState) -> String:
	"""Get menu name string."""
	match state:
		MenuState.MAIN:
			return "main"
		MenuState.SETTINGS:
			return "settings"
		MenuState.TUTORIAL:
			return "tutorial"
		MenuState.STATS:
			return "stats"
		_:
			return "closed"


## PUBLIC API

func set_text_scale(scale: float) -> void:
	"""Set text scale for accessibility."""
	text_scale = clampf(scale, 0.5, 2.0)
	# Recreate menus with new scale
	# (In production, this would update existing elements)
	print("VRMenuSystem: Text scale set to %.1f" % text_scale)
