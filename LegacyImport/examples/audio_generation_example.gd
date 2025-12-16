## Audio Generation Example
##
## Demonstrates how to use the ProceduralAudioGenerator to create test audio files.
## This is for testing purposes only - use proper audio assets for production.
##
## Usage:
##   1. Attach this script to a Node in your scene
##   2. Run the scene
##   3. Audio files will be generated in data/audio/ subdirectories
##   4. Check the console for progress messages

extends Node

## Reference to the audio generator
var generator: ProceduralAudioGenerator = null

## Reference to audio manager
var audio_manager: Node = null

func _ready() -> void:
	print("\n=== Audio Generation Example ===\n")
	
	# Create generator
	generator = ProceduralAudioGenerator.new()
	add_child(generator)
	
	# Get audio manager
	audio_manager = get_node_or_null("/root/AudioManager")
	
	# Generate all test audio files
	print("Generating test audio files...")
	generator.generate_test_audio_files()
	
	# Wait a moment for files to be created
	await get_tree().create_timer(1.0).timeout
	
	# Test playing some generated audio
	test_audio_playback()

## Test audio playback
func test_audio_playback() -> void:
	print("\n=== Testing Audio Playback ===\n")
	
	# Test 1: Play 432Hz base tone
	print("Test 1: Playing 432Hz base tone...")
	var base_tone = generator.generate_looping_sine_tone(432.0, 2.0, 0.3)
	var player1 = AudioStreamPlayer.new()
	player1.stream = base_tone
	player1.volume_db = -10.0
	add_child(player1)
	player1.play()
	
	await get_tree().create_timer(3.0).timeout
	player1.stop()
	player1.queue_free()
	
	# Test 2: Play harmonic series
	print("Test 2: Playing harmonic series...")
	var harmonics = generator.generate_harmonic_series(432.0, 4, 3.0, 0.3)
	var player2 = AudioStreamPlayer.new()
	player2.stream = harmonics
	player2.volume_db = -10.0
	add_child(player2)
	player2.play()
	
	await get_tree().create_timer(4.0).timeout
	player2.stop()
	player2.queue_free()
	
	# Test 3: Play UI beep
	print("Test 3: Playing UI beep...")
	var beep = generator.generate_beep(1000.0, 0.3, 0.5)
	var player3 = AudioStreamPlayer.new()
	player3.stream = beep
	player3.volume_db = -5.0
	add_child(player3)
	player3.play()
	
	await get_tree().create_timer(1.0).timeout
	player3.queue_free()
	
	# Test 4: Play frequency sweep
	print("Test 4: Playing frequency sweep...")
	var sweep = generator.generate_sweep(200.0, 2000.0, 1.0, 0.4)
	var player4 = AudioStreamPlayer.new()
	player4.stream = sweep
	player4.volume_db = -5.0
	add_child(player4)
	player4.play()
	
	await get_tree().create_timer(1.5).timeout
	player4.queue_free()
	
	# Test 5: Play white noise
	print("Test 5: Playing white noise...")
	var noise = generator.generate_white_noise(2.0, 0.2)
	var player5 = AudioStreamPlayer.new()
	player5.stream = noise
	player5.volume_db = -15.0
	add_child(player5)
	player5.play()
	
	await get_tree().create_timer(2.5).timeout
	player5.queue_free()
	
	print("\n=== Audio Playback Tests Complete ===\n")
	print("All test audio files have been generated.")
	print("Check data/audio/ subdirectories for .tres files.")
	print("\nNote: These are simple procedural sounds for testing only.")
	print("Replace with proper audio assets for production.")
	print("\nSee data/audio/AUDIO_ASSETS_GUIDE.md for detailed specifications.")

## Generate individual audio files on demand
func generate_custom_audio() -> void:
	"""Example of generating custom audio files."""
	
	# Generate a custom tone
	var custom_tone = generator.generate_sine_tone(880.0, 1.0, 0.5)  # A5 note
	generator.save_to_file(custom_tone, "res://data/audio/custom_tone.tres")
	
	# Generate a custom beep pattern
	var custom_beep = generator.generate_beep(1500.0, 0.2, 0.6)
	generator.save_to_file(custom_beep, "res://data/audio/custom_beep.tres")
	
	print("Custom audio files generated!")

## Test audio with AudioManager
func test_with_audio_manager() -> void:
	"""Test generated audio with the AudioManager system."""
	if not audio_manager:
		print("AudioManager not found!")
		return
	
	print("\n=== Testing with AudioManager ===\n")
	
	# Load and play a generated audio file
	var tone_path = "res://data/audio/tones/base_tone_432hz.tres"
	if ResourceLoader.exists(tone_path):
		print("Playing base tone through AudioManager...")
		audio_manager.play_sfx(tone_path, -10.0)
	else:
		print("Audio file not found: " + tone_path)
		print("Run generate_test_audio_files() first!")
