## RenderingSystem - Core Rendering Pipeline Configuration
## Configures Godot's built-in PBR rendering pipeline for Project Resonance.
## Handles lighting, shadows, ambient occlusion, and material management.
##
## Requirements: 1.3 - Use Godot's built-in PBR rendering pipeline
## Requirements: 16.1 - Calculate lighting intensity using inverse square law
## Requirements: 16.2 - Render shadow volumes based on Sun position
## Requirements: 16.3 - Reduce ambient lighting to near-zero in shadow
## Requirements: 16.4 - Apply PBR materials with accurate albedo and roughness
## Requirements: 16.5 - Render penumbra and umbra shadow regions
extends Node
class_name RenderingSystem

## Emitted when the rendering system is fully initialized
signal rendering_initialized
## Emitted when rendering settings change
signal settings_changed(setting_name: String, value: Variant)
## Emitted when a material is created
signal material_created(material_name: String)

## Reference to the world environment node
var world_environment: WorldEnvironment = null
## Reference to the sun directional light
var sun_light: DirectionalLight3D = null
## The environment resource for global settings
var environment: Environment = null

## PBR Material factory for creating consistent materials
var material_factory: PBRMaterialFactory = null

## Rendering quality settings
var _quality_preset: QualityPreset = QualityPreset.HIGH
var _shadow_quality: ShadowQuality = ShadowQuality.HIGH
# SDFGI disabled by default for VR performance (maintains 90 FPS target)
# Ambient lighting is provided through Environment.ambient_light_energy and color
# Optional: Enable via set_quality_preset(QualityPreset.MEDIUM/HIGH/ULTRA)
var _gi_enabled: bool = false  # Disabled for VR performance
var _gi_mode: GIMode = GIMode.NONE  # No GI for optimal VR performance

## Sun light parameters
var _sun_base_intensity: float = 1.0
var _sun_color: Color = Color(1.0, 0.98, 0.95)  # Slightly warm white
var _sun_angular_diameter: float = 0.5  # Degrees (realistic sun size)

## Ambient light parameters
var _ambient_light_energy: float = 0.1
var _ambient_light_color: Color = Color(0.05, 0.05, 0.1)  # Dark blue space ambient

## Quality presets
enum QualityPreset {
	LOW,
	MEDIUM,
	HIGH,
	ULTRA
}

## Shadow quality levels
enum ShadowQuality {
	LOW,
	MEDIUM,
	HIGH,
	ULTRA
}

## Global illumination modes
enum GIMode {
	NONE,
	SDFGI,
	VOXEL_GI
}


func _ready() -> void:
	# Create material factory
	material_factory = PBRMaterialFactory.new()
	add_child(material_factory)


## Initialize the rendering system with a scene root
func initialize(scene_root: Node3D) -> bool:
	if scene_root == null:
		push_error("RenderingSystem: Cannot initialize with null scene root")
		return false
	
	# Find or create WorldEnvironment
	world_environment = _find_or_create_world_environment(scene_root)
	if world_environment == null:
		push_error("RenderingSystem: Failed to create WorldEnvironment")
		return false
	
	# Configure the environment
	_configure_environment()
	
	# Find or create sun light
	sun_light = _find_or_create_sun_light(scene_root)
	if sun_light == null:
		push_error("RenderingSystem: Failed to create sun light")
		return false
	
	# Configure sun light with PBR settings
	_configure_sun_light()
	
	# Configure global illumination
	_configure_global_illumination()
	
	print("RenderingSystem: Initialized successfully")
	rendering_initialized.emit()
	return true


## Update rendering system (called each frame)
func update(delta: float) -> void:
	# Update any dynamic rendering effects here
	pass


## Shutdown and cleanup
func shutdown() -> void:
	print("RenderingSystem: Shutting down")
	# Cleanup resources if needed


## Find existing WorldEnvironment or create a new one
func _find_or_create_world_environment(scene_root: Node3D) -> WorldEnvironment:
	# First, try to find existing WorldEnvironment
	var existing := scene_root.find_child("WorldEnvironment", true, false)
	if existing is WorldEnvironment:
		return existing
	
	# Create new WorldEnvironment
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	scene_root.add_child(world_env)
	
	return world_env


## Find existing DirectionalLight3D (sun) or create a new one
func _find_or_create_sun_light(scene_root: Node3D) -> DirectionalLight3D:
	# First, try to find existing DirectionalLight3D
	var existing := scene_root.find_child("DirectionalLight3D", true, false)
	if existing is DirectionalLight3D:
		return existing
	
	# Also check for a node named "SunLight"
	existing = scene_root.find_child("SunLight", true, false)
	if existing is DirectionalLight3D:
		return existing
	
	# Create new DirectionalLight3D
	var sun := DirectionalLight3D.new()
	sun.name = "SunLight"
	scene_root.add_child(sun)
	
	return sun


## Configure the environment resource with PBR settings
func _configure_environment() -> void:
	# Create new environment if needed
	if world_environment.environment == null:
		environment = Environment.new()
		world_environment.environment = environment
	else:
		environment = world_environment.environment
	
	# Background settings (space is black)
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0, 0, 0, 1)
	
	# Ambient light settings
	# Requirements 16.3: Reduce ambient lighting to near-zero in shadow
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = _ambient_light_color
	environment.ambient_light_energy = _ambient_light_energy
	
	# Tonemap settings for HDR
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	environment.tonemap_white = 1.0
	
	# Glow settings (for emissive materials and stars)
	environment.glow_enabled = true
	environment.glow_intensity = 0.8
	environment.glow_strength = 1.0
	environment.glow_bloom = 0.1
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	environment.glow_hdr_threshold = 1.0
	environment.glow_hdr_scale = 2.0
	
	# Screen-space reflections (DISABLED for VR performance)
	environment.ssr_enabled = false

	# Screen-space ambient occlusion (DISABLED for VR performance)
	environment.ssao_enabled = false

	# SSIL (Screen-Space Indirect Lighting) (DISABLED for VR performance)
	environment.ssil_enabled = false
	
	print("RenderingSystem: Environment configured with PBR settings")


## Configure the sun directional light
## Requirements: 16.1 - Inverse square law (simulated via distance-based intensity)
## Requirements: 16.2 - Shadow volumes based on Sun position
## Requirements: 16.5 - Penumbra and umbra shadow regions
func _configure_sun_light() -> void:
	if sun_light == null:
		return
	
	# Basic light settings
	sun_light.light_color = _sun_color
	sun_light.light_energy = _sun_base_intensity
	sun_light.light_indirect_energy = 1.0
	sun_light.light_volumetric_fog_energy = 1.0
	
	# Angular size for soft shadows (penumbra/umbra)
	# Requirements 16.5: Render penumbra and umbra shadow regions
	sun_light.light_angular_distance = _sun_angular_diameter
	
	# Shadow settings
	# Requirements 16.2: Render shadow volumes based on Sun position
	sun_light.shadow_enabled = true
	sun_light.shadow_bias = 0.03
	sun_light.shadow_normal_bias = 1.0
	sun_light.shadow_opacity = 1.0
	
	# Directional shadow mode for large scenes
	sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun_light.directional_shadow_split_1 = 0.1
	sun_light.directional_shadow_split_2 = 0.2
	sun_light.directional_shadow_split_3 = 0.5
	sun_light.directional_shadow_max_distance = 10000.0
	sun_light.directional_shadow_fade_start = 0.8
	
	# Shadow blur for soft shadows (penumbra effect)
	sun_light.directional_shadow_blend_splits = true
	
	# Apply quality settings
	_apply_shadow_quality()
	
	print("RenderingSystem: Sun light configured with shadow settings")


## Configure global illumination (SDFGI or VoxelGI)
## NOTE: Default is GIMode.NONE for VR performance (90 FPS target)
## SDFGI can be enabled via set_quality_preset() for non-VR or optional high-quality rendering
func _configure_global_illumination() -> void:
	if environment == null:
		return

	match _gi_mode:
		GIMode.SDFGI:
			_configure_sdfgi()
		GIMode.VOXEL_GI:
			# VoxelGI requires a VoxelGI node in the scene
			# We'll just enable the environment settings here
			environment.sdfgi_enabled = false
			print("RenderingSystem: VoxelGI mode - requires VoxelGI node in scene")
		GIMode.NONE:
			environment.sdfgi_enabled = false
			print("RenderingSystem: Global illumination disabled (VR-optimized)")


## Configure SDFGI (Signed Distance Field Global Illumination)
func _configure_sdfgi() -> void:
	if not _gi_enabled:
		environment.sdfgi_enabled = false
		return
	
	environment.sdfgi_enabled = true
	environment.sdfgi_use_occlusion = true
	environment.sdfgi_read_sky_light = true
	environment.sdfgi_bounce_feedback = 0.5
	environment.sdfgi_cascades = 6
	environment.sdfgi_min_cell_size = 0.2
	environment.sdfgi_cascade0_distance = 12.8
	environment.sdfgi_max_distance = 819.2
	environment.sdfgi_y_scale = Environment.SDFGI_Y_SCALE_75_PERCENT
	environment.sdfgi_energy = 1.0
	environment.sdfgi_normal_bias = 1.1
	environment.sdfgi_probe_bias = 1.1
	
	print("RenderingSystem: SDFGI configured for ambient occlusion and indirect lighting")


## Apply shadow quality settings
func _apply_shadow_quality() -> void:
	if sun_light == null:
		return
	
	match _shadow_quality:
		ShadowQuality.LOW:
			# Lower quality shadows for performance
			sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
			sun_light.directional_shadow_max_distance = 2000.0
		ShadowQuality.MEDIUM:
			sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
			sun_light.directional_shadow_max_distance = 5000.0
		ShadowQuality.HIGH:
			sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			sun_light.directional_shadow_max_distance = 10000.0
		ShadowQuality.ULTRA:
			sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			sun_light.directional_shadow_max_distance = 20000.0


## Calculate light intensity using inverse square law
## Requirements: 16.1 - Calculate lighting intensity using inverse square law
## @param base_intensity: The intensity at reference distance (1 AU)
## @param distance: Distance from light source in game units
## @param reference_distance: Reference distance (default 1 AU = 149597870.7 km)
## @return: Calculated intensity at the given distance
static func calculate_inverse_square_intensity(
	base_intensity: float,
	distance: float,
	reference_distance: float = 1.0
) -> float:
	# Prevent division by zero
	var safe_distance := maxf(distance, 0.001)
	# I = I₀ * (d₀/d)²
	var ratio := reference_distance / safe_distance
	return base_intensity * ratio * ratio


## Update sun light intensity based on distance from sun
## This simulates the inverse square law for a moving observer
func update_sun_intensity_for_distance(distance_from_sun: float, reference_distance: float = 1.0) -> void:
	if sun_light == null:
		return
	
	var intensity := calculate_inverse_square_intensity(
		_sun_base_intensity,
		distance_from_sun,
		reference_distance
	)
	sun_light.light_energy = intensity
	settings_changed.emit("sun_intensity", intensity)


## Set the sun direction (for time of day or orbital position)
func set_sun_direction(direction: Vector3) -> void:
	if sun_light == null:
		return
	
	# DirectionalLight3D points in -Z direction by default
	# We need to rotate it to point in the given direction
	sun_light.look_at(sun_light.global_position + direction, Vector3.UP)


## Set the sun position (for calculating direction from a point)
func set_sun_position(sun_pos: Vector3, observer_pos: Vector3 = Vector3.ZERO) -> void:
	var direction := (observer_pos - sun_pos).normalized()
	set_sun_direction(direction)


## Create a PBR material with the given parameters
## Requirements: 16.4 - Apply PBR materials with accurate albedo and roughness
func create_pbr_material(
	albedo: Color = Color.WHITE,
	roughness: float = 0.5,
	metallic: float = 0.0,
	emission: Color = Color.BLACK,
	emission_energy: float = 0.0
) -> StandardMaterial3D:
	return material_factory.create_material(
		albedo, roughness, metallic, emission, emission_energy
	)


## Set quality preset
func set_quality_preset(preset: QualityPreset) -> void:
	_quality_preset = preset
	
	match preset:
		QualityPreset.LOW:
			_shadow_quality = ShadowQuality.LOW
			_gi_enabled = false
			_gi_mode = GIMode.NONE
		QualityPreset.MEDIUM:
			_shadow_quality = ShadowQuality.MEDIUM
			_gi_enabled = true
			_gi_mode = GIMode.SDFGI
		QualityPreset.HIGH:
			_shadow_quality = ShadowQuality.HIGH
			_gi_enabled = true
			_gi_mode = GIMode.SDFGI
		QualityPreset.ULTRA:
			_shadow_quality = ShadowQuality.ULTRA
			_gi_enabled = true
			_gi_mode = GIMode.SDFGI
	
	# Re-apply settings
	_apply_shadow_quality()
	_configure_global_illumination()
	
	settings_changed.emit("quality_preset", preset)


## Set shadow quality
func set_shadow_quality(quality: ShadowQuality) -> void:
	_shadow_quality = quality
	_apply_shadow_quality()
	settings_changed.emit("shadow_quality", quality)


## Enable or disable global illumination
func set_gi_enabled(enabled: bool) -> void:
	_gi_enabled = enabled
	_configure_global_illumination()
	settings_changed.emit("gi_enabled", enabled)


## Set global illumination mode
func set_gi_mode(mode: GIMode) -> void:
	_gi_mode = mode
	_configure_global_illumination()
	settings_changed.emit("gi_mode", mode)


## Get current quality preset
func get_quality_preset() -> QualityPreset:
	return _quality_preset


## Get current shadow quality
func get_shadow_quality() -> ShadowQuality:
	return _shadow_quality


## Check if GI is enabled
func is_gi_enabled() -> bool:
	return _gi_enabled


## Get current GI mode
func get_gi_mode() -> GIMode:
	return _gi_mode


## Get the sun light node
func get_sun_light() -> DirectionalLight3D:
	return sun_light


## Get the world environment node
func get_world_environment() -> WorldEnvironment:
	return world_environment


## Get the environment resource
func get_environment() -> Environment:
	return environment


## Get the material factory
func get_material_factory() -> PBRMaterialFactory:
	return material_factory
