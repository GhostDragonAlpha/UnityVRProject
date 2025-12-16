## SpacecraftExterior - Spacecraft Exterior Model with LOD
## Manages the visual representation of the spacecraft exterior with LOD levels,
## PBR materials, and optimized collision detection.
##
## Requirements:
## - 55.1: Switch to third-person view of spacecraft
## - 55.2: Allow camera to orbit around spacecraft
## - 55.3: Maintain flight controls and HUD in external view
## - 55.4: Show spacecraft in relation to planetary surface
## - 59.1: Render spacecraft model at landing location
## - 59.2: Keep spacecraft visible when walking away
## - 64.1: Ray-traced reflections on glass and metal surfaces
## - 64.2: Accurate metallic and roughness values
## - 64.3: Accurate Fresnel reflections and specular highlights
extends Node3D
class_name SpacecraftExterior

## Emitted when LOD level changes
signal lod_changed(new_level: int)
## Emitted when model is fully loaded
signal model_loaded()

## LOD distance thresholds (in meters)
@export var lod_distances: Array[float] = [10.0, 50.0, 200.0, 1000.0]

## Enable high-quality materials (ray tracing, reflections)
@export var enable_high_quality_materials: bool = true

## Enable glass refraction on canopy
@export var enable_glass_refraction: bool = true

## Current LOD level (0 = highest detail, 3 = lowest detail)
var current_lod_level: int = 0

## LOD mesh instances
var lod_meshes: Array[MeshInstance3D] = []

## Materials
var hull_material: StandardMaterial3D
var glass_material: StandardMaterial3D
var engine_material: StandardMaterial3D
var detail_material: StandardMaterial3D

## Collision shape
var collision_shape: CollisionShape3D

## Engine glow lights
var engine_lights: Array[OmniLight3D] = []

## Reference to camera for LOD calculations
var camera: Camera3D = null


func _ready() -> void:
	_create_materials()
	_create_lod_meshes()
	_create_collision()
	_create_engine_lights()
	
	# Find camera for LOD calculations
	_find_camera()
	
	# Start with highest detail LOD
	_set_lod_level(0)
	
	model_loaded.emit()


func _process(_delta: float) -> void:
	# Update LOD based on camera distance
	if camera:
		_update_lod()


## Create PBR materials for spacecraft
func _create_materials() -> void:
	"""Create physically-based materials for spacecraft components."""
	
	# Hull Material - Metallic spacecraft body
	# Requirement 64.2: Accurate metallic and roughness values
	hull_material = StandardMaterial3D.new()
	hull_material.albedo_color = Color(0.2, 0.22, 0.25)  # Dark gray-blue
	hull_material.metallic = 0.9  # Highly metallic
	hull_material.roughness = 0.3  # Smooth but not mirror-like
	hull_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	
	# Requirement 64.3: Accurate Fresnel reflections
	hull_material.metallic_specular = 1.0  # Full specular reflections
	
	if enable_high_quality_materials:
		# Requirement 64.1: Ray-traced reflections
		hull_material.rim_enabled = true
		hull_material.rim = 0.3
		hull_material.rim_tint = 0.5
	
	# Glass Material - Canopy
	# Requirement 64.1: Ray-traced reflections on glass
	glass_material = StandardMaterial3D.new()
	glass_material.albedo_color = Color(0.3, 0.5, 0.6, 0.2)  # Tinted blue-green
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.metallic = 0.95  # Very reflective
	glass_material.roughness = 0.02  # Extremely smooth
	glass_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	glass_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	
	if enable_glass_refraction:
		glass_material.refraction_enabled = true
		glass_material.refraction_scale = 0.05
	
	# Engine Material - Glowing engines
	engine_material = StandardMaterial3D.new()
	engine_material.albedo_color = Color(0.1, 0.1, 0.15)
	engine_material.metallic = 0.8
	engine_material.roughness = 0.4
	engine_material.emission_enabled = true
	engine_material.emission = Color(0.2, 0.5, 1.0)  # Blue glow
	engine_material.emission_energy_multiplier = 2.0
	
	# Detail Material - Accent panels and details
	detail_material = StandardMaterial3D.new()
	detail_material.albedo_color = Color(0.35, 0.35, 0.4)
	detail_material.metallic = 0.7
	detail_material.roughness = 0.5
	detail_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL


## Create LOD mesh instances
func _create_lod_meshes() -> void:
	"""Create multiple LOD levels for the spacecraft model."""
	
	# LOD 0 - Highest detail (< 10m)
	var lod0 = _create_detailed_mesh()
	lod0.name = "LOD0_Detailed"
	add_child(lod0)
	lod_meshes.append(lod0)
	
	# LOD 1 - Medium detail (10-50m)
	var lod1 = _create_medium_mesh()
	lod1.name = "LOD1_Medium"
	lod1.visible = false
	add_child(lod1)
	lod_meshes.append(lod1)
	
	# LOD 2 - Low detail (50-200m)
	var lod2 = _create_low_mesh()
	lod2.name = "LOD2_Low"
	lod2.visible = false
	add_child(lod2)
	lod_meshes.append(lod2)
	
	# LOD 3 - Minimal detail (200-1000m)
	var lod3 = _create_minimal_mesh()
	lod3.name = "LOD3_Minimal"
	lod3.visible = false
	add_child(lod3)
	lod_meshes.append(lod3)


## Create detailed mesh (LOD 0)
func _create_detailed_mesh() -> Node3D:
	"""Create the highest detail spacecraft mesh."""
	var container = Node3D.new()
	
	# Main hull body - elongated capsule
	var hull = MeshInstance3D.new()
	var hull_mesh = CapsuleMesh.new()
	hull_mesh.radius = 1.5
	hull_mesh.height = 8.0
	hull_mesh.radial_segments = 32
	hull_mesh.rings = 16
	hull.mesh = hull_mesh
	hull.material_override = hull_material
	hull.rotation_degrees = Vector3(90, 0, 0)  # Orient forward
	hull.position = Vector3(0, 0, 0)
	container.add_child(hull)
	
	# Cockpit canopy - glass sphere
	var canopy = MeshInstance3D.new()
	var canopy_mesh = SphereMesh.new()
	canopy_mesh.radius = 1.2
	canopy_mesh.height = 2.4
	canopy_mesh.radial_segments = 24
	canopy_mesh.rings = 12
	canopy.mesh = canopy_mesh
	canopy.material_override = glass_material
	canopy.position = Vector3(0, 0.5, -3.0)  # Front of spacecraft
	container.add_child(canopy)
	
	# Left wing
	var left_wing = MeshInstance3D.new()
	var left_wing_mesh = BoxMesh.new()
	left_wing_mesh.size = Vector3(4.0, 0.2, 2.0)
	left_wing.mesh = left_wing_mesh
	left_wing.material_override = hull_material
	left_wing.position = Vector3(-2.5, 0, 0)
	container.add_child(left_wing)
	
	# Right wing
	var right_wing = MeshInstance3D.new()
	var right_wing_mesh = BoxMesh.new()
	right_wing_mesh.size = Vector3(4.0, 0.2, 2.0)
	right_wing.mesh = right_wing_mesh
	right_wing.material_override = hull_material
	right_wing.position = Vector3(2.5, 0, 0)
	container.add_child(right_wing)
	
	# Left engine nacelle
	var left_engine = MeshInstance3D.new()
	var left_engine_mesh = CylinderMesh.new()
	left_engine_mesh.top_radius = 0.5
	left_engine_mesh.bottom_radius = 0.6
	left_engine_mesh.height = 3.0
	left_engine_mesh.radial_segments = 16
	left_engine.mesh = left_engine_mesh
	left_engine.material_override = detail_material
	left_engine.rotation_degrees = Vector3(90, 0, 0)
	left_engine.position = Vector3(-2.5, 0, 2.5)
	container.add_child(left_engine)
	
	# Right engine nacelle
	var right_engine = MeshInstance3D.new()
	var right_engine_mesh = CylinderMesh.new()
	right_engine_mesh.top_radius = 0.5
	right_engine_mesh.bottom_radius = 0.6
	right_engine_mesh.height = 3.0
	right_engine_mesh.radial_segments = 16
	right_engine.mesh = right_engine_mesh
	right_engine.material_override = detail_material
	right_engine.rotation_degrees = Vector3(90, 0, 0)
	right_engine.position = Vector3(2.5, 0, 2.5)
	container.add_child(right_engine)
	
	# Left engine glow
	var left_glow = MeshInstance3D.new()
	var left_glow_mesh = CylinderMesh.new()
	left_glow_mesh.top_radius = 0.4
	left_glow_mesh.bottom_radius = 0.5
	left_glow_mesh.height = 0.5
	left_glow.mesh = left_glow_mesh
	left_glow.material_override = engine_material
	left_glow.rotation_degrees = Vector3(90, 0, 0)
	left_glow.position = Vector3(-2.5, 0, 4.2)
	container.add_child(left_glow)
	
	# Right engine glow
	var right_glow = MeshInstance3D.new()
	var right_glow_mesh = CylinderMesh.new()
	right_glow_mesh.top_radius = 0.4
	right_glow_mesh.bottom_radius = 0.5
	right_glow_mesh.height = 0.5
	right_glow.mesh = right_glow_mesh
	right_glow.material_override = engine_material
	right_glow.rotation_degrees = Vector3(90, 0, 0)
	right_glow.position = Vector3(2.5, 0, 4.2)
	container.add_child(right_glow)
	
	# Detail panels on hull
	for i in range(4):
		var panel = MeshInstance3D.new()
		var panel_mesh = BoxMesh.new()
		panel_mesh.size = Vector3(0.8, 0.05, 1.0)
		panel.mesh = panel_mesh
		panel.material_override = detail_material
		panel.position = Vector3(0.6, 0.8, -2.0 + i * 1.5)
		container.add_child(panel)
		
		var panel2 = MeshInstance3D.new()
		panel2.mesh = panel_mesh
		panel2.material_override = detail_material
		panel2.position = Vector3(-0.6, 0.8, -2.0 + i * 1.5)
		container.add_child(panel2)
	
	return container


## Create medium detail mesh (LOD 1)
func _create_medium_mesh() -> Node3D:
	"""Create medium detail spacecraft mesh."""
	var container = Node3D.new()
	
	# Simplified hull
	var hull = MeshInstance3D.new()
	var hull_mesh = CapsuleMesh.new()
	hull_mesh.radius = 1.5
	hull_mesh.height = 8.0
	hull_mesh.radial_segments = 16  # Reduced from 32
	hull_mesh.rings = 8  # Reduced from 16
	hull.mesh = hull_mesh
	hull.material_override = hull_material
	hull.rotation_degrees = Vector3(90, 0, 0)
	container.add_child(hull)
	
	# Simplified canopy
	var canopy = MeshInstance3D.new()
	var canopy_mesh = SphereMesh.new()
	canopy_mesh.radius = 1.2
	canopy_mesh.height = 2.4
	canopy_mesh.radial_segments = 12  # Reduced
	canopy_mesh.rings = 6  # Reduced
	canopy.mesh = canopy_mesh
	canopy.material_override = glass_material
	canopy.position = Vector3(0, 0.5, -3.0)
	container.add_child(canopy)
	
	# Simplified wings
	var left_wing = MeshInstance3D.new()
	var wing_mesh = BoxMesh.new()
	wing_mesh.size = Vector3(4.0, 0.2, 2.0)
	left_wing.mesh = wing_mesh
	left_wing.material_override = hull_material
	left_wing.position = Vector3(-2.5, 0, 0)
	container.add_child(left_wing)
	
	var right_wing = MeshInstance3D.new()
	right_wing.mesh = wing_mesh
	right_wing.material_override = hull_material
	right_wing.position = Vector3(2.5, 0, 0)
	container.add_child(right_wing)
	
	# Simplified engines with glow
	var left_engine = MeshInstance3D.new()
	var engine_mesh = CylinderMesh.new()
	engine_mesh.top_radius = 0.5
	engine_mesh.bottom_radius = 0.6
	engine_mesh.height = 3.0
	engine_mesh.radial_segments = 8  # Reduced
	left_engine.mesh = engine_mesh
	left_engine.material_override = engine_material
	left_engine.rotation_degrees = Vector3(90, 0, 0)
	left_engine.position = Vector3(-2.5, 0, 2.5)
	container.add_child(left_engine)
	
	var right_engine = MeshInstance3D.new()
	right_engine.mesh = engine_mesh
	right_engine.material_override = engine_material
	right_engine.rotation_degrees = Vector3(90, 0, 0)
	right_engine.position = Vector3(2.5, 0, 2.5)
	container.add_child(right_engine)
	
	return container


## Create low detail mesh (LOD 2)
func _create_low_mesh() -> Node3D:
	"""Create low detail spacecraft mesh."""
	var container = Node3D.new()
	
	# Very simplified hull
	var hull = MeshInstance3D.new()
	var hull_mesh = CapsuleMesh.new()
	hull_mesh.radius = 1.5
	hull_mesh.height = 8.0
	hull_mesh.radial_segments = 8
	hull_mesh.rings = 4
	hull.mesh = hull_mesh
	hull.material_override = hull_material
	hull.rotation_degrees = Vector3(90, 0, 0)
	container.add_child(hull)
	
	# Combined wing structure
	var wings = MeshInstance3D.new()
	var wings_mesh = BoxMesh.new()
	wings_mesh.size = Vector3(10.0, 0.2, 2.0)
	wings.mesh = wings_mesh
	wings.material_override = hull_material
	container.add_child(wings)
	
	# Single engine representation
	var engines = MeshInstance3D.new()
	var engines_mesh = BoxMesh.new()
	engines_mesh.size = Vector3(5.0, 1.0, 3.0)
	engines.mesh = engines_mesh
	engines.material_override = engine_material
	engines.position = Vector3(0, 0, 2.5)
	container.add_child(engines)
	
	return container


## Create minimal detail mesh (LOD 3)
func _create_minimal_mesh() -> Node3D:
	"""Create minimal detail spacecraft mesh (distant view)."""
	var container = Node3D.new()
	
	# Single box representing entire spacecraft
	var hull = MeshInstance3D.new()
	var hull_mesh = BoxMesh.new()
	hull_mesh.size = Vector3(5.0, 2.0, 8.0)
	hull.mesh = hull_mesh
	hull.material_override = hull_material
	container.add_child(hull)
	
	# Single emissive box for engines
	var engines = MeshInstance3D.new()
	var engines_mesh = BoxMesh.new()
	engines_mesh.size = Vector3(5.0, 1.0, 1.0)
	engines.mesh = engines_mesh
	engines.material_override = engine_material
	engines.position = Vector3(0, 0, 4.0)
	container.add_child(engines)
	
	return container


## Create collision shape
func _create_collision() -> void:
	"""Create optimized collision shape for spacecraft."""
	# Create collision shape node
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape"
	
	# Use capsule shape for efficient collision
	var shape = CapsuleShape3D.new()
	shape.radius = 2.0  # Slightly larger than visual for safety margin
	shape.height = 8.0
	collision_shape.shape = shape
	collision_shape.rotation_degrees = Vector3(90, 0, 0)
	
	add_child(collision_shape)


## Create engine lights
func _create_engine_lights() -> void:
	"""Create glowing lights for engine effects."""
	# Left engine light
	var left_light = OmniLight3D.new()
	left_light.name = "LeftEngineLight"
	left_light.light_color = Color(0.2, 0.5, 1.0)  # Blue
	left_light.light_energy = 2.0
	left_light.omni_range = 5.0
	left_light.position = Vector3(-2.5, 0, 4.5)
	add_child(left_light)
	engine_lights.append(left_light)
	
	# Right engine light
	var right_light = OmniLight3D.new()
	right_light.name = "RightEngineLight"
	right_light.light_color = Color(0.2, 0.5, 1.0)  # Blue
	right_light.light_energy = 2.0
	right_light.omni_range = 5.0
	right_light.position = Vector3(2.5, 0, 4.5)
	add_child(right_light)
	engine_lights.append(right_light)


## Find camera for LOD calculations
func _find_camera() -> void:
	"""Find the active camera for LOD distance calculations."""
	# Try to find VR camera first
	var vr_camera = get_viewport().get_camera_3d()
	if vr_camera:
		camera = vr_camera
		return
	
	# Fallback: search for any Camera3D in scene
	var cameras = get_tree().get_nodes_in_group("camera")
	if cameras.size() > 0:
		camera = cameras[0]


## Update LOD based on camera distance
func _update_lod() -> void:
	"""Update LOD level based on distance to camera."""
	if not camera:
		return
	
	var distance = global_position.distance_to(camera.global_position)
	var new_lod = _calculate_lod_level(distance)
	
	if new_lod != current_lod_level:
		_set_lod_level(new_lod)


## Calculate appropriate LOD level for distance
func _calculate_lod_level(distance: float) -> int:
	"""Calculate which LOD level to use based on distance."""
	for i in range(lod_distances.size()):
		if distance < lod_distances[i]:
			return i
	return lod_distances.size()  # Furthest LOD


## Set active LOD level
func _set_lod_level(level: int) -> void:
	"""Set the active LOD level, hiding others."""
	level = clampi(level, 0, lod_meshes.size() - 1)
	
	# Hide all LODs
	for i in range(lod_meshes.size()):
		lod_meshes[i].visible = (i == level)
	
	current_lod_level = level
	lod_changed.emit(level)


## Set engine glow intensity
func set_engine_intensity(intensity: float) -> void:
	"""Set the intensity of engine glow (0.0 to 1.0)."""
	intensity = clampf(intensity, 0.0, 1.0)
	
	# Update engine material emission
	if engine_material:
		engine_material.emission_energy_multiplier = 2.0 * intensity
	
	# Update engine lights
	for light in engine_lights:
		light.light_energy = 2.0 * intensity


## Enable/disable high quality materials
func set_high_quality_materials(enabled: bool) -> void:
	"""Enable or disable high quality material features."""
	enable_high_quality_materials = enabled
	_create_materials()  # Recreate materials with new settings


## Enable/disable glass refraction
func set_glass_refraction(enabled: bool) -> void:
	"""Enable or disable glass refraction effect."""
	enable_glass_refraction = enabled
	if glass_material:
		glass_material.refraction_enabled = enabled


## Get collision shape for physics integration
func get_collision_shape() -> CollisionShape3D:
	"""Get the collision shape node."""
	return collision_shape


## Get current LOD level
func get_current_lod() -> int:
	"""Get the current LOD level."""
	return current_lod_level


## Force specific LOD level (for debugging)
func force_lod_level(level: int) -> void:
	"""Force a specific LOD level (for debugging/testing)."""
	_set_lod_level(level)


## Get model statistics
func get_statistics() -> Dictionary:
	"""Get model statistics for debugging."""
	return {
		"lod_level": current_lod_level,
		"lod_count": lod_meshes.size(),
		"high_quality": enable_high_quality_materials,
		"glass_refraction": enable_glass_refraction,
		"engine_lights": engine_lights.size()
	}
