# VFX Scripts - Moon Landing Visual Effects

## Overview
This directory contains visual effects scripts for the moon landing experience, designed to make jumping on the moon visually exciting while maintaining VR 90 FPS performance.

## Scripts

### landing_effects.gd
**Purpose**: Spacecraft visual effects
**Features**:
- Thruster particle trails (orange exhaust)
- Engine glow light (pulses with throttle)
- 4 landing lights (auto-activate near surface)
- Landing dust burst effect

**Usage**:
```gdscript
var effects = LandingEffects.new()
spacecraft.add_child(effects)
effects.setup(spacecraft)
```

### jetpack_effects.gd
**Purpose**: Jetpack thrust visualization
**Features**:
- Blue thrust particles (downward from feet)
- Thrust glow light
- Fuel-based intensity (sputters at low fuel)
- Audio player structure (ready for sound files)

**Usage**:
```gdscript
var jetpack = JetpackEffects.new()
walking_controller.add_child(jetpack)
jetpack.set_walking_controller(walking_controller)
```

### walking_dust_effects.gd
**Purpose**: Footstep and landing dust
**Features**:
- Footstep dust puffs (every 0.4s while walking)
- Jump landing dust burst (50 particles)
- Automatic triggering based on ground contact

**Usage**:
```gdscript
var dust = WalkingDustEffects.new()
walking_controller.add_child(dust)
dust.set_walking_controller(walking_controller)
```

### moon_landing_polish.gd
**Purpose**: Scene-wide visual polish
**Features**:
- Material improvements (moon, earth, spacecraft)
- 200-star starfield
- Earth atmosphere glow
- Environment settings (lighting, glow, tone mapping)
- Automatic scene node discovery and enhancement

**Usage**:
Add as node to moon_landing.tscn scene:
```
[node name="VisualPolish" type="Node" parent="."]
script = ExtResource("9_polish")
```

## Performance Guidelines

### Particle Counts
- Keep total simultaneous particles under 1000
- Use GPU particles (GPUParticles3D), not CPU
- Use one-shot for burst effects
- Limit lifetime to 2 seconds or less

### Lighting
- Limit dynamic lights to 10 or fewer
- Use shadows sparingly (only landing lights)
- Static lights for distant objects (stars)

### Materials
- Use StandardMaterial3D (Godot-optimized)
- Avoid custom shaders unless necessary
- Keep roughness/metallic simple calculations

## Integration with Existing Systems

### WalkingController
- Already references JetpackEffects (setup_jetpack_effects)
- Add WalkingDustEffects manually if desired
- Dust effects track is_on_floor() state changes

### Spacecraft
- LandingEffects connects to thrust_applied signal
- Updates automatically based on throttle/vertical_thrust
- Landing dust triggered by LandingDetector signal

### LandingDetector
- Emits landing_detected signal
- Connect to trigger landing dust burst
- MoonLandingPolish handles this automatically

## Customization

All effects expose `@export` variables for easy tuning:

```gdscript
# landing_effects.gd
@export var thruster_intensity: float = 1.0
@export var engine_glow_intensity: float = 2.0
@export var dust_on_landing: bool = true

# jetpack_effects.gd
@export var particle_amount: int = 50
@export var light_energy: float = 1.5
@export var sound_enabled: bool = true

# walking_dust_effects.gd
@export var dust_enabled: bool = true
@export var footstep_dust_amount: int = 20
@export var landing_dust_amount: int = 50
```

## Effect Timing

| Effect | Trigger | Duration | Particle Count |
|--------|---------|----------|----------------|
| Thruster | Continuous (throttle > 0.1) | Continuous | 50-200 |
| Engine Glow | Continuous (throttle > 0) | Continuous | N/A (light) |
| Landing Lights | <100m altitude | Continuous | N/A (4 lights) |
| Landing Dust | Landing detection | 2s burst | 200 |
| Jetpack Thrust | Space held | Continuous | 50 |
| Footstep Dust | Every 0.4s walking | 1s | 20 |
| Jump Landing | Ground contact after jump | 1.5s | 50 |

## Debugging

Enable debug prints in each script for troubleshooting:
- Look for `[LandingEffects]`, `[JetpackEffects]`, etc. in console
- Verify node creation messages on _ready()
- Check signal connections with `print()` in handlers

## Known Limitations

1. **No Audio**: Audio player structure exists but no sound files included
2. **No Textures**: Materials use solid colors, not texture maps
3. **Simple Particles**: Basic shapes (spheres/quads), not custom meshes
4. **No Decals**: Footprints not implemented (would require decal system)

## Future Enhancements

See MOON_LANDING_VFX_SUMMARY.md for full list of optional enhancements:
- Audio effects (thruster sounds, footsteps, impacts)
- Advanced shaders (heat distortion, atmosphere)
- Texture maps (normal maps, PBR materials)
- Decal system (footprints, scorch marks)
- Additional particle effects (dust trails, vapor)
