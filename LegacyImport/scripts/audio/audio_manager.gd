## AudioManager - Central Audio Management System
##
## Manages audio loading, caching, playback, mixing, and settings persistence.
## Serves as the central hub for all audio in the game.
##
## Requirements: 65.1, 65.2, 65.3, 65.4, 65.5

extends Node
class_name AudioManager

## Audio cache for loaded streams
var audio_cache: Dictionary = {}

## Audio settings
var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 1.0
var ambient_volume: float = 0.5

## Audio bus indices
var master_bus: int = 0
var music_bus: int = -1
var sfx_bus: int = -1
var ambient_bus: int = -1

## Music player
var music_player: AudioStreamPlayer = null
var current_music_track: String = ""

## Settings file path
const SETTINGS_PATH: String = "user://audio_settings.cfg"

## Reference to subsystems
var spatial_audio: SpatialAudio = null
var audio_feedback: AudioFeedback = null

## Initialize the audio manager
func _ready() -> void:
	# Setup audio buses
	setup_audio_buses()
	
	# Create music player
	setup_music_player()
	
	# Load settings
	load_settings()
	
	# Apply initial volumes
	apply_volume_settings()
	
	print("AudioManager initialized")
	print("  Master volume: ", master_volume)
	print("  Music volume: ", music_volume)
	print("  SFX volume: ", sfx_volume)

## Setup audio buses
## Requirement 65.5: Mix up to 256 simultaneous channels using AudioBusLayout
func setup_audio_buses() -> void:
	# Get master bus
	master_bus = AudioServer.get_bus_index("Master")
	
	# Create or get music bus
	music_bus = AudioServer.get_bus_index("Music")
	if music_bus == -1:
		AudioServer.add_bus()
		music_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(music_bus, "Music")
		AudioServer.set_bus_send(music_bus, "Master")
	
	# Create or get SFX bus
	sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus == -1:
		AudioServer.add_bus()
		sfx_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(sfx_bus, "SFX")
		AudioServer.set_bus_send(sfx_bus, "Master")
	
	# Create or get ambient bus
	ambient_bus = AudioServer.get_bus_index("Ambient")
	if ambient_bus == -1:
		AudioServer.add_bus()
		ambient_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(ambient_bus, "Ambient")
		AudioServer.set_bus_send(ambient_bus, "Master")

## Setup music player
## Requirement 65.4: Handle audio streaming for music
func setup_music_player() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

## Load an audio file and cache it
## Requirement 65.1: Load and cache audio files using ResourceLoader
func load_audio(path: String) -> AudioStream:
	"""Load an audio file and cache it for future use."""
	# Check cache first
	if audio_cache.has(path):
		return audio_cache[path]
	
	# Load the audio file
	var stream = ResourceLoader.load(path)
	if stream and stream is AudioStream:
		audio_cache[path] = stream
		return stream
	else:
		push_error("AudioManager: Failed to load audio file: " + path)
		return null

## Preload multiple audio files
func preload_audio_files(paths: Array[String]) -> void:
	"""Preload multiple audio files into the cache."""
	for path in paths:
		load_audio(path)

## Clear audio cache
func clear_cache() -> void:
	"""Clear the audio cache to free memory."""
	audio_cache.clear()

## Play a sound effect
## Requirement 65.2: Manage sound playback and mixing
func play_sfx(path: String, volume_db: float = 0.0) -> AudioStreamPlayer:
	"""Play a sound effect."""
	var stream = load_audio(path)
	if not stream:
		return null
	
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "SFX"
	player.volume_db = volume_db
	add_child(player)
	player.play()
	
	# Auto-cleanup when finished
	player.finished.connect(func(): player.queue_free())
	
	return player

## Play a 3D sound effect at a position
func play_sfx_3d(path: String, position: Vector3, volume_db: float = 0.0) -> AudioStreamPlayer3D:
	"""Play a 3D sound effect at a specific position."""
	if not spatial_audio:
		push_warning("AudioManager: SpatialAudio not available")
		return null
	
	var stream = load_audio(path)
	if not stream:
		return null
	
	return spatial_audio.play_sound_at_position(stream, position, volume_db)

## Play music
## Requirement 65.4: Handle audio streaming for music
func play_music(path: String, fade_in_duration: float = 1.0) -> void:
	"""Play a music track with optional fade-in."""
	var stream = load_audio(path)
	if not stream:
		return
	
	# Stop current music if playing
	if music_player.playing:
		stop_music(fade_in_duration)
		await get_tree().create_timer(fade_in_duration).timeout
	
	# Set new music
	music_player.stream = stream
	current_music_track = path
	
	# Fade in
	if fade_in_duration > 0.0:
		music_player.volume_db = -80.0
		music_player.play()
		
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), fade_in_duration)
	else:
		music_player.volume_db = linear_to_db(music_volume)
		music_player.play()

## Stop music
func stop_music(fade_out_duration: float = 1.0) -> void:
	"""Stop the current music track with optional fade-out."""
	if not music_player.playing:
		return
	
	if fade_out_duration > 0.0:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, fade_out_duration)
		tween.finished.connect(func(): music_player.stop())
	else:
		music_player.stop()
	
	current_music_track = ""

## Pause music
func pause_music() -> void:
	"""Pause the current music track."""
	if music_player.playing:
		music_player.stream_paused = true

## Resume music
func resume_music() -> void:
	"""Resume the paused music track."""
	if music_player.stream_paused:
		music_player.stream_paused = false

## Check if music is playing
func is_music_playing() -> bool:
	"""Check if music is currently playing."""
	return music_player.playing and not music_player.stream_paused

## Get current music track
func get_current_music() -> String:
	"""Get the path of the currently playing music track."""
	return current_music_track

## Set master volume
## Requirement 65.3: Control volume levels via AudioServer
func set_master_volume(volume: float) -> void:
	"""Set the master volume (0.0 to 1.0)."""
	master_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(master_volume))
	save_settings()

## Set music volume
func set_music_volume(volume: float) -> void:
	"""Set the music volume (0.0 to 1.0)."""
	music_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(music_volume))
	save_settings()

## Set SFX volume
func set_sfx_volume(volume: float) -> void:
	"""Set the sound effects volume (0.0 to 1.0)."""
	sfx_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume))
	save_settings()

## Set ambient volume
func set_ambient_volume(volume: float) -> void:
	"""Set the ambient sound volume (0.0 to 1.0)."""
	ambient_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(ambient_bus, linear_to_db(ambient_volume))
	save_settings()

## Get master volume
func get_master_volume() -> float:
	"""Get the master volume (0.0 to 1.0)."""
	return master_volume

## Get music volume
func get_music_volume() -> float:
	"""Get the music volume (0.0 to 1.0)."""
	return music_volume

## Get SFX volume
func get_sfx_volume() -> float:
	"""Get the SFX volume (0.0 to 1.0)."""
	return sfx_volume

## Get ambient volume
func get_ambient_volume() -> float:
	"""Get the ambient volume (0.0 to 1.0)."""
	return ambient_volume

## Apply volume settings to audio buses
func apply_volume_settings() -> void:
	"""Apply current volume settings to all audio buses."""
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(master_volume))
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(music_volume))
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume))
	AudioServer.set_bus_volume_db(ambient_bus, linear_to_db(ambient_volume))

## Save audio settings
## Requirement 65.5: Implement audio settings persistence using ConfigFile
func save_settings() -> void:
	"""Save audio settings to disk."""
	var config = ConfigFile.new()
	
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "ambient_volume", ambient_volume)
	
	var err = config.save(SETTINGS_PATH)
	if err != OK:
		push_error("AudioManager: Failed to save settings: " + error_string(err))

## Load audio settings
## Requirement 65.5: Implement audio settings persistence using ConfigFile
func load_settings() -> void:
	"""Load audio settings from disk."""
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	
	if err != OK:
		# Settings file doesn't exist or failed to load, use defaults
		print("AudioManager: Using default audio settings")
		return
	
	master_volume = config.get_value("audio", "master_volume", 1.0)
	music_volume = config.get_value("audio", "music_volume", 0.7)
	sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
	ambient_volume = config.get_value("audio", "ambient_volume", 0.5)
	
	print("AudioManager: Loaded audio settings from disk")

## Mute all audio
func mute_all() -> void:
	"""Mute all audio."""
	AudioServer.set_bus_mute(master_bus, true)

## Unmute all audio
func unmute_all() -> void:
	"""Unmute all audio."""
	AudioServer.set_bus_mute(master_bus, false)

## Check if audio is muted
func is_muted() -> bool:
	"""Check if audio is muted."""
	return AudioServer.is_bus_mute(master_bus)

## Set spatial audio reference
func set_spatial_audio(spatial: SpatialAudio) -> void:
	"""Set the spatial audio system reference."""
	spatial_audio = spatial

## Set audio feedback reference
func set_audio_feedback(feedback: AudioFeedback) -> void:
	"""Set the audio feedback system reference."""
	audio_feedback = feedback

## Get spatial audio system
func get_spatial_audio() -> SpatialAudio:
	"""Get the spatial audio system."""
	return spatial_audio

## Get audio feedback system
func get_audio_feedback() -> AudioFeedback:
	"""Get the audio feedback system."""
	return audio_feedback

## Convert linear volume to decibels
func linear_to_db(linear: float) -> float:
	"""Convert linear volume (0.0 to 1.0) to decibels."""
	if linear <= 0.0:
		return -80.0  # Effectively muted
	return 20.0 * log(linear) / log(10.0)

## Convert decibels to linear volume
func db_to_linear(db: float) -> float:
	"""Convert decibels to linear volume (0.0 to 1.0)."""
	if db <= -80.0:
		return 0.0
	return pow(10.0, db / 20.0)
