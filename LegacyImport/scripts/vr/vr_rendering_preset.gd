extends Node
class_name VRRenderingPreset

## VR Rendering Preset Manager
## Applies VR-optimized rendering settings at runtime
##
## Usage:
##   var preset = VRRenderingPreset.new()
##   add_child(preset)
##   preset.apply_preset(VRRenderingPreset.PresetLevel.RECOMMENDED)
##
## See: docs/VR_RENDERING_OPTIMIZATION.md for detailed documentation

signal preset_applied(preset_level: PresetLevel)

enum PresetLevel {
	HIGH_PERFORMANCE,  # Guaranteed 90 FPS (minimal quality)
	RECOMMENDED,       # Balanced quality/performance (target 90 FPS)
	HIGH_QUALITY       # Best quality (may drop below 90 FPS on lower-end hardware)
}

var current_preset: PresetLevel = PresetLevel.RECOMMENDED
var rendering_system: RenderingSystem = null


func _ready() -> void:
	# Get rendering system reference from ResonanceEngine
	var engine = get_node_or_null("/root/ResonanceEngine")
	if engine and engine.has_method("get_subsystem"):
		rendering_system = engine.get_subsystem("RenderingSystem")

	if rendering_system == null:
		push_warning("VRRenderingPreset: RenderingSystem not found, some settings may not apply")


## Apply VR rendering preset
## @param preset: PresetLevel to apply (HIGH_PERFORMANCE, RECOMMENDED, HIGH_QUALITY)
func apply_preset(preset: PresetLevel) -> void:
	current_preset = preset

	match preset:
		PresetLevel.HIGH_PERFORMANCE:
			_apply_high_performance()
		PresetLevel.RECOMMENDED:
			_apply_recommended()
		PresetLevel.HIGH_QUALITY:
			_apply_high_quality()

	print("VRRenderingPreset: Applied %s preset" % _preset_name(preset))
	preset_applied.emit(preset)


## High-performance preset (guaranteed 90 FPS)
## Minimal quality settings for maximum performance
func _apply_high_performance() -> void:
	print("VRRenderingPreset: Applying HIGH_PERFORMANCE preset...")

	# Shadow settings - minimal quality
	_set_project_setting("rendering/lights_and_shadows/directional_shadow/size", 2048)
	_set_project_setting("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality", 0)
	_set_project_setting("rendering/lights_and_shadows/positional_shadow/atlas_size", 2048)
	_set_project_setting("rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality", 0)

	# AA settings - MSAA 1x for performance
	_set_project_setting("rendering/anti_aliasing/quality/msaa_3d", 1)
	_set_project_setting("rendering/anti_aliasing/quality/screen_space_aa", 0)

	# LOD settings - aggressive transitions
	_set_project_setting("rendering/mesh_lod/lod_change/threshold_pixels", 2.0)

	# Anisotropic filtering - minimal
	_set_project_setting("rendering/textures/default_filters/anisotropic_filtering_level", 1)

	# Environment settings
	if rendering_system and rendering_system.environment:
		var env = rendering_system.environment
		env.glow_enabled = false  # Disable glow for max performance
		env.volumetric_fog_enabled = false
		env.ssao_enabled = false
		env.ssil_enabled = false
		env.ssr_enabled = false
		env.sdfgi_enabled = false
		env.adjustment_enabled = false

	# Sun light settings
	if rendering_system and rendering_system.sun_light:
		var sun = rendering_system.sun_light
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		sun.directional_shadow_max_distance = 2000.0
		sun.light_angular_distance = 0.0  # Hard shadows (no penumbra)
		sun.shadow_bias = 0.05


## Recommended VR preset (balanced quality/performance)
## Target 90 FPS with good visual quality
func _apply_recommended() -> void:
	print("VRRenderingPreset: Applying RECOMMENDED preset...")

	# Shadow settings - moderate quality
	_set_project_setting("rendering/lights_and_shadows/directional_shadow/size", 4096)
	_set_project_setting("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality", 1)
	_set_project_setting("rendering/lights_and_shadows/positional_shadow/atlas_size", 4096)
	_set_project_setting("rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality", 1)

	# AA settings - MSAA 2x (industry standard for VR)
	_set_project_setting("rendering/anti_aliasing/quality/msaa_3d", 2)
	_set_project_setting("rendering/anti_aliasing/quality/screen_space_aa", 0)

	# LOD settings - balanced
	_set_project_setting("rendering/mesh_lod/lod_change/threshold_pixels", 1.0)

	# Anisotropic filtering - moderate
	_set_project_setting("rendering/textures/default_filters/anisotropic_filtering_level", 2)

	# Environment settings
	if rendering_system and rendering_system.environment:
		var env = rendering_system.environment
		env.glow_enabled = true
		env.glow_intensity = 0.6  # Reduced from 0.8
		env.glow_strength = 0.8   # Reduced from 1.0
		env.glow_hdr_threshold = 1.2  # Increased from 1.0
		env.volumetric_fog_enabled = false
		env.ssao_enabled = false
		env.ssil_enabled = false
		env.ssr_enabled = false
		env.sdfgi_enabled = false

	# Sun light settings
	if rendering_system and rendering_system.sun_light:
		var sun = rendering_system.sun_light
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		sun.directional_shadow_max_distance = 5000.0
		sun.light_angular_distance = 0.25  # Subtle penumbra
		sun.shadow_bias = 0.05


## High-quality VR preset (desktop VR with high-end GPU)
## Best visual quality, may not maintain 90 FPS on lower-end hardware
func _apply_high_quality() -> void:
	print("VRRenderingPreset: Applying HIGH_QUALITY preset...")

	# Shadow settings - high quality
	_set_project_setting("rendering/lights_and_shadows/directional_shadow/size", 8192)
	_set_project_setting("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality", 2)
	_set_project_setting("rendering/lights_and_shadows/positional_shadow/atlas_size", 8192)
	_set_project_setting("rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality", 2)

	# AA settings - MSAA 4x for maximum quality
	_set_project_setting("rendering/anti_aliasing/quality/msaa_3d", 3)
	_set_project_setting("rendering/anti_aliasing/quality/screen_space_aa", 0)

	# LOD settings - less aggressive
	_set_project_setting("rendering/mesh_lod/lod_change/threshold_pixels", 0.5)

	# Anisotropic filtering - high quality
	_set_project_setting("rendering/textures/default_filters/anisotropic_filtering_level", 4)

	# Environment settings
	if rendering_system and rendering_system.environment:
		var env = rendering_system.environment
		env.glow_enabled = true
		env.glow_intensity = 0.8
		env.glow_strength = 1.0
		env.glow_hdr_threshold = 1.0
		env.volumetric_fog_enabled = false  # Still disabled for VR

		# Optional SSAO for high-quality mode
		env.ssao_enabled = true
		env.ssao_radius = 1.0
		env.ssao_intensity = 1.0
		env.ssao_detail = 0.5
		env.ssao_horizon = 0.06

		env.ssil_enabled = false  # SSIL still too expensive for VR
		env.ssr_enabled = false   # SSR not good in VR
		env.sdfgi_enabled = false # SDFGI too expensive for VR

	# Sun light settings
	if rendering_system and rendering_system.sun_light:
		var sun = rendering_system.sun_light
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		sun.directional_shadow_max_distance = 10000.0
		sun.light_angular_distance = 0.5  # Soft penumbra
		sun.shadow_bias = 0.03


## Safe wrapper for setting project settings
func _set_project_setting(setting: String, value: Variant) -> void:
	if ProjectSettings.has_setting(setting):
		ProjectSettings.set_setting(setting, value)
	else:
		push_warning("VRRenderingPreset: Setting not found: %s" % setting)


## Get preset level name as string
func _preset_name(preset: PresetLevel) -> String:
	match preset:
		PresetLevel.HIGH_PERFORMANCE:
			return "HIGH_PERFORMANCE"
		PresetLevel.RECOMMENDED:
			return "RECOMMENDED"
		PresetLevel.HIGH_QUALITY:
			return "HIGH_QUALITY"
	return "UNKNOWN"


## Get current preset level
func get_current_preset() -> PresetLevel:
	return current_preset


## Get preset description
func get_preset_description(preset: PresetLevel) -> String:
	match preset:
		PresetLevel.HIGH_PERFORMANCE:
			return "Guaranteed 90 FPS with minimal quality settings"
		PresetLevel.RECOMMENDED:
			return "Balanced quality/performance targeting 90 FPS (recommended for VR)"
		PresetLevel.HIGH_QUALITY:
			return "Best visual quality (may drop below 90 FPS on lower-end hardware)"
	return "Unknown preset"


## Get performance settings report
func get_settings_report() -> Dictionary:
	var report = {
		"current_preset": _preset_name(current_preset),
		"preset_description": get_preset_description(current_preset),
		"msaa_level": ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d", -1),
		"screen_space_aa": ProjectSettings.get_setting("rendering/anti_aliasing/quality/screen_space_aa", -1),
		"directional_shadow_size": ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/size", -1),
		"directional_shadow_quality": ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality", -1),
		"lod_threshold": ProjectSettings.get_setting("rendering/mesh_lod/lod_change/threshold_pixels", -1),
		"aniso_level": ProjectSettings.get_setting("rendering/textures/default_filters/anisotropic_filtering_level", -1),
	}

	if rendering_system and rendering_system.environment:
		var env = rendering_system.environment
		report["glow_enabled"] = env.glow_enabled
		report["ssao_enabled"] = env.ssao_enabled
		report["ssr_enabled"] = env.ssr_enabled
		report["sdfgi_enabled"] = env.sdfgi_enabled

	return report


## Apply preset based on performance measurement
## Automatically adjusts to maintain target FPS
func auto_adjust_for_performance(current_fps: float, target_fps: float = 90.0) -> void:
	if current_fps < target_fps * 0.85:  # Below 85% of target (< 76.5 FPS)
		if current_preset == PresetLevel.HIGH_QUALITY:
			apply_preset(PresetLevel.RECOMMENDED)
		elif current_preset == PresetLevel.RECOMMENDED:
			apply_preset(PresetLevel.HIGH_PERFORMANCE)
	elif current_fps > target_fps * 1.15:  # Above 115% of target (> 103.5 FPS)
		if current_preset == PresetLevel.HIGH_PERFORMANCE:
			apply_preset(PresetLevel.RECOMMENDED)
		elif current_preset == PresetLevel.RECOMMENDED:
			apply_preset(PresetLevel.HIGH_QUALITY)
