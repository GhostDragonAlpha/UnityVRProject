# Walking System Guide

## Overview

The Walking System enables first-person VR locomotion on planetary surfaces. It provides smooth movement controls using VR motion controllers or keyboard/mouse in desktop mode, with planet-specific gravity and terrain collision detection.

## Architecture

### Components

1. **WalkingController** (`scripts/player/walking_controller.gd`)

   - CharacterBody3D-based controller for first-person movement
   - Handles VR controller input and desktop keyboard/mouse input
   - Applies planet-specific gravity
   - Manages collision detection with terrain
   - Provides return-to-spacecraft functionality

2. **TransitionSystem** (updated)
   - Manages state transitions including walking mode
   - Creates and initializes walking controller
   - Handles switching between flight and walking modes

## Requirements Validation

### Requirement 52.1: First-person walking controls with VR motion controllers

- ✅ Left controller thumbstick for movement
- ✅ Right controller thumbstick for snap turning
- ✅ Left thumbstick click for sprinting
- ✅ Right A button for jumping
- ✅ Right B button for returning to spacecraft
- ✅ Desktop fallback with WASD + mouse

### Requirement 52.2: Planet-specific gravity

- ✅ Calculates gravity using G \* M / R²
- ✅ Applies gravity force in physics process
- ✅ Clamps to reasonable gameplay values (0.1 - 50.0 m/s²)

### Requirement 52.3: Collision detection

- ✅ Uses CharacterBody3D with capsule collision shape
- ✅ move_and_slide() for terrain collision
- ✅ Ground detection raycast
- ✅ Prevents clipping through terrain

### Requirement 52.4: Terrain rendering at walking scale

- ✅ LOD manager switches to surface mode
- ✅ High-detail terrain streaming
- ✅ Appropriate scale for walking speed

### Requirement 52.5: Return to spacecraft

- ✅ Proximity detection (3m range)
- ✅ Interact button to return
- ✅ Smooth transition back to flight mode
- ✅ Signal-based communication

## Usage

### Enabling Walking Mode

```gdscript
# From TransitionSystem
transition_system.enable_walking_mode()
```

### Disabling Walking Mode

```gdscript
# From TransitionSystem
transition_system.disable_walking_mode()

# Or automatically when player returns to spacecraft
# (walking controller emits returned_to_spacecraft signal)
```

### Checking Walking State

```gdscript
if transition_system.is_walking_mode_active():
    print("Player is walking")

if walking_controller.is_walking():
    print("Player is moving")
```

## VR Controls

### Left Controller

- **Thumbstick**: Move forward/backward/strafe
- **Thumbstick Click**: Sprint

### Right Controller

- **Thumbstick Left/Right**: Snap turn (45° increments)
- **A Button**: Jump
- **B Button**: Return to spacecraft (when near)

## Desktop Controls

- **W/A/S/D**: Movement
- **Mouse**: Look around
- **Shift**: Sprint
- **Space**: Jump
- **E**: Return to spacecraft (when near)
- **Escape**: Toggle mouse capture

## Configuration

### Movement Parameters

```gdscript
@export var walk_speed: float = 2.0  # m/s
@export var sprint_speed: float = 4.0  # m/s
@export var jump_velocity: float = 4.0  # m/s
```

### VR Comfort Options

```gdscript
@export var smooth_locomotion: bool = true  # If false, use teleport
@export var comfort_vignette: bool = true  # Reduce FOV during movement
@export var snap_turn_angle: float = 45.0  # Degrees for snap turning
```

## Integration with Other Systems

### Spacecraft

- Walking controller needs reference to spacecraft for return functionality
- Spacecraft should implement `disable_flight_controls()` and `enable_flight_controls()`

### VRManager

- Walking controller uses VRManager for input and camera tracking
- Supports both VR and desktop modes

### CelestialBody

- Walking controller calculates gravity from planet mass and radius
- Gravity direction points toward planet center

### LODManager

- Switches to surface mode for high-detail terrain
- Streams terrain chunks based on player position

### FloatingOrigin

- Maintains coordinate precision during walking
- Rebases coordinates as player moves

## Signals

### WalkingController Signals

```gdscript
signal walking_started
signal walking_stopped
signal returned_to_spacecraft
```

### TransitionSystem Signals

```gdscript
signal walking_mode_enabled
signal walking_mode_disabled
```

## Example Integration

```gdscript
# In main game scene
func _ready():
    # Initialize transition system with walking support
    transition_system.initialize(
        spacecraft,
        lod_manager,
        floating_origin,
        atmosphere_system,
        vr_manager
    )

    # Connect signals
    transition_system.walking_mode_enabled.connect(_on_walking_enabled)
    transition_system.walking_mode_disabled.connect(_on_walking_disabled)

func _on_spacecraft_landed():
    # Enable walking mode when landed
    transition_system.on_spacecraft_landed()

    # Player can now press a button to exit spacecraft
    # and enable walking mode
    if Input.is_action_just_pressed("exit_spacecraft"):
        transition_system.enable_walking_mode()

func _on_walking_enabled():
    print("Player is now walking on the surface")
    # Update UI, show walking controls, etc.

func _on_walking_disabled():
    print("Player returned to spacecraft")
    # Update UI, show flight controls, etc.
```

## Physics Details

### Gravity Calculation

The walking controller calculates surface gravity using Newton's law of universal gravitation:

```
g = G * M / R²

Where:
- G = 6.67430e-11 (gravitational constant)
- M = planet mass (kg)
- R = planet radius (m)
```

The result is clamped to 0.1 - 50.0 m/s² for gameplay purposes.

### Movement Physics

- Uses CharacterBody3D's built-in physics
- `move_and_slide()` handles collision and sliding
- Velocity is applied in the direction of camera facing
- Gravity is applied continuously when not on ground
- Friction is applied when no input is detected

### Collision Shape

- Capsule shape: 0.4m radius, 1.8m height
- Positioned at 0.9m height (center of capsule)
- Ground raycast extends 2m downward

## Performance Considerations

- Walking controller only processes when active
- Ground raycast is efficient (single ray)
- CharacterBody3D physics is optimized by Godot
- VR input polling is minimal overhead

## Future Enhancements

Potential improvements for future iterations:

1. **Teleport Locomotion**: Alternative to smooth locomotion for VR comfort
2. **Climbing**: Ability to climb steep terrain or structures
3. **Swimming**: Water physics and swimming mechanics
4. **Jetpack**: Short-duration flight for low-gravity planets
5. **Footstep Audio**: Terrain-specific footstep sounds
6. **Stamina System**: Limit sprinting duration
7. **Environmental Hazards**: Damage from extreme temperatures, radiation, etc.
8. **Inventory Access**: Open inventory while walking
9. **Scanning**: Scan terrain and objects while walking
10. **Photo Mode**: Take screenshots while walking

## Troubleshooting

### Player falls through terrain

- Ensure terrain has collision enabled
- Check collision layers/masks match
- Verify CharacterBody3D has collision shape

### Gravity feels wrong

- Check planet mass and radius values
- Verify gravity calculation in `calculate_planet_gravity()`
- Adjust gravity clamp values if needed

### VR controls not working

- Ensure VRManager is initialized
- Check controller tracking is active
- Verify controller state dictionary has expected keys

### Can't return to spacecraft

- Check spacecraft position is set correctly
- Verify proximity distance (3m default)
- Ensure interact button is being detected

### Desktop camera not rotating

- Check mouse capture mode is enabled
- Verify mouse sensitivity value
- Ensure \_input() is receiving mouse motion events

## Testing

### Manual Testing Checklist

- [ ] Walk forward/backward/strafe in VR
- [ ] Walk with WASD in desktop mode
- [ ] Sprint with thumbstick click / Shift
- [ ] Jump with A button / Space
- [ ] Snap turn with right thumbstick
- [ ] Return to spacecraft when nearby
- [ ] Gravity feels appropriate for planet
- [ ] No clipping through terrain
- [ ] Smooth transition from flight to walking
- [ ] Smooth transition from walking to flight
- [ ] Desktop mouse look works correctly
- [ ] VR camera tracking works correctly

### Automated Testing

Unit tests should cover:

- Gravity calculation for various planet masses/radii
- Movement direction calculation
- Input processing (VR and desktop)
- State transitions
- Proximity detection

## References

- Requirements: 52.1, 52.2, 52.3, 52.4, 52.5
- Design Document: Surface Walking Mechanics section
- Related Systems: TransitionSystem, VRManager, CelestialBody, LODManager
