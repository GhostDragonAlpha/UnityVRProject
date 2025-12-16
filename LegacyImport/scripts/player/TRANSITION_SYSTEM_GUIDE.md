# Space-to-Surface Transition System Guide

## Overview

The TransitionSystem manages seamless transitions between space flight and planetary surface exploration. It handles progressive LOD increases, atmospheric effects, and navigation mode switching without loading screens.

## Architecture

### State Machine

```
SPACE → APPROACHING → ATMOSPHERE → SURFACE
  ↑         ↓             ↓           ↓
  └─────────┴─────────────┴───────────┘
```

**States:**

- **SPACE**: Far from any planet, standard space navigation
- **APPROACHING**: Within transition altitude, LOD increasing
- **ATMOSPHERE**: In planetary atmosphere, drag and effects active
- **SURFACE**: Near surface, high-detail terrain streaming
- **LANDING**: Landing sequence (future implementation)

### Key Altitudes

- **Transition Altitude**: 100,000m - Begin approach sequence
- **Atmosphere Altitude**: 50,000m - Enter atmosphere
- **Surface Altitude**: 1,000m - Switch to surface mode

## Components

### TransitionSystem (`transition_system.gd`)

Main coordinator for space-to-surface transitions.

**Key Methods:**

- `initialize(craft, lod_mgr, float_origin, atmos)` - Set up system references
- `update_transition_state(delta)` - Main state machine update
- `find_nearest_planet()` - Locate closest planetary body
- `calculate_altitude(planet)` - Get altitude above surface

**Signals:**

- `transition_started(planet)` - Approach begins
- `transition_completed(planet)` - Returned to space
- `atmosphere_entered(planet)` - Entered atmosphere
- `atmosphere_exited(planet)` - Left atmosphere
- `surface_approached(altitude)` - Near surface

### AtmosphereSystem (`atmosphere_system.gd`)

Handles atmospheric effects during descent.

**Features:**

- Drag force calculation based on velocity and density
- Heat damage at high speeds
- Visual effects (shimmer, plasma)
- Audio effects (rumble, wind)

**Key Methods:**

- `activate(planet)` - Enable atmospheric effects
- `deactivate()` - Disable effects
- `update_effects(ratio, velocity)` - Update all effects
- `apply_drag_force(velocity, ratio)` - Calculate drag
- `apply_heat_effects(speed, ratio)` - Calculate heat damage

**Signals:**

- `drag_applied(force)` - Drag force calculated
- `heat_damage_applied(damage)` - Heat damage applied

## Integration

### Setup in Main Scene

```gdscript
# In main game scene
var transition_system = TransitionSystem.new()
var atmosphere_system = AtmosphereSystem.new()

func _ready():
    add_child(atmosphere_system)
    add_child(transition_system)

    transition_system.initialize(
        spacecraft,
        lod_manager,
        floating_origin,
        atmosphere_system
    )
```

### Spacecraft Integration

The spacecraft should respond to atmospheric drag:

```gdscript
# In spacecraft.gd
func _ready():
    var atmos = get_node("/root/AtmosphereSystem")
    if atmos:
        atmos.drag_applied.connect(_on_drag_applied)
        atmos.heat_damage_applied.connect(_on_heat_damage)

func _on_drag_applied(force: Vector3):
    apply_central_force(force)

func _on_heat_damage(damage: float):
    signal_manager.add_noise(damage)
```

### LOD Manager Integration

The LOD manager should respond to transition requests:

```gdscript
# In lod_manager.gd
func set_target_detail_level(planet: CelestialBody, level: float):
    # Progressively increase terrain detail
    pass

func switch_to_surface_mode(planet: CelestialBody):
    # Enable high-detail streaming
    pass

func switch_to_orbital_mode(planet: CelestialBody):
    # Return to orbital LOD
    pass
```

## Transition Sequence

### Approach Phase

1. **Detection**: System detects spacecraft within transition altitude
2. **LOD Increase**: Begin progressive terrain detail increase
3. **Floating Origin**: Maintain coordinate rebasing
4. **Signal**: Emit `transition_started`

### Atmospheric Entry

1. **Atmosphere Detection**: Altitude drops below atmosphere threshold
2. **Effect Activation**: Enable atmospheric effects
3. **Drag Application**: Begin applying drag forces
4. **Visual Effects**: Activate atmosphere shader
5. **Audio**: Start rumble and wind sounds
6. **Signal**: Emit `atmosphere_entered`

### Surface Approach

1. **Surface Detection**: Altitude drops below surface threshold
2. **LOD Switch**: Change to surface streaming mode
3. **Navigation Mode**: Switch to surface navigation
4. **High Detail**: Stream high-resolution terrain
5. **Signal**: Emit `surface_approached`

### Ascent (Reverse)

The system automatically reverses the sequence when ascending:

1. Leave surface → Atmosphere
2. Exit atmosphere → Approaching
3. Return to space → Space

## Performance Considerations

### LOD Management

- **Progressive Loading**: Terrain detail increases gradually
- **Streaming**: Only load visible terrain chunks
- **Unloading**: Unload distant chunks to free memory

### Floating Origin

- **Continuous Rebasing**: Maintain precision during transition
- **Coordinate Updates**: Update all objects during rebase
- **Frame Budget**: Complete rebasing within single frame

### Effect Optimization

- **Conditional Rendering**: Only render effects when visible
- **LOD for Effects**: Reduce particle counts at distance
- **Audio Culling**: Stop sounds when too quiet

## Configuration

### Transition Parameters

```gdscript
# Adjust in TransitionSystem
@export var transition_altitude: float = 100000.0
@export var atmosphere_altitude: float = 50000.0
@export var surface_altitude: float = 1000.0
@export var transition_speed: float = 2.0
```

### Atmosphere Parameters

```gdscript
# Adjust in AtmosphereSystem
@export var drag_coefficient: float = 0.5
@export var heat_damage_threshold: float = 500.0
@export var max_heat_damage: float = 10.0
```

## Testing

### Manual Testing

1. **Approach Test**: Fly toward a planet and verify LOD increases
2. **Atmosphere Test**: Enter atmosphere and check drag/effects
3. **Surface Test**: Approach surface and verify mode switch
4. **Ascent Test**: Take off and verify reverse sequence
5. **Performance Test**: Monitor FPS during transitions

### Debug Visualization

Enable debug output:

```gdscript
# In TransitionSystem
func _process(delta):
    print("State: ", TransitionState.keys()[current_state])
    print("Altitude: ", current_altitude)
    print("LOD Level: ", lod_manager.get_current_level())
```

## Troubleshooting

### Issue: Jerky LOD Transitions

**Solution**: Increase `transition_speed` or smooth LOD interpolation

### Issue: Excessive Drag

**Solution**: Reduce `drag_coefficient` or adjust atmosphere density

### Issue: No Atmospheric Effects

**Solution**: Verify AtmosphereSystem is connected and activated

### Issue: Floating Origin Glitches

**Solution**: Ensure rebasing completes before rendering

## Future Enhancements

- **Landing Gear**: Automatic deployment near surface
- **Terrain Collision**: Prevent clipping through terrain
- **Weather Effects**: Dynamic weather during descent
- **Multiple Atmospheres**: Different atmosphere types per planet
- **Reentry Heating**: Visual heat buildup on spacecraft
- **Sonic Boom**: Audio effect when breaking sound barrier

## Requirements Validated

- **51.1**: Progressive terrain detail increase ✓
- **51.2**: Smooth orbital to surface transition ✓
- **51.3**: Floating origin maintained ✓
- **51.4**: Atmospheric effects during descent ✓
- **51.5**: Surface navigation mode switch ✓
