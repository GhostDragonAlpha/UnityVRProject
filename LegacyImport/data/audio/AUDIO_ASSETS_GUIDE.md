# Audio Assets Guide

This document describes the audio assets needed for Project Resonance and provides guidance on creating or sourcing them.

## Requirements

Based on Requirements 27.1-27.5 and 65.1-65.5, the following audio assets are needed:

### 1. Engine Sounds

**Location**: `data/audio/engine/`

- **engine_idle.ogg** - Low rumble for idle spacecraft (looping)
  - Duration: 2-5 seconds loop
  - Frequency: Low bass (50-200 Hz)
  - Volume: Moderate, should blend with base tone
- **engine_thrust_low.ogg** - Light thrust sound (looping)
  - Duration: 2-5 seconds loop
  - Frequency: Mid-range (200-800 Hz)
  - Intensity: Moderate
- **engine_thrust_medium.ogg** - Medium thrust sound (looping)
  - Duration: 2-5 seconds loop
  - Frequency: Mid-high (500-1500 Hz)
  - Intensity: Strong
- **engine_thrust_high.ogg** - Full thrust sound (looping)
  - Duration: 2-5 seconds loop
  - Frequency: High (1000-3000 Hz)
  - Intensity: Very strong, with harmonics

**Creation Tips**:

- Use synthesizers to create clean, electronic engine sounds
- Layer white noise with sine waves for texture
- Add subtle modulation for organic feel
- Ensure seamless loops with crossfades

### 2. Harmonic Base Tones

**Location**: `data/audio/tones/`

- **base_tone_432hz.ogg** - Pure 432Hz sine wave (looping)
  - Duration: 2 seconds loop
  - Frequency: Exactly 432 Hz
  - Waveform: Pure sine wave
  - Volume: Moderate, should be subtle background
- **harmonic_overtones.ogg** - Harmonic series based on 432Hz (looping)
  - Duration: 4 seconds loop
  - Frequencies: 432, 864, 1296, 1728 Hz (harmonics)
  - Waveform: Layered sine waves
  - Volume: Soft, ethereal

**Creation Tips**:

- Use audio synthesis tools (Audacity, Vital, Serum)
- Generate pure sine waves at exact frequencies
- For overtones, layer multiple sine waves at harmonic intervals
- Apply gentle low-pass filter for warmth

### 3. Ambient Space Sounds

**Location**: `data/audio/ambient/`

- **space_ambient_deep.ogg** - Deep space ambience (looping)
  - Duration: 30-60 seconds loop
  - Character: Dark, mysterious, vast
  - Frequency: Very low (20-100 Hz) with occasional high sparkles
  - Volume: Very quiet, atmospheric
- **space_ambient_nebula.ogg** - Nebula region ambience (looping)
  - Duration: 30-60 seconds loop
  - Character: Ethereal, colorful, energetic
  - Frequency: Mid-range with sweeping pads
  - Volume: Moderate
- **space_ambient_filament.ogg** - Filament travel ambience (looping)
  - Duration: 20-40 seconds loop
  - Character: Flowing, energetic, rhythmic
  - Frequency: Full spectrum with pulsing elements
  - Volume: Moderate to strong
- **cockpit_ambient.ogg** - Cockpit interior ambience (looping)
  - Duration: 10-20 seconds loop
  - Character: Mechanical, electronic, subtle
  - Frequency: Mid-range (200-2000 Hz)
  - Volume: Quiet, background

**Creation Tips**:

- Use granular synthesis for evolving textures
- Layer multiple drone sounds
- Add subtle modulation and filtering
- Use reverb for spaciousness
- Ensure seamless loops

### 4. UI Interaction Sounds

**Location**: `data/audio/ui/`

- **button_click.ogg** - Button press sound
  - Duration: 0.1-0.2 seconds
  - Character: Clean, digital, satisfying
  - Frequency: Mid-high (1000-3000 Hz)
- **button_hover.ogg** - Button hover sound
  - Duration: 0.05-0.1 seconds
  - Character: Subtle, soft
  - Frequency: High (2000-4000 Hz)
- **menu_open.ogg** - Menu opening sound
  - Duration: 0.3-0.5 seconds
  - Character: Whoosh, expanding
  - Frequency: Sweep from low to high
- **menu_close.ogg** - Menu closing sound
  - Duration: 0.2-0.4 seconds
  - Character: Whoosh, collapsing
  - Frequency: Sweep from high to low
- **confirm.ogg** - Confirmation sound
  - Duration: 0.2-0.3 seconds
  - Character: Positive, uplifting
  - Frequency: Ascending chord
- **cancel.ogg** - Cancellation sound
  - Duration: 0.2-0.3 seconds
  - Character: Negative, descending
  - Frequency: Descending tone
- **resource_collect.ogg** - Resource collection sound
  - Duration: 0.3-0.5 seconds
  - Character: Satisfying, rewarding
  - Frequency: Bright, sparkly

**Creation Tips**:

- Keep UI sounds short and punchy
- Use synthesizers for clean digital sounds
- Add subtle reverb for depth
- Ensure sounds don't overlap badly when triggered rapidly

### 5. Warning Alert Sounds

**Location**: `data/audio/warnings/`

- **warning_danger.ogg** - General danger warning (looping)
  - Duration: 1-2 seconds loop
  - Character: Urgent, alarming
  - Frequency: Mid-range beep (800-1200 Hz)
  - Pattern: Repeating beep pattern
- **warning_critical.ogg** - Critical system failure (looping)
  - Duration: 0.5-1 second loop
  - Character: Very urgent, panic
  - Frequency: High beep (1500-2500 Hz)
  - Pattern: Rapid beeping
- **warning_collision.ogg** - Collision warning (looping)
  - Duration: 0.3-0.5 seconds loop
  - Character: Immediate danger
  - Frequency: Very high (2000-3000 Hz)
  - Pattern: Fast beeping
- **warning_low_snr.ogg** - Low signal warning (looping)
  - Duration: 2-3 seconds loop
  - Character: Degrading, corrupted
  - Frequency: Mid with distortion
  - Pattern: Pulsing with static
- **warning_gravity.ogg** - Gravity well warning
  - Duration: 1-2 seconds loop
  - Character: Deep, ominous
  - Frequency: Low (100-400 Hz)
  - Pattern: Slow pulsing
- **alert_discovery.ogg** - Discovery notification
  - Duration: 0.5-1 second
  - Character: Positive, informative
  - Frequency: Pleasant chime
- **alert_objective.ogg** - Objective update notification
  - Duration: 0.5-1 second
  - Character: Neutral, informative
  - Frequency: Mid-range tone

**Creation Tips**:

- Use square or sawtooth waves for harsh beeps
- Add urgency with rapid repetition
- Layer multiple frequencies for complexity
- Use distortion for critical warnings

### 6. Environmental Sounds

**Location**: `data/audio/environment/`

- **atmospheric_entry.ogg** - Atmospheric entry rumble (looping)
  - Duration: 5-10 seconds loop
  - Character: Intense, violent
  - Frequency: Full spectrum with emphasis on low
  - Volume: Very loud
- **atmospheric_wind.ogg** - Wind in atmosphere (looping)
  - Duration: 10-20 seconds loop
  - Character: Flowing, natural
  - Frequency: Mid-high with noise
  - Volume: Moderate
- **landing_gear.ogg** - Landing gear deployment
  - Duration: 2-3 seconds
  - Character: Mechanical, hydraulic
  - Frequency: Mid-range with mechanical sounds
- **collision_impact.ogg** - Collision impact sound
  - Duration: 0.5-1 second
  - Character: Harsh, destructive
  - Frequency: Full spectrum with emphasis on low
  - Volume: Very loud

**Creation Tips**:

- Use noise generators for wind and rumble
- Layer mechanical sounds for landing gear
- Use impact samples for collisions
- Add reverb for environmental context

## Audio Format Specifications

### File Format

- **Primary**: OGG Vorbis (.ogg)
- **Alternative**: WAV (.wav) for uncompressed
- **Bitrate**: 192-320 kbps for OGG
- **Sample Rate**: 44.1 kHz or 48 kHz
- **Bit Depth**: 16-bit minimum, 24-bit preferred

### Looping

- Ensure seamless loops with proper crossfades
- Use loop points in metadata when possible
- Test loops in Godot to verify smoothness

### Volume Normalization

- Normalize to -3dB to -6dB peak
- Leave headroom for mixing
- Consistent volume across similar sound types

## Sourcing Audio

### Free Resources

- **Freesound.org** - Large library of CC-licensed sounds
- **OpenGameArt.org** - Game-specific audio assets
- **Incompetech.com** - Royalty-free music and sounds
- **ZapSplat.com** - Free sound effects library

### Synthesis Tools

- **Audacity** - Free audio editor with tone generation
- **Vital** - Free wavetable synthesizer
- **Surge XT** - Free hybrid synthesizer
- **LMMS** - Free DAW with built-in synths

### Commercial Options

- **Sonniss Game Audio** - Professional game audio bundles
- **AudioJungle** - Royalty-free audio marketplace
- **Pro Sound Effects** - Professional sound library

## Testing Audio in Godot

1. Place audio files in appropriate directories
2. Import will happen automatically
3. Check import settings in Godot:
   - Loop: Enable for looping sounds
   - Compression: Vorbis for most sounds
   - Force Mono: Enable for 3D sounds to save memory
4. Test in-game with AudioManager system

## Procedural Audio Generation

For testing purposes, a procedural audio generator script is provided:

- `scripts/audio/procedural_audio_generator.gd`
- Can generate basic tones and noise for testing
- Not suitable for final production

## Integration with Audio Systems

Audio files are loaded and managed by:

- **AudioManager** (`scripts/audio/audio_manager.gd`) - Main audio system
- **SpatialAudio** (`scripts/audio/spatial_audio.gd`) - 3D positioning
- **AudioFeedback** (`scripts/audio/audio_feedback.gd`) - Dynamic feedback

See those files for implementation details.

## Checklist

- [ ] Engine sounds created/sourced
- [ ] Harmonic base tones generated
- [ ] Ambient space sounds created
- [ ] UI interaction sounds created
- [ ] Warning alert sounds created
- [ ] Environmental sounds created
- [ ] All files in OGG format
- [ ] All files properly normalized
- [ ] Looping sounds tested for seamlessness
- [ ] All files imported into Godot
- [ ] Audio tested in-game

## Notes

- Audio is critical for VR immersion
- Spatial audio requires mono sources
- Keep file sizes reasonable (< 1MB per file typically)
- Test with headphones for spatial accuracy
- Consider accessibility (visual indicators for audio cues)
