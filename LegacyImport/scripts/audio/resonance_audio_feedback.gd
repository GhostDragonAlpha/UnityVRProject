## ResonanceAudioFeedback - Audio Feedback System for Resonance Interactions
##
## Provides immersive audio cues that match frequencies being emitted and enhance
## the resonance gameplay experience with spatial audio, dynamic layering, and
## real-time synthesis.
##
## Requirements: 20.1, 20.2, 20.3, 20.4, 20.5, 65.1, 65.2, 65.3, 65.4, 65.5

extends Node
class_name ResonanceAudioFeedback

## Audio bus names
const RESONANCE_BUS: String = "Resonance"
const RESONANCE_SFX_BUS: String = "ResonanceSFX"

## Frequency range for resonance tones
const MIN_FREQUENCY: float = 100.0
const MAX_FREQUENCY: float = 1000.0

## Reference to subsystems
var resonance_system: ResonanceSystem = null
var resonance_input_controller: ResonanceInputController = null
var spatial_audio: SpatialAudio = null
var audio_manager: AudioManager = null
var procedural_generator: ProceduralAudioGenerator = null

## Audio players for different sound types
var scanned_object_players: Dictionary = {}  # Key: object_id, Value: AudioStreamPlayer3D
var emission_player: AudioStreamPlayer = null
var scanning_player: AudioStreamPlayer = null
var ambient_resonance_player: AudioStreamPlayer = null

## Real-time audio synthesis
var synthesis_bus_index: int = -1
var active_frequencies: Array[float] = []
var frequency_volumes: Dictionary = {}  # Key: frequency, Value: volume (0.0-1.0)

## Audio settings
@export var enable_spatial_audio: bool = true
@export var enable_dynamic_layering: bool = true
@export var max_simultaneous_frequencies: int = 8
@export var base_resonance_volume: float = 0.3
@export var emission_volume: float = 0.8
@export var scanning_volume: float = 0.6

## State tracking
var is_scanning: bool = false
var current_emission_frequency: float = 0.0
var emission_mode: String = "none"  # "constructive", "destructive", "none"


func _ready() -> void:
	# Setup audio buses
	_setup_audio_buses()
	
	# Create audio players
	_create_audio_players()
	
	# Find required systems
	_find_systems()
	
	# Setup signal connections
	_setup_signal_connections()
	
	print("ResonanceAudioFeedback initialized")
	print("  Spatial audio: ", enable_spatial_audio)
	print("  Dynamic layering: ", enable_dynamic_layering)
	print("  Max frequencies: ", max_simultaneous_frequencies)


func _setup_audio_buses() -> void:
	"""Setup dedicated audio buses for resonance audio."""
	# Create resonance bus
	var resonance_bus_index = AudioServer.get_bus_index(RESONANCE_BUS)
	if resonance_bus_index == -1:
		AudioServer.add_bus()
		resonance_bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(resonance_bus_index, RESONANCE_BUS)
		AudioServer.set_bus_send(resonance_bus_index, "Master")
		AudioServer.set_bus_volume_db(resonance_bus_index, linear_to_db(base_resonance_volume))
	
	# Create resonance SFX bus
	var sfx_bus_index = AudioServer.get_bus_index(RESONANCE_SFX_BUS)
	if sfx_bus_index == -1:
		AudioServer.add_bus()
		sfx_bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(sfx_bus_index, RESONANCE_SFX_BUS)
		AudioServer.set_bus_send(sfx_bus_index, RESONANCE_BUS)
		AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(0.8))
	
	synthesis_bus_index = resonance_bus_index


func _create_audio_players() -> void:
	"""Create audio players for different sound types."""
	# Emission player (for frequency emission sounds)
	emission_player = AudioStreamPlayer.new()
	emission_player.bus = RESONANCE_SFX_BUS
	emission_player.volume_db = linear_to_db(emission_volume)
	add_child(emission_player)
	
	# Scanning player (for scanning sounds)
	scanning_player = AudioStreamPlayer.new()
	scanning_player.bus = RESONANCE_SFX_BUS
	scanning_player.volume_db = linear_to_db(scanning_volume)
	add_child(scanning_player)
	
	# Ambient resonance player (for background resonance layer)
	ambient_resonance_player = AudioStreamPlayer.new()
	ambient_resonance_player.bus = RESONANCE_BUS
	ambient_resonance_player.volume_db = linear_to_db(0.2)
	add_child(ambient_resonance_player)
	
	# Create procedural generator
	procedural_generator = ProceduralAudioGenerator.new()
	add_child(procedural_generator)


func _find_systems() -> void:
	"""Find references to required systems."""
	# Find resonance system
	resonance_system = _find_node_of_type("ResonanceSystem")
	if not resonance_system:
		push_warning("ResonanceAudioFeedback: ResonanceSystem not found")
	
	# Find input controller
	resonance_input_controller = _find_node_of_type("ResonanceInputController")
	if not resonance_input_controller:
		push_warning("ResonanceAudioFeedback: ResonanceInputController not found")
	
	# Find spatial audio
	var engine_node = get_node_or_null("/root/ResonanceEngine")
	if engine_node and engine_node.has_method("get_spatial_audio"):
		spatial_audio = engine_node.get_spatial_audio()
	
	if not spatial_audio:
		spatial_audio = _find_node_of_type("SpatialAudio")
		if not spatial_audio:
			push_warning("ResonanceAudioFeedback: SpatialAudio not found")
	
	# Find audio manager
	if engine_node and engine_node.has_method("get_audio_manager"):
		audio_manager = engine_node.get_audio_manager()
	
	if not audio_manager:
		audio_manager = _find_node_of_type("AudioManager")
		if not audio_manager:
			push_warning("ResonanceAudioFeedback: AudioManager not found")


func _find_node_of_type(type_name: String) -> Node:
	"""Find a node of a specific type in the scene tree."""
	var root := get_tree().root
	return _recursive_find_type(root, type_name)


func _recursive_find_type(node: Node, type_name: String) -> Node:
	# Check by class_name for custom classes
	if node is ResonanceSystem and type_name == "ResonanceSystem":
		return node
	if node is ResonanceInputController and type_name == "ResonanceInputController":
		return node
	if node is SpatialAudio and type_name == "SpatialAudio":
		return node
	if node is AudioManager and type_name == "AudioManager":
		return node
	
	# Check script class name
	if node.get_script() != null:
		var script = node.get_script()
		if script.has_method("get_global_name"):
			if script.get_global_name() == type_name:
				return node
	
	# Recursively search children
	for child in node.get_children():
		var result := _recursive_find_type(child, type_name)
		if result != null:
			return result
	
	return null


func _setup_signal_connections() -> void:
	"""Setup connections to resonance system signals."""
	if resonance_system:
		# Connect to resonance system signals
		if resonance_system.has_signal("object_scanned"):
			resonance_system.object_scanned.connect(_on_object_scanned)
		if resonance_system.has_signal("interference_applied"):
			resonance_system.interference_applied.connect(_on_interference_applied)
		if resonance_system.has_signal("object_cancelled"):
			resonance_system.object_cancelled.connect(_on_object_cancelled)
	
	if resonance_input_controller:
		# Connect to input controller signals
		if resonance_input_controller.has_signal("object_scanned"):
			resonance_input_controller.object_scanned.connect(_on_input_object_scanned)
		if resonance_input_controller.has_signal("frequency_emitted"):
			resonance_input_controller.frequency_emitted.connect(_on_frequency_emitted)
		if resonance_input_controller.has_signal("emission_stopped"):
			resonance_input_controller.emission_stopped.connect(_on_emission_stopped)
		if resonance_input_controller.has_signal("mode_changed"):
			resonance_input_controller.mode_changed.connect(_on_mode_changed)
		if resonance_input_controller.has_signal("frequency_switched"):
			resonance_input_controller.frequency_switched.connect(_on_frequency_switched)


func _on_object_scanned(object: Node3D, frequency: float) -> void:
	"""Handle object scanned by resonance system."""
	# Create spatial audio for the scanned object
	if enable_spatial_audio and spatial_audio:
		_create_object_resonance_tone(object, frequency)
	
	# Play scanning completion sound
	_play_scan_complete_sound(frequency)


func _on_input_object_scanned(object: Node3D, frequency: float) -> void:
	"""Handle object scanned by input controller (additional audio feedback)."""
	# Add frequency to active list for dynamic layering
	if enable_dynamic_layering:
		_add_active_frequency(frequency)


func _on_interference_applied(object: Node3D, interference_type: String, amplitude_change: float) -> void:
	"""Handle interference applied to object."""
	# Update audio based on interference
	if object and is_instance_valid(object):
		var obj_id = object.get_instance_id()
		if scanned_object_players.has(obj_id):
			var player = scanned_object_players[obj_id]
			if is_instance_valid(player):
				# Adjust volume based on amplitude change
				var volume_change = amplitude_change * 10.0  # Convert to dB scale
				player.volume_db += volume_change
				
				# Apply pitch shift for dramatic effect
				if interference_type == "destructive":
					player.pitch_scale = 0.95  # Slight pitch down
				elif interference_type == "constructive":
					player.pitch_scale = 1.05  # Slight pitch up


func _on_object_cancelled(object: Node3D) -> void:
	"""Handle object cancellation through destructive interference."""
	# Play cancellation sound
	_play_cancellation_sound()
	
	# Remove object's resonance tone
	var obj_id = object.get_instance_id()
	if scanned_object_players.has(obj_id):
		var player = scanned_object_players[obj_id]
		if is_instance_valid(player):
			# Fade out before removal
			var tween = create_tween()
			tween.tween_property(player, "volume_db", -80.0, 0.5)
			tween.finished.connect(func(): _remove_object_player(obj_id))
	
	# Remove from active frequencies
	var frequency = resonance_system.get_object_frequency(object)
	_remove_active_frequency(frequency)


func _on_frequency_emitted(frequency: float, mode: String) -> void:
	"""Handle frequency emission start."""
	current_emission_frequency = frequency
	emission_mode = mode
	
	# Play emission sound
	_play_emission_sound(frequency, mode)


func _on_emission_stopped() -> void:
	"""Handle frequency emission stop."""
	current_emission_frequency = 0.0
	emission_mode = "none"
	
	# Stop emission sound
	if emission_player and emission_player.playing:
		var tween = create_tween()
		tween.tween_property(emission_player, "volume_db", -80.0, 0.2)
		tween.finished.connect(func(): emission_player.stop())


func _on_mode_changed(mode: String) -> void:
	"""Handle resonance mode change."""
	# Play mode switch sound
	_play_mode_switch_sound(mode)


func _on_frequency_switched(frequency: float) -> void:
	"""Handle quick frequency switch."""
	# Play frequency switch sound
	_play_frequency_switch_sound(frequency)


func _create_object_resonance_tone(object: Node3D, frequency: float) -> void:
	"""Create a spatial audio source for object resonance."""
	if not enable_spatial_audio or not spatial_audio:
		return
	
	# Generate tone for the object's frequency
	var duration = 2.0  # 2 second loop
	var tone_stream = procedural_generator.generate_looping_sine_tone(frequency, duration, 0.4)
	
	# Create 3D audio source at object position
	var player = spatial_audio.play_looping_sound(tone_stream, object.global_position, -10.0)
	
	if player:
		# Store reference for later updates
		var obj_id = object.get_instance_id()
		scanned_object_players[obj_id] = player
		
		# Set custom parameters
		player.max_distance = 50.0
		player.unit_size = 5.0


func _play_scan_complete_sound(frequency: float) -> void:
	"""Play sound for successful scan completion."""
	if not procedural_generator:
		return
	
	# Generate a confirmation chime with the scanned frequency
	var chime_stream = procedural_generator.generate_beep(frequency * 2, 0.3, 0.5)
	
	if scanning_player:
		scanning_player.stream = chime_stream
		scanning_player.play()


func _play_emission_sound(frequency: float, mode: String) -> void:
	"""Play emission sound based on frequency and mode."""
	if not procedural_generator or not emission_player:
		return
	
	# Generate different sounds for constructive vs destructive
	var stream: AudioStreamWAV
	if mode == "constructive":
		# Harmonic-rich tone for constructive
		stream = procedural_generator.generate_harmonic_series(frequency, 3, 1.0, 0.6)
	else:
		# Dissonant tone for destructive
		stream = procedural_generator.generate_sweep(frequency * 1.1, frequency * 0.9, 0.5, 0.5)
	
	emission_player.stream = stream
	emission_player.play()


func _play_cancellation_sound() -> void:
	"""Play sound for object cancellation."""
	if not procedural_generator or not emission_player:
		return
	
	# Generate dissolution sound (descending sweep)
	var stream = procedural_generator.generate_sweep(800.0, 200.0, 1.0, 0.7)
	
	emission_player.stream = stream
	emission_player.play()


func _play_mode_switch_sound(mode: String) -> void:
	"""Play sound for mode switch."""
	if not procedural_generator or not scanning_player:
		return
	
	var stream: AudioStreamWAV
	if mode == "constructive":
		# Upward sweep for constructive mode
		stream = procedural_generator.generate_sweep(400.0, 600.0, 0.2, 0.4)
	else:
		# Downward sweep for destructive mode
		stream = procedural_generator.generate_sweep(600.0, 400.0, 0.2, 0.4)
	
	scanning_player.stream = stream
	scanning_player.play()


func _play_frequency_switch_sound(frequency: float) -> void:
	"""Play sound for frequency switch."""
	if not procedural_generator or not scanning_player:
		return
	
	# Quick confirmation beep
	var stream = procedural_generator.generate_beep(frequency, 0.1, 0.3)
	
	scanning_player.stream = stream
	scanning_player.play()


func _add_active_frequency(frequency: float) -> void:
	"""Add frequency to active list for dynamic layering."""
	if not enable_dynamic_layering:
		return
	
	# Remove if already exists
	_remove_active_frequency(frequency)
	
	# Add to active list
	active_frequencies.append(frequency)
	frequency_volumes[frequency] = 0.5
	
	# Limit number of simultaneous frequencies
	if active_frequencies.size() > max_simultaneous_frequencies:
		var removed_freq = active_frequencies.pop_front()
		frequency_volumes.erase(removed_freq)
	
	# Update ambient layer
	_update_ambient_resonance_layer()


func _remove_active_frequency(frequency: float) -> void:
	"""Remove frequency from active list."""
	var idx = active_frequencies.find(frequency)
	if idx >= 0:
		active_frequencies.remove_at(idx)
		frequency_volumes.erase(frequency)
	
	_update_ambient_resonance_layer()


func _update_ambient_resonance_layer() -> void:
	"""Update the ambient resonance background layer."""
	if not enable_dynamic_layering or not procedural_generator or not ambient_resonance_player:
		return
	
	if active_frequencies.is_empty():
		if ambient_resonance_player.playing:
			ambient_resonance_player.stop()
		return
	
	# Generate a composite tone with all active frequencies
	var duration = 4.0
	var sample_count = int(ProceduralAudioGenerator.SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t = float(i) / ProceduralAudioGenerator.SAMPLE_RATE
		var value = 0.0
		
		# Sum all active frequencies
		for frequency in active_frequencies:
			var volume = frequency_volumes.get(frequency, 0.3)
			value += sin(2.0 * PI * frequency * t) * volume
		
		# Normalize
		if active_frequencies.size() > 0:
			value /= float(active_frequencies.size())
		
		# Apply gentle envelope
		value *= 0.3  # Keep ambient layer subtle
		
		var sample = int(value * 32767.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	
	# Create stream
	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = ProceduralAudioGenerator.SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	
	ambient_resonance_player.stream = stream
	if not ambient_resonance_player.playing:
		ambient_resonance_player.play()


func _remove_object_player(obj_id: int) -> void:
	"""Remove and cleanup object audio player."""
	if scanned_object_players.has(obj_id):
		var player = scanned_object_players[obj_id]
		if is_instance_valid(player):
			player.queue_free()
		scanned_object_players.erase(obj_id)


func linear_to_db(linear: float) -> float:
	"""Convert linear volume to decibels."""
	if linear <= 0.0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)


func _process(delta: float) -> void:
	"""Update audio feedback every frame."""
	# Update spatial audio positions for moving objects
	if enable_spatial_audio:
		_update_object_positions()
	
	# Update frequency volumes based on interference
	if enable_dynamic_layering and current_emission_frequency > 0:
		_update_frequency_volumes(delta)


func _update_object_positions() -> void:
	"""Update positions of object audio players."""
	for obj_id in scanned_object_players.keys():
		var player = scanned_object_players[obj_id]
		if not is_instance_valid(player):
			continue
		
		# Find the object
		var object = null
		for node in get_tree().get_nodes_in_group("resonance_objects"):
			if node.get_instance_id() == obj_id:
				object = node
				break
		
		if object and is_instance_valid(object):
			spatial_audio.update_source_position(player, object.global_position)


func _update_frequency_volumes(delta: float) -> void:
	"""Update volume levels based on interference strength."""
	if not resonance_system or active_frequencies.is_empty():
		return
	
	for frequency in active_frequencies:
		# Find object with this frequency
		var object = _find_object_by_frequency(frequency)
		if not object:
			continue
		
		var amplitude = resonance_system.get_object_amplitude(object)
		var target_volume = clamp(amplitude, 0.1, 1.0)
		
		# Smoothly transition to target volume
		var current_volume = frequency_volumes.get(frequency, 0.5)
		current_volume = lerp(current_volume, target_volume, delta * 2.0)
		frequency_volumes[frequency] = current_volume


func _find_object_by_frequency(frequency: float) -> Node3D:
	"""Find an object with the given frequency."""
	if not resonance_system:
		return null
	
	var tracked_objects: Array[Node3D] = resonance_system.get_tracked_objects()
	for obj in tracked_objects:
		if is_instance_valid(obj):
			var obj_freq: float = resonance_system.get_object_frequency(obj)
			if abs(obj_freq - frequency) < 0.01:
				return obj
	
	return null


func _exit_tree() -> void:
	"""Cleanup when node is removed."""
	# Disconnect all signal connections to prevent memory leaks
	if resonance_system and is_instance_valid(resonance_system):
		if resonance_system.has_signal("object_scanned") and resonance_system.object_scanned.is_connected(_on_object_scanned):
			resonance_system.object_scanned.disconnect(_on_object_scanned)
		if resonance_system.has_signal("interference_applied") and resonance_system.interference_applied.is_connected(_on_interference_applied):
			resonance_system.interference_applied.disconnect(_on_interference_applied)
		if resonance_system.has_signal("object_cancelled") and resonance_system.object_cancelled.is_connected(_on_object_cancelled):
			resonance_system.object_cancelled.disconnect(_on_object_cancelled)

	if resonance_input_controller and is_instance_valid(resonance_input_controller):
		if resonance_input_controller.has_signal("object_scanned") and resonance_input_controller.object_scanned.is_connected(_on_input_object_scanned):
			resonance_input_controller.object_scanned.disconnect(_on_input_object_scanned)
		if resonance_input_controller.has_signal("frequency_emitted") and resonance_input_controller.frequency_emitted.is_connected(_on_frequency_emitted):
			resonance_input_controller.frequency_emitted.disconnect(_on_frequency_emitted)
		if resonance_input_controller.has_signal("emission_stopped") and resonance_input_controller.emission_stopped.is_connected(_on_emission_stopped):
			resonance_input_controller.emission_stopped.disconnect(_on_emission_stopped)
		if resonance_input_controller.has_signal("mode_changed") and resonance_input_controller.mode_changed.is_connected(_on_mode_changed):
			resonance_input_controller.mode_changed.disconnect(_on_mode_changed)
		if resonance_input_controller.has_signal("frequency_switched") and resonance_input_controller.frequency_switched.is_connected(_on_frequency_switched):
			resonance_input_controller.frequency_switched.disconnect(_on_frequency_switched)

	# Stop all audio players
	if emission_player and is_instance_valid(emission_player):
		emission_player.stop()
	if scanning_player and is_instance_valid(scanning_player):
		scanning_player.stop()
	if ambient_resonance_player and is_instance_valid(ambient_resonance_player):
		ambient_resonance_player.stop()

	# Cleanup object players
	for obj_id in scanned_object_players.keys():
		_remove_object_player(obj_id)

	# Clear references to prevent accessing freed nodes
	resonance_system = null
	resonance_input_controller = null
	spatial_audio = null
	audio_manager = null
	procedural_generator = null