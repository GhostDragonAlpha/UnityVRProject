# Audio Assets Quick Start Guide

## 🎵 Get Audio Working in 5 Minutes

### Option 1: Generate Test Audio (Fastest)

**Step 1:** Open Godot Editor

**Step 2:** Open the Script Editor and create a new script

**Step 3:** Paste this code:

```gdscript
extends Node

func _ready():
    var generator = ProceduralAudioGenerator.new()
    add_child(generator)
    generator.generate_test_audio_files()
    print("Test audio generated! Check data/audio/ subdirectories")
```

**Step 4:** Attach to any node and run the scene (F5)

**Step 5:** Done! You now have 28 test audio files ready to use.

### Option 2: Use the Example Script

**Step 1:** Open `examples/audio_generation_example.gd`

**Step 2:** Attach it to a Node in your scene

**Step 3:** Run the scene (F5)

**Step 4:** Listen to the test audio playback

### Testing Audio in Game

```gdscript
# Play a UI sound
var audio_manager = get_node("/root/AudioManager")
audio_manager.play_sfx("res://data/audio/ui/button_click.tres")

# Play a 3D sound
var spatial_audio = get_node("/root/ResonanceEngine/SpatialAudio")
var stream = load("res://data/audio/engine/engine_idle.tres")
spatial_audio.play_sound_at_position(stream, Vector3(0, 0, 0))
```

## 📁 What You Get

After generating test audio, you'll have:

- **4 engine sounds** - For spacecraft thrust
- **2 harmonic tones** - Including 432Hz base tone
- **4 ambient sounds** - Space and cockpit atmosphere
- **7 UI sounds** - Buttons, menus, confirmations
- **7 warning sounds** - Alerts and notifications
- **4 environmental sounds** - Atmospheric entry, wind, impacts

**Total: 28 audio files** ready for testing!

## 🎯 Next Steps

### For Testing & Development

✅ You're done! Use the generated audio for development.

### For Production

1. Read `AUDIO_ASSETS_GUIDE.md` for specifications
2. Create or source professional audio files
3. Convert to OGG Vorbis format
4. Replace test files with production files
5. Test in VR with headphones

## 🔧 Troubleshooting

**Q: Audio files not generating?**

- Make sure `scripts/audio/procedural_audio_generator.gd` exists
- Check console for error messages
- Verify write permissions in `data/audio/` directory

**Q: Can't hear audio in game?**

- Check AudioManager is initialized
- Verify volume settings aren't muted
- Test with headphones
- Check console for loading errors

**Q: Audio sounds bad?**

- Test audio is intentionally simple
- Replace with professional assets for production
- See `AUDIO_ASSETS_GUIDE.md` for quality guidelines

## 📚 Documentation

- **AUDIO_ASSETS_GUIDE.md** - Complete specifications
- **README.md** - Overview and status
- **TASK_64_COMPLETION.md** - Implementation details
- **AUDIO_ASSETS_IMPLEMENTATION_SUMMARY.md** - Full summary

## ✨ Features

The audio system supports:

- ✓ 3D spatial audio with distance attenuation
- ✓ Doppler shift for moving sources
- ✓ Dynamic audio based on game state
- ✓ Entropy-based distortion effects
- ✓ Gravity well bass effects
- ✓ SNR-based audio dropouts
- ✓ Up to 256 simultaneous audio channels
- ✓ Environmental reverb

## 🎮 Integration

Audio integrates with:

- **AudioManager** - Main audio system
- **SpatialAudio** - 3D positioning
- **AudioFeedback** - Dynamic feedback

All systems are already implemented and ready to use!

## 💡 Tips

- Test audio is for development only
- Use mono files for 3D sounds
- Keep file sizes under 1MB
- Test with VR headphones for spatial accuracy
- Ensure looping sounds are seamless

---

**Need help?** Check the comprehensive guides in this directory or the example scripts in `examples/`.
