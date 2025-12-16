## AudioFeedback - Game State Audio Feedback System
##
## Provides audio feedback based on game state changes including
## velocity, entropy, gravity wells, and signal coherence.
##
## Requirements: 27.1, 27.2, 27.3, 27.4, 27.5

extends Node
class_name AudioFeedback

## Base harmonic frequency (Hz)
## Requirement 27.1: Play 432Hz harmonic base tone when idle
const BASE_FREQUENCY: float = 432.0

## Reference to the spacecraft
@export var spacecraft: Node3D = null

## Reference to the signal manager
@export var signal_manager: Node = null

## Reference to the spatial audio system
var spatial_audio: SpatialAudio = null

## Audio stream generators
var base_tone_generator: AudioStreamGenerator = null
var base_tone_player: AudioStreamPlayer = null

## Current audio state
var current_pitch_scale: float = 1.0
var current_distortion: float = 0.0
var current_volume: float = 0.0

## Audio effects
var distortion_effect: AudioEffectDistortion = null
var pitch_shift_effect: AudioEffectPitchShift = null

## Audio bus indices
var feedback_bus_index: int = -1

## Playback position for tone generation
var playback_position: float = 0.0

## Enable/disable different feedback types
@export var enable_base_tone: bool = true
@export var enable_doppler_shift: bool = true
@export var enable_entropy_effects: bool = true
@export var enable_gravity_effects: bool = true
@export var enable_snr_effects: bool = true

## Initialize the audio feedback system
func _ready() -> void:
	setup_audio_bus()
	setup_base_tone()
	
	# Find spatial audio system
	spatial_audio = get_node_or_null("/root/ResonanceEngine/SpatialAudio")
	if not spatial_audio:
		push_warning("AudioFeedback: SpatialAudio not found")
	
	print("AudioFeedback initialized")
	print("  Base frequency: ", BASE_FREQUENCY, " Hz")
	print("  Doppler shift: ", enable_doppler_shift)
	print("  Entropy effects: ", enable_entropy_effects)

## Setup audio bus for feedback
func setup_audio_bus() -> void:
	# Create or get feedback bus
	feedback_bus_index = AudioServer.get_bus_index("Feedback")
	if feedback_bus_index == -1:
		AudioServer.add_bus()
		feedback_bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(feedback_bus_index, "Feedback")
		AudioServer.set_bus_send(feedback_bus_index, "Master")
	
	# Add distortion effect for entropy
	# Requirement 27.3: Apply bit-crushing effects to audio output
	distortion_effect = AudioEffectDistortion.new()
	distortion_effect.mode = AudioEffectDistortion.MODE_OVERDRIVE
	distortion_effect.drive = 0.0
	distortion_effect.pre_gain = 0.0
	distortion_effect.post_gain = 0.0
	AudioServer.add_bus_effect(feedback_bus_index, distortion_effect)
	
	# Add pitch shift effect for Doppler
	pitch_shift_effect = AudioEffectPitchShift.new()
	pitch_shift_effect.pitch_scale = 1.0
	AudioServer.add_bus_effect(feedback_bus_index, pitch_shift_effect)

## Setup base harmonic tone
## Requirement 27.1: Play 432Hz harmonic base tone when idle
func setup_base_tone() -> void:
	if not enable_base_tone:
		return
	
	# Create audio stream player
	base_tone_player = AudioStreamPlayer.new()
	base_tone_player.bus = "Feedback"
	base_tone_player.volume_db = -10.0  # Start quiet
	add_child(base_tone_player)
	
	# Create a simple sine wave generator
	# Note: In a real implementation, you'd use AudioStreamGenerator
	# For now, we'll use a placeholder approach
	
	# Start playing
	if base_tone_player.stream:
		base_tone_player.play()

## Update audio feedback based on game state
func _process(delta: float) -> void:
	if not spacecraft:
		return
	
	# Update base tone pitch based on velocity
	if enable_doppler_shift:
		update_doppler_shift()
	
	# Update distortion based on entropy
	if enable_entropy_effects and signal_manager:
		update_entropy_effects()
	
	# Update bass distortion based on gravity
	if enable_gravity_effects:
		update_gravity_effects()
	
	# Update dropouts based on SNR
	if enable_snr_effects and signal_manager:
		update_snr_effects()

## Update Doppler shift based on velocity
## Requirement 27.2: Pitch-shift audio with velocity (Doppler)
func update_doppler_shift() -> void:
	if not spacecraft:
		return
	
	# Get spacecraft velocity
	var velocity = Vector3.ZERO
	if spacecraft.has_method("get_velocity_magnitude"):
		var speed = spacecraft.get_velocity_magnitude()
		# Normalize to a reasonable range (0 to 1000 units/s)
		var normalized_speed = clamp(speed / 1000.0, 0.0, 1.0)
		
		# Calculate pitch shift (1.0 = normal, >1.0 = higher pitch, <1.0 = lower pitch)
		# At max speed, pitch shifts up by 20%
		current_pitch_scale = 1.0 + (normalized_speed * 0.2)
	else:
		current_pitch_scale = 1.0
	
	# Apply pitch shift
	if pitch_shift_effect:
		pitch_shift_effect.pitch_scale = current_pitch_scale

## Update entropy-based audio effects
## Requirement 27.3: Apply bit-crushing effects with entropy
func update_entropy_effects() -> void:
	if not signal_manager:
		return
	
	# Get entropy level (0.0 to 1.0)
	var entropy = 0.0
	if signal_manager.has_method("get_entropy"):
		entropy = signal_manager.get_entropy()
	
	# Apply distortion based on entropy
	# Higher entropy = more distortion
	current_distortion = entropy
	
	if distortion_effect:
		# Drive increases with entropy (0 to 0.8)
		distortion_effect.drive = entropy * 0.8
		# Pre-gain increases slightly
		distortion_effect.pre_gain = entropy * 10.0

## Update gravity well audio effects
## Requirement 27.4: Add bass-heavy distortion in gravity wells
func update_gravity_effects() -> void:
	if not spacecraft:
		return
	
	# Find nearest celestial body
	var nearest_body = find_nearest_celestial_body()
	if not nearest_body:
		return
	
	# Calculate distance to body
	var distance = (spacecraft.global_position - nearest_body.global_position).length()
	var body_radius = nearest_body.radius if nearest_body.has("radius") else 100.0
	
	# Calculate gravity well strength (0.0 to 1.0)
	# Stronger when closer to the body
	var gravity_strength = 0.0
	if distance < body_radius * 10.0:
		gravity_strength = 1.0 - (distance / (body_radius * 10.0))
		gravity_strength = clamp(gravity_strength, 0.0, 1.0)
	
	# Add bass boost when in gravity well
	# This would typically be done with an EQ effect
	# For now, we'll increase the overall volume slightly
	if base_tone_player and gravity_strength > 0.0:
		var bass_boost = gravity_strength * 3.0  # Up to +3dB
		base_tone_player.volume_db = -10.0 + bass_boost

## Update SNR-based audio effects
## Requirement 27.5: Introduce dropouts and static at low SNR
func update_snr_effects() -> void:
	if not signal_manager:
		return
	
	# Get SNR (0.0 to 100.0)
	var snr = 100.0
	if signal_manager.has_method("calculate_snr"):
		snr = signal_manager.calculate_snr()
	
	# Normalize SNR to 0.0 to 1.0
	var snr_normalized = clamp(snr / 100.0, 0.0, 1.0)
	
	# At low SNR, introduce audio dropouts
	if snr_normalized < 0.25:
		# Random dropouts
		if randf() < (1.0 - snr_normalized) * 0.1:  # Up to 10% chance per frame
			if base_tone_player:
				base_tone_player.volume_db = -80.0  # Mute briefly
		else:
			if base_tone_player:
				base_tone_player.volume_db = -10.0
	
	# Add static noise at low SNR
	# This would typically be done by mixing in a noise generator
	# For now, we'll increase distortion
	if snr_normalized < 0.5:
		var static_amount = (1.0 - snr_normalized) * 0.5
		if distortion_effect:
			distortion_effect.drive = max(distortion_effect.drive, static_amount)

## Find the nearest celestial body
func find_nearest_celestial_body() -> Node3D:
	"""Find the nearest CelestialBody to the spacecraft."""
	if not spacecraft:
		return null
	
	var nearest: Node3D = null
	var nearest_distance = INF
	
	# Find all CelestialBody nodes
	var bodies = get_tree().get_nodes_in_group("celestial_bodies")
	for body in bodies:
		if body is Node3D:
			var distance = (spacecraft.global_position - body.global_position).length()
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = body
	
	return nearest

## Set the spacecraft reference
func set_spacecraft(craft: Node3D) -> void:
	"""Set the spacecraft reference."""
	spacecraft = craft

## Set the signal manager reference
func set_signal_manager(manager: Node) -> void:
	"""Set the signal manager reference."""
	signal_manager = manager

## Enable or disable base tone
func set_base_tone_enabled(enabled: bool) -> void:
	"""Enable or disable the base harmonic tone."""
	enable_base_tone = enabled
	if base_tone_player:
		if enabled:
			base_tone_player.play()
		else:
			base_tone_player.stop()

## Enable or disable Doppler shift
func set_doppler_enabled(enabled: bool) -> void:
	"""Enable or disable Doppler shift effect."""
	enable_doppler_shift = enabled
	if not enabled and pitch_shift_effect:
		pitch_shift_effect.pitch_scale = 1.0

## Enable or disable entropy effects
func set_entropy_effects_enabled(enabled: bool) -> void:
	"""Enable or disable entropy-based audio effects."""
	enable_entropy_effects = enabled
	if not enabled and distortion_effect:
		distortion_effect.drive = 0.0
		distortion_effect.pre_gain = 0.0

## Enable or disable gravity effects
func set_gravity_effects_enabled(enabled: bool) -> void:
	"""Enable or disable gravity well audio effects."""
	enable_gravity_effects = enabled

## Enable or disable SNR effects
func set_snr_effects_enabled(enabled: bool) -> void:
	"""Enable or disable SNR-based audio effects."""
	enable_snr_effects = enabled

## Get current pitch scale
func get_pitch_scale() -> float:
	"""Get the current pitch scale factor."""
	return current_pitch_scale

## Get current distortion level
func get_distortion_level() -> float:
	"""Get the current distortion level (0.0 to 1.0)."""
	return current_distortion

## Cleanup
func _exit_tree() -> void:
	if base_tone_player:
		base_tone_player.stop()
		base_tone_player.queue_free()
