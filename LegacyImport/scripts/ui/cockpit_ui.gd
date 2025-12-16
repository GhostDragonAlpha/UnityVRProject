## CockpitUI - Interactive VR Cockpit Interface
## Provides interactive 3D controls and displays for spacecraft systems in VR.
## Supports both VR motion controller interaction and desktop fallback.
##
## Requirements: 19.1, 19.2, 19.3, 19.4, 19.5, 64.4, 64.5
## - 19.1: Load and render spacecraft cockpit model with interactive controls
## - 19.2: Position camera at pilot viewpoint
## - 19.3: Detect collisions between controllers and cockpit elements
## - 19.4: Trigger spacecraft system responses on activation
## - 19.5: Show real-time telemetry data
## - 64.4: Use emissive materials with bloom effects for displays
## - 64.5: Apply emissive materials with WorldEnvironment glow
extends Node3D
class_name CockpitUI

## Emitted when a control is activated
signal control_activated(control_name: String)
## Emitted when a control is hovered
signal control_hovered(control_name: String)
## Emitted when a control is released
signal control_released(control_name: String)
## Emitted when telemetry data is updated
signal telemetry_updated(data: Dictionary)

## Control types
enum ControlType {
	BUTTON,      # Push button
	SWITCH,      # Toggle switch
	LEVER,       # Pull/push lever
	DIAL,        # Rotary dial
	SLIDER,      # Linear slider
	DISPLAY      # Read-only display
}

## Control state
enum ControlState {
	IDLE,
	HOVERED,
	PRESSED,
	ACTIVE
}

## Interactive control data
class CockpitControl:
	var name: String = ""
	var type: ControlType = ControlType.BUTTON
	var state: ControlState = ControlState.IDLE
	var area: Area3D = null
	var mesh: MeshInstance3D = null
	var collision_shape: CollisionShape3D = null
	var position: Vector3 = Vector3.ZERO
	var value: float = 0.0  # 0.0 to 1.0
	var enabled: bool = true
	var callback: Callable = Callable()
	
	func _init(n: String = "", t: ControlType = ControlType.BUTTON) -> void:
		name = n
		type = t

#region Exported Properties

## Path to cockpit model scene
@export var cockpit_model_path: String = ""

## Pilot viewpoint offset from cockpit origin
@export var pilot_viewpoint_offset: Vector3 = Vector3(0, 1.6, 0)

## Enable VR controller interaction
@export var enable_vr_interaction: bool = true

## Enable desktop mouse interaction (fallback)
@export var enable_desktop_interaction: bool = true

## Interaction distance for desktop mode
@export var desktop_interaction_distance: float = 2.0

## Control highlight color when hovered
@export var hover_color: Color = Color(0.3, 0.7, 1.0, 0.5)

## Control active color when pressed
@export var active_color: Color = Color(0.0, 1.0, 0.5, 0.8)

## Display update frequency (Hz)
@export var display_update_frequency: float = 30.0

## Enable emissive displays
@export var enable_emissive_displays: bool = true

## Display emission intensity
@export var display_emission_intensity: float = 2.0

#endregion

#region Runtime Properties

## Dictionary of all interactive controls
var _controls: Dictionary = {}

## Cockpit model instance
var _cockpit_model: Node3D = null

## Pilot viewpoint node (camera parent)
var _pilot_viewpoint: Node3D = null

## Left VR controller reference
var _left_controller: XRController3D = null

## Right VR controller reference
var _right_controller: XRController3D = null

## Camera reference
var _camera: Camera3D = null

## Currently hovered control (VR)
var _hovered_control_left: CockpitControl = null
var _hovered_control_right: CockpitControl = null

## Currently hovered control (desktop)
var _hovered_control_desktop: CockpitControl = null

## Display viewports for telemetry
var _display_viewports: Dictionary = {}

## Telemetry data
var _telemetry_data: Dictionary = {
	"velocity": Vector3.ZERO,
	"position": Vector3.ZERO,
	"snr": 100.0,
	"entropy": 0.0,
	"speed_of_light_percent": 0.0,
	"escape_velocity": 0.0,
	"time_multiplier": 1.0,
	"simulation_date": ""
}

## Update timer for displays
var _display_update_timer: float = 0.0

## Whether the cockpit is initialized
var _is_initialized: bool = false

## Spacecraft reference
var _spacecraft: Node = null

## Signal manager reference
var _signal_manager: Node = null

## Time manager reference
var _time_manager: Node = null

#endregion


func _ready() -> void:
	_setup_pilot_viewpoint()
	
	# Initialize will be called after scene is fully loaded
	call_deferred("initialize")


func _process(delta: float) -> void:
	if not _is_initialized:
		return
	
	# Update displays
	_display_update_timer += delta
	if _display_update_timer >= 1.0 / display_update_frequency:
		_update_telemetry_displays()
		_display_update_timer = 0.0
	
	# Handle desktop interaction
	if enable_desktop_interaction and not enable_vr_interaction:
		_handle_desktop_interaction()


func _physics_process(delta: float) -> void:
	if not _is_initialized:
		return
	
	# Update VR controller interactions
	if enable_vr_interaction:
		_update_vr_interactions()


#region Initialization

## Initialize the cockpit UI
func initialize() -> bool:
	"""Initialize the cockpit UI system."""
	if _is_initialized:
		return true
	
	# Load cockpit model
	if not _load_cockpit_model():
		push_warning("CockpitUI: Failed to load cockpit model, using default")
		_create_default_cockpit()
	
	# Setup interactive controls
	_setup_interactive_controls()
	
	# Setup displays
	_setup_telemetry_displays()
	
	# Find VR controllers if available
	_find_vr_controllers()
	
	# Find camera
	_find_camera()
	
	# Find spacecraft and managers
	_find_system_references()
	
	_is_initialized = true
	print("CockpitUI: Initialized successfully")
	return true


## Load cockpit model from scene file
## Requirement 19.1: Load and render spacecraft cockpit model
func _load_cockpit_model() -> bool:
	"""Load the cockpit model from the specified path."""
	if cockpit_model_path == "" or not FileAccess.file_exists(cockpit_model_path):
		return false
	
	var scene = load(cockpit_model_path)
	if scene == null:
		return false
	
	_cockpit_model = scene.instantiate()
	if _cockpit_model == null:
		return false
	
	add_child(_cockpit_model)
	_cockpit_model.position = Vector3.ZERO
	
	print("CockpitUI: Loaded cockpit model from %s" % cockpit_model_path)
	return true


## Create a default cockpit if no model is provided
func _create_default_cockpit() -> void:
	"""Create a simple default cockpit for testing."""
	_cockpit_model = Node3D.new()
	_cockpit_model.name = "DefaultCockpit"
	add_child(_cockpit_model)
	
	# Create a simple dashboard
	var dashboard = MeshInstance3D.new()
	dashboard.name = "Dashboard"
	var box = BoxMesh.new()
	box.size = Vector3(2.0, 0.1, 1.0)
	dashboard.mesh = box
	dashboard.position = Vector3(0, 0.8, -0.5)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.2, 0.25)
	material.metallic = 0.8
	material.roughness = 0.3
	dashboard.material_override = material
	
	_cockpit_model.add_child(dashboard)
	
	print("CockpitUI: Created default cockpit")


## Setup pilot viewpoint
## Requirement 19.2: Position camera at pilot viewpoint
func _setup_pilot_viewpoint() -> void:
	"""Create the pilot viewpoint node."""
	_pilot_viewpoint = Node3D.new()
	_pilot_viewpoint.name = "PilotViewpoint"
	add_child(_pilot_viewpoint)
	_pilot_viewpoint.position = pilot_viewpoint_offset


## Find VR controllers in the scene tree
func _find_vr_controllers() -> void:
	"""Find VR controller nodes."""
	# Look for XROrigin3D and its controllers (under VRMain parent)
	var xr_origin = get_node_or_null("/root/VRMain/XROrigin3D")
	if xr_origin == null:
		# Fallback: Try to find in scene dynamically
		xr_origin = get_tree().root.find_child("XROrigin3D", true, false)
	
	if xr_origin != null:
		_left_controller = xr_origin.find_child("LeftController", true, false)
		_right_controller = xr_origin.find_child("RightController", true, false)
		
		if _left_controller != null:
			print("CockpitUI: Found left VR controller")
		if _right_controller != null:
			print("CockpitUI: Found right VR controller")


## Find camera in the scene
func _find_camera() -> void:
	"""Find the main camera."""
	_camera = get_viewport().get_camera_3d()
	if _camera != null:
		print("CockpitUI: Found camera")


## Find system references (spacecraft, managers)
func _find_system_references() -> void:
	"""Find references to spacecraft and manager systems."""
	# Try to find spacecraft
	_spacecraft = get_node_or_null("/root/Spacecraft")
	if _spacecraft == null:
		_spacecraft = get_tree().root.find_child("Spacecraft", true, false)
	
	# Try to find signal manager
	_signal_manager = get_node_or_null("/root/SignalManager")
	if _signal_manager == null and _spacecraft != null:
		_signal_manager = _spacecraft.find_child("SignalManager", true, false)
	
	# Try to find time manager
	var engine = get_node_or_null("/root/ResonanceEngine")
	if engine != null and engine.has_method("get"):
		_time_manager = engine.get("time_manager")

#endregion



#region Interactive Controls

## Setup interactive controls
## Requirement 19.1: Interactive controls
func _setup_interactive_controls() -> void:
	"""Create interactive control elements."""
	# Create default controls if no model is loaded
	if _cockpit_model == null:
		return
	
	# Create throttle lever
	_create_control("throttle", ControlType.LEVER, Vector3(-0.3, 0.9, -0.4))
	
	# Create power button
	_create_control("power", ControlType.BUTTON, Vector3(0.0, 0.9, -0.4))
	
	# Create navigation switch
	_create_control("nav_mode", ControlType.SWITCH, Vector3(0.3, 0.9, -0.4))
	
	# Create time acceleration dial
	_create_control("time_accel", ControlType.DIAL, Vector3(-0.2, 0.85, -0.45))
	
	# Create signal boost button
	_create_control("signal_boost", ControlType.BUTTON, Vector3(0.2, 0.85, -0.45))
	
	print("CockpitUI: Created %d interactive controls" % _controls.size())


## Create an interactive control
func _create_control(control_name: String, type: ControlType, pos: Vector3) -> CockpitControl:
	"""Create an interactive control at the specified position."""
	var control = CockpitControl.new(control_name, type)
	control.position = pos
	
	# Create Area3D for interaction detection
	control.area = Area3D.new()
	control.area.name = "Control_" + control_name
	control.area.collision_layer = 0
	control.area.collision_mask = 1  # Interact with layer 1
	_cockpit_model.add_child(control.area)
	control.area.position = pos
	
	# Create collision shape
	control.collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.1, 0.1, 0.1)
	control.collision_shape.shape = shape
	control.area.add_child(control.collision_shape)
	
	# Create visual mesh
	control.mesh = MeshInstance3D.new()
	control.mesh.name = "Mesh_" + control_name
	
	match type:
		ControlType.BUTTON:
			var cylinder = CylinderMesh.new()
			cylinder.top_radius = 0.04
			cylinder.bottom_radius = 0.04
			cylinder.height = 0.02
			control.mesh.mesh = cylinder
		ControlType.SWITCH:
			var box = BoxMesh.new()
			box.size = Vector3(0.05, 0.08, 0.03)
			control.mesh.mesh = box
		ControlType.LEVER:
			var capsule = CapsuleMesh.new()
			capsule.radius = 0.02
			capsule.height = 0.15
			control.mesh.mesh = capsule
		ControlType.DIAL:
			var torus = TorusMesh.new()
			torus.inner_radius = 0.03
			torus.outer_radius = 0.05
			control.mesh.mesh = torus
		ControlType.SLIDER:
			var box = BoxMesh.new()
			box.size = Vector3(0.15, 0.03, 0.03)
			control.mesh.mesh = box
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.3, 0.35)
	material.metallic = 0.7
	material.roughness = 0.4
	control.mesh.material_override = material
	
	control.area.add_child(control.mesh)
	
	# Connect signals
	control.area.body_entered.connect(_on_control_body_entered.bind(control))
	control.area.body_exited.connect(_on_control_body_exited.bind(control))
	
	_controls[control_name] = control
	return control


## Register a control callback
func register_control_callback(control_name: String, callback: Callable) -> bool:
	"""Register a callback function for a control."""
	if not _controls.has(control_name):
		return false
	
	_controls[control_name].callback = callback
	return true


## Set control enabled state
func set_control_enabled(control_name: String, enabled: bool) -> void:
	"""Enable or disable a control."""
	if not _controls.has(control_name):
		return
	
	var control: CockpitControl = _controls[control_name]
	control.enabled = enabled
	
	# Update visual appearance
	if control.mesh != null and control.mesh.material_override != null:
		var mat = control.mesh.material_override as StandardMaterial3D
		if enabled:
			mat.albedo_color = Color(0.3, 0.3, 0.35)
		else:
			mat.albedo_color = Color(0.15, 0.15, 0.15)


## Get control value
func get_control_value(control_name: String) -> float:
	"""Get the current value of a control (0.0 to 1.0)."""
	if not _controls.has(control_name):
		return 0.0
	return _controls[control_name].value


## Set control value
func set_control_value(control_name: String, value: float) -> void:
	"""Set the value of a control (0.0 to 1.0)."""
	if not _controls.has(control_name):
		return
	
	_controls[control_name].value = clampf(value, 0.0, 1.0)
	_update_control_visual(control_name)


## Update control visual based on value
func _update_control_visual(control_name: String) -> void:
	"""Update the visual appearance of a control based on its value."""
	if not _controls.has(control_name):
		return
	
	var control: CockpitControl = _controls[control_name]
	if control.mesh == null:
		return
	
	# Update based on control type
	match control.type:
		ControlType.LEVER:
			# Move lever up/down
			control.mesh.position.y = control.value * 0.1 - 0.05
		ControlType.DIAL:
			# Rotate dial
			control.mesh.rotation.z = control.value * TAU
		ControlType.SLIDER:
			# Move slider left/right
			control.mesh.position.x = (control.value - 0.5) * 0.1
		ControlType.SWITCH:
			# Tilt switch
			control.mesh.rotation.x = (control.value - 0.5) * PI / 4


## Activate a control
## Requirement 19.4: Trigger spacecraft system responses
func activate_control(control_name: String) -> void:
	"""Activate a control (button press, switch toggle, etc.)."""
	if not _controls.has(control_name):
		return
	
	var control: CockpitControl = _controls[control_name]
	if not control.enabled:
		return
	
	# Update state
	control.state = ControlState.ACTIVE
	
	# Handle based on type
	match control.type:
		ControlType.BUTTON:
			# Button press
			control.value = 1.0
			_update_control_visual(control_name)
			# Auto-release after a moment
			await get_tree().create_timer(0.1).timeout
			control.value = 0.0
			_update_control_visual(control_name)
		ControlType.SWITCH:
			# Toggle switch
			control.value = 1.0 if control.value < 0.5 else 0.0
			_update_control_visual(control_name)
	
	# Call callback if registered
	if control.callback.is_valid():
		control.callback.call(control.value)
	
	# Emit signal
	control_activated.emit(control_name)
	
	# Trigger haptic feedback if VR
	_trigger_haptic_feedback(control_name)
	
	print("CockpitUI: Activated control '%s' (value: %.2f)" % [control_name, control.value])


## Trigger haptic feedback for VR controllers
func _trigger_haptic_feedback(control_name: String) -> void:
	"""Trigger haptic feedback on VR controllers."""
	if _left_controller != null and _left_controller.has_method("trigger_haptic_pulse"):
		_left_controller.trigger_haptic_pulse("haptic", 0.0, 0.3, 0.1, 0.0)
	if _right_controller != null and _right_controller.has_method("trigger_haptic_pulse"):
		_right_controller.trigger_haptic_pulse("haptic", 0.0, 0.3, 0.1, 0.0)

#endregion

#region VR Interaction

## Update VR controller interactions
## Requirement 19.3: Detect collisions between controllers and cockpit elements
func _update_vr_interactions() -> void:
	"""Update VR controller interactions with controls."""
	if _left_controller != null:
		_check_controller_interaction(_left_controller, true)
	if _right_controller != null:
		_check_controller_interaction(_right_controller, false)


## Check controller interaction with controls
func _check_controller_interaction(controller: XRController3D, is_left: bool) -> void:
	"""Check if a controller is interacting with any controls."""
	if controller == null:
		return
	
	var controller_pos = controller.global_position
	var closest_control: CockpitControl = null
	var closest_distance: float = INF
	
	# Find closest control within interaction range
	for control_name in _controls:
		var control: CockpitControl = _controls[control_name]
		if not control.enabled or control.area == null:
			continue
		
		var control_pos = control.area.global_position
		var distance = controller_pos.distance_to(control_pos)
		
		if distance < 0.15 and distance < closest_distance:  # 15cm interaction range
			closest_distance = distance
			closest_control = control
	
	# Update hover state
	var previous_hover = _hovered_control_left if is_left else _hovered_control_right
	
	if closest_control != previous_hover:
		# Unhover previous
		if previous_hover != null:
			_set_control_hover(previous_hover, false)
		
		# Hover new
		if closest_control != null:
			_set_control_hover(closest_control, true)
			control_hovered.emit(closest_control.name)
		
		if is_left:
			_hovered_control_left = closest_control
		else:
			_hovered_control_right = closest_control
	
	# Check for trigger press
	if closest_control != null:
		var trigger_pressed = controller.get_float("trigger") > 0.5
		if trigger_pressed:
			activate_control(closest_control.name)


## Set control hover state
func _set_control_hover(control: CockpitControl, hovered: bool) -> void:
	"""Set the hover state of a control."""
	if control.mesh == null or control.mesh.material_override == null:
		return
	
	var mat = control.mesh.material_override as StandardMaterial3D
	if hovered:
		control.state = ControlState.HOVERED
		mat.emission_enabled = true
		mat.emission = hover_color
		mat.emission_energy_multiplier = 1.0
	else:
		control.state = ControlState.IDLE
		mat.emission_enabled = false


## Handle control body entered (for VR controllers)
func _on_control_body_entered(body: Node3D, control: CockpitControl) -> void:
	"""Handle when a body enters a control's area."""
	# This is used for additional collision detection if needed
	pass


## Handle control body exited
func _on_control_body_exited(body: Node3D, control: CockpitControl) -> void:
	"""Handle when a body exits a control's area."""
	pass

#endregion

#region Desktop Interaction

## Handle desktop mouse interaction (fallback)
func _handle_desktop_interaction() -> void:
	"""Handle desktop mouse interaction with controls."""
	if _camera == null:
		return
	
	# Raycast from camera to mouse position
	var mouse_pos = get_viewport().get_mouse_position()
	var from = _camera.project_ray_origin(mouse_pos)
	var to = from + _camera.project_ray_normal(mouse_pos) * desktop_interaction_distance
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	var result = space_state.intersect_ray(query)
	
	var hovered_control: CockpitControl = null
	
	if result:
		# Check if we hit a control
		var collider = result.collider
		if collider is Area3D:
			for control_name in _controls:
				var control: CockpitControl = _controls[control_name]
				if control.area == collider:
					hovered_control = control
					break
	
	# Update hover state
	if hovered_control != _hovered_control_desktop:
		if _hovered_control_desktop != null:
			_set_control_hover(_hovered_control_desktop, false)
		
		if hovered_control != null:
			_set_control_hover(hovered_control, true)
			control_hovered.emit(hovered_control.name)
		
		_hovered_control_desktop = hovered_control
	
	# Check for mouse click
	if hovered_control != null and Input.is_action_just_pressed("ui_select"):
		activate_control(hovered_control.name)

#endregion



#region Telemetry Displays

## Setup telemetry displays
## Requirement 19.5: Show real-time telemetry data
## Requirement 64.4: Use emissive materials with bloom effects
func _setup_telemetry_displays() -> void:
	"""Create telemetry display screens."""
	if _cockpit_model == null:
		return
	
	# Create main display (center)
	_create_display("main", Vector3(0, 1.0, -0.5), Vector2(0.4, 0.3))
	
	# Create left display (velocity/position)
	_create_display("left", Vector3(-0.4, 0.95, -0.5), Vector2(0.25, 0.2))
	
	# Create right display (SNR/entropy)
	_create_display("right", Vector3(0.4, 0.95, -0.5), Vector2(0.25, 0.2))
	
	print("CockpitUI: Created %d telemetry displays" % _display_viewports.size())


## Create a display screen
func _create_display(display_name: String, pos: Vector3, size: Vector2) -> void:
	"""Create a display screen with SubViewport."""
	# Create SubViewport for rendering display content
	var viewport = SubViewport.new()
	viewport.name = "Viewport_" + display_name
	viewport.size = Vector2i(int(size.x * 1024), int(size.y * 1024))
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	
	# Create UI content for viewport
	var panel = Panel.new()
	panel.size = viewport.size
	viewport.add_child(panel)
	
	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 1.0)
	style.border_color = Color(0.2, 0.4, 0.6, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	
	# Create label for display content
	var label = Label.new()
	label.name = "DisplayLabel"
	label.position = Vector2(10, 10)
	label.size = viewport.size - Vector2(20, 20)
	label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	label.add_theme_font_size_override("font_size", 24)
	panel.add_child(label)
	
	# Create mesh to display the viewport texture
	var display_mesh = MeshInstance3D.new()
	display_mesh.name = "Display_" + display_name
	_cockpit_model.add_child(display_mesh)
	display_mesh.position = pos
	
	# Create quad mesh
	var quad = QuadMesh.new()
	quad.size = size
	display_mesh.mesh = quad
	
	# Create material with viewport texture
	var material = StandardMaterial3D.new()
	material.albedo_texture = viewport.get_texture()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	# Add emission for glow effect
	if enable_emissive_displays:
		material.emission_enabled = true
		material.emission_texture = viewport.get_texture()
		material.emission_energy_multiplier = display_emission_intensity
	
	display_mesh.material_override = material
	
	# Store references
	_display_viewports[display_name] = {
		"viewport": viewport,
		"label": label,
		"mesh": display_mesh
	}


## Update telemetry displays with current data
func _update_telemetry_displays() -> void:
	"""Update all telemetry displays with current data."""
	# Gather telemetry data
	_gather_telemetry_data()
	
	# Update main display
	if _display_viewports.has("main"):
		var label: Label = _display_viewports["main"]["label"]
		label.text = _format_main_display()
	
	# Update left display (velocity/position)
	if _display_viewports.has("left"):
		var label: Label = _display_viewports["left"]["label"]
		label.text = _format_velocity_display()
	
	# Update right display (SNR/entropy)
	if _display_viewports.has("right"):
		var label: Label = _display_viewports["right"]["label"]
		label.text = _format_snr_display()
	
	# Emit telemetry updated signal
	telemetry_updated.emit(_telemetry_data)


## Gather telemetry data from systems
func _gather_telemetry_data() -> void:
	"""Gather telemetry data from spacecraft and managers."""
	# Get velocity from spacecraft
	if _spacecraft != null:
		if _spacecraft.has_method("get_velocity"):
			_telemetry_data["velocity"] = _spacecraft.get_velocity()
		if _spacecraft.has_method("get_global_position"):
			_telemetry_data["position"] = _spacecraft.get_global_position()
		
		# Calculate speed of light percentage
		var speed = _telemetry_data["velocity"].length()
		var c = 1000.0  # Speed of light in game units
		_telemetry_data["speed_of_light_percent"] = (speed / c) * 100.0
	
	# Get SNR and entropy from signal manager
	if _signal_manager != null:
		if _signal_manager.has_method("get_snr"):
			_telemetry_data["snr"] = _signal_manager.get_snr()
		if _signal_manager.has_method("get_entropy"):
			_telemetry_data["entropy"] = _signal_manager.get_entropy()
	
	# Get time data from time manager
	if _time_manager != null:
		if _time_manager.has_method("get_time_scale"):
			_telemetry_data["time_multiplier"] = _time_manager.get_time_scale()
		if _time_manager.has_method("get_current_date_string"):
			_telemetry_data["simulation_date"] = _time_manager.get_current_date_string()


## Format main display text
func _format_main_display() -> String:
	"""Format the main display text."""
	var text = "SPACECRAFT TELEMETRY\n\n"
	text += "Time: %s\n" % _telemetry_data.get("simulation_date", "Unknown")
	text += "Time Scale: %.1fx\n" % _telemetry_data.get("time_multiplier", 1.0)
	text += "\n"
	text += "Speed: %.1f u/s\n" % _telemetry_data["velocity"].length()
	text += "Light Speed: %.2f%%\n" % _telemetry_data.get("speed_of_light_percent", 0.0)
	return text


## Format velocity display text
func _format_velocity_display() -> String:
	"""Format the velocity/position display text."""
	var vel = _telemetry_data["velocity"]
	var pos = _telemetry_data["position"]
	
	var text = "NAVIGATION\n\n"
	text += "Position:\n"
	text += "X: %.1f\n" % pos.x
	text += "Y: %.1f\n" % pos.y
	text += "Z: %.1f\n" % pos.z
	text += "\n"
	text += "Velocity:\n"
	text += "X: %.1f\n" % vel.x
	text += "Y: %.1f\n" % vel.y
	text += "Z: %.1f\n" % vel.z
	return text


## Format SNR display text
func _format_snr_display() -> String:
	"""Format the SNR/entropy display text."""
	var snr = _telemetry_data.get("snr", 100.0)
	var entropy = _telemetry_data.get("entropy", 0.0)
	
	var text = "SIGNAL STATUS\n\n"
	text += "SNR: %.1f%%\n" % snr
	text += "Entropy: %.2f\n" % entropy
	text += "\n"
	
	# Status indicator
	if snr > 75.0:
		text += "Status: OPTIMAL"
	elif snr > 50.0:
		text += "Status: GOOD"
	elif snr > 25.0:
		text += "Status: DEGRADED"
	else:
		text += "Status: CRITICAL"
	
	return text


## Update a specific display
func update_display(display_name: String, content: String) -> void:
	"""Update a specific display with custom content."""
	if not _display_viewports.has(display_name):
		return
	
	var label: Label = _display_viewports[display_name]["label"]
	label.text = content

#endregion

#region Public API

## Get pilot viewpoint node
func get_pilot_viewpoint() -> Node3D:
	"""Get the pilot viewpoint node for camera positioning."""
	return _pilot_viewpoint


## Get pilot viewpoint global position
func get_pilot_viewpoint_position() -> Vector3:
	"""Get the global position of the pilot viewpoint."""
	if _pilot_viewpoint != null:
		return _pilot_viewpoint.global_position
	return global_position + pilot_viewpoint_offset


## Check if cockpit is initialized
func is_initialized() -> bool:
	"""Check if the cockpit UI is initialized."""
	return _is_initialized


## Get all control names
func get_control_names() -> Array[String]:
	"""Get a list of all control names."""
	var names: Array[String] = []
	for name in _controls.keys():
		names.append(name)
	return names


## Get control by name
func get_control(control_name: String) -> CockpitControl:
	"""Get a control by name."""
	if _controls.has(control_name):
		return _controls[control_name]
	return null


## Get telemetry data
func get_telemetry_data() -> Dictionary:
	"""Get the current telemetry data."""
	return _telemetry_data.duplicate()


## Set spacecraft reference
func set_spacecraft(spacecraft: Node) -> void:
	"""Set the spacecraft reference."""
	_spacecraft = spacecraft


## Set signal manager reference
func set_signal_manager(signal_manager: Node) -> void:
	"""Set the signal manager reference."""
	_signal_manager = signal_manager


## Set time manager reference
func set_time_manager(time_manager: Node) -> void:
	"""Set the time manager reference."""
	_time_manager = time_manager


## Enable/disable VR interaction
func set_vr_interaction_enabled(enabled: bool) -> void:
	"""Enable or disable VR controller interaction."""
	enable_vr_interaction = enabled


## Enable/disable desktop interaction
func set_desktop_interaction_enabled(enabled: bool) -> void:
	"""Enable or disable desktop mouse interaction."""
	enable_desktop_interaction = enabled


## Get statistics
func get_statistics() -> Dictionary:
	"""Get cockpit UI statistics."""
	return {
		"initialized": _is_initialized,
		"control_count": _controls.size(),
		"display_count": _display_viewports.size(),
		"vr_enabled": enable_vr_interaction,
		"desktop_enabled": enable_desktop_interaction,
		"has_left_controller": _left_controller != null,
		"has_right_controller": _right_controller != null,
		"has_camera": _camera != null,
		"has_spacecraft": _spacecraft != null,
		"has_signal_manager": _signal_manager != null,
		"has_time_manager": _time_manager != null
	}


## Handle button press events
func on_button_pressed(button_name: String) -> void:
	"""Handle cockpit button press events."""
	print("CockpitUI: Button pressed - %s" % button_name)
	activate_control(button_name)


## Update telemetry displays with specific data
func update_telemetry(velocity: Vector3, altitude: float, fuel: float) -> void:
	"""Update telemetry displays with velocity, altitude, and fuel data."""
	# Update internal telemetry data
	_telemetry_data["velocity"] = velocity
	_telemetry_data["altitude"] = altitude
	_telemetry_data["fuel"] = fuel
	
	# Update the displays
	_update_telemetry_displays()
	print("CockpitUI: Updated telemetry - Velocity: %.1f, Altitude: %.1f, Fuel: %.1f" % [velocity.length(), altitude, fuel])


## Handle 3D area entered events for VR interactions
func _on_area_entered(area: Area3D) -> void:
	"""Handle 3D area entered events for VR controller interactions."""
	print("CockpitUI: Area entered - %s" % area.name)
	
	# Check if this is a control area
	for control_name in _controls:
		var control: CockpitControl = _controls[control_name]
		if control.area == area:
			_set_control_hover(control, true)
			control_hovered.emit(control_name)
			break


## Trigger system responses based on system name and response type
func trigger_system_response(system_name: String, response_type: String) -> void:
	"""Trigger system responses based on system name and response type."""
	print("CockpitUI: System response triggered - %s: %s" % [system_name, response_type])
	
	# Map system responses to control activations
	match system_name:
		"propulsion":
			match response_type:
				"engage":
					activate_control("throttle")
				"disengage":
					set_control_value("throttle", 0.0)
		"navigation":
			match response_type:
				"activate":
					activate_control("nav_mode")
				"deactivate":
					set_control_value("nav_mode", 0.0)
		"signal":
			match response_type:
				"boost":
					activate_control("signal_boost")
		"time":
			match response_type:
				"accelerate":
					activate_control("time_accel")


#endregion

#region Cleanup

## Cleanup resources
func shutdown() -> void:
	"""Clean up cockpit UI resources."""
	# Clear controls
	for control_name in _controls:
		var control: CockpitControl = _controls[control_name]
		if control.area != null:
			control.area.queue_free()
	_controls.clear()
	
	# Clear displays
	for display_name in _display_viewports:
		var display_data = _display_viewports[display_name]
		if display_data.has("viewport"):
			display_data["viewport"].queue_free()
		if display_data.has("mesh"):
			display_data["mesh"].queue_free()
	_display_viewports.clear()
	
	# Clear model
	if _cockpit_model != null:
		_cockpit_model.queue_free()
		_cockpit_model = null
	
	_is_initialized = false
	print("CockpitUI: Shutdown complete")

#endregion
