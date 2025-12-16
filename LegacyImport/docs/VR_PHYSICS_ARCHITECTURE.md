# VR Physics Architecture

**Last Updated:** 2025-12-09
**Purpose:** Explain the correct architecture for VR physics that doesn't interfere with VR tracking

## The Problem

**Original broken architecture:**
```
XROrigin3D (VR tracking updates position)
└── CharacterBody3D (move_and_slide() OVERRIDES position every frame)
```

**Result:** VR tracking moves XROrigin3D, but then `move_and_slide()` immediately overrides it with physics calculations. Player sees gray screen because position is stuck.

## The Solution: Two Approaches

### Approach 1: CharacterBody3D Follows VR Tracking (RECOMMENDED for VR Player Mode)

**Architecture:**
```gdscript
func _physics_process(delta):
    # Get VR headset position from XROrigin3D
    var vr_position = xr_origin.global_position

    # Sync CharacterBody3D to follow VR tracking
    player_body.global_position = vr_position

    # Now do collision detection at VR position
    # This gives us ground detection, wall collision, etc.
    # WITHOUT overriding the VR tracking position

    # Apply local gravity (not N-body orbital gravity)
    if not player_body.is_on_floor():
        velocity.y -= 9.8 * delta  # Standard ground gravity
    else:
        velocity.y = 0

    # Move with collision (but position is set by VR tracking)
    player_body.velocity = velocity
    player_body.move_and_slide()

    # CRITICAL: Don't apply the result back to XROrigin3D
    # VR tracking controls position, physics only does collision
```

**Key principle:** VR tracking sets position, physics provides collision feedback.

### Approach 2: AI Controls CharacterBody3D (For AI Training Mode)

**Architecture:**
```gdscript
func _physics_process(delta):
    if ai_controller_active:
        # AI calculates desired movement
        var ai_velocity = ai_controller.get_desired_velocity()

        # Apply physics movement
        player_body.velocity = ai_velocity
        player_body.move_and_slide()

        # Sync XROrigin3D to follow physics (for observation)
        xr_origin.global_position = player_body.global_position
```

**Key principle:** AI controls position via physics, VR tracking follows for observation.

## Correct Mode Behaviors

### VR Player Mode
- **VR Tracking:** Controls XROrigin3D position (PRIMARY)
- **Physics:** Provides collision detection and gravity (SECONDARY)
- **CharacterBody3D:** Syncs TO XROrigin3D position
- **AI Controller:** Disabled
- **Result:** Player has full VR control with realistic physics interactions

### AI Training Mode
- **AI Controller:** Controls CharacterBody3D velocity (PRIMARY)
- **Physics:** Moves character based on AI input (SECONDARY)
- **XROrigin3D:** Follows CharacterBody3D for VR observation (TERTIARY)
- **VR Tracking:** Still active but position follows AI movement
- **Result:** AI learns to control character, human can observe in VR

## Implementation in vr_main.gd

### Current Problem Code (WRONG)
```gdscript
func _physics_process(delta):
    # This ALWAYS overrides VR tracking:
    player_body.velocity = calculated_physics_velocity
    player_body.move_and_slide()  # ← OVERRIDES XROrigin3D position!
```

### Fixed Code for VR Player Mode (CORRECT)
```gdscript
func _physics_process(delta):
    if physics_movement_enabled and not is_vr_player_mode():
        # AI Training Mode: Physics controls position
        var ai_velocity = _calculate_ai_movement()
        player_body.velocity = ai_velocity
        player_body.move_and_slide()

        # Sync VR to physics
        xr_origin.global_position = player_body.global_position
    else:
        # VR Player Mode: VR tracking controls position
        # Sync physics body to VR position
        player_body.global_position = xr_origin.global_position

        # Apply local gravity for ground detection
        if not player_body.is_on_floor():
            velocity.y -= 9.8 * delta
        else:
            velocity.y = 0

        # Collision detection only (doesn't change XROrigin3D position)
        player_body.velocity = Vector3(0, velocity.y, 0)
        player_body.move_and_slide()
```

## Why This Matters

**Without proper separation:**
- VR tracking updates position → Physics immediately overrides it → Gray screen
- Player can't move in VR because physics locks position at (0,0,0)

**With proper separation:**
- VR Player Mode: VR tracking works perfectly, physics adds realism
- AI Training Mode: AI learns movement, VR provides observation viewport

## Implementation Checklist

- [ ] Separate VR Player mode from AI Training mode
- [ ] In VR Player mode: CharacterBody3D follows XROrigin3D
- [ ] In AI Training mode: XROrigin3D follows CharacterBody3D
- [ ] Use ControllerModeManager to switch between modes
- [ ] Never call `move_and_slide()` that overrides VR tracking in VR Player mode
- [ ] Physics provides collision/gravity feedback, not position control (in VR mode)

## Testing

**VR Player Mode Test:**
1. Put on headset
2. Move head - position should update immediately
3. Walk around - should feel walls/floor via haptics
4. Position should NEVER be stuck at (0,0,0)

**AI Training Mode Test:**
1. Enable AI controller
2. AI should be able to move character
3. VR headset should show AI's view (following AI movement)
4. RL agent can observe and learn

## Key Files

- `scripts/core/controller_mode_manager.gd` - Mode switching system
- `vr_main.gd:127-175` - Physics process loop (needs refactoring)
- `docs/VR_TESTING_WORKFLOW.md` - Debugging VR issues
