## PostProcessing - Manages post-processing effects for entropy/damage visualization
## Implements entropy-based glitch effects, chromatic aberration, scanlines,
## and pixelation effects that respond to player SNR (Signal-to-Noise Ratio).
##
## Requirements: 13.1 - Apply post-processing effects when entropy increases
## Requirements: 13.2 - Apply pixelation by snapping UV to low-resolution grid
## Requirements: 13.3 - Inject random static noise into final image
## Requirements: 13.4 - Apply chromatic aberration by separating RGB channels
## Requirements: 13.5 - Add scanline effects to simulate digital display corruption
extends Node
class_name PostProcessing

## Emitted when post-processing is initialized
signal post_processing_initialized
## Emitted when entropy level changes
signal entropy_changed(entropy: float)
## Emitted when effect intensity changes
signal effect_intensity_changed(effect_name: String, intensity: float)

## Reference to the WorldEnvironment node
var world_environment: WorldEnvironment = null
## Reference to the ColorRect used for screen-space effects
var effect_rect: ColorRect = null
## Reference to the SubViewportContainer for full-screen effects
var viewport_container: SubViewportContainer = null
## The shader material for glitch effects
var glitch_material: ShaderMaterial = null

## Current entropy level (0.0 = healthy, 1.0 = maximum corruption)
var _entropy: float = 0.0
## Current SNR (Signal-to-Noise Ratio) - inverse of entropy
var _snr: float = 1.0
## Whether post-processing is enabled
var _enabled: bool = true
## Whether the system is initialized
var _initialized: bool = false

## Effect intensity multipliers
var _chromatic_aberration_strength: float = 1.0
var _scanline_strength: float = 1.0
var _pixelation_strength: float = 1.0
var _noise_strength: float = 1.0
var _datamosh_strength: float = 1.0

## Thresholds for effect activation
const ENTROPY_PIXELATION_THRESHOLD: float = 0.5  # Requirements 13.2
const ENTROPY_NOISE_THRESHOLD: float = 0.3
const ENTROPY_CHROMATIC_THRESHOLD: float = 0.2
const ENTROPY_SCANLINE_THRESHOLD: float = 0.1

## Shader parameter names
const PARAM_ENTROPY: String = "entropy"
const PARAM_TIME: String = "time"
const PARAM_CHROMATIC_STRENGTH: String = "chromatic_strength"
const PARAM_SCANLINE_STRENGTH: String = "scanline_strength"
const PARAM_PIXELATION_STRENGTH: String = "pixelation_strength"
const PARAM_NOISE_STRENGTH: String = "noise_strength"
const PARAM_DATAMOSH_STRENGTH: String = "datamosh_strength"
const PARAM_SCREEN_SIZE: String = "screen_size"


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if _initialized and _enabled and glitch_material != null:
		# Update time uniform for animated effects
		var current_time: float = glitch_material.get_shader_parameter(PARAM_TIME)
		glitch_material.set_shader_parameter(PARAM_TIME, current_time + delta)


## Initialize the post-processing system
## @param canvas_layer: The CanvasLayer to attach effects to (should be on top)
## @return: true if initialization was successful
func initialize(canvas_layer: CanvasLayer = null) -> bool:
	if _initialized:
		return true
	
	# Create a CanvasLayer if not provided
	var layer := canvas_layer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = "PostProcessingLayer"
		layer.layer = 100  # Render on top of everything
		add_child(layer)
	
	# Create the ColorRect for full-screen effects
	effect_rect = ColorRect.new()
	effect_rect.name = "PostProcessingRect"
	effect_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	effect_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(effect_rect)
	
	# Create and assign the glitch shader material
	glitch_material = ShaderMaterial.new()
	
	# Try to load the glitch shader
	var shader_path := "res://shaders/post_glitch.gdshader"
	if FileAccess.file_exists(shader_path):
		var shader: Shader = load(shader_path)
		if shader != null:
			glitch_material.shader = shader
			print("PostProcessing: Loaded glitch shader from %s" % shader_path)
		else:
			push_warning("PostProcessing: Failed to load shader, creating inline shader")
			_create_inline_shader()
	else:
		push_warning("PostProcessing: Shader file not found at %s, creating inline shader" % shader_path)
		_create_inline_shader()
	
	effect_rect.material = glitch_material
	
	# Initialize shader parameters
	_initialize_shader_parameters()
	
	_initialized = true
	post_processing_initialized.emit()
	print("PostProcessing: Initialized successfully")
	return true


## Create an inline shader if the external file is not available
func _create_inline_shader() -> void:
	var shader := Shader.new()
	shader.code = _get_fallback_shader_code()
	glitch_material.shader = shader


## Initialize shader parameters with default values
func _initialize_shader_parameters() -> void:
	if glitch_material == null:
		return
	
	glitch_material.set_shader_parameter(PARAM_ENTROPY, _entropy)
	glitch_material.set_shader_parameter(PARAM_TIME, 0.0)
	glitch_material.set_shader_parameter(PARAM_CHROMATIC_STRENGTH, 0.0)
	glitch_material.set_shader_parameter(PARAM_SCANLINE_STRENGTH, 0.0)
	glitch_material.set_shader_parameter(PARAM_PIXELATION_STRENGTH, 0.0)
	glitch_material.set_shader_parameter(PARAM_NOISE_STRENGTH, 0.0)
	glitch_material.set_shader_parameter(PARAM_DATAMOSH_STRENGTH, 0.0)
	
	# Set screen size
	var viewport_size := get_viewport().get_visible_rect().size
	glitch_material.set_shader_parameter(PARAM_SCREEN_SIZE, viewport_size)


## Update the entropy level and adjust all effects accordingly
## Requirements: 13.1 - Apply post-processing effects when entropy increases
## @param entropy: The new entropy level (0.0 to 1.0)
func set_entropy(entropy: float) -> void:
	_entropy = clampf(entropy, 0.0, 1.0)
	_snr = 1.0 - _entropy
	
	if glitch_material != null:
		glitch_material.set_shader_parameter(PARAM_ENTROPY, _entropy)
		_update_effect_intensities()
	
	entropy_changed.emit(_entropy)


## Get the current entropy level
func get_entropy() -> float:
	return _entropy


## Set entropy from SNR value (inverse relationship)
## @param snr: Signal-to-Noise Ratio (0.0 to 1.0, where 1.0 is healthy)
func set_snr(snr: float) -> void:
	_snr = clampf(snr, 0.0, 1.0)
	set_entropy(1.0 - _snr)


## Get the current SNR
func get_snr() -> float:
	return _snr


## Update effect intensities based on current entropy level
## Requirements: 13.1-13.5 - Apply effects proportionally to entropy
func _update_effect_intensities() -> void:
	if glitch_material == null:
		return
	
	# Calculate effect intensities based on entropy thresholds
	# Requirements 13.5: Add scanline effects
	var scanline_intensity := 0.0
	if _entropy > ENTROPY_SCANLINE_THRESHOLD:
		scanline_intensity = (_entropy - ENTROPY_SCANLINE_THRESHOLD) / (1.0 - ENTROPY_SCANLINE_THRESHOLD)
		scanline_intensity *= _scanline_strength
	
	# Requirements 13.4: Apply chromatic aberration
	var chromatic_intensity := 0.0
	if _entropy > ENTROPY_CHROMATIC_THRESHOLD:
		chromatic_intensity = (_entropy - ENTROPY_CHROMATIC_THRESHOLD) / (1.0 - ENTROPY_CHROMATIC_THRESHOLD)
		chromatic_intensity *= _chromatic_aberration_strength
	
	# Requirements 13.3: Inject random static noise
	var noise_intensity := 0.0
	if _entropy > ENTROPY_NOISE_THRESHOLD:
		noise_intensity = (_entropy - ENTROPY_NOISE_THRESHOLD) / (1.0 - ENTROPY_NOISE_THRESHOLD)
		noise_intensity *= _noise_strength
	
	# Requirements 13.2: Apply pixelation when entropy exceeds 0.5
	var pixelation_intensity := 0.0
	if _entropy > ENTROPY_PIXELATION_THRESHOLD:
		pixelation_intensity = (_entropy - ENTROPY_PIXELATION_THRESHOLD) / (1.0 - ENTROPY_PIXELATION_THRESHOLD)
		pixelation_intensity *= _pixelation_strength
	
	# Datamosh effect (severe corruption)
	var datamosh_intensity := 0.0
	if _entropy > 0.7:
		datamosh_intensity = (_entropy - 0.7) / 0.3
		datamosh_intensity *= _datamosh_strength
	
	# Apply to shader
	glitch_material.set_shader_parameter(PARAM_SCANLINE_STRENGTH, scanline_intensity)
	glitch_material.set_shader_parameter(PARAM_CHROMATIC_STRENGTH, chromatic_intensity)
	glitch_material.set_shader_parameter(PARAM_NOISE_STRENGTH, noise_intensity)
	glitch_material.set_shader_parameter(PARAM_PIXELATION_STRENGTH, pixelation_intensity)
	glitch_material.set_shader_parameter(PARAM_DATAMOSH_STRENGTH, datamosh_intensity)
	
	# Emit signals for each effect
	effect_intensity_changed.emit("scanline", scanline_intensity)
	effect_intensity_changed.emit("chromatic", chromatic_intensity)
	effect_intensity_changed.emit("noise", noise_intensity)
	effect_intensity_changed.emit("pixelation", pixelation_intensity)
	effect_intensity_changed.emit("datamosh", datamosh_intensity)


## Enable or disable post-processing
func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if effect_rect != null:
		effect_rect.visible = enabled


## Check if post-processing is enabled
func is_enabled() -> bool:
	return _enabled


## Set individual effect strength multipliers
func set_chromatic_aberration_strength(strength: float) -> void:
	_chromatic_aberration_strength = maxf(strength, 0.0)
	_update_effect_intensities()


func set_scanline_strength(strength: float) -> void:
	_scanline_strength = maxf(strength, 0.0)
	_update_effect_intensities()


func set_pixelation_strength(strength: float) -> void:
	_pixelation_strength = maxf(strength, 0.0)
	_update_effect_intensities()


func set_noise_strength(strength: float) -> void:
	_noise_strength = maxf(strength, 0.0)
	_update_effect_intensities()


func set_datamosh_strength(strength: float) -> void:
	_datamosh_strength = maxf(strength, 0.0)
	_update_effect_intensities()


## Get the glitch shader material for direct manipulation
func get_glitch_material() -> ShaderMaterial:
	return glitch_material


## Update screen size (call when viewport resizes)
func update_screen_size() -> void:
	if glitch_material != null:
		var viewport_size := get_viewport().get_visible_rect().size
		glitch_material.set_shader_parameter(PARAM_SCREEN_SIZE, viewport_size)


## Apply a damage flash effect (temporary spike in entropy)
## @param intensity: Flash intensity (0.0 to 1.0)
## @param duration: Duration of the flash in seconds
func apply_damage_flash(intensity: float = 0.5, duration: float = 0.2) -> void:
	if not _initialized:
		return
	
	var original_entropy := _entropy
	var flash_entropy := minf(_entropy + intensity, 1.0)
	
	# Create a tween for the flash effect
	var tween := create_tween()
	tween.tween_method(set_entropy, flash_entropy, original_entropy, duration)


## Shutdown and cleanup
func shutdown() -> void:
	_enabled = false
	_initialized = false
	
	if effect_rect != null:
		effect_rect.queue_free()
		effect_rect = null
	
	glitch_material = null
	print("PostProcessing: Shutdown complete")


## Get fallback shader code for when external shader file is not available
func _get_fallback_shader_code() -> String:
	return """
shader_type canvas_item;

// Post-processing glitch shader for entropy-based visual corruption
// Requirements: 13.1-13.5

uniform float entropy : hint_range(0.0, 1.0) = 0.0;
uniform float time = 0.0;
uniform float chromatic_strength : hint_range(0.0, 1.0) = 0.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.0;
uniform float pixelation_strength : hint_range(0.0, 1.0) = 0.0;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.0;
uniform float datamosh_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec2 screen_size = vec2(1920.0, 1080.0);

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Random function for noise generation
float random(vec2 st) {
	return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Requirements 13.2: Pixelation by snapping UV to low-resolution grid
	if (pixelation_strength > 0.0) {
		float pixel_size = mix(1.0, 16.0, pixelation_strength);
		vec2 pixel_uv = floor(uv * screen_size / pixel_size) * pixel_size / screen_size;
		uv = mix(uv, pixel_uv, pixelation_strength);
	}
	
	// Requirements 13.4: Chromatic aberration by separating RGB channels
	vec3 color;
	if (chromatic_strength > 0.0) {
		float offset = chromatic_strength * 0.01;
		color.r = texture(SCREEN_TEXTURE, uv + vec2(offset, 0.0)).r;
		color.g = texture(SCREEN_TEXTURE, uv).g;
		color.b = texture(SCREEN_TEXTURE, uv - vec2(offset, 0.0)).b;
	} else {
		color = texture(SCREEN_TEXTURE, uv).rgb;
	}
	
	// Requirements 13.3: Inject random static noise
	if (noise_strength > 0.0) {
		float noise = random(uv + vec2(time * 0.1, 0.0));
		color = mix(color, vec3(noise), noise_strength * 0.3);
	}
	
	// Requirements 13.5: Scanline effects
	if (scanline_strength > 0.0) {
		float scanline = sin(uv.y * screen_size.y * 2.0) * 0.5 + 0.5;
		scanline = pow(scanline, 2.0);
		color *= mix(1.0, scanline, scanline_strength * 0.3);
	}
	
	// Datamoshing effect (UV displacement)
	if (datamosh_strength > 0.0) {
		float block_size = 32.0;
		vec2 block = floor(uv * screen_size / block_size);
		float block_noise = random(block + vec2(floor(time * 2.0), 0.0));
		if (block_noise > 0.8) {
			vec2 offset = vec2(random(block) - 0.5, random(block + vec2(1.0, 0.0)) - 0.5);
			offset *= datamosh_strength * 0.1;
			color = texture(SCREEN_TEXTURE, uv + offset).rgb;
		}
	}
	
	COLOR = vec4(color, 1.0);
}
"""


## Get statistics about the post-processing system
func get_stats() -> Dictionary:
	return {
		"initialized": _initialized,
		"enabled": _enabled,
		"entropy": _entropy,
		"snr": _snr,
		"chromatic_strength": _chromatic_aberration_strength,
		"scanline_strength": _scanline_strength,
		"pixelation_strength": _pixelation_strength,
		"noise_strength": _noise_strength,
		"datamosh_strength": _datamosh_strength
	}
