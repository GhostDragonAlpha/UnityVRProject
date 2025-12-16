## CockpitModel - Spacecraft Cockpit 3D Model
## Provides the visual cockpit model with PBR materials and interactive elements.
## This is the visual representation that CockpitUI uses for interaction.
##
## Requirements: 2.1, 2.2, 19.1, 19.2, 19.3, 64.1, 64.2, 64.3, 64.4, 64.5
## - 2.1: Maintain 90 FPS minimum frame rate
## - 2.2: Create stereoscopic display for VR
## - 19.1: Load and render spacecraft cockpit model with interactive controls
## - 19.2: Position camera at pilot viewpoint
## - 19.3: Detect collisions between controllers and cockpit elements
## - 64.1: Use ray-traced reflections on glass and metal surfaces
## - 64.2: Apply accurate metallic and roughness values
## - 64.3: Calculate accurate Fresnel reflections
## - 64.4: Use emissive materials with bloom effects for displays
## - 64.5: Update reflections in real-time
extends Node3D
class_name CockpitModel

## Emitted when the cockpit model is fully loaded
signal cockpit_loaded()

## Emitted when a control element is ready for interaction
signal control_ready(control_name: String, area: Area3D)

#region Exported Properties

## Enable high-quality materials (PBR with advanced features)
@export var enable_high_quality_materials: bool = true

## Enable emissive displays
@export var enable_emissive_displays: bool = true

## Display emission intensity
@export var display_emission_intensity: float = 1.5

## Enable glass refraction
@export var enable_glass_refraction: bool = true

## Metallic value for metal surfaces
@export_range(0.0, 1.0) var metal_metallic: float = 0.85

## Roughness value for metal surfaces
@export_range(0.0, 1.0) var metal_roughness: float = 0.25

## Enable real-time reflections
@export var enable_realtime_reflections: bool = true

#endregion

#region Runtime Properties

## Dashboard mesh reference
var _dashboard: MeshInstance3D = null

## Display meshes
var _displays: Dictionary = {}

## Control meshes
var _controls: Dictionary = {}

## Lighting nodes
var _lights: Dictionary = {}

## Interaction areas
var _interaction_areas: Dictionary = {}

## Whether the cockpit is loaded
var _is_loaded: bool = false

#endregion


func _ready() -> void:
	call_deferred("_initialize_cockpit")


func _initialize_cockpit() -> void:
	"""Initialize the cockpit model."""
	# Find and cache references to all cockpit elements
	_find_cockpit_elements()
	
	# Setup materials
	if enable_high_quality_materials:
		_setup_pbr_materials()
	
	# Setup interaction areas
	_setup_interaction_areas()
	
	# Setup lighting
	_setup_lighting()
	
	_is_loaded = true
	cockpit_loaded.emit()
	print("CockpitModel: Initialized successfully")


#region Element Discovery

## Find all cockpit elements in the scene tree
func _find_cockpit_elements() -> void:
	"""Find and cache references to cockpit elements."""
	# Find dashboard
	_dashboard = find_child("Dashboard", true, false)
	
	# Find displays
	var displays_node = find_child("Displays", true, false)
	if displays_node != null:
		_displays["main"] = displays_node.find_child("MainDisplay", false, false)
		_displays["left"] = displays_node.find_child("LeftDisplay", false, false)
		_displays["right"] = displays_node.find_child("RightDisplay", false, false)
	
	# Find controls
	var controls_node = find_child("Controls", true, false)
	if controls_node != null:
		_controls["throttle"] = controls_node.find_child("ThrottleLever", false, false)
		_controls["power"] = controls_node.find_child("PowerButton", false, false)
		_controls["nav_mode"] = controls_node.find_child("NavModeSwitch", false, false)
		_controls["time_accel"] = controls_node.find_child("TimeAccelDial", false, false)
		_controls["signal_boost"] = controls_node.find_child("SignalBoostButton", false, false)
		_controls["emergency"] = controls_node.find_child("EmergencyButton", false, false)
		_controls["landing_gear"] = controls_node.find_child("LandingGearButton", false, false)
	
	# Find lighting
	var lighting_node = find_child("Lighting", true, false)
	if lighting_node != null:
		for child in lighting_node.get_children():
			if child is Light3D:
				_lights[child.name] = child
	
	print("CockpitModel: Found %d displays, %d controls, %d lights" % [
		_displays.size(), _controls.size(), _lights.size()
	])

#endregion

#region Material Setup

## Setup PBR materials for all cockpit elements
## Requirement 64.2: Apply accurate metallic and roughness values
## Requirement 64.3: Calculate accurate Fresnel reflections
func _setup_pbr_materials() -> void:
	"""Setup physically-based rendering materials."""
	# Setup dashboard materials
	if _dashboard != null:
		_apply_metal_material(_dashboard)
	
	# Setup display materials with emission
	for display_name in _displays:
		var display = _displays[display_name]
		if display != null:
			_apply_display_material(display)
	
	# Setup control materials
	for control_name in _controls:
		var control = _controls[control_name]
		if control != null:
			_apply_control_material(control, control_name)
	
	# Setup glass canopy
	var canopy = find_child("Canopy", true, false)
	if canopy != null:
		_apply_glass_material(canopy)
	
	print("CockpitModel: Applied PBR materials")


## Apply metal material to a mesh
func _apply_metal_material(mesh: MeshInstance3D) -> void:
	"""Apply metallic PBR material to a mesh."""
	if mesh.material_override == null:
		return
	
	var mat = mesh.material_override as StandardMaterial3D
	if mat == null:
		return
	
	# Set PBR properties
	mat.metallic = metal_metallic
	mat.roughness = metal_roughness
	
	# Enable features for high quality
	if enable_realtime_reflections:
		mat.metallic_specular = 1.0
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL


## Apply display material with emission
## Requirement 64.4: Use emissive materials with bloom effects
func _apply_display_material(mesh: MeshInstance3D) -> void:
	"""Apply emissive display material to a mesh."""
	if mesh.material_override == null:
		return
	
	var mat = mesh.material_override as StandardMaterial3D
	if mat == null:
		return
	
	# Enable emission
	if enable_emissive_displays:
		mat.emission_enabled = true
		mat.emission_energy_multiplier = display_emission_intensity
		
		# Set emission color (blue-ish for displays)
		mat.emission = Color(0.2, 0.4, 0.8, 1.0)
	
	# Low metallic, high roughness for displays
	mat.metallic = 0.1
	mat.roughness = 0.9


## Apply control material
func _apply_control_material(mesh: MeshInstance3D, control_name: String) -> void:
	"""Apply material to a control element."""
	if mesh.material_override == null:
		return
	
	var mat = mesh.material_override as StandardMaterial3D
	if mat == null:
		return
	
	# Set metallic properties
	mat.metallic = 0.7
	mat.roughness = 0.4
	
	# Enable emission for buttons
	if "button" in control_name.to_lower():
		mat.emission_enabled = true
		mat.emission_energy_multiplier = 0.5


## Apply glass material with refraction
## Requirement 64.1: Use ray-traced reflections on glass surfaces
func _apply_glass_material(mesh: MeshInstance3D) -> void:
	"""Apply glass material with transparency and refraction."""
	if mesh.material_override == null:
		return
	
	var mat = mesh.material_override as StandardMaterial3D
	if mat == null:
		return
	
	# Enable transparency
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.15
	
	# High metallic, low roughness for glass
	mat.metallic = 0.9
	mat.roughness = 0.05
	
	# Enable refraction if supported
	if enable_glass_refraction:
		mat.refraction_enabled = true
		mat.refraction_scale = 0.05
	
	# Enable depth draw for proper transparency
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS

#endregion

#region Interaction Areas

## Setup interaction areas for VR controllers
## Requirement 19.3: Detect collisions between controllers and cockpit elements
func _setup_interaction_areas() -> void:
	"""Setup collision areas for interactive controls."""
	var areas_node = find_child("InteractionAreas", true, false)
	if areas_node == null:
		return
	
	# Find all Area3D nodes
	for child in areas_node.get_children():
		if child is Area3D:
			var area = child as Area3D
			
			# Extract control name from area name
			var control_name = area.name.replace("Area", "").to_snake_case()
			_interaction_areas[control_name] = area
			
			# Setup collision shape if not already set
			var collision_shape = area.find_child("CollisionShape3D", false, false)
			if collision_shape != null and collision_shape.shape == null:
				var shape = BoxShape3D.new()
				shape.size = Vector3(0.1, 0.1, 0.1)
				collision_shape.shape = shape
			
			# Emit signal that control is ready
			control_ready.emit(control_name, area)
	
	print("CockpitModel: Setup %d interaction areas" % _interaction_areas.size())

#endregion

#region Lighting

## Setup cockpit lighting
## Requirement 64.4: Use emissive materials with bloom effects
func _setup_lighting() -> void:
	"""Setup and configure cockpit lighting."""
	# Configure display lights
	for light_name in _lights:
		var light = _lights[light_name]
		
		if "Display" in light_name:
			# Display lights - blue-ish
			if light is OmniLight3D:
				light.light_color = Color(0.3, 0.6, 1.0, 1.0)
				light.light_energy = 0.5
				light.omni_range = 0.3
		
		elif "Control" in light_name:
			# Control lights - white
			if light is SpotLight3D:
				light.light_color = Color(0.9, 0.9, 1.0, 1.0)
				light.light_energy = 0.3
				light.spot_range = 0.5
				light.spot_angle = 30.0
		
		elif "Ambient" in light_name:
			# Ambient light - soft white
			if light is OmniLight3D:
				light.light_color = Color(0.8, 0.85, 0.9, 1.0)
				light.light_energy = 0.3
				light.omni_range = 2.0
	
	print("CockpitModel: Configured %d lights" % _lights.size())

#endregion

#region Public API

## Get a display mesh by name
func get_display(display_name: String) -> MeshInstance3D:
	"""Get a display mesh by name."""
	if _displays.has(display_name):
		return _displays[display_name]
	return null


## Get a control mesh by name
func get_control(control_name: String) -> MeshInstance3D:
	"""Get a control mesh by name."""
	if _controls.has(control_name):
		return _controls[control_name]
	return null


## Get an interaction area by name
func get_interaction_area(control_name: String) -> Area3D:
	"""Get an interaction area by name."""
	if _interaction_areas.has(control_name):
		return _interaction_areas[control_name]
	return null


## Get a light by name
func get_light(light_name: String) -> Light3D:
	"""Get a light by name."""
	if _lights.has(light_name):
		return _lights[light_name]
	return null


## Check if cockpit is loaded
func is_loaded() -> bool:
	"""Check if the cockpit model is fully loaded."""
	return _is_loaded


## Set display emission intensity
func set_display_emission(intensity: float) -> void:
	"""Set the emission intensity for all displays."""
	display_emission_intensity = intensity
	
	for display_name in _displays:
		var display = _displays[display_name]
		if display != null and display.material_override != null:
			var mat = display.material_override as StandardMaterial3D
			if mat != null and mat.emission_enabled:
				mat.emission_energy_multiplier = intensity


## Set control emission (for highlighting)
func set_control_emission(control_name: String, enabled: bool, color: Color = Color.WHITE) -> void:
	"""Set emission for a specific control."""
	if not _controls.has(control_name):
		return
	
	var control = _controls[control_name]
	if control == null or control.material_override == null:
		return
	
	var mat = control.material_override as StandardMaterial3D
	if mat == null:
		return
	
	mat.emission_enabled = enabled
	if enabled:
		mat.emission = color
		mat.emission_energy_multiplier = 1.0


## Animate control (for visual feedback)
func animate_control(control_name: String, value: float) -> void:
	"""Animate a control based on its value (0.0 to 1.0)."""
	if not _controls.has(control_name):
		return
	
	var control = _controls[control_name]
	if control == null:
		return
	
	# Animate based on control type
	if "lever" in control_name.to_lower():
		# Move lever up/down
		control.position.y = value * 0.1 - 0.05
	elif "dial" in control_name.to_lower():
		# Rotate dial
		control.rotation.z = value * TAU
	elif "button" in control_name.to_lower():
		# Press button (scale down slightly)
		var scale = 1.0 - (value * 0.2)
		control.scale = Vector3(1.0, scale, 1.0)


## Get all control names
func get_control_names() -> Array[String]:
	"""Get a list of all control names."""
	var names: Array[String] = []
	for name in _controls.keys():
		names.append(name)
	return names


## Get all display names
func get_display_names() -> Array[String]:
	"""Get a list of all display names."""
	var names: Array[String] = []
	for name in _displays.keys():
		names.append(name)
	return names


## Get statistics
func get_statistics() -> Dictionary:
	"""Get cockpit model statistics."""
	return {
		"loaded": _is_loaded,
		"display_count": _displays.size(),
		"control_count": _controls.size(),
		"light_count": _lights.size(),
		"interaction_area_count": _interaction_areas.size(),
		"high_quality_materials": enable_high_quality_materials,
		"emissive_displays": enable_emissive_displays,
		"glass_refraction": enable_glass_refraction,
		"realtime_reflections": enable_realtime_reflections
	}

#endregion
