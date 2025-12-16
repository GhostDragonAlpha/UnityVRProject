# Moon Landing Audio - Quick Start Checklist

## Status: AUDIO SYSTEM FULLY IMPLEMENTED ✅

The audio system is complete and ready to use. Just need to:
1. Add audio files
2. Update 2 files (scene + initializer)
3. Test!

---

## Quick Integration (15 minutes)

### Step 1: Add MoonAudioManager to Scene (5 min)

Edit `moon_landing.tscn`:

**Add at top (with other ext_resource lines):**
```gdscript
[ext_resource type="Script" path="res://scripts/audio/moon_audio_manager.gd" id="8_audio"]
```

**Add before SceneInitializer node:**
```gdscript
[node name="MoonAudioManager" type="Node" parent="."]
script = ExtResource("8_audio")
```

### Step 2: Update Initializer (5 min)

Edit `scripts/gameplay/moon_landing_initializer.gd`:

**Add to exports (line 13):**
```gdscript
@export var moon_audio_manager: MoonAudioManager = null
```

**Add to find_scene_nodes() (line 50):**
```gdscript
if not moon_audio_manager:
    moon_audio_manager = get_node_or_null("../MoonAudioManager")
```

**Add to _ready() (line 27, after initialize_hud()):**
```gdscript
initialize_audio()
```

**Add new function (after initialize_hud()):**
```gdscript
func initialize_audio() -> void:
    """Initialize the audio manager."""
    if not moon_audio_manager:
        push_warning("[MoonLandingInitializer] Moon audio manager not found")
        return

    var walking_controller: WalkingController = null
    if transition_system:
        walking_controller = transition_system.get_walking_controller()

    moon_audio_manager.initialize(spacecraft, walking_controller, landing_detector)
    print("[MoonLandingInitializer] Audio manager initialized")
```

### Step 3: Test Without Audio Files (5 min)

1. Open moon_landing.tscn in Godot
2. Run the scene
3. Check console for:
   - "[MoonAudioManager] Initialized (audio files not yet loaded)"
   - "[MoonLandingInitializer] Audio manager initialized"
4. Verify no crashes (system handles missing files gracefully)

✅ **System is now integrated!** Audio will work as soon as files are added.

---

## Adding Audio Files

### Option 1: Use Placeholders (Immediate Testing)
You can test with ANY .ogg files for now:
1. Find some placeholder .ogg files
2. Place in correct directories (see below)
3. Test audio triggers

### Option 2: Create/Source Proper Audio
See `audio/AUDIO_FILES_NEEDED.txt` for complete specifications.

### Directory Structure
```
audio/sfx/
├── spacecraft/
│   ├── engine_thrust_loop.ogg          [LOOP]
│   ├── rcs_thruster_burst.ogg
│   ├── cockpit_ambience_loop.ogg       [LOOP]
│   └── landing_gear_deploy.ogg
├── landing/
│   ├── landing_impact_soft.ogg
│   ├── landing_impact_medium.ogg
│   ├── landing_impact_hard.ogg
│   └── dust_settling.ogg
├── walking/
│   ├── footstep_moon_01.ogg
│   ├── footstep_moon_02.ogg
│   ├── footstep_moon_03.ogg
│   ├── jetpack_thrust_loop.ogg         [LOOP]
│   ├── jetpack_ignition.ogg
│   ├── jetpack_shutdown.ogg
│   ├── landing_thud.ogg
│   └── breathing_loop.ogg              [LOOP]
└── ui/
    ├── objective_complete.ogg
    ├── warning_beep.ogg
    ├── notification.ogg
    └── success_chime.ogg
```

**Total: 20 files**

### Configure Loops (Important!)
For files marked [LOOP], in Godot Editor:
1. Select file in FileSystem
2. Import tab → check "Loop"
3. Click "Reimport"

---

## Testing Checklist

Once audio files are added:

### Spacecraft
- [ ] Press W → engine thrust sound starts
- [ ] Release W → engine thrust sound stops
- [ ] Hold W → pitch increases
- [ ] Rotate (A/D/Q/E) → RCS thruster bursts
- [ ] Background cockpit hum present

### Descent
- [ ] Descend fast (>7.5 m/s) → warning beep
- [ ] Get close to moon → sounds louder

### Landing
- [ ] Touch down softly → soft impact
- [ ] Touch down fast → loud impact
- [ ] After landing → dust settling sound
- [ ] 1 sec later → success chime

### Walking
- [ ] Press SPACE to exit → cockpit ambience fades
- [ ] Walk → footsteps (timing matches speed)
- [ ] Sprint → faster footsteps
- [ ] Stand still → no footsteps
- [ ] Hold SPACE (jetpack) → ignition, then loop
- [ ] Release SPACE → jetpack shutdown
- [ ] Jump and land → landing thud
- [ ] Breathing in background (very quiet)

---

## Priority Audio Files

Can't create all 20 files? Start with these 8:

1. **engine_thrust_loop.ogg** - Essential for spacecraft feel
2. **footstep_moon_01.ogg** - Essential for walking feel
3. **jetpack_thrust_loop.ogg** - Essential for jetpack feel
4. **landing_impact_medium.ogg** - Essential for landing feedback
5. **success_chime.ogg** - Reward feedback
6. **warning_beep.ogg** - Safety feedback
7. **jetpack_ignition.ogg** - Jetpack start
8. **landing_thud.ogg** - Jump landing

These 8 files cover 80% of the audio experience!

---

## Troubleshooting

### "Audio files not yet loaded" in console
✅ Normal! Just means files haven't been added yet. No error.

### No sound playing
1. Check audio files exist in correct paths
2. Check Godot audio settings (not muted)
3. Check console for warnings

### Integration not working
1. Verify MoonAudioManager node exists in scene tree
2. Check console for "[MoonAudioManager] Initialized"
3. Check initializer has initialize_audio() call

---

## Resources

- **Complete Documentation**: `MOON_LANDING_AUDIO_SYSTEM.md`
- **Audio File Specs**: `audio/AUDIO_FILES_NEEDED.txt`
- **Integration Guide**: `scripts/audio/INTEGRATION_GUIDE.md`
- **Implementation Summary**: `AUDIO_IMPLEMENTATION_SUMMARY.md`

---

## What You Get

With audio fully integrated, the moon landing experience becomes:

🎵 **Immersive** - Feel like you're really flying and walking on the moon
🎮 **Responsive** - Every action has audio feedback
⚠️ **Safe** - Audio warnings help you land safely
🎉 **Rewarding** - Success sounds celebrate achievements
🌙 **Atmospheric** - Muffled sounds convey the vacuum of space
🚀 **Fun** - Jumping with the jetpack is satisfying and fun!

---

## Ready to Go!

The system is **fully implemented** and waiting for audio files.

**Estimated time to full integration: 15 minutes + audio file creation**

Even without audio files, the system is safe to integrate (graceful degradation).

Happy moon landing! 🚀🌕🎵
