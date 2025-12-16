## ProceduralAudioGenerator - Generate Simple Audio for Testing
##
## Generates basic audio tones and noise procedurally for testing purposes.
## NOT suitable for production - use proper audio assets instead.
##
## Usage:
##   var generator = ProceduralAudioGenerator.new()
##   var tone = generator.generate_sine_tone(432.0, 2.0)
##   var player = AudioStreamPlayer.new()
##   player.stream = tone
##   player.play()

extends Node
class_name ProceduralAudioGenerator

## Sample rate for generated audio
const SAMPLE_RATE: int = 44100

## Generate a sine wave tone
func generate_sine_tone(frequency: float, duration: float, amplitude: float = 0.5) -> AudioStreamWAV:
	"""Generate a pure sine wave at the specified frequency."""
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)  # 16-bit samples = 2 bytes each
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var value = sin(2.0 * PI * frequency * t) * amplitude
		var sample = int(value * 32767.0)  # Convert to 16-bit range
		
		# Write as little-endian 16-bit
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	
	# Create AudioStreamWAV
	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	return stream

## Generate a looping sine wave tone
func generate_looping_sine_tone(frequency: float, duration: float, amplitude: float = 0.5) -> AudioStreamWAV:
	"""Generate a looping sine wave tone."""
	var stream = generate_sine_tone(frequency, duration, amplitude)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(SAMPLE_RATE * duration)
	return stream

## Generate harmonic overtones
func generate_harmonic_series(base_frequency: float, num_harmonics: int, duration: float, amplitude: float = 0.5) -> AudioStreamWAV:
	"""Generate a tone with harmonic overtones."""
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var value = 0.0
		
		# Add harmonics with decreasing amplitude
		for h in range(1, num_harmonics + 1):
			var harmonic_freq = base_frequency * h
			var harmonic_amp = amplitude / float(h)  # Decrease amplitude for higher harmonics
			value += sin(2.0 * PI * harmonic_freq * t) * harmonic_amp
		
		# Normalize
		value /= float(num_harmonics)
		var sample = int(value * 32767.0)
		
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	
	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	
	return stream

## Generate white noise
func generate_white_noise(duration: float, amplitude: float = 0.3) -> AudioStreamWAV:
	"""Generate white noise."""
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	for i in range(sample_count):
		var value = (randf() * 2.0 - 1.0) * amplitude
		var sample = int(value * 32767.0)
		
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	
	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	return stream

## Generate a simple beep
func generate_beep(frequency: float, duration: float, amplitude: float = 0.5) -> AudioStreamWAV:
	"""Generate a simple beep with envelope."""
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	var attack_samples = int(SAMPLE_RATE * 0.01)  # 10ms attack
	var release_samples = int(SAMPLE_RATE * 0.05)  # 50ms release
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var value = sin(2.0 * PI * frequency * t)
		
		# Apply envelope
		var envelope = 1.0
		if i < attack_samples:
			envelope = float(i) / attack_samples
		elif i > sample_count - release_samples:
			envelope = float(sample_count - i) / release_samples
		
		value *= envelope * amplitude
		var sample = int(value * 32767.0)
		
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	
	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	return stream

## Generate a sweep (frequency ramp)
func generate_sweep(start_freq: float, end_freq: float, duration: float, amplitude: float = 0.5) -> AudioStreamWAV:
	"""Generate a frequency sweep from start_freq to end_freq."""
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = t / duration
		var frequency = lerp(start_freq, end_freq, progress)
		var value = sin(2.0 * PI * frequency * t) * amplitude
		var sample = int(value * 32767.0)
		
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	
	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	return stream

## Generate a simple click
func generate_click(amplitude: float = 0.8) -> AudioStreamWAV:
	"""Generate a short click sound."""
	var duration = 0.05  # 50ms
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	for i in range(sample_count):
		var envelope = 1.0 - (float(i) / sample_count)  # Linear decay
		var value = (randf() * 2.0 - 1.0) * envelope * amplitude
		var sample = int(value * 32767.0)
		
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	
	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	return stream

## Save generated audio to file
func save_to_file(stream: AudioStreamWAV, path: String) -> Error:
	"""Save an AudioStreamWAV to a WAV file."""
	# Note: Godot doesn't have built-in WAV export, so we'll save as a resource
	var err = ResourceSaver.save(stream, path)
	if err != OK:
		push_error("Failed to save audio to: " + path)
	return err

## Generate all test audio files
func generate_test_audio_files() -> void:
	"""Generate a complete set of test audio files."""
	print("Generating test audio files...")
	
	# Create directories
	DirAccess.make_dir_recursive_absolute("res://data/audio/engine")
	DirAccess.make_dir_recursive_absolute("res://data/audio/tones")
	DirAccess.make_dir_recursive_absolute("res://data/audio/ambient")
	DirAccess.make_dir_recursive_absolute("res://data/audio/ui")
	DirAccess.make_dir_recursive_absolute("res://data/audio/warnings")
	DirAccess.make_dir_recursive_absolute("res://data/audio/environment")
	
	# Generate engine sounds
	print("  Generating engine sounds...")
	save_to_file(generate_looping_sine_tone(100.0, 3.0, 0.3), "res://data/audio/engine/engine_idle.tres")
	save_to_file(generate_looping_sine_tone(300.0, 3.0, 0.4), "res://data/audio/engine/engine_thrust_low.tres")
	save_to_file(generate_looping_sine_tone(600.0, 3.0, 0.5), "res://data/audio/engine/engine_thrust_medium.tres")
	save_to_file(generate_looping_sine_tone(1200.0, 3.0, 0.6), "res://data/audio/engine/engine_thrust_high.tres")
	
	# Generate harmonic tones
	print("  Generating harmonic tones...")
	save_to_file(generate_looping_sine_tone(432.0, 2.0, 0.4), "res://data/audio/tones/base_tone_432hz.tres")
	save_to_file(generate_harmonic_series(432.0, 4, 4.0, 0.3), "res://data/audio/tones/harmonic_overtones.tres")
	
	# Generate ambient sounds (using noise and low tones)
	print("  Generating ambient sounds...")
	save_to_file(generate_white_noise(30.0, 0.1), "res://data/audio/ambient/space_ambient_deep.tres")
	save_to_file(generate_white_noise(30.0, 0.15), "res://data/audio/ambient/space_ambient_nebula.tres")
	save_to_file(generate_looping_sine_tone(60.0, 20.0, 0.2), "res://data/audio/ambient/space_ambient_filament.tres")
	save_to_file(generate_white_noise(15.0, 0.08), "res://data/audio/ambient/cockpit_ambient.tres")
	
	# Generate UI sounds
	print("  Generating UI sounds...")
	save_to_file(generate_click(0.5), "res://data/audio/ui/button_click.tres")
	save_to_file(generate_beep(2000.0, 0.05, 0.3), "res://data/audio/ui/button_hover.tres")
	save_to_file(generate_sweep(200.0, 1000.0, 0.3, 0.4), "res://data/audio/ui/menu_open.tres")
	save_to_file(generate_sweep(1000.0, 200.0, 0.3, 0.4), "res://data/audio/ui/menu_close.tres")
	save_to_file(generate_sweep(400.0, 800.0, 0.2, 0.5), "res://data/audio/ui/confirm.tres")
	save_to_file(generate_sweep(800.0, 400.0, 0.2, 0.5), "res://data/audio/ui/cancel.tres")
	save_to_file(generate_beep(1500.0, 0.3, 0.5), "res://data/audio/ui/resource_collect.tres")
	
	# Generate warning sounds
	print("  Generating warning sounds...")
	save_to_file(generate_beep(1000.0, 0.5, 0.6), "res://data/audio/warnings/warning_danger.tres")
	save_to_file(generate_beep(2000.0, 0.3, 0.7), "res://data/audio/warnings/warning_critical.tres")
	save_to_file(generate_beep(2500.0, 0.2, 0.8), "res://data/audio/warnings/warning_collision.tres")
	save_to_file(generate_beep(800.0, 1.0, 0.5), "res://data/audio/warnings/warning_low_snr.tres")
	save_to_file(generate_beep(200.0, 1.5, 0.6), "res://data/audio/warnings/warning_gravity.tres")
	save_to_file(generate_beep(1200.0, 0.5, 0.5), "res://data/audio/warnings/alert_discovery.tres")
	save_to_file(generate_beep(900.0, 0.5, 0.5), "res://data/audio/warnings/alert_objective.tres")
	
	# Generate environmental sounds
	print("  Generating environmental sounds...")
	save_to_file(generate_white_noise(8.0, 0.5), "res://data/audio/environment/atmospheric_entry.tres")
	save_to_file(generate_white_noise(15.0, 0.3), "res://data/audio/environment/atmospheric_wind.tres")
	save_to_file(generate_sweep(300.0, 150.0, 2.0, 0.4), "res://data/audio/environment/landing_gear.tres")
	save_to_file(generate_white_noise(0.5, 0.8), "res://data/audio/environment/collision_impact.tres")
	
	print("Test audio generation complete!")
	print("Note: These are simple procedural sounds for testing only.")
	print("Replace with proper audio assets for production.")


## Generate real-time frequency tone with dynamic parameters
func generate_realtime_tone(frequency: float, duration: float, amplitude: float = 0.5, 
						   harmonic_content: int = 1, detune: float = 0.0) -> AudioStreamWAV:
	"""Generate a tone with adjustable harmonic content and detuning."""
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var value = 0.0
		
		# Base frequency with optional detuning
		var base_freq = frequency * (1.0 + detune)
		value += sin(2.0 * PI * base_freq * t) * amplitude
		
		# Add harmonics
		for h in range(2, harmonic_content + 1):
			var harmonic_freq = base_freq * h
			var harmonic_amp = amplitude / float(h * h)  # Square law for smoother harmonics
			value += sin(2.0 * PI * harmonic_freq * t) * harmonic_amp
		
		# Normalize based on harmonic content
		var normalization_factor = 1.0 + float(harmonic_content - 1) * 0.5
		value /= normalization_factor
		
		var sample = int(value * 32767.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	
	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	return stream

## Generate interference pattern tone (beating effect)
func generate_interference_tone(freq1: float, freq2: float, duration: float, amplitude: float = 0.5) -> AudioStreamWAV:
	"""Generate a tone that demonstrates interference between two frequencies."""
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var value = 0.0
		
		# Sum of two close frequencies creates beating
		value += sin(2.0 * PI * freq1 * t) * amplitude * 0.5
		value += sin(2.0 * PI * freq2 * t) * amplitude * 0.5
		
		var sample = int(value * 32767.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	
	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	return stream

## Generate resonance scanning tone (building pitch)
func generate_scanning_tone(start_freq: float, end_freq: float, duration: float, amplitude: float = 0.5) -> AudioStreamWAV:
	"""Generate a scanning tone that builds from start to end frequency."""
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = t / duration
		
		# Exponential frequency sweep for more natural scanning sound
		var frequency = start_freq * pow(end_freq / start_freq, progress)
		var value = sin(2.0 * PI * frequency * t) * amplitude
		
		# Add subtle amplitude envelope
		var envelope = 0.5 + 0.5 * sin(PI * progress)  # Build up then fade
		value *= envelope
		
		var sample = int(value * 32767.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	
	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	return stream

## Generate cancellation/dissolution sound
func generate_cancellation_sound(duration: float = 1.0, amplitude: float = 0.7) -> AudioStreamWAV:
	"""Generate a dissolution/cancellation sound effect."""
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = t / duration
		
		# Descending frequency with noise
		var base_freq = 1000.0 * (1.0 - progress * 0.9)  # Drop to 100Hz
		var value = sin(2.0 * PI * base_freq * t) * amplitude
		
		# Add increasing noise for dissolution effect
		var noise_amount = progress * 0.5
		value += (randf() * 2.0 - 1.0) * noise_amount * amplitude
		
		# Apply fade out envelope
		var envelope = 1.0 - progress
		value *= envelope
		
		var sample = int(value * 32767.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	
	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	return stream

## Generate short confirmation chirp
func generate_confirmation_chirp(frequency: float, amplitude: float = 0.5) -> AudioStreamWAV:
	"""Generate a short confirmation chirp sound."""
	var duration = 0.1
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	var attack_samples = int(SAMPLE_RATE * 0.02)  # 20ms attack
	var release_samples = int(SAMPLE_RATE * 0.08)  # 80ms release
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var value = sin(2.0 * PI * frequency * t) * amplitude
		
		# Apply sharp attack/release envelope
		var envelope = 1.0
		if i < attack_samples:
			envelope = float(i) / attack_samples
		elif i > sample_count - release_samples:
			envelope = float(sample_count - i) / release_samples
		
		value *= envelope
		
		var sample = int(value * 32767.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	
	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	return stream