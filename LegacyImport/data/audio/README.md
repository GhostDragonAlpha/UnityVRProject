# Audio Assets Directory

This directory contains all audio assets for Project Resonance.

## Directory Structure

```
data/audio/
├── engine/          # Spacecraft engine sounds
├── tones/           # Harmonic base tones (432Hz, etc.)
├── ambient/         # Ambient space and environment sounds
├── ui/              # User interface interaction sounds
├── warnings/        # Warning and alert sounds
└── environment/     # Environmental sounds (wind, impacts, etc.)
```

## Quick Start

### Option 1: Use Procedural Test Audio (For Testing Only)

Run the procedural audio generator to create simple test sounds:

```gdscript
# In Godot editor, run this script:
var generator = ProceduralAudioGenerator.new()
generator.generate_test_audio_files()
```

This will create basic `.tres` resource files that can be used for testing.

### Option 2: Add Real Audio Assets (Recommended for Production)

1. Read `AUDIO_ASSETS_GUIDE.md` for detailed specifications
2. Create or source audio files according to the guide
3. Place files in the appropriate subdirectories
4. Ensure files are in OGG Vorbis format (.ogg)
5. Godot will automatically import the files

## Required Audio Files

See `AUDIO_ASSETS_GUIDE.md` for the complete list of required audio files and their specifications.

### Minimum Required Files

**Engine Sounds** (4 files):

- engine_idle.ogg
- engine_thrust_low.ogg
- engine_thrust_medium.ogg
- engine_thrust_high.ogg

**Harmonic Tones** (2 files):

- base_tone_432hz.ogg
- harmonic_overtones.ogg

**Ambient Sounds** (4 files):

- space_ambient_deep.ogg
- space_ambient_nebula.ogg
- space_ambient_filament.ogg
- cockpit_ambient.ogg

**UI Sounds** (7 files):

- button_click.ogg
- button_hover.ogg
- menu_open.ogg
- menu_close.ogg
- confirm.ogg
- cancel.ogg
- resource_collect.ogg

**Warning Sounds** (7 files):

- warning_danger.ogg
- warning_critical.ogg
- warning_collision.ogg
- warning_low_snr.ogg
- warning_gravity.ogg
- alert_discovery.ogg
- alert_objective.ogg

**Environmental Sounds** (4 files):

- atmospheric_entry.ogg
- atmospheric_wind.ogg
- landing_gear.ogg
- collision_impact.ogg

**Total: 28 audio files minimum**

## Audio Format Requirements

- **Format**: OGG Vorbis (.ogg) preferred
- **Sample Rate**: 44.1 kHz or 48 kHz
- **Bitrate**: 192-320 kbps
- **Channels**: Mono for 3D sounds, Stereo for music/ambient
- **Normalization**: -3dB to -6dB peak

## Testing Audio

To test audio in-game:

1. Ensure audio files are in the correct directories
2. Launch the game in VR or desktop mode
3. Audio will be automatically loaded by AudioManager
4. Check console for any loading errors

## Resources

- **Freesound.org** - Free sound effects library
- **OpenGameArt.org** - Game audio assets
- **Audacity** - Free audio editor
- **Vital** - Free synthesizer for tone generation

## Notes

- Audio is critical for VR immersion
- All 3D sounds should be mono (Godot will spatialize them)
- Test with headphones for proper spatial audio
- Keep file sizes reasonable (< 1MB per file typically)
- Ensure looping sounds have seamless loops

## Status

Current status: **Placeholder structure created**

- [ ] Engine sounds added
- [ ] Harmonic tones added
- [ ] Ambient sounds added
- [ ] UI sounds added
- [ ] Warning sounds added
- [ ] Environmental sounds added
- [ ] All files tested in-game
- [ ] Audio quality verified

## Integration

Audio files are loaded and managed by:

- `scripts/audio/audio_manager.gd` - Main audio system
- `scripts/audio/spatial_audio.gd` - 3D spatial audio
- `scripts/audio/audio_feedback.gd` - Dynamic audio feedback

See those files for implementation details and usage examples.
