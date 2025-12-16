# Audio System API Reference

Complete API documentation for all five audio subsystems in SpaceTime.

## Table of Contents

1. [AudioManager](#audiomanager)
2. [SpatialAudio](#spatialaudio)
3. [ProceduralAudioGenerator](#proceduralaudiogenerator)
4. [ResonanceAudioFeedback](#resonanceaudiofeedback)
5. [AudioFeedback](#audiofeedback)
6. [Common Types](#common-types)
7. [Signal Reference](#signal-reference)

---

## AudioManager

**File:** `C:/godot/scripts/audio/audio_manager.gd`
**Class:** `AudioManager` (extends Node)
**Purpose:** Central audio management hub for loading, caching, playback, and settings

### Properties

#### Audio Settings
```gdscript
var master_volume: float = 1.0     # Master volume (0.0-1.0)
var music_volume: float = 0.7      # Music volume (0.0-1.0)
var sfx_volume: float = 1.0        # SFX volume (0.0-1.0)
var ambient_volume: float = 0.5    # Ambient volume (0.0-1.0)
```

#### Audio Buses
```gdscript
var master_bus: int = 0            # Master bus index
var music_bus: int = -1            # Music bus index
var sfx_bus: int = -1              # SFX bus index
var ambient_bus: int = -1          # Ambient bus index
```

#### Subsystem References
```gdscript
var spatial_audio: SpatialAudio = null        # Reference to spatial audio system
var audio_feedback: AudioFeedback = null      # Reference to audio feedback system
```

#### Internal State
```gdscript
var audio_cache: Dictionary = {}              # Key: path, Value: AudioStream
var music_player: AudioStreamPlayer = null    # Background music player
var current_music_track: String = ""          # Currently playing track path
```

#### Constants
```gdscript
const SETTINGS_PATH: String = "user://audio_settings.cfg"
```

### Methods

#### Initialization

##### `_ready() -> void`
Initializes the audio manager:
- Sets up audio buses
- Creates music player
- Loads saved settings
- Applies volume levels

**Called automatically** when node enters scene tree.

##### `setup_audio_buses() -> void`
Creates or retrieves audio buses:
- Master, Music, SFX, Ambient buses
- Sets up bus routing (all send to Master)

**Requirements:** 65.5 - Mix up to 256 simultaneous channels using AudioBusLayout

##### `setup_music_player() -> void`
Creates the background music player:
- AudioStreamPlayer on Music bus
- Handles music playback and streaming

**Requirements:** 65.4 - Handle audio streaming for music

#### Audio Loading

##### `load_audio(path: String) -> AudioStream`
Load and cache an audio file.

**Parameters:**
- `path`: Resource path to audio file (e.g., "res://data/audio/sound.ogg")

**Returns:**
- `AudioStream` if successful
- `null` if loading failed

**Behavior:**
- Checks cache first (returns cached stream if available)
- Loads via ResourceLoader if not cached
- Caches newly loaded streams
- Prints error on failure

**Requirements:** 65.1 - Load and cache audio files using ResourceLoader

**Example:**
```gdscript
var stream = audio_mgr.load_audio("res://data/audio/explosion.ogg")
if stream:
    print("Loaded successfully")
```

##### `preload_audio_files(paths: Array[String]) -> void`
Preload multiple audio files into cache.

**Parameters:**
- `paths`: Array of resource paths

**Use case:** Preload frequently used sounds during loading screen

**Example:**
```gdscript
audio_mgr.preload_audio_files([
    "res://data/audio/ui/click.ogg",
    "res://data/audio/ui/hover.ogg",
    "res://data/audio/sfx/thrust.ogg"
])
```

##### `clear_cache() -> void`
Clear all cached audio streams.

**Use case:** Free memory after scene transitions

**Warning:** Subsequent audio loads will reload from disk

#### Sound Playback

##### `play_sfx(path: String, volume_db: float = 0.0) -> AudioStreamPlayer`
Play a 2D sound effect.

**Parameters:**
- `path`: Resource path to audio file
- `volume_db`: Volume in decibels (default: 0.0)

**Returns:**
- `AudioStreamPlayer` node (or `null` on failure)

**Behavior:**
- Creates new AudioStreamPlayer
- Plays on SFX bus
- Auto-cleanup when finished

**Requirements:** 65.2 - Manage sound playback and mixing

**Example:**
```gdscript
audio_mgr.play_sfx("res://data/audio/ui/click.ogg", -5.0)
```

##### `play_sfx_3d(path: String, position: Vector3, volume_db: float = 0.0) -> AudioStreamPlayer3D`
Play a 3D sound effect at a position.

**Parameters:**
- `path`: Resource path to audio file
- `position`: 3D world position
- `volume_db`: Volume in decibels (default: 0.0)

**Returns:**
- `AudioStreamPlayer3D` node (or `null` on failure)

**Behavior:**
- Delegates to `SpatialAudio.play_sound_at_position()`
- Auto-cleanup when finished

**Requirements:** 65.1 - Use AudioStreamPlayer3D for 3D audio

**Example:**
```gdscript
audio_mgr.play_sfx_3d(
    "res://data/audio/explosion.ogg",
    Vector3(100, 0, 50),
    -3.0
)
```

#### Music Playback

##### `play_music(path: String, fade_in_duration: float = 1.0) -> void`
Play a music track with fade-in.

**Parameters:**
- `path`: Resource path to music file
- `fade_in_duration`: Fade-in time in seconds (default: 1.0)

**Behavior:**
- Stops current music with fade-out
- Waits for fade-out to complete
- Starts new music with fade-in
- Uses tweens for smooth transitions

**Requirements:** 65.4 - Handle audio streaming for music

**Example:**
```gdscript
audio_mgr.play_music("res://data/audio/music/exploration.ogg", 2.0)
```

##### `stop_music(fade_out_duration: float = 1.0) -> void`
Stop current music with fade-out.

**Parameters:**
- `fade_out_duration`: Fade-out time in seconds (default: 1.0)

**Example:**
```gdscript
audio_mgr.stop_music(3.0)  # 3 second fade-out
```

##### `pause_music() -> void`
Pause the current music track.

**Behavior:**
- Sets `stream_paused = true`
- Music position preserved

##### `resume_music() -> void`
Resume the paused music track.

**Behavior:**
- Sets `stream_paused = false`
- Resumes from paused position

##### `is_music_playing() -> bool`
Check if music is currently playing.

**Returns:**
- `true` if playing and not paused
- `false` otherwise

##### `get_current_music() -> String`
Get the path of the currently playing music track.

**Returns:**
- Resource path to current track
- Empty string if no music playing

#### Volume Control

##### `set_master_volume(volume: float) -> void`
Set master volume level.

**Parameters:**
- `volume`: Volume level (0.0 to 1.0)

**Behavior:**
- Clamps to valid range
- Converts to decibels
- Saves settings to disk

**Requirements:** 65.3 - Control volume levels via AudioServer

**Example:**
```gdscript
audio_mgr.set_master_volume(0.8)  # 80% volume
```

##### `set_music_volume(volume: float) -> void`
Set music volume level.

**Parameters:**
- `volume`: Volume level (0.0 to 1.0)

##### `set_sfx_volume(volume: float) -> void`
Set sound effects volume level.

**Parameters:**
- `volume`: Volume level (0.0 to 1.0)

##### `set_ambient_volume(volume: float) -> void`
Set ambient sounds volume level.

**Parameters:**
- `volume`: Volume level (0.0 to 1.0)

##### `get_master_volume() -> float`
Get current master volume.

**Returns:** Volume level (0.0 to 1.0)

##### `get_music_volume() -> float`
Get current music volume.

**Returns:** Volume level (0.0 to 1.0)

##### `get_sfx_volume() -> float`
Get current SFX volume.

**Returns:** Volume level (0.0 to 1.0)

##### `get_ambient_volume() -> float`
Get current ambient volume.

**Returns:** Volume level (0.0 to 1.0)

##### `apply_volume_settings() -> void`
Apply all volume settings to audio buses.

**Use case:** Refresh volumes after manual changes

#### Mute Controls

##### `mute_all() -> void`
Mute all audio output.

**Behavior:**
- Sets Master bus mute flag
- Volume settings preserved

##### `unmute_all() -> void`
Unmute all audio output.

##### `is_muted() -> bool`
Check if audio is muted.

**Returns:**
- `true` if muted
- `false` otherwise

#### Settings Persistence

##### `save_settings() -> void`
Save audio settings to disk.

**Behavior:**
- Saves to `user://audio_settings.cfg`
- Stores all volume levels
- Called automatically when volumes change

**Requirements:** 65.5 - Implement audio settings persistence using ConfigFile

##### `load_settings() -> void`
Load audio settings from disk.

**Behavior:**
- Loads from `user://audio_settings.cfg`
- Uses defaults if file doesn't exist
- Called automatically on initialization

#### Subsystem Integration

##### `set_spatial_audio(spatial: SpatialAudio) -> void`
Set reference to spatial audio system.

**Parameters:**
- `spatial`: SpatialAudio instance

##### `set_audio_feedback(feedback: AudioFeedback) -> void`
Set reference to audio feedback system.

**Parameters:**
- `feedback`: AudioFeedback instance

##### `get_spatial_audio() -> SpatialAudio`
Get spatial audio system reference.

**Returns:** SpatialAudio instance (or `null`)

##### `get_audio_feedback() -> AudioFeedback`
Get audio feedback system reference.

**Returns:** AudioFeedback instance (or `null`)

#### Utility Functions

##### `linear_to_db(linear: float) -> float`
Convert linear volume (0.0-1.0) to decibels.

**Parameters:**
- `linear`: Linear volume (0.0 to 1.0)

**Returns:**
- Decibels (-80.0 to 0.0+)
- -80.0 if linear <= 0.0 (effectively muted)

**Formula:** `20.0 * log10(linear)`

**Example:**
```gdscript
var db = audio_mgr.linear_to_db(0.5)  # Returns approximately -6.02 dB
```

##### `db_to_linear(db: float) -> float`
Convert decibels to linear volume (0.0-1.0).

**Parameters:**
- `db`: Decibels

**Returns:**
- Linear volume (0.0 to 1.0+)
- 0.0 if db <= -80.0

**Formula:** `10.0 ^ (db / 20.0)`

**Example:**
```gdscript
var linear = audio_mgr.db_to_linear(-6.0)  # Returns approximately 0.5
```

---

## SpatialAudio

**File:** `C:/godot/scripts/audio/spatial_audio.gd`
**Class:** `SpatialAudio` (extends Node)
**Purpose:** 3D spatial audio with distance attenuation, Doppler shift, and reverb

### Properties

#### Configuration
```gdscript
@export var reference_distance: float = 10.0      # Reference distance (game units)
@export var max_distance: float = 1000.0          # Maximum audible distance
@export var attenuation_model: String = "inverse_square"  # Attenuation type
@export var enable_doppler: bool = true           # Enable Doppler shift
@export var doppler_factor: float = 1.0           # Doppler intensity (0.0-1.0)
@export var enable_reverb: bool = true            # Enable environmental reverb
@export var reverb_room_size: float = 0.5         # Reverb room size (0.0-1.0)
@export var reverb_damping: float = 0.5           # Reverb damping (0.0-1.0)
```

#### Internal State
```gdscript
var active_sources: Array[AudioStreamPlayer3D] = []  # Active audio sources
var spatial_bus_index: int = -1                      # Spatial audio bus
var reverb_bus_index: int = -1                       # Reverb bus
var listener: Node3D = null                          # Audio listener (VR camera)
```

#### Constants
```gdscript
const MAX_CHANNELS: int = 256                        # Maximum simultaneous sources
```

### Methods

#### Initialization

##### `_ready() -> void`
Initialize spatial audio system:
- Setup audio buses
- Find VR camera listener
- Configure reverb effects

##### `setup_audio_buses() -> void`
Create spatial and reverb audio buses.

**Requirements:** 65.5 - Mix up to 256 simultaneous channels using AudioBusLayout

##### `find_listener() -> void`
Find the audio listener (VR camera).

**Behavior:**
- Searches for XRCamera3D first
- Falls back to any Camera3D
- Prints warning if no listener found

#### Audio Source Creation

##### `create_audio_source(stream: AudioStream, position: Vector3, autoplay: bool = true) -> AudioStreamPlayer3D`
Create a new 3D audio source.

**Parameters:**
- `stream`: AudioStream to play
- `position`: 3D world position
- `autoplay`: Start playing immediately (default: true)

**Returns:**
- `AudioStreamPlayer3D` node
- `null` if max channels reached

**Behavior:**
- Creates AudioStreamPlayer3D
- Sets attenuation model
- Configures Doppler tracking
- Adds to scene tree
- Tracks in active_sources array

**Requirements:** 65.1 - Use AudioStreamPlayer3D for 3D audio positioning

**Example:**
```gdscript
var source = spatial_audio.create_audio_source(
    my_stream,
    Vector3(10, 5, 20),
    true
)
```

##### `play_sound_at_position(stream: AudioStream, position: Vector3, volume_db: float = 0.0) -> AudioStreamPlayer3D`
Play a one-shot sound at a position.

**Parameters:**
- `stream`: AudioStream to play
- `position`: 3D world position
- `volume_db`: Volume in decibels (default: 0.0)

**Returns:**
- `AudioStreamPlayer3D` node

**Behavior:**
- Creates audio source
- Plays immediately
- Auto-cleanup when finished

**Example:**
```gdscript
spatial_audio.play_sound_at_position(
    explosion_sound,
    explosion_pos,
    -5.0
)
```

##### `play_looping_sound(stream: AudioStream, position: Vector3, volume_db: float = 0.0) -> AudioStreamPlayer3D`
Play a looping sound at a position.

**Parameters:**
- `stream`: AudioStream to play (should have loop enabled)
- `position`: 3D world position
- `volume_db`: Volume in decibels (default: 0.0)

**Returns:**
- `AudioStreamPlayer3D` node

**Behavior:**
- Creates audio source
- Enables looping
- Plays immediately
- Manual cleanup required

**Example:**
```gdscript
var engine_source = spatial_audio.play_looping_sound(
    engine_sound,
    spacecraft.global_position,
    -10.0
)
```

#### Audio Source Management

##### `remove_audio_source(source: AudioStreamPlayer3D) -> void`
Remove and cleanup an audio source.

**Parameters:**
- `source`: AudioStreamPlayer3D to remove

**Behavior:**
- Stops playback
- Removes from active_sources
- Queues for deletion

**Example:**
```gdscript
spatial_audio.remove_audio_source(engine_source)
```

##### `cleanup_inactive_sources() -> void`
Remove inactive audio sources.

**Behavior:**
- Checks all active sources
- Removes non-playing and invalid sources
- Called automatically every 60 frames

##### `update_source_position(source: AudioStreamPlayer3D, position: Vector3) -> void`
Update an audio source's position.

**Parameters:**
- `source`: AudioStreamPlayer3D to update
- `position`: New 3D world position

**Example:**
```gdscript
func _process(delta):
    spatial_audio.update_source_position(
        engine_source,
        spacecraft.global_position
    )
```

##### `stop_all() -> void`
Stop and remove all audio sources.

**Use case:** Scene transitions, game state resets

##### `get_active_source_count() -> int`
Get number of active audio sources.

**Returns:**
- Count of currently playing sources

**Use case:** Performance monitoring

**Example:**
```gdscript
if spatial_audio.get_active_source_count() > 64:
    print("Warning: High audio source count")
```

#### Listener Management

##### `set_listener(new_listener: Node3D) -> void`
Set the audio listener node.

**Parameters:**
- `new_listener`: Node3D to use as listener (usually Camera3D/XRCamera3D)

**Note:** Usually handled automatically

##### `get_listener() -> Node3D`
Get the current audio listener.

**Returns:**
- Current listener node
- `null` if not set

#### Distance Attenuation

##### `calculate_attenuation(distance: float) -> float`
Calculate volume attenuation for a given distance.

**Parameters:**
- `distance`: Distance from listener to source

**Returns:**
- Attenuation factor (0.0 to 1.0)

**Attenuation Models:**
- **inverse**: `reference_distance / distance`
- **inverse_square**: `reference_distance² / distance²`
- **linear**: Linear fade from reference to max distance
- **exponential**: Exponential decay

**Requirements:** 65.2 - Calculate distance attenuation

**Example:**
```gdscript
var dist = 50.0
var attenuation = spatial_audio.calculate_attenuation(dist)
print("Attenuation at ", dist, "m: ", attenuation)
```

#### Doppler Shift

##### `calculate_doppler_shift(source_velocity: Vector3, listener_velocity: Vector3, source_to_listener: Vector3) -> float`
Calculate Doppler shift factor for pitch adjustment.

**Parameters:**
- `source_velocity`: Source velocity vector
- `listener_velocity`: Listener velocity vector
- `source_to_listener`: Direction from source to listener

**Returns:**
- Pitch scale factor (0.5 to 2.0)
- 1.0 = no shift
- >1.0 = higher pitch (approaching)
- <1.0 = lower pitch (receding)

**Formula:** Based on Doppler effect with configurable factor

**Requirements:** 65.3 - Implement Doppler shift for moving sources using doppler_tracking

**Example:**
```gdscript
var doppler = spatial_audio.calculate_doppler_shift(
    spacecraft_velocity,
    player_velocity,
    (player_pos - spacecraft_pos).normalized()
)
source.pitch_scale = doppler
```

#### Reverb Control

##### `set_reverb_parameters(room_size: float, damping: float) -> void`
Set reverb room size and damping.

**Parameters:**
- `room_size`: Room size (0.0 to 1.0)
- `damping`: Damping amount (0.0 to 1.0)

**Requirements:** 65.4 - Apply environment reverb using AudioEffectReverb

**Example:**
```gdscript
# Small, damped room (cockpit)
spatial_audio.set_reverb_parameters(0.3, 0.7)

# Large, reflective space (hangar)
spatial_audio.set_reverb_parameters(0.8, 0.3)
```

##### `set_reverb_enabled(enabled: bool) -> void`
Enable or disable reverb effect.

**Parameters:**
- `enabled`: True to enable, false to disable

**Example:**
```gdscript
# Disable reverb in open space
spatial_audio.set_reverb_enabled(false)
```

#### Processing

##### `_process(_delta: float) -> void`
Called every frame.

**Behavior:**
- Periodic cleanup of inactive sources (every 60 frames)

---

## ProceduralAudioGenerator

**File:** `C:/godot/scripts/audio/procedural_audio_generator.gd`
**Class:** `ProceduralAudioGenerator` (extends Node)
**Purpose:** Generate audio waveforms procedurally for testing and dynamic audio

### Constants

```gdscript
const SAMPLE_RATE: int = 44100  # Sample rate for all generated audio
```

### Methods

#### Basic Waveforms

##### `generate_sine_tone(frequency: float, duration: float, amplitude: float = 0.5) -> AudioStreamWAV`
Generate a pure sine wave tone.

**Parameters:**
- `frequency`: Frequency in Hz
- `duration`: Duration in seconds
- `amplitude`: Amplitude (0.0 to 1.0, default: 0.5)

**Returns:**
- `AudioStreamWAV` with generated tone

**Example:**
```gdscript
var generator = ProceduralAudioGenerator.new()
var tone_440 = generator.generate_sine_tone(440.0, 2.0, 0.5)
```

##### `generate_looping_sine_tone(frequency: float, duration: float, amplitude: float = 0.5) -> AudioStreamWAV`
Generate a looping sine wave tone.

**Parameters:**
- `frequency`: Frequency in Hz
- `duration`: Loop duration in seconds
- `amplitude`: Amplitude (0.0 to 1.0)

**Returns:**
- `AudioStreamWAV` with loop enabled

**Example:**
```gdscript
var loop_tone = generator.generate_looping_sine_tone(432.0, 2.0, 0.4)
```

##### `generate_harmonic_series(base_frequency: float, num_harmonics: int, duration: float, amplitude: float = 0.5) -> AudioStreamWAV`
Generate a tone with harmonic overtones.

**Parameters:**
- `base_frequency`: Base frequency in Hz
- `num_harmonics`: Number of harmonics to include
- `duration`: Duration in seconds
- `amplitude`: Base amplitude (0.0 to 1.0)

**Returns:**
- `AudioStreamWAV` with harmonic series

**Behavior:**
- Each harmonic has amplitude divided by harmonic number
- Creates richer, more complex tones

**Example:**
```gdscript
# Generate 432 Hz with 4 harmonics (432, 864, 1296, 1728 Hz)
var harmonic = generator.generate_harmonic_series(432.0, 4, 4.0, 0.3)
```

##### `generate_white_noise(duration: float, amplitude: float = 0.3) -> AudioStreamWAV`
Generate white noise.

**Parameters:**
- `duration`: Duration in seconds
- `amplitude`: Amplitude (0.0 to 1.0, default: 0.3)

**Returns:**
- `AudioStreamWAV` with random noise

**Example:**
```gdscript
var noise = generator.generate_white_noise(5.0, 0.2)
```

#### Enveloped Sounds

##### `generate_beep(frequency: float, duration: float, amplitude: float = 0.5) -> AudioStreamWAV`
Generate a simple beep with envelope.

**Parameters:**
- `frequency`: Frequency in Hz
- `duration`: Duration in seconds
- `amplitude`: Amplitude (0.0 to 1.0)

**Returns:**
- `AudioStreamWAV` with ADSR envelope

**Envelope:**
- Attack: 10ms
- Release: 50ms

**Example:**
```gdscript
var beep = generator.generate_beep(1000.0, 0.5, 0.6)
```

##### `generate_click(amplitude: float = 0.8) -> AudioStreamWAV`
Generate a short click sound.

**Parameters:**
- `amplitude`: Amplitude (0.0 to 1.0, default: 0.8)

**Returns:**
- `AudioStreamWAV` with 50ms click

**Example:**
```gdscript
var click = generator.generate_click(0.5)
```

#### Frequency Sweeps

##### `generate_sweep(start_freq: float, end_freq: float, duration: float, amplitude: float = 0.5) -> AudioStreamWAV`
Generate a frequency sweep (linear).

**Parameters:**
- `start_freq`: Starting frequency in Hz
- `end_freq`: Ending frequency in Hz
- `duration`: Duration in seconds
- `amplitude`: Amplitude (0.0 to 1.0)

**Returns:**
- `AudioStreamWAV` with linear frequency sweep

**Example:**
```gdscript
# Sweep from 200 Hz to 1000 Hz over 1 second
var sweep = generator.generate_sweep(200.0, 1000.0, 1.0, 0.4)
```

##### `generate_scanning_tone(start_freq: float, end_freq: float, duration: float, amplitude: float = 0.5) -> AudioStreamWAV`
Generate a scanning tone (exponential sweep).

**Parameters:**
- `start_freq`: Starting frequency in Hz
- `end_freq`: Ending frequency in Hz
- `duration`: Duration in seconds
- `amplitude`: Amplitude (0.0 to 1.0)

**Returns:**
- `AudioStreamWAV` with exponential frequency sweep and envelope

**Behavior:**
- Exponential frequency curve (more natural)
- Sine wave amplitude envelope

**Example:**
```gdscript
var scan = generator.generate_scanning_tone(100.0, 800.0, 2.0, 0.5)
```

#### Resonance-Specific

##### `generate_realtime_tone(frequency: float, duration: float, amplitude: float = 0.5, harmonic_content: int = 1, detune: float = 0.0) -> AudioStreamWAV`
Generate a tone with adjustable parameters.

**Parameters:**
- `frequency`: Base frequency in Hz
- `duration`: Duration in seconds
- `amplitude`: Amplitude (0.0 to 1.0)
- `harmonic_content`: Number of harmonics (default: 1)
- `detune`: Detuning factor (default: 0.0)

**Returns:**
- `AudioStreamWAV` with specified characteristics

**Example:**
```gdscript
# 440 Hz with 3 harmonics, slightly detuned
var tone = generator.generate_realtime_tone(440.0, 2.0, 0.5, 3, 0.01)
```

##### `generate_interference_tone(freq1: float, freq2: float, duration: float, amplitude: float = 0.5) -> AudioStreamWAV`
Generate interference pattern (beating effect).

**Parameters:**
- `freq1`: First frequency in Hz
- `freq2`: Second frequency in Hz
- `duration`: Duration in seconds
- `amplitude`: Amplitude (0.0 to 1.0)

**Returns:**
- `AudioStreamWAV` with beating interference pattern

**Use case:** Demonstrating wave interference

**Example:**
```gdscript
# 440 Hz and 445 Hz create 5 Hz beating
var interference = generator.generate_interference_tone(440.0, 445.0, 4.0, 0.5)
```

##### `generate_cancellation_sound(duration: float = 1.0, amplitude: float = 0.7) -> AudioStreamWAV`
Generate a cancellation/dissolution sound.

**Parameters:**
- `duration`: Duration in seconds (default: 1.0)
- `amplitude`: Amplitude (0.0 to 1.0, default: 0.7)

**Returns:**
- `AudioStreamWAV` with descending frequency and noise

**Behavior:**
- Frequency drops from 1000 Hz to 100 Hz
- Increasing noise amount
- Fade-out envelope

**Example:**
```gdscript
var cancel = generator.generate_cancellation_sound(1.5, 0.7)
```

##### `generate_confirmation_chirp(frequency: float, amplitude: float = 0.5) -> AudioStreamWAV`
Generate a short confirmation chirp.

**Parameters:**
- `frequency`: Frequency in Hz
- `amplitude`: Amplitude (0.0 to 1.0, default: 0.5)

**Returns:**
- `AudioStreamWAV` with 100ms chirp

**Envelope:**
- Attack: 20ms
- Release: 80ms

**Example:**
```gdscript
var chirp = generator.generate_confirmation_chirp(800.0, 0.4)
```

#### File Operations

##### `save_to_file(stream: AudioStreamWAV, path: String) -> Error`
Save generated audio to file.

**Parameters:**
- `stream`: AudioStreamWAV to save
- `path`: Resource path for saving (e.g., "res://audio/tone.tres")

**Returns:**
- `OK` (0) on success
- Error code on failure

**Note:** Saves as Godot resource (.tres), not WAV file

**Example:**
```gdscript
var tone = generator.generate_sine_tone(440.0, 2.0)
var err = generator.save_to_file(tone, "res://data/audio/tone_440.tres")
if err == OK:
    print("Saved successfully")
```

##### `generate_test_audio_files() -> void`
Generate a complete set of test audio files.

**Behavior:**
- Creates directory structure
- Generates engine, tone, ambient, UI, warning, and environment sounds
- Saves all to `res://data/audio/` subdirectories

**Use case:** Quick placeholder audio generation for testing

**Warning:** This is for testing only. Replace with proper audio assets for production.

**Example:**
```gdscript
var generator = ProceduralAudioGenerator.new()
add_child(generator)
generator.generate_test_audio_files()
```

---

## ResonanceAudioFeedback

**File:** `C:/godot/scripts/audio/resonance_audio_feedback.gd`
**Class:** `ResonanceAudioFeedback` (extends Node)
**Purpose:** Audio feedback for resonance gameplay mechanics

### Properties

#### Configuration
```gdscript
@export var enable_spatial_audio: bool = true         # Enable 3D object tones
@export var enable_dynamic_layering: bool = true      # Enable ambient layering
@export var max_simultaneous_frequencies: int = 8     # Max frequencies in layer
@export var base_resonance_volume: float = 0.3        # Base volume level
@export var emission_volume: float = 0.8              # Emission sound volume
@export var scanning_volume: float = 0.6              # Scanning sound volume
```

#### Subsystem References
```gdscript
var resonance_system: ResonanceSystem = null                    # Resonance mechanics
var resonance_input_controller: ResonanceInputController = null # VR input
var spatial_audio: SpatialAudio = null                          # 3D audio
var audio_manager: AudioManager = null                          # Audio hub
var procedural_generator: ProceduralAudioGenerator = null       # Tone generation
```

#### Audio Players
```gdscript
var emission_player: AudioStreamPlayer = null          # Frequency emission sounds
var scanning_player: AudioStreamPlayer = null          # Scanning sounds
var ambient_resonance_player: AudioStreamPlayer = null # Ambient layer
var scanned_object_players: Dictionary = {}            # Key: object_id, Value: AudioStreamPlayer3D
```

#### State
```gdscript
var active_frequencies: Array[float] = []              # Active resonance frequencies
var frequency_volumes: Dictionary = {}                 # Key: frequency, Value: volume
var current_emission_frequency: float = 0.0            # Currently emitted frequency
var emission_mode: String = "none"                     # "constructive", "destructive", "none"
```

#### Constants
```gdscript
const RESONANCE_BUS: String = "Resonance"              # Main resonance bus
const RESONANCE_SFX_BUS: String = "ResonanceSFX"       # SFX bus
const MIN_FREQUENCY: float = 100.0                     # Minimum frequency
const MAX_FREQUENCY: float = 1000.0                    # Maximum frequency
```

### Methods

#### Initialization

##### `_ready() -> void`
Initialize resonance audio feedback:
- Setup audio buses
- Create audio players
- Find system references
- Connect to signals

##### `_setup_audio_buses() -> void`
Create resonance-specific audio buses.

##### `_create_audio_players() -> void`
Create AudioStreamPlayer nodes for different sound types.

##### `_find_systems() -> void`
Find references to required systems in scene tree.

##### `_setup_signal_connections() -> void`
Connect to resonance system signals.

**Signals Connected:**
- `ResonanceSystem.object_scanned`
- `ResonanceSystem.interference_applied`
- `ResonanceSystem.object_cancelled`
- `ResonanceInputController.frequency_emitted`
- `ResonanceInputController.emission_stopped`
- `ResonanceInputController.mode_changed`
- `ResonanceInputController.frequency_switched`

#### Signal Handlers (Private)

These methods are called automatically via signal connections:

##### `_on_object_scanned(object: Node3D, frequency: float) -> void`
Handle object scanned by resonance system.

**Behavior:**
- Creates spatial audio tone for object
- Plays scan completion sound

##### `_on_interference_applied(object: Node3D, interference_type: String, amplitude_change: float) -> void`
Handle interference applied to object.

**Behavior:**
- Adjusts object tone volume based on amplitude change
- Applies pitch shift for dramatic effect

##### `_on_object_cancelled(object: Node3D) -> void`
Handle object cancellation.

**Behavior:**
- Plays cancellation sound
- Fades out and removes object tone

##### `_on_frequency_emitted(frequency: float, mode: String) -> void`
Handle frequency emission start.

**Behavior:**
- Plays emission sound (different for constructive/destructive)

##### `_on_emission_stopped() -> void`
Handle frequency emission stop.

**Behavior:**
- Fades out emission sound

##### `_on_mode_changed(mode: String) -> void`
Handle resonance mode change.

**Behavior:**
- Plays mode switch sound (upward/downward sweep)

##### `_on_frequency_switched(frequency: float) -> void`
Handle quick frequency switch.

**Behavior:**
- Plays confirmation beep

#### Audio Generation (Private)

##### `_create_object_resonance_tone(object: Node3D, frequency: float) -> void`
Create spatial audio source for scanned object.

**Parameters:**
- `object`: Object to attach sound to
- `frequency`: Object's resonance frequency

**Behavior:**
- Generates looping sine tone at object's frequency
- Creates 3D audio source at object position
- Stores reference for position updates

##### `_play_scan_complete_sound(frequency: float) -> void`
Play sound for successful scan.

**Parameters:**
- `frequency`: Scanned frequency

##### `_play_emission_sound(frequency: float, mode: String) -> void`
Play emission sound.

**Parameters:**
- `frequency`: Emitted frequency
- `mode`: "constructive" or "destructive"

**Behavior:**
- Harmonic-rich tone for constructive
- Dissonant sweep for destructive

##### `_play_cancellation_sound() -> void`
Play object cancellation sound.

##### `_play_mode_switch_sound(mode: String) -> void`
Play mode switch sound.

**Parameters:**
- `mode`: "constructive" or "destructive"

##### `_play_frequency_switch_sound(frequency: float) -> void`
Play frequency switch sound.

**Parameters:**
- `frequency`: New frequency

#### Dynamic Layering (Private)

##### `_add_active_frequency(frequency: float) -> void`
Add frequency to dynamic layer.

**Parameters:**
- `frequency`: Frequency to add

**Behavior:**
- Adds to active list (max 8)
- Updates ambient resonance layer

##### `_remove_active_frequency(frequency: float) -> void`
Remove frequency from dynamic layer.

**Parameters:**
- `frequency`: Frequency to remove

##### `_update_ambient_resonance_layer() -> void`
Update ambient background layer.

**Behavior:**
- Generates composite tone of all active frequencies
- Real-time synthesis every update
- Creates seamless looping audio

#### Processing

##### `_process(delta: float) -> void`
Called every frame.

**Behavior:**
- Updates object audio positions
- Updates frequency volumes based on interference

##### `_update_object_positions() -> void`
Update positions of all object audio players.

##### `_update_frequency_volumes(delta: float) -> void`
Update volume levels based on interference strength.

##### `_exit_tree() -> void`
Cleanup when node is removed.

**Behavior:**
- Disconnects all signal connections
- Stops all audio players
- Clears references

---

## AudioFeedback

**File:** `C:/godot/scripts/audio/audio_feedback.gd`
**Class:** `AudioFeedback` (extends Node)
**Purpose:** Game state audio feedback (velocity, entropy, gravity, SNR)

### Properties

#### Configuration
```gdscript
@export var spacecraft: Node3D = null                  # Reference to spacecraft
@export var signal_manager: Node = null                # Reference to signal manager
@export var enable_base_tone: bool = true              # Enable 432 Hz base tone
@export var enable_doppler_shift: bool = true          # Enable velocity pitch shift
@export var enable_entropy_effects: bool = true        # Enable entropy distortion
@export var enable_gravity_effects: bool = true        # Enable gravity bass boost
@export var enable_snr_effects: bool = true            # Enable SNR dropouts
```

#### State
```gdscript
var current_pitch_scale: float = 1.0                   # Current Doppler pitch
var current_distortion: float = 0.0                    # Current distortion level
var current_volume: float = 0.0                        # Current volume level
var playback_position: float = 0.0                     # Tone generation position
```

#### Audio Components
```gdscript
var base_tone_player: AudioStreamPlayer = null         # Base tone player
var distortion_effect: AudioEffectDistortion = null    # Distortion effect
var pitch_shift_effect: AudioEffectPitchShift = null   # Pitch shift effect
var feedback_bus_index: int = -1                       # Feedback bus index
var spatial_audio: SpatialAudio = null                 # Spatial audio reference
```

#### Constants
```gdscript
const BASE_FREQUENCY: float = 432.0  # Base harmonic frequency (Hz)
```

### Methods

#### Initialization

##### `_ready() -> void`
Initialize audio feedback system:
- Setup audio bus and effects
- Generate/load base tone
- Find spatial audio reference

##### `setup_audio_bus() -> void`
Create feedback bus with effects.

**Requirements:**
- 27.3: Apply bit-crushing effects using AudioEffectDistortion
- 27.2: Pitch-shift audio with velocity using AudioEffectPitchShift

##### `setup_base_tone() -> void`
Create base harmonic tone player.

**Requirements:** 27.1 - Play 432Hz harmonic base tone when idle

#### Processing

##### `_process(delta: float) -> void`
Update audio feedback based on game state.

**Behavior:**
- Updates Doppler shift based on velocity
- Updates distortion based on entropy
- Updates bass boost based on gravity
- Updates dropouts based on SNR

#### Doppler Shift

##### `update_doppler_shift() -> void`
Update pitch based on spacecraft velocity.

**Requirements:** 27.2 - Pitch-shift audio with velocity (Doppler)

**Behavior:**
- Gets spacecraft velocity magnitude
- Normalizes to 0-1 range (0-1000 units/s)
- Applies pitch shift up to 20% at max speed

#### Entropy Effects

##### `update_entropy_effects() -> void`
Update distortion based on entropy level.

**Requirements:** 27.3 - Apply bit-crushing effects with entropy

**Behavior:**
- Gets entropy level from signal manager (0.0-1.0)
- Applies distortion drive (0 to 0.8)
- Increases pre-gain

#### Gravity Effects

##### `update_gravity_effects() -> void`
Update bass boost in gravity wells.

**Requirements:** 27.4 - Add bass-heavy distortion in gravity wells

**Behavior:**
- Finds nearest celestial body
- Calculates distance and gravity strength
- Boosts volume up to +3dB when close

#### SNR Effects

##### `update_snr_effects() -> void`
Update dropouts and static at low SNR.

**Requirements:** 27.5 - Introduce dropouts and static at low SNR

**Behavior:**
- Gets SNR from signal manager (0-100)
- Random dropouts at SNR < 25%
- Static distortion at SNR < 50%

#### Utility Methods

##### `find_nearest_celestial_body() -> Node3D`
Find the nearest celestial body.

**Returns:**
- Nearest CelestialBody node
- `null` if none found

##### `set_spacecraft(craft: Node3D) -> void`
Set spacecraft reference.

**Parameters:**
- `craft`: Spacecraft node

##### `set_signal_manager(manager: Node) -> void`
Set signal manager reference.

**Parameters:**
- `manager`: SignalManager node

##### `set_base_tone_enabled(enabled: bool) -> void`
Enable/disable base harmonic tone.

**Parameters:**
- `enabled`: True to enable, false to disable

##### `set_doppler_enabled(enabled: bool) -> void`
Enable/disable Doppler shift.

**Parameters:**
- `enabled`: True to enable, false to disable

##### `set_entropy_effects_enabled(enabled: bool) -> void`
Enable/disable entropy effects.

**Parameters:**
- `enabled`: True to enable, false to disable

##### `set_gravity_effects_enabled(enabled: bool) -> void`
Enable/disable gravity effects.

**Parameters:**
- `enabled`: True to enable, false to disable

##### `set_snr_effects_enabled(enabled: bool) -> void`
Enable/disable SNR effects.

**Parameters:**
- `enabled`: True to enable, false to disable

##### `get_pitch_scale() -> float`
Get current pitch scale factor.

**Returns:**
- Pitch scale (1.0 = normal)

##### `get_distortion_level() -> float`
Get current distortion level.

**Returns:**
- Distortion level (0.0 to 1.0)

##### `_exit_tree() -> void`
Cleanup when node is removed.

---

## Common Types

### Enumerations

#### Attenuation Models (String)
```gdscript
"inverse"          # Inverse distance
"inverse_square"   # Inverse square distance (default)
"linear"           # Linear falloff
"exponential"      # Exponential decay
```

#### Resonance Modes (String)
```gdscript
"constructive"     # Constructive interference mode
"destructive"      # Destructive interference mode
"none"             # No emission
```

### Data Structures

#### Audio Bus Names
```gdscript
"Master"           # Master bus (all audio)
"Music"            # Background music
"SFX"              # Sound effects
"Ambient"          # Ambient sounds
"Spatial"          # 3D spatial audio
"Reverb"           # Environmental reverb
"Resonance"        # Resonance gameplay
"ResonanceSFX"     # Resonance sound effects
"Feedback"         # Game state feedback
```

---

## Signal Reference

### ResonanceAudioFeedback Connections

Connects to external signals from ResonanceSystem and ResonanceInputController.

#### From ResonanceSystem
```gdscript
signal object_scanned(object: Node3D, frequency: float)
signal interference_applied(object: Node3D, interference_type: String, amplitude_change: float)
signal object_cancelled(object: Node3D)
```

#### From ResonanceInputController
```gdscript
signal object_scanned(object: Node3D, frequency: float)
signal frequency_emitted(frequency: float, mode: String)
signal emission_stopped()
signal mode_changed(mode: String)
signal frequency_switched(frequency: float)
```

---

## Usage Examples

### Complete Audio Setup Example
```gdscript
extends Node

var audio_mgr: AudioManager
var spatial_audio: SpatialAudio
var audio_feedback: AudioFeedback

func _ready():
    # Get audio manager (autoload)
    audio_mgr = get_node("/root/AudioManager")

    # Get subsystems
    spatial_audio = audio_mgr.get_spatial_audio()
    audio_feedback = audio_mgr.get_audio_feedback()

    # Configure volumes
    audio_mgr.set_master_volume(0.8)
    audio_mgr.set_music_volume(0.6)

    # Play background music
    audio_mgr.play_music("res://data/audio/music/exploration.ogg", 2.0)

    # Configure spatial audio
    spatial_audio.enable_reverb = true
    spatial_audio.set_reverb_parameters(0.5, 0.5)

    # Configure audio feedback
    audio_feedback.set_spacecraft(get_node("Spacecraft"))
    audio_feedback.set_base_tone_enabled(true)
```

### Spacecraft Engine Audio Example
```gdscript
class_name Spacecraft
extends RigidBody3D

var engine_source: AudioStreamPlayer3D = null
var spatial_audio: SpatialAudio

func _ready():
    # Get spatial audio
    spatial_audio = get_node("/root/AudioManager").get_spatial_audio()

    # Create engine sound
    var engine_stream = load("res://data/audio/engine_idle.tres")
    engine_source = spatial_audio.play_looping_sound(
        engine_stream,
        global_position,
        -15.0
    )

    # Configure source
    engine_source.max_distance = 200.0
    engine_source.unit_size = 10.0

func _process(delta):
    # Update position
    if is_instance_valid(engine_source):
        spatial_audio.update_source_position(engine_source, global_position)

        # Update volume/pitch based on thrust
        var thrust = get_thrust_magnitude()  # 0.0 to 1.0
        engine_source.volume_db = lerp(-15.0, 0.0, thrust)
        engine_source.pitch_scale = lerp(0.8, 1.2, thrust)

func _exit_tree():
    if is_instance_valid(engine_source):
        spatial_audio.remove_audio_source(engine_source)
```

### Procedural UI Sounds Example
```gdscript
class_name UIButton
extends Button

var audio_mgr: AudioManager
var generator: ProceduralAudioGenerator
var hover_sound: AudioStreamWAV
var click_sound: AudioStreamWAV

func _ready():
    audio_mgr = get_node("/root/AudioManager")
    generator = ProceduralAudioGenerator.new()

    # Generate sounds
    hover_sound = generator.generate_beep(2000.0, 0.05, 0.3)
    click_sound = generator.generate_click(0.5)

    # Connect signals
    mouse_entered.connect(_on_hover)
    pressed.connect(_on_pressed)

func _on_hover():
    var player = AudioStreamPlayer.new()
    player.stream = hover_sound
    player.bus = "SFX"
    add_child(player)
    player.play()
    player.finished.connect(func(): player.queue_free())

func _on_pressed():
    var player = AudioStreamPlayer.new()
    player.stream = click_sound
    player.bus = "SFX"
    add_child(player)
    player.play()
    player.finished.connect(func(): player.queue_free())
```

### Zone-Based Reverb Example
```gdscript
class_name ReverbZone
extends Area3D

@export var room_size: float = 0.5
@export var damping: float = 0.5

var spatial_audio: SpatialAudio
var player_inside: bool = false

func _ready():
    spatial_audio = get_node("/root/AudioManager").get_spatial_audio()

    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body):
    if body.name == "Player" or body.name == "Spacecraft":
        player_inside = true
        spatial_audio.set_reverb_parameters(room_size, damping)

func _on_body_exited(body):
    if body.name == "Player" or body.name == "Spacecraft":
        player_inside = false
        # Restore default reverb
        spatial_audio.set_reverb_parameters(0.5, 0.5)
```

---

## Performance Monitoring

### Audio Performance Diagnostics
```gdscript
func print_audio_performance():
    print("=== Audio Performance ===")
    print("Active spatial sources: ", spatial_audio.get_active_source_count())
    print("Music playing: ", audio_mgr.is_music_playing())
    print("Current music: ", audio_mgr.get_current_music())
    print("Master volume: ", audio_mgr.get_master_volume())
    print("Is muted: ", audio_mgr.is_muted())

    # Check for performance issues
    var source_count = spatial_audio.get_active_source_count()
    if source_count > 64:
        print("WARNING: High source count (", source_count, ") - may impact performance")
```

---

## Related Documentation

- [Audio System Architecture](AUDIO_SYSTEM_ARCHITECTURE.md) - System overview
- [Spatial Audio Guide](SPATIAL_AUDIO_GUIDE.md) - VR spatial audio best practices
- [CLAUDE.md](../../CLAUDE.md) - Project overview
- [Godot Audio Documentation](https://docs.godotengine.org/en/stable/tutorials/audio/index.html)
