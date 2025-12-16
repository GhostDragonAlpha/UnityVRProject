# VR Controller Mapping for Moon Landing Experience

This document describes the VR controller mappings for the SpaceTime moon landing experience. The controls are designed to be intuitive and comfortable, with automatic fallback to desktop keyboard/mouse controls when VR is not available.

## System Requirements

- **VR Headset**: OpenXR-compatible headset (Quest 2/3, Index, Vive, etc.)
- **Controllers**: Left and right hand controllers with triggers, grip buttons, and thumbsticks
- **OpenXR Runtime**: SteamVR, Oculus Runtime, or other OpenXR-compatible runtime

## Mode Detection

The game automatically detects whether VR is available:
- **VR Mode**: If OpenXR headset and controllers are detected
- **Desktop Mode**: Falls back to keyboard/mouse if VR hardware is unavailable

## Spacecraft Controls (Flight Mode)

When piloting the spacecraft, the controls are:

### Left Controller
- **Trigger (Analog)**: **Forward Thrust**
  - Squeeze lightly for gentle acceleration
  - Squeeze fully for maximum thrust
  - Release to stop applying thrust

- **Thumbstick (Y-axis)**: **Forward/Backward Movement**
  - Push up: Move forward
  - Push down: Move backward

- **Thumbstick (X-axis)**: **Strafe Left/Right**
  - Push left: Strafe left
  - Push right: Strafe right

- **Grip Button**: **Roll Modifier**
  - Hold grip + use right thumbstick for roll control

### Right Controller
- **Trigger (Analog)**: **Backward Thrust / Brake**
  - Squeeze to apply reverse thrust or slow down

- **Thumbstick (Y-axis)**: **Pitch Control**
  - Push up: Pitch down (nose down)
  - Push down: Pitch up (nose up)

- **Thumbstick (X-axis)**: **Yaw Control** (when grip not held)
  - Push left: Turn left (yaw left)
  - Push right: Turn right (yaw right)

- **Thumbstick (X-axis)**: **Roll Control** (when left grip held)
  - Push left: Roll left
  - Push right: Roll right

- **A/X Button**: **Exit Spacecraft** (when landed)
  - Press to exit spacecraft and enter walking mode
  - Only available when safely landed (low altitude + low speed)

- **B/Y Button**: **Secondary Actions**
  - Reserved for future features (scanner, menu, etc.)

### Cockpit View
- **Head Tracking**: Look around the cockpit freely
- **Hand Visualization**: See simplified hand models representing your controllers
- **Seated Position**: Camera positioned at pilot seat (1.5m above spacecraft origin)

## Moon Walking Controls

When walking on the moon surface, the controls are:

### Left Controller
- **Thumbstick**: **Movement**
  - Push forward/back/left/right to walk
  - Thumbstick click: **Sprint** (hold while moving)
  - Movement direction is relative to where you're looking

### Right Controller
- **A/X Button**: **Jump** (when on ground)
  - Single tap for regular jump
  - Jump height affected by lunar gravity (1.62 m/s²)

- **Grip Button**: **Jetpack Thrust** (hold)
  - Hold to activate jetpack and fly
  - Uses fuel (shown in HUD)
  - Recharges when on ground
  - Especially useful in low-gravity environments

- **Thumbstick (X-axis)**: **Snap Turn**
  - Push left: Snap turn 45° left
  - Push right: Snap turn 45° right
  - Helps reduce motion sickness

- **B/Y Button**: **Return to Spacecraft** (when near)
  - Press when within 3 meters of spacecraft to return to flight mode

### Walking View
- **Head Tracking**: Full 360° head movement
- **Standing Height**: Camera positioned at eye level (1.7m)
- **Hand Presence**: See hands/gloves in your peripheral vision

## VR Comfort Features

The following comfort features are available to reduce motion sickness:

### Snap Turning (Recommended)
- **Default**: Enabled
- **Function**: Instant 45° rotation instead of smooth turning
- **Why**: Reduces disorientation and motion sickness
- **Control**: Right thumbstick left/right (in walking mode)

### Movement Vignette
- **Default**: Enabled (when implemented)
- **Function**: Reduces peripheral vision during movement
- **Why**: Limits visual flow, reducing nausea
- **When**: Activates during walking and spacecraft acceleration

### Smooth Locomotion Option
- **Default**: Enabled
- **Alternative**: Teleportation mode (not yet implemented)
- **Note**: Some users prefer teleport for maximum comfort

### Low-Gravity Flight Mode
- **Automatic**: Activates on bodies with gravity < 5 m/s²
- **Benefits**: Easier movement, reduced friction, increased speed
- **Jetpack**: More powerful in low-gravity environments

## Desktop Fallback Controls

When VR is not available, the following keyboard/mouse controls are used:

### Spacecraft Controls
- **W**: Forward thrust
- **S**: Backward thrust / brake
- **A/D**: Yaw (turn left/right)
- **Q/E**: Roll
- **Arrow Keys** or **I/J/K/L**: Pitch and yaw
- **Space**: Vertical thrust up
- **Ctrl**: Vertical thrust down
- **Space** (when landed): Exit spacecraft

### Walking Controls
- **W/A/S/D**: Movement
- **Mouse**: Look around
- **Space**: Jump / Jetpack thrust (hold)
- **Shift**: Sprint
- **E**: Return to spacecraft (when near)
- **Escape**: Toggle mouse capture

## Tips for VR Users

1. **Start Seated**: Begin in spacecraft mode while seated for comfort
2. **Take Breaks**: Remove headset if feeling uncomfortable
3. **Adjust Settings**: Use comfort features if experiencing motion sickness
4. **Clear Play Area**: Ensure safe space for standing/walking in VR
5. **Controller Orientation**: Controllers should point forward naturally
6. **Smooth Movements**: Start with small movements, gradually increase as comfortable

## Troubleshooting

### VR Not Detected
- Ensure OpenXR runtime is running (SteamVR, Oculus, etc.)
- Check that headset and controllers are connected
- Restart the application
- Falls back to desktop mode automatically if VR unavailable

### Controllers Not Responding
- Check controller battery levels
- Re-pair controllers with headset
- Restart OpenXR runtime

### Motion Sickness
- Enable snap turning instead of smooth turning
- Take frequent breaks
- Start with shorter sessions
- Use comfort vignette when available
- Focus on distant objects, not nearby ones

### Desktop Mode Instead of VR
- Check that OpenXR interface initialized properly
- Look for VR initialization messages in console
- Verify headset is detected by OpenXR runtime

## Technical Implementation

### Files Modified/Created
- `moon_landing.tscn`: Added XROrigin3D, XRCamera3D, XRController3D nodes
- `scripts/gameplay/moon_landing_vr_controller.gd`: Main VR coordinator
- `scripts/player/pilot_controller.gd`: Already has VR support built-in
- `scripts/player/walking_controller.gd`: Already has VR support built-in
- `scripts/gameplay/landing_detector.gd`: Updated for VR input detection
- `scripts/gameplay/moon_landing_initializer.gd`: Connects all systems
- `scripts/ui/moon_hud.gd`: Shows different prompts for VR vs desktop

### VR Integration Points
- **VRManager**: Core VR system (autoload from ResonanceEngine)
- **OpenXR**: Industry-standard VR API
- **PilotController**: Handles spacecraft VR input
- **WalkingController**: Handles moon walking VR input
- **MoonLandingVRController**: Coordinates mode transitions

### Desktop Mode Compatibility
- All features work in desktop mode
- Keyboard/mouse replaces controller input
- Camera3D replaces XRCamera3D
- Full feature parity maintained

## Future Enhancements

Planned VR features for future updates:
- Hand tracking support (no controllers required)
- Haptic feedback patterns (thrust vibration, landing impact)
- Virtual cockpit controls (interactive buttons, levers)
- Teleportation locomotion option
- Adjustable comfort settings menu
- VR-specific UI panels (3D in world space)
- Voice commands for spacecraft systems

## Control Summary Table

| Action | VR (Spacecraft) | VR (Walking) | Desktop |
|--------|-----------------|--------------|---------|
| Forward Thrust | Left Trigger | - | W |
| Backward Thrust | Right Trigger | - | S |
| Pitch | Right Stick Y | - | Arrow Up/Down |
| Yaw | Right Stick X | - | A/D |
| Roll | Grip + Right Stick X | - | Q/E |
| Move | - | Left Stick | W/A/S/D |
| Look | Head Tracking | Head Tracking | Mouse |
| Jump | - | A/X Button | Space |
| Jetpack | - | Grip (hold) | Space (hold) |
| Sprint | - | L-Stick Click | Shift |
| Snap Turn | - | R-Stick X | - |
| Exit Craft | A/X Button | - | Space |
| Return to Craft | - | B/Y Button | E |

---

**Note**: This document describes the current implementation as of December 2025. Controls and features may be updated in future releases.
