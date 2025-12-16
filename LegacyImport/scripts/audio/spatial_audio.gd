## SpatialAudio - 3D Spatial Audio System
##
## Manages 3D audio positioning, distance attenuation, Doppler shift,
## and environmental reverb for immersive VR audio experience.
##
## Requirements: 65.1, 65.2, 65.3, 65.4, 65.5

extends Node
class_name SpatialAudio

## Maximum number of simultaneous audio channels
const MAX_CHANNELS: int = 256

## Reference distance for audio attenuation (in game units)
@export var reference_distance: float = 10.0

## Maximum distance for audio (beyond this, audio is silent)
@export var max_distance: float = 1000.0

## Attenuation model: "inverse", "inverse_square", "linear", "exponential"
@export var attenuation_model: String = "inverse_square"

## Enable Doppler shift effect
@export var enable_doppler: bool = true

## Doppler factor (0.0 to 1.0, where 1.0 is realistic)
@export var doppler_factor: float = 1.0

## Enable environmental reverb
@export var enable_reverb: bool = true

## Reverb room size (0.0 to 1.0)
@export var reverb_room_size: float = 0.5

## Reverb damping (0.0 to 1.0)
@export var reverb_damping: float = 0.5

## Active audio sources (AudioStreamPlayer3D nodes)
var active_sources: Array[AudioStreamPlayer3D] = []

## Audio bus for spatial audio
var spatial_bus_index: int = -1

## Audio bus for reverb
var reverb_bus_index: int = -1

## Reference to the listener (usually the VR camera)
var listener: Node3D = null

## Initialize the spatial audio system
func _ready() -> void:
	# Setup audio buses
	setup_audio_buses()
	
	# Find the VR camera as the listener
	find_listener()
	
	print("SpatialAudio initialized")
	print("  Max channels: ", MAX_CHANNELS)
	print("  Attenuation model: ", attenuation_model)
	print("  Doppler enabled: ", enable_doppler)
	print("  Reverb enabled: ", enable_reverb)

## Setup audio buses for spatial audio and reverb
## Requirement 65.5: Mix up to 256 simultaneous channels using AudioBusLayout
func setup_audio_buses() -> void:
	# Get or create spatial audio bus
	spatial_bus_index = AudioServer.get_bus_index("Spatial")
	if spatial_bus_index == -1:
		# Create spatial bus if it doesn't exist
		AudioServer.add_bus()
		spatial_bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(spatial_bus_index, "Spatial")
		AudioServer.set_bus_send(spatial_bus_index, "Master")
	
	# Get or create reverb bus
	if enable_reverb:
		reverb_bus_index = AudioServer.get_bus_index("Reverb")
		if reverb_bus_index == -1:
			# Create reverb bus
			AudioServer.add_bus()
			reverb_bus_index = AudioServer.bus_count - 1
			AudioServer.set_bus_name(reverb_bus_index, "Reverb")
			AudioServer.set_bus_send(reverb_bus_index, "Spatial")
			
			# Add reverb effect
			# Requirement 65.4: Apply environment reverb using AudioEffectReverb
			var reverb_effect = AudioEffectReverb.new()
			reverb_effect.room_size = reverb_room_size
			reverb_effect.damping = reverb_damping
			reverb_effect.spread = 1.0
			reverb_effect.hipass = 0.0
			reverb_effect.dry = 0.5
			reverb_effect.wet = 0.5
			AudioServer.add_bus_effect(reverb_bus_index, reverb_effect)

## Find the audio listener (VR camera)
func find_listener() -> void:
	# Try to find XRCamera3D
	var xr_camera = get_tree().root.find_child("XRCamera3D", true, false)
	if xr_camera and xr_camera is Camera3D:
		listener = xr_camera
		print("SpatialAudio: Listener set to XRCamera3D")
		return
	
	# Fallback to any Camera3D
	var camera = get_viewport().get_camera_3d()
	if camera:
		listener = camera
		print("SpatialAudio: Listener set to Camera3D")
		return
	
	push_warning("SpatialAudio: No listener found!")

## Create a new 3D audio source
## Requirement 65.1: Use AudioStreamPlayer3D for 3D audio positioning
func create_audio_source(stream: AudioStream, position: Vector3, autoplay: bool = true) -> AudioStreamPlayer3D:
	"""Create a new 3D audio source at the specified position."""
	
	# Check channel limit
	if active_sources.size() >= MAX_CHANNELS:
		push_warning("SpatialAudio: Maximum channels reached (%d)" % MAX_CHANNELS)
		# Remove oldest inactive source
		cleanup_inactive_sources()
		if active_sources.size() >= MAX_CHANNELS:
			return null
	
	# Create AudioStreamPlayer3D
	var source = AudioStreamPlayer3D.new()
	source.stream = stream
	source.bus = "Spatial"
	
	# Set attenuation model
	# Requirement 65.2: Calculate distance attenuation
	match attenuation_model:
		"inverse":
			source.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		"inverse_square":
			source.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
		"linear":
			source.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
		"exponential":
			source.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
	
	source.unit_size = reference_distance
	source.max_distance = max_distance
	
	# Enable Doppler tracking
	# Requirement 65.3: Implement Doppler shift for moving sources using doppler_tracking
	if enable_doppler:
		source.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP
	else:
		source.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
	
	# Set position
	source.global_position = position
	
	# Add to scene
	add_child(source)
	active_sources.append(source)
	
	# Autoplay if requested
	if autoplay:
		source.play()
	
	return source

## Play a sound at a specific position
func play_sound_at_position(stream: AudioStream, position: Vector3, volume_db: float = 0.0) -> AudioStreamPlayer3D:
	"""Play a one-shot sound at a specific position."""
	var source = create_audio_source(stream, position, true)
	if source:
		source.volume_db = volume_db
		# Auto-cleanup when finished
		source.finished.connect(func(): remove_audio_source(source))
	return source

## Play a looping sound at a specific position
func play_looping_sound(stream: AudioStream, position: Vector3, volume_db: float = 0.0) -> AudioStreamPlayer3D:
	"""Play a looping sound at a specific position."""
	var source = create_audio_source(stream, position, false)
	if source:
		source.volume_db = volume_db
		if stream:
			stream.loop = true
		source.play()
	return source

## Remove an audio source
func remove_audio_source(source: AudioStreamPlayer3D) -> void:
	"""Remove an audio source from the system."""
	if source in active_sources:
		active_sources.erase(source)
	
	if is_instance_valid(source):
		source.stop()
		source.queue_free()

## Cleanup inactive sources
func cleanup_inactive_sources() -> void:
	"""Remove sources that are no longer playing."""
	var to_remove: Array[AudioStreamPlayer3D] = []
	
	for source in active_sources:
		if not is_instance_valid(source) or not source.playing:
			to_remove.append(source)
	
	for source in to_remove:
		remove_audio_source(source)

## Update audio source position
func update_source_position(source: AudioStreamPlayer3D, position: Vector3) -> void:
	"""Update the position of an audio source."""
	if is_instance_valid(source):
		source.global_position = position

## Set the listener position (usually handled automatically by Camera3D)
func set_listener(new_listener: Node3D) -> void:
	"""Set the audio listener node."""
	listener = new_listener

## Get the current listener
func get_listener() -> Node3D:
	"""Get the current audio listener."""
	return listener

## Calculate distance attenuation manually (for custom audio processing)
## Requirement 65.2: Calculate distance attenuation
func calculate_attenuation(distance: float) -> float:
	"""Calculate attenuation factor based on distance."""
	if distance <= reference_distance:
		return 1.0
	
	if distance >= max_distance:
		return 0.0
	
	match attenuation_model:
		"inverse":
			return reference_distance / distance
		"inverse_square":
			return reference_distance * reference_distance / (distance * distance)
		"linear":
			var t = (distance - reference_distance) / (max_distance - reference_distance)
			return 1.0 - clamp(t, 0.0, 1.0)
		"exponential":
			var t = (distance - reference_distance) / (max_distance - reference_distance)
			return exp(-t * 5.0)  # Exponential falloff
		_:
			return 1.0

## Calculate Doppler shift factor
## Requirement 65.3: Implement Doppler shift for moving sources
func calculate_doppler_shift(source_velocity: Vector3, listener_velocity: Vector3, source_to_listener: Vector3) -> float:
	"""Calculate Doppler shift factor for pitch adjustment."""
	if not enable_doppler or doppler_factor <= 0.0:
		return 1.0
	
	# Speed of sound in game units per second (approximate)
	const SPEED_OF_SOUND = 343.0
	
	# Project velocities onto the line between source and listener
	var direction = source_to_listener.normalized()
	var source_speed = source_velocity.dot(direction)
	var listener_speed = listener_velocity.dot(direction)
	
	# Doppler formula: f' = f * (v + v_listener) / (v + v_source)
	# where v is speed of sound
	var denominator = SPEED_OF_SOUND + source_speed
	if abs(denominator) < 0.001:
		return 1.0
	
	var doppler_shift = (SPEED_OF_SOUND + listener_speed) / denominator
	
	# Apply doppler factor to control intensity
	doppler_shift = lerp(1.0, doppler_shift, doppler_factor)
	
	# Clamp to reasonable range
	return clamp(doppler_shift, 0.5, 2.0)

## Set reverb parameters
## Requirement 65.4: Apply environment reverb
func set_reverb_parameters(room_size: float, damping: float) -> void:
	"""Set reverb room size and damping."""
	reverb_room_size = clamp(room_size, 0.0, 1.0)
	reverb_damping = clamp(damping, 0.0, 1.0)
	
	if reverb_bus_index >= 0:
		var effect = AudioServer.get_bus_effect(reverb_bus_index, 0)
		if effect is AudioEffectReverb:
			effect.room_size = reverb_room_size
			effect.damping = reverb_damping

## Enable or disable reverb
func set_reverb_enabled(enabled: bool) -> void:
	"""Enable or disable reverb effect."""
	enable_reverb = enabled
	if reverb_bus_index >= 0:
		AudioServer.set_bus_effect_enabled(reverb_bus_index, 0, enabled)

## Get the number of active audio sources
func get_active_source_count() -> int:
	"""Get the number of currently active audio sources."""
	cleanup_inactive_sources()
	return active_sources.size()

## Stop all audio sources
func stop_all() -> void:
	"""Stop and remove all audio sources."""
	for source in active_sources:
		if is_instance_valid(source):
			source.stop()
			source.queue_free()
	active_sources.clear()

## Process audio updates
func _process(_delta: float) -> void:
	# Periodic cleanup of inactive sources
	if Engine.get_frames_drawn() % 60 == 0:  # Every 60 frames
		cleanup_inactive_sources()
